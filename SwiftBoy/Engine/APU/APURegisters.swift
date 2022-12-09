//
//  APURegisters.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 22/11/2022.
//

import Foundation


class Register: MemoryMappable {
    fileprivate var data: Byte = 0
    private var mappedTo: Address
    
    
    let size = 1

    init(mappedTo: Address) {
        self.mappedTo = mappedTo
    }

    func read(at address: UInt16) throws -> UInt8 {
        guard address == mappedTo else { throw MemoryError.outOfBounds(address, UInt16(mappedTo)..<UInt16(mappedTo+1)) }
        return data
    }

    func write(byte: UInt8, at address: UInt16) throws {
        guard address == mappedTo else { throw MemoryError.outOfBounds(address, UInt16(mappedTo)..<UInt16(mappedTo+1)) }
        data = byte
       
    }
}

/*
 APU Registers:
 Bit-layout
 Name | Addr | 7654 3210 | Init | Description
 -----+------+-----------+------+---------------------------------
 Pulse 1:
 NR10 | FF10 | -PPP NSSS | 0x80 | Sweep period, direction, shift
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
 NR51 | FF25 | 4321 4321 | 0xF3 | Left enables, Right enables
 NR52 | FF26 | P--- 4321 | 0xF1 | Power control/status, Channel length statuses

 Wave pattern ram:
 FF30–FF3F   | 111122222 | ---- | Wave RAM is 16 bytes long; each byte holds two                                   “samples”, each 4 bits.
 */

class APURegisters: MemoryMappable {
    struct MemoryLocations  {
        // Pulse1 registers
        static let NR10 = Address(0xFF10)
        static let NR11 = Address(0xFF11)
        static let NR12 = Address(0xFF12)
        static let NR13 = Address(0xFF13)
        static let NR14 = Address(0xFF14)
        
        // Pulse 2 registers
        static let NR20 = Address(0xFF15)
        static let NR21 = Address(0xFF16)
        static let NR22 = Address(0xFF17)
        static let NR23 = Address(0xFF18)
        static let NR24 = Address(0xFF19)
        
        // Wave registers
        static let NR30 = Address(0xFF1A)
        static let NR31 = Address(0xFF1B)
        static let NR32 = Address(0xFF1C)
        static let NR33 = Address(0xFF1D)
        static let NR34 = Address(0xFF1E)
        
        // Noise registers
        static let NR40 = Address(0xFF1F)
        static let NR41 = Address(0xFF20)
        static let NR42 = Address(0xFF21)
        static let NR43 = Address(0xFF22)
        static let NR44 = Address(0xFF23)
        
        // control/config registers
        static let NR50 = Address(0xFF24)
        static let NR51 = Address(0xFF25)
        static let NR52 = Address(0xFF26)
        
        static let pulse1 = NR10...NR14
        static let pulse2 = NR20...NR24
        static let wave   = NR30...NR34
        static let noise  = NR40...NR44
        static let conf   = NR50...NR52
        static let unused = Address(0xFF27)...Address(0xFF29)
        static let wavePattern = Address(0xFF30)...Address(0xFF3F)
        static let range = NR10..<wavePattern.upperBound+1
    }
    
    var pulse1 = Pulse(baseAddress: MemoryLocations.pulse1.lowerBound)
    var pulse2 = Pulse(baseAddress: MemoryLocations.pulse2.lowerBound)
    var wave = Wave()
    var noise = Noise()
    var conf = Config()
    

    
    func read(at address: UInt16) throws -> UInt8 {
        switch(address) {
        case MemoryLocations.pulse1:
            return try pulse1.read(at: address)
        case MemoryLocations.pulse2:
            return try pulse2.read(at: address)
        case MemoryLocations.wave:
            return try wave.read(at: address)
        case MemoryLocations.wavePattern:
            return try wave.read(at: address)
        case MemoryLocations.noise:
            return try noise.read(at: address)
        case MemoryLocations.conf:
            return try conf.read(at: address)
        default:
            throw MemoryError.invalidAddress(address)
        }
    }
    
