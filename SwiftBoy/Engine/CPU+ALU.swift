//
//  CPU+ALU.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 28/11/2020.
//

import Foundation

extension CPU {
    func rotateLeft(_ reg: UInt8, viaCarry: Bool = false) -> UInt8 {
        var res = reg << 1
        res[0] = viaCarry ? registers.flags.C.intValue : reg[7]
        
        registers.flags.C = reg[7].boolValue
        registers.flags.Z = (res == 0)
        registers.flags.N = false
        registers.flags.H = false
        return res
    }
    
    func rotateRight(_ reg: UInt8, viaCarry: Bool = false) -> UInt8 {
        var res = reg >> 1
        res[7] = viaCarry ? registers.flags.C.intValue : reg[0]
        
        registers.flags.C = reg[0].boolValue
        registers.flags.Z = (res == 0)
        registers.flags.N = false
        registers.flags.H = false
        
        return res
    }
    
    func inc(_ reg: UInt8) -> UInt8 {
        registers.flags.H = ((reg & 0xF) == 0xF)
        let res = reg &+ 1
        registers.flags.Z = (res == 0)
        registers.flags.N = false
        return res
    }
    
    func inc(_ reg: UInt16) -> UInt16 {
        let res = reg &+ 1
        return res
    }
    
    func dec(_ reg: UInt8) -> UInt8 {
        registers.flags.H = ((reg & 0xF) == 0x0)
        let res = reg &- 1
        registers.flags.Z = (res == 0)
        registers.flags.N = true
        return res
    }
    
    func dec(_ reg: UInt16) -> UInt16 {
        let res = reg &- 1
        return res
    }

    func add(_ reg: UInt8, value: UInt8) -> UInt8 {
        var res: UInt8
        registers.flags.H = ((reg & 0xF) + (value & 0xF) > 0xF)
        (res, registers.flags.C) = reg.addingReportingOverflow(value)
        registers.flags.N = false
        registers.flags.Z = (res == 0)
        return res
    }

    func adc(_ reg: UInt8, value: UInt8) -> UInt8 {
        let hadCarry = registers.flags.C
        var res = add(reg, value: value)
        // C and H flags need to be updated for both operations + value and +1
        if hadCarry {
            let addC = registers.flags.C
            let addH = registers.flags.H
            res = add(res, value: 1)
            if addH == true { registers.flags.H = addH }
            if addC == true { registers.flags.C = addC }
        }
        return res
    }
    
    func add(_ reg: UInt16, value: UInt8) -> UInt16 {
        let res = reg &+ value.signed16
        // On the gameboy, when adding u8 to u16, the H and carry flags
        // behave like when adding two u8 together
        registers.flags.H = ((reg & 0xF) + UInt16(value & 0xF) > 0xF)
        registers.flags.C = ((reg & 0xFF) + UInt16(value & 0xFF) > 0xFF)
        registers.flags.N = false
        registers.flags.Z = false
        return res
    }
    
    func add(_ reg: UInt16, value: UInt16) -> UInt16 {
        var res = reg
        // On 16-bit operations, H is calculated for bit 11
        // (which is H of the upper-byte)
        registers.flags.H = ((reg & 0xFFF) + (value & 0xFFF) > 0xFFF)
        registers.flags.N = false
        (res, registers.flags.C) = reg.addingReportingOverflow(value)
        return res
    }
   
    /*
     After comparing with Intel 8080 and Zilog 80, we find that decriptions of effect to Carry Flag and Half Carry are completely wrong.
     The correct version should be:
     Half Carry - Set if borrow from bit 4, which means it will NOT overflow to bit 4
     Carry - Set if borrow form bit 8, which means it will NOT overflow to bit 8
     */
    func sub(_ reg: UInt8, value: UInt8) -> UInt8 {
        var res = reg
        registers.flags.H = ((value & 0x0F) > (reg & 0x0F))
        (res, registers.flags.C) = reg.subtractingReportingOverflow(value)
        registers.flags.N = true
        registers.flags.Z = (res == 0)
        return res
    }
    
    func sbc(_ reg: UInt8, value: UInt8) -> UInt8 {
        let hadCarry = registers.flags.C
        var res = sub(reg, value: value)
        // C and H flags need to be updated for both operations - value and -1
        if hadCarry {
            let subC = registers.flags.C
            let subH = registers.flags.H
            res = sub(res, value: 1)
            if subH == true { registers.flags.H = subH }
            if subC == true { registers.flags.C = subC }
        }
        return res
    }
    
