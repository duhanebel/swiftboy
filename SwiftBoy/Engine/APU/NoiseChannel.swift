//
//  NoiseChannel.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 11/12/2022.
//

import Foundation

extension APURegisters.Noise {
    var frequencyTics: UInt16 {
        get {
            var freqTics = (shiftDivisor.divisor << 4)
            if freqTics == 0 { freqTics = 8 }
            freqTics = freqTics << shiftDivisor.clockShift
            return UInt16(freqTics)
        }
    }
}

final class Noise: Actor {
    private var lfsr: LinearFeedbackShiftRegister
    
    private let register: APURegisters.Noise
    
    private var lengthTimer: LengthTimer
    private var volumeEnvelope: VolumeEnvelope
    
    var isEnabled: Bool
    
    private var frequencyTics: UInt16 = 0
    
    func tic() {

      //  lfsr.tic()// freuqenc!
    }
    
    func volumeEnvelopeDidTic() {
        guard isEnabled == true else { return }
        volumeEnvelope.tic()
        if volumeEnvelope.volume == 0 { isEnabled = false }
    }
    
    func lengthDidTic() {
        guard isEnabled == true else { return }
        if register.trigger.lengthEnabled {
            lengthTimer.tic()
            if lengthTimer.hasFired { self.isEnabled = false }
        }
    }
    
    init(with register: APURegisters.Noise) {
        self.register = register
        
        self.lfsr = LinearFeedbackShiftRegister(mode: (register.shiftDivisor.width == .narrow) ? .short : .long)
        
        self.lengthTimer = LengthTimer(initialLength: register.length.lengthTimer)
        self.volumeEnvelope = VolumeEnvelope(initialVolume: register.volumeEnvelope.initialVolume,
                                             direction: register.volumeEnvelope.direction,
                                             pace: register.volumeEnvelope.sweepPace)
        self.isEnabled = register.trigger.trigger
        register.observer = self
    }
    
    private func reset() {
        self.lfsr = LinearFeedbackShiftRegister(mode: (register.shiftDivisor.width == .narrow) ? .short : .long)
        
        self.lengthTimer = LengthTimer(initialLength: register.length.lengthTimer)
        self.volumeEnvelope = VolumeEnvelope(initialVolume: register.volumeEnvelope.initialVolume,
                                             direction: register.volumeEnvelope.direction,
                                             pace: register.volumeEnvelope.sweepPace)
        self.isEnabled = register.trigger.trigger
    }
    
    func currentValue() -> Byte {
        volumeEnvelope.volume * lfsr.value
    }
}

extension Noise: MemoryObserver {
    var observedRange: Range<UInt16> {
        APURegisters.MemoryLocations.noise.lowerBound..<APURegisters.MemoryLocations.noise.upperBound
    }
    
    func memoryChanged(sender: MemoryMappable, at address: Address, with: Byte) {
        switch(address) {
        case APURegisters.MemoryLocations.NR41:
            self.lengthTimer = LengthTimer(initialLength: register.length.lengthTimer)
        case APURegisters.MemoryLocations.NR42:
            self.volumeEnvelope = VolumeEnvelope(initialVolume: register.volumeEnvelope.initialVolume,
                                                 direction: register.volumeEnvelope.direction,
                                                 pace: register.volumeEnvelope.sweepPace)
        case APURegisters.MemoryLocations.NR43:
            self.lfsr = LinearFeedbackShiftRegister(mode: (register.shiftDivisor.width == .narrow) ? .short : .long)
        case APURegisters.MemoryLocations.NR44:
            if register.trigger.trigger == true { reset() }
        default:
            ()
        }
    }
    
}
