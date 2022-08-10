//
//  Types.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 30/11/2020.
//

import Foundation

typealias Byte = UInt8
typealias Word = UInt16
typealias Address = UInt16

//struct Address2: ExpressibleByIntegerLiteral {
//    private let address: UInt16
//    private let base: UInt16
//    
//    init(integerLiteral value: UInt16) {
//        self.init(absoluteAddress: value, baseAddress: 0x00)
//    }
//    
//    init(absoluteAddress: UInt16, baseAddress: UInt16) {
//        assert(absoluteAddress >= baseAddress, "Base address out of bounds")
//        address = absoluteAddress
//        base = baseAddress
//    }
//    
//    var relative: UInt16 { address - base }
//    var absolute: UInt16 { address }
//}
//
//
//let d: Address2 = 4
