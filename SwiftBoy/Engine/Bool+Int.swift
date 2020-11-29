//
//  Bool+Int.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 28/11/2020.
//

import Foundation


extension Bool {
    var intValue: UInt8 {
        return self ? 1 : 0
    }
}
