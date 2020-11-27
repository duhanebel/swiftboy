//
//  CPU.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 25/11/2020.
//

import Foundation

private extension Array where Element == UInt8 {
    var word: UInt16 {
        get {
            assert(self.count == 2, "Array is not a word")
            var word: UInt16 = 0
            word.lowerByte = self[0]
            word.upperByte = self[1]
            return word
        }
    }
    
    var byte: UInt8 {
        get {
            assert(self.count == 1, "Array is not a byte")
            return self[0]
        }
    }
}

class RAM {
    private var rawmem = Array<UInt8>(repeating: 0x0, count: 0xFFFF)
    
    func read(at address: UInt16) -> UInt8 {
        return rawmem[Int(address)]
    }
    
    func readWord(at address: UInt16) -> UInt16 {
        var word: UInt16 = 0
        word.upperByte = rawmem[Int(address)]
        word.lowerByte = rawmem[Int(address)+1]
        return word
    }
    
    func write(byte: UInt8, at address: UInt16) {
        rawmem[Int(address)] = byte
    }
    
    func write(word: UInt16, at address: UInt16) {
        rawmem[Int(address)] = word.upperByte
        rawmem[Int(address)+1] = word.lowerByte
    }
}

let noop: (CPU)->Void = {_ in }

struct Instruction {
    let asm: String
    let opcode: UInt8
    let length: Length
    private let cycles: Int?
    private let execute: ((CPU) -> Void)!
    private let execute8: ((CPU, UInt8) -> Void)!
    private let execute16: ((CPU, UInt16) -> Void)!
    
    private let executeb: ((CPU) -> Int)!
    private let execute8b: ((CPU, UInt8) -> Int)!
    private let execute16b: ((CPU, UInt16) -> Int)!
    
    enum Length: Int {
        case single = 1
        case double = 2
        case multi = 3
    }
    
    func run(on cpu: CPU) -> Int {
        assert(length == .single)
        if let cycles = cycles {
            execute(cpu)
            return cycles
        } else {
            return executeb(cpu)
        }
    }
    
    func run(on cpu: CPU, with param: UInt8) -> Int {
        assert(length == .double)
        if let cycles = cycles {
            execute8(cpu, param)
            return cycles
        } else {
            return execute8b(cpu, param)
        }
    }
    
    func run(on cpu: CPU, with param: UInt16) -> Int {
        assert(length == .multi)
        if let cycles = cycles {
            execute16(cpu, param)
            return cycles
        } else {
            return execute16b(cpu, param)
        }
    }
    
    init(asm: String, opcode: UInt8, cycles: Int = 4, execute: @escaping ((CPU) -> Void)) {
        self.asm = asm
        self.opcode = opcode
        self.length = .single
        self.cycles = cycles
        self.execute = execute
    }
    
    init(asm: String, opcode: UInt8, cycles: Int = 4, execute: @escaping ((CPU, UInt8) -> Void)) {
        self.asm = asm
        self.opcode = opcode
        self.length = .double
        self.cycles = cycles
        self.execute8 = execute
    }
    
    init(asm: String, opcode: UInt8, cycles: Int = 4, execute: @escaping ((CPU, UInt16) -> Void)) {
        self.asm = asm
        self.opcode = opcode
        self.length = .multi
        self.cycles = cycles
        self.execute16 = execute
    }
    
    init(asm: String, opcode: UInt8, execute: @escaping ((CPU) -> Int)) {
        self.asm = asm
        self.opcode = opcode
        self.length = .single
        self.cycles = nil
        self.executeb = execute
    }
    
    init(asm: String, opcode: UInt8, execute: @escaping ((CPU, UInt8) -> Int)) {
        self.asm = asm
        self.opcode = opcode
        self.length = .double
        self.cycles = nil
        self.execute8b = execute
    }
    
    init(asm: String, opcode: UInt8, execute: @escaping ((CPU, UInt16) -> Int)) {
        self.asm = asm
        self.opcode = opcode
        self.length = .multi
        self.cycles = nil
        self.execute16b = execute
    }
}

struct Flags {
    var Z: Bool = false
    var N: Bool = false
    var H: Bool = false
    var C: Bool = false
}

struct Registers {
    var AF: UInt16 = 0x0
    var BC: UInt16 = 0x0
    var DE: UInt16 = 0x0
    var HL: UInt16 = 0x0
    
    var SP: UInt16 = 0xFFFE
    var PC: UInt16 = 0x100
    
    var flag: UInt8 = 0x0

    var A: UInt8 {
        get { return AF.upperByte }
        set { AF.upperByte = newValue }
    }
    var F: UInt8 {
        get { return AF.lowerByte }
        set { AF.lowerByte = newValue }
    }
    
    var B: UInt8 {
        get { return BC.upperByte }
        set { BC.upperByte = newValue }
    }
    var C: UInt8 {
        get { return BC.lowerByte }
        set { BC.lowerByte = newValue }
    }
    
    var D: UInt8 {
        get { return DE.upperByte }
        set { DE.upperByte = newValue }
    }
    var E: UInt8 {
        get { return DE.lowerByte }
        set { DE.lowerByte = newValue }
    }
    var H: UInt8 {
        get { return HL.upperByte }
        set { HL.upperByte = newValue }
    }
    var L: UInt8 {
        get { return HL.lowerByte }
        set { HL.lowerByte = newValue }
    }
    
