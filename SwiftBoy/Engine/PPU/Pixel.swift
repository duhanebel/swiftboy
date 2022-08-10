//
//  Pixel.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 06/12/2020.
//

import Foundation

enum Pixel: UInt8, ExpressibleByNilLiteral {
    case c0 = 0b00
    case c1 = 0b10
    case c2 = 0b01
    case c3 = 0b11
    
    init(nilLiteral: ()) {
        self = .c0
    }
    
    var isTransparentColor: Bool {
        return self == .c0
    }
}
