//
//  RAM.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 28/11/2020.
//

import Foundation

class RAM {
    private var rawmem = Array<UInt8>(repeating: 0x0, count: 0xFFFF)
    
    func read(at address: UInt16) -> UInt8 {
        return rawmem[Int(address)]
    }
    
    func readWord(at address: UInt16) -> UInt16 {
        var word: UInt16 = 0
        word.upperByte = rawmem[Int(address)]
        word.lowerByte = rawmem[Int(address)+1]
        return word
    }
    
    func write(byte: UInt8, at address: UInt16) {
        rawmem[Int(address)] = byte
    }
    
    func write(word: UInt16, at address: UInt16) {
        rawmem[Int(address)] = word.upperByte
        rawmem[Int(address)+1] = word.lowerByte
    }
}
