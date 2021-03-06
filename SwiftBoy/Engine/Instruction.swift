//
//  Instruction.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 28/11/2020.
//

import Foundation

let noop: (CPU)->Void = {_ in }

struct Instruction {
    let asm: String
    let opcode: UInt8
    let length: Length
    let cycles: Int?
    private let execute: ((CPU) -> Void)!
    private let execute8: ((CPU, UInt8) -> Void)!
    private let execute16: ((CPU, UInt16) -> Void)!
    
    private let executeb: ((CPU) -> Int)!
    private let execute8b: ((CPU, UInt8) -> Int)!
    private let execute16b: ((CPU, UInt16) -> Int)!
    
    private var param8: UInt8!
    private var param16: UInt16!
    
    enum Length: Int {
        case single = 1
        case double = 2
        case multi = 3
    }
    
    var isExtendedPrefix: Bool {
        return opcode == 0xCB
    }
    
    mutating func setParam(_ param: UInt8) {
        param8 = param
    }
    
    mutating func setParam(_ param: UInt16) {
        param16 = param
    }
    
    func run(on cpu: CPU) -> Int {
        switch(length) {
        case .single:
        
        if let cycles = cycles {
            execute(cpu)
            return cycles
        } else {
            return executeb(cpu)
        }
        case .double:
            if let cycles = cycles {
                execute8(cpu, param8)
                return cycles
            } else {
                return execute8b(cpu, param8)
            }
        case .multi:
            if let cycles = cycles {
                execute16(cpu, param16)
                return cycles
            } else {
                return execute16b(cpu, param16)
            }
        }
    }
    
    private init(asm: String, opcode: UInt8, cycles: Int? = nil, argLenght: Length, execute: ((CPU) -> Void)? = nil,
         execute8: ((CPU, UInt8) -> Void)? = nil,
         execute16: ((CPU, UInt16) -> Void)? = nil,
         executeb: ((CPU) -> Int)? = nil,
         execute8b: ((CPU, UInt8) -> Int)? = nil,
         execute16b: ((CPU, UInt16) -> Int)? = nil) {
        self.asm = asm
        self.opcode = opcode
        self.length = argLenght
        self.cycles = cycles
        self.execute = execute
        self.execute8 = execute8
        self.execute16 = execute16
        self.executeb = executeb
        self.execute8b = execute8b
        self.execute16b = execute16b
    }
}

extension Instruction {
    static func instructionMap() -> [UInt8:Instruction] {
        Instruction.allInstructions.reduce(into: [UInt8:Instruction]()) { table, item in table[item.opcode] = item }        
    }
    
     init(asm: String, opcode: UInt8, cycles: Int, execute: @escaping ((CPU) -> Void)) {
        self.init(asm: asm, opcode: opcode, cycles: cycles, argLenght: .single, execute: execute)
    }
    
     init(asm: String, opcode: UInt8, cycles: Int, execute: @escaping ((CPU, UInt8) -> Void)) {
        self.init(asm: asm, opcode: opcode, cycles: cycles, argLenght: .double, execute8: execute)
    }
    
     init(asm: String, opcode: UInt8, cycles: Int, execute: @escaping ((CPU, UInt16) -> Void)) {
        self.init(asm: asm, opcode: opcode, cycles: cycles, argLenght: .multi, execute16: execute)
    }
    
     init(asm: String, opcode: UInt8, execute: @escaping ((CPU) -> Int)) {
        self.init(asm: asm, opcode: opcode, argLenght: .single, executeb: execute)
    }
    
     init(asm: String, opcode: UInt8, execute: @escaping ((CPU, UInt8) -> Int)) {
        self.init(asm: asm, opcode: opcode, argLenght: .double, execute8b: execute)
    }
    
     init(asm: String, opcode: UInt8, execute: @escaping ((CPU, UInt16) -> Int)) {
        self.init(asm: asm, opcode: opcode, argLenght: .multi, execute16b: execute)
    }
    
