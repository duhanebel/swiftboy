//
//  OpcodesTests.swift
//  SwiftBoyTests
//
//  Created by Fabio Gallonetto on 13/12/2020.
//

import XCTest
@testable import SwiftBoy

struct Opcodes: Decodable {
    let unprefixed: [Opcode]
    let cbprefixed: [Opcode]
}

struct Opcode : Decodable {
    struct Operand: Decodable {
        let name: String
        let immediate: Bool
        let increment: Bool?
        let decrement: Bool?
        var string: String {
            var ret = name
            if let inc = increment, inc {
                ret += "+"
            }
            if let dec = decrement, dec {
                ret += "-"
            }
            if immediate == false {
                ret = "(\(ret))"
            }
            return ret
        }
    }
    
    struct Flags : Decodable {
        let Z: String
        let N: String
        let H: String
        let C: String
    }
    
    let code: String
    var opcode: UInt8 {
        return UInt8(code.dropFirst("0x".count), radix: 16)!
    }
    
    var asm: String {
        var res = mnemonic
        if operands.count > 0 {
            res += " "
            operands.forEach { op in
                res += op.string
                res += ", "
            }
            res =  String(res[..<res.lastIndex(of: ",")!])
        }
        return res
    }
    let mnemonic: String
    let bytes: Int
    let cycles: [Int]
    let operands: [Operand]
    let immediate: Bool
    let flags: Flags
}

class OpcodesTests: XCTestCase {
    
    lazy var opcodes: Opcodes = {
        let path = URL(fileURLWithPath: Bundle(for: OpcodesTests.self).path(forResource: "Opcodes", ofType: "json")!)
        let jsonData = try! Data(contentsOf: path)
        let decoder = JSONDecoder()
        
        return try! decoder.decode(Opcodes.self, from: jsonData)
        
    }()
    
    let instructions = Instruction.instructionMap()
    let prefixInstructions = Instruction.extInstructionMap()

    func testInsturctions() throws {
        
        opcodes.unprefixed.forEach { jsonIns in
            let ins = instructions[jsonIns.opcode]!
            XCTAssertNotNil(ins, "Unable to find instruction: \(jsonIns.opcode)")
            XCTAssertEqual(ins.asm, jsonIns.asm, "Error in asm definition for \(ins.opcode)")
            XCTAssertEqual(ins.length.rawValue, jsonIns.bytes, "Error in op length for \(ins.opcode)")
        
            if(jsonIns.cycles.count == 1) {
                XCTAssertNotNil(ins.cycles)
                XCTAssertEqual(ins.cycles!, jsonIns.cycles[0], "Error in cycles definition for \(ins.opcode)")
            }
        }
    }
    
    func testExtendedInstructions() throws {
        
        opcodes.cbprefixed.forEach { jsonIns in
            let ins = prefixInstructions[jsonIns.opcode]!
            XCTAssertNotNil(ins, "Unable to find instruction: \(jsonIns.opcode)")
            XCTAssertEqual(ins.asm, jsonIns.asm)
            
            XCTAssertEqual(ins.length.rawValue + 1, jsonIns.bytes, "Error in op length for \(ins.opcode)")
            
            if(jsonIns.cycles.count == 1) {
                XCTAssertNotNil(ins.cycles)
                XCTAssertEqual(ins.cycles!, jsonIns.cycles[0], "Error in cycles definition for \(ins.opcode)")
            }
        }
    }
}
