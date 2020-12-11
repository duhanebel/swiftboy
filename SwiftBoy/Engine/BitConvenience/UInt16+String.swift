//
//  UInt16+String.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 09/12/2020.
//

import Foundation

extension UInt16 {
    var hexString: String {
        return String(format:"%04X", self)
    }
}

extension String.StringInterpolation {
    mutating func appendInterpolation(_ value: UInt16, prefix: String = "0x") {
        appendLiteral(prefix)
        appendLiteral(value.hexString)
    }
}
