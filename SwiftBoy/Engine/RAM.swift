//
//  RAM.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 28/11/2020.
//

import Foundation

class RAM: MemoryMappable {
    private var rawmem: [UInt8]
    
    let size: Int
    
    init(size: Int) {
        self.size = size
        self.rawmem = Array<UInt8>(repeating: 0x0, count: size)
    }
    
    func read(at address: UInt16) throws -> UInt8 {
        guard address < rawmem.count else { throw MemoryError.outOfBounds(address, 0x00..<UInt16(rawmem.count)) }
        return rawmem[Int(address)]
    }
    
    func readWord(at address: UInt16) throws -> UInt16 {
        var word: UInt16 = 0
        word.lowerByte = try read(at: address)
        word.upperByte = try read(at: address + 1)
        return word
    }
    
    func write(byte: UInt8, at address: UInt16) throws {
        guard address < rawmem.count else { throw MemoryError.outOfBounds(address, 0x00..<UInt16(rawmem.count)) }
        rawmem[Int(address)] = byte
    }
    
    func write(word: UInt16, at address: UInt16) throws {
        try write(byte: word.lowerByte, at: address)
        try write(byte: word.upperByte, at: address + 1)
    }
}
