//
//  UInt8+BitsTests.swift
//  SwiftBoyTests
//
//  Created by Fabio Gallonetto on 26/11/2020.
//

import XCTest
@testable import SwiftBoy

class UInt8_BitsTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testReadsBits() throws {
        let num: UInt8 = 0b00010010
        XCTAssertEqual(num[4], 1)
        XCTAssertEqual(num[3], 0)
        XCTAssertEqual(num[1], 1)
    }
    
    func testSetsBits() throws {
        var num: UInt8 = 0b00010010
        num[2] = 1
        num[1] = 0
        XCTAssertEqual(num, 0b00010100)
    }
    
    func testSetsBitsIllegal() throws {
        var num: UInt8 = 0b00010010
        num[2] = 2
        num[1] = 0
        XCTAssertEqual(num, 0b00010100)
    }
    
    func testLowerNibble() throws {
        let num: UInt8 = 0xFA
        XCTAssertEqual(num.lowerNibble, 0x0A)
    }
    
    func testUpperNibble() throws {
        let num: UInt8 = 0xFA
        XCTAssertEqual(num.upperNibble, 0x0F)

    }
    
    func testWriteLowerNibble() throws {
        var num: UInt8 = 0xFA
        num.lowerNibble = 0x1
        XCTAssertEqual(num, 0xF1)
        
        num.lowerNibble = 0x21
        XCTAssertEqual(num, 0xF1)
    }
    
    func testWriteUpperNibble() throws {
        var num: UInt8 = 0xFA
        num.upperNibble = 0x1
        XCTAssertEqual(num, 0x1A)
        
        num.upperNibble = 0x21
        XCTAssertEqual(num, 0x1A)

    }
    
    func testComplement() throws {
        let num: UInt8 = 0b00010010
        XCTAssertEqual(num.complement, 0b11101101)
    }



}
