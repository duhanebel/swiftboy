//
//  FMSynthesizer.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 27/11/2022.
//

import Foundation
import AVFoundation

// The maximum number of audio buffers in flight. Setting to two allows one
// buffer to be played while the next is being written.
private let kInFlightAudioBuffers: Int = 2

// The number of audio samples per buffer. A lower value reduces latency for
// changes but requires more processing but increases the risk of being unable
// to fill the buffers in time. A setting of 1024 represents about 23ms of
// samples.
 let kSamplesPerBuffer: AVAudioFrameCount = 4 * 1024

final class FMSynthesizer: Synthetizer {

    private let engine: AVAudioEngine = AVAudioEngine()
    private let playerNode: AVAudioPlayerNode = AVAudioPlayerNode()
    let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)!
    private let audioBuffers: [AVAudioPCMBuffer]
    //private var stopWatches: [Stopwatch]

    // The index of the next buffer to fill.
    private var bufferIndex: Int = 0
    
    var sampleRate: Int {
        get { Int(audioFormat.sampleRate) }
    }

    init() {
        audioBuffers = Array<AVAudioPCMBuffer>(repeating: AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: kSamplesPerBuffer)!,
                                               count: kInFlightAudioBuffers)
      //  stopWatches = Array<Stopwatch>(repeating: Stopwatch(), count: kInFlightAudioBuffers)

        // Attach and connect the player node.
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: audioFormat)

        do {
            try engine.start()
            playerNode.play()
        } catch {
            // TODO: move this up and put it in a better place
            print("ERROR: initializing audio")
        }
    }
    
    func play(buffer: [Float]) {
        let audioBuffer = self.audioBuffers[self.bufferIndex]
        let leftChannel = audioBuffer.floatChannelData![0]
        let rightChannel = audioBuffer.floatChannelData![1]
        
        for (index, value) in buffer.enumerated() {
            leftChannel[index] = value
            rightChannel[index] = value
        }
        audioBuffer.frameLength = AVAudioFrameCount(buffer.count)

        let playingIdx = self.bufferIndex
        //var stopwatch = stopWatches[self.bufferIndex]
        //stopwatch.reset()
        
        self.playerNode.scheduleBuffer(audioBuffer) {
          //  print("*** APS: \(stopwatch.elapsedTimeInterval())")
         //   if self.bufferIndex != playingIdx { print("UNDERRUN: ", terminator: "")}
        }
        
        self.bufferIndex = (self.bufferIndex + 1) % self.audioBuffers.count
        
        
    }
}
