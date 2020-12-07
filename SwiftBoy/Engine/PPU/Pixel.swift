//
//  Pixel.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 06/12/2020.
//

import Foundation

/*
 Gameboy pixels can only have 4 colors:
 +------+------------+
 | 0b11 | white      |
 | 0b10 | dark-gray  |
 | 0b01 | light-gray |
 | 0b00 | black      |
 +------+------------+
 */
enum Pixel: UInt8, ExpressibleByNilLiteral {
    case black     = 0b00
    case darkGray  = 0b10
    case lightGray = 0b01
    case white     = 0b11
    
    init(nilLiteral: ()) {
        self = .white
    }
    
    var grayscaleValue: UInt8 {
        switch(self) {
        case .black:
            return 0x00
        case .darkGray:
            return 0x55
        case .lightGray:
            return 0xAA
        case .white:
            return 0xFF
        }
    }
}
