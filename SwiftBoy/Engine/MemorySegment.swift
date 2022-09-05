//
//  RAM.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 28/11/2020.
//

import Foundation

class MemorySegment: MemoryMappable {
    private var data: ContiguousArray<UInt8>
    
    var size: Int  { data.count }
    
    var mappedTo: Range<Address>
    
    init(from: Address, size: Int) {
//        assert(size < UInt16.max, "Can't map more than 2^16 bytes")
//        assert(from+UInt16(size) < UInt16.max, "Mapping outside of total addressable space (2^16 bytes)")
        self.data = ContiguousArray<UInt8>(repeating: 0x0, count: size)
        self.mappedTo = from..<(from+UInt16(size))
    }
    
    private func absoluteToRelativeAddress(absolute address: Address) throws -> Address {
        return address
        // TODO: decide where we do the transaltion
        assert(mappedTo.upperBound > address && mappedTo.lowerBound <= address)
        return address - mappedTo.lowerBound
    }
    
    func read(at address: UInt16) throws -> UInt8 {
        let relAddress = try absoluteToRelativeAddress(absolute: address)
        return data[Int(relAddress)]
    }
    
    func write(byte: UInt8, at address: UInt16) throws {
        let relAddress = try absoluteToRelativeAddress(absolute: address)
        data[Int(relAddress)] = byte
    }
}

//class Register: MemoryMappable {
//    private var data: UInt8
//    
//    var size = 1
//    
//    init(data: UInt8) {
//        self.data = data
//    }
//    
//    func read(at address: UInt16) throws -> UInt8 {
//        guard address == 0 else { throw MemoryError.outOfBounds(address, 0x00..0x00) }
//        return data
//    }
//    
//    func write(byte: UInt8, at address: UInt16) throws {
//        guard address < data.count else { throw MemoryError.outOfBounds(address, 0x00..0x00) }
//        data = byte
//    }
//}

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
