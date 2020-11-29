//
//  ScreenView.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 29/11/2020.
//

import Foundation
import Cocoa

struct Pixel {}

let screenWidth = 160
let screenHeight = 144
let screenSize = screenWidth * screenHeight

class ScreenView: NSView {

    
    var buffer: Array<CGColor> = Array(repeating: .black, count: screenSize)
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
        self.layer?.backgroundColor = .black

        
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        for w in 0..<screenWidth {
            for h in 0..<screenHeight {
                let loc = pixelLocation(x: w, y: h)
                let color = buffer[h*screenWidth + w]
                drawPixel(at: loc, color: color)
            }
        }

    }
    
    private func pixelLocation(x: Int, y: Int) -> CGRect {
        let size = pixelSize()
        return CGRect(x: CGFloat(x)*size.width, y: CGFloat(y) * size.height, width: size.width, height: size.height)
    }
    
    func drawPixel(at rect: NSRect, color: CGColor) {
        let context = NSGraphicsContext.current?.cgContext
        let borderColor = CGColor.white
        let path = CGPath(rect: rect, transform: nil)
        
        context?.setLineWidth(0.1)
        context?.setFillColor(color)
        context?.setStrokeColor(borderColor)
        context?.addPath(path)
        context?.drawPath(using: .fillStroke)
        
    }
    
    func pixelSize() -> CGSize {
        let pixelSize = Int(self.bounds.size.width) / screenWidth
        return CGSize(width: pixelSize, height: pixelSize)
    }
    
}
