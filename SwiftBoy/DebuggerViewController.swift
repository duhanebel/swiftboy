//
//  DebuggerViewController.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 09/12/2020.
//

import AppKit
import SwiftUI

class DebuggerViewController: NSHostingController<DebuggerView> {

    required init?(coder: NSCoder) {
        super.init(coder: coder,rootView: DebuggerView());
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        preferredContentSize = NSSize(width: 1024, height: 768)
    }
}
