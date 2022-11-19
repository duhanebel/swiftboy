//
//  Timer.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 02/01/2021.
//

import Foundation

final class Counter: Actor, MemoryMappable {
    enum ClockSpeed: Int {
        case mode00 = 4096
        case mode01 = 262144
        case mode10 = 65536
        case mode11 = 16384
    }
    
    private struct MemoryAddress {
        static let counterData = UInt16(0xFF05)
        static let moduloData = UInt16(0xFF06)
        static let controlData = UInt16(0xFF07)
        static let range = UInt16(0xFF05)..<UInt16(0xFF08)
    }
    
    let CPUSpeed: Int
    var cyclesPerTic: Int = 0
    
    private var running: Bool = false
    
    var counterData: UInt8 = 0x00
    var moduloData: UInt8 = 0x00
    
    // Bit 2    - Timer Stop  (0=Stop, 1=Start)
    // Bits 1-0 - Input Clock Select
    //           00:   4096 Hz    (~4194 Hz SGB)
    //           01: 262144 Hz  (~268400 Hz SGB)
    //           10:  65536 Hz   (~67110 Hz SGB)
    //           11:  16384 Hz   (~16780 Hz SGB)
    var controlData: UInt8 = 0x0 {
        didSet {
            running = controlData[2].boolValue
            
            switch(controlData[1], controlData[0]) {
            case (0, 0):
                cyclesPerTic = CPUSpeed / ClockSpeed.mode00.rawValue
            case (0, 1):
                cyclesPerTic = CPUSpeed / ClockSpeed.mode01.rawValue
            case (1, 0):
                cyclesPerTic = CPUSpeed / ClockSpeed.mode10.rawValue
            case (1, 1):
                cyclesPerTic = CPUSpeed / ClockSpeed.mode11.rawValue
            default:
                running = false
            }
        }
    }
    
    var intRegister: InterruptRegister
    
    private var tics = 0
    
    init(CPUSpeed: Int, intRegister: InterruptRegister) {
        self.CPUSpeed = CPUSpeed
        self.intRegister = intRegister
    }
    
    // If the timer is started (bit 2 of the TAC), the Timer Counter (TIMA) gets incremented
    // at a rate specified by the Timer Control (TAC).  When the Timer Counter gets to 0xFF
    // and is incremented, it effectively overflows, and when this happens, it gets loaded with
    // the value held at the Timer Modulo (TMA).
    func tic() {
        guard running else { return }
        self.tics += 1
        guard self.tics == cyclesPerTic else { return }
        
        
        counterData &+= 1
        let overflow = (counterData == 0)

        if overflow {
            generateInterrupt()
            counterData = moduloData
        }
        self.tics = 0
    }
    
    func read(at address: UInt16) throws -> UInt8 {
        switch(address) {
        case MemoryAddress.counterData:
            return counterData
        case MemoryAddress.moduloData:
            return moduloData
        case MemoryAddress.controlData:
            return controlData
        default:
            throw MemoryError.outOfBounds(address, MemoryAddress.range)
        }
    }
    
    func write(byte: UInt8, at address: UInt16) throws {
        switch(address) {
        case MemoryAddress.counterData:
            counterData = byte
        case MemoryAddress.moduloData:
            moduloData = byte
        case MemoryAddress.controlData:
            controlData = byte
        default:
            throw MemoryError.outOfBounds(address, MemoryAddress.range)
        }
    }
    
    private func generateInterrupt() {
        intRegister.timer = true
    }
}
