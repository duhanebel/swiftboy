//
//  MMU.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 28/11/2020.
//

import Foundation

enum MemoryError: Error {
    case readonly(UInt16)
    case invalidAddress(UInt16)
    case outOfBounds(UInt16, Range<UInt16>)
}

protocol MemoryMappableR {
    func read(at address: UInt16) throws -> UInt8
    func readWord(at address: UInt16) throws -> UInt16
}
protocol MemoryMappableW {
    func write(byte: UInt8, at address: UInt16) throws
    func write(word: UInt16, at address: UInt16) throws
}
protocol MemoryMappable: MemoryMappableR, MemoryMappableW {}

struct InterruptRegister: MemoryMappableR {
    func read(at address: UInt16) -> UInt8 {
        return reg
    }
    
    func readWord(at address: UInt16) -> UInt16 {
        return UInt16(reg)
    }
    
    private var reg: Byte
    
    var vBlankEnabled: Bool {
        get { return reg[0].boolValue }
        set { reg[0] = newValue.intValue }
    }
        
    var LCDCEnabled: Bool {
        get { return reg[1].boolValue }
        set { reg[1] = newValue.intValue }
    }
    
    var TimerOverflowEnabled: Bool {
        get { return reg[2].boolValue }
        set { reg[2] = newValue.intValue }
    }
    
    var SerialIOTransferComplete: Bool {
        get { return reg[3].boolValue }
        set { reg[3] = newValue.intValue }
    }
    
    var HiToLowJoypadTransition: Bool {
        get { return reg[4].boolValue }
        set { reg[4] = newValue.intValue }
    }
}

/*
 Memory layout:
   Start | End  | Description                     | Notes
   ------+------+---------------------------------+---------------------------------------------------------------
    0000 | 3FFF | 16KB ROM bank 00                | From cartridge, usually a fixed bank
    4000 | 7FFF | 16KB ROM Bank 01~NN             | From cartridge, switchable bank via MBC (if any)
    8000 | 9FFF | 8KB Video RAM (VRAM)            | Only bank 0 in Non-CGB mode, switchable bank 0/1 in CGB mode
    A000 | BFFF | 8KB External RAM                | In cartridge, switchable bank if any
    C000 | CFFF | 4KB Work RAM (WRAM) bank 0      |
    D000 | DFFF | 4KB Work RAM (WRAM) bank 1~N    | Only bank 1 in Non-CGB mode, switchable bank 1~7 in CGB mode
    E000 | FDFF | Mirror of C000~DDFF (ECHO RAM)  | Typically not used
    FE00 | FE9F | Sprite attribute table (OAM)    |
    FEA0 | FEFF | Not Usable                      |
    FF00 | FF7F | I/O Registers                   |
    FF80 | FFFE | High RAM (HRAM)                 |
    FFFF | FFFF | Interrupts Enable Register (IE) |
 */

class MMU {
    struct MemoryRanges {
        static let biosROM = UInt16(0x0000)..<UInt16(0x0100)
        static let rom = UInt16(0x0000)..<UInt16(0x4000)
        static let switchableRom = UInt16(0x4000)..<UInt16(0x8000)
        static let vram = UInt16(0x8000)..<UInt16(0xA000)
        static let extRam = UInt16(0xA000)..<UInt16(0xC000)
        static let workRam = UInt16(0xC000)..<UInt16(0xE000)
        static let workRamEcho = UInt16(0xE000)..<UInt16(0xFE00)
        static let sram = UInt16(0xFE00)..<UInt16(0xFEA0)
        static let unusable = UInt16(0xFEA0)..<UInt16(0xFF00)
        static let io = UInt16(0xFF00)..<UInt16(0xFF80)
        static let hram = UInt16(0xFF80)..<UInt16(0xFFFF)
        static let InterruptRegister = UInt16(0xFFFF)...UInt16(0xFFFF)
    }
    
    let rom: ROM = ROM()
    var biosROM: ROM? = ROM()
    let switchableRom: ROM
    let ram: MemoryMappable = RAM(size: 0x2000)
    let extRam: MemoryMappable = RAM(size: 0x2000)
    let workRam: MemoryMappable = RAM(size: 0x2000)

    let vram: MemoryMappable = RAM(size: 0x2000)
    let sram: MemoryMappable = RAM(size: 0x2000)

    let io: MemoryMappable = RAM(size: 0x2000)
    let ir: MemoryMappable = RAM(size: 0x20)
    
    init() {
        self.switchableRom = rom
    }
    func read(at address: UInt16) throws -> UInt8 {
        let (dest, localAddress) = try map(address: address)
        return try dest.read(at: localAddress)
    }
    
    func readWord(at address: UInt16) throws -> UInt16 {
        let (dest, localAddress) = try map(address: address)
        return try dest.readWord(at: localAddress)
    }
    
    func write(byte: UInt8, at address: UInt16) throws {
        // Writing the value of 1 to the address 0xFF50 unmaps the boot ROM.
        if(address ==  0xFF50 && byte == 1) {
            biosROM = nil
            return
        }
        let (dest, localAddress) = try map(address: address)
        try dest.write(byte: byte, at: localAddress)
    }
    func write(word: UInt16, at address: UInt16) throws {
        let (dest, localAddress) = try map(address: address)
        try dest.write(word: word, at: localAddress)
    }
    
    private func map(address: UInt16) throws -> (MemoryMappable, Word) {
        switch(address) {
        case MemoryRanges.biosROM:
            guard let biosROM = biosROM else { fallthrough }
            return (biosROM, address)
        case MemoryRanges.rom:
            return (rom, address)
        case MemoryRanges.switchableRom:
            return (switchableRom, address - MemoryRanges.switchableRom.lowerBound)
        case MemoryRanges.vram:
            return (vram, address - MemoryRanges.vram.lowerBound)
        case MemoryRanges.extRam:
            return (extRam, address - MemoryRanges.extRam.lowerBound)
        case MemoryRanges.workRam:
            return (workRam, address - MemoryRanges.workRam.lowerBound)
        case MemoryRanges.workRamEcho: // wram mirror
            return (workRam, address - MemoryRanges.workRamEcho.lowerBound)
        case MemoryRanges.sram:
            return (sram, address - MemoryRanges.sram.lowerBound)
        case MemoryRanges.unusable:
            throw MemoryError.invalidAddress(address)
        case MemoryRanges.io:
            return (io, address - MemoryRanges.io.lowerBound)
        case MemoryRanges.hram:
            return (ram, address - MemoryRanges.hram.lowerBound)
        case MemoryRanges.InterruptRegister:
            return (ir, 0x0000)
        default:
            throw MemoryError.invalidAddress(address)
        }
    }
}
