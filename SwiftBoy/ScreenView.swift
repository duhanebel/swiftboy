////
////  ScreenView.swift
////  SwiftBoy
////
////  Created by Fabio Gallonetto on 29/11/2020.
////
//
//import Foundation
//import Cocoa
//
//struct Pixel {}
//
//let screenWidth = 160
//let screenHeight = 144
//let screenSize = screenWidth * screenHeight
//
//class ScreenView: NSView {
//    var buffer: Array<CGColor> = Array(repeating: .black, count: screenSize)
//    var index: Int = 0
//
//    var timer: Timer! = nil
//
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        self.wantsLayer = true
//        self.layer?.backgroundColor = .black
//        timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
//            if(self.index > 4) { self.buffer[self.index-4] = .black}
//            self.buffer[self.index] = .white
//            self.buffer[self.index+1] = .white
//            self.buffer[self.index+2] = .white
//            self.buffer[self.index+3] = .white
//            self.needsDisplay = true
//            self.index += 1
//            if self.index >= self.buffer.count-4 { self.index = 0 }
//        }
//    }
//
//    override func draw(_ dirtyRect: NSRect) {
//        super.draw(dirtyRect)
//        let context = NSGraphicsContext.current?.cgContext
//        context?.setShouldAntialias(false)
//
//        for w in 0..<screenWidth {
//            for h in 0..<screenHeight {
//                let loc = pixelLocation(x: w, y: h)
//                let color = buffer[h*screenWidth + w]
//                drawPixel(at: loc, color: color)
//            }
//        }
//    }
//
//    private func pixelLocation(x: Int, y: Int) -> CGRect {
//        let size = pixelSize()
//        return CGRect(x: CGFloat(x)*size.width, y: CGFloat(y) * size.height, width: size.width, height: size.height)
//    }
//
//    func drawPixel(at rect: NSRect, color: CGColor) {
//        let context = NSGraphicsContext.current?.cgContext
//
//        let borderColor = CGColor.white
//        let path = CGPath(rect: rect, transform: nil)
//
//        context?.setLineWidth(0.1)
//        context?.setFillColor(color)
//        context?.setStrokeColor(borderColor)
//        context?.addPath(path)
//        context?.drawPath(using: .fillStroke)
//    }
//
//    func pixelSize() -> CGSize {
//        let pixelSize = Int(self.bounds.size.width) / screenWidth
//        return CGSize(width: pixelSize, height: pixelSize)
//    }
//}

import Cocoa
import GLUT

class ScreenView: NSOpenGLView, Screen {

  let screenWidth = 160
  let screenHeight = 144
  let texSize: Int32 = 256
  
  var textureName = GLuint()
  var textureData: [GLubyte]
    
    var timer: Timer! = nil
    var index: Int = 0
  
    var buffer:[UInt8] = Array(repeating: 0, count: 160*144)
    
  required init?(coder aDecoder: NSCoder) {
    textureData = [GLubyte](repeating: GLubyte(0), count: Int(texSize*texSize)*4)
    super.init(coder: aDecoder)
    
    
//    timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
//
//        if(self.index > 4) { self.buffer[self.index-4] = 0}
//        self.buffer[self.index] = 255
//        self.buffer[self.index+1] = 255
//        self.buffer[self.index+2] = 255
//        self.buffer[self.index+3] = 255
//        self.index += 1
//        if self.index >= self.textureData.count-4 { self.index = 0 }
//        self.copyBuffer(self.buffer)
//    }
  }
  
  override var needsPanelToBecomeKey: Bool{
    get {
      return true
    }
  }
  override var acceptsFirstResponder: Bool {
    get {
      return true
    }
  }
  
  override func prepareOpenGL() {
    super.prepareOpenGL()
    // some init gl code here
    
    glGenTextures(1, &textureName);
    glBindTexture(UInt32(GL_TEXTURE_2D), textureName);
    glTexParameteri(UInt32(GL_TEXTURE_2D),UInt32(GL_TEXTURE_MIN_FILTER),GL_NEAREST);
    glTexParameteri(UInt32(GL_TEXTURE_2D),UInt32(GL_TEXTURE_MAG_FILTER),GL_NEAREST);
    glTexImage2D(UInt32(GL_TEXTURE_2D), 0, Int32(GL_RGBA), texSize, texSize, 0, UInt32(GL_RGBA), UInt32(GL_UNSIGNED_BYTE), textureData);
  }
  
  override func reshape() {
    //TODO viewport reshaping
  }
  
  override func draw(_ dirtyRect: NSRect) {
    glClearColor(0, 0, 0, 0);
    glClear(UInt32(GL_COLOR_BUFFER_BIT))
    
    glEnable(UInt32(GL_TEXTURE_2D));
    glActiveTexture(UInt32(GL_TEXTURE0))
    glBindTexture(UInt32(GL_TEXTURE_2D), textureName);
    glTexImage2D(UInt32(GL_TEXTURE_2D), 0, Int32(GL_RGBA), texSize, texSize, 0, UInt32(GL_RGBA), UInt32(GL_UNSIGNED_BYTE), textureData);
    
    let cord_right = Float(screenWidth)/Float(texSize)
    let cord_down = Float(screenHeight)/Float(texSize)
    
    glBegin(UInt32(GL_TRIANGLE_STRIP));
    glTexCoord2f(0.0, cord_down); glVertex2f(-1.0, -1.0);
    glTexCoord2f(cord_right, cord_down); glVertex2f(1.0, -1.0);
    glTexCoord2f(0.0, 0.0); glVertex2f(-1.0, 1.0);
    glTexCoord2f(cord_right, 0.0); glVertex2f(1.0, 1.0);
    glEnd();
    
    glDisable(UInt32(GL_TEXTURE_2D))
    glFlush();
  }
  
  func copyBuffer(_ screenBuffer: [UInt8]) {
    
        for j in 0 ..< self.screenHeight {
          for i in 0 ..< self.screenWidth {
            let reverseY = j //(self.screenHeight - 1) - j
            let reverseX = i // (self.screenWidth - 1) - i
            let hue = 255 - screenBuffer[reverseY * self.screenWidth + reverseX]
            
            self.textureData[(j*Int(self.texSize)+i)*4] = GLubyte(hue)
            self.textureData[(j*Int(self.texSize)+i)*4+1] = GLubyte(hue)
            self.textureData[(j*Int(self.texSize)+i)*4+2] = GLubyte(hue)
            self.textureData[(j*Int(self.texSize)+i)*4+3] = 255;
          }
        }
        DispatchQueue.main.async {
        self.needsDisplay = true
      }
    }
}
