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
    var noiseChannel: Noise
    
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

    init(output: Synthetizer = FMSynthesizer()) {
        registers = APURegisters()
        
        self.pulseChannel1 = Pulse(with: registers.pulse1)
        self.pulseChannel2 = Pulse(with: registers.pulse2)
        self.waveChannel = Wave(with: registers.wave)
        self.noiseChannel = Noise(with: registers.noise)
        
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
        self.noiseChannel.volumeEnvelopeDidTic()
    }
    
    func sweepDidTic() {
        self.pulseChannel1.sweepDidTic()
    }
    
    func lengthDidTic() {
        self.pulseChannel1.lengthDidTic()
        self.pulseChannel2.lengthDidTic()
        self.waveChannel.lengthDidTic()
        self.noiseChannel.lengthDidTic()
    }
    
    func tic() {
        guard registers.conf.powerControl.powerControl == true else { return }
        sequencer.tic()
        
        pulseChannel1.tic()
        pulseChannel2.tic()
        waveChannel.tic()
        noiseChannel.tic()
        
        if currentTic == audioSampleRateCPUTics {
            
            if buff.count == Int(kSamplesPerBuffer) {
                printDebugLogTiming()
                
                output.play(buffer: buff)
                resetBuffer()
            } else {
                let sample = mixedSample()
                buff.append((sample.left + sample.right)/2)
            }
            currentTic = 0
        } else {
            currentTic += 1
        }
    }
    
    private func printDebugLogTiming() {
        let timeString = String(format: "%.4f", stopwatch.elapsedTimeInterval())
        let deltaTimeString = String(format: "%.6f", stopwatch.elapsedTimeInterval() - Double(buff.count)/Double(output.sampleRate))
        print("Elapsed: \(timeString) | \(deltaTimeString)")
        stopwatch.reset()
    }
    
    private func resetBuffer() {
        buff = Array<Float>()
        buff.reserveCapacity(Int(kSamplesPerBuffer))
    }
    
    private func mixedSample() -> (left: Float, right: Float) {
        var activeChannels: Float = 0
        var sampleLeft: Float = 0
        var sampleRight: Float = 0
        if pulseChannel1.isDACEnabled {
            activeChannels += 1
            let value = Float(pulseChannel1.currentValue()) / Float(volumeSteps)
            if registers.conf.enabledChannels.isLeftCh1Enabled { sampleLeft += value }
            if registers.conf.enabledChannels.isRightCh1Enabled { sampleRight += value }
        }
        
        if pulseChannel2.isDACEnabled {
            activeChannels += 1
            let value = Float(pulseChannel2.currentValue()) / Float(volumeSteps)
            if registers.conf.enabledChannels.isLeftCh2Enabled { sampleLeft += value }
            if registers.conf.enabledChannels.isRightCh2Enabled { sampleRight += value }
        }
        
        if waveChannel.isDACEnabled {
            activeChannels += 1
            let value = Float(waveChannel.currentValue()) / Float(volumeSteps)
            if registers.conf.enabledChannels.isLeftCh3Enabled { sampleLeft += value }
            if registers.conf.enabledChannels.isRightCh3Enabled { sampleRight += value }
        }
        
        if noiseChannel.isDACEnabled {
            activeChannels += 1
            let value = Float(noiseChannel.currentValue()) / Float(volumeSteps)
            if registers.conf.enabledChannels.isLeftCh4Enabled { sampleLeft += value }
            if registers.conf.enabledChannels.isRightCh4Enabled { sampleRight += value }
        }
        
        return (left: (sampleLeft / activeChannels), right:(sampleRight / activeChannels))
    }
}
