//
//  TileFetcher.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 06/12/2020.
//

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

class TileFetcher: Actor {
    struct TileData {
        var t0: UInt8
        var t1: UInt8
    
        var pixels: [Pixel] {
            var pixels: [Pixel] = []
            
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
    
    
    var buffer = CircularBuffer<Pixel>(size: 16)
    
    private var vram: MemoryMappable
    
    private let tileLine: UInt8
    private var tileMapAddress: UInt16
    private var tileDataAddress: UInt16
    
    private var currentTileID: UInt8 = 0
    private var tileData: TileData = TileData(t0: 0, t1: 0)
    
    enum State {
        case idle
        case readTile
        case readData0
        case readData1
        case writeTile
    }
    
    private(set) var state: State = .readTile
    
    init(vram: MemoryMappable, tileMapAddress: UInt16, tileDataAddress: UInt16, tileLine: UInt8) {
        self.vram = vram
        self.tileMapAddress = tileMapAddress
        self.tileDataAddress = tileDataAddress
        self.tileLine = tileLine
    }
    
    private var tics: Int = 0
    
    func tic() {
        // The fetcher runs at half the speed of the PPU
        self.tics += 1
        guard self.tics == 2 else { return }
        
        switch(state) {
        case .idle:
            if buffer.count <= 8 {
                state = .readTile
            }
        case .readTile:
            currentTileID = try! vram.read(at: tileMapAddress)
            state = .readData0
        case .readData0:
            let tileLineAddress = memoryAddressFor(tile: currentTileID, line: tileLine)
            tileData.t0 = try! vram.read(at: tileLineAddress)
            state = .readData1
        case .readData1:
            let tileLineAddress = memoryAddressFor(tile: currentTileID, line: tileLine)
            tileData.t1 = try! vram.read(at: tileLineAddress+1)
            state = .writeTile
            fallthrough // read and rendering is done at the same time
        case .writeTile:
            tileData.pixels.forEach { buffer.push(value:$0) }
            tileMapAddress += 1
            state = buffer.count > 8 ? .idle : .readTile
        }
        self.tics = 0
    }
 
    func reset() {
        buffer.clear()
        state = .readTile
        tics = 0
    }
    // Tile are store sequentially in vram.
    // A tile's graphical data takes 16 bytes (2 bytes per row of 8 pixels).
    // Each line (0f 8 pixels) is 2 bytes
    private func memoryAddressFor(tile: UInt8, line: UInt8) -> UInt16 {
        let baseTileAddress = tileDataAddress + (UInt16(tile) * 16)
        let tileLineAddress = baseTileAddress + UInt16(line) * 2
        return tileLineAddress
    }
}
