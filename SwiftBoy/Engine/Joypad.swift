//
//  Joypad.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 30/11/2020.
//

import Foundation

/*
  Register format:
    Bit 7 - Not used
    Bit 6 - Not used
    Bit 5 - P15 out port
    Bit 4 - P14 out port
    Bit 3 - P13 in port
    Bit 2 - P12 in port
    Bit 1 - P11 in port
    Bit 0 - P10 in port
  
          P14         P15
           |           |
  --P10----O-Right-----O-A-------
           |           |
  --P11----O-Left------O-B-------
           |           |
  --P12----O-Up--------O-Select--
           |           |
  --P13----O-Down------O-Start---
           |           |
 
   NOTE: the joy pad info returned is like the C64 info. 0 means on, 1 means off.
*/

private extension Bool {
    var toggled: Bool {
        return !self
    }
}

class Joypad: MemoryMappable {
    private var reg: Byte = 0x0
    
    private var leftPressed: Bool = false
    private var rightPressed: Bool = false
    private var upPressed: Bool = false
    private var downPressed: Bool = false
    
    private var aPressed: Bool = false
    private var bPressed: Bool = false
    
    private var startPressed: Bool = false
    private var selectPressed: Bool = false
    
    func read(at address: UInt16) -> UInt8 {
        return reg
    }
    
    func readWord(at address: UInt16) -> UInt16 {
        return UInt16(read(at: address))
    }
    
    func write(byte: UInt8, at address: UInt16) {
        assert(address == 0x0, "Invalid address for a byte register")
        reg = byte
        reg = registerForRequest(byte)
    }
    
    func write(word: UInt16, at address: UInt16) {
        return write(byte: UInt8(word), at: address)
    }
    
    private func registerForRequest(_ request: Byte) -> Byte {
        let directionKeys = 1 << 4
        let actionKeys = 1 << 5
        var response = request
        if request == directionKeys {
            response[0] = rightPressed.toggled.intValue
            response[1] = leftPressed.toggled.intValue
            response[2] = upPressed.toggled.intValue
            response[3] = downPressed.toggled.intValue
        } else if request == actionKeys {
            response[0] = aPressed.toggled.intValue
            response[1] = bPressed.toggled.intValue
            response[2] = selectPressed.toggled.intValue
            response[3] = startPressed.toggled.intValue
        }
        return response
    }
}

extension Joypad {
    enum Key {
        case left
        case right
        case up
        case down
        case a
        case b
        case start
        case select
    }
    
    func keyDown(key: Key) {
        switch(key) {
        
        case .left:
            leftPressed = true
        case .right:
            rightPressed = true
        case .up:
            upPressed = true
        case .down:
            downPressed = true
        case .a:
            aPressed = true
        case .b:
            bPressed = true
        case .start:
            startPressed = true
        case .select:
            selectPressed = true
        }
    }
    
    func keyUp(key: Key) {
        switch(key) {
        
        case .left:
            leftPressed = false
        case .right:
            rightPressed = false
        case .up:
            upPressed = false
        case .down:
            downPressed = false
        case .a:
            aPressed = false
        case .b:
            bPressed = false
        case .start:
            startPressed = false
        case .select:
            selectPressed = false
        }
    }
}
