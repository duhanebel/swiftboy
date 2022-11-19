//
//  Joypad.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 30/11/2020.
//

import Foundation

/*
  Register format:
    Bit 7 - Not used (reads as 1)
    Bit 6 - Not used (reads as 1)
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

final class Joypad: MemoryMappable {
    // First two bit unimplemented, read as 1
    private var reg: Byte = 0xF0
    
    private var leftPressed: Bool = false
    private var rightPressed: Bool = false
    private var upPressed: Bool = false
    private var downPressed: Bool = false
    
    private var aPressed: Bool = false
    private var bPressed: Bool = false
    
    private var startPressed: Bool = false
    private var selectPressed: Bool = false
    
    private(set) var intRegister: InterruptRegister
    
    init(intRegister: InterruptRegister) {
        self.intRegister = intRegister
    }
    
    func read(at address: Address) -> Byte {
        return reg
    }
    
    func write(byte: Byte, at address: Address) {
        assert(address == 0xFF00, "Invalid address for a byte register")
        assert(address.lowerByte == 0x0, "First 4 bits are read only")
        // first two bits not implemented, return 1
        reg = registerForRequest(byte | 0xC0)
    }
    
    private func registerForRequest(_ request: Byte) -> Byte {
        var response = request
        // 1 represent button NOT pressed
        // 0 represent button PRESSED
        if request[4] == 0 {
            response[0] = rightPressed.toggled.intValue
            response[1] = leftPressed.toggled.intValue
            response[2] = upPressed.toggled.intValue
            response[3] = downPressed.toggled.intValue
        }
        if request[5] == 0 {
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
        generateInterrupt()
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
        generateInterrupt() // TODO: does it generates an int on keyup?
    }
    
    private func generateInterrupt() {
        self.intRegister.joypad = true
    }
}
