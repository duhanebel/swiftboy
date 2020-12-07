//
//  CircularBuffer.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 05/12/2020.
//

import Foundation

struct CircularBuffer<T: ExpressibleByNilLiteral> {
    
    private var storage: [T]
    private var readIndex = 0
    private var writeIndex = 0
    private var storedCount = 0
    
    init(size: Int) {
        storage = Array<T>(repeating: T.init(nilLiteral: ()), count: size)
    }
    
    var count: Int {
        return storedCount
    }
    
    var isEmpty: Bool {
        return storedCount == 0
    }
    
    var isFull: Bool {
        return storedCount == count
    }
    
    mutating func clear() {
        readIndex = 0
        writeIndex = 0
        storedCount = 0
    }
    
    mutating func push(value: T) {
        storage[writeIndex] = value
        writeIndex = (writeIndex + 1) % storage.count
        storedCount += 1
    }
    
    mutating func pop() -> T {
        assert(!isEmpty, "Cannot pop from an empty buffer")
        
        let val = storage[readIndex]
        readIndex = (readIndex + 1) % storage.count
        storedCount -= 1
        return val
    }
}
