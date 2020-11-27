//
//  UInt16+BytesTests.swift
//  SwiftBoyTests
//
//  Created by Fabio Gallonetto on 25/11/2020.
//

import XCTest
@testable import SwiftBoy

class UInt16_BytesTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSetsLowerByte() throws {
        var num: UInt16 = 0x1234
        num.lowerByte = 0xA5
        XCTAssertEqual(num, 0x12A5)
    }
    
    func testSetsUpperByte() throws {
        var num: UInt16 = 0x1234
        num.upperByte = 0xA5
        XCTAssertEqual(num, 0xA534)
    }
    
    func testReadsLowerByte() throws {
        let num: UInt16 = 0xA1F2
        XCTAssertEqual(num.lowerByte, 0xF2)
    }
    
    func testReadsUpperByte() throws {
        let num: UInt16 = 0xA1F2
        XCTAssertEqual(num.upperByte, 0xA1)
    }

}
