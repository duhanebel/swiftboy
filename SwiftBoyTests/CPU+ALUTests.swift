//
//  CPU+ALUTests.swift
//  SwiftBoyTests
//
//  Created by Fabio Gallonetto on 28/11/2020.
//

import XCTest
@testable import SwiftBoy


// TODO: move this to alu
class CPU_ALUTests: XCTestCase {
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

    func testRotateLeft() throws {
        var reg: UInt8 = 0b0001_0000
        reg = cpu.rotateLeft(reg, viaCarry: false)
        XCTAssertEqual(reg, 0b0010_0000)
        assertFlags(c: false, z: false, n: false, h: false)
        
        reg = 0b1001_0000
        reg = cpu.rotateLeft(reg, viaCarry: false)
        XCTAssertEqual(reg, 0b0010_0001)
        assertFlags(c: true, z: false, n: false, h: false)
        
        reg = 0b0000_0000
        reg = cpu.rotateLeft(reg, viaCarry: false)
        XCTAssertEqual(reg, 0b0000_0000)
        assertFlags(c: false, z: true, n: false, h: false)
    }
    
    func testRotateLeftCarry() throws {
        var reg: UInt8 = 0b0001_0000
        cpu.registers.flags.C = true
        reg = cpu.rotateLeft(reg, viaCarry: true)
        XCTAssertEqual(reg, 0b0010_0001)
        assertFlags(c: false, z: false, n: false, h: false)
        
        reg = 0b1001_0000
        cpu.registers.flags.C = false
        reg = cpu.rotateLeft(reg, viaCarry: true)
        XCTAssertEqual(reg, 0b0010_0000)
        assertFlags(c: true, z: false, n: false, h: false)
    }
    
    func testRotateRight() throws {
        var reg: UInt8 = 0b0001_0000
        reg = cpu.rotateRight(reg, viaCarry: false)
        XCTAssertEqual(reg, 0b0000_1000)
        assertFlags(c: false, z: false, n: false, h: false)
        
        reg = 0b0001_0001
        reg = cpu.rotateRight(reg, viaCarry: false)
        XCTAssertEqual(reg, 0b1000_1000)
        assertFlags(c: true, z: false, n: false, h: false)
        
        reg = 0b0000_0000
        reg = cpu.rotateLeft(reg, viaCarry: false)
        XCTAssertEqual(reg, 0b0000_0000)
        assertFlags(c: false, z: true, n: false, h: false)
    }
    
    func testRotateRighCarry() throws {
        var reg: UInt8 = 0b0001_0000
        cpu.registers.flags.C = true
        reg = cpu.rotateRight(reg, viaCarry: true)
        XCTAssertEqual(reg, 0b1000_1000)
        assertFlags(c: false, z: false, n: false, h: false)
        
        reg = 0b0001_0001
        cpu.registers.flags.C = false
        reg = cpu.rotateRight(reg, viaCarry: true)
        XCTAssertEqual(reg, 0b0000_1000)
        assertFlags(c: true, z: false, n: false, h: false)
    }
    
    func testInc() throws {
        var reg: UInt8 = 0b0001_0000
        cpu.registers.flags.C = true // C is not affected
        reg = cpu.inc(reg)
        XCTAssertEqual(reg, 0b0001_0001)
        assertFlags(c: true, z: false, n: false, h: false)
        
        reg = 0b0000_1111
        reg = cpu.inc(reg)
        XCTAssertEqual(reg, 0b0001_0000)
        assertFlags(c: true, z: false, n: false, h: true)
        
        reg = 0b1111_1111
        reg = cpu.inc(reg)
        XCTAssertEqual(reg, 0b0000_0000)
        assertFlags(c: true, z: true, n: false, h: true)
        
        reg = 0b1111_1111
        reg = cpu.inc(reg)
        XCTAssertEqual(reg, 0b0000_0000)
        assertFlags(c: true, z: true, n: false, h: true)
    }
    
