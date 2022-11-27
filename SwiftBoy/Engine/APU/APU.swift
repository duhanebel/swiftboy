//
//  APU.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 02/01/2021.
//

import Foundation




protocol Synthetizer {
    var sampleRate: Int { get }
    func play(buffer: [Byte])
}



final class Pulse: Actor {
    enum WaveForm: Int {
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
    private var length: Int
    private var waveForm: WaveForm
    private var frequency: Int
    private var pulseTics: Int
    
    
    private var currentTic = 0
    
    init(length: Int, frequency: Int, wave: WaveForm) {
        self.length = length
        self.frequency = frequency
        self.waveForm = wave
        
        /*
           The actual signal frequency is 131072 / (2048 - freq) Hz.
           This is the whole wave’s frequency; the rate at which the channel steps through the 8 “steps”.
           The following formula is a simplified version of the above.
         */
        self.pulseTics = (2048 - frequency) * 4
    }
    
    func tic() {
        if currentTic == pulseTics {
            dutyIndex = (dutyIndex + 1) % 8
            currentTic = 0
        } else {
            currentTic += 1
        }
    }
    
    func currentValue() -> Byte {
        return wavetable[waveForm.rawValue][dutyIndex]
    }
}


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

final class Audio: Actor {
    
    var registers: APURegisters = APURegisters()
    
    var pulseChannel: Pulse = Pulse(length: 1000, frequency: 0x2FF, wave: .half)
    
    private var currentTic = 0
    
    private var buff: [Byte] = {
        var a = Array<Byte>()
        a.reserveCapacity(1024)
        return a
    }()
    
    private var output: Synthetizer

    init(output: Synthetizer) {
        self.output = output
    }
    
    convenience init() {
        self.init(output: FMSynthesizer())
    }
    
