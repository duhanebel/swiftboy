//
//  APURegisters.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 22/11/2022.
//

import Foundation

/*
 APU Registers:
               Bit-layout
 Name | Addr | 7654 3210 | Init | Description
 -----+------+-----------+------+---------------------------------
Pulse 1:
 NR10 | FF10 | -PPP NSSS | 0x80 | Sweep period, negate, shift
 NR11 | FF11 | DDLL LLLL | 0xBF | Duty, Length load (64-L)
 NR12 | FF12 | VVVV APPP | 0xF3 | Starting volume, Envelope add mode, period
 NR13 | FF13 | FFFF FFFF | 0x00 | Frequency LSB
 NR14 | FF14 | TL-- -FFF | 0xBF | Trigger, Length enable, Frequency MSB

Pulse 2:
 ---- | FF15 | ---- ---- | ---- | Not used
 NR21 | FF16 | DDLL LLLL | 0x3F | Duty, Length load (64-L)
 NR22 | FF17 | VVVV APPP | 0x00 | Starting volume, Envelope add mode, period
 NR23 | FF18 | FFFF FFFF | 0x00 | Frequency LSB
 NR24 | FF19 | TL-- -FFF | 0xBF | Trigger, Length enable, Frequency MSB

Wave:
 NR30 | FF1A | E--- ---- | 0x7F | DAC power
 NR31 | FF1B | LLLL LLLL | 0xFF | Length load (256-L)
 NR32 | FF1C | -VV- ---- | 0x9F | Volume code (00=0%, 01=100%, 10=50%, 11=25%)
 NR33 | FF1D | FFFF FFFF | 0x00 | Frequency LSB
 NR34 | FF1E | TL-- -FFF | 0xBF | Trigger, Length enable, Frequency MSB

Noise:
 ---- | FF1F | ---- ---- | ---- | Not used
 NR41 | FF20 | --LL LLLL | 0xFF | Length load (64-L)
 NR42 | FF21 | VVVV APPP | 0x00 | Starting volume, Envelope add mode, period
 NR43 | FF22 | SSSS WDDD | 0x00 | Clock shift, Width mode of LFSR, Divisor code
 NR44 | FF23 | TL-- ---- | 0xBF | Trigger, Length enable

Control/Status:
 NR50 | FF24 | ALLL BRRR | 0x77 | Vin L enable, Left vol, Vin R enable, Right vol
 NR51 | FF25 | NW21 NW21 | 0xF3 | Left enables, Right enables
 NR52 | FF26 | P--- NW21 | 0xF1 | Power control/status, Channel length statuses

 */
final class APURegisters: MemoryMappable {
    
    struct MemoryLayout {
        static let Pulse1 = (address: Address(0xFF10), size: 5)
        static let Pulse2 = (address: Address(0xFF15), size: 5)
        static let Wave = (address: Address(0xFF30), size: 5)
        static let Noise = (address: Address(0xFF1F), size: 5)
        static let Control = (address: Address(0xFF24), size: 3)
        static let Unused = (address: Address(0xFF27), size: 9)
        static let WavePattern = (address: Address(0xFF30), size:16)
        static let size = Pulse1.size + Pulse2.size + Wave.size +
                          Noise.size + Control.size + Unused.size + WavePattern.size
    }

    final class Pulse {
        enum MemoryLayoutOffsets {
            static let sweepShift = UInt16(0)
            static let timerDuty = UInt16(1)
            static let volumeEnvelope = UInt16(2)
            static let freqLow = UInt16(3)
            static let freqHighTrigger = UInt16(4)
        }
        
        struct SweepMemoryBitLayout {
            static let unused    = 7
            static let sweepPace = (4, 6)
            static let sweepDir  = 3
            static let sweepCtrl = (0, 2)
        }
        
        enum Direction: UInt8 {
            case increase = 0
            case decrease = 1
        }
        
        var rawmem: MemorySegment
        let registerAddress: Address
        
