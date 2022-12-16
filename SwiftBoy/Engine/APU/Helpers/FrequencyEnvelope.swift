//
//  FrequencyEnvelope.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 11/12/2022.
//

import Foundation

final class FrequencyEnvelope: Actor {
    private var currentTic = 0
    var frequency: Int
    
    private let direction: APURegisters.SweepRegister.SweepDirection
    private let pace: Byte
    private let slope: Byte
    
    // Frequency here is the amount of tics before moving to the next wave value
    init(initialFrequency: UInt16,
         direction: APURegisters.SweepRegister.SweepDirection,
         pace: Byte,
         slope: Byte) {
        self.frequency = Int(initialFrequency)
        self.direction = direction
        self.pace = pace
        self.slope = slope
    }
    
    // The freuqency is a 11bit value so it will overflow at > 2^11-1 = 0x7FF
    var isOverflow: Bool {
        get { return frequency > 0x7FF }
    }
    
    func tic() {
        // if slope is zero then nothing happens
        guard slope != 0 else { return }
        
        if currentTic != pace {
            currentTic += 1
        } else {
            // final frenquecy is +/- current_frequency / 2^slope
            // remember that dividing by a power of two is a bitshift!
            let freqDelta = frequency >> slope
            switch(direction) {
            case .add:
                frequency += freqDelta
            case .sub:
                frequency -= freqDelta
            }
        }
    }
}

extension FrequencyEnvelope {
    convenience init(initialFrequency: UInt16, register: APURegisters.SweepRegister) {
        self.init(initialFrequency: initialFrequency,
                         direction: register.direction,
                              pace: register.pace,
                             slope: register.slope)
    }
}
