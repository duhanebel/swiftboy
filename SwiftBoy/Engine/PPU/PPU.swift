//
//  GPU.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 01/12/2020.
//

import Foundation

protocol Screen {
    func copyBuffer(_ screenBuffer: [UInt8])
}

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
class PPU : Actor {
    enum MemoryLocations: UInt16, CaseIterable {
        case lcdc = 0 //0xFF40
        case stat //= 0xFF41
        case scy  //= 0xFF42
        case scx  //= 0xFF43
        case ly   //= 0xFF44
        case lyc  //= 0xFF45
        case dma  //= 0xFF46
        case bgp  //= 0xFF47
        case obp0 //= 0xFF48
        case obp1 //= 0xFF49
        case wy   //= 0xFF4A
        case wx   //= 0xFF4B
    }
    
    let screenWidth = 160
    let screenHeight = 144
    let vblankLines = 10

    init(screen: Screen, interruptRegister: InterruptRegister) {
        self.screen = screen
        self.interruptRegister = interruptRegister
    }
    
    let vram = MemorySegment(size: 0x2000)
    let sram = MemorySegment(size: 0x00A0)
    let interruptRegister: InterruptRegister
    var registers = MemorySegment(size: MemoryLocations.allCases.count)
    
    let screen: Screen?
    
    var tics: Int = 0

    struct Timing {
        static let OAMSearch = 20 * 4
        static let pixelTransfer = 40 * 4 + 6 //6 3x2mhz pipeline warm up at the beginning
        static let hBlank = 51 * 4
        static let vBlank = 1140 * 4
        static let fullLine = OAMSearch + pixelTransfer + hBlank
    }
    
    enum Mode {
        case OAMSearch
        case pixelTransfer
        case hBlank
        case vBlank
    }
    
    /*
       PPU Timing diagram (t = CPU tic @ ~4Mhz):
     
              --> |-- 80t --|------ 172t ------|------- 204t -------| <--       <--
              |   |         |                  |                    |   |         |
       144    |   |   OAM   |      Pixel       |      H-Blank       |   |         |
      lines   |   |  Search |     Transfer     |                    |   | 65664t  | 70224t
              |   |         |                  |                    |   |         |
              --> |-------------------------------------------------| <--         |
     10 lines |   |                     V-Blank                     |   | 4560t   |
              --> |---------------------- 456t ---------------------| <--       <--
     
     PPU State machine modes:
       
          ┌───────────┐             ┌───────────┐
          │    OAM    │             │   Pixel   │
          │  Search   │────Done────▶│ Transfer  │
          │           │▲            │           │
          └───────────┘ ╲           └───────────┘
                ▲        ╲                │
                │         ╲             x=160
             ly=153        ly<144         │
                │                ╲        5
          ┌───────────┐           ╲ ┌───────────┐
          │           │            ╲│           │
          │  VBlank   │             │  HBlank   │
          │           │◀───ly=144───│           │
          └───────────┘             └───────────┘
     */
    
    var fetcher: TileFetcher?
    
    var mode: Mode = .OAMSearch
    
    var currentPixelX = 0
    
    func tic() {
        self.tics += 1
        switch(mode) {
        case .OAMSearch:
            if tics == Timing.OAMSearch {
                // search
                tics = 0
                mode = .pixelTransfer
                let tileLine = currentLY()
                let tileMapOffset = (UInt16(tileLine / 8) * 32)
                fetcher = TileFetcher(vram: vram,
                                      tileMapAddress: 0x9800-0x8000 + tileMapOffset,
                                      tileDataAddress: 0x8000-0x8000,
                                      tileLine: tileLine % 8)
            }
        case .pixelTransfer:
            if tics == Timing.pixelTransfer {
                tics = 0
                currentPixelX = 0
                fetcher!.reset()
                mode = .hBlank
            }
            fetcher!.tic()
    
            guard fetcher!.buffer.isEmpty == false else { return }
            let pixel = fetcher!.buffer.pop()
            writeToBuffer(pixel)
            currentPixelX += 1
        case .hBlank:
            if tics == Timing.hBlank {
                tics = 0
                let isLastLine = (currentLY() == (screenHeight - 1))
                if isLastLine {
                    mode = .vBlank
                    interruptRegister.VBlank = true
                } else {
                    mode = .OAMSearch
                }
                increaseLY()
            }
        case .vBlank:
            if tics == Timing.fullLine {
                tics = 0
                let isLastVBlankLine = (currentLY() == (screenHeight + vblankLines - 1))
                if isLastVBlankLine {
                    draw()
                    // TODO: An interesting quirk is that LY starts reporting 0 in the middle of scanline 153.
                    try! registers.write(byte: 0, at: MemoryLocations.ly.rawValue)
                    mode = .OAMSearch
                } else {
                    // need to update ly too during these vblank!
                    increaseLY()
                }
            }
        }
    }
    
    private func increaseLY() {
        let nextLine = currentLY() + 1
        try! registers.write(byte: nextLine, at: MemoryLocations.ly.rawValue)
    }
    
    private func currentLY() -> UInt8 {
        try! registers.read(at: MemoryLocations.ly.rawValue)
    }
    
    private func scrollY() -> UInt8 {
        try! registers.read(at: MemoryLocations.scy.rawValue)
    }
    
    private func writeToBuffer(_ pixel: Pixel) {
        guard currentLY() >= scrollY() else { return }

        let buffIndex = (Int(currentLY() - scrollY()) % screenHeight) * screenWidth + currentPixelX
        buffer[buffIndex] = pixel.grayscaleValue
    }
    
//    var stopwatch = Stopwatch()
//    var refresh: Int = 0
    var buffer:[UInt8] = Array(repeating: 0, count: 160*144) //TODO delete

    var animationIndex = 0

    private func draw() {
//        refresh += 1
//        if Int(stopwatch.elapsedTimeInterval()) % 5 == 4 {
//            print("****************** RPS: \(refresh/5)")
//            stopwatch.reset()
//            refresh = 0
//        }
//        if(self.animationIndex > 4) { self.buffer[self.animationIndex-4] = 0}
//        self.buffer[self.animationIndex] = 255
//        self.buffer[self.animationIndex+1] = 255
//        self.buffer[self.animationIndex+2] = 255
//        self.buffer[self.animationIndex+3] = 255
//        self.animationIndex += 1
//        if self.animationIndex >= self.buffer.count-4 { self.animationIndex = 0 }
        screen?.copyBuffer(self.buffer)
    }
}


     
