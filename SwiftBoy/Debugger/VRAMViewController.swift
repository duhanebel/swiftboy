//
//  VRAMViewController.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 16/12/2020.
//

import AppKit
import SwiftUI

protocol MemoryObserver {
    func memoryChanged(sender: MemoryMappable) 
}
class VRAMViewController: NSHostingController<TilesView> {

    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: TilesView(gridWidth: 16));
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
    }
    
    func update(_ ram: MemorySegment) {
        print("gr")
    }
}
