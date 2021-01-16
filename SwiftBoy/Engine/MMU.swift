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
}
protocol MemoryMappableW {
    func write(byte: UInt8, at address: UInt16) throws
}
protocol MemoryMappable: MemoryMappableR, MemoryMappableW {}

//protocol Interceptor {
//    static var affectedRange: Range<Address> { get }
//    var allowWrite: Bool { get }
//    func process(byte: Byte, at: Address)
//}
//
//struct BootRomUnload: Interceptor {
//    static var affectedRange: Range<Address> = IO.MemoryLocations.bootROMRegister...IO.MemoryLocations.bootROMRegister
//    var allowWrite = false
//
//    private var mmu: MMU
//    func process(byte: Byte, at: Address) {
//        if byte == 1 {
//            mmu.biosROM = nil
//        }
//    }
//}

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

class MMU: MemoryMappable {
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
    }
    
    var rom: MemoryMappable! = ROM()
    var biosROM: MemoryMappable?
    var switchableRom: MemoryMappable! = ROM()
    let ram: MemoryMappable = RAM(size: 0x2000)
    let extRam: MemoryMappable = RAM(size: 0x2000)

    let hram: MemoryMappable = RAM(size: 0x80)

    let vram: MemoryMappable
    let sram: MemoryMappable
    let io: MemoryMappable
    
    private var memoryObservers: [MemoryObserver] = []
    
    func register(observer: MemoryObserver) {
        memoryObservers.append(observer)
    }
    
    func notifyObservers(for address: Address) {
        for observer in memoryObservers {
            if observer.observedRange.contains(address) {
                observer.memoryChanged(sender: self)
            }
        }
    }
    
    init(rom: MemoryMappable?, biosROM: MemoryMappable?, switchableRom: MemoryMappable?,
         vram: MemoryMappable, sram: MemoryMappable, io: MemoryMappable) {
        
        self.rom = rom
        self.biosROM = biosROM
        
        if let switchableRom = switchableRom {
            self.switchableRom = switchableRom
        } else {
            self.switchableRom = rom
        }

        self.vram = vram
        self.sram = sram
        self.io = io
    }
    
    func read(at address: UInt16) throws -> UInt8 {
        let (dest, localAddress) = try map(address: address)
        return try dest.read(at: localAddress)
    }
    
    //private var writeInterceptors: [Range<UInt16>:Interceptor] = [:]
    
    func write(byte: UInt8, at address: UInt16) throws {
        // Writing the value of 1 to the address 0xFF50 unmaps the boot ROM.
        if(address ==  IO.MemoryLocations.bootROMRegister && byte == 1) {
            biosROM = nil
            return
        }
        
        // TODO timing: this take 160ms - does it need to be accounted for anywhere?
        if(address == 0xFF46) {
            // The source address written to 0xFF46 is divided by 0x100 (256)
            let sourceAddress = UInt16(byte) << 8
            try performDmaTransfer(from: sourceAddress)
            return
        }
        let (dest, localAddress) = try map(address: address)
        try dest.write(byte: byte, at: localAddress)
        
        notifyObservers(for: address)
    }
    
    private func performDmaTransfer(from address: Address) throws {
        var sourceAddress = address
        for sramCounter in MemoryRanges.sram {
            let sourceByte = try read(at:sourceAddress)
            try sram.write(byte: sourceByte, at: sramCounter - MemoryRanges.sram.lowerBound)
            sourceAddress += 1
        }
    }
    
    private func map(address: UInt16) throws -> (MemoryMappable, Word) {
        switch(address) {
        case MemoryRanges.biosROM:
            guard let biosROM = biosROM else { fallthrough }
            return (biosROM, address)
        case MemoryRanges.rom:
            return (rom, address)
        case MemoryRanges.switchableRom:
            return (switchableRom, address)
        case MemoryRanges.vram:
            return (vram, address - MemoryRanges.vram.lowerBound)
        case MemoryRanges.extRam:
            return (extRam, address - MemoryRanges.extRam.lowerBound)
        case MemoryRanges.workRam:
            return (ram, address - MemoryRanges.workRam.lowerBound)
        case MemoryRanges.workRamEcho: // ram mirror
            return (ram, address - MemoryRanges.workRamEcho.lowerBound)
        case MemoryRanges.sram:
            return (sram, address - MemoryRanges.sram.lowerBound)
        case MemoryRanges.unusable:
            throw MemoryError.invalidAddress(address)
        case MemoryRanges.io:
            return (io, address) //TODO: this is inconsistent - move bounds to destination
        case MemoryRanges.hram:
            return (hram, address - MemoryRanges.hram.lowerBound)
        case 0xFFFF: //TODO: do better
            return(io, 0xFFFF)
        default:
            throw MemoryError.invalidAddress(address)
        }
    }
}
