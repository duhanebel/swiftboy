//
//  GameViewController.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 25/11/2020.
//

import Cocoa

// Our macOS specific view controller
class GameViewController: NSViewController {

    var device: Device!

    override func viewDidLoad() {
        super.viewDidLoad()
        let bootURL = Bundle.main.url(forResource: "boot", withExtension: "gb")!
        let tetrisURL = Bundle.main.url(forResource: "tetris", withExtension: "gb")!
//       let tetrisURL = Bundle.main.url(forResource: "cpu_bits", withExtension: "gb")!
        let bootROM = ROM()
        let rom = ROM()
        try! bootROM.load(url: bootURL)
        try! rom.load(url: tetrisURL)
        device = Device.gameBoy(biosROM: bootROM, rom: rom, screen: self.view as! Screen)
        device.didExecute = { DispatchQueue.main.async { ((NSApplication.shared.delegate as! AppDelegate).debugController.contentViewController as? VRAMViewController)?.update(self.device.ppu.vram)}}
        device.fastBoot = true
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        device.run()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        preferredContentSize = NSSize(width: 160*2, height: 144*2)
    }
    
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
