//
//  WaveDuty.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 10/12/2022.
//

import Foundation

final class WaveDuty: Actor {
    private var dutyIndex = 0
    private var currentTic = 0
    
    var waveTable: [Byte]
    var ticFrequency: Int
    
    // Frequency here is the amount of tics before moving to the next wave value
    init(wave: [Byte], frequency: Int, startFrom: Int = 0) {
        self.waveTable = wave
        self.ticFrequency = frequency
        self.dutyIndex = startFrom
    }
    
    func tic() {
        if currentTic != ticFrequency {
            currentTic += 1
        } else {
            dutyIndex = (dutyIndex + 1) % waveTable.count
            currentTic = 0
        }
    }
    
    var currentValue: Byte { get { waveTable[dutyIndex] } }
}
