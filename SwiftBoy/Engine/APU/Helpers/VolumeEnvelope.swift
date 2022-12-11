//
//  VolumeEnvelope.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 11/12/2022.
//

import Foundation

final class VolumeEnvelope: Actor {
    private var currentTic = 0
    var volume: Byte
    
    private let direction: APURegisters.VolumeAndEnvelopeRegister.EnvelopeDirection
    private let pace: Byte
    
    // Frequency here is the amount of tics before moving to the next wave value
    init(initialVolume: Byte,
         direction: APURegisters.VolumeAndEnvelopeRegister.EnvelopeDirection,
         pace: Byte) {
        self.volume = initialVolume
        self.direction = direction
        self.pace = pace
    }
    
    func tic() {
        if currentTic != pace {
            currentTic += 1
        } else {
            // Volume is 4 bits so 16 values max
            if direction == .increase  && volume < 15 {
                volume += 1
            } else if volume > 0 {
                volume -= 1
            }
            currentTic = 0
        }
    }
}