    static var allInstructions: [Instruction] = {
        
        var allInstructions = [
            Instruction(asm: "NOP",        opcode: 0x00, cycles: 4, execute: { cpu in cpu.nop() }),
            
            Instruction(asm: "LD BC, d16", opcode: 0x01, cycles: 12, execute: { cpu, arg in cpu.registers.BC = arg }),
            Instruction(asm: "LD (BC), A", opcode: 0x02, cycles: 8, execute: { cpu in cpu.write(byte: cpu.registers.A, at: cpu.registers.BC)}),

            Instruction(asm: "INC BC",     opcode: 0x03, cycles: 8, execute: { cpu in cpu.registers.BC = cpu.inc(cpu.registers.BC) }),
            Instruction(asm: "INC B",      opcode: 0x04, cycles: 4, execute: { cpu in cpu.registers.B = cpu.inc(cpu.registers.B) }),
            Instruction(asm: "DEC B",      opcode: 0x05, cycles: 4, execute: { cpu in cpu.registers.B = cpu.dec(cpu.registers.B) }),
            Instruction(asm: "LD B, d8",   opcode: 0x06, cycles: 8, execute: { cpu, arg in cpu.registers.B = arg }),

            Instruction(asm: "RLCA",       opcode: 0x07, cycles: 4, execute: { cpu in
                            cpu.registers.A = cpu.rlc(cpu.registers.A);
                            cpu.registers.flags.Z = false }),

            Instruction(asm: "LD (a16), SP", opcode: 0x08, cycles: 20, execute: { cpu, arg in cpu.write(word: cpu.registers.SP, at: arg) }),

            Instruction(asm: "ADD HL, BC", opcode: 0x09, cycles: 8, execute: { cpu in cpu.registers.HL = cpu.add(cpu.registers.HL, value: cpu.registers.BC)}),

            Instruction(asm: "LD A, (BC)", opcode: 0x0A, cycles: 8, execute: { cpu in cpu.registers.A = cpu.read(at: cpu.registers.BC)}),

            Instruction(asm: "DEC BC",     opcode: 0x0B, cycles: 8, execute: { cpu in cpu.registers.BC = cpu.dec(cpu.registers.BC) }),
            Instruction(asm: "INC C",      opcode: 0x0C, cycles: 4, execute: { cpu in cpu.registers.C = cpu.inc(cpu.registers.C) }),
            Instruction(asm: "DEC C",      opcode: 0x0D, cycles: 4, execute: { cpu in cpu.registers.C = cpu.dec(cpu.registers.C) }),

            Instruction(asm: "LD C, d8",   opcode: 0x0E, cycles: 8, execute: { cpu, arg in cpu.registers.C = arg }),

            Instruction(asm: "RRCA",       opcode: 0x0F, cycles: 4, execute: { cpu in
                            cpu.registers.A = cpu.rrc(cpu.registers.A);
                            cpu.registers.flags.Z = false }),

            Instruction(asm: "STOP",       opcode: 0x10, cycles: 4, execute: { cpu in cpu.stop() }),

            Instruction(asm: "LD DE, d16", opcode: 0x11, cycles: 12, execute: { cpu, arg in cpu.registers.DE = arg }),
            Instruction(asm: "LD (DE), A", opcode: 0x12, cycles: 8, execute: { cpu in cpu.write(byte: cpu.registers.A, at: cpu.registers.DE)}),

            Instruction(asm: "INC DE",     opcode: 0x13, cycles: 8, execute: { cpu in cpu.registers.DE = cpu.inc(cpu.registers.DE) }),
            Instruction(asm: "INC D",      opcode: 0x14, cycles: 4, execute: { cpu in cpu.registers.D = cpu.inc(cpu.registers.D) }),
            Instruction(asm: "DEC D",      opcode: 0x15, cycles: 4, execute: { cpu in cpu.registers.D = cpu.dec(cpu.registers.D) }),
            Instruction(asm: "LD D, d8",   opcode: 0x16, cycles: 8, execute: { cpu, arg in cpu.registers.D = arg }),

            Instruction(asm: "RLA",        opcode: 0x17, cycles: 4, execute: { cpu in
                            cpu.registers.A = cpu.rl(cpu.registers.A)
                            cpu.registers.flags.Z = false
            }),

            Instruction(asm: "JR r8",      opcode: 0x18, cycles: 12, execute: { cpu, arg in cpu.jump(offset: arg) }),

            Instruction(asm: "ADD HL, DE", opcode: 0x19, cycles: 8, execute: { cpu in cpu.registers.HL = cpu.add(cpu.registers.HL, value: cpu.registers.DE)}),

            Instruction(asm: "LD A, (DE)", opcode: 0x1A, cycles: 8, execute: { cpu in cpu.registers.A = cpu.read(at: cpu.registers.DE)}),

            Instruction(asm: "DEC DE",     opcode: 0x1B, cycles: 8, execute: { cpu in cpu.registers.DE = cpu.dec(cpu.registers.DE) }),
            Instruction(asm: "INC E",      opcode: 0x1C, cycles: 4, execute: { cpu in cpu.registers.E = cpu.inc(cpu.registers.E) }),
            Instruction(asm: "DEC E",      opcode: 0x1D, cycles: 4, execute: { cpu in cpu.registers.E = cpu.dec(cpu.registers.E) }),

            Instruction(asm: "LD E, d8",   opcode: 0x1E, cycles: 8, execute: { cpu, arg in cpu.registers.E = arg }),

            /*
             RLCA, RLA, RRCA, RRA instructions: the flags are described wrong in the CPU manual: after the execution C contains the rotated bit while N, H and Z are always 0. The equivalent instructions in the extended CB opcode space however set Z if the result is 0 and that's correctly documented.
             */
            Instruction(asm: "RRA",        opcode: 0x1F, cycles: 4, execute: { cpu in
                            cpu.registers.A = cpu.rr(cpu.registers.A);
                            cpu.registers.flags.Z = false }),

            Instruction(asm: "JR NZ, r8",  opcode: 0x20, execute: { cpu, arg in cpu.jump(offset: arg, if: cpu.registers.flags.Z, is: false) ? 12 : 8 }),

            Instruction(asm: "LD HL, d16", opcode: 0x21, cycles: 12, execute: { cpu, arg in cpu.registers.HL = arg }),
            Instruction(asm: "LD (HL+), A",opcode: 0x22, cycles: 8, execute: { cpu in
                            cpu.write(byte: cpu.registers.A, at: cpu.registers.HL);
                            cpu.registers.HL &+= 1}),

            Instruction(asm: "INC HL",     opcode: 0x23, cycles: 8, execute: { cpu in cpu.registers.HL = cpu.inc(cpu.registers.HL) }),
            Instruction(asm: "INC H",      opcode: 0x24, cycles: 4, execute: { cpu in cpu.registers.H = cpu.inc(cpu.registers.H) }),
            Instruction(asm: "DEC H",      opcode: 0x25, cycles: 4, execute: { cpu in cpu.registers.H = cpu.dec(cpu.registers.H) }),
            Instruction(asm: "LD H, d8",   opcode: 0x26, cycles: 8, execute: { cpu, arg in cpu.registers.H = arg }),

            Instruction(asm: "DAA", opcode: 0x27, cycles: 4, execute: { cpu in cpu.daa() }),
            
            Instruction(asm: "JR Z, r8",   opcode: 0x28, execute: { cpu, arg in cpu.jump(offset: arg, if: cpu.registers.flags.Z, is: true) ? 12 : 8 }),

            Instruction(asm: "ADD HL, HL", opcode: 0x29, cycles: 8, execute: { cpu in cpu.registers.HL = cpu.add(cpu.registers.HL, value: cpu.registers.HL)}),

            Instruction(asm: "LD A, (HL+)",opcode: 0x2A, cycles: 8, execute: { cpu in
                            cpu.registers.A = cpu.read(at: cpu.registers.HL);
                            cpu.registers.HL += 1 }),

            Instruction(asm: "DEC HL",     opcode: 0x2B, cycles: 8, execute: { cpu in cpu.registers.HL = cpu.dec(cpu.registers.HL) }),
            Instruction(asm: "INC L",      opcode: 0x2C, cycles: 4, execute: { cpu in cpu.registers.L = cpu.inc(cpu.registers.L) }),
            Instruction(asm: "DEC L",      opcode: 0x2D, cycles: 4, execute: { cpu in cpu.registers.L = cpu.dec(cpu.registers.L) }),

            Instruction(asm: "LD L, d8",   opcode: 0x2E, cycles: 8, execute: { cpu, arg in cpu.registers.L = arg }),

            Instruction(asm: "CPL",        opcode: 0x2F, cycles: 4, execute: { cpu in
                            cpu.registers.A = cpu.registers.A.complement
                            cpu.registers.flags.N = true
                            cpu.registers.flags.H = true
            }),

            Instruction(asm: "JR NC, r8",   opcode: 0x30, execute: { cpu, arg in cpu.jump(offset: arg, if: cpu.registers.flags.C, is: false) ? 12 : 8 }),

            Instruction(asm: "LD SP, d16", opcode: 0x31, cycles: 12, execute: { cpu, arg in cpu.registers.SP = arg }),
            Instruction(asm: "LD (HL-), A",opcode: 0x32, cycles: 8, execute: { cpu in
                            cpu.write(byte: cpu.registers.A, at: cpu.registers.HL);
                            cpu.registers.HL &-= 1}),

            Instruction(asm: "INC SP",     opcode: 0x33, cycles: 8, execute: { cpu in cpu.registers.SP = cpu.inc(cpu.registers.SP) }),
            Instruction(asm: "INC (HL)",   opcode: 0x34, cycles: 12, execute: { cpu in cpu.write(byte: cpu.inc(cpu.read(at: cpu.registers.HL)), at: cpu.registers.HL) }),
            Instruction(asm: "DEC (HL)",   opcode: 0x35, cycles: 12, execute: { cpu in cpu.write(byte: cpu.dec(cpu.read(at: cpu.registers.HL)), at: cpu.registers.HL) }),
            Instruction(asm: "LD (HL), d8",opcode: 0x36, cycles: 12, execute: { cpu, arg in cpu.write(byte: arg, at: cpu.registers.HL) }),

            Instruction(asm: "SCF",        opcode: 0x37, cycles: 4, execute: { cpu in
                            cpu.registers.flags.N = false;
                            cpu.registers.flags.H = false;
                            cpu.registers.flags.C  = true }),

            Instruction(asm: "JR C, r8",   opcode: 0x38, execute: { cpu, arg in cpu.jump(offset: arg, if: cpu.registers.flags.C, is: true) ? 12 : 8 }),

            Instruction(asm: "ADD HL, SP", opcode: 0x39, cycles: 8, execute: { cpu in cpu.registers.HL = cpu.add(cpu.registers.HL, value: cpu.registers.SP)}),

            Instruction(asm: "LD A, (HL-)",opcode: 0x3A, cycles: 8, execute: { cpu in
                            cpu.registers.A = cpu.read(at: cpu.registers.HL);
                            cpu.registers.HL &-= 1 }),

            Instruction(asm: "DEC SP",     opcode: 0x3B, cycles: 8, execute: { cpu in cpu.registers.SP = cpu.dec(cpu.registers.SP) }),
            Instruction(asm: "INC A",      opcode: 0x3C, cycles: 4, execute: { cpu in cpu.registers.A = cpu.inc(cpu.registers.A) }),
            Instruction(asm: "DEC A",      opcode: 0x3D, cycles: 4, execute: { cpu in cpu.registers.A = cpu.dec(cpu.registers.A) }),

            Instruction(asm: "LD A, d8",   opcode: 0x3E, cycles: 8, execute: { cpu, arg in cpu.registers.A = arg }),

            Instruction(asm: "CCF",        opcode: 0x3F, cycles: 4, execute: { cpu in
                            cpu.registers.flags.N = false;
                            cpu.registers.flags.H = false;
                            cpu.registers.flags.C.toggle() }),

            Instruction(asm: "LD B, B",    opcode: 0x40, cycles: 4, execute: noop),
            Instruction(asm: "LD B, C",    opcode: 0x41, cycles: 4, execute: { cpu in cpu.registers.B = cpu.registers.C}),
            Instruction(asm: "LD B, D",    opcode: 0x42, cycles: 4, execute: { cpu in cpu.registers.B = cpu.registers.D}),
            Instruction(asm: "LD B, E",    opcode: 0x43, cycles: 4, execute: { cpu in cpu.registers.B = cpu.registers.E}),
            Instruction(asm: "LD B, H",    opcode: 0x44, cycles: 4, execute: { cpu in cpu.registers.B = cpu.registers.H}),
            Instruction(asm: "LD B, L",    opcode: 0x45, cycles: 4, execute: { cpu in cpu.registers.B = cpu.registers.L}),
            Instruction(asm: "LD B, (HL)", opcode: 0x46, cycles: 8, execute: { cpu in cpu.registers.B = cpu.read(at: cpu.registers.HL)}),
            Instruction(asm: "LD B, A",    opcode: 0x47, cycles: 4, execute: { cpu in cpu.registers.B = cpu.registers.A}),

            Instruction(asm: "LD C, B",    opcode: 0x48, cycles: 4, execute: { cpu in cpu.registers.C = cpu.registers.B}),
            Instruction(asm: "LD C, C",    opcode: 0x49, cycles: 4, execute: noop),
            Instruction(asm: "LD C, D",    opcode: 0x4A, cycles: 4, execute: { cpu in cpu.registers.C = cpu.registers.D}),
            Instruction(asm: "LD C, E",    opcode: 0x4B, cycles: 4, execute: { cpu in cpu.registers.C = cpu.registers.E}),
            Instruction(asm: "LD C, H",    opcode: 0x4C, cycles: 4, execute: { cpu in cpu.registers.C = cpu.registers.H}),
            Instruction(asm: "LD C, L",    opcode: 0x4D, cycles: 4, execute: { cpu in cpu.registers.C = cpu.registers.L}),
            Instruction(asm: "LD C, (HL)", opcode: 0x4E, cycles: 8, execute: { cpu in cpu.registers.C = cpu.read(at: cpu.registers.HL)}),
            Instruction(asm: "LD C, A",    opcode: 0x4F, cycles: 4, execute: { cpu in cpu.registers.C = cpu.registers.A}),

            Instruction(asm: "LD D, B",    opcode: 0x50, cycles: 4, execute: { cpu in cpu.registers.D = cpu.registers.B}),
            Instruction(asm: "LD D, C",    opcode: 0x51, cycles: 4, execute: { cpu in cpu.registers.D = cpu.registers.C}),
            Instruction(asm: "LD D, D",    opcode: 0x52, cycles: 4, execute: noop),
            Instruction(asm: "LD D, E",    opcode: 0x53, cycles: 4, execute: { cpu in cpu.registers.D = cpu.registers.E}),
            Instruction(asm: "LD D, H",    opcode: 0x54, cycles: 4, execute: { cpu in cpu.registers.D = cpu.registers.H}),
            Instruction(asm: "LD D, L",    opcode: 0x55, cycles: 4, execute: { cpu in cpu.registers.D = cpu.registers.L}),
            Instruction(asm: "LD D, (HL)", opcode: 0x56, cycles: 8, execute: { cpu in cpu.registers.D = cpu.read(at: cpu.registers.HL)}),
            Instruction(asm: "LD D, A",    opcode: 0x57, cycles: 4, execute: { cpu in cpu.registers.D = cpu.registers.A}),

            Instruction(asm: "LD E, B",    opcode: 0x58, cycles: 4, execute: { cpu in cpu.registers.E = cpu.registers.B}),
            Instruction(asm: "LD E, C",    opcode: 0x59, cycles: 4, execute: { cpu in cpu.registers.E = cpu.registers.C}),
            Instruction(asm: "LD E, D",    opcode: 0x5A, cycles: 4, execute: { cpu in cpu.registers.E = cpu.registers.D}),
            Instruction(asm: "LD E, E",    opcode: 0x5B, cycles: 4, execute: noop),
            Instruction(asm: "LD E, H",    opcode: 0x5C, cycles: 4, execute: { cpu in cpu.registers.E = cpu.registers.H}),
            Instruction(asm: "LD E, L",    opcode: 0x5D, cycles: 4, execute: { cpu in cpu.registers.E = cpu.registers.L}),
            Instruction(asm: "LD E, (HL)", opcode: 0x5E, cycles: 8, execute: { cpu in cpu.registers.E = cpu.read(at: cpu.registers.HL)}),
            Instruction(asm: "LD E, A",    opcode: 0x5F, cycles: 4, execute: { cpu in cpu.registers.E = cpu.registers.A}),

            Instruction(asm: "LD H, B",    opcode: 0x60, cycles: 4, execute: { cpu in cpu.registers.H = cpu.registers.B}),
            Instruction(asm: "LD H, C",    opcode: 0x61, cycles: 4, execute: { cpu in cpu.registers.H = cpu.registers.C}),
            Instruction(asm: "LD H, D",    opcode: 0x62, cycles: 4, execute: { cpu in cpu.registers.H = cpu.registers.D}),
            Instruction(asm: "LD H, E",    opcode: 0x63, cycles: 4, execute: { cpu in cpu.registers.H = cpu.registers.E}),
            Instruction(asm: "LD H, H",    opcode: 0x64, cycles: 4, execute: noop),
            Instruction(asm: "LD H, L",    opcode: 0x65, cycles: 4, execute: { cpu in cpu.registers.H = cpu.registers.L}),
            Instruction(asm: "LD H, (HL)", opcode: 0x66, cycles: 8, execute: { cpu in cpu.registers.H = cpu.read(at: cpu.registers.HL)}),
            Instruction(asm: "LD H, A",    opcode: 0x67, cycles: 4, execute: { cpu in cpu.registers.H = cpu.registers.A}),

            Instruction(asm: "LD L, B",    opcode: 0x68, cycles: 4, execute: { cpu in cpu.registers.L = cpu.registers.B}),
            Instruction(asm: "LD L, C",    opcode: 0x69, cycles: 4, execute: { cpu in cpu.registers.L = cpu.registers.C}),
            Instruction(asm: "LD L, D",    opcode: 0x6A, cycles: 4, execute: { cpu in cpu.registers.L = cpu.registers.D}),
            Instruction(asm: "LD L, E",    opcode: 0x6B, cycles: 4, execute: { cpu in cpu.registers.L = cpu.registers.E}),
            Instruction(asm: "LD L, H",    opcode: 0x6C, cycles: 4, execute: { cpu in cpu.registers.L = cpu.registers.H}),
            Instruction(asm: "LD L, L",    opcode: 0x6D, cycles: 4, execute: noop),
            Instruction(asm: "LD L, (HL)", opcode: 0x6E, cycles: 8, execute: { cpu in cpu.registers.L = cpu.read(at: cpu.registers.HL)}),
            Instruction(asm: "LD L, A",    opcode: 0x6F, cycles: 4, execute: { cpu in cpu.registers.L = cpu.registers.A}),

            Instruction(asm: "LD (HL), B", opcode: 0x70, cycles: 8, execute: { cpu in cpu.write(byte: cpu.registers.B, at: cpu.registers.HL) }),
            Instruction(asm: "LD (HL), C", opcode: 0x71, cycles: 8, execute: { cpu in cpu.write(byte: cpu.registers.C, at: cpu.registers.HL) }),
            Instruction(asm: "LD (HL), D", opcode: 0x72, cycles: 8, execute: { cpu in cpu.write(byte: cpu.registers.D, at: cpu.registers.HL) }),
            Instruction(asm: "LD (HL), E", opcode: 0x73, cycles: 8, execute: { cpu in cpu.write(byte: cpu.registers.E, at: cpu.registers.HL) }),
            Instruction(asm: "LD (HL), H", opcode: 0x74, cycles: 8, execute: { cpu in cpu.write(byte: cpu.registers.H, at: cpu.registers.HL) }),
            Instruction(asm: "LD (HL), L", opcode: 0x75, cycles: 8, execute: { cpu in cpu.write(byte: cpu.registers.L, at: cpu.registers.HL) }),

            Instruction(asm: "HALT",       opcode: 0x76, cycles: 4, execute: { cpu in cpu.halt() }),

            Instruction(asm: "LD (HL), A", opcode: 0x77, cycles: 8, execute: { cpu in cpu.write(byte: cpu.registers.A, at: cpu.registers.HL) }),

            Instruction(asm: "LD A, B",    opcode: 0x78, cycles: 4, execute: { cpu in cpu.registers.A = cpu.registers.B}),
            Instruction(asm: "LD A, C",    opcode: 0x79, cycles: 4, execute: { cpu in cpu.registers.A = cpu.registers.C}),
            Instruction(asm: "LD A, D",    opcode: 0x7A, cycles: 4, execute: { cpu in cpu.registers.A = cpu.registers.D}),
            Instruction(asm: "LD A, E",    opcode: 0x7B, cycles: 4, execute: { cpu in cpu.registers.A = cpu.registers.E}),
            Instruction(asm: "LD A, H",    opcode: 0x7C, cycles: 4, execute: { cpu in cpu.registers.A = cpu.registers.H}),
            Instruction(asm: "LD A, L",    opcode: 0x7D, cycles: 4, execute: { cpu in cpu.registers.A = cpu.registers.L}),
            Instruction(asm: "LD A, (HL)", opcode: 0x7E, cycles: 8, execute: { cpu in cpu.registers.A = cpu.read(at: cpu.registers.HL)}),
            Instruction(asm: "LD A, A",    opcode: 0x7F, cycles: 4, execute: noop),

            Instruction(asm: "ADD A, B",   opcode: 0x80, cycles: 4, execute: { cpu in cpu.registers.A = cpu.add(cpu.registers.A, value: cpu.registers.B) }),
            Instruction(asm: "ADD A, C",   opcode: 0x81, cycles: 4, execute: { cpu in cpu.registers.A = cpu.add(cpu.registers.A, value: cpu.registers.C) }),
            Instruction(asm: "ADD A, D",   opcode: 0x82, cycles: 4, execute: { cpu in cpu.registers.A = cpu.add(cpu.registers.A, value: cpu.registers.D) }),
            Instruction(asm: "ADD A, E",   opcode: 0x83, cycles: 4, execute: { cpu in cpu.registers.A = cpu.add(cpu.registers.A, value: cpu.registers.E) }),
            Instruction(asm: "ADD A, H",   opcode: 0x84, cycles: 4, execute: { cpu in cpu.registers.A = cpu.add(cpu.registers.A, value: cpu.registers.H) }),
            Instruction(asm: "ADD A, L",   opcode: 0x85, cycles: 4, execute: { cpu in cpu.registers.A = cpu.add(cpu.registers.A, value: cpu.registers.L) }),
            Instruction(asm: "ADD A, (HL)",opcode: 0x86, cycles: 8, execute: { cpu in cpu.registers.A = cpu.add(cpu.registers.A, value: cpu.read(at: cpu.registers.HL)) }),
            Instruction(asm: "ADD A, A",   opcode: 0x87, cycles: 4, execute: { cpu in cpu.registers.A = cpu.add(cpu.registers.A, value: cpu.registers.A) }),

            Instruction(asm: "ADC A, B",   opcode: 0x88, cycles: 4, execute: { cpu in cpu.registers.A = cpu.adc(cpu.registers.A, value: cpu.registers.B) }),
            Instruction(asm: "ADC A, C",   opcode: 0x89, cycles: 4, execute: { cpu in cpu.registers.A = cpu.adc(cpu.registers.A, value: cpu.registers.C) }),
            Instruction(asm: "ADC A, D",   opcode: 0x8A, cycles: 4, execute: { cpu in cpu.registers.A = cpu.adc(cpu.registers.A, value: cpu.registers.D) }),
            Instruction(asm: "ADC A, E",   opcode: 0x8B, cycles: 4, execute: { cpu in cpu.registers.A = cpu.adc(cpu.registers.A, value: cpu.registers.E) }),
            Instruction(asm: "ADC A, H",   opcode: 0x8C, cycles: 4, execute: { cpu in cpu.registers.A = cpu.adc(cpu.registers.A, value: cpu.registers.H) }),
            Instruction(asm: "ADC A, L",   opcode: 0x8D, cycles: 4, execute: { cpu in cpu.registers.A = cpu.adc(cpu.registers.A, value: cpu.registers.L) }),
            Instruction(asm: "ADC A, (HL)",opcode: 0x8E, cycles: 8, execute: { cpu in cpu.registers.A = cpu.adc(cpu.registers.A, value: cpu.read(at:cpu.registers.HL)) }),
            Instruction(asm: "ADC A, A",   opcode: 0x8F, cycles: 4, execute: { cpu in cpu.registers.A = cpu.adc(cpu.registers.A, value: cpu.registers.A) }),

            Instruction(asm: "SUB B",   opcode: 0x90, cycles: 4, execute: { cpu in cpu.registers.A = cpu.sub(cpu.registers.A, value: cpu.registers.B) }),
            Instruction(asm: "SUB C",   opcode: 0x91, cycles: 4, execute: { cpu in cpu.registers.A = cpu.sub(cpu.registers.A, value: cpu.registers.C) }),
            Instruction(asm: "SUB D",   opcode: 0x92, cycles: 4, execute: { cpu in cpu.registers.A = cpu.sub(cpu.registers.A, value: cpu.registers.D) }),
            Instruction(asm: "SUB E",   opcode: 0x93, cycles: 4, execute: { cpu in cpu.registers.A = cpu.sub(cpu.registers.A, value: cpu.registers.E) }),
            Instruction(asm: "SUB H",   opcode: 0x94, cycles: 4, execute: { cpu in cpu.registers.A = cpu.sub(cpu.registers.A, value: cpu.registers.H) }),
            Instruction(asm: "SUB L",   opcode: 0x95, cycles: 4, execute: { cpu in cpu.registers.A = cpu.sub(cpu.registers.A, value: cpu.registers.L) }),
            Instruction(asm: "SUB (HL)",opcode: 0x96, cycles: 8, execute: { cpu in cpu.registers.A = cpu.sub(cpu.registers.A, value: cpu.read(at:cpu.registers.HL)) }),
            Instruction(asm: "SUB A",   opcode: 0x97, cycles: 4, execute: { cpu in cpu.registers.A = cpu.sub(cpu.registers.A, value: cpu.registers.A) }),

            Instruction(asm: "SBC A, B",   opcode: 0x98, cycles: 4, execute: { cpu in cpu.registers.A = cpu.sbc(cpu.registers.A, value: cpu.registers.B) }),
            Instruction(asm: "SBC A, C",   opcode: 0x99, cycles: 4, execute: { cpu in cpu.registers.A = cpu.sbc(cpu.registers.A, value: cpu.registers.C) }),
            Instruction(asm: "SBC A, D",   opcode: 0x9A, cycles: 4, execute: { cpu in cpu.registers.A = cpu.sbc(cpu.registers.A, value: cpu.registers.D) }),
            Instruction(asm: "SBC A, E",   opcode: 0x9B, cycles: 4, execute: { cpu in cpu.registers.A = cpu.sbc(cpu.registers.A, value: cpu.registers.E) }),
            Instruction(asm: "SBC A, H",   opcode: 0x9C, cycles: 4, execute: { cpu in cpu.registers.A = cpu.sbc(cpu.registers.A, value: cpu.registers.H) }),
            Instruction(asm: "SBC A, L",   opcode: 0x9D, cycles: 4, execute: { cpu in cpu.registers.A = cpu.sbc(cpu.registers.A, value: cpu.registers.L) }),
            Instruction(asm: "SBC A, (HL)",opcode: 0x9E, cycles: 8, execute: { cpu in cpu.registers.A = cpu.sbc(cpu.registers.A, value: cpu.read(at:cpu.registers.HL)) }),
            Instruction(asm: "SBC A, A",   opcode: 0x9F, cycles: 4, execute: { cpu in cpu.registers.A = cpu.sbc(cpu.registers.A, value: cpu.registers.A) }),

            Instruction(asm: "AND B",   opcode: 0xA0, cycles: 4, execute: { cpu in cpu.registers.A = cpu.and(cpu.registers.A, value: cpu.registers.B) }),
            Instruction(asm: "AND C",   opcode: 0xA1, cycles: 4, execute: { cpu in cpu.registers.A = cpu.and(cpu.registers.A, value: cpu.registers.C) }),
            Instruction(asm: "AND D",   opcode: 0xA2, cycles: 4, execute: { cpu in cpu.registers.A = cpu.and(cpu.registers.A, value: cpu.registers.D) }),
            Instruction(asm: "AND E",   opcode: 0xA3, cycles: 4, execute: { cpu in cpu.registers.A = cpu.and(cpu.registers.A, value: cpu.registers.E) }),
            Instruction(asm: "AND H",   opcode: 0xA4, cycles: 4, execute: { cpu in cpu.registers.A = cpu.and(cpu.registers.A, value: cpu.registers.H) }),
            Instruction(asm: "AND L",   opcode: 0xA5, cycles: 4, execute: { cpu in cpu.registers.A = cpu.and(cpu.registers.A, value: cpu.registers.L) }),
            Instruction(asm: "AND (HL)",opcode: 0xA6, cycles: 8, execute: { cpu in cpu.registers.A = cpu.and(cpu.registers.A, value: cpu.read(at:cpu.registers.HL)) }),
            Instruction(asm: "AND A",   opcode: 0xA7, cycles: 4, execute: { cpu in cpu.registers.A = cpu.and(cpu.registers.A, value: cpu.registers.A) }),

            Instruction(asm: "XOR B",   opcode: 0xA8, cycles: 4, execute: { cpu in cpu.registers.A = cpu.xor(cpu.registers.A, value: cpu.registers.B) }),
            Instruction(asm: "XOR C",   opcode: 0xA9, cycles: 4, execute: { cpu in cpu.registers.A = cpu.xor(cpu.registers.A, value: cpu.registers.C) }),
            Instruction(asm: "XOR D",   opcode: 0xAA, cycles: 4, execute: { cpu in cpu.registers.A = cpu.xor(cpu.registers.A, value: cpu.registers.D) }),
            Instruction(asm: "XOR E",   opcode: 0xAB, cycles: 4, execute: { cpu in cpu.registers.A = cpu.xor(cpu.registers.A, value: cpu.registers.E) }),
            Instruction(asm: "XOR H",   opcode: 0xAC, cycles: 4, execute: { cpu in cpu.registers.A = cpu.xor(cpu.registers.A, value: cpu.registers.H) }),
            Instruction(asm: "XOR L",   opcode: 0xAD, cycles: 4, execute: { cpu in cpu.registers.A = cpu.xor(cpu.registers.A, value: cpu.registers.L) }),
            Instruction(asm: "XOR (HL)",opcode: 0xAE, cycles: 8, execute: { cpu in cpu.registers.A = cpu.xor(cpu.registers.A, value: cpu.read(at:cpu.registers.HL)) }),
            Instruction(asm: "XOR A",   opcode: 0xAF, cycles: 4, execute: { cpu in cpu.registers.A = cpu.xor(cpu.registers.A, value: cpu.registers.A) }),

            Instruction(asm: "OR B",    opcode: 0xB0, cycles: 4, execute: { cpu in cpu.registers.A = cpu.or(cpu.registers.A, value: cpu.registers.B) }),
            Instruction(asm: "OR C",    opcode: 0xB1, cycles: 4, execute: { cpu in cpu.registers.A = cpu.or(cpu.registers.A, value: cpu.registers.C) }),
            Instruction(asm: "OR D",    opcode: 0xB2, cycles: 4, execute: { cpu in cpu.registers.A = cpu.or(cpu.registers.A, value: cpu.registers.D) }),
            Instruction(asm: "OR E",    opcode: 0xB3, cycles: 4, execute: { cpu in cpu.registers.A = cpu.or(cpu.registers.A, value: cpu.registers.E) }),
            Instruction(asm: "OR H",    opcode: 0xB4, cycles: 4, execute: { cpu in cpu.registers.A = cpu.or(cpu.registers.A, value: cpu.registers.H) }),
            Instruction(asm: "OR L",    opcode: 0xB5, cycles: 4, execute: { cpu in cpu.registers.A = cpu.or(cpu.registers.A, value: cpu.registers.L) }),
            Instruction(asm: "OR (HL)", opcode: 0xB6, cycles: 8, execute: { cpu in cpu.registers.A = cpu.or(cpu.registers.A, value: cpu.read(at:cpu.registers.HL)) }),
            Instruction(asm: "OR A",    opcode: 0xB7, cycles: 4, execute: { cpu in cpu.registers.A = cpu.or(cpu.registers.A, value: cpu.registers.A) }),

            Instruction(asm: "CP B",    opcode: 0xB8, cycles: 4, execute: { cpu in cpu.cmp(cpu.registers.A, value: cpu.registers.B) }),
            Instruction(asm: "CP C",    opcode: 0xB9, cycles: 4, execute: { cpu in cpu.cmp(cpu.registers.A, value: cpu.registers.C) }),
            Instruction(asm: "CP D",    opcode: 0xBA, cycles: 4, execute: { cpu in cpu.cmp(cpu.registers.A, value: cpu.registers.D) }),
            Instruction(asm: "CP E",    opcode: 0xBB, cycles: 4, execute: { cpu in cpu.cmp(cpu.registers.A, value: cpu.registers.E) }),
            Instruction(asm: "CP H",    opcode: 0xBC, cycles: 4, execute: { cpu in cpu.cmp(cpu.registers.A, value: cpu.registers.H) }),
            Instruction(asm: "CP L",    opcode: 0xBD, cycles: 4, execute: { cpu in cpu.cmp(cpu.registers.A, value: cpu.registers.L) }),
            Instruction(asm: "CP (HL)", opcode: 0xBE, cycles: 8, execute: { cpu in cpu.cmp(cpu.registers.A, value: cpu.read(at:cpu.registers.HL)) }),
            Instruction(asm: "CP A",    opcode: 0xBF, cycles: 4, execute: { cpu in cpu.cmp(cpu.registers.A, value: cpu.registers.A) }),

            Instruction(asm: "RET NZ",     opcode: 0xC0, execute: { cpu in cpu.ret(if: cpu.registers.flags.Z, is: false) ? 20 : 8 }),

            Instruction(asm: "POP BC",     opcode: 0xC1, cycles: 12, execute: { cpu in cpu.registers.BC = cpu.pop() }),

            Instruction(asm: "JP NZ, a16", opcode: 0xC2, execute: { cpu, arg in cpu.jump(address: arg, if: cpu.registers.flags.Z, is: false) ? 16 : 12 }),

            Instruction(asm: "JP a16",     opcode: 0xc3, cycles: 16, execute: { cpu, arg in cpu.jump(to: arg) }),
            Instruction(asm: "CALL NZ, a16", opcode: 0xC4, execute: { cpu, arg in cpu.call(arg, if: cpu.registers.flags.Z, is: false) ? 24 : 12 }),

            Instruction(asm: "PUSH BC",    opcode: 0xC5, cycles: 16, execute: { cpu in cpu.push(cpu.registers.BC)}),
            Instruction(asm: "ADD A, d8",   opcode: 0xC6, cycles: 8,  execute: { cpu, arg in cpu.registers.A = cpu.add(cpu.registers.A, value: arg) }),
            Instruction(asm: "RST 00H",    opcode: 0xC7, cycles: 16, execute: { cpu in cpu.rst(to: 0x00)}),
            Instruction(asm: "RET Z",      opcode: 0xC8, execute: { cpu in cpu.ret(if: cpu.registers.flags.Z, is: true) ? 20 : 8 }),

            Instruction(asm: "RET",        opcode: 0xC9, cycles: 16, execute: { cpu in cpu.ret() }),
            Instruction(asm: "JP Z, a16",  opcode: 0xCA, execute: { cpu, arg in cpu.jump(address: arg, if: cpu.registers.flags.Z, is: true) ? 16 : 12 }),

            Instruction(asm: "PREFIX",    opcode: 0xCB, cycles: 4, execute: { _ in  } ),
            Instruction(asm: "CALL Z, a16", opcode: 0xCC, execute: { cpu, arg in cpu.call(arg, if: cpu.registers.flags.Z, is: true) ? 24 : 12 }),

            Instruction(asm: "CALL a16",   opcode: 0xCD, cycles: 24, execute: { cpu, arg in cpu.call(arg) }),
            Instruction(asm: "ADC A, d8",  opcode: 0xCE, cycles: 8,  execute: { cpu, arg in cpu.registers.A = cpu.adc(cpu.registers.A, value: arg) }),

            Instruction(asm: "RST 08H",    opcode: 0xCF, cycles: 16, execute: { cpu in cpu.rst(to: 0x08)}),

            Instruction(asm: "RET NC",     opcode: 0xD0, execute: { cpu in cpu.ret(if: cpu.registers.flags.C, is: false) ? 20 : 8 }),

            Instruction(asm: "POP DE",     opcode: 0xD1, cycles: 12, execute: { cpu in cpu.registers.DE = cpu.pop()}),

            Instruction(asm: "JP NC, a16", opcode: 0xD2, execute: { cpu, arg in cpu.jump(address: arg, if: cpu.registers.flags.C, is: false) ? 16 : 12 }),

            Instruction(asm: "ILLEGAL_D3",    opcode: 0xD3, cycles: 4, execute: { cpu in cpu.panic() }),
            Instruction(asm: "CALL NC, a16",opcode: 0xD4, execute: { cpu, arg in cpu.call(arg, if: cpu.registers.flags.C, is: false) ? 24 : 12 }),

            Instruction(asm: "PUSH DE",    opcode: 0xD5, cycles: 16, execute: { cpu in cpu.push(cpu.registers.DE)}),
            Instruction(asm: "SUB d8",     opcode: 0xD6, cycles: 8,  execute: { cpu, arg in cpu.registers.A = cpu.sub(cpu.registers.A, value: arg) }),

            Instruction(asm: "RST 10H",    opcode: 0xD7, cycles: 16, execute: { cpu in cpu.rst(to: 0x10)}),

            Instruction(asm: "RET C",      opcode: 0xD8, execute: { cpu in cpu.ret(if: cpu.registers.flags.C, is: true) ? 20 : 8 }),

            Instruction(asm: "RETI",       opcode: 0xD9, cycles: 16, execute: { cpu in
                            cpu.ret();
                            cpu.enableInterrupts()}),

            Instruction(asm: "JP C, a16",  opcode: 0xDA, execute: { cpu, arg in cpu.jump(address: arg, if: cpu.registers.flags.C, is: true) ? 16 : 12 }),

            Instruction(asm: "ILLEGAL_DB",    opcode: 0xDB, cycles: 4, execute: { cpu in cpu.panic() }),

            Instruction(asm: "CALL C, a16",opcode: 0xDC, execute: { cpu, arg in cpu.call(arg, if: cpu.registers.flags.C, is: true) ? 24 : 12 }),

            Instruction(asm: "ILLEGAL_DD",    opcode: 0xDD, cycles: 4, execute: { cpu in cpu.panic() }),

            Instruction(asm: "SBC A, d8",  opcode: 0xDE, cycles: 8,  execute: { cpu, arg in cpu.registers.A = cpu.sbc(cpu.registers.A, value: arg) }),

            Instruction(asm: "RST 18H",    opcode: 0xDF, cycles: 16, execute: { cpu in cpu.rst(to: 0x18) }),

            Instruction(asm: "LDH (a8), A",opcode: 0xE0, cycles: 12, execute: { cpu, arg in cpu.write(byte: cpu.registers.A, atFF: arg) }),

            Instruction(asm: "POP HL",     opcode: 0xE1, cycles: 12, execute: { cpu in cpu.registers.HL = cpu.pop() }),

            Instruction(asm: "LD (C), A",  opcode: 0xE2, cycles: 8, execute: { cpu in cpu.write(byte: cpu.registers.A, atFF: cpu.registers.C) }),

            Instruction(asm: "ILLEGAL_E3",    opcode: 0xE3, cycles: 4, execute: { cpu in cpu.panic() }),
            Instruction(asm: "ILLEGAL_E4",    opcode: 0xE4, cycles: 4, execute: { cpu in cpu.panic() }),

            Instruction(asm: "PUSH HL",    opcode: 0xE5, cycles: 16, execute: { cpu in cpu.push(cpu.registers.HL) }),

            Instruction(asm: "AND d8",     opcode: 0xE6, cycles: 8,  execute: { cpu, arg in cpu.registers.A = cpu.and(cpu.registers.A, value: arg) }),

            Instruction(asm: "RST 20H",    opcode: 0xE7, cycles: 16, execute: { cpu in cpu.rst(to: 0x20) }),

            Instruction(asm: "ADD SP, r8", opcode: 0xE8, cycles: 16,  execute: { (cpu, arg: UInt8) in cpu.registers.SP = cpu.add(cpu.registers.SP, value: arg) }),

            Instruction(asm: "JP HL",      opcode: 0xE9, cycles: 4, execute: { cpu in cpu.jump(to: cpu.registers.HL) }),

            Instruction(asm: "LD (a16), A",opcode: 0xEA, cycles: 16, execute: { cpu, arg in cpu.write(byte: cpu.registers.A, at: arg) }),

            Instruction(asm: "ILLEGAL_EB",    opcode: 0xEB, cycles: 4, execute: { cpu in cpu.panic() }),
            Instruction(asm: "ILLEGAL_EC",    opcode: 0xEC, cycles: 4, execute: { cpu in cpu.panic() }),
            Instruction(asm: "ILLEGAL_ED",    opcode: 0xED, cycles: 4, execute: { cpu in cpu.panic() }),

            Instruction(asm: "XOR d8",     opcode: 0xEE, cycles: 8, execute: { cpu, arg in cpu.registers.A = cpu.xor(cpu.registers.A, value: arg) }),

            Instruction(asm: "RST 28H",    opcode: 0xEF, cycles: 16, execute: { cpu in cpu.rst(to: 0x28) }),

            Instruction(asm: "LDH A, (a8)",opcode: 0xF0, cycles: 12, execute: { cpu, arg in cpu.registers.A = cpu.read(atFF: arg) }),

            Instruction(asm: "POP AF",     opcode: 0xF1, cycles: 12, execute: { cpu in cpu.registers.AF = cpu.pop() }),

            Instruction(asm: "LD A, (C)", opcode: 0xF2, cycles: 8, execute: { cpu in cpu.registers.A = cpu.read(atFF: cpu.registers.C) }),

            Instruction(asm: "DI",         opcode: 0xF3, cycles: 4, execute: { cpu in cpu.disableIntNext() }),

            Instruction(asm: "ILLEGAL_F4",    opcode: 0xF4, cycles: 4, execute: { cpu in cpu.panic() }),
            Instruction(asm: "PUSH AF",    opcode: 0xF5, cycles: 16, execute: { cpu in cpu.push(cpu.registers.AF) }),
            Instruction(asm: "OR d8",      opcode: 0xF6, cycles: 8,  execute: { cpu, arg in cpu.registers.A = cpu.or(cpu.registers.A, value: arg) }),
            Instruction(asm: "RST 30H",    opcode: 0xF7, cycles: 16, execute: { cpu in cpu.rst(to: 0x30) }),

            Instruction(asm: "LD HL, SP+r8", opcode: 0xF8, cycles: 12, execute: { (cpu, arg: UInt8) in cpu.registers.HL = cpu.add(cpu.registers.SP, value: arg) }),
            Instruction(asm: "LD SP, HL",  opcode: 0xF9, cycles: 8, execute: { cpu in cpu.registers.SP = cpu.registers.HL }),

            Instruction(asm: "LD A, (a16)",opcode: 0xFA, cycles: 16, execute: { cpu, arg in cpu.registers.A = cpu.read(at: arg) }),

            Instruction(asm: "EI",         opcode: 0xFB, cycles: 4, execute: { cpu in cpu.enableIntNext() }),

            Instruction(asm: "ILLEGAL_FC",    opcode: 0xFC, cycles: 4, execute: { cpu in cpu.panic() }),
            Instruction(asm: "ILLEGAL_FD",    opcode: 0xFD, cycles: 4, execute: { cpu in cpu.panic() }),

            Instruction(asm: "CP d8",      opcode: 0xFE, cycles: 8, execute: { cpu, arg in cpu.cmp(cpu.registers.A, value: arg) }),

            Instruction(asm: "RST 38H",    opcode: 0xFF, cycles: 16, execute: { cpu in cpu.rst(to: 0x38) }),
    ]
        return allInstructions
    }()
    
}

extension Instruction {
    var disassembly: String {
        get {
            switch(length) {
            case .single:
                return asm
            case .double:
                let formatAsm = asm.replacingOccurrences(of: "d8", with: "$%02X")
                                   .replacingOccurrences(of: "a8", with: "$FF00+$%02X")
                                   .replacingOccurrences(of: "r8", with: "$%02X")
                return String(format: formatAsm, param8)
            case .multi:
                let formatAsm = asm.replacingOccurrences(of: "d16", with: "$%04X")
                                   .replacingOccurrences(of: "a16", with: "$%04X")
                                   .replacingOccurrences(of: "r16", with: "$%04X")
                return String(format: formatAsm, param16)
            }
        }
    }
}
