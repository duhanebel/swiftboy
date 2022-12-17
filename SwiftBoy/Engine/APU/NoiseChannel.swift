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
    
    private var ticFrequency: UInt16 = 0
    private var currentTic = 0
    
    
    func tic() {
        guard isEnabled == true else { return }
        
        if currentTic != ticFrequency {
            currentTic += 1
        } else {
            lfsr.tic()
        }
    }
    
    func volumeEnvelopeDidTic() {
        guard isEnabled == true else { return }
        volumeEnvelope.tic()
        // The envelope reaching a volume of 0 does NOT turn the channel off!
        // if volumeEnvelope.volume == 0 { isEnabled = false }
    }
    
    func lengthDidTic() {
        guard isEnabled == true else { return }
        if register.trigger.lengthEnabled {
            lengthTimer.tic()
            if lengthTimer.hasFired { isEnabled = false }
        }
    }
    
    init(with register: APURegisters.Noise) {
        self.register = register
        
        self.lfsr = LinearFeedbackShiftRegister(mode: (register.shiftDivisor.width == .narrow) ? .short : .long)
        
        self.lengthTimer = LengthTimer(withRegister: register.length)
        self.volumeEnvelope = VolumeEnvelope(withRegister: register.volumeEnvelope)
        self.isEnabled = register.trigger.trigger
        register.observer = self
    }
    
    private func reset() {
        self.lfsr = LinearFeedbackShiftRegister(mode: (register.shiftDivisor.width == .narrow) ? .short : .long)
        
        self.lengthTimer = LengthTimer(withRegister: register.length)
        self.volumeEnvelope = VolumeEnvelope(withRegister: register.volumeEnvelope)
        self.isEnabled = register.trigger.trigger && register.volumeEnvelope.isDACEnabled
        
        let shiftedDivisor = UInt16(register.shiftDivisor.divisor) << 4
        self.ticFrequency = (shiftedDivisor > 0 ? shiftedDivisor : 8) << register.shiftDivisor.clockShift
      //  self.ticFrequency = UInt16(CPU.clockSpeed) / self.ticFrequency
        self.currentTic = 0
    }
    
    func currentValue() -> Byte {
        guard self.isEnabled else { return 0 }
        
        return volumeEnvelope.volume * lfsr.value
    }
    
    var isDACEnabled: Bool { get { return register.volumeEnvelope.isDACEnabled } }
}

extension Noise: MemoryObserver {
    var observedRange: Range<UInt16> {
        APURegisters.MemoryLocations.noise.lowerBound..<APURegisters.MemoryLocations.noise.upperBound
    }
    
    func memoryChanged(sender: MemoryMappable, at address: Address, with: Byte) {
        switch(address) {
        case APURegisters.MemoryLocations.NR41:
            self.lengthTimer = LengthTimer(withRegister: register.length)
            
        case APURegisters.MemoryLocations.NR42:
            self.isEnabled = register.volumeEnvelope.isDACEnabled
            // Writes to this register while the channel is on require retriggering it afterwards.
            //self.volumeEnvelope = VolumeEnvelope(withRegister: register.volumeEnvelope)
        case APURegisters.MemoryLocations.NR43:
            self.lfsr = LinearFeedbackShiftRegister(mode: (register.shiftDivisor.width == .narrow) ? .short : .long)
            let shiftedDivisor = UInt16(register.shiftDivisor.divisor) << 4
            self.ticFrequency = (shiftedDivisor > 0 ? shiftedDivisor : 8) << register.shiftDivisor.clockShift
          //  self.ticFrequency = UInt16(CPU.clockSpeed) / self.ticFrequency

        case APURegisters.MemoryLocations.NR44:
            if register.trigger.trigger == true { reset() }
        default:
            ()
        }
    }
}
