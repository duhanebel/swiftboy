//
//  ByteRegisters.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 16/12/2022.
//

import Foundation

extension APURegisters {
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
        
        enum WidthMode: Byte {
            case wide = 0
            case narrow = 1
        }
        
        var divisor: Byte {
            get { data[BitLayout.divisor] }
            set { data[BitLayout.divisor] = newValue}
        }
        
        var width: WidthMode {
            get { WidthMode(rawValue: data[BitLayout.widthMode])! }
            set { data[BitLayout.widthMode] = newValue.rawValue}
        }
        
        var clockShift: Byte {
            get { data[BitLayout.clockShift] }
            set { data[BitLayout.clockShift] = newValue}
        }
    }
    
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
}