        init(memory: MemorySegment, registerAddress: Address) {
            self.registerAddress = registerAddress
            rawmem = memory
            try! rawmem.write(byte: 0x80, at: registerAddress + MemoryLayoutOffsets.sweepShift)
            try! rawmem.write(byte: 0xBF, at: registerAddress + MemoryLayoutOffsets.timerDuty)
            try! rawmem.write(byte: 0xF3, at: registerAddress + MemoryLayoutOffsets.volumeEnvelope)
            try! rawmem.write(byte: 0xBF, at: registerAddress + MemoryLayoutOffsets.freqHighTrigger)

        }
        
        private var sweepRegister: Byte {
            get { try! rawmem.read(at: registerAddress + MemoryLayoutOffsets.sweepShift)}
        }
        
        private var timerDutyRegister: Byte {
            get { try! rawmem.read(at: registerAddress + MemoryLayoutOffsets.timerDuty)}
        }
        
        private var volumeEnvelopeRegister: Byte {
            get { try! rawmem.read(at: registerAddress + MemoryLayoutOffsets.volumeEnvelope)}
        }
        
        private var frequencyLowRegister: Byte {
            get { try! rawmem.read(at: registerAddress + MemoryLayoutOffsets.freqLow)}
        }
        
        private var frequencyHighTrigger: Byte {
            get { try! rawmem.read(at: registerAddress + MemoryLayoutOffsets.freqHighTrigger)}
        }
  
        // //////////
        // Sweep register
        var sweepPace: Byte {
            get { sweepRegister[SweepMemoryBitLayout.sweepPace] }
        }
        
        var sweepDirection: Direction {
            get { Direction(rawValue: sweepRegister[SweepMemoryBitLayout.sweepDir])! }
        }
        
        var sweepSlope: Byte {
            get { sweepRegister[SweepMemoryBitLayout.sweepCtrl] }
        }
        
        // ////////////
        // Timer & Duty register
        struct TimerDutyBitLayout {
            static let waveDuty  = (6,7)
            static let lenghtTimer = (0, 5)
        }
    
        enum WaveDuty: UInt8 {
            case eigth     = 0b00
            case quarter   = 0b01
            case half      = 0b10
            case twoThirds = 0b11
        }
        
        var lengthTimer: Byte {
            get { timerDutyRegister[TimerDutyBitLayout.lenghtTimer] }
        }
        
        var waveDuty: WaveDuty {
            get { WaveDuty(rawValue: timerDutyRegister[TimerDutyBitLayout.waveDuty])! }
        }
        
        // /////////////
        // Volume & Envelope
        struct VolumeEnvelopeBitLayout {
            static let initialVolume = (4,7)
            static let direction  = 3
            static let period = (0, 2)
        }
        
        enum EnvelopeDirection: UInt8 {
            case decrease = 0
            case increase = 1
        }
        
        var envelopeInitialVolume: Byte {
            get { volumeEnvelopeRegister[VolumeEnvelopeBitLayout.initialVolume] }
        }
        
        var envelopeDirection: EnvelopeDirection {
            get { EnvelopeDirection(rawValue: volumeEnvelopeRegister[VolumeEnvelopeBitLayout.direction])! }
        }
        
        var envelopePeriod: Byte {
            get { volumeEnvelopeRegister[VolumeEnvelopeBitLayout.period] }
        }
        
        // /////////////
        // High Frequency & Trigger
        struct TriggerFreqBitLayout {
            static let trigger = 7
            static let lengthEnabled = 6
        }
        var frequency: UInt16 {
            get {
                return  (UInt16(frequencyHighTrigger) & 0b0000_0111 << 5) | UInt16(frequencyLowRegister)
            }
        }
        
        var trigger: Bool {
            get { return frequencyHighTrigger[TriggerFreqBitLayout.trigger] == 1}
        }
        
        var lengthEnabled: Bool {
            get { return frequencyHighTrigger[TriggerFreqBitLayout.lengthEnabled] == 1}
        }
        
    }
    
