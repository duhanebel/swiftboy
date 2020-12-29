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
    let sram = OAM()
    let interruptRegister: InterruptRegister
    var registers = MemorySegment(size: MemoryLocations.allCases.count)
    
    let screen: Screen?
    
    var tics: Int = 0
    
   /*
        PPU Timing diagram (t = CPU tic @ ~4Mhz):
      
               --> |-- 80t --|---------- XXXt ----------/--- YYYt ---| <--       <--
               |   |         |                          \            |   |         |
        144    |   |   OAM   |          Pixel           /  H-Blank   |   |         |
       lines   |   |  Search |         Transfer         \            |   | 65664t  | 70224t
               |   |         |                          /            |   |         |
               --> |-------------------------------------------------| <--         |
      10 lines |   |                     V-Blank                     |   | 4560t   |
               --> |---------------------- 456t ---------------------| <--       <--
      
      Pixel transfer algorith:
      - B01:  (6 cycles) fetch Background nametable byte, then 2 tile planes
      - B01s: (167.5 + (xscroll % 7) cycles) fetch another tile and sprite window.
      
      Where:
      - B fetch the background tile ID
      - 0 fetch the upper-end of the bytes representing the tile's pixels at the current line
      - 1 fetch teh lower-end bytes of the tile's pixels
      - s B01 loop for the sprite(s) under the current pixel.
      
      Total pixel transfer timing: 6 + (167.5 + (xscroll % 7)) cycles + (6 * sprites)  (max 10 sprites)
      Total H-Blank timing: 456-80-[pixel_transfer] (288.5~148.5)
      
      The tile fetcher works at 1/2 the speed of the CPU so a loop of B,0,1 takes 6 cycles.
      The PPU won't push pixels unless there are more than 8 in the buffer (so that it's sure the first
      8 had time to be blend with potential sprites). Which means it takes 6 cycles at the beginning
      of each line before pushing pixels out.
      
      There are a maximum of 10 sprites per line which means the "s" steps can only add up
      to 40 more tics.
      The 0.5 clock at the end means that whatever operation is ongoing it will be trunkated.
      See here for more details:
          http://blog.kevtris.org/blogfiles/Nitty%20Gritty%20Gameboy%20VRAM%20Timing.txt
    */
    private struct Timing {
        static let OAMSearch = 20 * 4
        static let pixelTransfer = (42 * 4 - 1) + 6 //6 3x2mhz pipeline warm up at the beginning
        static let hBlank = 51 * 4
        static let vBlank = 1140 * 4
        static let fullLine = OAMSearch + pixelTransfer + hBlank
    }
    
    func calculatePixelTransferTics() -> Int {
        var timing: Int = Timing.pixelTransfer + (6 * activeSprites.count) + (scrollX() % 8)
        var buckets: [Int:Int] = [:]
        activeSprites.forEach { s in
            let bucket = Int(s.x / 8)
            let bucketPos = Int(s.x % 8)
            buckets[bucket] = max((buckets[bucket] ?? 0), 5 - (bucketPos))
        }
        timing += buckets.values.reduce(0) { acc, val in acc + val}
        return timing
    }
    
    private var pixelTransferTics: Int = 0
    
    private var hBlankTicks: Int {
        Timing.fullLine - Timing.OAMSearch - pixelTransferTics
    }
    
    /*
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
    
    enum Mode {
        case OAMSearch
        case pixelTransfer
        case pixelTransferSprite
        case hBlank
        case vBlank
    }
    
    var bgFetcher: TileFetcher!
    var spriteFetcher: TileFetcher?
    
    var mode: Mode = .OAMSearch {
        didSet {
            switch(mode) {
            case .OAMSearch:
                return
            case .pixelTransfer:
                if currentPixelX == 0 {
                    let tileLine = currentLY
                    let tileMapOffset = (UInt16(tileLine / 8) * 32)
                    bgFetcher = TileFetcher(tileDataRam: vram,
                                            tileMapAddress: 0x9800-0x8000 + tileMapOffset,
                                            tileDataAddress: 0x8000-0x8000,
                                            tileLine: tileLine % 8)
                }
            case .pixelTransferSprite:
                let i = 3
            case .hBlank:
                currentPixelX = 0
                bgFetcher.reset()
            case .vBlank:
                interruptRegister.VBlank = true
            }
        }
    }
    
    var currentPixelX = 0
    
    var activeSprites: [Sprite] = []
    
    private func hasActiveSprites(at x: Int) -> Bool {
        activeSprites.first(where: { $0.x - 8 == x }) != nil
    }
        
    func tic() {
        switch(mode) {
        case .OAMSearch:
            if tics == Timing.OAMSearch {
                // Locate the sprites that are drawn on this line
                activeSprites = sram.sprites(at: Int(currentLY))
                pixelTransferTics = calculatePixelTransferTics()
                
                tics = 0
                mode = .pixelTransfer
                return
            }
        case .pixelTransfer:
            if tics == pixelTransferTics {
                tics = 0
                mode = .hBlank
                return
            }
            
            bgFetcher.tic()
            
            // Wait until there are enough bytes to pop
            if bgFetcher.buffer.storedCount > 8 {
                if hasActiveSprites(at: currentPixelX) {
                    if bgFetcher.isBusy == false {
                        mode = .pixelTransferSprite
                        fallthrough
                    }
                } else {
                    let pixel = bgFetcher.buffer.pop()
                    writeToBuffer(pixel)
                    currentPixelX += 1
                }
            }
        case .pixelTransferSprite:
            if spriteFetcher == nil {
                if let sprite = activeSprites.first(where: { $0.isVisibleAt(x: currentPixelX) }) {
                    spriteFetcher = TileFetcher(tileDataRam: vram,
                                                tileMapRam: sram,
                                                tileMapAddress: UInt16(sprite.tileIndexMemOffset),
                                                tileDataAddress: 0x8000-0x8000,
                                                tileLine: currentLY - (sprite.y - 16))
                } else { assert(false, "Sprite not found!") }
            }
            
            spriteFetcher?.tic()
            if spriteFetcher?.buffer.storedCount == 8 {
                var mixer: [Pixel] = []
                for _ in 0..<bgFetcher.buffer.storedCount {
                    mixer.append(bgFetcher.buffer.pop())
                }
                for i in 0..<8 {
                    let pixel = spriteFetcher!.buffer.pop()
                    if pixel != .black { // .black is transparent
                        mixer[i] = pixel
                    }
                }
                mixer.forEach { bgFetcher.buffer.push(value: $0) }
                
                activeSprites.remove(at: activeSprites.firstIndex(where: { $0.isVisibleAt(x: currentPixelX) })!)
                spriteFetcher = nil
                mode = .pixelTransfer
            }
        case .hBlank:
            if tics == Timing.hBlank {
                tics = 0
                let isLastLine = (currentLY == (screenHeight - 1))
                if isLastLine {
                    mode = .vBlank
                } else {
                    mode = .OAMSearch
                }
                currentLY += 1
                return
            }
        case .vBlank:
            if tics == Timing.fullLine {
                tics = 0
                let isLastVBlankLine = (currentLY == (screenHeight + vblankLines - 1))
                if isLastVBlankLine {
                    draw()
                    // TODO: An interesting quirk is that LY starts reporting 0 in the middle of scanline 153.
                    try! registers.write(byte: 0, at: MemoryLocations.ly.rawValue)
                    mode = .OAMSearch
                } else {
                    // need to update ly too during these vblank!
                    currentLY += 1
                }
                return
            }
        }
        self.tics += 1
    }
    
    private var currentLY: UInt8 {
        get { try! registers.read(at: MemoryLocations.ly.rawValue) }
        set { try! registers.write(byte: newValue, at: MemoryLocations.ly.rawValue) }
    }
    
    private func scrollY() -> Int {
        try! Int(registers.read(at: MemoryLocations.scy.rawValue))
    }
    
    private func scrollX() -> Int {
        try! Int(registers.read(at: MemoryLocations.scx.rawValue))
    }
    
    private func writeToBuffer(_ pixel: Pixel) {
        guard currentLY >= scrollY() else { return }

        let buffIndex = (Int(currentLY) - scrollY() % screenHeight) * screenWidth + currentPixelX
      //  guard buffIndex < buffer.count else { print("Out of bounds: \(buffIndex)"); return}

        buffer[buffIndex] = pixel.grayscaleValue
    }
    

    var buffer:[UInt8] = Array(repeating: 0, count: 160*144) //TODO delete

    var animationIndex = 0

    //    var stopwatch = Stopwatch()
    //    var refresh: Int = 0
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


     
