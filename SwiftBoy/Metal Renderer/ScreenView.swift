//
//  ScreenView.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 29/12/2020.
//

import Foundation
import MetalKit

protocol InputDelegate: class {
    func keyUp(with event: NSEvent)
    func keyDown(with event: NSEvent)
}

class ScreenView: MTKView {
    var inputDelegate: InputDelegate?
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func keyUp(with event: NSEvent) {
        inputDelegate?.keyUp(with: event)
    }
    
    override func keyDown(with event: NSEvent) {
        inputDelegate?.keyDown(with: event)
    }
}