    mutating func incrementPC(bytes: Int = 1) {
        PC += UInt16(bytes)
    }
}

typealias OpCode = UInt8

class CPU {
    let ram = RAM()
    var registers = Registers()
    var flags = Flags()
    var cycles = 0
    let instructionLookup: [UInt8:Instruction] = {
        CPUInstructions.reduce(into: [UInt8:Instruction]()) { table, item in table[item.opcode] = item }
    }()
    
    func tic() {
        let rawIns = fetch()
        guard let op = decode(ins: rawIns) else { return }
        cycles += op()
    }
  
    func readPCAdvance() -> UInt8 {
        let byte = ram.read(at: registers.PC)
        registers.incrementPC()
        return byte
    }
    
    func readPCAdvanceWord() -> UInt16 {
        let word = ram.readWord(at: registers.PC)
        registers.incrementPC(bytes: 2)
        return word
    }
    
    func fetch() -> OpCode {
        return readPCAdvance()
    }
    
    func decode(ins: OpCode) -> (()->Int)? {
        if let ins = instructionLookup[ins] {
            switch(ins.length) {
            case .single:
                return { return ins.run(on: self) }
            case .double:
                let arg = readPCAdvance()
                return { return ins.run(on: self, with: arg) }
            case .multi:
                let arg = readPCAdvanceWord()
                return { return ins.run(on: self, with: arg) }
            }
        } else {
            print("Unknown opcode: \(String(format:"%02X", ins))")
            return nil
        }
    }

    func pop() -> UInt16 {
        let value = ram.readWord(at: registers.SP)
        registers.SP += 2
        return value
    }
    
    func push(value: UInt16) {
        registers.SP -= 2
        ram.write(word: value, at: registers.SP)
    }
}

