//
//  APURegisters.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 22/11/2022.
//

import Foundation



/*
 APU Registers:
 Bit-layout
 Name | Addr | 7654 3210 | Init | Description
 -----+------+-----------+------+---------------------------------
 Pulse 1:
 NR10 | FF10 | -PPP NSSS | 0x80 | Sweep period, direction, shift
 NR11 | FF11 | DDLL LLLL | 0xBF | Duty, Length load (64-L)
 NR12 | FF12 | VVVV APPP | 0xF3 | Starting volume, Envelope add mode, period
 NR13 | FF13 | FFFF FFFF | 0x00 | Frequency LSB
 NR14 | FF14 | TL-- -FFF | 0xBF | Trigger, Length enable, Frequency MSB
 
 Pulse 2:
 ---- | FF15 | ---- ---- | ---- | Not used
 NR21 | FF16 | DDLL LLLL | 0x3F | Duty, Length load (64-L)
 NR22 | FF17 | VVVV APPP | 0x00 | Starting volume, Envelope add mode, period
 NR23 | FF18 | FFFF FFFF | 0x00 | Frequency LSB
 NR24 | FF19 | TL-- -FFF | 0xBF | Trigger, Length enable, Frequency MSB
 
 Wave:
 NR30 | FF1A | E--- ---- | 0x7F | DAC power
 NR31 | FF1B | LLLL LLLL | 0xFF | Length load (256-L)
 NR32 | FF1C | -VV- ---- | 0x9F | Volume code (00=0%, 01=100%, 10=50%, 11=25%)
 NR33 | FF1D | FFFF FFFF | 0x00 | Frequency LSB
 NR34 | FF1E | TL-- -FFF | 0xBF | Trigger, Length enable, Frequency MSB
 
 Noise:
 ---- | FF1F | ---- ---- | ---- | Not used
 NR41 | FF20 | --LL LLLL | 0xFF | Length load (64-L)
 NR42 | FF21 | VVVV APPP | 0x00 | Starting volume, Envelope add mode, period
 NR43 | FF22 | SSSS WDDD | 0x00 | Clock shift, Width mode of LFSR, Divisor code
 NR44 | FF23 | TL-- ---- | 0xBF | Trigger, Length enable
 
 Control/Status:
 NR50 | FF24 | ALLL BRRR | 0x77 | Vin L enable, Left vol, Vin R enable, Right vol
 NR51 | FF25 | 4321 4321 | 0xF3 | Left enables, Right enables
 NR52 | FF26 | P--- 4321 | 0xF1 | Power control/status, Channel length statuses

 Wave pattern ram:
 FF30–FF3F   | 1111 2222 | ---- | Wave RAM is 16 bytes long; each byte holds two                                                                  “samples”, each 4 bits.
 */

class APURegisters: MemoryMappable {
    struct MemoryLocations  {
        // Pulse1 registers
        static let NR10 = Address(0xFF10)
        static let NR11 = Address(0xFF11)
        static let NR12 = Address(0xFF12)
        static let NR13 = Address(0xFF13)
        static let NR14 = Address(0xFF14)
        
        // Pulse 2 registers
        static let NR20 = Address(0xFF15)
        static let NR21 = Address(0xFF16)
        static let NR22 = Address(0xFF17)
        static let NR23 = Address(0xFF18)
        static let NR24 = Address(0xFF19)
        
        // Wave registers
        static let NR30 = Address(0xFF1A)
        static let NR31 = Address(0xFF1B)
        static let NR32 = Address(0xFF1C)
        static let NR33 = Address(0xFF1D)
        static let NR34 = Address(0xFF1E)
        
        // Noise registers
        static let NR40 = Address(0xFF1F)
        static let NR41 = Address(0xFF20)
        static let NR42 = Address(0xFF21)
        static let NR43 = Address(0xFF22)
        static let NR44 = Address(0xFF23)
        
        // control/config registers
        static let NR50 = Address(0xFF24)
        static let NR51 = Address(0xFF25)
        static let NR52 = Address(0xFF26)
        
        static let pulse1 = NR10...NR14
        static let pulse2 = NR20...NR24
        static let wave   = NR30...NR34
        static let noise  = NR40...NR44
        static let conf   = NR50...NR52
        static let unused = Address(0xFF27)...Address(0xFF29)
        static let wavePattern = Address(0xFF30)...Address(0xFF3F)
        static let range = NR10..<wavePattern.upperBound+1
    }
    
    var pulse1 = Pulse(baseAddress: MemoryLocations.pulse1.lowerBound)
    var pulse2 = Pulse(baseAddress: MemoryLocations.pulse2.lowerBound)
    var wave = Wave()
    var noise = Noise()
    var conf = Config()
    
    func read(at address: UInt16) throws -> UInt8 {
        switch(address) {
        case MemoryLocations.pulse1:
            return try pulse1.read(at: address)
        case MemoryLocations.pulse2:
            return try pulse2.read(at: address)
        case MemoryLocations.wave:
            return try wave.read(at: address)
        case MemoryLocations.wavePattern:
            return try wave.read(at: address)
        case MemoryLocations.noise:
            return try noise.read(at: address)
        case MemoryLocations.conf:
            return try conf.read(at: address)
        default:
            throw MemoryError.invalidAddress(address)
        }
    }
    
    func write(byte: UInt8, at address: UInt16) throws {
        switch(address) {
        case MemoryLocations.pulse1:
            return try pulse1.write(byte: byte, at: address)
        case MemoryLocations.pulse2:
            return try pulse2.write(byte: byte, at: address)
        case MemoryLocations.wave:
            return try wave.write(byte: byte, at: address)
        case MemoryLocations.wavePattern:
            return try wave.write(byte: byte, at: address)
        case MemoryLocations.noise:
            return try noise.write(byte: byte, at: address)
        case MemoryLocations.conf:
            return try conf.write(byte: byte, at: address)
        default:
            throw MemoryError.invalidAddress(address)
        }
    }
}
