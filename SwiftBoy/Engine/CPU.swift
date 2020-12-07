//
//  CPU.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 25/11/2020.
//

import Foundation

struct Flags {
    private struct Locations {
        static let Z: Int = 7
        static let N: Int = 6
        static let H: Int = 5
        static let C: Int = 4
    }
    
    var byteValue: UInt8
    
    init(values: UInt8) {
        byteValue = values
        byteValue.lowerNibble = 0x0
    }
    
    var Z: Bool {
        get { return byteValue[Locations.Z].boolValue }
        set { byteValue[Locations.Z] = newValue.intValue }
    }
    
    var N: Bool {
        get { return byteValue[Locations.N].boolValue }
        set { byteValue[Locations.N] = newValue.intValue }
    }
    
    var H: Bool {
        get { return byteValue[Locations.H].boolValue }
        set { byteValue[Locations.H] = newValue.intValue }
    }
    
    var C: Bool {
        get { return byteValue[Locations.C].boolValue }
        set { byteValue[Locations.C] = newValue.intValue }
    }
}

struct Registers {
    var A: UInt8 = 0x0
    var flags: Flags = Flags(values: 0x0)

    var BC: UInt16 = 0x0
    var DE: UInt16 = 0x0
    var HL: UInt16 = 0x0
    
    var SP: UInt16 = 0xFFFE
    var PC: UInt16 = 0x0 // 0x100

    var AF: UInt16 {
        get {
            var AF: UInt16 = 0
            AF.lowerByte = A
            AF.upperByte = flags.byteValue
            return AF
        }
        set {
            A = newValue.lowerByte
            flags = Flags(values: newValue.upperByte)
        }
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
    static let clockSpeed = 4194304
    
    enum State {
        case running
        case halt
        case stop
    }
    
    enum IntState {
        case enabled
        case toEnable
        case disabled
        case toDisable
    }
    
    var state: State = .running
    var interruptState: IntState = .enabled
    
    var mmu: MemoryMappable
    var registers = Registers()
    
    var intEnabled: InterruptRegister
    var intRegister: InterruptRegister
    
    var cycles = 0
    
    var fastBoot: Bool = false {
        didSet {
            registers.PC = fastBoot ? 0x0100 : 0x0000
        }
    }
    
    let instructionLookup: [UInt8:Instruction] = {
        return Instruction.allInstructions.reduce(into: [UInt8:Instruction]()) { table, item in table[item.opcode] = item }
    }()
    
    let instructionLookupExtended: [UInt8:Instruction] = {
        return Instruction.allExtInstructions.reduce(into: [UInt8:Instruction]()) { table, item in table[item.opcode] = item }
    }()
    
    init(mmu: MemoryMappable, intEnabled: InterruptRegister, intRegister: InterruptRegister) {
        self.mmu = mmu
        self.intEnabled = intEnabled
        self.intRegister = intRegister
    }
    
    func tic() -> Int {
        let interruptTics = processInterrupts()
        
        switch(state){
        case .running:
            return (interruptTics > 0) ? interruptTics : fetchExecute()
        case .halt:
            fallthrough
        case .stop:
            return interruptTics
        }
    }
    
    private func fetchExecute() -> Int {
        let enableInterrupts = interruptState == .toEnable
        let disableInterrupts = interruptState == .toDisable
        
        let currentPC = registers.PC
        let rawOp = fetch()
        guard let ins = decode(code: rawOp) else { return 0 }
        let opCycles = run(ins, for: currentPC)
        cycles += opCycles
        if enableInterrupts { interruptState = .enabled }
        else if disableInterrupts { interruptState = .disabled }
        return opCycles
    }
    
    enum InterruptVectors: UInt16 {
        case VBlank   = 0x0040
        case LCDStat  = 0x0048
        case timer    = 0x0050
        case serial   = 0x0058
        case joypad   = 0x0060
    }
    
    private func processInterrupts() -> Int {
        guard interruptState == .enabled else { return 0 }

        var intVector: InterruptVectors? = nil
        if intEnabled.VBlank && intRegister.VBlank {
            intVector = .VBlank
        }
        if intEnabled.LCDStat && intEnabled.LCDStat {
            intVector = .LCDStat
        }
        if intEnabled.timer && intEnabled.timer {
            intVector = .timer
        }
        if intEnabled.serial && intEnabled.serial {
            intVector = .serial
        }
        if intEnabled.joypad && intEnabled.joypad {
            intVector = .joypad
        }
        
        if let intVector = intVector {
            disableIntAndJumpTo(vector: intVector)
            return 12 // TODO: uh? are we sure it's 12?
        }
        return 0
    }
    
    private func disableIntAndJumpTo(vector: InterruptVectors) {
        self.interruptState = .disabled
        push(registers.PC)
        jump(to: vector.rawValue)
    }
    
    func readByteAdvance() -> UInt8 {
        let byte = try! mmu.read(at: registers.PC)
        registers.PC += 1
        return byte
    }
    
    func readWordAdvance() -> UInt16 {
        let val = readWord(at: registers.PC)
        registers.PC += 2
        return val
    }
    
    func fetch() -> OpCode {
        return readByteAdvance()
    }
    
    func decode(code: OpCode) -> Instruction? {
        guard var ins = instructionLookup[code] else {
            print("Unknown opcode: \(String(format:"%02X", code))")
            return nil
        }
        if ins.isExtendedPrefix {
            let subCode = readByteAdvance()
            guard let extIns = instructionLookupExtended[subCode] else {
                print("Unknown opcode: \(String(format:"%02X%02X", code, subCode))")
                return nil
            }
            ins = extIns
        }
        
        switch(ins.length) {
        case .single:
            break
        case .double:
            ins.setParam(readByteAdvance())
        case .multi:
            ins.setParam(readWordAdvance())
        }
        return ins
    }
    
    func run(_ ins: Instruction, for currentPC: UInt16) -> Int {
        let cycles = ins.run(on: self)
#if DEBUG
        print("\(String(format:"0x%04X", currentPC)): \(ins.disassembly)")
#endif
        return cycles
    }
    
    func dumpRam(from: UInt16, to: UInt16) {
        var acc = 0
        for i in from..<to {
            if acc == 0 {
                print(String(format:"%04X", i), terminator:": ")
            }
            print(String(format:"%02X", try! mmu.read(at: i)), terminator:"")
            acc += 1
            if acc >= 16 {
                acc = 0
                print("\n", terminator: "")
            }
        }
    }
}

// MARK: Stack operations
extension CPU {
    func pop() -> UInt16 {
        let value = readWord(at: registers.SP)
        registers.SP += 2
        return value
    }
    
