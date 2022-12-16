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
        get { buffer[0] }
    }
    
    init(mode: Mode) {
        self.buffer = UInt16.random(in: UInt16.min...UInt16.max)
        self.mode = mode
    }
    
    func tic() {
        let res = value[0] ^ value[1]
        buffer[15] = res
        if mode == .short {
            buffer[7] = res
        }
        buffer = buffer >> 1
    }
}
