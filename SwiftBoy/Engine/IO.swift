//
//  IO.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 30/11/2020.
//

import Foundation

/*
 I/O Registers layout:
   Addr | Name | RW | Name
   -----+------+----+-------------------------------------------
   FFOO | P1   | RW | Register for reading joy pad info
   FF01 | SB   | RW | Serial transfer data
   FF02 | SBCL | RW | Serial transfer data clock
    ..  | Unused
   FF04 | DIV  | RW | Divider register ?
   FF05 | TIMA | RW | Timer counter (int when overflow)
   FF06 | TMA  | RW | Timer modulo (loaded after reset)
   FF07 | TAC  | RW | Timer control (start/stop + clock select)
    ..  | Unused
   FF0F | IF   | RW | Interrupt flag
   FF10 |      |    | \
    ..  |      |    |  |-- Audio
   FF3F |      |    | /
   FF40 |      |    | \
    ..  |      |    |  |-- Video
   FF4B |      |    | /
   FF50 | BOOT | -- | BootROM toggle register (write 1 to unload the bootROM)
     .. | Unused
   FFFF | IE   | RW | Interrupt enable
   XXXX | IME  | -- | Interrupt master enable
 */

class InterruptRegister: MemoryMappable {
    private var rawmem: UInt8
    
    var VBlank: Bool {
        get { return rawmem[0].boolValue }
        set { rawmem[0] = newValue.intValue }
    }
    
    var LCDStat: Bool {
        get { return rawmem[1].boolValue }
        set { rawmem[1] = newValue.intValue }
    }
    
    var timer: Bool {
        get { return rawmem[2].boolValue }
        set { rawmem[2] = newValue.intValue }
    }
    
    var serial: Bool {
        get { return rawmem[3].boolValue }
        set { rawmem[3] = newValue.intValue }
    }
    
    var joypad: Bool {
        get { return rawmem[4].boolValue }
        set { rawmem[4] = newValue.intValue }
    }
    
    func read(at address: UInt16) throws -> UInt8 {
        return rawmem
    }
    
    func write(byte: UInt8, at address: UInt16) throws {
        rawmem = byte
    }
    
    var allOff: Bool {
        return rawmem == 0
    }
    
    init(initialValue: UInt8 = 0x0) {
        rawmem = initialValue
    }
}

class IO: MemoryMappable {
    struct MemoryLocations {
        static let joypad = UInt16(0xFF00)
        static let serial = UInt16(0xFF01)...UInt16(0xFF02)
        static let divider = UInt16(0xFF04)
        static let timer = UInt16(0xFF05)...UInt16(0xFF07)
        static let interruptFlag = UInt16(0xFF0F)
        static let audio = UInt16(0xFF10)...UInt16(0xFF3F)
        static let video = UInt16(0xFF40)...UInt16(0xFF4B)
        static let bootROMRegister: UInt16 = 0xFF50
        static let interruptEnabled: UInt16 = 0xFFFF
    }
   
    /* TODO: add these
     FF6C - Undocumented (FEh) - Bit 0 (Read/Write) - CGB Mode Only
     FF72 - Undocumented (00h) - Bit 0-7 (Read/Write)
     FF73 - Undocumented (00h) - Bit 0-7 (Read/Write)
     FF74 - Undocumented (00h) - Bit 0-7 (Read/Write) - CGB Mode Only
     FF75 - Undocumented (8Fh) - Bit 4-6 (Read/Write)
     FF76 - Undocumented (00h) - Always 00h (Read Only)
     FF77 - Undocumented (00h) - Always 00h (Read Only)
     These are undocumented CGB Registers. The numbers in brackets () indicate the initial values. Purpose of these registers is unknown (if any). Registers FF6C and FF74 are always FFh if the CGB is in Non CGB Mode.
     */
    var joypad: MemoryMappable
    var serial: MemoryMappable
    var divider: MemoryMappable
    var timer: MemoryMappable
    var interruptFlag: MemoryMappable
    var audio: MemoryMappable
    var video: MemoryMappable
    let bootROMRegister: MemoryMappable
    var interruptEnabled: MemoryMappable
    
    init(joypad: MemoryMappable, serial: MemoryMappable, divider: MemoryMappable, timer: MemoryMappable,
         interruptFlag: MemoryMappable, audio: MemoryMappable, video: MemoryMappable, interruptEnabled: MemoryMappable) {
        self.joypad = joypad
        self.serial = serial
        self.divider = divider
        self.timer = timer
        self.interruptFlag = interruptFlag
        self.audio = audio
        self.video = AddressTranslator(memory: video, offset: MemoryLocations.video.lowerBound)
        // bit 7-1 Unimplemented: Read as 1
        // bit 0 BOOT_OFF: Boot ROM lock bit
        self.bootROMRegister = MemorySegment(from: 0xFF50, size: 1)
        try! self.bootROMRegister.write(byte: 0xFE, at: 0x0)
        
        self.interruptEnabled = interruptEnabled
        
    }
    
//    private var handlers: [UInt16:MemoryMappable] = [:]
//    private func register(_ handler: MemoryMappable, for address: MemoryLocations) {
//        handler[address.rawValue] = handler
//    }
    
    private func map(address: UInt16) throws -> (MemoryMappable, Word) {
        switch(address) {
        case MemoryLocations.joypad:
            return (joypad, 0x00)
        case MemoryLocations.serial:
            return (serial, 0x00)
        case MemoryLocations.divider:
            return (divider, 0x00)
        case MemoryLocations.timer:
            return (timer, address)//- MemoryLocations.timer.lowerBound)
        case MemoryLocations.interruptFlag:
            return (interruptFlag, 0x00)
        case MemoryLocations.audio:
            return (audio, address - MemoryLocations.audio.lowerBound)
        case MemoryLocations.video:
            return (video, address)
        case MemoryLocations.bootROMRegister:
            return (bootROMRegister, 0x00)
        case MemoryLocations.interruptEnabled:
            return (interruptEnabled, 0x00)
        default:
            throw MemoryError.invalidAddress(address)
        }
    }
    
    func read(at address: UInt16) throws -> UInt8 {
        let (dest, localAddress) = try map(address: address)
        return try dest.read(at: localAddress)
    }
    
    func write(byte: UInt8, at address: UInt16) throws {
        let (dest, localAddress) = try map(address: address)
        try dest.write(byte: byte, at: localAddress)
    }
}