    func write(byte: UInt8, at address: UInt16) throws {
        switch(address) {
        case MemoryLocations.pulse1:
            return try pulse1.write(byte: byte, at: address)
        case MemoryLocations.pulse2:
            return try pulse2.write(byte: byte, at: address)
        case MemoryLocations.wave:
            return try wave.write(byte: byte, at: address)
        case MemoryLocations.wavePattern:
            return try wave.write(byte: byte, at: address)
        case MemoryLocations.noise:
            return try noise.write(byte: byte, at: address)
        case MemoryLocations.conf:
            return try conf.write(byte: byte, at: address)
        default:
            throw MemoryError.invalidAddress(address)
        }
        
    }
    
    final class SweepRegister: Register {
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
        
        var pace: Byte {
            get { data[BitLayout.sweepPace] }
            set { data[BitLayout.sweepPace] = newValue }
        }
        
        var direction: SweepDirection {
            get { SweepDirection(rawValue: data[BitLayout.sweepDir])! }
            set { data[BitLayout.sweepDir] = newValue.rawValue }
        }
        
        var slope: Byte {
            get { data[BitLayout.sweepCtrl] }
            set { data[BitLayout.sweepCtrl] = newValue }
        }
    }
    
    final class DutyAndLengthRegister: Register {
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
        
        var lengthTimer: Byte {
            get { data[BitLayout.lenghtTimer] }
            set { data[BitLayout.lenghtTimer] = newValue }
        }
        
        var waveDuty: WaveDuty {
            get { WaveDuty(rawValue: data[BitLayout.waveDuty])! }
            set { data[BitLayout.waveDuty] = newValue.rawValue }
        }
    }
    
    final class VolumeAndEnvelopeRegister: Register {
        struct BitLayout {
            static let sweepPace = (0, 2)
            static let envelopeDir  = 3
            static let initialEnvVolume = (4,7)
        }
        
        enum EnvelopeDirection: UInt8 {
            case decrease = 0
            case increase = 1
        }
        
        var initialVolume: Byte {
            get { data[BitLayout.initialEnvVolume] }
            set { data[BitLayout.initialEnvVolume] = newValue }
        }
        
        var direction: EnvelopeDirection {
            get { EnvelopeDirection(rawValue: data[BitLayout.envelopeDir])! }
            set { data[BitLayout.envelopeDir] = newValue.rawValue }
        }
        
        var sweepPace: Byte {
            get { data[BitLayout.sweepPace] }
            set { data[BitLayout.sweepPace] = newValue }
        }
    }
    
    final class FrequencyHIAndTriggerRegister: Register {
        struct BitLayout {
            static let frequencyHigh = (0, 2)
            static let lengthEnabled  = 6
            static let trigger        = 7
        }
        
        var trigger: Bool {
            get { data[BitLayout.trigger] == 1 ? true : false }
            set { data[BitLayout.trigger] = (newValue == true ? 1 : 0)}
        }
        
        var lengthEnabled: Bool {
            get { data[BitLayout.lengthEnabled] == 1 ? true : false }
            set { data[BitLayout.lengthEnabled] = (newValue == true ? 1 : 0)}
        }
        
        var frequencyHigh: Byte {
            get { data[BitLayout.frequencyHigh] }
            set { data[BitLayout.frequencyHigh] = newValue }
        }
    }
    
    final class ShiftAndDivisorRegister: Register {
        struct BitLayout {
            static let divisor = (0, 2)
            static let widthMode = 3
            static let clockShift = (4,7)
        }
        
        var divisor: Byte {
            get { data[BitLayout.divisor] }
            set { data[BitLayout.divisor] = newValue}
        }
        
        var widthMode: Byte {
            get { data[BitLayout.widthMode] }
            set { data[BitLayout.widthMode] = newValue}
        }
        
