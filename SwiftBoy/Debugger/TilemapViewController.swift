//
//  VRAMViewController.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 16/12/2020.
//

import AppKit
import SwiftUI

class TilemapViewController: NSHostingController<EnvTilesView> {
    
    var tilesObservable = TilesObserver()
    
    required init?(coder: NSCoder) {
        tilesObservable.tiles = Array<Tile>(repeating: Tile(width: 8, height: 8, bits:Array<UInt8>(repeating: 0, count: 64)), count: 256*4)
        super.init(coder: coder, rootView: TilesView(gridWidth: 32, scale: 2).environmentObject(tilesObservable) as! EnvTilesView)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
    }
    
    func startMonitoring(_ device: Device) {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            self.update(device.mmu, ppu: device.ppu)
        }
    }
    
    func update(_ ram: MemoryMappable, ppu: PPU) {
        var tiles: [Tile] = []
        let tileMapAddress = ppu.registers.lcdc.bgTileMapStartAddress
        let tileDataStartAddress = ppu.registers.lcdc.tileDataStartAddress

        for i in 0..<256*4 {
            let signedAddressingMode = (tileDataStartAddress == 0x8800)
            var tileAddressOffset = UInt8(try! ram.read(at: tileMapAddress + UInt16(i)))
            if (signedAddressingMode) { tileAddressOffset = tileAddressOffset &- 128 }
            
            let tileAddress = tileDataStartAddress + UInt16(tileAddressOffset) * 16
            
            tiles.append(readTile(from: ram, at: tileAddress))
        }
        DispatchQueue.main.async { self.tilesObservable.tiles = tiles }
    }

    
    private func readTile(from memory: MemoryMappable, at address: UInt16) -> Tile {
        var bytes: [UInt8] = []
        for i in 0..<8 {
            let t0 = try! memory.read(at: (address + UInt16(i*2)))
            let t1 = try! memory.read(at: (address + UInt16(i*2 + 1)))
            let tileData = TileFetcher.TileData(t0: t0, t1: t1)
            let palette = ColorPalette(withRegister: 0xE4)
            let pixels = tileData.pixels.map { palette.rgbValue(for:$0) }
            bytes.append(contentsOf: pixels)
        }
        return Tile(width: 8, height: 8, bits: bytes)
    }
}
