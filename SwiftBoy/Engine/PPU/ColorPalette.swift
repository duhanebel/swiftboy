//
//  ColorPalette.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 16/01/2021.
//

import Foundation

/*
 Gameboy pixels can only have 4 colors:
 +------+------------+
 | 0b00 | white      |
 | 0b10 | dark-gray  |
 | 0b01 | light-gray |
 | 0b11 | black      |
 +------+------------+
 */

struct ColorPalette {
    enum Color: UInt8 {
        case white     = 0b00 // dark why?
        case lightGray = 0b01
        case darkGray  = 0b10 // white why?
        case black     = 0b11
        
        var grayscaleValue: UInt8 {
            switch(self) {
            case .black:
                return 0xFF
            case .lightGray:
                return 0xAA
            case .darkGray:
                return 0x55
            case .white:
                return 0x00
            }
        }
    }
    
    let color0: Color
    let color1: Color
    let color2: Color
    let color3: Color
    
    init(color0: Byte, color1: Byte, color2: Byte, color3: Byte) {
        assert(color0 < 4 && color1 < 4 && color2 < 4 && color3 < 4, "Invalid color index for palette")
        self.color0 = Color(rawValue: color0)!
        self.color1 = Color(rawValue: color1)!
        self.color2 = Color(rawValue: color2)!
        self.color3 = Color(rawValue: color3)!
    }
    
    func rgbValue(for pixel: Pixel) -> UInt8 {
        switch(pixel) {
        case .c0:
            return color0.grayscaleValue
        case .c1:
            return color1.grayscaleValue
        case .c2:
            return color2.grayscaleValue
        case .c3:
            return color3.grayscaleValue
        }
    }
}

extension ColorPalette {
    init(withRegister reg: Byte) {
        let c0 = reg & 0b0000_0011
        let c1 = (reg >> 2) & 0b0000_0011
        let c2 = (reg >> 4) & 0b0000_0011
        let c3 = (reg >> 6) & 0b0000_0011
        self.init(color0: c0, color1: c1, color2: c2, color3: c3)
    }
    
    var registerValue: Byte {
        var value = color0.rawValue
        value &= (color1.rawValue << 2) | 0b1111_0011
        value &= (color2.rawValue << 4) | 0b1100_1111
        value &= (color3.rawValue << 6) | 0b0011_1111
        return value
    }
}