    func testInc16() throws {
        var reg: UInt16 = 0x0101
        reg = cpu.inc(reg)
        XCTAssertEqual(reg, 0x0102)
        
        reg = 0xFFFF
        reg = cpu.inc(reg)
        XCTAssertEqual(reg, 0x0000)
    }
    
    func testDec() throws {
        var reg: UInt8 = 0b0000_1000
        cpu.registers.flags.C = true // C is not affected
        reg = cpu.dec(reg)
        XCTAssertEqual(reg, 0b0000_0111)
        assertFlags(c: true, z: false, n: true, h: false)
        
        reg = 0b0001_0000
        reg = cpu.dec(reg)
        XCTAssertEqual(reg, 0b0000_1111)
        assertFlags(c: true, z: false, n: true, h: true)
        
        reg = 0b0000_00000
        reg = cpu.dec(reg)
        XCTAssertEqual(reg, 0b1111_1111)
        assertFlags(c: true, z: false, n: true, h: true)

        reg = 0b00000_0001
        reg = cpu.dec(reg)
        XCTAssertEqual(reg, 0b0000_0000)
        assertFlags(c: true, z: true, n: true, h: false)
    }
    
    func testDec16() throws {
        var reg: UInt16 = 0x0102
        reg = cpu.dec(reg)
        XCTAssertEqual(reg, 0x0101)
        
        reg = 0x0000
        reg = cpu.dec(reg)
        XCTAssertEqual(reg, 0xFFFF)
    }
   
    func testAdd() {
        var reg: UInt8 = 0b0000_0100
        reg = cpu.add(reg, value: 0b0000_0100)
        XCTAssertEqual(reg, 0b0000_1000)
        assertFlags(c: false, z: false, n: false, h: false)
        
        reg  = 0b0000_1000
        reg = cpu.add(reg, value: 0b0000_1000)
        XCTAssertEqual(reg, 0b0001_0000)
        assertFlags(c: false, z: false, n: false, h: true)
        
        reg  = 0b1000_0001
        reg = cpu.add(reg, value: 0b1000_0000)
        XCTAssertEqual(reg, 0b0000_0001)
        assertFlags(c: true, z: false, n: false, h: false)
        
        reg  = 0b0000_0000
        reg = cpu.add(reg, value: 0b0000_0000)
        XCTAssertEqual(reg, 0b0000_0000)
        assertFlags(c: false, z: true, n: false, h: false)
    }
    
    func testAddCarry() {
        var reg: UInt8 = 0b0000_0100
        cpu.registers.flags.C = true
        reg = cpu.adc(reg, value: 0b0000_0100)
        XCTAssertEqual(reg, 0b0000_1001)
        assertFlags(c: false, z: false, n: false, h: false)
        
        reg  = 0b1111_1111
        cpu.registers.flags.C = false
        reg = cpu.adc(reg, value: 0b0000_0010)
        XCTAssertEqual(reg, 0b0000_0001)
        assertFlags(c: true, z: false, n: false, h: true)

        reg  = 0b1111_1111
        cpu.registers.flags.C = true
        reg = cpu.adc(reg, value: 0b0000_0001)
        XCTAssertEqual(reg, 0b0000_0001)
        assertFlags(c: true, z: false, n: false, h: false)
    }
    
    func testAdd16_8() throws {
        var reg: UInt16 = 0x0102
        reg = cpu.add(reg, value: UInt16(0x20))
        XCTAssertEqual(reg, 0x0122)
        
        reg = 0xFFFF
        reg = cpu.add(reg, value: UInt16(0x02))
        XCTAssertEqual(reg, 0x0001)
    }
    
