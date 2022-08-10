//
//  Sprite.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 24/12/2020.
//

import Foundation

/*
 The Sprite RAM (OAM) is 0xA0 bytes long and contains 40 sprites of 4bytes each.
 Each sprite looks like this:
 
   Byte | Description
   -----+---------------------------------------------------------------------------
     0  | Y-coordinate of top-left corner (Value stored is Y-coordinate minus 16)
     1  | X-coordinate of top-left corner (Value stored is X-coordinate minus 8)
     2  | Data tile number (index into the tile ram)
     3  | Flags
 
 Flags layout:
    Bit | Description                | Value 0          | Value 1
   -----+----------------------------+------------------+-------------------------------------
     7  | Sprite/background priority | Above background | Below background (except colour 0)
     6  | Y-flip                     | No change        | Vertically flipped
     5  | X-flip                     | No change        | Horizontally flipped
     4  | Palette                    | OBJ palette #0   | OBJ palette #1
   -----+----------------------------+------------------+-------------------------------------
     3  | VRAM bank (GBC Only)
     2  | Palette # bit 3 (GBC only)
     1  | Palette # bit 2 (GBC only)
     0  | Palette # bit 1 (GBC only)
 */

struct Sprite {
    enum MemoryLayout {
        static let y = 0
        static let x = 1
        static let tileIndex = 2
        static let flags = 3
        enum Flags {
            static let priority = 7
            static let yFlip = 6
            static let xFlip = 5
            static let paletteIndex = 4
        }
    }
    
    struct Flags {
        private let bits: UInt8
        init(bits: UInt8) { self.bits = bits }
        var backgroundPriority: Bool { return bits[MemoryLayout.Flags.priority].boolValue }
        var yFlip: Bool { return bits[MemoryLayout.Flags.yFlip].boolValue }
        var xFlip: Bool { return bits[MemoryLayout.Flags.xFlip].boolValue }
        var paletteIndex: UInt8 { return bits[MemoryLayout.Flags.paletteIndex] }
    }
    
    private let bytes: [UInt8]
    var memOffset: UInt8
    var tileIndexMemOffset: UInt8 { memOffset + UInt8(MemoryLayout.tileIndex) }
    var x: UInt8 { bytes[MemoryLayout.x] }
    var y: UInt8 { bytes[MemoryLayout.y] }
    var tileIndex: UInt8  { bytes[MemoryLayout.tileIndex] }
    var flags: Flags { Flags(bits: bytes[MemoryLayout.flags]) }
    
    var height: UInt8
    let width = 8
    
    init(memOffset: UInt8, bytes: [UInt8], height: UInt8) {
        self.memOffset = memOffset
        self.bytes = bytes
        self.height = height
    }
    
    func isVisibleAt(x: Int) -> Bool {
        // A sprite at 0 is completely invisible.
        //The first pixel of the right end is visible at x == 1
        return self.x <= x + 8 && x < self.x
        //    self.x - 8 < x < self.x
    }
    
    func isVisibleAt(y: Int) -> Bool {
        return (self.y <= y + 16 && y + 16 < self.y + self.height)
        //self.y - 16 < y < self.y - 16 + self.height
    }
}
