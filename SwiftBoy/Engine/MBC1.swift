//
//  MBC1.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 30/12/2020.
//

import Foundation

class MBC1: MemoryController, MemoryMappable {
    struct MemoryAddresses {
        static let ROMBank: Range<UInt16> = 0x4000..<0x8000
        static let RAMBank: Range<UInt16> = 0xA000..<0xC000
        static let RAMEnable: Range<UInt16> = 0x0000..<0x2000
        static let ROMBankLow: Range<UInt16> = 0x2000..<0x4000
        static let ROMHiRamBank: Range<UInt16> = 0x4000..<0x6000
        static let ROMRAMMode: Range<UInt16> = 0x6000..<0x8000
    }
    
    var bankNumber: Byte = 1
    
    func addressFor(address: Address) -> Address {
        assert(address >= 0x4000, "Trying to switch a non switchable bank")
        return (address - 0x4000) + (0x4000 * UInt16(bankNumber))
    }
    
    func read(at address: UInt16) throws -> UInt8 {
        return 0
    }
    
    func write(byte: UInt8, at address: UInt16) throws {
        switch(address) {
        case MemoryAddresses.ROMBankLow:
            // Writing to this range will specify the lower 5 bits of the bank
            let lowBank = (byte & 0b0001_1111)
            if lowBank == 0 {
                bankNumber |= 1
            } else {
                bankNumber |= lowBank
            }
        case MemoryAddresses.ROMHiRamBank:
            let hiBank = (byte & 0b0000_0011)
            if hiBank == 0 {
                bankNumber &= 0b0001_1111
            } else {
                bankNumber |= (hiBank << 5)
            }
        default:
            break
        }
    }
    
    //let rom: ROM
    
  //  init(rom: ROM) {
  //      self.rom = rom
  //  }

}
