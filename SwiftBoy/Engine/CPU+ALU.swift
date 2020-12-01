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
        res |= viaCarry ? registers.flags.C.intValue : reg[7]
        
        registers.flags.C = reg[7] == 1
        registers.flags.Z = (res == 0)
        registers.flags.N = false
        registers.flags.H = false
        return res
    }
    
    func rotateRight(_ reg: UInt8, viaCarry: Bool = false) -> UInt8 {
        var res = reg >> 1
        
        res |= (viaCarry ? registers.flags.C.intValue : reg[1]) << 7
        registers.flags.C = (reg[1] == 1)
        
        registers.flags.Z = (res == 0)
        registers.flags.N = false
        registers.flags.H = false
        
        return res
    }
    
    func inc(_ reg: UInt8) -> UInt8{
        registers.flags.H = ((reg & 0xF) == 0xF)
        let res = reg &+ 1
        registers.flags.Z = (res == 0)
        registers.flags.N = false
        return res
    }
    
    func inc(_ reg: UInt16) -> UInt16 {
        let res = reg + 1
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
        var res = add(reg, value: value)
        let C = registers.flags.C
        res = add(res, value: registers.flags.C.intValue)
        if C == true { registers.flags.C = C }
        return res
    }
    
    func add(_ reg: UInt16, value: UInt16) -> UInt16 {
        var res = reg
        registers.flags.H = ((reg & 0xFF) + (value & 0xFF) > 0xFF)
        registers.flags.N = false
        (res, registers.flags.C) = reg.addingReportingOverflow(value)
        return res
    }
    
    func sub(_ reg: UInt8, value: UInt8) -> UInt8 {
        var res = reg
        registers.flags.H = ((value & 0xF) > (reg & 0xF))
        (res, registers.flags.C) = reg.subtractingReportingOverflow(value)
        registers.flags.N = true
        return res
    }
    
    func sbc(_ reg: UInt8, value: UInt8) -> UInt8 {
        sub(reg, value: (value &- registers.flags.C.intValue))
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
        if registers.A.lowerNibble > 9 || registers.flags.H {
            registers.A += 6
        }
        if registers.A.upperNibble > 9 || registers.flags.C {
            registers.A += 60
        }
//        if the lower 4 bits form a number greater than 9 or H is set, add $06 to the accumulator
//        if the upper 4 bits form a number greater than 9 or C is set, add $60 to the accumulator
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
        registers.flags.C = (reg[7] == 1)
        let res = reg << 1
        registers.flags.Z = (res == 0)
        registers.flags.N = false
        registers.flags.H = false
        return res
    }

    func sra(_ reg: UInt8) -> UInt8 {
        registers.flags.C = (reg[0] == 1)
        var res = reg >> 1
        res[7] = res[6]
        registers.flags.Z = (res == 0)
        registers.flags.N = false
        registers.flags.H = false
        
        return res
    }
    
    func swap(_ reg: UInt8) -> UInt8 {
        let res = ((reg >> 4) & 0x0F) | ((reg << 4) & 0xF0)
        registers.flags.Z = (res == 0)
        registers.flags.N = false
        registers.flags.Z = false
        registers.flags.C = false
        return res
    }
    
    func srl(_ reg: UInt8) -> UInt8 {
        registers.flags.C = (reg[0] == 1)
        let res = reg >> 1
        registers.flags.Z = (reg == 0)
        registers.flags.N = false
        registers.flags.H = false
        return res
    }
    
    func bit(_ index: Int, of reg: UInt8) {
        assert(index > 0 && index < 8, "Bit indexing out fo bounds")
        
        registers.flags.Z = (reg[index] == 1)
        registers.flags.N = false
        registers.flags.H = true
    }
    
    func res(_ index: Int, of reg: UInt8) -> UInt8 {
        assert(index > 0 && index < 8, "Bit indexing out fo bounds")
        
        var res = reg
        res[index] = 0
        return res
    }

    func set(_ index: Int, of reg: UInt8) -> UInt8 {
        assert(index > 0 && index < 8, "Bit indexing out fo bounds")
        
        var res = reg
        res[index] = 1
        return res
    }

}
