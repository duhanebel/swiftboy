//
//  GameViewController.swift
//  oiuhygtfg
//
//  Created by Fabio Gallonetto on 18/12/2020.
//

import Cocoa
import MetalKit

// Our macOS specific view controller
class GameViewController: NSViewController {

    var renderer: Renderer!
    var mtkView: MTKView!

    var device: Device!
    
    private var screenBuff: Array<UInt8>!

    override func viewDidLoad() {
        super.viewDidLoad()
        metalSetup()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
    }
    
    func metalSetup() {
        guard let mtkView = self.view as? ScreenView else {
            print("View attached to GameViewController is not an MTKView")
            return
        }

        // Select the device to render with.  We choose the default device
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return
        }

        mtkView.device = defaultDevice

        guard let newRenderer = Renderer(metalKitView: mtkView) else {
            print("Renderer cannot be initialized")
            return
        }

        renderer = newRenderer
        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
        mtkView.delegate = renderer
        mtkView.inputDelegate = self
        
        screenBuff = Array<UInt8>(repeating: 0, count: renderer.width*renderer.height*4)
    }
}

extension GameViewController: Screen {
    func copyBuffer(_ screenBuffer: [UInt8]) {
        
        for j in 0 ..< self.renderer.height {
          for i in 0 ..< self.renderer.width {
            let pixelIndex = j * self.renderer.width + i
            let bufferIndex = pixelIndex * 4
            let hue = 255 - screenBuffer[pixelIndex]
            
            screenBuff[bufferIndex] = hue
            screenBuff[bufferIndex + 1] = hue
            screenBuff[bufferIndex + 2] = hue
            screenBuff[bufferIndex + 3] = 255
          }
        }
        self.renderer.updateTexture(bytes: screenBuff)
    }
}

extension GameViewController: InputDelegate {
    enum Keycode: UInt16 {
        case w = 13
        case a = 0
        case s = 1
        case d = 2
        case j = 38
        case k = 40
        case u = 32
        case i = 34
        
        var joypadKey: Joypad.Key {
            switch(self) {
            case .w:
                return .up
            case .a:
                return .left
            case .s:
                return .down
            case .d:
                return .right
            case .j:
                return .a
            case .k:
                return .b
            case .u:
                return .start
            case .i:
                return .select
            }
        }
    }
    
    override func keyDown(with event: NSEvent) {
        if let keyCode = Keycode(rawValue: event.keyCode) {
            device.keyDown(key: keyCode.joypadKey)
        }
    }
    
    override func keyUp(with event: NSEvent) {
        if let keyCode = Keycode(rawValue: event.keyCode) {
            device.keyUp(key: keyCode.joypadKey)
        }
    }
}
