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

    subscript(_ idx: (Int, Int)) -> UInt8 {
        get { return self[idx.0, idx.1] }
        set { self[idx.0, idx.1] = newValue }
    }
    
    subscript(_ startIdx: Int, _ endIdx: Int) -> UInt8 {
        get {
            let endIndexBitmask: UInt8 = (1 << (endIdx+1)) &- 1
            return (self & endIndexBitmask) >> startIdx
        }
        set {
            
            let endIndexBitmask: UInt8 = (1 << (endIdx+1)) &- 1
            let startIndexBitmask: UInt8 = (1 << (startIdx)) - 1
            let bitmask: UInt8 = endIndexBitmask ^ startIndexBitmask
            
            self = (self & ~bitmask) | ((newValue << startIdx) & bitmask)
        }
    }
    
    var complement: Self {
        get {
            var result = self
            for n in 0..<self.bitWidth {
                result[n] = self[n] == 1 ? 0 : 1
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
    
    // TODO needed?
    var bitReversed: UInt8 {
        // See "Reverse the bits in a byte with 4 operations (64-bit multiply, no division)"
        // at http://graphics.stanford.edu/%7Eseander/bithacks.html#ReverseByteWith64BitsDiv
        let v = ((UInt64(self) * UInt64(0x8020_0802)) & UInt64(0x08_8442_2110) &* UInt64(0x01_0101_0101)) >> 32
        return UInt8(v & 0xFF)
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
