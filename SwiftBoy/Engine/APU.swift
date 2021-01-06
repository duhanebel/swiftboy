//
//  APU.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 02/01/2021.
//

import Foundation

class Audio: Actor, MemoryMappable {
    
    var rawData: [UInt8] = Array<UInt8>(repeating: 0x00, count: 0x30)
    
    init() {
        /*[$FF10] = $80   ; NR10
         [$FF11] = $BF   ; NR11
         [$FF12] = $F3   ; NR12
         [$FF14] = $BF   ; NR14
         [$FF16] = $3F   ; NR21
         [$FF17] = $00   ; NR22
         [$FF19] = $BF   ; NR24*/
        rawData[0] = 0x80
        rawData[1] = 0xBF
        rawData[2] = 0xF3
        rawData[4] = 0xBF
        rawData[6] = 0x3F
        rawData[7] = 0x00
        rawData[9] = 0x80
        
        /*
         [$FF1A] = $7F   ; NR30
         [$FF1B] = $FF   ; NR31
         [$FF1C] = $9F   ; NR32
         [$FF1E] = $BF   ; NR33
         [$FF20] = $FF   ; NR41
         */
        rawData[10] = 0x7E
        rawData[11] = 0xFF
        rawData[12] = 0x9F
        rawData[14] = 0xBF
        rawData[16] = 0xFF
        
        /*
         [$FF21] = $00   ; NR42
         [$FF22] = $00   ; NR43
         [$FF23] = $BF   ; NR30
         [$FF24] = $77   ; NR50
         [$FF25] = $F3   ; NR51
         [$FF26] = $F1
         */
        rawData[17] = 0x00
        rawData[18] = 0x00
        rawData[19] = 0xBF
        rawData[20] = 0x77
        rawData[21] = 0xF3
        rawData[22] = 0xF1
         
    }
    func read(at address: UInt16) throws -> UInt8 {
        return rawData[Int(address)]
    }
    
    func write(byte: UInt8, at address: UInt16) throws {
        rawData[Int(address)] = byte
    }
    
    func tic() {
        
    }
}