        var clockShift: Byte {
            get { data[BitLayout.clockShift] }
            set { data[BitLayout.clockShift] = newValue}
        }
    }
    
    final class Pulse: MemoryMappable, MemoryObservable {
        
        enum MemoryLocationOffsets: UInt16, CaseIterable {
            case sweep = 0
            case dutyLength
            case volumeEnvelope
            case freqLow
            case freqHighTrigger
        }
        
        var baseAddress: Address
        
        var observer: MemoryObserver?

        
        var sweep: SweepRegister
        var dutyLength: DutyAndLengthRegister
        var volumeEnvelope: VolumeAndEnvelopeRegister
        var frequencyLow: Byte = 0
        var freqHIAndTrigger: FrequencyHIAndTriggerRegister
        
        var frequency: UInt16 {
            get { (UInt16(freqHIAndTrigger.frequencyHigh) << 8) | UInt16(frequencyLow) }
        }
        
        init(baseAddress: Address) {
            self.baseAddress = baseAddress
            sweep = SweepRegister(mappedTo: baseAddress + MemoryLocationOffsets.sweep.rawValue)
            dutyLength = DutyAndLengthRegister(mappedTo: baseAddress + MemoryLocationOffsets.dutyLength.rawValue)
            volumeEnvelope = VolumeAndEnvelopeRegister(mappedTo: baseAddress + MemoryLocationOffsets.volumeEnvelope.rawValue)
            freqHIAndTrigger = FrequencyHIAndTriggerRegister(mappedTo: baseAddress + MemoryLocationOffsets.freqHighTrigger.rawValue)
        }
        
        func read(at address: UInt16) throws -> UInt8 {
            let addressOffset = address - baseAddress
            switch(addressOffset) {
            case MemoryLocationOffsets.sweep.rawValue:
                return try sweep.read(at: address)
            case MemoryLocationOffsets.dutyLength.rawValue:
                return try dutyLength.read(at: address)
            case MemoryLocationOffsets.volumeEnvelope.rawValue:
                return try volumeEnvelope.read(at: address)
            case MemoryLocationOffsets.freqLow.rawValue:
                return frequencyLow
            case MemoryLocationOffsets.freqHighTrigger.rawValue:
                return try freqHIAndTrigger.read(at: address)
            default:
                throw MemoryError.invalidAddress(address)
            }
        }
        
        func write(byte: UInt8, at address: UInt16) throws {
            let addressOffset = address - baseAddress
            switch(addressOffset) {
            case MemoryLocationOffsets.sweep.rawValue:
                try sweep.write(byte: byte, at: address)
            case MemoryLocationOffsets.dutyLength.rawValue:
                try dutyLength.write(byte: byte, at: address)
            case MemoryLocationOffsets.volumeEnvelope.rawValue:
                try volumeEnvelope.write(byte: byte, at: address)
            case MemoryLocationOffsets.freqLow.rawValue:
                frequencyLow = byte
            case MemoryLocationOffsets.freqHighTrigger.rawValue:
                try freqHIAndTrigger.write(byte: byte, at: address)
            default:
                throw MemoryError.invalidAddress(address)
            }
            observer?.memoryChanged(sender: self, at: address, with: byte)

        }
    }
    
    final class Wave: MemoryMappable, MemoryObservable {
        
        enum MemoryLocations: UInt16, CaseIterable {
            case dacPower = 0xFF1A
            case length   = 0xFF1B
            case volume   = 0xFF1C
            case freqLow  = 0xFF1D
            case freqHighTrigger = 0xFF1E
            static let wavePattern = Address(0xFF30)...Address(0xFF3F)
        }
        
        enum Volume: UInt8 {
            case mute    = 0b0000_0000
            case full    = 0b0010_0000
            case half    = 0b0100_0000
            case quarter = 0b0110_0000
        }
        
        var observer: MemoryObserver?
        
        // Only the 6-5th bits are in use for the volume
        let volumeBitmask: Byte = 0b0110_0000
        
