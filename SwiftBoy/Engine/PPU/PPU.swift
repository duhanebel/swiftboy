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

class PPU : Actor {

    let screenWidth = 160
    let screenHeight = 144
    let vblankLines = 10

    init(screen: Screen, interruptRegister: InterruptRegister) {
        self.screen = screen
        self.interruptRegister = interruptRegister
    }
    
    let vram = MemorySegment(from: 0x8000, size: 0x2000)
    let sram = OAM()
    let interruptRegister: InterruptRegister
    
    let registers = PPURegister()
    
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
        // TODO: why base is 168 instead of 167.5 (aka 167)? Is there an
        // extra wasted tic  in the algo?
        static let pixelTransfer = (42 * 4) + 6 //6 3x2mhz pipeline warm up at the beginning
        static let hBlank = 51 * 4
        static let vBlank = 1140 * 4
        static let fullLine = OAMSearch + pixelTransfer + hBlank
    }
    
    func calculatePixelTransferTics() -> Int {
        var timing: Int = Timing.pixelTransfer + (6 * activeSprites.count) + (Int(registers.scx) % 8)
        var buckets: [Int:Int] = [:]
        activeSprites.forEach { s in
            let bucket = Int(s.x / 8)
            let bucketPos = Int(s.x % 8)
            buckets[bucket] = max((buckets[bucket] ?? 0), (5 - bucketPos))
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
    var activeSpriteIndex: Int?
    
    var mode: Mode = .OAMSearch {
        didSet {
            switch(mode) {
            case .OAMSearch:
                registers.stat.PPUModeFlag = .OAMSearch
            case .pixelTransfer:
                if currentPixelX == 0 { // not when coming back from sprite
                    let tileLine = registers.ly % 8
                    let scxTileOffset = (registers.scx / 8) & 0x1F // If we scroll more than 8px, no need to fetch that tile
                    let scyTileOffset = 32 * ((UInt16(registers.ly) + UInt16(registers.scy) & 0xFF) / 8)
                    //let tileMapOffset = (scyTileOffset + scxTileOffset) & 0x3ff //TODO: this last bit is not needed if fetching window (as there is no scx for windows)
                    // TODO: Note: The sum of both the X-POS+SCX and LY+SCY offsets is ANDed with 0x3ff in order to ensure that the address stays within the Tilemap memory regions.
                    bgFetcher = TileFetcher(tileDataRam: AddressTranslator(memory: vram, offset: 0x8000),
                                            tileMapBaseAddress: registers.lcdc.bgTileMapStartAddress + scyTileOffset,
                                            tileMapOffset: scxTileOffset,
                                            tileDataAddress: registers.lcdc.tileDataStartAddress,
                                            tileLine: tileLine)
                    
                    registers.stat.PPUModeFlag = .pixelTransfer
                }
            case .pixelTransferSprite:
                return
            case .hBlank:
                currentPixelX = 0
                bgFetcher.reset()
                registers.stat.PPUModeFlag = .hBlank
                if registers.stat.HBlankIntEnabled {
                    interruptRegister.LCDStat = true
                }
            case .vBlank:
                currentPixelX = 0
                registers.stat.PPUModeFlag = .vBlank
                if registers.stat.VBlankIntEnabled {
                    interruptRegister.LCDStat = true
                }
                interruptRegister.VBlank = true
            }
        }
    }
    
    var currentPixelX = 0 {
        didSet {
            //This goes to bounds+1 because the last time it's set it's never read again
            assert(currentPixelX - Int(registers.scx) <= screenWidth + 1, "Line out of bounds: \(currentPixelX)")
        }
    }
    
    var activeSprites: [Sprite] = []
    
    private func hasActiveSprites(at x: Int) -> Bool {
        activeSprites.first(where: { $0.x == x + 8 }) != nil
    }
        
    func tic() {
        switch(mode) {
        case .OAMSearch:
            if tics == Timing.OAMSearch {
                // Locate the sprites that are drawn on this line
                activeSprites = []
                if registers.lcdc.spriteDisplayEnabled {
                    let lineSprites = sram.sprites(of: registers.lcdc.spriteSize.height, at: Int(registers.ly))
                    // Remove the ones that are beyond the 160x144 space (taking into consideration scx)
                    activeSprites = lineSprites.filter {
                        $0.x < 160 + $0.width - (Int(registers.scx)) % 8
                    }
                }
                pixelTransferTics = calculatePixelTransferTics()
                
                tics = 0
                mode = .pixelTransfer
                return
            }
        case .pixelTransfer:
            // TODO this needs fixing! why >= ?????
            if tics >= pixelTransferTics {
                tics = 0
                mode = .hBlank
                return
            }

//            if pixelTransferTics == 239 {
//                print("X/Y:\(currentPixelX)/\(registers.ly) -T/FT:\(tics)/\(bgFetcher.tics) -FS: \(bgFetcher.state) -Busy?\(bgFetcher.isBusy) -buff:\(bgFetcher.buffer.storedCount)")
//            }
            
            // Wait until there are enough pixels to pop
            // There need to be always at least 8 pixels on the queue otherwise
            // if we encouter a sprite (fetched 8pixel at a time) we won't have
            // enough background data to draw the sprite on top.
            if bgFetcher.buffer.storedCount > 8 {
                if hasActiveSprites(at: currentPixelX - (Int(registers.scx)) % 8) {
                    // The PPU won't stop the fetcher if it's busy (first 5 cycles)
                    // Why? No idea.
                    if bgFetcher.isBusy == false {
                        // Stop the bg-fetcher and reset but keep the existing buffer
                        // TODO: move the buffer to a shared class so that the fetcher
                        // can be properly stopped and used for the sprites too (maybe?)
                        bgFetcher.reset(clearBuffer: false)
                        mode = .pixelTransferSprite
                        fallthrough
                    }
                } else {
                    let pixel = bgFetcher.buffer.pop()
                    if (currentPixelX >= Int(registers.scx) % 8) { // discard pixels that are past the x-scroll within the current tile
                      writeToBuffer(pixel)
                    }
                    currentPixelX += 1
                }
            }
            bgFetcher.tic()
        case .pixelTransferSprite:
            if spriteFetcher == nil {
                if let spriteIndex = activeSprites.firstIndex(where: { $0.isVisibleAt(x: currentPixelX - (Int(registers.scx)) % 8) }) {
                    activeSpriteIndex = spriteIndex
                    let sprite = activeSprites[spriteIndex]
                    let tileLine = sprite.flags.yFlip ? (sprite.height - (registers.ly - (sprite.y - 16))) :
                    UInt8((Int(registers.ly) - (Int(sprite.y) - 16)))
                    spriteFetcher = TileFetcher(tileDataRam: AddressTranslator(memory: vram, offset: 0x8000),
                                                tileMapRam: sram,
                                                tileMapBaseAddress: Address(sprite.tileIndexMemOffset),
                                                tileMapOffset: 0,
                                                tileDataAddress: 0x8000, //sprites always at 0x8000!
                                                tileLine: tileLine)
                } else { assert(false, "Sprite not found!") }
            }
            
            spriteFetcher?.tic()
            
//            if pixelTransferTics == 239 {
//                print("SPRITE X/Y:\(currentPixelX)/\(registers.ly) -T/FT:\(tics)/\(bgFetcher.tics) -FS: \(bgFetcher.state) -Busy?\(bgFetcher.isBusy) -buff:\(bgFetcher.buffer.storedCount)")
//            }
            
            if spriteFetcher?.buffer.storedCount == 8 {
                var mixer: [Pixel] = []
                for _ in 0..<bgFetcher.buffer.storedCount {
                    mixer.append(bgFetcher.buffer.pop())
                }
                let sprite = activeSprites[activeSpriteIndex!]
                for i in 0..<8 {
                    let pixel = spriteFetcher!.buffer.pop()
                    if pixel.isTransparentColor == false { // .black is transparent
                        if sprite.flags.xFlip {
                            mixer[8-i] = pixel
                        } else {
                            mixer[i] = pixel
                        }
                    }
                }
                mixer.forEach { bgFetcher.buffer.push(value: $0) }
                
                activeSprites.remove(at: activeSpriteIndex!)
                spriteFetcher = nil
                activeSpriteIndex = nil
                // If there's another sprite overlapping, restart the loop without going back to
                // pixelTransfer
                if(activeSprites.contains(where: { $0.isVisibleAt(x: currentPixelX - (Int(registers.scx)) % 8) }) == false) {
                    mode = .pixelTransfer
                }
            }
        case .hBlank:
            if tics == Timing.hBlank {
                tics = 0
                let isLastLine = (registers.ly == (screenHeight - 1))
                if isLastLine {
                    mode = .vBlank
                } else {
                    mode = .OAMSearch
                }
                registers.ly += 1
                let yCoincidence = (registers.ly == registers.lyc)
                registers.stat.lycCoincidenceFlag = yCoincidence
                if yCoincidence && registers.stat.lycCoincidenceIntEnabled {
                    interruptRegister.LCDStat = true
                }
                return
            }
        case .vBlank:
            if tics == Timing.fullLine {
                tics = 0
                let isLastVBlankLine = (registers.ly == (screenHeight + vblankLines - 1))
                if isLastVBlankLine {
                    draw()
                    // TODO: An interesting quirk is that LY starts reporting 0 in the middle of scanline 153.
                    registers.ly = 0
                    mode = .OAMSearch
                } else {
                    // need to update ly too during these vblank!
                    registers.ly += 1
                }
                return
            }
        }
        self.tics += 1
    }
    
    private func writeToBuffer(_ pixel: Pixel) {
       // guard registers.ly >= registers.scy else { return } TODO: why?
        assert(registers.ly < screenHeight)
      //  assert(currentPixelX - Int(registers.scx) < screenWidth)

        let buffIndex = (Int(registers.ly) - Int(registers.scy) % screenHeight) * screenWidth +
                        (currentPixelX - Int(registers.scx) % 8)
        guard buffIndex < buffer.count else { print("Out of bounds: \(buffIndex)"); return}

        buffer[buffIndex] = registers.bgp.rgbValue(for: pixel)
    }
    
    var buffer: [UInt8] = Array(repeating: 0, count: 160*144) //TODO delete

    var animationIndex = 0

        var stopwatch = Stopwatch()
        var refresh: Int = 0
    private func draw() {
        screen?.copyBuffer(self.buffer)
        refresh += 1
        if refresh == 300 {
            print("****************** RPS: \(1/(stopwatch.elapsedTimeInterval()/300))")
            stopwatch.reset()
            refresh = 0
        }
    }
}


     
