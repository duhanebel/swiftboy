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
    
    func write(byte: UInt8, at address: UInt16) throws {
        guard address < rawmem.count else { throw MemoryError.outOfBounds(address, 0x00..<UInt16(rawmem.count)) }
        rawmem[Int(address)] = byte
    }
}

class MemorySegment: MemoryMappable {
    private var data: [UInt8]
    
    var size: Int {
        get { return data.count }
    }
    
    init(size: Int) {
        self.data = Array<UInt8>(repeating: 0x0, count: size)
    }
    
    func read(at address: UInt16) throws -> UInt8 {
        guard address < data.count else { throw MemoryError.outOfBounds(address, 0x00..<UInt16(data.count)) }
        return data[Int(address)]
    }
    
    func write(byte: UInt8, at address: UInt16) throws {
        guard address < data.count else { throw MemoryError.outOfBounds(address, 0x00..<UInt16(data.count)) }
        data[Int(address)] = byte
    }
}

class AddressTranslator: MemoryMappable {
    private var memory: MemoryMappable
    private var offset: UInt16
    
    init(memory: MemoryMappable, offset: UInt16) {
        self.memory = memory
        self.offset = offset
    }
    
    func read(at address: UInt16) throws -> UInt8 {
        let localAddress = relativeAddress(for: address)
        return try memory.read(at: localAddress)
    }
    
    func write(byte: UInt8, at address: UInt16) throws {
        let localAddress = relativeAddress(for: address)
        try memory.write(byte: byte, at: localAddress)
    }
    
    private func relativeAddress(for address: UInt16) -> UInt16 {
        assert(address >= offset, "Address out of bounds")
        return address - offset
    }
}
