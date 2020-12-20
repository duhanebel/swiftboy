//
//  ScreenView.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 29/11/2020.
//

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
  }
  
  override var needsPanelToBecomeKey: Bool{ get { return true } }
  override var acceptsFirstResponder: Bool { get { return true } }
  
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
            let hue = 255 - screenBuffer[j * self.screenWidth + i]
            
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
