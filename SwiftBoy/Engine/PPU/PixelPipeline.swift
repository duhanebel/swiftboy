////
////  PixelPipeline.swift
////  SwiftBoy
////
////  Created by Fabio Gallonetto on 24/12/2020.
////
//
//import Foundation
//
//class PixelPipeline: Actor {
//    private var bgFetcher: TileFetcher
//    private var activeSprites: [Sprite]
//    private var spriteFetcher: TileFetcher?
//    
//    private var buffer: [UInt8]
//    
//    init(bgFetcher: TileFetcher, activeSprites: [Sprite]) {
//        self.bgFetcher = bgFetcher
//        self.activeSprites = activeSprites
//    }
//    
//    func tic() {
//        bgFetcher.tic()
//    }
//    
//    var isEmpty: Bool {
//        return bgFetcher.buffer.isEmpty
//    }
//    
//    func pop() -> Pixel {
//        
//    }
//    
//    private func spritesStarting(at x: Int) -> [Sprite] {
//        return activeSprites.filter { $0.x == x }
//    }
//    
//}
