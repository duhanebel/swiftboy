//
//  Device.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 02/12/2020.
//

import Foundation

protocol Actor {
    func compute(for tics: Int)
    func tic()
}

extension Actor {
    func compute(for tics: Int) {
        for _ in 0..<tics {
            tic()
        }
    }
}

protocol InterruptGenerator {
    typealias InterruptHandler = (() -> Void)
    var interruptHandler: InterruptHandler? { get set }
}

enum RegisteError : Error {
    case invalidValue(String)
}

class MemoryPrinter: MemoryMappable {
    let size: Int = 2
#if DEBUG
    let direct = true
#else
    let direct = false
#endif
    
    var buffer: String = ""
    func read(at address: UInt16) throws -> UInt8 {
        return 0
    }
    
    func write(byte: UInt8, at address: UInt16) throws {
        guard address == 0 else { return }
        let char = UnicodeScalar(byte)
        guard char.isASCII else { return }
        if direct {
            print(String(char))
            return
        }
        if char != "\n" {
            buffer += String(char)
        } else {
            print("Serial output: \(buffer)")
            buffer = ""
        }
    }
}


class Device {
    let cpu: CPU
    let mmu: MMU
    let ppu: PPU
    
    let joypad: Joypad
    
    let timer: Counter
    let divider: Divider
    
    let audio: Audio
    
    var running = false
    
    let queue: DispatchQueue = DispatchQueue(label: "com.swiftboy.compute")
    
    static func gameBoy(biosROM: ROM?, rom: ROM, screen: Screen) -> Device {
        let intRegister = InterruptRegister()
        let intEnabledRegister = InterruptRegister(initialValue: 0xE0)
        
        let ppu = PPU(screen: screen, interruptRegister: intRegister)
        
        let joypad = Joypad(intRegister: intRegister)
        let divider = Divider(CPUSpeed: CPU.clockSpeed)
        let counter = Counter(CPUSpeed: CPU.clockSpeed, intRegister: intRegister)
        let serial = MemoryPrinter() //RAM(size: 2) // unimplemented
        let audio = Audio()
        
        let io = IO(joypad: joypad,
                    serial: serial,
                    divider: divider,
                    timer: counter,
                    interruptFlag: intRegister,
                    audio: audio,
                    video: ppu.registers,
                    interruptEnabled: intEnabledRegister)
        
        let mmu = MMU(rom: rom,
                      biosROM: biosROM,
                      switchableRom: rom,
                      vram: ppu.vram,
                      sram: ppu.sram,
                      io: io)
        
        let cpu = CPU(mmu: mmu, intEnabled: intEnabledRegister, intRegister: intRegister)
        
        return Device(cpu: cpu,
                      mmu: mmu,
                      ppu: ppu,
                      joypad: joypad,
                      timer: counter,
                      divider: divider,
                      audio: audio)
    }
    
    init(cpu: CPU, mmu: MMU, ppu: PPU, joypad: Joypad, timer: Counter, divider: Divider, audio: Audio) {
        self.cpu = cpu
        self.mmu = mmu
        self.ppu = ppu
        self.joypad = joypad
        self.timer = timer
        self.divider = divider
        self.audio = audio
    }
    
    var fastBoot: Bool = false {
        didSet {
            cpu.fastBoot = fastBoot
            mmu.biosROM = nil
        }
    }
    
    func run() {
        running = true
        queue.async { self.compute() }
    }
    
    func keyDown(key: Joypad.Key) {
        joypad.keyDown(key: key)
    }
    
    func keyUp(key: Joypad.Key) {
        joypad.keyUp(key: key)
    }
    
    var didExecute: (()->Void)? = nil
    
    private func compute(at startTime: DispatchTime = DispatchTime.now()) {
        let cycles = cpu.tic()
        for _ in 0..<cycles {
            timer.tic()
            divider.tic()
            ppu.tic()
            audio.tic()
        }
        didExecute?()

        if running {
            let nextCycleDeadline = adjustRuntimeAfter(cycles: cycles, since: startTime)
            queue.asyncAfter(deadline: nextCycleDeadline, execute: { self.compute(at: nextCycleDeadline) })
        }
    }
    
    private func adjustRuntimeAfter(cycles: Int, since: DispatchTime) -> DispatchTime {
        let cpuExpectedRunTimeInterval = (Double(cycles) / Double(CPU.clockSpeed))
        let expectedCPURunTime = since + cpuExpectedRunTimeInterval
        
        let elapsedTime = since.distance(to: DispatchTime.now())
        return expectedCPURunTime - elapsedTime
    }
}
