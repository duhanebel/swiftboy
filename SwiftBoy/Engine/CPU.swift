//
//  CPU.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 25/11/2020.
//

import Foundation

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
    
    let ram = RAM()
    var registers = Registers()
    var flags = Flags()
    var cycles = 0
    
    let instructionLookup: [UInt8:Instruction] = {
        Instruction.allInstructions.reduce(into: [UInt8:Instruction]()) { table, item in table[item.opcode] = item }
    }()
    
    let instructionLookupExtended: [UInt8:Instruction] = {
        Instruction.allExtInstructions.reduce(into: [UInt8:Instruction]()) { table, item in table[item.opcode] = item }
    }()
    
    func tic() {
        let enableInterrupts = interruptState == .toEnable
        let disableInterrupts = interruptState == .toDisable
        
        let rawOp = fetch()
        guard let instruction = decode(code: rawOp) else { return }
        cycles += instruction()
        
        if enableInterrupts { interruptState = .enabled }
        else if disableInterrupts { interruptState = .disabled }
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
    
    func decode(code: OpCode) -> (()->Int)? {
        guard var ins = instructionLookup[code] else {
            print("Unknown opcode: \(String(format:"%02X", code))")
            return nil
        }
        if ins.isExtended {
            let subCode = readPCAdvance()
            guard let extIns = instructionLookupExtended[subCode] else {
                print("Unknown opcode: \(String(format:"%02X%02X", code, subCode))")
                return nil
            }
            ins = extIns
        }
        
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
    }

    func pop() -> UInt16 {
        let value = ram.readWord(at: registers.SP)
        registers.SP += 2
        return value
    }
    
    func push(_ value: UInt16) {
        registers.SP -= 2
        ram.write(word: value, at: registers.SP)
    }
}

extension CPU {
    func jump(to address: UInt8) {
        registers.PC = UInt16(address)
    }
    
    func jump(to address: UInt16) {
        registers.PC = address
    }
    
    func call(_ address: UInt16) {
        push(registers.PC &+ 1)
        jump(to: address)
    }
    
    func ret() {
        registers.PC = pop()
    }
    
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
    
    func nop() {
        
    }
    
    func stop() {
        state = .stop
    }
    
    func panic() {
        print("CPU PANIC!")
    }
}