private extension Bool {
    var intValue: UInt8 {
        return self ? 1 : 0
    }
}

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
        flags.C = (reg + value > reg)
    }

    func adc(_ reg: inout UInt8, value: UInt8) {
        add(&reg, value: (value &+ flags.C.intValue))
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
    
    func swap(_ reg: inout UInt8) {
        reg = ((reg & 0xF0) >> 4) & ((reg & 0x0F) << 4)
        flags.Z = (reg == 0)
        flags.N = false
        flags.Z = false
        flags.C = false
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
    
    func jump(to address: UInt16) {
        registers.PC = address
    }


    static let CPUInstructions: [Instruction] = [

        Instruction(asm: "NOP",        opcode: 0x00, cycles: 4, execute: noop),
        
        Instruction(asm: "LD BC, d16", opcode: 0x01, cycles: 12, execute: { cpu, arg in cpu.registers.BC = arg }),
        Instruction(asm: "LD (BC), A", opcode: 0x02, cycles: 8, execute: { cpu in cpu.ram.write(byte: cpu.registers.A, at: cpu.registers.BC)}),
        
        Instruction(asm: "INC BC",     opcode: 0x03, cycles: 8, execute: { cpu in cpu.inc(&cpu.registers.BC) }),
        Instruction(asm: "INC B",      opcode: 0x04, cycles: 4, execute: { cpu in cpu.inc(&cpu.registers.B) }),
        Instruction(asm: "DEC B",      opcode: 0x05, cycles: 4, execute: { cpu in cpu.dec(&cpu.registers.B) }),
        Instruction(asm: "LD B, d8",   opcode: 0x06, cycles: 8, execute: { cpu, arg in cpu.registers.B = arg }),
        
        Instruction(asm: "RLCA",       opcode: 0x07, cycles: 4, execute: { cpu in cpu.rotateLeft(&cpu.registers.A) }),
        
        Instruction(asm: "LD (a16), SP", opcode: 0x08, cycles: 20, execute: { cpu, arg in cpu.ram.write(word: cpu.registers.SP, at: arg) }),
        
        Instruction(asm: "ADD HL, BC", opcode: 0x09, cycles: 8, execute: { cpu in cpu.add(&cpu.registers.HL, value: cpu.registers.BC)}),
        
        Instruction(asm: "LD A, (BC)", opcode: 0x0A, cycles: 8, execute: { cpu in cpu.registers.A = cpu.ram.read(at: cpu.registers.BC)}),
        
        Instruction(asm: "DEC BC",     opcode: 0x0B, cycles: 8, execute: { cpu in cpu.dec(&cpu.registers.BC) }),
        Instruction(asm: "INC C",      opcode: 0x0C, cycles: 4, execute: { cpu in cpu.inc(&cpu.registers.C) }),
        Instruction(asm: "DEC C",      opcode: 0x0D, cycles: 4, execute: { cpu in cpu.dec(&cpu.registers.C) }),
        
        Instruction(asm: "LD C, d8",   opcode: 0x0E, cycles: 8, execute: { cpu, arg in cpu.registers.C = arg }),

        Instruction(asm: "RRCA",       opcode: 0x0F, cycles: 4, execute: { cpu in cpu.rotateRight(&cpu.registers.A) }),

        //Instruction(asm: "STOP", opcode: 0x10, execute: noop),
     
        Instruction(asm: "LD DE, d16", opcode: 0x11, cycles: 12, execute: { cpu, arg in cpu.registers.DE = arg }),
        Instruction(asm: "LD (DE), A", opcode: 0x12, cycles: 8, execute: { cpu in cpu.ram.write(byte: cpu.registers.A, at: cpu.registers.DE)}),
     
        Instruction(asm: "INC DE",     opcode: 0x13, cycles: 8, execute: { cpu in cpu.inc(&cpu.registers.DE) }),
        Instruction(asm: "INC D",      opcode: 0x14, cycles: 4, execute: { cpu in cpu.inc(&cpu.registers.D) }),
        Instruction(asm: "DEC D",      opcode: 0x15, cycles: 4, execute: { cpu in cpu.dec(&cpu.registers.D) }),
        Instruction(asm: "LD D, d8",   opcode: 0x16, cycles: 8, execute: { cpu, arg in cpu.registers.D = arg }),
        
        Instruction(asm: "RLA",        opcode: 0x17, cycles: 4, execute: { cpu in cpu.rotateLeft(&cpu.registers.A, viaCarry: true) }),
        
        Instruction(asm: "JR r8",      opcode: 0x18, cycles: 12, execute: { cpu, arg in cpu.registers.PC += arg }),
        
        Instruction(asm: "ADD HL, DE", opcode: 0x19, cycles: 8, execute: { cpu in cpu.add(&cpu.registers.HL, value: cpu.registers.DE)}),

        Instruction(asm: "LD A, (DE)", opcode: 0x1A, cycles: 8, execute: { cpu in cpu.registers.A = cpu.ram.read(at: cpu.registers.DE)}),
        
        Instruction(asm: "DEC DE",     opcode: 0x1B, cycles: 8, execute: { cpu in cpu.dec(&cpu.registers.DE) }),
        Instruction(asm: "INC E",      opcode: 0x1C, cycles: 4, execute: { cpu in cpu.inc(&cpu.registers.E) }),
        Instruction(asm: "DEC E",      opcode: 0x1D, cycles: 4, execute: { cpu in cpu.dec(&cpu.registers.E) }),
        
        Instruction(asm: "LD E, d8",   opcode: 0x1E, cycles: 8, execute: { cpu, arg in cpu.registers.E = arg }),

        Instruction(asm: "RRA",        opcode: 0x1F, cycles: 4, execute: { cpu in cpu.rotateRight(&cpu.registers.A, viaCarry: true) }),
        
        Instruction(asm: "JR NZ, r8",  opcode: 0x20, cycles: 0, execute: { cpu, arg in
                        if cpu.flags.Z.false {
                            cpu.jump(arg)
                            return 12
                        } else { return 8 }
        }),
        
        Instruction(asm: "LD HL, d16", opcode: 0x21, cycles: 12, execute: { cpu, arg in cpu.registers.HL = arg }),
        Instruction(asm: "LD (HL+), A",opcode: 0x22, cycles: 8, execute: { cpu in cpu.ram.write(byte: cpu.registers.A, at: cpu.registers.HL); cpu.registers.HL += 1}),
        
        Instruction(asm: "INC HL",     opcode: 0x23, cycles: 8, execute: { cpu in cpu.inc(&cpu.registers.HL) }),
        Instruction(asm: "INC H",      opcode: 0x24, execute: { cpu in cpu.inc(&cpu.registers.H) }),
        Instruction(asm: "DEC H",      opcode: 0x25, execute: { cpu in cpu.dec(&cpu.registers.H) }),
        Instruction(asm: "LD H, d8",   opcode: 0x26, cycles: 8, execute: { cpu, arg in cpu.registers.H = arg }),
        
       // Instruction(asm: "DAA", opcode: 0x27, execute: { cpu in _ }),
        
        Instruction(asm: "JR Z, r8",   opcode: 0x28, cycles: 0, execute: { cpu, arg in
                    if cpu.flags.Z {
                        cpu.jump(arg)
                        return 12
                    } else { return 8 }
        }),
        
        Instruction(asm: "ADD HL, HL", opcode: 0x29, cycles: 8, execute: { cpu in cpu.add(&cpu.registers.HL, value: cpu.registers.HL)}),
        
        Instruction(asm: "LD A, (HL+)",opcode: 0x2A, cycles: 8, execute: { cpu in cpu.registers.A = cpu.ram.read(at: cpu.registers.HL); cpu.registers.HL += 1 }),
        
        Instruction(asm: "DEC HL",     opcode: 0x2B, cycles: 8, execute: { cpu in cpu.dec(&cpu.registers.HL) }),
        Instruction(asm: "INC L",      opcode: 0x2C, execute: { cpu in cpu.inc(&cpu.registers.L) }),
        Instruction(asm: "DEC L",      opcode: 0x2D, execute: { cpu in cpu.dec(&cpu.registers.L) }),
        
        Instruction(asm: "LD L, d8",   opcode: 0x2E, cycles: 8, execute: { cpu, arg in cpu.registers.L = arg }),

        Instruction(asm: "CPL",        opcode: 0x2F, execute: { cpu in cpu.registers.A = cpu.registers.A.complement }),
        
        Instruction(asm: "JR Z, r8",   opcode: 0x30, cycles: 0, execute: { cpu, arg in
                    if cpu.flags.C == false {
                        cpu.jump(arg)
                        return 12
                    } else { return 8 }
        }),
        
        Instruction(asm: "LD SP, d16", opcode: 0x31, cycles: 12, execute: { cpu, arg in cpu.registers.SP = arg }),
        Instruction(asm: "LD (HL-), A",opcode: 0x32, cycles: 8, execute: { cpu in cpu.ram.write(byte: cpu.registers.A, at: cpu.registers.HL); cpu.registers.HL -= 1}),
         
        Instruction(asm: "INC SP",     opcode: 0x33, cycles: 8, execute: { cpu in cpu.inc(&cpu.registers.SP) }),
        Instruction(asm: "INC (HL)",   opcode: 0x34, execute: { cpu in cpu.inc(&cpu.registers.HL) }),
        Instruction(asm: "DEC (HL)",   opcode: 0x35, execute: { cpu in cpu.dec(&cpu.registers.HL) }),
        Instruction(asm: "LD (HL), d8",opcode: 0x36, cycles: 8, execute: { cpu, arg in cpu.ram.write(word: arg, at: registers.HL) }),
        
        Instruction(asm: "SCF",        opcode: 0x37, execute: { cpu in cpu.registers.N = 0; cpu.registers.H = 0; cpu.registers.C  = 1 }),
        
        Instruction(asm: "JR C, r8",   opcode: 0x38, cycles: 0, execute: { cpu, arg in
                    if cpu.flags.C {
                        cpu.jump(arg);
                        return 12
                    } else { return 8 }
        }),
        
        Instruction(asm: "ADD HL, SP", opcode: 0x39, cycles: 8, execute: { cpu in cpu.add(&cpu.registers.HL, value: cpu.registers.SP)}),
        
        Instruction(asm: "LD A, (HL-)",opcode: 0x3A, cycles: 8, execute: { cpu in cpu.registers.A = cpu.ram.read(at: cpu.registers.HL); cpu.registers.HL -= 1 }),
        
        Instruction(asm: "DEC SP",     opcode: 0x3B, cycles: 8, execute: { cpu in cpu.dec(&cpu.registers.SP) }),
        Instruction(asm: "INC A",      opcode: 0x3C, execute: { cpu in cpu.inc(&cpu.registers.A) }),
        Instruction(asm: "DEC A",      opcode: 0x3D, execute: { cpu in cpu.dec(&cpu.registers.A) }),
        
        Instruction(asm: "LD A, d8",   opcode: 0x3E, cycles: 8, execute: { cpu, arg in cpu.registers.A = arg }),

        Instruction(asm: "CCF",        opcode: 0x3F, execute: { cpu in cpu.registers.N = 0; cpu.registers.H = 0; cpu.registers.C = (cpu.registers.C == 0) ? 1 : 0  }),
        
        Instruction(asm: "LD B, B",    opcode: 0x40, cycles: 4, execute: noop),
        Instruction(asm: "LD B, C",    opcode: 0x41, cycles: 4, execute: { cpu in cpu.registers.B = cpu.registers.C}),
        Instruction(asm: "LD B, D",    opcode: 0x42, cycles: 4, execute: { cpu in cpu.registers.B = cpu.registers.D}),
        Instruction(asm: "LD B, E",    opcode: 0x43, cycles: 4, execute: { cpu in cpu.registers.B = cpu.registers.E}),
        Instruction(asm: "LD B, H",    opcode: 0x44, cycles: 4, execute: { cpu in cpu.registers.B = cpu.registers.H}),
        Instruction(asm: "LD B, L",    opcode: 0x45, cycles: 4, execute: { cpu in cpu.registers.B = cpu.registers.L}),
        Instruction(asm: "LD B, (HL)", opcode: 0x46, cycles: 8, execute: { cpu in cpu.registers.B = cpu.ram.read(at: cpu.registers.HL)}),
        Instruction(asm: "LD B, A",    opcode: 0x47, execute: { cpu in cpu.registers.B = cpu.registers.A}),
        
        Instruction(asm: "LD C, B",    opcode: 0x48, cycles: 4, execute: { cpu in cpu.registers.C = cpu.registers.B}),
        Instruction(asm: "LD C, C",    opcode: 0x49, cycles: 4, execute: noop),
        Instruction(asm: "LD C, D",    opcode: 0x4A, cycles: 4, execute: { cpu in cpu.registers.C = cpu.registers.D}),
        Instruction(asm: "LD C, E",    opcode: 0x4B, cycles: 4, execute: { cpu in cpu.registers.C = cpu.registers.E}),
        Instruction(asm: "LD C, H",    opcode: 0x4C, cycles: 4, execute: { cpu in cpu.registers.C = cpu.registers.H}),
        Instruction(asm: "LD C, L",    opcode: 0x4D, cycles: 4, execute: { cpu in cpu.registers.C = cpu.registers.L}),
        Instruction(asm: "LD C, (HL)", opcode: 0x4E, cycles: 8, execute: { cpu in cpu.registers.C = cpu.ram.read(at: cpu.registers.HL)}),
        Instruction(asm: "LD C, A",    opcode: 0x4F, cycles: 4, execute: { cpu in cpu.registers.C = cpu.registers.A}),
        
        Instruction(asm: "LD D, B",    opcode: 0x50, cycles: 4, execute: { cpu in cpu.registers.D = cpu.registers.B}),
        Instruction(asm: "LD D, C",    opcode: 0x51, cycles: 4, execute: { cpu in cpu.registers.D = cpu.registers.C}),
        Instruction(asm: "LD D, D",    opcode: 0x52, cycles: 4, execute: noop),
        Instruction(asm: "LD D, E",    opcode: 0x53, cycles: 4, execute: { cpu in cpu.registers.D = cpu.registers.E}),
        Instruction(asm: "LD D, H",    opcode: 0x54, cycles: 4, execute: { cpu in cpu.registers.D = cpu.registers.H}),
        Instruction(asm: "LD D, L",    opcode: 0x55, cycles: 4, execute: { cpu in cpu.registers.D = cpu.registers.L}),
        Instruction(asm: "LD D, (HL)", opcode: 0x56, cycles: 8, execute: { cpu in cpu.registers.D = cpu.ram.read(at: cpu.registers.HL)}),
        Instruction(asm: "LD D, A",    opcode: 0x57, cycles: 4, execute: { cpu in cpu.registers.D = cpu.registers.A}),
        
        Instruction(asm: "LD E, B",    opcode: 0x58, cycles: 4, execute: { cpu in cpu.registers.E = cpu.registers.B}),
        Instruction(asm: "LD E, C",    opcode: 0x59, cycles: 4, execute: { cpu in cpu.registers.E = cpu.registers.C}),
        Instruction(asm: "LD E, D",    opcode: 0x5A, cycles: 4, execute: { cpu in cpu.registers.E = cpu.registers.D}),
        Instruction(asm: "LD E, E",    opcode: 0x5B, cycles: 4, execute: noop),
        Instruction(asm: "LD E, H",    opcode: 0x5C, cycles: 4, execute: { cpu in cpu.registers.E = cpu.registers.H}),
        Instruction(asm: "LD E, L",    opcode: 0x5D, cycles: 4, execute: { cpu in cpu.registers.E = cpu.registers.L}),
        Instruction(asm: "LD E, (HL)", opcode: 0x5E, cycles: 8, execute: { cpu in cpu.registers.E = cpu.ram.read(at: cpu.registers.HL)}),
        Instruction(asm: "LD E, A",    opcode: 0x5F, cycles: 4, execute: { cpu in cpu.registers.E = cpu.registers.A}),
        
        Instruction(asm: "LD H, B",    opcode: 0x60, cycles: 4, execute: { cpu in cpu.registers.H = cpu.registers.B}),
        Instruction(asm: "LD H, C",    opcode: 0x61, cycles: 4, execute: { cpu in cpu.registers.H = cpu.registers.C}),
        Instruction(asm: "LD H, D",    opcode: 0x62, cycles: 4, execute: { cpu in cpu.registers.H = cpu.registers.D}),
        Instruction(asm: "LD H, E",    opcode: 0x63, cycles: 4, execute: { cpu in cpu.registers.H = cpu.registers.E}),
        Instruction(asm: "LD H, H",    opcode: 0x64, cycles: 4, execute: noop),
        Instruction(asm: "LD H, L",    opcode: 0x65, cycles: 4, execute: { cpu in cpu.registers.H = cpu.registers.L}),
        Instruction(asm: "LD H, (HL)", opcode: 0x66, cycles: 8, execute: { cpu in cpu.registers.H = cpu.ram.read(at: cpu.registers.HL)}),
        Instruction(asm: "LD H, A",    opcode: 0x67, cycles: 4, execute: { cpu in cpu.registers.H = cpu.registers.A}),
        
        Instruction(asm: "LD L, B",    opcode: 0x68, cycles: 4, execute: { cpu in cpu.registers.L = cpu.registers.B}),
        Instruction(asm: "LD L, C",    opcode: 0x69, cycles: 4, execute: { cpu in cpu.registers.L = cpu.registers.C}),
        Instruction(asm: "LD L, D",    opcode: 0x6A, cycles: 4, execute: { cpu in cpu.registers.L = cpu.registers.D}),
        Instruction(asm: "LD L, E",    opcode: 0x6B, cycles: 4, execute: { cpu in cpu.registers.L = cpu.registers.E}),
        Instruction(asm: "LD L, H",    opcode: 0x6C, cycles: 4, execute: { cpu in cpu.registers.L = cpu.registers.H}),
        Instruction(asm: "LD L, L",    opcode: 0x6D, cycles: 4, execute: noop),
        Instruction(asm: "LD L, (HL)", opcode: 0x6E, cycles: 8, execute: { cpu in cpu.registers.L = cpu.ram.read(at: cpu.registers.HL)}),
        Instruction(asm: "LD L, A",    opcode: 0x6F, cycles: 4, execute: { cpu in cpu.registers.L = cpu.registers.A}),
        
        Instruction(asm: "LD (HL), B", opcode: 0x70, cycles: 8, execute: { cpu in cpu.ram.write(byte: cpu.registers.B, at: cpu.registers.HL) }),
        Instruction(asm: "LD (HL), C", opcode: 0x71, cycles: 8, execute: { cpu in cpu.ram.write(byte: cpu.registers.C, at: cpu.registers.HL) }),
        Instruction(asm: "LD (HL), D", opcode: 0x72, cycles: 8, execute: { cpu in cpu.ram.write(byte: cpu.registers.D, at: cpu.registers.HL) }),
        Instruction(asm: "LD (HL), E", opcode: 0x73, cycles: 8, execute: { cpu in cpu.ram.write(byte: cpu.registers.E, at: cpu.registers.HL) }),
        Instruction(asm: "LD (HL), H", opcode: 0x74, cycles: 8, execute: { cpu in cpu.ram.write(byte: cpu.registers.H, at: cpu.registers.HL) }),
        Instruction(asm: "LD (HL), L", opcode: 0x75, cycles: 8, execute: { cpu in cpu.ram.write(byte: cpu.registers.L, at: cpu.registers.HL) }),
        
        Instruction(asm: "HALT",       opcode: 0x76, cycles: 4, execute: noop),
        
        Instruction(asm: "LD (HL), L", opcode: 0x77, cycles: 8, execute: { cpu in cpu.ram.write(byte: cpu.registers.A, at: cpu.registers.HL) }),
        
        Instruction(asm: "LD A, B",    opcode: 0x78, cycles: 4, execute: { cpu in cpu.registers.A = cpu.registers.B}),
        Instruction(asm: "LD A, C",    opcode: 0x79, cycles: 4, execute: { cpu in cpu.registers.A = cpu.registers.C}),
        Instruction(asm: "LD A, D",    opcode: 0x7A, cycles: 4, execute: { cpu in cpu.registers.A = cpu.registers.D}),
        Instruction(asm: "LD A, E",    opcode: 0x7B, cycles: 4, execute: { cpu in cpu.registers.A = cpu.registers.E}),
        Instruction(asm: "LD A, H",    opcode: 0x7C, cycles: 4, execute: { cpu in cpu.registers.A = cpu.registers.H}),
        Instruction(asm: "LD A, L",    opcode: 0x7D, cycles: 4, execute: { cpu in cpu.registers.A = cpu.registers.L}),
        Instruction(asm: "LD A, (HL)", opcode: 0x7E, cycles: 8, execute: { cpu in cpu.registers.A = cpu.ram.read(at: cpu.registers.HL)}),
        Instruction(asm: "LD A, A",    opcode: 0x7F, cycles: 4, execute: noop),

        Instruction(asm: "ADD A, B",   opcode: 0x80, cycles: 4, execute: { cpu in cpu.add(&cpu.registers.A, value: cpu.registers.B) }),
        Instruction(asm: "ADD A, C",   opcode: 0x81, cycles: 4, execute: { cpu in cpu.add(&cpu.registers.A, value: cpu.registers.C) }),
        Instruction(asm: "ADD A, D",   opcode: 0x82, cycles: 4, execute: { cpu in cpu.add(&cpu.registers.A, value: cpu.registers.D) }),
        Instruction(asm: "ADD A, E",   opcode: 0x83, cycles: 4, execute: { cpu in cpu.add(&cpu.registers.A, value: cpu.registers.E) }),
        Instruction(asm: "ADD A, H",   opcode: 0x84, cycles: 4, execute: { cpu in cpu.add(&cpu.registers.A, value: cpu.registers.H) }),
        Instruction(asm: "ADD A, L",   opcode: 0x85, cycles: 4, execute: { cpu in cpu.add(&cpu.registers.A, value: cpu.registers.L) }),
        Instruction(asm: "ADD A, (HL)",opcode: 0x86, cycles: 8, execute: { cpu, arg in cpu.add(&cpu.registers.A, value: cpu.ram.read(at:arg)) }),
        Instruction(asm: "ADD A, A",   opcode: 0x87, cycles: 4, execute: { cpu in cpu.add(&cpu.registers.A, value: cpu.registers.A) }),
            
        Instruction(asm: "ADC A, B",   opcode: 0x88, cycles: 4, execute: { cpu in cpu.adc(&cpu.registers.A, value: cpu.registers.B) }),
        Instruction(asm: "ADC A, C",   opcode: 0x89, cycles: 4, execute: { cpu in cpu.adc(&cpu.registers.A, value: cpu.registers.C) }),
        Instruction(asm: "ADC A, D",   opcode: 0x8A, cycles: 4, execute: { cpu in cpu.adc(&cpu.registers.A, value: cpu.registers.D) }),
        Instruction(asm: "ADC A, E",   opcode: 0x8B, cycles: 4, execute: { cpu in cpu.adc(&cpu.registers.A, value: cpu.registers.E) }),
        Instruction(asm: "ADC A, H",   opcode: 0x8C, cycles: 4, execute: { cpu in cpu.adc(&cpu.registers.A, value: cpu.registers.H) }),
        Instruction(asm: "ADC A, L",   opcode: 0x8D, cycles: 4, execute: { cpu in cpu.adc(&cpu.registers.A, value: cpu.registers.L) }),
        Instruction(asm: "ADC A, (HL)",opcode: 0x8E, cycles: 8, execute: { cpu, arg in cpu.adc(&cpu.registers.A, value: cpu.ram.read(at:arg)) }),
        Instruction(asm: "ADC A, A",   opcode: 0x8F, cycles: 4, execute: { cpu in cpu.adc(&cpu.registers.A, value: cpu.registers.A) }),
        
        Instruction(asm: "SUB A, B",   opcode: 0x90, cycles: 4, execute: { cpu in cpu.sub(&cpu.registers.A, value: cpu.registers.B) }),
        Instruction(asm: "SUB A, C",   opcode: 0x91, cycles: 4, execute: { cpu in cpu.sub(&cpu.registers.A, value: cpu.registers.C) }),
        Instruction(asm: "SUB A, D",   opcode: 0x92, cycles: 4, execute: { cpu in cpu.sub(&cpu.registers.A, value: cpu.registers.D) }),
        Instruction(asm: "SUB A, E",   opcode: 0x93, cycles: 4, execute: { cpu in cpu.sub(&cpu.registers.A, value: cpu.registers.E) }),
        Instruction(asm: "SUB A, H",   opcode: 0x94, cycles: 4, execute: { cpu in cpu.sub(&cpu.registers.A, value: cpu.registers.H) }),
        Instruction(asm: "SUB A, L",   opcode: 0x95, cycles: 4, execute: { cpu in cpu.sub(&cpu.registers.A, value: cpu.registers.L) }),
        Instruction(asm: "SUB A, (HL)",opcode: 0x96, cycles: 8, execute: { cpu, arg in cpu.sub(&cpu.registers.A, value: cpu.ram.read(at:arg)) }),
        Instruction(asm: "SUB A, A",   opcode: 0x97, cycles: 4, execute: { cpu in cpu.sub(&cpu.registers.A, value: cpu.registers.A) }),
            
        Instruction(asm: "SBC A, B",   opcode: 0x98, cycles: 4, execute: { cpu in cpu.sbc(&cpu.registers.A, value: cpu.registers.B) }),
        Instruction(asm: "SBC A, C",   opcode: 0x99, cycles: 4, execute: { cpu in cpu.sbc(&cpu.registers.A, value: cpu.registers.C) }),
        Instruction(asm: "SBC A, D",   opcode: 0x9A, cycles: 4, execute: { cpu in cpu.sbc(&cpu.registers.A, value: cpu.registers.D) }),
        Instruction(asm: "SBC A, E",   opcode: 0x9B, cycles: 4, execute: { cpu in cpu.sbc(&cpu.registers.A, value: cpu.registers.E) }),
        Instruction(asm: "SBC A, H",   opcode: 0x9C, cycles: 4, execute: { cpu in cpu.sbc(&cpu.registers.A, value: cpu.registers.H) }),
        Instruction(asm: "SBC A, L",   opcode: 0x9D, cycles: 4, execute: { cpu in cpu.sbc(&cpu.registers.A, value: cpu.registers.L) }),
        Instruction(asm: "SBC A, (HL)",opcode: 0x9E, cycles: 4, execute: { cpu, arg in cpu.sbc(&cpu.registers.A, value: cpu.ram.read(at:arg)) }),
        Instruction(asm: "SBC A, A",   opcode: 0x9F, cycles: 4, execute: { cpu in cpu.sbc(&cpu.registers.A, value: cpu.registers.A) }),
      
        Instruction(asm: "AND A, B",   opcode: 0xA0, cycles: 4, execute: { cpu in cpu.and(&cpu.registers.A, value: cpu.registers.B) }),
        Instruction(asm: "AND A, C",   opcode: 0xA1, cycles: 4, execute: { cpu in cpu.and(&cpu.registers.A, value: cpu.registers.C) }),
        Instruction(asm: "AND A, D",   opcode: 0xA2, cycles: 4, execute: { cpu in cpu.and(&cpu.registers.A, value: cpu.registers.D) }),
        Instruction(asm: "AND A, E",   opcode: 0xA3, cycles: 4, execute: { cpu in cpu.and(&cpu.registers.A, value: cpu.registers.E) }),
        Instruction(asm: "AND A, H",   opcode: 0xA4, cycles: 4, execute: { cpu in cpu.and(&cpu.registers.A, value: cpu.registers.H) }),
        Instruction(asm: "AND A, L",   opcode: 0xA5, cycles: 4, execute: { cpu in cpu.and(&cpu.registers.A, value: cpu.registers.L) }),
        Instruction(asm: "AND A, (HL)",opcode: 0xA6, cycles: 8, execute: { cpu, arg in cpu.and(&cpu.registers.A, value: cpu.ram.read(at:arg)) }),
        Instruction(asm: "AND A, A",   opcode: 0xA7, cycles: 4, execute: { cpu in cpu.and(&cpu.registers.A, value: cpu.registers.A) }),
            
        Instruction(asm: "XOR A, B",   opcode: 0xA8, cycles: 4, execute: { cpu in cpu.xor(&cpu.registers.A, value: cpu.registers.B) }),
        Instruction(asm: "XOR A, C",   opcode: 0xA9, cycles: 4, execute: { cpu in cpu.xor(&cpu.registers.A, value: cpu.registers.C) }),
        Instruction(asm: "XOR A, D",   opcode: 0xAA, cycles: 4, execute: { cpu in cpu.xor(&cpu.registers.A, value: cpu.registers.D) }),
        Instruction(asm: "XOR A, E",   opcode: 0xAB, cycles: 4, execute: { cpu in cpu.xor(&cpu.registers.A, value: cpu.registers.E) }),
        Instruction(asm: "XOR A, H",   opcode: 0xAC, cycles: 4, execute: { cpu in cpu.xor(&cpu.registers.A, value: cpu.registers.H) }),
        Instruction(asm: "XOR A, L",   opcode: 0xAD, cycles: 4, execute: { cpu in cpu.xor(&cpu.registers.A, value: cpu.registers.L) }),
        Instruction(asm: "XOR A, (HL)",opcode: 0xAE, cycles: 4, execute: { cpu, arg in cpu.xor(&cpu.registers.A, value: cpu.ram.read(at:arg)) }),
        Instruction(asm: "XOR A, A",   opcode: 0xAF, cycles: 4, execute: { cpu in cpu.xor(&cpu.registers.A, value: cpu.registers.A) }),
            
        Instruction(asm: "OR A, B",   opcode: 0xB0, cycles: 4, execute: { cpu in cpu.or(&cpu.registers.A, value: cpu.registers.B) }),
        Instruction(asm: "OR A, C",   opcode: 0xB1, cycles: 4, execute: { cpu in cpu.or(&cpu.registers.A, value: cpu.registers.C) }),
        Instruction(asm: "OR A, D",   opcode: 0xB2, cycles: 4, execute: { cpu in cpu.or(&cpu.registers.A, value: cpu.registers.D) }),
        Instruction(asm: "OR A, E",   opcode: 0xB3, cycles: 4, execute: { cpu in cpu.or(&cpu.registers.A, value: cpu.registers.E) }),
        Instruction(asm: "OR A, H",   opcode: 0xB4, cycles: 4, execute: { cpu in cpu.or(&cpu.registers.A, value: cpu.registers.H) }),
        Instruction(asm: "OR A, L",   opcode: 0xB5, cycles: 4, execute: { cpu in cpu.or(&cpu.registers.A, value: cpu.registers.L) }),
        Instruction(asm: "OR A, (HL)",opcode: 0xB6, cycles: 8, execute: { cpu, arg in cpu.or(&cpu.registers.A, value: cpu.ram.read(at:arg)) }),
        Instruction(asm: "OR A, A",   opcode: 0xB7, cycles: 4, execute: { cpu in cpu.or(&cpu.registers.A, value: cpu.registers.A) }),
            
        Instruction(asm: "CP A, B",   opcode: 0xB8, cycles: 4, execute: { cpu in cpu.cmp(&cpu.registers.A, value: cpu.registers.B) }),
        Instruction(asm: "CP A, C",   opcode: 0xB9, cycles: 4, execute: { cpu in cpu.cmp(&cpu.registers.A, value: cpu.registers.C) }),
        Instruction(asm: "CP A, D",   opcode: 0xBA, cycles: 4, execute: { cpu in cpu.cmp(&cpu.registers.A, value: cpu.registers.D) }),
        Instruction(asm: "CP A, E",   opcode: 0xBB, cycles: 4, execute: { cpu in cpu.cmp(&cpu.registers.A, value: cpu.registers.E) }),
        Instruction(asm: "CP A, H",   opcode: 0xBC, cycles: 4, execute: { cpu in cpu.cmp(&cpu.registers.A, value: cpu.registers.H) }),
        Instruction(asm: "CP A, L",   opcode: 0xBD, cycles: 4, execute: { cpu in cpu.cmp(&cpu.registers.A, value: cpu.registers.L) }),
        Instruction(asm: "CP A, (HL)",opcode: 0xBE, cycles: 4, execute: { cpu, arg in cpu.cmp(&cpu.registers.A, value: cpu.ram.read(at:arg)) }),
        Instruction(asm: "CP A, A",   opcode: 0xBF, cycles: 4, execute: { cpu in cpu.cmp(&cpu.registers.A, value: cpu.registers.A) }),

        Instruction(asm: "RET NZ",    opcode: 0xC0, execute: { cpu in
            if(cpu.flags.Z == false) {
                let address = cpu.pop()
                cpu.jump(address)
                return 12
            } else { return 8 }
        }),
        
        Instruction(asm: "POP BC",    opcode: 0xC1, cycles: 12, execute: { cpu in cpu.registers.BC = cpu.pop()}),
        
        Instruction(asm: "JP NZ a16", opcode: 0xC2, execute: { cpu, arg in
            if(cpu.flags.Z == false) {
                cpu.jump(arg)
                return 12
            } else { return 8 }
        }),
        
        Instruction(asm: "JP a16",    opcode: 0xc3, cycles: 16, execute: { cpu, arg in cpu.jump(arg) }),
        Instruction(asm: "CALL NZ, a16", opcode: 0xC4, execute: { cpu, arg in
            if(cpu.flags.Z == false) {
                cpu.push(cpu.registers.PC &+ 1)
                cpu.jump(arg)
                return 24
            } else { return 12 }
        }),
    ]

}
