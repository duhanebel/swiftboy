//
//  TilesView.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 15/12/2020.
//

import SwiftUI
import CoreGraphics


struct Tile {
    let width: Int
    let height: Int
    let bits: [UInt8]
    var size: NSSize { NSSize(width: width, height: height) }
    var image: CGImage {
        let rbgaBits = bits.compactMap { return [$0, $0, $0, 255] }.joined()
        return cgImageFromPixelValues(Array(rbgaBits), width: width, height: height)!
    }
}
    

struct TilesView: View {
    var tiles: [Tile]
    
    let gridWidth: Int
    let scale: CGFloat
    
    init(_ tiles: [Tile] = [], gridWidth: Int, scale: CGFloat = 1) {
        self.gridWidth = gridWidth
        self.scale = scale
        self.tiles = tiles
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            let rows = tiles.count / gridWidth
            ForEach(0..<rows) { vindex in
                HStack(spacing: 1) {
                    ForEach(0..<gridWidth) { hindex in
                        let tile = tiles[vindex*gridWidth + hindex]
                        Image(nsImage: NSImage(cgImage:tile.image,
                                               size: tile.size))
                            .resizable().frame(width: scale*CGFloat(tile.width),
                                               height: scale*CGFloat(tile.height))
                    }
                }
            }
            let lastRow = tiles.count % gridWidth
            HStack(spacing: 1) {
                ForEach(tiles.count-lastRow..<tiles.count) { hindex in
                    let tile = tiles[hindex]
                    Image(nsImage: NSImage(cgImage:tile.image,
                                           size: tile.size))
                        .resizable().frame(width: scale*CGFloat(tile.width),
                                           height: scale*CGFloat(tile.height))
                }
            }
        }.background(Color.gray)
    }
}

struct TilesView_Previews: PreviewProvider {
    static var previews: some View {
        
        let tiles = [
            Tile(width: 8, height: 8, bits:Array<UInt8>(repeating: 0, count: 64)),
            Tile(width: 8, height: 8, bits:Array<UInt8>(repeating: 90, count: 64)),
            Tile(width: 8, height: 8, bits:Array<UInt8>(repeating: 0, count: 64)),
            Tile(width: 8, height: 8, bits:Array<UInt8>(repeating: 90, count: 64)),
            Tile(width: 8, height: 8, bits:Array<UInt8>(repeating: 160, count: 64)),
            Tile(width: 8, height: 8, bits:Array<UInt8>(repeating: 255, count: 64)),
            Tile(width: 8, height: 8, bits:Array<UInt8>(repeating: 160, count: 64)),
            Tile(width: 8, height: 8, bits:Array<UInt8>(repeating: 0, count: 64)),
            Tile(width: 8, height: 8, bits:Array<UInt8>(repeating: 90, count: 64)),
            Tile(width: 8, height: 8, bits:Array<UInt8>(repeating: 160, count: 64)),
            Tile(width: 8, height: 8, bits:Array<UInt8>(repeating: 0, count: 64)),
            Tile(width: 8, height: 8, bits:Array<UInt8>(repeating: 90, count: 64)),
            Tile(width: 8, height: 8, bits:Array<UInt8>(repeating: 160, count: 64)),
            Tile(width: 8, height: 8, bits:Array<UInt8>(repeating: 255, count: 64)),
            Tile(width: 8, height: 8, bits:Array<UInt8>(repeating: 255, count: 64)),
            Tile(width: 8, height: 8, bits:Array<UInt8>(repeating: 255, count: 64)),
            Tile(width: 8, height: 8, bits:Array<UInt8>(repeating: 255, count: 64))
        ]
        TilesView(tiles, gridWidth:4, scale: 2)
    }
}
