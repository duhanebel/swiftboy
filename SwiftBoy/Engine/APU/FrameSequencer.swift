//
//  FrameSequencer.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 26/11/2022.
//

import Foundation

typealias CompletionHandler = () -> Void

/*
 This sequencer is clocked about every 8192 CPU cycles (it runs at 512hz,
 CPU runs at 4194304hz, 4194304/512=8192).
 There's 8-steps to the frame sequencer, so every 8192 cpu cycles is 1 step.
 Every other step, the length counter is clocked in each channel, on the 7th step,
 the envelope is clocked, and on the 2nd and 6th step, the sweep
 generator is clocked.
 https://www.reddit.com/r/EmuDev/comments/5gkwi5/comment/dat3zni/
 */
final class FrameSequencer: Actor {
    private let CPUTics = CPU.clockSpeed / 512
    private var clock = 0
    
    var lengthHandler: CompletionHandler?
    var envelopeHandler: CompletionHandler?
    var sweepHandler: CompletionHandler?
    var cpuTic = 0
    
    /*
     Step   Length Ctr  Vol Env     Sweep
     ---------------------------------------
     0      Clock       -           -
     1      -           -           -
     2      Clock       -           Clock
     3      -           -           -
     4      Clock       -           -
     5      -           -           -
     6      Clock       -           Clock
     7      -           Clock       -
     ---------------------------------------
     Rate   256 Hz      64 Hz       128 Hz
     
     The frame sequencer clocks are derived from the DIV timer. In Normal Speed Mode,
     falling edges of bit 5 step the FS. Here bits 5 refer to the bits of the upper byte of DIV.
    */
    func tic() {
        guard cpuTic == CPUTics else { cpuTic += 1; return }
        
        // 256Hz - every other tic
        if clock % 2 == 1 {
            lengthHandler?()
        }
        
        // 128Hz - every 4 tics
        // TODO: when does it actually clocks up???
        if clock % 4 == 3 {
            sweepHandler?()
        }
        
        // 64Hz - every 8 ticks
        if clock == 7 {
            envelopeHandler?()
        }
        
        clock = (clock + 1) % 8
        cpuTic = 0
    }
    
}