    final class Wave {
        struct MemoryLayoutOffsets {
            static let DACPower = UInt16(0xFF1A)
            static let lengthLoad = UInt16(0xFF1B)
            static let volume = UInt16(0xFF1C)
            static let freqLow = UInt16(0xFF1D)
            static let freqHighTrigger = UInt16(0xFF1E)
        }
        
        var rawmem: MemorySegment
        
        init(memory: MemorySegment) {
            rawmem = memory
            try! rawmem.write(byte: 0x7F, at: MemoryLayoutOffsets.DACPower)
            try! rawmem.write(byte: 0xFF, at: MemoryLayoutOffsets.lengthLoad)
            try! rawmem.write(byte: 0x9F, at: MemoryLayoutOffsets.volume)
            try! rawmem.write(byte: 0xBF, at: MemoryLayoutOffsets.freqHighTrigger)
        }
        
        private var dacPower: Byte {
            get { try! rawmem.read(at: MemoryLayoutOffsets.DACPower)}
        }
        
        private var frequencyLowRegister: Byte {
            get { try! rawmem.read(at: MemoryLayoutOffsets.freqLow)}
        }
        
        private var frequencyHighTrigger: Byte {
            get { try! rawmem.read(at: MemoryLayoutOffsets.freqHighTrigger)}
        }
        
        // /////////////
        struct DACPowerBitLayout {
            static let power    = 7
        }
        
        var power: Bool {
            get { return dacPower[DACPowerBitLayout.power] == 1 }
        }
        
        var lengthLoad: Byte {
            get { try! rawmem.read(at: MemoryLayoutOffsets.lengthLoad)}
        }
        
        enum Volume: UInt8 {
            case mute = 0
            case full = 1
            case half = 2
            case quarter = 3
        }
        
        struct VolumeBitLayout {
            static let volume = (6,5)
        }
        var volume: Volume {
            get {
                let volumeByte = try! rawmem.read(at: MemoryLayoutOffsets.volume)
                return Volume(rawValue: volumeByte[VolumeBitLayout.volume] )!
            }
        }
        
        // /////////////
        // High Frequency & Trigger
        struct TriggerFreqBitLayout {
            static let trigger = 7
            static let lengthEnabled = 6
        }
        var frequency: UInt16 {
            get {
                return (UInt16(frequencyHighTrigger) & 0b0000_0111 << 5) |
                        UInt16(frequencyLowRegister)
            }
        }
        
        var trigger: Bool {
            get { return frequencyHighTrigger[TriggerFreqBitLayout.trigger] == 1}
        }
        
        var lengthEnabled: Bool {
            get { return frequencyHighTrigger[TriggerFreqBitLayout.lengthEnabled] == 1}
        }
    }
    
    final class Noise {
        struct MemoryLayoutOffsets {
            static let unused = UInt16(0xFF1F)
            static let lengthLoad = UInt16(0xFF20)
            static let volumeEnvelope = UInt16(0xFF21)
            static let clockWidth = UInt16(0xFF22)
            static let triggerLength = UInt16(0xFF23)
        }
        
        var rawmem: MemorySegment
        
        init(memory: MemorySegment) {
            rawmem = memory
            try! rawmem.write(byte: 0xFF, at: MemoryLayoutOffsets.lengthLoad)
            try! rawmem.write(byte: 0xBF, at: MemoryLayoutOffsets.triggerLength)
        }
        
        
        // Only 6 bits are used, the upper two are unused
        private var lengthLoad: Byte {
            get { try! rawmem.read(at: MemoryLayoutOffsets.lengthLoad) & 0b0011_1111 }
        }
        
        private var volumeEnvelopeRegister: Byte {
            get { try! rawmem.read(at: MemoryLayoutOffsets.volumeEnvelope) }
        }
        
        private var triggerLength: Byte {
            get { try! rawmem.read(at: MemoryLayoutOffsets.triggerLength) }
        }
        
        // /////////////
        // Volume & Envelope
        struct VolumeEnvelopeBitLayout {
            static let initialVolume = (4,7)
            static let direction  = 3
            static let period = (0, 2)
        }
        