        private var DACPower: Byte = 0
        var lengthLoad: Byte = 0
        private var volumeByte: Byte = 0
        var frequencyLow: Byte = 0
        var freqHIAndTrigger = FrequencyHIAndTriggerRegister(mappedTo: MemoryLocations.freqHighTrigger.rawValue)
        
        var wavePattern: MemorySegment = MemorySegment(from: MemoryLocations.wavePattern.lowerBound, size: MemoryLocations.wavePattern.count)
        
        var frequency: UInt16 {
            get { (UInt16(freqHIAndTrigger.frequencyHigh) << 8) | UInt16(frequencyLow) }
        }
        
        // Only the 7th bit is used
        var power: Bool {
            get { return DACPower == 0b1000_0000 }
            set { DACPower = (newValue ? 0b1000_0000 : 0) }
        }
        
        var volume: Volume {
            get { return Volume(rawValue: (volumeByte & volumeBitmask))!}
            set { volumeByte &= newValue.rawValue & volumeBitmask }
        }
        
        func read(at address: UInt16) throws -> UInt8 {
            switch(address) {
            case MemoryLocations.dacPower.rawValue:
                return DACPower
            case MemoryLocations.length.rawValue:
                return lengthLoad
            case MemoryLocations.volume.rawValue:
                return volumeByte
            case MemoryLocations.freqLow.rawValue:
                return frequencyLow
            case MemoryLocations.freqHighTrigger.rawValue:
                return try freqHIAndTrigger.read(at: address)
            case MemoryLocations.wavePattern:
                return try wavePattern.read(at: address)
            default:
                throw MemoryError.invalidAddress(address)
            }
        }
        
        func write(byte: UInt8, at address: UInt16) throws {
            switch(address) {
            case MemoryLocations.dacPower.rawValue:
                DACPower = byte
            case MemoryLocations.length.rawValue:
                lengthLoad = byte
            case MemoryLocations.volume.rawValue:
                volumeByte = byte
            case MemoryLocations.freqLow.rawValue:
                frequencyLow = byte
            case MemoryLocations.freqHighTrigger.rawValue:
                try freqHIAndTrigger.write(byte: byte, at: address)
            case MemoryLocations.wavePattern:
                return try wavePattern.write(byte: byte, at: address)
            default:
                throw MemoryError.invalidAddress(address)
            }
            observer?.memoryChanged(sender: self, at: address, with: byte)
        }
    }
    
    final class Noise: MemoryMappable {
        
        enum MemoryLocations: UInt16 {
            case unused   = 0xFF1F
            case length   = 0xFF20
            case volumeEnvelope   = 0xFF21
            case shiftDivisor  = 0xFF22
            case trigger = 0xFF23
        }
        
        var unused: Byte
        var length: DutyAndLengthRegister
        var volumeEnvelope: VolumeAndEnvelopeRegister
        var shiftDivisor: ShiftAndDivisorRegister
        var trigger: FrequencyHIAndTriggerRegister
        
        init() {
            unused = 0
            length = DutyAndLengthRegister(mappedTo: MemoryLocations.length.rawValue)
            volumeEnvelope = VolumeAndEnvelopeRegister(mappedTo: MemoryLocations.volumeEnvelope.rawValue)
            shiftDivisor = ShiftAndDivisorRegister(mappedTo: MemoryLocations.shiftDivisor.rawValue)
            trigger = FrequencyHIAndTriggerRegister(mappedTo: MemoryLocations.trigger.rawValue)
        }
        
        func read(at address: UInt16) throws -> UInt8 {
            switch(address) {
            case MemoryLocations.unused.rawValue:
                return unused
            case MemoryLocations.length.rawValue:
                return try length.read(at: address)
            case MemoryLocations.volumeEnvelope.rawValue:
                return try volumeEnvelope.read(at: address)
            case MemoryLocations.shiftDivisor.rawValue:
                return try shiftDivisor.read(at: address)
            case MemoryLocations.trigger.rawValue:
                return try trigger.read(at: address)
            default:
                throw MemoryError.invalidAddress(address)
            }
        }
        
