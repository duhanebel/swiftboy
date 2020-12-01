//
//  ROM.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 29/11/2020.
//

import Foundation


class ROM: MemoryMappable {
    private var rawmem: [UInt8] = []
     
//    class func emptyRom() -> ROM {
//        let rom = ROM()
//        rom.rawmem = Array<UInt8>(repeating: 0xFF, count: 0x4FFF)
//        return rom
//    }
    
    func load(url: URL) throws {
        rawmem = try Array<UInt8>(Data(contentsOf: url))
    }
    
    func loadEmpty() {
        rawmem = Array<UInt8>(repeating: 0xFF, count: 0x4FFF)
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
        throw MemoryError.readonly(address)
    }
    
    func write(word: UInt16, at address: UInt16) throws {
        throw MemoryError.readonly(address)
    }
    
}
