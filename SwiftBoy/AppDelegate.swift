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
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let cpu = CPU()
        let bootURL = Bundle.main.url(forResource: "boot", withExtension: "gb")!
//        try! cpu.mmu.biosROM?.load(url: bootURL)
//        cpu.mmu.rom.loadEmpty()
//        for _ in 1...25700 {
//            cpu.tic()
//        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
}