        enum EnvelopeDirection: UInt8 {
            case decrease = 0
            case increase = 1
        }
        
        var envelopeInitialVolume: Byte {
            get { volumeEnvelopeRegister[VolumeEnvelopeBitLayout.initialVolume] }
        }
        
        var envelopeDirection: EnvelopeDirection {
            get { EnvelopeDirection(rawValue: volumeEnvelopeRegister[VolumeEnvelopeBitLayout.direction])! }
        }
        
        var envelopePeriod: Byte {
            get { volumeEnvelopeRegister[VolumeEnvelopeBitLayout.period] }
        }
        
        // /////////////
        // Trigger
        struct TriggerBitLayout {
            static let trigger = 7
            static let lengthEnabled = 6
        }
        
        var trigger: Bool {
            get { return triggerLength[TriggerBitLayout.trigger] == 1}
        }
        
        var lengthEnabled: Bool {
            get { return triggerLength[TriggerBitLayout.lengthEnabled] == 1}
        }
    }
    
    final class ControlStatus {
        struct MemoryLayoutOffsets {
            static let volumePanning = UInt16(0xFF24)
            static let soundPanning = UInt16(0xFF25)
            static let powerControl = UInt16(0xFF26)
        }
        
        var rawmem: MemorySegment
        
        init(memory: MemorySegment) {
            rawmem = memory
            try! rawmem.write(byte: 0x77, at: MemoryLayoutOffsets.volumePanning)
            try! rawmem.write(byte: 0xF3, at: MemoryLayoutOffsets.soundPanning)
            try! rawmem.write(byte: 0xF1, at: MemoryLayoutOffsets.powerControl)
        }
        
        var volumePanning: Byte {
            get { try! rawmem.read(at: MemoryLayoutOffsets.volumePanning) }
        }
        
        var soundPanning: Byte {
            get { try! rawmem.read(at: MemoryLayoutOffsets.soundPanning) }
        }
        
        var powerControl: Byte {
            get { try! rawmem.read(at: MemoryLayoutOffsets.powerControl) }
        }
        
        struct VolumePanningBitLayout {
            static let initialVolume = (4,7)
            static let direction  = 3
            static let period = (0, 2)
        }
        
        struct SoundPanningBitLayout {
            static let channel4left = 7
            static let channel3left = 6
            static let channel2left = 4
            static let channel1left = 3

            static let direction  = 3
            static let period = (0, 2)
        }
        
        struct PowerControlBitLayout {
            static let soundOn = 7
            static let channel4on  = 3
            static let channel3on  = 2
            static let channel2on  = 1
            static let channel1on  = 0
        }
    }
    
    
    var rawmem: MemorySegment
    
    var pulse1: Pulse
    var pulse2: Pulse
    var wave: Wave
    var noise: Noise
    var status: ControlStatus
    
    func wavePattern(nibbleIndex: Int) throws -> Byte {
        assert(nibbleIndex > 0 && nibbleIndex < MemoryLayout.WavePattern.size - 1, "Invalid wavePattern index")
        let nibbleAddress = MemoryLayout.WavePattern.address + UInt16(nibbleIndex)
        return try rawmem.read(at: nibbleAddress)
    }
    
    init() {
        self.rawmem = MemorySegment(from: 0xFF10, size: MemoryLayout.size)
        self.pulse1 = Pulse(memory: rawmem, registerAddress: MemoryLayout.Pulse1.address)
        self.pulse2 = Pulse(memory: rawmem, registerAddress: MemoryLayout.Pulse2.address)
        self.wave =  Wave(memory: rawmem)
        self.noise = Noise(memory: rawmem)
        self.status = ControlStatus(memory: rawmem)
    }
        
    func read(at address: UInt16) throws -> UInt8 {
        return try rawmem.read(at: address)
    }
    
    func write(byte: UInt8, at address: UInt16) throws {
        try rawmem.write(byte: byte, at: address)
    }
}
