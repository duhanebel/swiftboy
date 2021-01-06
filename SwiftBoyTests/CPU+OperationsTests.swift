//
//  CPU+OperationsTests.swift
//  SwiftBoyTests
//
//  Created by Fabio Gallonetto on 30/12/2020.
//

import Foundation

import XCTest
@testable import SwiftBoy


// TODO: move this to alu
class CPU_OperationTests: XCTestCase {
    var cpu: CPU!

    override func setUpWithError() throws {
        let mmu = MemorySegment(size: 0xFFFF)
        let ir = InterruptRegister()
        let ie = InterruptRegister()
        cpu = CPU(mmu: mmu, intEnabled: ie, intRegister: ir)
    }

    override func tearDownWithError() throws {
        cpu = nil
    }
    
    private func assertFlags(c: Bool, z: Bool, n: Bool, h: Bool) {
        XCTAssertEqual(cpu.registers.flags.C, c)
        XCTAssertEqual(cpu.registers.flags.Z, z)
        XCTAssertEqual(cpu.registers.flags.N, n)
        XCTAssertEqual(cpu.registers.flags.H, h)
    }

    func testPushPop() throws {
        let value1: UInt16 = 0xFEE1
        let value2: UInt16 = 0xFEE2
        let value3: UInt16 = 0xFEE3

        cpu.push(value1)
        cpu.push(value2)
        cpu.push(value3)
        XCTAssertEqual(cpu.pop(), value3)
        XCTAssertEqual(cpu.pop(), value2)
        XCTAssertEqual(cpu.pop(), value1)
    }
    
    func testStoreAF() throws {
        let value: UInt16 = 0xFEE1
        cpu.registers.AF = value
        XCTAssertEqual(cpu.registers.A, 0xFE)
    }
}
