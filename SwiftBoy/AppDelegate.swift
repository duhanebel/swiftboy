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
    var debugController: NSWindowController!
    var mainController: NSWindowController!
    var vramController: VRAMViewController!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        let storyBoard = NSStoryboard(name: "Main", bundle: nil)
        debugController = storyBoard.instantiateController(withIdentifier: "vramController") as? NSWindowController
        debugController.showWindow(self)
        vramController = debugController.contentViewController as? VRAMViewController
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
}
