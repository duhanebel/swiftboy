//
//  UInt8+Bits.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 26/11/2020.
//

import Foundation

extension UInt8 {
    subscript(index: Int) -> UInt8 {
        get { (self >> index) & 0x01 }
        set {
            let bitValue = (newValue == 0) ? 0 : 1
            guard self[index] != bitValue else { return }
            self ^= (1 << index)
        }
    }
    
    var complement: Self {
        get {
            var result = self
            for n in 0..<self.bitWidth {
                result[n] = result[n] == 1 ? 0 : 1
            }
            return result
        }
    }
    
    var lowerNibble: Self {
        get { self & 0x0F }
        set { self = (self & 0xF0) | (newValue & 0x0F) }
    }
    
    var upperNibble: Self {
        get { self >> 4 }
        set { self = (self & 0x0F) | ((newValue << 4) & 0xF0) }
    }
    
    var signed16: UInt16 {
        get {
            var res = UInt16(self)
            // preserve 2-complement when extending
            if self[7] == 0x01 { res |= 0xFFFF << 8 }
            return res
        }
    }
}

extension UInt16 {
    subscript(index: Int) -> UInt8 {
        get {
            return UInt8((self >> index) & 0x01)
        }
        set {
            guard self[index] != newValue else { return }
            self ^= (1 << index)
        }
    }
    
    var complement: Self {
        get {
            var result = self
            for n in 0..<self.bitWidth {
                result[n] = result[n] == 1 ? 0 : 1
            }
            return result
        }
    }
}
