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
    ..  | Unused
   FF04 | DIV  | RW | Divider register ?
   FF05 | TIMA | RW | Timer counter (int when overflow)
   FF06 | TMA  | RW | Timer modulo (loaded after reset)
   FF07 | TAC  | RW | Timer control (start/stop + clock select)
    ..  | Unused
   FF0F | IF   | RW | Interrupt flag
   FF10 | Audio
    ..  | Audio
   FF3F | Audio
   FF41 | Video
    ..  | Video
   FF4B | Video
   FFFF | IE   | RW | Interrupt enable
   XXXX | IME  | -- | Interrupt master enable
 */

class IO: MemoryMappable {
    struct MemoryLocations {
        static let joypad = UInt16(0xFF00)
        static let serial = UInt16(0xFF01)
        static let divider = UInt16(0xFF04)
        static let timer = UInt16(0xFF05)...UInt16(0xFF07)
        static let interruptFlag = UInt16(0xFF0F)
        static let audio = UInt16(0xFF10)...UInt16(0xFF3F)
        static let video = UInt16(0xFF41)...UInt16(0xFF4B)
        static let interruptEnabled = UInt16(0xFFFF)
    }
    
    var joypad: MemoryMappable
    var serial: MemoryMappable
    var divider: MemoryMappable
    var timer: MemoryMappable
    var interruptFlag: MemoryMappable
    var audio: MemoryMappable
    var video: MemoryMappable
    var interruptEnabled: MemoryMappable
    
    init(joypad: MemoryMappable, serial: MemoryMappable, divider: MemoryMappable, timer: MemoryMappable,
         interruptFlag: MemoryMappable, audio: MemoryMappable, video: MemoryMappable, interruptEnabled: MemoryMappable) {
        self.joypad = joypad
        self.serial = serial
        self.divider = divider
        self.timer = timer
        self.interruptFlag = interruptFlag
        self.audio = audio
        self.video = video
        self.interruptEnabled = interruptEnabled
    }
    
    private func map(address: UInt16) throws -> (MemoryMappable, Word) {
        switch(address) {
        case MemoryLocations.joypad:
            return (joypad, 0x00)
        case MemoryLocations.serial:
            return (serial, 0x00)
        case MemoryLocations.divider:
            return (divider, 0x00)
        case MemoryLocations.timer:
            return (timer, address - MemoryLocations.timer.lowerBound)
        case MemoryLocations.interruptFlag:
            return (interruptFlag, address - MemoryLocations.interruptFlag)
        case MemoryLocations.audio:
            return (audio, address - MemoryLocations.audio.lowerBound)
        case MemoryLocations.video:
            return (video, address - MemoryLocations.video.lowerBound)
        case MemoryLocations.interruptEnabled:
            return (interruptEnabled, address - MemoryLocations.interruptEnabled)
        default:
            throw MemoryError.invalidAddress(address)
        }
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
        let (dest, localAddress) = try map(address: address)
        try dest.write(byte: byte, at: localAddress)
    }
    func write(word: UInt16, at address: UInt16) throws {
        let (dest, localAddress) = try map(address: address)
        try dest.write(word: word, at: localAddress)
    }
}
