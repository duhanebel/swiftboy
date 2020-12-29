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
    let isNegative: Bool = true
    var size: NSSize { NSSize(width: width, height: height) }
    var image: CGImage {
        let rbgaBits = bits.reduce([]) { acc, val -> [UInt8] in
            let av = isNegative ? 255 - val : val
            return acc + [av, av, av, 255]
        }
        return cgImageFromPixelValues(rbgaBits, width: width, height: height)!
    }
}

struct TilesView: View {
    @EnvironmentObject var tilesObservable: TilesObserver
    
    var gridWidth: Int
    var scale: CGFloat = 1.0
    
    @State var text: String = ""
    
    init(gridWidth: Int, scale: CGFloat = 1) {
        self.gridWidth = gridWidth
        self.scale = scale
    }
    
    var body: some View {
        let tiles = tilesObservable.tiles
        let rows = tiles.count / gridWidth
        GeometryReader { proxy in
        VStack(alignment: .leading, spacing: 1) {
            
            ForEach(0..<rows) { vindex in
                HStack(spacing: 1) {
                    ForEach(0..<gridWidth) { hindex in
                        let tile = tiles[vindex*gridWidth + hindex]
                        Image(nsImage: NSImage(cgImage:tile.image,
                                               size: tile.size))
                            .interpolation(.none)
                            .resizable().frame(width: scale*CGFloat(tile.width),
                                               height: scale*CGFloat(tile.height))
                            .onHover(perform: { hovering in
                                if hovering {
                                    text = "\(UInt16(vindex*gridWidth+hindex), prefix:"$")"
                                }
                            })
                    }
                }
            }
            let lastRow = tiles.count % gridWidth
            HStack(spacing: 1) {
                ForEach(tiles.count-lastRow..<tiles.count) { hindex in
                    let tile = tiles[hindex]
                    Image(nsImage: NSImage(cgImage:tile.image,
                                           size: tile.size))
                        .interpolation(.none)
                        .resizable().frame(width: scale*CGFloat(tile.width),
                                           height: scale*CGFloat(tile.height))
                }
            }
            Text(text)
                .padding(.bottom, 8)
                .padding(.leading, 8)
                .frame(width: proxy.size.width, alignment: .leading)
                .background(Color.white)
                
        }}.background(Color.gray).frame(maxWidth: .infinity, maxHeight: .infinity)
        
    }
}


#if DEBUG
struct TilesView_Previews: PreviewProvider {
    static var env: TilesObserver = {
        let to = TilesObserver()
        to.tiles = [
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
        return to
    }()
    
    static var previews: some View {
        TilesView(gridWidth: 4, scale: 3).environmentObject(env)
    }
}
#endif
