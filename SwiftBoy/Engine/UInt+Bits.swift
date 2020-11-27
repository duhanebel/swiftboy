//
//  UInt8+Bits.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 26/11/2020.
//

import Foundation

extension UInt8 {
    subscript(index: Int) -> UInt8 {
        get {
            return (self >> index) & 0x01
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
