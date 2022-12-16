//
//  Register.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 16/12/2022.
//

import Foundation

class Register: MemoryMappable {
    var data: Byte = 0
    private var mappedTo: Address
    
    let size = 1

    init(mappedTo: Address) {
        self.mappedTo = mappedTo
    }

    func read(at address: UInt16) throws -> UInt8 {
        guard address == mappedTo else { throw MemoryError.outOfBounds(address, UInt16(mappedTo)..<UInt16(mappedTo+1)) }
        return data
    }

    func write(byte: UInt8, at address: UInt16) throws {
        guard address == mappedTo else { throw MemoryError.outOfBounds(address, UInt16(mappedTo)..<UInt16(mappedTo+1)) }
        data = byte
       
    }
}
