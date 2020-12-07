////
////  CircularBufferTests.swift
////  SwiftBoyTests
////
////  Created by Fabio Gallonetto on 05/12/2020.
////
//
//import XCTest
//@testable import SwiftBoy
//
//class CircularBufferTests: XCTestCase {
//
//    func testPushPop() throws {
//        var buffer = CircularBuffer<Int>(size: 3)
//        buffer.push(value: 5)
//        
//        XCTAssertEqual(buffer.pop(), 5)
//    }
//    
//    func testMultiPushPop() throws {
//        var buffer = CircularBuffer<Int>(size: 3)
//        buffer.push(value: 1)
//        buffer.push(value: 2)
//        buffer.push(value: 3)
//        
//        XCTAssertEqual(buffer.pop(), 1)
//        XCTAssertEqual(buffer.pop(), 2)
//        XCTAssertEqual(buffer.pop(), 3)
//    }
//    
//    func testDetectFull() throws {
//        var buffer = CircularBuffer<Int>(size: 3)
//        buffer.push(value: 1)
//        buffer.push(value: 2)
//        XCTAssertFalse(buffer.isFull)
//        buffer.push(value: 3)
//        XCTAssertTrue(buffer.isFull)
//        _ = buffer.pop()
//        XCTAssertFalse(buffer.isFull)
//    }
//    
//    func testDetectEmpty() throws {
//        var buffer = CircularBuffer<Int>(size: 3)
//        XCTAssertTrue(buffer.isEmpty)
//
//        buffer.push(value: 1)
//        buffer.push(value: 2)
//        XCTAssertFalse(buffer.isEmpty)
//        _ = buffer.pop()
//        _ = buffer.pop()
//        XCTAssertTrue(buffer.isEmpty)
//    }
//    
//    func testPushPopPastSize() throws {
//        var buffer = CircularBuffer<Int>(size: 3)
//        buffer.push(value: 1)
//        buffer.push(value: 2)
//        buffer.push(value: 3)
//        
//        XCTAssertEqual(buffer.pop(), 1)
//        XCTAssertEqual(buffer.pop(), 2)
//        XCTAssertEqual(buffer.pop(), 3)
//        
//        buffer.push(value: 4)
//        buffer.push(value: 5)
//        buffer.push(value: 6)
//        
//        XCTAssertEqual(buffer.pop(), 4)
//        XCTAssertEqual(buffer.pop(), 5)
//        XCTAssertEqual(buffer.pop(), 6)
//    }
//    
//    func testOverwriteCircular() throws {
//        var buffer = CircularBuffer<Int>(size: 3)
//        buffer.push(value: 1)
//        buffer.push(value: 2)
//        buffer.push(value: 3)
//        
//        buffer.push(value: 4)
//        buffer.push(value: 5)
//        
//        XCTAssertEqual(buffer.pop(), 4)
//        XCTAssertEqual(buffer.pop(), 5)
//        XCTAssertEqual(buffer.pop(), 3)
//    }
//
//}
