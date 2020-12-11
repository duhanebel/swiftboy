//
//  UInt8+String.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 09/12/2020.
//

import Foundation

extension UInt8 {
    var hexString: String {
        return String(format:"%02X", self)
    }
}

extension String.StringInterpolation {
    mutating func appendInterpolation(_ value: UInt8, prefix: String = "0x") {
        appendLiteral(prefix)
        appendLiteral(value.hexString)
    }
}
