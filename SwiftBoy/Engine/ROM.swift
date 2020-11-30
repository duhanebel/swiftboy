//
//  ROM.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 29/11/2020.
//

import Foundation


class ROM: MemoryMappable {
    var rawmem: [UInt8] = []
     
    func load(url: URL) throws {
        rawmem = try Array<UInt8>(Data(contentsOf: url))
    }
    
    func read(at address: UInt16) -> UInt8 {
        return rawmem[Int(address)]
    }
    
    func readWord(at address: UInt16) -> UInt16 {
        var word: UInt16 = 0
        word.lowerByte = rawmem[Int(address)]
        word.upperByte = rawmem[Int(address)+1]
        return word
    }
    
    func write(byte: UInt8, at address: UInt16) {
        
    }
    
    func write(word: UInt16, at address: UInt16) {
        
    }
    
}
