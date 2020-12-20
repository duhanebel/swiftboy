//
//  BitImage.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 15/12/2020.
//

import CoreGraphics

func cgImageFromPixelValues(_ pixelValues: [UInt8], width: Int, height: Int) -> CGImage? {
    var buffer = pixelValues
    let cgImg = buffer.withUnsafeMutableBytes { (ptr) -> CGImage in
        let ctx = CGContext(
            data: ptr.baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 4*8,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue + CGImageAlphaInfo.premultipliedFirst.rawValue
        )!
        return ctx.makeImage()!
    }
    return cgImg
}
