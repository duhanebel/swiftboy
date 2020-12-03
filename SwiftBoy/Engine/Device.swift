//
//  Device.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 02/12/2020.
//

import Foundation

protocol Actor {
    func compute(for tics: Int)
}

protocol InterruptGenerator {
    typealias InterruptHandler = (() -> Void)
    var interruptHandler: InterruptHandler? { get set }
}

class Divider: Actor, MemoryMappable {
    var rawdata: UInt8 = 0x0
    private var tics: Int = 0

    // The  DIV register is incremented 16384 times per second
    // The CPU frequency is 4194304 Hz.
    // The number of cycles requires for the DIV register to be incremented is then
    // 4194304/16384=256 CPU cycles.
    // NOTE: This timer doesn't include any interrupt mechanism
    static let speed = 16384 // Hz
    let cyclesPerTic: Int
    
    init(CPUSpeed: Int) {
        self.cyclesPerTic = CPUSpeed / Divider.speed
    }

    func compute(for tics: Int) {
        self.tics += tics
        rawdata &+= UInt8(tics / cyclesPerTic)
        self.tics = tics % cyclesPerTic
    }
    
    func read(at address: UInt16) throws -> UInt8 {
        return rawdata
    }
    
    // Writing any value to this register will reset it
    func write(byte: UInt8, at address: UInt16) throws {
        rawdata = 0x0
    }
}

enum RegisteError : Error {
    case invalidValue(String)
}

class Counter: Actor, MemoryMappable {
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
    
    var counterData: UInt8 = 0x0
    var moduloData: UInt8 = 0x0
    
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
    func compute(for tics: Int) {
        self.tics += tics
        let counterDelta = tics / cyclesPerTic
        let overflow = (Int(counterData) + counterDelta) / 0xFFFF
        counterData &+= UInt8(tics / counterDelta)

        for _ in 0..<overflow {
            generateInterrupt()
            counterData = moduloData
        }
        
        self.tics = tics % cyclesPerTic
        
        // TODO: should check for overflow again here for completeness??
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

class Audio: Actor, MemoryMappable {
    func read(at address: UInt16) throws -> UInt8 {
        return 0

    }
    
    func write(byte: UInt8, at address: UInt16) throws {
    }
    
    func compute(for tics: Int) {
        
    }
}


class Device {
    let cpu: CPU
    let mmu: MMU
    let ppu: PPU
    
    let joypad: Joypad
    
    let timer: Counter
    let divider: Divider
    
    let audio: Audio
    
    var running = false
    
    let queue: DispatchQueue = DispatchQueue(label: "com.swiftboy.compute")
    
    static func gameBoy(biosROM: ROM?) -> Device {
        let intRegister = InterruptRegister()
        let intEnabledRegister = InterruptRegister()
        
        let ppu = PPU(screen: Screen())
        
        let joypad = Joypad(intRegister: intRegister)
        let divider = Divider(CPUSpeed: CPU.clockSpeed)
        let counter = Counter(CPUSpeed: CPU.clockSpeed, intRegister: intRegister)
        let serial = RAM(size: 1) // unimplemented
        let audio = Audio()
        
        let io = IO(joypad: joypad,
                    serial: serial,
                    divider: divider,
                    timer: counter,
                    interruptFlag: intRegister,
                    audio: audio,
                    video: ppu.registers,
                    interruptEnabled: intEnabledRegister)
        
        let mmu = MMU(rom: nil,
                      biosROM: biosROM,
                      switchableRom: nil,
                      vram: ppu.vram,
                      sram: ppu.sram,
                      io: io)
        
        let cpu = CPU(mmu: mmu, intEnabled: intEnabledRegister, intRegister: intRegister)
        
        return Device(cpu: cpu,
                      mmu: mmu,
                      ppu: ppu,
                      joypad: joypad,
                      timer: counter,
                      divider: divider,
                      audio: audio)
    }
    
    init(cpu: CPU, mmu: MMU, ppu: PPU, joypad: Joypad, timer: Counter, divider: Divider, audio: Audio) {
        self.cpu = cpu
        self.mmu = mmu
        self.ppu = ppu
        self.joypad = joypad
        self.timer = timer
        self.divider = divider
        self.audio = audio
    }
    
    func run() {
        running = true
        queue.async { self.compute() }
    }
    
    private func compute(at startTime: DispatchTime = DispatchTime.now()) {
        let cycles = cpu.tic()
        timer.compute(for: cycles)
        divider.compute(for: cycles)
        ppu.compute(for: cycles)
        audio.compute(for: cycles)
        
        if running {
            let nextCycleDeadline = adjustRuntimeAfter(cycles: cycles, since: startTime)
            queue.asyncAfter(deadline: nextCycleDeadline, execute: { self.compute(at: nextCycleDeadline) })
        }
    }
    
    private func adjustRuntimeAfter(cycles: Int, since: DispatchTime) -> DispatchTime {
        let cpuExpecteRunTimeInterval = (Double(cycles) / Double(CPU.clockSpeed))
        let expectedCPURunTime = since + cpuExpecteRunTimeInterval
        
        let elapsedTime = since.distance(to: DispatchTime.now())
        return expectedCPURunTime - elapsedTime
    }
}
