//
//  ChannelRegisters.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 16/12/2022.
//

import Foundation

extension APURegisters {
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
    
    
    final class Noise: MemoryMappable, MemoryObservable {
        
        enum MemoryLocations: UInt16 {
            case unused   = 0xFF1F
            case length   = 0xFF20
            case volumeEnvelope   = 0xFF21
            case shiftDivisor  = 0xFF22
            case trigger = 0xFF23
        }
        
        var observer: MemoryObserver?
        
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
            
            observer?.memoryChanged(sender: self, at: address, with: byte)
        }
    }
    
    final class Config: MemoryMappable {
        
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