        func write(byte: UInt8, at address: UInt16) throws {
            switch(address) {
            case MemoryLocations.unused.rawValue:
                unused = byte
            case MemoryLocations.length.rawValue:
                try length.write(byte: byte, at: address)
            case MemoryLocations.volumeEnvelope.rawValue:
                try volumeEnvelope.write(byte: byte, at: address)
            case MemoryLocations.shiftDivisor.rawValue:
                try shiftDivisor.write(byte: byte, at: address)
            case MemoryLocations.trigger.rawValue:
                try trigger.write(byte: byte, at: address)
            default:
                throw MemoryError.invalidAddress(address)
            }
        }
    }
    
    final class Config: MemoryMappable {
        final class VolumeRegister: Register {
            struct BitLayout {
                static let rightVolume      = (0, 2)
                static let rightVINEnabled  = 3
                static let leftVolume       = (4, 6)
                static let leftVINEnabled   = 7
            }
            
            var rightVolume: Byte {
                get { data[BitLayout.rightVolume] }
                set { data[BitLayout.rightVolume] = newValue }
            }
            
            var isRightVINEnabled: Bool {
                get { data[BitLayout.rightVINEnabled] == 1 ? true : false }
                set { data[BitLayout.rightVINEnabled] = newValue ? 1 : 0 }
            }
            
            var leftVolume: Byte {
                get { data[BitLayout.leftVolume] }
                set { data[BitLayout.leftVolume] = newValue }
            }
            
            var isLeftVINEnabled: Bool {
                get { data[BitLayout.leftVINEnabled] == 1 ? true : false }
                set { data[BitLayout.leftVINEnabled] = newValue ? 1 : 0 }
            }
        }
        
        final class AudioEnableRegister: Register {
            struct BitLayout {
                static let isRightCh1Enabled = 0
                static let isRightCh2Enabled = 1
                static let isRightCh3Enabled = 2
                static let isRightCh4Enabled = 3
                static let isLeftCh1Enabled = 4
                static let isLeftCh2Enabled = 5
                static let isLeftCh3Enabled = 6
                static let isLeftCh4Enabled = 7
                
            }
            
            var isRightCh1Enabled: Bool {
                get { data[BitLayout.isRightCh1Enabled] == 1 ? true : false }
                set { data[BitLayout.isRightCh1Enabled] = newValue ? 1 : 0 }
            }
            var isRightCh2Enabled: Bool {
                get { data[BitLayout.isRightCh2Enabled] == 1 ? true : false }
                set { data[BitLayout.isRightCh2Enabled] = newValue ? 1 : 0 }
            }
            var isRightCh3Enabled: Bool {
                get { data[BitLayout.isRightCh3Enabled] == 1 ? true : false }
                set { data[BitLayout.isRightCh3Enabled] = newValue ? 1 : 0 }
            }
            var isRightCh4Enabled: Bool {
                get { data[BitLayout.isRightCh4Enabled] == 1 ? true : false }
                set { data[BitLayout.isRightCh4Enabled] = newValue ? 1 : 0 }
            }
            
            var isLeftCh1Enabled: Bool {
                get { data[BitLayout.isLeftCh1Enabled] == 1 ? true : false }
                set { data[BitLayout.isLeftCh1Enabled] = newValue ? 1 : 0 }
            }
            var isLeftCh2Enabled: Bool {
                get { data[BitLayout.isLeftCh2Enabled] == 1 ? true : false }
                set { data[BitLayout.isLeftCh2Enabled] = newValue ? 1 : 0 }
            }
            var isLeftCh3Enabled: Bool {
                get { data[BitLayout.isLeftCh3Enabled] == 1 ? true : false }
                set { data[BitLayout.isLeftCh3Enabled] = newValue ? 1 : 0 }
            }
            var isLeftCh4Enabled: Bool {
                get { data[BitLayout.isLeftCh4Enabled] == 1 ? true : false }
                set { data[BitLayout.isLeftCh4Enabled] = newValue ? 1 : 0 }
            }
        }
        
