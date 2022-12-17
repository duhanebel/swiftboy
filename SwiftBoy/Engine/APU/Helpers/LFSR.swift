//
//  LFSR.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 11/12/2022.
//

import Foundation

final class LinearFeedbackShiftRegister: Actor {
    enum Mode {
        case `long`
        case `short`
    }
    var buffer: UInt16
    let mode: Mode
    
    var value: Byte {
        // The value of the Shift Register is reversed
        get { (buffer[0] == 0) ? 1 : 0 }
    }
    
    init(mode: Mode) {
        // On a trigger event, all the bits of LFSR are set to 1.
        self.buffer =  0xFFFF //UInt16.random(in: UInt16.min...UInt16.max)
        self.mode = mode
    }
    
    func tic() {
        let res = buffer[0] ^ buffer[1]
        buffer[15] = res
        if mode == .short {
            buffer[7] = res
        }
        buffer = buffer >> 1
    }
}
