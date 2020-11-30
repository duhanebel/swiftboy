//
//  UInt8+Bool.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 30/11/2020.
//

import Foundation

extension UInt8 {
    var boolValue: Bool {
        get { return self != 0 }
    }
}
