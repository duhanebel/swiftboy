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

final class Audio: Actor {
    
    var registers: APURegisters
    
    var pulseChannel1: Pulse
    var pulseChannel2: Pulse
    var waveChannel: Wave
    
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
    
    var stopwatch = Stopwatch()

    init(output: Synthetizer) {
        registers = APURegisters()
        
        self.pulseChannel1 = Pulse(with: registers.pulse1)
        self.pulseChannel2 = Pulse(with: registers.pulse2)
        self.waveChannel = Wave(with: registers.wave)
        
        self.output = output
        audioSampleRateCPUTics = CPU.clockSpeed / output.sampleRate
        
        sequencer = FrameSequencer()
        sequencer.envelopeHandler = self.volumeEnvelopeDidTic
        sequencer.sweepHandler = self.sweepDidTic
        sequencer.lengthHandler = self.lengthDidTic
    }
    
    func volumeEnvelopeDidTic() {
        self.pulseChannel1.volumeEnvelopeDidTic()
        self.pulseChannel2.volumeEnvelopeDidTic()
    }
    
    func sweepDidTic() {
        self.pulseChannel1.sweepDidTic()
    }
    
    func lengthDidTic() {
        self.pulseChannel1.lengthDidTic()
        self.pulseChannel2.lengthDidTic()
        self.waveChannel.lengthDidTic()
    }
    
    convenience init() {
        self.init(output: FMSynthesizer())
    }
    
    func tic() {
        sequencer.tic()
        guard registers.conf.powerControl.powerControl == true else { return }
        
        if currentTic == audioSampleRateCPUTics {
            let sample = Float(pulseChannel1.currentValue()) / Float(volumeSteps) +
                         Float(pulseChannel2.currentValue()) / Float(volumeSteps) +
                         Float(waveChannel.currentValue()) / Float(volumeSteps)
            buff.append(sample)
            if buff.count == Int(kSamplesPerBuffer) {
                let timeString = String(format: "%.4f", stopwatch.elapsedTimeInterval())
                let deltaTimeString = String(format: "%.6f", stopwatch.elapsedTimeInterval() - Double(buff.count)/Double(output.sampleRate))
                print("Elapsed: \(timeString) | \(deltaTimeString)")
                stopwatch.reset()
                output.play(buffer: buff)
                buff = Array<Float>()
                buff.reserveCapacity(Int(kSamplesPerBuffer))
            }
            currentTic = 0
        } else {
            currentTic += 1
        }
        pulseChannel1.tic()
        pulseChannel2.tic()
        waveChannel.tic()
    }
}
