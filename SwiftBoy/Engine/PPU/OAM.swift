//
//  OAM.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 22/12/2020.
//

import Foundation

final class OAM: MemoryMappable {
    private var data: [UInt8]
    
    var spritesCount: Int {
        get { return data.count / 4 }
    }
    
    init() {
        self.data = Array<UInt8>(repeating: 0x0, count: 0xA0)
    }
    
    func sprite(of height: Int, at index: Int) -> Sprite {
        let spriteSize = 4
        let spriteOffset = spriteSize * index
        assert((spriteOffset + 3) < data.count, "Sprite index out of bounds \(spriteOffset) of \(data.count)")
        return Sprite(memOffset: UInt8(spriteOffset),
                      bytes: Array(data[spriteOffset...(spriteOffset + 3)]),
                      height: UInt8(height))
    }
    
    func read(at address: UInt16) throws -> UInt8 {
        guard address < data.count else { throw MemoryError.outOfBounds(address, 0x00..<UInt16(data.count)) }
        return data[Int(address)]
    }
    
    func write(byte: UInt8, at address: UInt16) throws {
        guard address < data.count else { throw MemoryError.outOfBounds(address, 0x00..<UInt16(data.count)) }
        data[Int(address)] = byte
    }
}

extension OAM {
    func sprites(of height: Int, at line: Int) -> [Sprite] {
        var sprites: [Sprite] = []
        sprites.reserveCapacity(spritesCount)
        for s in 0..<spritesCount {
            let sprite = self.sprite(of: height, at: s)
            // TODO: x 0 is just off screen on the left, y 0 is just off screen on the top
            // also sprites can be 8 or 16 high - configured once at game level
            if sprite.x > 0 &&
                sprite.isVisibleAt(y: line) {
                sprites.append(sprite)
            }
            if sprites.count >= 10 {
                return sprites
            }
        }
        return sprites
    }
}