    func tic() {
        if currentTic == CPU.clockSpeed / output.sampleRate  {
            buff.append(pulseChannel.currentValue())
            if buff.count == 1024 {
                output.play(buffer: buff)
                buff = Array<Byte>()
            }
            currentTic = 0
        } else {
            currentTic += 1
        }
        pulseChannel.tic()
    }
}


/*
 class Audio: Actor {
 struct MemoryLocations  {
 static let pulse1 = UInt16(0xFF10)...UInt16(0xFF14)
 static let pulse2 = UInt16(0xFF15)...UInt16(0xFF19)
 static let wave   = UInt16(0xFF1A)...UInt16(0xFF1E)
 static let wavePattern = UInt16(0xFF30)...UInt16(0xFF3F)
 static let noise  = UInt16(0xFF1F)...UInt16(0xFF23)
 static let conf   = UInt16(0xFF24)...UInt16(0xFF26)
 static let size = Int(conf.upperBound - pulse1.lowerBound)
 }
 
 var pulse1 = Pulse()
 var pulse2 = Pulse()
 var wave = Wave()
 var noise = Noise()
 var conf = Config()
 
 var rawmem = MemorySegment(from: 0xFF10, size: MemoryLocations.size)
 
 func read(at address: UInt16) throws -> UInt8 {
 switch(address) {
 case MemoryLocations.pulse1:
 return try! pulse1.read(at: address)
 case MemoryLocations.stat.rawValue:
 return try! stat.read(at: 0)
 default:
 return try! rawmem.read(at: address)
 }
 }
 
 func write(byte: UInt8, at address: UInt16) throws {
 switch(address) {
 case MemoryLocations.lcdc.rawValue:
 return try! pulse1.write(byte: byte, at: address)
 case MemoryLocations.stat.rawValue:
 return try! stat.write(byte: byte, at: 0)
 default:
 return try! rawmem.write(byte: byte, at: address)
 }
 }
 
 
 
 
 final class WavelengthAndControl: MemoryMappable {
 struct BitLayout {
 static let wavelengthHigh = (0, 2)
 static let lengthEnabled  = 6
 static let trigger        = 7
 }
 
 var rawmem: Byte = 0
 
 var trigger: Bool {
 get { rawmem[BitLayout.trigger] == 1 ? true : false }
 set { rawmem[BitLayout.trigger] = (newValue == true ? 1 : 0)}
 }
 
 var lengthEnabled: Bool {
 get { rawmem[BitLayout.lengthEnabled] == 1 ? true : false }
 set { rawmem[BitLayout.lengthEnabled] = (newValue == true ? 1 : 0)}
 }
 
 var wavelengthHigh: Byte {
 get { rawmem[BitLayout.wavelengthHigh] }
 set { rawmem[BitLayout.wavelengthHigh] = newValue }
 }
 
 func read(at address: UInt16) throws -> UInt8 {
 return rawmem
 }
 
 func write(byte: UInt8, at address: UInt16) throws {
 rawmem = byte
 }
 }
 
 final class Pulse: MemoryMappable {
 
 enum MemoryLocationOffsets: UInt16, CaseIterable {
 case sweep = 0
 case timerDuty
 case volumeEnvelope
 case waveLow
 case waveHigh
 }
 
 final class Sweep: MemoryMappable {
 struct BitLayout {
 static let sweepCtrl = (0, 2)
 static let sweepDir  = 3
 static let sweepPace = (4, 6)
 static let unused    = 7
 }
 
 enum SweepDirection: UInt8 {
 case add = 0
 case sub = 1
 }
 
 var rawmem: Byte = 0
 
 var pace: Byte {
 get { rawmem[BitLayout.sweepPace] }
 set { rawmem[BitLayout.sweepPace] = newValue }
 }
 
 var direction: SweepDirection {
 get { Direction(rawValue: rawmem[BitLayout.sweepDir])! }
 set { rawmem[BitLayout.sweepDir] = newValue.rawValue }
 }
 
 var slope: Byte {
 get { rawmem[BitLayout.sweepCtrl] }
 set { rawmem[BitLayout.sweepCtrl] = newValue }
 }
 
 func read(at address: UInt16) throws -> UInt8 {
 return rawmem
 }
 
 func write(byte: UInt8, at address: UInt16) throws {
 rawmem = byte
 }
 
 }
 
 final class TimerAndDuty: MemoryMappable {
 struct BitLayout {
 static let lenghtTimer = (0, 5)
 static let waveDuty  = (6,7)
 }
 
 enum WaveDuty: UInt8 {
 case eigth     = 0b00
 case quarter   = 0b01
 case half      = 0b10
 case twoThirds = 0b11
 }
 
 var rawmem: Byte = 0
 
 var lengthTimer: Byte {
 get { rawmem[BitLayout.lenghtTimer] }
 set { rawmem[BitLayout.lenghtTimer] = newValue }
 }
 
 var waveDuty: WaveDuty {
 get { WaveDuty(rawValue: rawmem[BitLayout.waveDuty])! }
 set { rawmem[BitLayout.waveDuty] = newValue.rawValue }
 }
 
 func read(at address: UInt16) throws -> UInt8 {
 return rawmem
 }
 
 func write(byte: UInt8, at address: UInt16) throws {
 rawmem = byte
 }
 }
 
 final class VolumeAndEnvelope: MemoryMappable {
 struct BitLayout {
 static let sweepPace = (0, 2)
 static let envelopeDir  = 3
 static let initialEnvVolume = (4,7)
 }
 
 enum Direction: UInt8 {
 case decrease = 0
 case increase = 1
 }
 
 var rawmem: Byte = 0
 
 var initialVolume: Byte {
 get { rawmem[BitLayout.initialEnvVolume] }
 set { rawmem[BitLayout.initialEnvVolume] = newValue }
 }
 
 var direction: Direction {
 get { Direction(rawValue: rawmem[BitLayout.envelopeDir])! }
 set { rawmem[BitLayout.envelopeDir] = newValue.rawValue }
 }
 
 var sweepPace: Byte {
 get { rawmem[BitLayout.sweepPace] }
 set { rawmem[BitLayout.sweepPace] = newValue }
 }
 
 func read(at address: UInt16) throws -> UInt8 {
 return rawmem
 }
 
 func write(byte: UInt8, at address: UInt16) throws {
 rawmem = byte
 }
 }
 
 var baseAddress: Address
 
 var sweep: Sweep = Sweep()
 var timerDuty: TimerAndDuty = TimerAndDuty()
 var volumeEnvelope: VolumeAndEnvelope = VolumeAndEnvelope()
 var wavelengthLow: Byte = 0
 var WavelengthControl: WavelengthAndControl = WavelengthAndControl()
 
 init(baseAddress: Address) {
 self.baseAddress = baseAddress
 }
 
 func read(at address: UInt16) throws -> UInt8 {
 let addressOffset = address - baseAddress
 switch(addressOffset) {
 case MemoryLocationOffsets.sweep.rawValue:
 return try sweep.read(at: address)
 case MemoryLocationOffsets.timerDuty.rawValue:
 return try timerDuty.read(at: address)
 case MemoryLocationOffsets.volumeEnvelope.rawValue:
 return try volumeEnvelope.read(at: address)
 case MemoryLocationOffsets.waveLow.rawValue:
 return wavelengthLow
 case MemoryLocationOffsets.waveHigh.rawValue:
 return try WavelengthControl.read(at: address)
 default:
 throw MemoryError.invalidAddress(address)
 }
 }
 
 func write(byte: UInt8, at address: UInt16) throws {
 let addressOffset = address - baseAddress
 switch(addressOffset) {
 case MemoryLocationOffsets.sweep.rawValue:
 try sweep.write(byte: byte, at: address)
 case MemoryLocationOffsets.timerDuty.rawValue:
 try timerDuty.write(byte: byte, at: address)
 case MemoryLocationOffsets.volumeEnvelope.rawValue:
 try volumeEnvelope.write(byte: byte, at: address)
 case MemoryLocationOffsets.waveLow.rawValue:
 wavelengthLow = byte
 case MemoryLocationOffsets.waveHigh.rawValue:
 try WavelengthControl.write(byte: byte, at: address)
 default:
 throw MemoryError.invalidAddress(address)
 }
 }
 }
 
 final class Wave: MemoryMappable {
 
 enum MemoryLocations: UInt16, CaseIterable {
 case dacPower = 0xFF1A
 case length   = 0xFF1B
 case volume   = 0xFF1C
 case waveLow  = 0xFF1D
 case waveHigh = 0xFF1E
 }
 
 var DACPower: Byte = 0
 var lengthLoad: Byte = 0
 var volume: Byte = 0
 var wavelengthLow: Byte = 0
 var WavelengthControl: WavelengthAndControl = WavelengthAndControl()
 
 var power: Bool {
 get { return DACPower == 0b1000_000 }
 set { DACPower = newValue ? 0b1000_000 : 0 }
 }
 
 
 
 final class Sweep: MemoryMappable {
 struct BitLayout {
 static let sweepCtrl = (0, 2)
 static let sweepDir  = 3
 static let sweepPace = (4, 6)
 static let unused    = 7
 }
 
 enum Direction: UInt8 {
 case add = 0
 case sub = 1
 }
 
 var rawmem: Byte = 0
 
 var pace: Byte {
 get { rawmem[BitLayout.sweepPace] }
 set { rawmem[BitLayout.sweepPace] = newValue }
 }
 
 var direction: Direction {
 get { Direction(rawValue: rawmem[BitLayout.sweepDir])! }
 set { rawmem[BitLayout.sweepDir] = newValue.rawValue }
 }
 
 var slope: Byte {
 get { rawmem[BitLayout.sweepCtrl] }
 set { rawmem[BitLayout.sweepCtrl] = newValue }
 }
 
 func read(at address: UInt16) throws -> UInt8 {
 return rawmem
 }
 
 func write(byte: UInt8, at address: UInt16) throws {
 rawmem = byte
 }
 
 }
 
 final class TimerAndDuty: MemoryMappable {
 struct BitLayout {
 static let lenghtTimer = (0, 5)
 static let waveDuty  = (6,7)
 }
 
 enum WaveDuty: UInt8 {
 case eigth     = 0b00
 case quarter   = 0b01
 case half      = 0b10
 case twoThirds = 0b11
 }
 
 var rawmem: Byte = 0
 
 var lengthTimer: Byte {
 get { rawmem[BitLayout.lenghtTimer] }
 set { rawmem[BitLayout.lenghtTimer] = newValue }
 }
 
 var waveDuty: WaveDuty {
 get { WaveDuty(rawValue: rawmem[BitLayout.waveDuty])! }
 set { rawmem[BitLayout.waveDuty] = newValue.rawValue }
 }
 
 func read(at address: UInt16) throws -> UInt8 {
 return rawmem
 }
 
 func write(byte: UInt8, at address: UInt16) throws {
 rawmem = byte
 }
 }
 
 final class VolumeAndEnvelope: MemoryMappable {
 struct BitLayout {
 static let sweepPace = (0, 2)
 static let envelopeDir  = 3
 static let initialEnvVolume = (4,7)
 }
 
 enum Direction: UInt8 {
 case decrease = 0
 case increase = 1
 }
 
 var rawmem: Byte = 0
 
 var initialVolume: Byte {
 get { rawmem[BitLayout.initialEnvVolume] }
 set { rawmem[BitLayout.initialEnvVolume] = newValue }
 }
 
 var direction: Direction {
 get { Direction(rawValue: rawmem[BitLayout.envelopeDir])! }
 set { rawmem[BitLayout.envelopeDir] = newValue.rawValue }
 }
 
 var sweepPace: Byte {
 get { rawmem[BitLayout.sweepPace] }
 set { rawmem[BitLayout.sweepPace] = newValue }
 }
 
 func read(at address: UInt16) throws -> UInt8 {
 return rawmem
 }
 
 func write(byte: UInt8, at address: UInt16) throws {
 rawmem = byte
 }
 }
 
 
 
 var baseAddress: Address
 
 var sweep: Sweep = Sweep()
 var timerDuty: TimerAndDuty = TimerAndDuty()
 var volumeEnvelope: VolumeAndEnvelope = VolumeAndEnvelope()
 var wavelengthLow: Byte = 0
 var WavelengthControl: WavelengthAndControl = WavelengthAndControl()
 
 init(baseAddress: Address) {
 self.baseAddress = baseAddress
 }
 
 func read(at address: UInt16) throws -> UInt8 {
 let addressOffset = address - baseAddress
 switch(addressOffset) {
 case MemoryLocationOffsets.sweep.rawValue:
 return try sweep.read(at: address)
 case MemoryLocationOffsets.timerDuty.rawValue:
 return try timerDuty.read(at: address)
 case MemoryLocationOffsets.volumeEnvelope.rawValue:
 return try volumeEnvelope.read(at: address)
 case MemoryLocationOffsets.waveLow.rawValue:
 return wavelengthLow
 case MemoryLocationOffsets.waveHigh.rawValue:
 return try WavelengthControl.read(at: address)
 default:
 throw MemoryError.invalidAddress(address)
 }
 }
 
 func write(byte: UInt8, at address: UInt16) throws {
 let addressOffset = address - baseAddress
 switch(addressOffset) {
 case MemoryLocationOffsets.sweep.rawValue:
 try sweep.write(byte: byte, at: address)
 case MemoryLocationOffsets.timerDuty.rawValue:
 try timerDuty.write(byte: byte, at: address)
 case MemoryLocationOffsets.volumeEnvelope.rawValue:
 try volumeEnvelope.write(byte: byte, at: address)
 case MemoryLocationOffsets.waveLow.rawValue:
 wavelengthLow = byte
 case MemoryLocationOffsets.waveHigh.rawValue:
 try WavelengthControl.write(byte: byte, at: address)
 default:
 throw MemoryError.invalidAddress(address)
 }
 }
 }
 }
 
 
 
 */
