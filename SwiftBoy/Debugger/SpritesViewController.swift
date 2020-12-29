////
////  SpritesViewController.swift
////  SwiftBoy
////
////  Created by Fabio Gallonetto on 16/12/2020.
////
//
//import AppKit
//import SwiftUI
//
//class SpritesObserver: ObservableObject {
//    @Published var sprites: [Sprite] = []
//}
//
//typealias EnvSpritesView = ModifiedContent<TilesView, _EnvironmentKeyWritingModifier<Optional<SpritesObserver>>>
//
//class SpritesViewController: NSHostingController<EnvSpritesView> {
//    
//    var spritesObservable = SpritesObserver()
//    
//    required init?(coder: NSCoder) {
//        tilesObservable.tiles = Array<Tile>(repeating: Tile(width: 8, height: 8, bits:Array<UInt8>(repeating: 0, count: 64)), count: 256)
//        super.init(coder: coder, rootView: TilesView(gridWidth: 16, scale: 2).environmentObject(spritesObservable) as! EnvTilesView)
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//    }
//    
//    override func viewWillAppear() {
//        super.viewWillAppear()
//    }
//    
//    override func viewDidAppear() {
//        super.viewDidAppear()
//    }
//    
//    func startMonitoring(_ device: Device) {
//        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
//            self.update(device.mmu)
//        }
//    }
//    
//    func update(_ ram: MemoryMappable) {
//        var tiles: [Tile] = []
//        
//        for i in 0..<16 {
//            for j in 0..<16 {
//                let address = UInt16((i * 16 + j) * 16) + 0x8000
//                tiles.append(readTile(from: ram, at: address))
//            }
//        }
//        DispatchQueue.main.async { self.tilesObservable.tiles = tiles }
//    }
//    
//    private func readTile(from memory: MemoryMappable, at address: UInt16) -> Tile {
//        var bytes: [UInt8] = []
//        for i in 0..<8 {
//            let t0 = try! memory.read(at: (address + UInt16(i*2)))
//            let t1 = try! memory.read(at: (address + UInt16(i*2 + 1)))
//            let tileData = TileFetcher.TileData(t0: t0, t1: t1)
//            let pixels = tileData.pixels.map(\.grayscaleValue)
//            bytes.append(contentsOf: pixels)
//        }
//        return Tile(width: 8, height: 8, bits: bytes)
//    }
//}