    func testSub() {
        var reg: UInt8 = 0b0000_1000
        reg = cpu.sub(reg, value: 0b0000_0010)
        XCTAssertEqual(reg, 0b0000_0110)
        assertFlags(c: false, z: false, n: true, h: false)
        
        reg  = 0b0001_0000
        reg = cpu.sub(reg, value: 0b0000_0001)
        XCTAssertEqual(reg, 0b0000_1111)
        assertFlags(c: false, z: false, n: true, h: true)
        
        reg  = 0b0000_0010
        reg = cpu.sub(reg, value: 0b0000_0011)
        XCTAssertEqual(reg, 0b1111_1111)
        assertFlags(c: true, z: false, n: true, h: true)
        
        reg  = 0b0000_0001
        reg = cpu.sub(reg, value: 0b0000_0001)
        XCTAssertEqual(reg, 0b0000_0000)
        assertFlags(c: false, z: true, n: true, h: false)
    }
    
    func testSubCarry() {
        var reg: UInt8  = 0b0000_1000
        cpu.registers.flags.C = true
        reg = cpu.sbc(reg, value: 0b0000_0001)
        XCTAssertEqual(reg, 0b0000_0110)
        assertFlags(c: false, z: false, n: true, h: false)
        
        reg  = 0b0000_0000
        cpu.registers.flags.C = false
        reg = cpu.sbc(reg, value: 0b0000_0001)
        XCTAssertEqual(reg, 0b1111_1111)
        assertFlags(c: true, z: false, n: true, h: true)

        reg  = 0b0000_0000
        cpu.registers.flags.C = true
        reg = cpu.sbc(reg, value: 0b0000_0001)
        XCTAssertEqual(reg, 0b1111_1110)
        assertFlags(c: true, z: false, n: true, h: false)
    }
    
    func testSwap() {
        var reg: UInt8 = 0xFA
        reg = cpu.swap(reg)
        XCTAssertEqual(reg, 0xAF)
        assertFlags(c: false, z: false, n: false, h: false)
    }
    
    func testComplement() {
        var reg: UInt8 = 0b0011_0101
        reg = cpu.complement(reg)
        XCTAssertEqual(reg, 0b1100_1010)
    }
    
    func testAnd() {
        var reg: UInt8    = 0b0011_0101
        var value: UInt8  = 0b0101_1100
        reg = cpu.and(reg, value: value)
        XCTAssertEqual(reg, 0b0001_0100)
        assertFlags(c: false, z: false, n: false, h: true)

        reg   = 0b1111_0000
        value = 0b0000_1111
        reg = cpu.and(reg, value: value)
        XCTAssertEqual(reg, 0b0000_0000)
        assertFlags(c: false, z: true, n: false, h: true)
    }
    
    func testOr() {
        var reg: UInt8    = 0b0011_0101
        var value: UInt8  = 0b0101_1100
        reg = cpu.or(reg, value: value)
        XCTAssertEqual(reg, 0b0111_1101)
        assertFlags(c: false, z: false, n: false, h: false)
        
        reg   = 0b0
        value = 0b0
        reg = cpu.or(reg, value: value)
        XCTAssertEqual(reg, 0b0000_0000)
        assertFlags(c: false, z: true, n: false, h: false)
    }
    
    func testXor() {
        var reg: UInt8    = 0b0011_0101
        var value: UInt8  = 0b0101_1100
        reg = cpu.xor(reg, value: value)
        XCTAssertEqual(reg, 0b0110_1001)
        assertFlags(c: false, z: false, n: false, h: false)
        
        reg   = 0b1111_1111
        value = 0b1111_1111
        reg = cpu.xor(reg, value: value)
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
        reg = cpu.set(1, of: reg)
        XCTAssertEqual(reg, 0b0000_1110)
    }
    
    func testReset() {
        var reg: UInt8 = 0b0000_1100
        reg = cpu.res(2, of: reg)
        XCTAssertEqual(reg, 0b0000_1000)
    }
    
    func testBit() {
        let reg: UInt8 = 0b0000_1100
        cpu.registers.flags.C = false // C is not affected
        cpu.bit(1, of: reg)
        assertFlags(c: false, z: true, n: false, h: true)
        
        cpu.bit(2, of: reg)
        assertFlags(c: false, z: false, n: false, h: true)

    }
}
