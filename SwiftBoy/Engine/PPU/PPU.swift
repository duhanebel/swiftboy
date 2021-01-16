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
    
    let vram = MemorySegment(size: 0x2000)
    let sram = OAM()
    let interruptRegister: InterruptRegister
    
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
    class PPURegister: MemoryMappable {
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
        var rawmem = MemorySegment(size: MemoryLocations.allCases.count)
        
        init() {
            // Registers are initialised to specific values at boot
            self.lcdc = LCDCRegister(value: 0x91)
            self.stat = STATRegister(value: 0x00)
            self.scy = 0x00
            self.scx = 0x00
            self.lyc = 0x00
            self.bgp = 0xFC
            self.obp0 = 0xFF
            self.obp1 = 0xFF
            self.wy = 0x00
            self.wx = 0x00
        }
        
        func read(at address: UInt16) throws -> UInt8 {
            switch(address) {
            case MemoryLocations.lcdc.rawValue:
                return try! lcdc.read(at: address)
            default:
                return try! rawmem.read(at: address)
            }
        }
        
        func write(byte: UInt8, at address: UInt16) throws {
            switch(address) {
            case MemoryLocations.lcdc.rawValue:
                return try! lcdc.write(byte: byte, at: address)
            default:
                return try! rawmem.write(byte: byte, at: address)
            }
        }
        
        /*
         LCDC register bit layout:
           Bit# | Description                    | Values
           -----+--------------------------------+-----------------------------------------------
             7  | LCD Display Enable             | 0=Off, 1=On
             6  | Window Tile Map Display Select | 0=9800-9BFF, 1=9C00-9FFF
             5  | Window Display Enable          | 0=Off, 1=On
             4  | BG & Window Tile Data Select   | 0=8800-97FF, 1=8000-8FFF
             3  | BG Tile Map Display Select     | 0=9800-9BFF, 1=9C00-9FFF
             2  | OBJ (Sprite) Size              | 0=8x8, 1=8x16
             1  | OBJ (Sprite) Display Enable    | 0=Off, 1=On
             0  | BG display enabled             | 0=Off, 1=On
         */
        //TODO: One of the important aspects of LCDC is that unlike VRAM, the PPU never locks it. It's thus possible to modify it mid-scanline!
        class LCDCRegister: MemoryMappable {
            enum MemoryLayout: Int {
                case displayEnabled = 7
                case windowTileMapDisplaySelect = 6
                case windowDisplayEnabled = 5
                case tileDataDisplaySelect = 4
                case bgTileMapDisplaySelect = 3
                case spriteSize = 2
                case spriteDisplayEnabled = 1
                case bgWindowDisplayPriority = 0
            }
            
            enum SpriteSize: UInt8 {
                case single = 0
                case double = 1
                
                var height: Int {
                    switch(self) {
                    case .single:
                        return 8
                    case .double:
                        return 16
                    }
                }
            }
            
            var rawmem: Byte
            
            init(value: Byte) {
                rawmem = value
            }
            
            func read(at address: UInt16) throws -> UInt8 {
                assert(address == 0)
                return rawmem
            }
            
            func write(byte: UInt8, at address: UInt16) throws {
                assert(address == 0)
                rawmem = byte
            }
            
            var displayEnabled: Bool {
                get { rawmem[MemoryLayout.displayEnabled.rawValue].boolValue }
                set { rawmem[MemoryLayout.displayEnabled.rawValue] = newValue.intValue}
            }
            
            var windowTileMapStartAddress: Address {
                get { rawmem[MemoryLayout.windowTileMapDisplaySelect.rawValue] == 0 ? 0x9800 : 0x9C00 }
            }
            
            var windowDisplayEnabled: Bool {
                get { rawmem[MemoryLayout.windowDisplayEnabled.rawValue].boolValue }
                set { rawmem[MemoryLayout.windowDisplayEnabled.rawValue] = newValue.intValue}
            }
            
            var tileDataStartAddress: Address {
                get { rawmem[MemoryLayout.tileDataDisplaySelect.rawValue] == 0 ? 0x8800 : 0x8000 }
            }
            
            var bgTileMapStartAddress: Address {
                get { rawmem[MemoryLayout.bgTileMapDisplaySelect.rawValue] == 0 ? 0x9800 : 0x9C00 }
            }
            
            var spriteSize: SpriteSize {
                get { SpriteSize(rawValue: rawmem[MemoryLayout.spriteSize.rawValue])! }
                set { rawmem[MemoryLayout.spriteSize.rawValue] = newValue.rawValue }
            }
            
            var spriteDisplayEnabled: Bool {
                get { rawmem[MemoryLayout.spriteDisplayEnabled.rawValue].boolValue }
                set { rawmem[MemoryLayout.spriteDisplayEnabled.rawValue] = newValue.intValue }
            }
            
            var bgDisplayPriority: Bool {
                get { rawmem[MemoryLayout.bgWindowDisplayPriority.rawValue].boolValue }
                set { rawmem[MemoryLayout.bgWindowDisplayPriority.rawValue] = newValue.intValue }
            }
        }
        
        /*
         Bit 6 - LYC=LY Coincidence Interrupt (1=Enable) (Read/Write)
           Bit 5 - Mode 2 OAM Interrupt         (1=Enable) (Read/Write)
           Bit 4 - Mode 1 V-Blank Interrupt     (1=Enable) (Read/Write)
           Bit 3 - Mode 0 H-Blank Interrupt     (1=Enable) (Read/Write)
           Bit 2 - Coincidence Flag  (0:LYC<>LY, 1:LYC=LY) (Read Only)
           Bit 1-0 - Mode Flag       (Mode 0-3, see below) (Read Only)
                     0: During H-Blank
                     1: During V-Blank
                     2: During Searching OAM-RAM
                     3: During Transfering Data to LCD Driver
         */
        /*
         STAT register bit layout:
           Bit# | RW |Description                     | Values
           -----+----+--------------------------------+-----------------------------------------------
             6  | RW | LYC=LY Coincidence Interrupt   | 1 = enabled
             5  | RW | Mode 2 OAM Interrupt           | 1 = enabled
             4  | RW | Mode 1 V-Blank Interrupt       | 1 = enabled
             3  | RW | Mode 0 H-Blank Interrupt       | 1 = enabled
             2  | RO | Coincidence Flag               | 0: LYC<>LY, 1: LYC=LY
            0-1 | RO | Mode flag                      | b00: During H-Blank
                |    |                                | b01: During V-Blank
                |    |                                | b10: During Searching OAM-RAM
                |    |                                | b11: During Transfering Data to LCD Driver
                                                        
         */
        class STATRegister: MemoryMappable {
            enum MemoryLayout: Int {
                case lycCoincidenceIntEnabled = 6
                case OAMIntEnabled = 5
                case VBlankIntEnabled = 4
                case HBlankIntEnabled = 3
                case lycCoincidenceFlag = 2
                case PPUModeFlagHiBit = 1
                case PPUModeFlagLowBit = 0
            }
            var rawmem: Byte
            
            init(value: Byte) {
                rawmem = value
            }
            
            func read(at address: UInt16) throws -> UInt8 {
                assert(address == 0)
                return rawmem
            }
            
            func write(byte: UInt8, at address: UInt16) throws {
                assert(address == 0)
                rawmem = byte
            }
            
            var lycCoincidenceIntEnabled: Bool {
                get { rawmem[MemoryLayout.lycCoincidenceIntEnabled.rawValue].boolValue }
                set { rawmem[MemoryLayout.lycCoincidenceIntEnabled.rawValue] = newValue.intValue}
            }
            
            var OAMIntEnabled: Bool {
                get { rawmem[MemoryLayout.OAMIntEnabled.rawValue].boolValue }
                set { rawmem[MemoryLayout.OAMIntEnabled.rawValue] = newValue.intValue}
            }
            
            var VBlankIntEnabled: Bool {
                get { rawmem[MemoryLayout.VBlankIntEnabled.rawValue].boolValue }
                set { rawmem[MemoryLayout.VBlankIntEnabled.rawValue] = newValue.intValue}
            }
            
            var HBlankIntEnabled: Bool {
                get { rawmem[MemoryLayout.HBlankIntEnabled.rawValue].boolValue }
                set { rawmem[MemoryLayout.HBlankIntEnabled.rawValue] = newValue.intValue}
            }
            
            var lycCoincidenceFlag: Bool {
                get { rawmem[MemoryLayout.lycCoincidenceFlag.rawValue].boolValue }
                set { rawmem[MemoryLayout.lycCoincidenceFlag.rawValue] = newValue.intValue}
            }
            
            var PPUModeFlag: PPU.Mode {
                get { let val = rawmem[MemoryLayout.PPUModeFlagLowBit.rawValue] |
                                rawmem[MemoryLayout.PPUModeFlagHiBit.rawValue] << 1
                    switch(val) {
                    case 0:
                        return .hBlank
                    case 1:
                        return .vBlank
                    case 2:
                        return .OAMSearch
                    case 3:
                        return .pixelTransfer
                    default:
                        fatalError("Invalid PPUMode in RAM")
                    }
                }
                set {
                    var val: UInt8
                    switch(newValue) {
                    case .hBlank:
                        val = 0
                    case .vBlank:
                        val = 1
                    case .OAMSearch:
                        val = 2
                    case .pixelTransferSprite:
                        fallthrough
                    case .pixelTransfer:
                        val = 3
                    }
                    rawmem[MemoryLayout.PPUModeFlagLowBit.rawValue] = val[0]
                    rawmem[MemoryLayout.PPUModeFlagHiBit.rawValue] = val[1]
                }
            }
        }
        
        var lcdc: LCDCRegister
        var stat: STATRegister
        
        var scy: Byte {
            get { try! rawmem.read(at: MemoryLocations.scy.rawValue) }
            set { try! rawmem.write(byte: newValue, at: MemoryLocations.scy.rawValue)}
        }
        
        var scx: Byte {
            get { try! rawmem.read(at: MemoryLocations.scx.rawValue) }
            set { try! rawmem.write(byte: newValue, at: MemoryLocations.scx.rawValue)}
        }
        
        var ly: Byte {
            get { try! rawmem.read(at: MemoryLocations.ly.rawValue) }
            set { try! rawmem.write(byte: newValue, at: MemoryLocations.ly.rawValue)}
        }
        
        var lyc: Byte {
            get { try! rawmem.read(at: MemoryLocations.lyc.rawValue) }
            set { try! rawmem.write(byte: newValue, at: MemoryLocations.lyc.rawValue)}
        }
        
        var bgp: Byte {
            get { try! rawmem.read(at: MemoryLocations.bgp.rawValue) }
            set { try! rawmem.write(byte: newValue, at: MemoryLocations.bgp.rawValue)}
        }
        
        var obp0: Byte {
            get { try! rawmem.read(at: MemoryLocations.obp0.rawValue) }
            set { try! rawmem.write(byte: newValue, at: MemoryLocations.obp0.rawValue)}
        }
        
        var obp1: Byte {
            get { try! rawmem.read(at: MemoryLocations.obp1.rawValue) }
            set { try! rawmem.write(byte: newValue, at: MemoryLocations.obp1.rawValue)}
        }
        
        var wx: Byte {
            get { try! rawmem.read(at: MemoryLocations.wx.rawValue) }
            set { try! rawmem.write(byte: newValue, at: MemoryLocations.wx.rawValue)}
        }
        
        var wy: Byte {
            get { try! rawmem.read(at: MemoryLocations.wy.rawValue) }
            set { try! rawmem.write(byte: newValue, at: MemoryLocations.wy.rawValue)}
        }
    }
    
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
                registers.stat.PPUModeFlag = .OAMSearch
            case .pixelTransfer:
                if currentPixelX == 0 { // not when coming back from sprite
                    let tileLine = registers.ly
                    let tileMapOffset = (UInt16(tileLine / 8) * 32)
                    bgFetcher = TileFetcher(tileDataRam: vram,
                                            tileMapAddress: registers.lcdc.bgTileMapStartAddress-0x8000 + tileMapOffset,
                                            signedTileMapAddress: registers.lcdc.tileDataStartAddress == 0x8800, // TODO this is shit
                                            tileDataAddress: registers.lcdc.tileDataStartAddress-0x8000,
                                            tileLine: tileLine % 8)
                    
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
            assert(currentPixelX <= screenWidth, "Line out of bounds: \(currentPixelX)")
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
                if registers.lcdc.spriteDisplayEnabled {
                    activeSprites = sram.sprites(of: registers.lcdc.spriteSize.height, at: Int(registers.ly))
                } else {
                    activeSprites = []
                }
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

//            if pixelTransferTics == 239 {
//                print("X/Y:\(currentPixelX)/\(registers.ly) -T/FT:\(tics)/\(bgFetcher.tics) -FS: \(bgFetcher.state) -Busy?\(bgFetcher.isBusy) -buff:\(bgFetcher.buffer.storedCount)")
//            }
            
            // Wait until there are enough pixels to pop
            // There need to be always at least 8 pixels on the queue otherwise
            // if we encouter a sprite (fetched 8pixel at a time) we won't have
            // enough background data to draw the sprite on top.
            if bgFetcher.buffer.storedCount > 8 {
                if hasActiveSprites(at: currentPixelX) {
                    // The PPU won't stop the fetcher if it's busy (first 5 cycles)
                    // Why? No idea.
                    if bgFetcher.isBusy == false {
                        // Stop the bf-fetcher and reset but keep the existing buffer
                        // TODO: move the buffer to a shared class so that the fetcher
                        // can be properly stopped and used for the sprites too (maybe?)
                        bgFetcher.reset(clearBuffer: false)
                        mode = .pixelTransferSprite
                        fallthrough
                    }
                } else {
                    let pixel = bgFetcher.buffer.pop()
                    writeToBuffer(pixel)
                    currentPixelX += 1
                }
            }
            bgFetcher.tic()
        case .pixelTransferSprite:
            if spriteFetcher == nil {
                if let sprite = activeSprites.first(where: { $0.isVisibleAt(x: currentPixelX) }) {
                    spriteFetcher = TileFetcher(tileDataRam: vram,
                                                tileMapRam: sram,
                                                tileMapAddress: UInt16(sprite.tileIndexMemOffset),
                                                tileDataAddress: registers.lcdc.tileDataStartAddress-0x8000,
                                                tileLine: registers.ly - (sprite.y - 16))
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
        guard registers.ly >= registers.scy else { return }
        assert(registers.ly < screenHeight)
        assert(currentPixelX < screenWidth)

        let buffIndex = (Int(registers.ly) - Int(registers.scy) % screenHeight) * screenWidth + currentPixelX
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


     
