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
        
        let logo: [UInt8] = [0xce, 0xed, 0x66, 0x66, 0xcc, 0x0d, 0x00, 0x0b, 0x03, 0x73, 0x00, 0x83, 0x00, 0x0c, 0x00, 0x0d, 0x00, 0x08, 0x11, 0x1f, 0x88, 0x89, 0x00, 0x0e, 0xdc, 0xcc, 0x6e, 0xe6, 0xdd, 0xdd, 0xd9, 0x99, 0xbb, 0xbb, 0x67, 0x63, 0x6e, 0x0e, 0xec, 0xcc, 0xdd, 0xdc, 0x99, 0x9f, 0xbb, 0xb9, 0x33, 0x3e]
        for i in 0..<logo.count {
            rawmem[0x104+i] = logo[i]
        }
    }
    
    func read(at address: UInt16) throws -> UInt8 {
        guard address < rawmem.count else { throw MemoryError.outOfBounds(address, 0x00..<UInt16(rawmem.count)) }
        return rawmem[Int(address)]
    }
    
    func write(byte: UInt8, at address: UInt16) throws {
        throw MemoryError.readonly(address)
    }
    
}
