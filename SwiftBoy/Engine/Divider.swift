//
//  Divider.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 02/01/2021.
//

import Foundation

final class Divider: Actor, MemoryMappable {
    var rawdata: UInt8 = 0x00
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

//    func compute(for tics: Int) {
//        self.tics += tics
//        rawdata &+= UInt8(truncatingIfNeeded: (tics / cyclesPerTic))
//        self.tics = tics % cyclesPerTic
//    }
    
    func tic() {
        self.tics += 1
        rawdata &+= UInt8(truncatingIfNeeded: (tics / cyclesPerTic))
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
