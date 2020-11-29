//
//  CPU+ALU.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 28/11/2020.
//

import Foundation

extension CPU {
    func rotateLeft(_ reg: inout UInt8, viaCarry: Bool = false) {
        let bit7 = (reg >> 7)
        
        reg <<= 1
        reg |= viaCarry ? flags.C.intValue : bit7
        
        flags.C = (bit7 == 1)
        flags.Z = (reg == 0)
        flags.N = false
        flags.H = false
    }
    
    func rotateRight(_ reg: inout UInt8, viaCarry: Bool = false) {
        let bit1 = reg & 0x01
        reg >>= 1
        
        reg |= (viaCarry ? flags.C.intValue : bit1) << 7
        flags.C = (bit1 == 1)
        
        flags.Z = (reg == 0)
        flags.N = false
        flags.H = false
    }
    
    func inc(_ reg: inout UInt8) {
        flags.H = ((reg & 0xF) == 0xF)
        reg &+= 1
        flags.Z = (reg == 0)
        flags.N = false
    }
    
    func inc(_ reg: inout UInt16) {
        reg &+= 1
    }
    
    func dec(_ reg: inout UInt8) {
        flags.H = ((reg & 0xF) == 0x0)
        reg &-= 1
        flags.Z = (reg == 0)
        flags.N = true
    }
    
    func dec(_ reg: inout UInt16) {
        reg &-= 1
    }

    func add(_ reg: inout UInt8, value: UInt8) {
        flags.H = ((reg & 0xF) + (value & 0xF) > 0xF)
        (reg, flags.C) = reg.addingReportingOverflow(value)
        flags.N = false
        flags.Z = (reg == 0)
    }

    func adc(_ reg: inout UInt8, value: UInt8) {
        add(&reg, value: value)
        let C = flags.C
        add(&reg, value: flags.C.intValue)
        if C == true { flags.C = C }
    }
    
    func add(_ reg: inout UInt16, value: UInt16) {
        flags.H = ((reg & 0xFF) + (value & 0xFF) > 0xFF)
        flags.N = false
        (reg, flags.C) = reg.addingReportingOverflow(value)
    }
    
    func sub(_ reg: inout UInt8, value: UInt8) {
        flags.H = ((value & 0xF) > (reg & 0xF))
        (reg, flags.C) = reg.subtractingReportingOverflow(value)
        flags.N = true
    }
    
    func sbc(_ reg: inout UInt8, value: UInt8) {
        sub(&reg, value: (value &- flags.C.intValue))
    }
    
    func swap(_ val: UInt8) -> UInt8 {
        var ret: UInt8 = val
        swap(&ret)
        return ret
    }
    
    func complement(_ reg: inout UInt8) {
        reg = reg.complement
        flags.N = true
        flags.Z = true
        flags.C = false
    }
    
    func and(_ reg: inout UInt8, value: UInt8) {
        reg &= value
        flags.Z = (reg == 0)
        flags.N = false
        flags.H = true
        flags.C = false
    }
    
    func xor(_ reg: inout UInt8, value: UInt8) {
        reg ^= value
        flags.Z = (reg == 0)
        flags.N = false
        flags.H = false
        flags.C = false
    }
    
    func or(_ reg: inout UInt8, value: UInt8) {
        reg |= value
        flags.Z = (reg == 0)
        flags.N = false
        flags.H = false
        flags.C = false
    }
    
    func cmp(_ reg: UInt8, value: UInt8) {
        var r = reg
        sub(&r, value: value)
    }
    
    func daa() {
        if registers.A.lowerNibble > 9 || flags.H {
            registers.A += 6
        }
        if registers.A.upperNibble > 9 || flags.C {
            registers.A += 60
        }
//        if the lower 4 bits form a number greater than 9 or H is set, add $06 to the accumulator
//        if the upper 4 bits form a number greater than 9 or C is set, add $60 to the accumulator
    }
    
    func rlc(_ reg: inout UInt8) {
        rotateLeft(&reg, viaCarry: false)
    }

    func rrc(_ reg: inout UInt8) {
        rotateRight(&reg, viaCarry: false)
    }
    
    func rl(_ reg: inout UInt8) {
        rotateLeft(&reg, viaCarry: true)
    }
    
    func rr(_ reg: inout UInt8) {
        rotateRight(&reg, viaCarry: true)
    }

    func sla(_ reg: inout UInt8) {
        flags.C = (reg[7] == 1)
        reg <<= 1
        flags.Z = (reg == 0)
        flags.N = false
        flags.H = false
    }

    func sra(_ reg: inout UInt8) {
        flags.C = (reg[0] == 1)
        reg >>= 1
        reg[7] = reg[6]
        flags.Z = (reg == 0)
        flags.N = false
        flags.H = false
    }
    
    func swap(_ reg: inout UInt8) {
        reg = ((reg >> 4) & 0x0F) | ((reg << 4) & 0xF0)
        flags.Z = (reg == 0)
        flags.N = false
        flags.Z = false
        flags.C = false
    }
    
    func srl(_ reg: inout UInt8) {
        flags.C = (reg[0] == 1)
        reg >>= 1
        flags.Z = (reg == 0)
        flags.N = false
        flags.H = false
    }
    
    func bit(_ index: Int, of reg: inout UInt8) {
        assert(index > 0 && index < 8, "Bit indexing out fo bounds")
        flags.Z = reg[index] == 1
        flags.N = false
        flags.H = true
    }
    
    func res(_ index: Int, of reg: inout UInt8) {
        assert(index > 0 && index < 8, "Bit indexing out fo bounds")
        reg[index] = 0
    }

    func set(_ index: Int, of reg: inout UInt8) {
        assert(index > 0 && index < 8, "Bit indexing out fo bounds")
        reg[index] = 1
    }

}