    func complement(_ reg: UInt8) -> UInt8 {
        registers.flags.N = true
        registers.flags.Z = true
        registers.flags.C = false
        return reg.complement
    }
    
    func and(_ reg: UInt8, value: UInt8) -> UInt8 {
        let res = reg & value
        registers.flags.Z = (res == 0)
        registers.flags.N = false
        registers.flags.H = true
        registers.flags.C = false
        return res
    }
    
    func xor(_ reg: UInt8, value: UInt8) -> UInt8 {
        let res = reg ^ value
        registers.flags.Z = (res == 0)
        registers.flags.N = false
        registers.flags.H = false
        registers.flags.C = false
        return res
    }
    
    func or(_ reg: UInt8, value: UInt8) -> UInt8 {
        let res = reg | value
        registers.flags.Z = (res == 0)
        registers.flags.N = false
        registers.flags.H = false
        registers.flags.C = false
        return res
    }
    
    func cmp(_ reg: UInt8, value: UInt8) {
        _ = sub(reg, value: value)
    }
    
    func daa() {
        // note: assumes a is a uint8_t and wraps from 0xff to 0
        if registers.flags.N == false {  // after an addition, adjust if (half-)carry occurred or if result is out of bounds
            if registers.flags.C || registers.A > 0x99 {
                registers.A &+= 0x60
                registers.flags.C = true
            }
            if registers.flags.H || (registers.A & 0x0F) > 0x09 { registers.A &+= 0x06; }
        } else {  // after a subtraction, only adjust if (half-)carry occurred
            if registers.flags.C { registers.A &-= 0x60; }
            if registers.flags.H { registers.A &-= 0x6; }
        }
        // these flags are always updated
        registers.flags.Z = (registers.A == 0) // the usual z flag
        registers.flags.H = false // h flag is always cleared
        
    }
    
    func rlc(_ reg:  UInt8) -> UInt8 {
        rotateLeft(reg, viaCarry: false)
    }

    func rrc(_ reg: UInt8) -> UInt8 {
        rotateRight(reg, viaCarry: false)
    }
    
    func rl(_ reg: UInt8) -> UInt8 {
        rotateLeft(reg, viaCarry: true)
    }
    
    func rr(_ reg: UInt8) -> UInt8 {
        rotateRight(reg, viaCarry: true)
    }

    func sla(_ reg: UInt8) -> UInt8 {
        let res = reg << 1
        registers.flags.C = reg[7].boolValue
        registers.flags.Z = (res == 0)
        registers.flags.N = false
        registers.flags.H = false
        return res
    }

    func sra(_ reg: UInt8) -> UInt8 {
        var res = reg >> 1
        res[7] = reg[7]
        registers.flags.C = reg[0].boolValue
        registers.flags.Z = (res == 0)
        registers.flags.N = false
        registers.flags.H = false
        
        return res
    }
    
    func swap(_ reg: UInt8) -> UInt8 {
        let res = ((reg >> 4) & 0x0F) | ((reg << 4) & 0xF0)
        registers.flags.Z = (res == 0)
        registers.flags.N = false
        registers.flags.H = false
        registers.flags.C = false
        return res
    }
    
    func srl(_ reg: UInt8) -> UInt8 {
        let res = reg >> 1
        registers.flags.C = reg[0].boolValue
        registers.flags.Z = (res == 0)
        registers.flags.N = false
        registers.flags.H = true
        return res
    }
    
    func bit(_ index: Int, of reg: UInt8) {
        assert(index >= 0 && index < 8, "Bit indexing out fo bounds")
        
        registers.flags.Z = (reg[index] == 0)
        registers.flags.N = false
        registers.flags.H = true
    }
    
    func res(_ index: Int, of reg: UInt8) -> UInt8 {
        assert(index >= 0 && index < 8, "Bit indexing out fo bounds")
        
        var res = reg
        res[index] = 0
        return res
    }

    func set(_ index: Int, of reg: UInt8) -> UInt8 {
        assert(index >= 0 && index < 8, "Bit indexing out fo bounds")
        
        var res = reg
        res[index] = 1
        return res
    }
}
