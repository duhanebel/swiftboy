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
    private(set) var storedCount = 0
    
    init(size: Int) {
        storage = Array<T>(repeating: T.init(nilLiteral: ()), count: size)
    }
    
    var count: Int {
        return storage.count
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
        writeIndex = (writeIndex + 1) % count
        storedCount += 1
    }
    
    mutating func pop() -> T {
        assert(!isEmpty, "Cannot pop from an empty buffer")
        
        let val = storage[readIndex]
        readIndex = (readIndex + 1) % count
        storedCount -= 1
        return val
    }
    
    mutating func pop(count popCount: Int) -> [T] {
        assert(!isEmpty, "Cannot pop from an empty buffer")
        assert(popCount<=count, "Not enough items to pop")
        var val: Array<T>
        if readIndex + popCount < count {
            val = Array(storage[readIndex..<readIndex+popCount])
        } else {
            let rangeUntilEndOfArray = readIndex..<count
            let remainingWrappedAroundRange = 0..<(popCount-(count-readIndex))
            val = Array(storage[rangeUntilEndOfArray] + storage[remainingWrappedAroundRange])
        }
        readIndex = (readIndex + popCount) % count
        storedCount -= popCount
        return val
    }
}

extension CircularBuffer {
    mutating func mixWith(_ buffer: [T?]) {
        assert(buffer.count <= storage.count)
        for (idx, item) in buffer.enumerated() {
            if let item = item {
                storage[(readIndex + idx) % count] = item
            }
        }
    }
}
