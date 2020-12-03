//
//  GPU.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 01/12/2020.
//

import Foundation

class Screen {}

/*
 Video Registers layout:
   Addr | Name | RW | Name
   -----+------+----+-------------------------------------------
   FF4O | LCDC | RW | LCD Control
   FF41 | STAT | RW | LCDC Status
   FF42 | SCY  | RW | Scroll Y
   FF43 | SCX  | RW | Scroll X
   FF44 | LY   | R  | LCDC Y-Coordinate
   FF45 | LYC  | RW | LY Compare
   FF46 | DMA  | W  | DMA TRansfer and Start Address
   FF47 | BGP  | RW | BG Palette Data (R/W) - Non CGB Mode Only
   FF48 | OBP0 | RW | Object Palette 0 Data (R/W) - Non CGB Mode Only
   FF49 | OBP1 | RW | Object Palette 1 Data (R/W) - Non CGB Mode Only
   FF4A | WY   | RW | WX - Window Y Position
   FF4B | WX   | RW | WX - Window X Position minus 7
    ..  | Below this only CGB registers (unimplemented)
 */
class VideoRegisters: MemoryMappable {
    private var rawmem: [UInt8] = Array<UInt8>(repeating: 0x0, count: MemoryLocations.allCases.count)
    
    enum MemoryLocations: UInt16, CaseIterable {
        case lcdc = 0xFF40
        case stat = 0xFF41
        case scy  = 0xFF42
        case scx  = 0xFF43
        case ly   = 0xFF44
        case lyc  = 0xFF45
        case dma  = 0xFF46
        case bgp  = 0xFF47
        case obp0 = 0xFF48
        case obp1 = 0xFF49
        case wy   = 0xFF4A
        case wx   = 0xFF4B
    }
    
    private let baseAddress: UInt16
    
    init(baseAddress: UInt16) {
        self.baseAddress = baseAddress
    }
    
    private func mapLocal(address: UInt16) -> UInt16 {
        let localAddress = address - baseAddress
        assert(localAddress <= MemoryLocations.allCases.count, "Accessing register out of bounds!")
        return localAddress
    }
    
    func read(at address: UInt16) throws -> UInt8 {
        return rawmem[Int(mapLocal(address: address))]
    }
    
    func write(byte: UInt8, at address: UInt16) throws {
//        rawmem[mapLocal(address: address)] = byte
//        find what changed -> func processUpdate, or better wait for next tic?
    }
    
}

class PPU : Actor {

    init(screen: Screen) {
        self.screen = screen
    }
    
    let vram = RAM(size: 0x2000)
    let sram = RAM(size: 0x00A0)
    var registers = VideoRegisters(baseAddress: 0xFF40)
    let screen: Screen?
    
    func compute(for tics: Int) {
        
    }
}
