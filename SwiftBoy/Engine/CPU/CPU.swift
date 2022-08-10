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
        
        // Bottom 4 bits of the flag register are always zero and can't be changed
        // for example by a direct write to AF
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
    
    var description: String {
        var description = ""
        description += (Z == true) ? "Z" : "z"
        description += (N == true) ? "N" : "n"
        description += (H == true) ? "H" : "h"
        description += (C == true) ? "C" : "c"
        return description
    }
}

// Registers are initialised to specific values at boot
struct Registers {
    var A: UInt8 = 0x01
    var flags: Flags = Flags(values: 0xB0)

    var BC: UInt16 = 0x0013
    var DE: UInt16 = 0x00D8
    var HL: UInt16 = 0x014D
    
    var SP: UInt16 = 0xFFFE
    var PC: UInt16 = 0x0000

    var AF: UInt16 {
        get {
            var AF: UInt16 = 0
            AF.upperByte  = A
            AF.lowerByte = flags.byteValue
            return AF
        }
        set {
            A = newValue.upperByte
            flags = Flags(values: newValue.lowerByte)
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
    
    var description: String {
        var description = "AF:\(AF) "
        description += "BC:\(BC) "
        description += "DE:\(DE) "
        description += "HL:\(HL) "
        description += "SP:\(SP)v"
        return description
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
        
        switch(state) {
        case .running:
            return (interruptTics > 0) ? interruptTics : fetchExecute()
        case .halt:
            fallthrough
        case .stop:
            return interruptTics > 0 ? interruptTics : 1
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
        if enableInterrupts {
            interruptState = .enabled
        }
        else if disableInterrupts {
            interruptState = .disabled
        }
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
        // See below re "state != .running"
        guard interruptState == .enabled || state != .running else { return 0 }

        // TODO: what's the priority of interrupts?
        var intVector: InterruptVectors? = nil
        if intEnabled.VBlank && intRegister.VBlank {
            intVector = .VBlank
        } else if intEnabled.LCDStat && intRegister.LCDStat {
            intVector = .LCDStat
        } else if intEnabled.timer && intRegister.timer {
            intVector = .timer
        } else if intEnabled.serial && intRegister.serial {
            intVector = .serial
        } else if intEnabled.joypad && intRegister.joypad {
            intVector = .joypad
        }
        
        if let intVector = intVector {
            /*
             The HALT state is left when an enabled interrupt occurs, no matter if the IME
             is enabled or not. However, if the IME is disabled the program counter register
             is frozen for one incrementation process upon leaving the HALT state.
             TODO: implmenet halt bug!
             */
            if state != .running {
                state = .running
                return 0
            }
            
            disableInterrupts()
            call(intVector.rawValue)
        
            switch(intVector) {
            case .VBlank:
                intRegister.VBlank = false
            case .LCDStat:
                intRegister.LCDStat = false
            case .timer:
                intRegister.timer = false
            case .serial:
                intRegister.serial = false
            case .joypad:
                intRegister.joypad = false
            }
            return 32 // TODO: uh? are we sure it's 32?
        }
        return 0
    }
    
//    private func disableIntAndJumpTo(vector: InterruptVectors) {
//        self.interruptState = .disabled
//        push(registers.PC)
//        jump(to: vector.rawValue)
//    }
    
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
#if DEBUG
    static var debug = false
#endif
    func run(_ ins: Instruction, for currentPC: UInt16) -> Int {
        #if DEBUG
        
        if(CPU.debug) {
            print("\(currentPC): \(ins.disassembly) ; \(ins.opcode, prefix: "")")
        }
        #endif
        let cycles = ins.run(on: self)
        #if DEBUG
        if(CPU.debug) {
            print("        \(registers.flags.description) \(registers.description)")
        }
#endif
        return cycles
    }
    
    func dumpRam(from: UInt16, to: UInt16) {
        var acc = 0
        for i in from..<to {
            if acc == 0 {
                print("\(i)", terminator:":")
            }
            print("\(try! mmu.read(at: i), prefix:" ")", terminator:"")
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
    
    func call(_ address: UInt16, if flag: Bool, is value: Bool) -> Bool {
        if flag == value {
            call(address)
            return true
        } else {
            return false
        }
    }
    
    func jump(address: UInt16, if flag: Bool, is value: Bool) -> Bool {
        if flag == value {
            jump(to: address)
            return true
        } else {
            return false
        }
    }
    
    func jump(offset: UInt8, if flag: Bool, is value: Bool) -> Bool {
        if flag == value {
            jump(offset: offset)
            return true
        } else {
            return false
        }
    }
    
    func ret(if flag: Bool, is value: Bool) -> Bool {
        if flag == value {
            ret()
            return true
        } else {
            return false
        }
    }
    
    func jump(offset: UInt8) {
        var offset16 = UInt16(offset)
        // If it's negative (2-complement) number the negative prefix must be extended
        if offset[7] == 1 {
            offset16.upperByte = 0xFF
        }
        registers.PC = registers.PC &+ offset16
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
        jump(to: UInt16(address))
    }
}

// MARK: Misk operations
extension CPU {
    func nop() {
        
    }
    
    func stop() {
        // Prevent stalling the CPU if there are no interrupts
        if intEnabled.allOff {
            registers.PC += 1
            return
        }
        state = .stop
    }
    
    func halt() {
        // Prevent stalling the CPU if there are no interrupts
        if intEnabled.allOff {
            registers.PC += 1
            return
        }
        state = .halt
    }
    
    func panic() {
        print("CPU PANIC!")
    }
}

// MARK: Address space
extension CPU {
    func read(at address: UInt16) -> UInt8 {
        do {
            return try mmu.read(at: address)
        } catch {
            print("ERROR: Invalid read at: \(address)")
            return 0x00
        }
    }
    
    func readWord(at address: UInt16) -> UInt16 {
        var word: UInt16 = 0
        word.lowerByte = try! mmu.read(at: address)
        word.upperByte = try! mmu.read(at: address + 1)
        return word
    }
    
    func read(atFF haddress: UInt8) -> UInt8 {
        return read(at: (0xFF00 + UInt16(haddress)))
    }
    
    func write(byte: UInt8, at address: UInt16) {
        do {
            try mmu.write(byte: byte, at: address)
        }
        catch {
            //print("ERROR: Invalid write at: \(address)")
        }
    }
    
    func write(word: UInt16, at address: UInt16) {
        do {
            try mmu.write(byte: word.lowerByte, at: address)
            try mmu.write(byte: word.upperByte, at: address + 1)
        }
        catch {
            print("Write to bad ram \(address)")
            return
        }
    }
    
    func write(byte: UInt8, atFF haddress: UInt8) {
        write(byte: byte, at: (0xFF00 + UInt16(haddress)))
    }
}
