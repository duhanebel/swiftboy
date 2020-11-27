//
//  UInt16+Bytes.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 25/11/2020.
//

import Foundation

extension UInt16 {
    var lowerByte: UInt8 {
        get { UInt8(self & 0x00FF) }
        set { self = (self & 0xFF00) | UInt16(newValue) }
        
    }
    
    var upperByte: UInt8 {
        get { UInt8(self >> 8) }
        set { self = (self & 0x00FF) | (UInt16(newValue) << 8) }
    }
}
