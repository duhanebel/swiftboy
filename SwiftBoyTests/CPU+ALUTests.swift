//
//  CPU+ALUTests.swift
//  SwiftBoyTests
//
//  Created by Fabio Gallonetto on 28/11/2020.
//

import XCTest
@testable import SwiftBoy

class CPU_ALUTests: XCTestCase {
    var cpu: CPU!

    override func setUpWithError() throws {
        cpu = CPU()
    }

    override func tearDownWithError() throws {
        cpu = nil
    }
    
    private func assertFlags(c: Bool, z: Bool, n: Bool, h: Bool) {
        XCTAssertEqual(cpu.flags.C, c)
        XCTAssertEqual(cpu.flags.Z, z)
        XCTAssertEqual(cpu.flags.N, n)
        XCTAssertEqual(cpu.flags.H, h)
    }

    func testRotateLeft() throws {
        var reg: UInt8 = 0b0001_0000
        cpu.rotateLeft(&reg, viaCarry: false)
        XCTAssertEqual(reg, 0b0010_0000)
        assertFlags(c: false, z: false, n: false, h: false)
        
        reg = 0b1001_0000
        cpu.rotateLeft(&reg, viaCarry: false)
        XCTAssertEqual(reg, 0b0010_0001)
        assertFlags(c: true, z: false, n: false, h: false)
        
        reg = 0b0000_0000
        cpu.rotateLeft(&reg, viaCarry: false)
        XCTAssertEqual(reg, 0b0000_0000)
        assertFlags(c: false, z: true, n: false, h: false)
    }
    
    func testRotateLeftCarry() throws {
        var reg: UInt8 = 0b0001_0000
        cpu.flags.C = true
        cpu.rotateLeft(&reg, viaCarry: true)
        XCTAssertEqual(reg, 0b0010_0001)
        assertFlags(c: false, z: false, n: false, h: false)
        
        reg = 0b1001_0000
        cpu.flags.C = false
        cpu.rotateLeft(&reg, viaCarry: true)
        XCTAssertEqual(reg, 0b0010_0000)
        assertFlags(c: true, z: false, n: false, h: false)
    }
    
    func testRotateRight() throws {
        var reg: UInt8 = 0b0001_0000
        cpu.rotateRight(&reg, viaCarry: false)
        XCTAssertEqual(reg, 0b0000_1000)
        assertFlags(c: false, z: false, n: false, h: false)
        
        reg = 0b0001_0001
        cpu.rotateRight(&reg, viaCarry: false)
        XCTAssertEqual(reg, 0b1000_1000)
        assertFlags(c: true, z: false, n: false, h: false)
        
        reg = 0b0000_0000
        cpu.rotateLeft(&reg, viaCarry: false)
        XCTAssertEqual(reg, 0b0000_0000)
        assertFlags(c: false, z: true, n: false, h: false)
    }
    
    func testRotateRighCarry() throws {
        var reg: UInt8 = 0b0001_0000
        cpu.flags.C = true
        cpu.rotateRight(&reg, viaCarry: true)
        XCTAssertEqual(reg, 0b1000_1000)
        assertFlags(c: false, z: false, n: false, h: false)
        
        reg = 0b0001_0001
        cpu.flags.C = false
        cpu.rotateRight(&reg, viaCarry: true)
        XCTAssertEqual(reg, 0b0000_1000)
        assertFlags(c: true, z: false, n: false, h: false)
    }
    
    func testInc() throws {
        var reg: UInt8 = 0b0001_0000
        cpu.inc(&reg)
        XCTAssertEqual(reg, 0b0001_0001)
        assertFlags(c: false, z: false, n: false, h: false)
        
        reg = 0b0000_1111
        cpu.inc(&reg)
        XCTAssertEqual(reg, 0b0001_0000)
        assertFlags(c: false, z: false, n: false, h: true)
        
        reg = 0b1111_1111
        cpu.inc(&reg)
        XCTAssertEqual(reg, 0b0000_0000)
        assertFlags(c: false, z: true, n: false, h: true)
        
        reg = 0b1111_1111
        cpu.inc(&reg)
        XCTAssertEqual(reg, 0b0000_0000)
        assertFlags(c: false, z: true, n: false, h: true)
    }
    
    func testDec() throws {
        var reg: UInt8 = 0b0000_1000
        cpu.dec(&reg)
        XCTAssertEqual(reg, 0b0000_0111)
        assertFlags(c: false, z: false, n: true, h: false)
        
        reg = 0b0001_0000
        cpu.dec(&reg)
        XCTAssertEqual(reg, 0b0000_1111)
        assertFlags(c: false, z: false, n: true, h: true)
        
        reg = 0b0000_00000
        cpu.dec(&reg)
        XCTAssertEqual(reg, 0b1111_1111)
        assertFlags(c: false, z: false, n: true, h: true)

        reg = 0b00000_0001
        cpu.dec(&reg)
        XCTAssertEqual(reg, 0b0000_0000)
        assertFlags(c: false, z: true, n: true, h: false)
    }
   
