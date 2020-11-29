//
//  MMU.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 28/11/2020.
//

import Foundation

//struct ROM: MemoryMappableR {}
//
//protocol MemoryMappableR {
//    func read(at address: UInt16) -> UInt8
//    func readWord(at address: UInt16) -> UInt16
//}
//protocol MemoryMappableW {
//    func write(byte: UInt8, at address: UInt16)
//    func write(word: UInt16, at address: UInt16)
//}
//protocol MemoryMappable: MemoryMappableR, MemoryMappableW {}

//class MMU {
//    let rom: MemoryMappable
//    let ram: MemoryMappable
//    let vram: MemoryMappable
//    let sram: MemoryMappable
//
//    let io: MemoryMappable
//    let ir: MemoryMappable
//    
//    func read(at address: UInt16) -> UInt8 {}
//    func readWord(at address: UInt16) -> UInt16 {}
//    func write(byte: UInt8, at address: UInt16) {}
//    func write(word: UInt16, at address: UInt16) {}
//    
//    
//    private func map(address: UInt16) -> MemoryMappable {
//        switch(address) {
//        case 0x0000..<0x4000:
//            return rom
//        case 0x4000..<0x8000:
//            return rom
//        case 0x8000..<0xA000:
//            return vram
////        case 0xA000..<0xC000:
////            return ?
//        case 0xC000..<0xE000:
//            return ram
//        case 0xE000..<0xFE00:
//            return ram
//        case 0xFE00..<0xFEA0:
//            return sram
////        case 0xFEA0..<0xFF00:
////            return ?
//        case 0xFF00..<0xFF4C:
//            return io
//        case 0xFF4C..<0xFFFF:
//            return ram
//        case 0xFFFF:
//            return ir
//            
//        }
//    }
//}
