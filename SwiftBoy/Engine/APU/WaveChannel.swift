//
//  WaveChannel.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 10/12/2022.
//

import Foundation

extension APURegisters.Wave {
    func getDutyValues() -> [Byte] {
        var wave = Array<Byte>()
        for idx in 0..<16 {
            let byteAddress = MemoryLocations.wavePattern.lowerBound + UInt16(idx)
            let waveByte = try! wavePattern.read(at: byteAddress)
            
            // As CH3 plays, it reads wave RAM left to right, upper nibble first.
            // That is, $FF30’s upper nibble, $FF30’s lower nibble, $FF31’s upper nibble,
            // and so on.
            wave.append(waveByte.upperNibble)
            wave.append(waveByte.lowerNibble)
        }
        return wave
    }
}

/*
 The actual signal frequency is 65536 / (2048 - freq) Hz.
 This is the whole wave’s frequency; the rate at which the channel steps
 through the 32 “steps”.
 The frequency of each step would be 32 times that, which is 2097152 / (2048 - freq) Hz.
 Note that 2097152 is 2Mhz, if we divide the CPU freq (to get the number of tics,
 we end up with: 2 * (2048 - freq)
 */
private func frequencyToTics(_ frequency: UInt16) -> Int {
    return (2048 - Int(frequency)) * 2
}

final class Wave: Actor {
    var volume: Byte
    var isEnabled: Bool
    
    var wave: WaveDuty
    private var lengthTimer: LengthTimer
    
    private var currentSweepTic: Int = 0
    
    private let register: APURegisters.Wave
    
    init(with register: APURegisters.Wave) {
        self.register = register
        self.volume = register.volume.rawValue
        self.isEnabled = register.freqHIAndTrigger.trigger
        
        self.wave = WaveDuty(wave: register.getDutyValues(),
                             frequency: frequencyToTics(register.frequency),
                             startFrom: 1)
        self.lengthTimer = LengthTimer(initialLength: register.lengthLoad)

        register.observer = self
    }
    
    deinit {
        register.observer = nil
    }
    
    func reset() {
        self.volume = register.volume.rawValue
        
        self.isEnabled = register.freqHIAndTrigger.trigger
        
        /* When CH3 is started, the first sample read is the one at index 1, i.e. the lower nibble of the first byte, NOT the upper nibble.
         */
        self.wave = WaveDuty(wave: register.getDutyValues(),
                             frequency: frequencyToTics(register.frequency),
                             startFrom: 1)
        self.lengthTimer = LengthTimer(initialLength: register.lengthLoad)

    }
    
    func tic() {
        wave.tic()
    }
    
    func lengthDidTic() {
        guard isEnabled == true else { return }
        if register.freqHIAndTrigger.lengthEnabled {
            lengthTimer.tic()
            if lengthTimer.hasFired { self.isEnabled = false }
        }
    }
   
    func currentValue() -> Byte {
        switch(register.volume) {
        case .mute:
            return 0
        case .full:
            return wave.currentValue
        case .half:
            return wave.currentValue / 2
        case .quarter:
            return wave.currentValue / 4
        }
    }
}

extension Wave: MemoryObserver {
    var observedRange: Range<UInt16> {
        APURegisters.MemoryLocations.wave.lowerBound..<APURegisters.MemoryLocations.wave.upperBound
    }
    
    func memoryChanged(sender: MemoryMappable, at address: Address, with: Byte) {
        switch(address) {
        case APURegisters.MemoryLocations.NR30:
            self.isEnabled = register.power
            if register.power { reset() }
        case APURegisters.MemoryLocations.NR31:
            self.lengthTimer = LengthTimer(initialLength: register.lengthLoad)
        case APURegisters.MemoryLocations.NR32:
            ()
        case APURegisters.MemoryLocations.NR33:
            wave.ticFrequency = frequencyToTics(register.frequency)
        case APURegisters.MemoryLocations.NR34:
            if register.freqHIAndTrigger.trigger == true {
                reset()
            } else {
                wave.ticFrequency = frequencyToTics(register.frequency)
            }
        case APURegisters.MemoryLocations.wavePattern:
            self.wave.waveTable = register.getDutyValues()
        default:
            ()
        }
    }
    
}