    func testAdd() {
        var reg: UInt8 = 0b0000_0100
        cpu.add(&reg, value: 0b0000_0100)
        XCTAssertEqual(reg, 0b0000_1000)
        assertFlags(c: false, z: false, n: false, h: false)
        
        reg  = 0b0000_1000
        cpu.add(&reg, value: 0b0000_1000)
        XCTAssertEqual(reg, 0b0001_0000)
        assertFlags(c: false, z: false, n: false, h: true)
        
        reg  = 0b1000_0001
        cpu.add(&reg, value: 0b1000_0000)
        XCTAssertEqual(reg, 0b0000_0001)
        assertFlags(c: true, z: false, n: false, h: false)
        
        reg  = 0b0000_0000
        cpu.add(&reg, value: 0b0000_0000)
        XCTAssertEqual(reg, 0b0000_0000)
        assertFlags(c: false, z: true, n: false, h: false)
    }
    
    func testAddCarry() {
        var reg: UInt8 = 0b0000_0100
        cpu.add(&reg, value: 0b0000_0100)
        XCTAssertEqual(reg, 0b0000_1000)
        assertFlags(c: false, z: false, n: false, h: false)
        
        reg  = 0b0000_1000
        cpu.add(&reg, value: 0b0000_1000)
        XCTAssertEqual(reg, 0b0001_0000)
        assertFlags(c: false, z: false, n: false, h: true)
        
        reg  = 0b1000_0001
        cpu.add(&reg, value: 0b1000_0000)
        XCTAssertEqual(reg, 0b0000_0001)
        assertFlags(c: true, z: false, n: false, h: false)
        
        reg  = 0b0000_0000
        cpu.add(&reg, value: 0b0000_0000)
        XCTAssertEqual(reg, 0b0000_0000)
        assertFlags(c: false, z: true, n: false, h: false)
    }
    
    func testSwap() {
        var reg: UInt8 = 0xFA
        cpu.swap(&reg)
        XCTAssertEqual(reg, 0xAF)
        assertFlags(c: false, z: false, n: false, h: false)
        
//        reg = 0x0
//        cpu.swap(&reg)
//        XCTAssertEqual(reg, 0x0)
//        assertFlags(c: false, z: true, n: false, h: false)
    }
    
    func testComplement() {
        var reg: UInt8 = 0b0011_0101
        cpu.complement(&reg)
        XCTAssertEqual(reg, 0b1100_1010)
    }
    
    func testAnd() {
        var reg: UInt8    = 0b0011_0101
        var value: UInt8  = 0b0101_1100
        cpu.and(&reg, value: value)
        XCTAssertEqual(reg, 0b0001_0100)
        assertFlags(c: false, z: false, n: false, h: true)

        reg   = 0b1111_0000
        value = 0b0000_1111
        cpu.and(&reg, value: value)
        XCTAssertEqual(reg, 0b0000_0000)
        assertFlags(c: false, z: true, n: false, h: true)
    }
    
    func testOr() {
        var reg: UInt8    = 0b0011_0101
        var value: UInt8  = 0b0101_1100
        cpu.or(&reg, value: value)
        XCTAssertEqual(reg, 0b0111_1101)
        assertFlags(c: false, z: false, n: false, h: false)
        
        reg   = 0b0
        value = 0b0
        cpu.or(&reg, value: value)
        XCTAssertEqual(reg, 0b0000_0000)
        assertFlags(c: false, z: true, n: false, h: false)
        
    }
    
    func testXor() {
        var reg: UInt8    = 0b0011_0101
        var value: UInt8  = 0b0101_1100
        cpu.xor(&reg, value: value)
        XCTAssertEqual(reg, 0b0110_1001)
        assertFlags(c: false, z: false, n: false, h: false)
        
        reg   = 0b1111_1111
        value = 0b1111_1111
        cpu.xor(&reg, value: value)
        XCTAssertEqual(reg, 0b0000_0000)
        assertFlags(c: false, z: true, n: false, h: false)
    }
    
    func testCmp() {
        var reg: UInt8   = 0b0000_1100
        var value: UInt8 = 0b0101_1100
        
        cpu.cmp(reg, value: value)
        assertFlags(c: true, z: false, n: true, h: false)
        
        reg   = 0b0000_0000
        value = 0b0000_1100
        
        cpu.cmp(reg, value: value)
        assertFlags(c: true, z: false, n: true, h: true)
    }
    
    func testDaa() {}
    
    func testSet() {
        var reg: UInt8 = 0b0000_1100
        cpu.set(1, of: &reg)
        XCTAssertEqual(reg, 0b0000_1110)
    }
    
    func testReset() {
        var reg: UInt8 = 0b0000_1100
        cpu.res(2, of: &reg)
        XCTAssertEqual(reg, 0b0000_1000)
    }
    
    func testBit() {
        var reg: UInt8 = 0b0000_1100
        cpu.bit(1, of: &reg)
        assertFlags(c: false, z: false, n: false, h: true)
        
        cpu.bit(2, of: &reg)
        assertFlags(c: false, z: true, n: false, h: true)

    }
}
