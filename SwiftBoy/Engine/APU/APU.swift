//
//  APU.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 02/01/2021.
//

import Foundation




protocol Synthetizer {
    var sampleRate: Int { get }
    func play(buffer: [Float])
}



final class Pulse: Actor {
    enum WaveForm: UInt8 {
        case oneEight = 0
        case oneQuarter
        case half
        case threeQuarters
    }
    
    private let wavetable: [[Byte]] = [[0, 0, 0, 0, 0, 0, 0, 1], // 12.5% duty wave
                                       [1, 0, 0, 0, 0, 0, 0, 1], // 25%   duty wave
                                       [1, 0, 0, 0, 0, 1, 1, 1], // 50%   duty wave
                                       [0, 1, 1, 1, 1, 1, 1, 0]] // 65%   duty wave

    private var dutyIndex = 0
    private var length: Byte
    var waveForm: WaveForm
    var frequency: UInt16
    var volume: Byte
    var isEnabled: Bool
    
    private var pulseTics: Int
    private var currentTic = 0
    
    private var currentVolumeEnvelopeTic: Int = 0
    
    private let register: APURegisters.Pulse
    
    
    init(with register: APURegisters.Pulse) {
        self.register = register
        
        self.length = register.dutyLength.lengthTimer
        self.waveForm = WaveForm(rawValue: register.dutyLength.waveDuty.rawValue)!
        self.frequency = register.frequency
        self.volume = register.volumeEnvelope.initialVolume
        
        self.isEnabled = register.freqHIAndTrigger.trigger
        self.pulseTics = (2048 - Int(frequency)) * 4
        
        register.observer = self
    }
    
    deinit {
        register.observer = nil
    }
    
    func reset() {
        self.length = register.dutyLength.lengthTimer
        self.waveForm = WaveForm(rawValue: register.dutyLength.waveDuty.rawValue)!
        self.frequency = register.frequency
        self.volume = register.volumeEnvelope.initialVolume
        
        self.isEnabled = register.freqHIAndTrigger.trigger
        
        /*
           The actual signal frequency is 131072 / (2048 - freq) Hz.
           This is the whole wave’s frequency; the rate at which the channel steps
           through the 8 “steps”.
           The frequency of each step would be 8 times that, which is 1048576 / (2048 - freq) Hz.
           Note that 1048576 is 1Mhz, if we divide the CPU freq (to get the number of tics, we end up with: 4 * (2048 - freq)
        */
        self.pulseTics = (2048 - Int(frequency)) * 4
        self.currentTic = 0
    }
    
    func tic() {
        guard currentTic == pulseTics else { currentTic += 1; return }
        
        dutyIndex = (dutyIndex + 1) % 8
        currentTic = 0
    }
    
    func currentValue() -> Byte {
        return volume * wavetable[Int(waveForm.rawValue)][dutyIndex]
    }
    
    func volumeEnvelopeDidTic() {
        guard isEnabled == true else { return }
        
        if currentVolumeEnvelopeTic == register.volumeEnvelope.sweepPace {
            // Volume is 4 bits so 16 values max
            if register.volumeEnvelope.direction == .increase  && volume < 15 {
                volume += 1
            } else if volume > 0 {
                volume -= 1
            }
            if volume == 0 { isEnabled = false }
            currentVolumeEnvelopeTic = 0
        } else {
            currentVolumeEnvelopeTic += 1
        }
    }
    
   
}

extension Pulse: MemoryObserver {
    var observedRange: Range<UInt16> {
        register.baseAddress..<register.baseAddress+5 //TODO better range?
    }
    
    func memoryChanged(sender: MemoryMappable, at address: Address, with: Byte) {
        switch(address) {
        //case APURegisters.MemoryLocations.NR10:
        case APURegisters.MemoryLocations.NR11:
            self.waveForm = WaveForm(rawValue: register.dutyLength.waveDuty.rawValue)!
            self.length = register.dutyLength.lengthTimer
        case APURegisters.MemoryLocations.NR12:
            ()
        case APURegisters.MemoryLocations.NR13:
            frequency = register.frequency
        case APURegisters.MemoryLocations.NR14:
            frequency = register.frequency
            if register.freqHIAndTrigger.trigger == true {
                reset()
            }
        default:
            ()
        }
    }
    
    
}



final class Audio: Actor {
    
    var registers: APURegisters
    
    var pulseChannel: Pulse
    
    private var currentTic = 0
    
    private var buff: [Float] = {
        var a = Array<Float>()
        a.reserveCapacity(Int(kSamplesPerBuffer))
        return a
    }()
    
    private let output: Synthetizer
    private let audioSampleRateCPUTics: Int
    
    private let sequencer: FrameSequencer
    
    // Volume of each channel is described by 4bits so the range is 0-15, 16 steps.
    private let volumeSteps = 16

    init(output: Synthetizer) {
        registers = APURegisters()
        
        self.pulseChannel = Pulse(with: registers.pulse1)
        
        self.output = output
        audioSampleRateCPUTics = CPU.clockSpeed / output.sampleRate
        
        sequencer = FrameSequencer()
        sequencer.envelopeHandler = self.volumeEnvelopeDidTic
    }
    
    func volumeEnvelopeDidTic() {
        self.pulseChannel.volumeEnvelopeDidTic()
    }
    
    convenience init() {
        self.init(output: FMSynthesizer())
    }
    
    func tic() {
        sequencer.tic()
        guard registers.conf.powerControl.powerControl == true else { return }
      //  guard registers.pulse1.freqHIAndTrigger.trigger == true else { return }
        
        if currentTic ==  audioSampleRateCPUTics {
            buff.append(Float(pulseChannel.currentValue())/Float(volumeSteps))
            if buff.count == Int(kSamplesPerBuffer) {
                output.play(buffer: buff)
                buff = Array<Float>()
                buff.reserveCapacity(Int(kSamplesPerBuffer))
            }
            currentTic = 0
        } else {
            currentTic += 1
        }
        pulseChannel.tic()
    }
}


extension Audio: MemoryObserver {
    var observedRange: Range<UInt16> {
        APURegisters.MemoryLocations.range
    }
    
    func memoryChanged(sender: MemoryMappable, at address: Address, with: Byte) {
        switch(address) {
        
        default:
            ()
        }
    }
    
    
}
