//
//  TileFetcher.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 06/12/2020.
//

private extension CircularBuffer {
    var hasSpaceForOneTile: Bool { return (count - storedCount) >= 8 }
}

/*
  Each row of a tile is 2 bytes worth of data (8 pixels with 2 bits per pixel equals 16 bits or 2 bytes).
  Instead of each pixels value coming one after the other, each pixel is split between the two bytes.
  So the first pixel's color will be represented by the first bits of each byte as represented in the
  following graph:

                   Bit Position
    A            7 6 5 4 3 2 1 0
    d          +-----------------+
    d  0x8000  | 1 0 1 1 0 1 0 1 |
    r          |-----------------|
    e  0x8001  | 0 1 1 0 0 1 0 1 |
    s          +-----------------+
    s            D L W D B W B W
                      Color
 */

final class TileFetcher: Actor {
    struct TileData {
        var t0: UInt8
        var t1: UInt8
    
        var pixels: [Pixel] {
            var pixels: [Pixel] = []
            pixels.reserveCapacity(8)
            
            // Pixels are ordered from right to left and not from left to right.
            // So the first one is actually the one on the right side of the tile.
            for n in 0..<8 {
                var rawPixelValue = t0[7-n]
                rawPixelValue[1] = t1[7-n]
                pixels.append(Pixel(rawValue: rawPixelValue)!)
            }
            return pixels
        }
    }
    
    //The fetcher works in a period of 8 T-cycles
    struct Timing {
        static let readTile = 0
        static let readT0 = 2
        static let readT1 = 4
        static let write = 6
    }
    
    // The fetcher is considered busy during the first 5 T-cycles of its period
    // Since the fetcher i
    var isBusy: Bool {
        tics < 5
    }
    
    var buffer = CircularBuffer<Pixel>(size: 16)
    
    private var tileDataRam: MemoryMappable
    private var tileMapRam: MemoryMappable
    
    private let tileLine: UInt8
    private var tileMapBaseAddress: Address
    private var tileDataAddress: UInt16
    private var currentTileID: UInt8 = 0
    
    private var currentTileMapOffset: UInt8
    private var tileData: TileData = TileData(t0: 0, t1: 0)
    
    enum State {
        case readTile
        case readData0
        case readData1
        case writeTile
    }
    
    private(set) var state: State = .readTile
        
    init(tileDataRam: MemoryMappable, tileMapRam: MemoryMappable? = nil, tileMapBaseAddress: Address, tileMapOffset: UInt8, tileDataAddress: UInt16, tileLine: UInt8) {
        self.tileDataRam = tileDataRam
        self.tileMapRam = tileMapRam ?? tileDataRam
        self.tileMapBaseAddress = tileMapBaseAddress
        self.tileDataAddress = tileDataAddress
        self.currentTileMapOffset = tileMapOffset

        self.tileLine = tileLine
    }
    
    /*private*/ var tics: Int = 0
    
    func tic() {
        // The fetcher runs at half the speed of the PPU
        if tics % 2 == 1 {
            switch(state) {
            case .readTile:  // 0-1
                let tileMapAddress = tileMapBaseAddress + UInt16(currentTileMapOffset)
                currentTileID = try! tileMapRam.read(at: tileMapAddress)
                state = .readData0
            case .readData0: // 2-3
                let tileLineAddress0 = memoryAddressFor(tile: currentTileID, line: tileLine)
                tileData.t0 = try! tileDataRam.read(at: tileLineAddress0)
                state = .readData1
            case .readData1: // 4-5
                let tileLineAddress1 = memoryAddressFor(tile: currentTileID, line: tileLine) + 1
                tileData.t1 = try! tileDataRam.read(at: tileLineAddress1)
                state = .writeTile
                if buffer.isEmpty { // on the first line there is no idle time as the buffer is empty
                    tics = 7
                    fallthrough
                }
            case .writeTile: // 6-7
                if buffer.hasSpaceForOneTile {
                    tileData.pixels.forEach { buffer.push(value:$0) }
                    currentTileMapOffset = (currentTileMapOffset &+ 1) & 0x1F // manage wrap-around for scx
                    state = .readTile
                }
            }
        }
        tics = (tics + 1) % 8
    }
 
    func reset(clearBuffer: Bool = true) {
        if clearBuffer { buffer.clear() }
        state = .readTile
        tics = 0
    }
    
    func dumpTile() -> [Pixel] {
        var pixels: [Pixel] = []
        let tileLineAddress0 = memoryAddressFor(tile: currentTileID, line: 0)
        for i in 0..<8 {
            let t0 = try! tileDataRam.read(at: (tileLineAddress0 + UInt16(i*2)))
            let t1 = try! tileDataRam.read(at: (tileLineAddress0 + UInt16(i*2 + 1)))
            let tileData = TileFetcher.TileData(t0: t0, t1: t1)
            pixels.append(contentsOf: tileData.pixels)
        }
        return pixels
    }
    
    func tileString() -> String {
        let pixels = dumpTile()
        var string = ""
        for i in 0..<8 {
            for j in 0..<8 {
                switch(pixels[i*8+j]) {
                case .c3:
                    string += "■"
                case .c2:
                    string += "▨"
                case .c1:
                    string += "▥"
                case .c0:
                    string += "□"
                }
            }
            string += "\n"
        }
        return string
    }
    // Tile are store sequentially in tileDataRam.
    // A tile is 8x8 pixels big.
    // A tile's graphical data takes 16 bytes (2 bytes per row of 8 pixels).
    // Each line (of 8 pixels) is 2 bytes so each tile data is 16bytes apart
    private func memoryAddressFor(tile: UInt8, line: UInt8) -> UInt16 {
        // There are two indexing modes for the tiles: 0x8000 or 0x8800.
        // In 0x8000 the index is an uint8, in 0x8800 is a int8!
        let signedAddressingMode = (tileDataAddress == 0x8800)
        
        // The tileID is an offset from the initial section of the allocated vram
        // in the range 8000-8FFF it's an unsigned int8,
        // in the range 8800-97FF it's a signed int8 with base at 0x9000. In order not to
        // do signed math here, we set the base at 0x9000 - (128 * 16) = 0x8800 so
        // we can just add the tile index after converting it to unsigned.
        // NOTE: the tile regions overlap
        let tileID = signedAddressingMode ? UInt16(tile &- 128) : UInt16(tile)
        let baseTileAddress = tileDataAddress + UInt16(tileID) * 16
        let tileLineAddress = baseTileAddress + UInt16(line) * 2
        return tileLineAddress
    }
}
