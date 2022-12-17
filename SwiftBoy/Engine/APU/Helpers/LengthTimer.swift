//
//  LengthTimer.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 11/12/2022.
//

import Foundation

final class LengthTimer: Actor {
    private var currentTic = 0
    var length: Byte
    
    // Frequency here is the amount of tics before moving to the next wave value
    init(initialLength: Byte) {
        self.length = initialLength
    }
    
    var hasFired: Bool {
        return (length == 0)
    }
    
    func tic() {
        guard length > 0 else { return }
        length -= 1
    }
}

extension LengthTimer {
    convenience init(withRegister register: APURegisters.DutyAndLengthRegister) {
        let initialLength = register.lengthTimer > 0 ? register.lengthTimer : 63
        self.init(initialLength: initialLength)
    }
    
    convenience init(withRegister register: APURegisters.Wave) {
        let initialLength = register.lengthLoad > 0 ? register.lengthLoad : 255
        self.init(initialLength: initialLength)
    }
}
