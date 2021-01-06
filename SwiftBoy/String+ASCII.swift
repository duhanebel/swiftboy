//
//  String+ASCII.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 31/12/2020.
//

import Foundation

extension String {
    static func stringWith(ASCII: [UInt8]) -> String {
        return ASCII.reduce("") { acc, val in return acc + String(UnicodeScalar(val)) }
    }
}
