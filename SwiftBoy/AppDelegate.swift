//
//  AppDelegate.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 25/11/2020.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet var window: NSWindow!
    @IBOutlet var debugWindow: NSWindow!
    var vramControllerWindow: NSWindowController!
    var tilemapControllerWindow: NSWindowController!
    var gameController: GameViewController!
    var vramController: VRAMViewController!
    var tilemapController: TilemapViewController!
    
    var device: Device!
        
    @IBAction func openTetris(_ sender: Any) {
        gameController = NSApplication.shared.windows[0].contentViewController as? GameViewController
        vramController = vramControllerWindow.contentViewController as? VRAMViewController
        tilemapController = tilemapControllerWindow.contentViewController as? TilemapViewController

        setupGame()
        gameController.device = device
        device.run()
        vramController.startMonitoring(device)
        tilemapController.startMonitoring(device)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let storyBoard = NSStoryboard(name: "Main", bundle: nil)
        vramControllerWindow = storyBoard.instantiateController(withIdentifier: "vramController") as? NSWindowController
        vramControllerWindow.showWindow(self)
        
        tilemapControllerWindow = storyBoard.instantiateController(withIdentifier: "tilemapController") as? NSWindowController
        tilemapControllerWindow.showWindow(self)
    }
    
    func setupGame() {
        let bootURL = Bundle.main.url(forResource: "boot", withExtension: "gb")!
        let tetrisURL = Bundle.main.url(forResource: "supermario_land", withExtension: "gb")!
       // let tetrisURL = Bundle.main.url(forResource: "interrupt_time", withExtension: "gb")!
      // let tetrisURL = Bundle.main.url(forResource: "cpu_op-a-hl", withExtension: "gb")!

        let bootROM = ROM()
        let rom = ROM()
        try! bootROM.load(url: bootURL)
        try! rom.load(url: tetrisURL)
        device = Device.gameBoy(biosROM: bootROM, rom: rom, screen: gameController)
       // device.fastBoot = true
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
}
