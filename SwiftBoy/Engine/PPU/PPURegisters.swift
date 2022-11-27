//
//  PPURegisters.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 16/01/2021.
//

import Foundation

/*
 Video Registers layout:
   Addr | Name | RW | Name
   -----+------+----+-------------------------------------------
   FF40 | LCDC | RW | LCD Control
   FF41 | STAT | RW | LCDC Status
   FF42 | SCY  | RW | Scroll Y
   FF43 | SCX  | RW | Scroll X
   FF44 | LY   | R  | LCDC Y-Coordinate
   FF45 | LYC  | RW | LY Compare
   FF46 | DMA  | W  | DMA TRansfer and Start Address
   FF47 | BGP  | RW | BG Palette Data - Non CGB Mode Only
   FF48 | OBP0 | RW | Object Palette 0 Data - Non CGB Mode Only
   FF49 | OBP1 | RW | Object Palette 1 Data - Non CGB Mode Only
   FF4A | WY   | RW | WX - Window Y Position
   FF4B | WX   | RW | WX - Window X Position minus 7
    ..  | Below this only CGB registers (unimplemented)
 */
final class PPURegister: MemoryMappable {
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
    var rawmem = MemorySegment(from: 0xFF40, size: MemoryLocations.allCases.count)
    
    init() {
        // Registers are initialised to specific values at boot
        self.lcdc = LCDCRegister(value: 0x91)
        self.stat = STATRegister(value: 0x00)
        self.scy = 0x00
        self.scx = 0x00
        self.lyc = 0x00
        self.bgp = ColorPalette(withRegister: 0xFC)
        self.obp0 = 0xFF
        self.obp1 = 0xFF
        self.wy = 0x00
        self.wx = 0x00
    }
    
    func read(at address: UInt16) throws -> UInt8 {
        switch(address) {
        case MemoryLocations.lcdc.rawValue:
            return try! lcdc.read(at: address)
        case MemoryLocations.stat.rawValue:
            return try! stat.read(at: address)
        default:
            return try! rawmem.read(at: address)
        }
    }
    
    func write(byte: UInt8, at address: UInt16) throws {
        switch(address) {
        case MemoryLocations.lcdc.rawValue:
            return try! lcdc.write(byte: byte, at: address)
        case MemoryLocations.stat.rawValue:
            return try! stat.write(byte: byte, at: address)
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
    final class LCDCRegister: MemoryMappable {
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
            assert(address == MemoryLocations.lcdc.rawValue)
            return rawmem
        }
        
        func write(byte: UInt8, at address: UInt16) throws {
            assert(address == MemoryLocations.lcdc.rawValue)
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
    final class STATRegister: MemoryMappable {
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
            assert(address == MemoryLocations.stat.rawValue)
            return rawmem
        }
        
        func write(byte: UInt8, at address: UInt16) throws {
            assert(address == MemoryLocations.stat.rawValue)
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
    
    var bgp: ColorPalette {
        get {
            let regValue = try! rawmem.read(at: MemoryLocations.bgp.rawValue)
            return ColorPalette(withRegister: regValue)
        }
        set { try! rawmem.write(byte: newValue.registerValue, at: MemoryLocations.bgp.rawValue) }
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
