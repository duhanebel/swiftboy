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
        //let tetrisURL = Bundle.main.url(forResource: "tetris", withExtension: "gb")!
        let tetrisURL = Bundle.main.url(forResource: "test_bits", withExtension: "gb")!
        let bootROM = ROM()
        let rom = ROM()
        try! bootROM.load(url: bootURL)
        try! rom.load(url: tetrisURL)
        device = Device.gameBoy(biosROM: bootROM, rom: rom, screen: self.view as! Screen)
        
        device.fastBoot = true

       
    }
    
    override func viewDidAppear() {
        device.run()
    }

}