        final class PowerControlRegister: Register {
            struct BitLayout {
                static let isLengthCh1Enabled = 0
                static let isLengthCh2Enabled = 1
                static let isLengthCh3Enabled = 2
                static let isLengthCh4Enabled = 3
                static let unused = (4, 6)
                static let powerControl = 7
            }
            
            var isLengthCh1Enabled: Bool {
                get { data[BitLayout.isLengthCh1Enabled] == 1 ? true : false }
                set { data[BitLayout.isLengthCh1Enabled] = newValue ? 1 : 0 }
            }
            var isLengthCh2Enabled: Bool {
                get { data[BitLayout.isLengthCh2Enabled] == 1 ? true : false }
                set { data[BitLayout.isLengthCh2Enabled] = newValue ? 1 : 0 }
            }
            var isLengthCh3Enabled: Bool {
                get { data[BitLayout.isLengthCh3Enabled] == 1 ? true : false }
                set { data[BitLayout.isLengthCh3Enabled] = newValue ? 1 : 0 }
            }
            var isLengthCh4Enabled: Bool {
                get { data[BitLayout.isLengthCh4Enabled] == 1 ? true : false }
                set { data[BitLayout.isLengthCh4Enabled] = newValue ? 1 : 0 }
            }
            
            var powerControl: Bool {
                get { data[BitLayout.powerControl] == 1 ? true : false }
                set { data[BitLayout.powerControl] = newValue ? 1 : 0 }
            }
        }
        
        enum MemoryLocations: UInt16 {
            case volume          = 0xFF24
            case enabledChannels = 0xFF25
            case powerControl    = 0xFF26
        }
        
        
        var volume: VolumeRegister
        var enabledChannels: AudioEnableRegister
        var powerControl: PowerControlRegister
        
        init() {
            volume = VolumeRegister(mappedTo: MemoryLocations.volume.rawValue)
            enabledChannels = AudioEnableRegister(mappedTo: MemoryLocations.enabledChannels.rawValue)
            powerControl = PowerControlRegister(mappedTo: MemoryLocations.powerControl.rawValue)
        }
        
        func read(at address: UInt16) throws -> UInt8 {
            switch(address) {
            case MemoryLocations.volume.rawValue:
                return try volume.read(at: address)
            case MemoryLocations.enabledChannels.rawValue:
                return try enabledChannels.read(at: address)
            case MemoryLocations.powerControl.rawValue:
                return try powerControl.read(at: address)
            default:
                throw MemoryError.invalidAddress(address)
            }
        }
        
        func write(byte: Byte, at address: Address) throws {
            switch(address) {
            case MemoryLocations.volume.rawValue:
                try volume.write(byte: byte, at: address)
            case MemoryLocations.enabledChannels.rawValue:
                return try enabledChannels.write(byte: byte, at: address)
            case MemoryLocations.powerControl.rawValue:
                return try powerControl.write(byte: byte, at: address)
            default:
                throw MemoryError.invalidAddress(address)
            }
        }
    }
}



/*
 OLD IMPL
 
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
 static let dutyLength = UInt16(1)
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
 try! rawmem.write(byte: 0xBF, at: registerAddress + MemoryLayoutOffsets.dutyLength)
 try! rawmem.write(byte: 0xF3, at: registerAddress + MemoryLayoutOffsets.volumeEnvelope)
 try! rawmem.write(byte: 0xBF, at: registerAddress + MemoryLayoutOffsets.freqHighTrigger)
 
 }
 
 private var sweepRegister: Byte {
 get { try! rawmem.read(at: registerAddress + MemoryLayoutOffsets.sweepShift)}
 }
 
 private var timerDutyRegister: Byte {
 get { try! rawmem.read(at: registerAddress + MemoryLayoutOffsets.dutyLength)}
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
 
 
 */
