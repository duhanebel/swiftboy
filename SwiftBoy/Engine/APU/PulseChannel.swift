//
//  PulseChannel.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 10/12/2022.
//

import Foundation

extension APURegisters.DutyAndLengthRegister.WaveDuty {
    var waveValues: [Byte] {
        switch(self) {
        case .quarter:
            return [1, 0, 0, 0, 0, 0, 0, 1] // 25%   duty wave
        case .eigth:
            return [0, 0, 0, 0, 0, 0, 0, 1] // 12.5% duty wave
        case .half:
            return [1, 0, 0, 0, 0, 1, 1, 1] // 50%   duty wave
        case .twoThirds:
            return [0, 1, 1, 1, 1, 1, 1, 0] // 65%   duty wave
        }
    }
}

/*
 The actual signal frequency is 131072 / (2048 - freq) Hz.
 This is the whole wave’s frequency; the rate at which the channel steps
 through the 8 “steps”.
 The frequency of each step would be 8 times that, which is 1048576 / (2048 - freq) Hz.
 Note that 1048576 is 1Mhz, if we divide the CPU freq (to get the number of tics, we end up with: 4 * (2048 - freq)
 */
private func frequencyToTics(_ frequency: UInt16) -> Int {
    return (2048 - Int(frequency)) * 4
}

final class Pulse: Actor {

    private var dutyIndex = 0
    private var lengthTimer: LengthTimer
    var wave: WaveDuty
    var volumeEnvelope: VolumeEnvelope
    var frequencySweep: FrequencyEnvelope
    var isEnabled: Bool
    
    private let register: APURegisters.Pulse
    
    init(with register: APURegisters.Pulse) {
        self.register = register
        
        self.volumeEnvelope = VolumeEnvelope(initialVolume: register.volumeEnvelope.initialVolume,
                                             direction: register.volumeEnvelope.direction,
                                             pace: register.volumeEnvelope.sweepPace)
        self.frequencySweep = FrequencyEnvelope(initialFrequency: register.frequency,
                                                direction: register.sweep.direction,
                                                pace: register.sweep.pace,
                                                slope: register.sweep.slope)
        self.lengthTimer = LengthTimer(initialLength: register.dutyLength.lengthTimer)
        self.isEnabled = register.freqHIAndTrigger.trigger
        
        self.wave = WaveDuty(wave: register.dutyLength.waveDuty.waveValues,
                             frequency: frequencyToTics(register.frequency))
        
        register.observer = self
    }
    
    deinit {
        register.observer = nil
    }
    
    func reset() {
        self.volumeEnvelope = VolumeEnvelope(initialVolume: register.volumeEnvelope.initialVolume,
                                             direction: register.volumeEnvelope.direction,
                                             pace: register.volumeEnvelope.sweepPace)
        self.frequencySweep = FrequencyEnvelope(initialFrequency: register.frequency,
                                                direction: register.sweep.direction,
                                                pace: register.sweep.pace,
                                                slope: register.sweep.slope)
        self.lengthTimer = LengthTimer(initialLength: register.dutyLength.lengthTimer)
        self.isEnabled = register.freqHIAndTrigger.trigger
        

        self.wave = WaveDuty(wave: register.dutyLength.waveDuty.waveValues,
                             frequency: frequencyToTics(register.frequency))
    }
    
    func tic() {
        wave.tic()
        
    }

    
    func volumeEnvelopeDidTic() {
        guard isEnabled == true else { return }
        volumeEnvelope.tic()
        if volumeEnvelope.volume == 0 { isEnabled = false }
    }
    
    func sweepDidTic() {
        guard isEnabled == true else { return }
        frequencySweep.tic()
        if frequencySweep.isOverflow { self.isEnabled = false }
        else {
            wave.ticFrequency = frequencyToTics(UInt16(frequencySweep.frequency))
        }
    }
    
    func lengthDidTic() {
        guard isEnabled == true else { return }
        if register.freqHIAndTrigger.lengthEnabled {
            lengthTimer.tic()
            if lengthTimer.hasFired { self.isEnabled = false }
        }
    }
    
    func currentValue() -> Byte {
        return volumeEnvelope.volume * wave.currentValue
    }
}

extension Pulse: MemoryObserver {
    var observedRange: Range<UInt16> {
        register.baseAddress..<register.baseAddress+5 //TODO better range?
    }
    
    func memoryChanged(sender: MemoryMappable, at address: Address, with: Byte) {
        switch(address) {
        case (register.baseAddress + APURegisters.Pulse.MemoryLocationOffsets.sweep.rawValue):
            self.frequencySweep = FrequencyEnvelope(initialFrequency: register.frequency,
                                                    direction: register.sweep.direction,
                                                    pace: register.sweep.pace,
                                                    slope: register.sweep.slope)
        case (register.baseAddress + APURegisters.Pulse.MemoryLocationOffsets.dutyLength.rawValue):
            self.wave.waveTable = register.dutyLength.waveDuty.waveValues
            
            self.lengthTimer = LengthTimer(initialLength: register.dutyLength.lengthTimer)
        case (register.baseAddress + APURegisters.Pulse.MemoryLocationOffsets.volumeEnvelope.rawValue):
            self.volumeEnvelope = VolumeEnvelope(initialVolume: register.volumeEnvelope.initialVolume,
                                                 direction: register.volumeEnvelope.direction,
                                                 pace: register.volumeEnvelope.sweepPace)
        case (register.baseAddress + APURegisters.Pulse.MemoryLocationOffsets.freqLow.rawValue):
            wave.ticFrequency = frequencyToTics(register.frequency)
        case (register.baseAddress + APURegisters.Pulse.MemoryLocationOffsets.freqHighTrigger.rawValue):
            if register.freqHIAndTrigger.trigger == true {
                reset()
            } else {
                wave.ticFrequency = frequencyToTics(register.frequency)
            }
        default:
            ()
        }
    }
    
    
}