    func push(_ value: UInt16) {
        registers.SP -= 2
        write(word: value, at: registers.SP)
    }
}

// MARK: Call/Jump operations
extension CPU {
    func jump(to address: UInt8) {
        registers.PC = UInt16(address)
    }
    
    func jump(offset: UInt8) {
        registers.PC = UInt16(offset &+ registers.PC.lowerByte)
    }
    
    func jump(to address: UInt16) {
        registers.PC = address
    }
    
    func call(_ address: UInt16) {
        push(registers.PC)
        jump(to: address)
    }
    
    func ret() {
        registers.PC = pop()
    }
}

// MARK: int operations
extension CPU {
    func enableInterrupts() {
        interruptState = .enabled
    }
    
    func disableInterrupts() {
        interruptState = .disabled
    }
    
    func disableIntNext() {
        interruptState = .toDisable
    }
    
    func enableIntNext() {
        interruptState = .toEnable
    }
    
    func rst(to address: UInt8) {
        push(registers.PC)
        jump(to: address)
    }
}

// MARK: Misk operations
extension CPU {
    func nop() {
        
    }
    
    func stop() {
        state = .stop
    }
    
    func panic() {
        print("CPU PANIC!")
    }
}

// MARK: Address space
extension CPU {
    func read(at address: UInt16) -> UInt8 {
        return try! mmu.read(at: address)
    }
    
    func readWord(at address: UInt16) -> UInt16 {
        var word: UInt16 = 0
        word.lowerByte = try! mmu.read(at: address)
        word.upperByte = try! mmu.read(at: address + 1)
        return word
    }
    
    func write(byte: UInt8, at address: UInt16) {
        try! mmu.write(byte: byte, at: address)
    }
    
    func write(word: UInt16, at address: UInt16) {
        try! mmu.write(byte: word.lowerByte, at: address)
        try! mmu.write(byte: word.upperByte, at: address + 1)
    }
}
