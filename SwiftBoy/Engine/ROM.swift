//
//  ROM.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 29/11/2020.
//

import Foundation

/*
 ROM header:
   Location  | Name            | Size | Details
   ----------+-----------------+------+-------------------------------------
   0104-0133 | Nintendo logo   |  48  | Used by the BIOS to verify checksum
   0134-0143 | Title           |  16  | Uppercase, padded with 0
   0144-0145 | Publisher       |  2   | Used by newer GameBoy games
   0146      | SGB flag        |  1   | Value of 3 indicates SGB support
   0147      | Cartridge type  |  1   | MBC type/extras (see table below)
   0148      | ROM size        |  1   | Usually between 0 and 7 (Size = 32kB << val - see table below)
   0149      | RAM size        |  1   | Size of external RAM (see table below)
   014A      | Destination     |  1   | 0 for Japan market, 1 otherwise
   014B      | Publisher       |  1   | Used by older GameBoy games
   014C      | ROM version     |  1   | Version of the game, usually 0
   014D      | Header checksum |  1   | Checked by BIOS before loading
   014E-014F | Global checksum |  2   | Simple summation, not checked
*/

struct ROMHeader {
    struct MemoryLocations {
        static let headerStart = 0x0104
        static let headerEnd = 0x0150
        
        static let logo = 0x00..<0x30
        static let title = 0x30..<0x40
        static let publisherNew = 0x40..<0x41
        static let cgbFlag = 0x42
        static let cartrigeType = 0x43
        static let ROMSize = 0x44
        static let RAMSize = 0x45
        static let destination = 0x46
        static let publisherOld = 0x47
        static let ROMVersion = 0x48
        static let headerChecksum = 0x49
        static let globalChecksum = 0x4A..<0x4C
        
        static func absolute(address: Address) -> Int {
            return ROMHeader.MemoryLocations.headerStart + Int(address)
        }
        
        static func absolute(range: Range<Int>) -> Range<Int> {
            return (ROMHeader.MemoryLocations.headerStart + range.lowerBound)..<(headerStart + range.upperBound)
        }
    }
    
/*
 Cartriges types:
   Value | Type
   ------+----------------------------------------
     00  | ROM only - No MBC
     01  | MBC1
     02  | MBC1 with external RAM
     03  | MBC1 with battery-backed external RAM
     --  | ---
     05  | MBC2
     06  | MBC2 battery-backed
     --  | ---
     08  | ROM with external RAM
     09  | ROM with battery-backed externalRAM
     --  | ---
     0B  | MMM01
     0C  | MMM01 with external RAM
     0D  | MMM01 with battery-backed externalRAM
     --  | ---
     0F  | MBC3 with timer and external battery
     10  | MBC3 with timer and external battery and battery-backed external RAM
     11  | MBC3
     12  | MBC3 with external RAM
     13  | MBC3 with external battery-backed RAM
     --  | ---
     19  | MBC5
     1A  | MBC5 with external RAM
     1B  | MBC5 with external battery-backed RAM
     1C  | MBC5 with rumble
     1D  | MBC5 with rumble and external RAM
     1E  | MBC5 with rumble and external memory-backed RAM
     --  | ---
     20  | MBC6
     22  | MBC7 with sensor, rumble, and external memory-backed RAM
     --  | ---
     FC  | Pocket camera
     FD  | Bandai TAMA5
     FE  | HuC3
     FF  | HuC1 with exteral battery-backed RAM
 */
    enum CartrigeType: UInt8 {
        case ROM                        = 0x00
        case MBC1                       = 0x01
        case MBC1Ram                    = 0x02
        case MBC1RamBattery             = 0x03
        case MBC2                       = 0x05
        case MBC2Battery                = 0x06
        case ROMRam                     = 0x08
        case ROMRamBattery              = 0x09
        case MMM01                      = 0x0B
        case MMM01Ram                   = 0x0C
        case MMM01RamBattery            = 0x0D
        case MBC3TimerBattery           = 0x0F
        case MBC3RamTimerBattery        = 0x10
        case MBC3                       = 0x11
        case MBC3RamBattery             = 0x12
        case MBC5                       = 0x19
        case MBC5Ram                    = 0x1A
        case MBC5RamBattery             = 0x1B
        case MBC5Rumble                 = 0x1C
        case MBC5RamRumble              = 0x1D
        case MBCRamBatteryRumble        = 0x1E
        case MBC6                       = 0x20
        case MBC7RamBatterySensorRumble = 0x22
        case PocketCamera               = 0xFC
        case BandaiTAMA5                = 0xFD
        case HuC3                       = 0xFE
        case HuC1RamBattery             = 0xFF
    }
    
    /*
     ROM size:
       Value | Size
       ------+----------------------------------------------------
         00  | 32KByte (no ROM banking)
         01  | 64KByte (4 banks)
         02  | 128KByte (8 banks)
         03  | 256KByte (16 banks)
         04  | 512KByte (32 banks)
         05  | 1MByte (64 banks) - only 63 banks used by MBC1
         06  | 2MByte (128 banks) - only 125 banks used by MBC1
         07  | 4MByte (256 banks)
         08  | 8MByte (512 banks)
         52  | 1.1MByte (72 banks)
         53  | 1.2MByte (80 banks)
         54  | 1.5MByte (96 banks)
     */
    var ROMSize: Int {
        if data[MemoryLocations.ROMSize] <= 8 {
            return 32 << data[MemoryLocations.ROMSize]
        } else {
            let idx = data[MemoryLocations.ROMSize] - 52
            return 16 * (64 + (8 << idx))
        }
    }
    var ROMBanks: Int { ROMSize / 16 }
    
    /*
     RAM size:
       Value | Size
       ------+----------------------------------------
         00  | None
         01  | 2 KBytes
         02  | 8 Kbytes
         03  | 32 KBytes (4 banks of 8KBytes each)
         04  | 128 KBytes (16 banks of 8KBytes each)
         05  | 64 KBytes (8 banks of 8KBytes each)
     */
    var RAMSize: Int {
        switch(data[MemoryLocations.RAMSize]) {
        case 0x00:
            return 0
        case 0x01:
            return 2
        case 0x02:
            return 8
        case 0x03:
            return 32
        case 0x04:
            return 128
        case 0x05:
            return 64
        default:
            assert(false, "Invalid RAMSize found in header")
            return 0
        }
    }
    
    var RAMBanks: Int { RAMSize / 8 }
    
    private let data: [Byte]
    
    init(data: [Byte]) {
        assert(data.count == 0x0150 - 0x0104, "Invalid header size")
        self.data = data
    }
    
    var logo: [Byte] { Array(data[MemoryLocations.logo]) }
    var title: String { String.stringWith(ASCII: Array(data[MemoryLocations.logo])) }
    var publisherNew: [Byte] { Array(data[MemoryLocations.publisherNew]) }
    var cgbFlag: Bool { data[MemoryLocations.cgbFlag] == 1 }
    var cartrigeType: CartrigeType { CartrigeType(rawValue: data[MemoryLocations.cartrigeType])!}

    var destination: Byte { return data[MemoryLocations.destination] }
    var publisherOld: Byte { return data[MemoryLocations.publisherOld] }
    var headerChecksum: Byte { return data[MemoryLocations.headerChecksum] }
    
    func validate() -> Bool {
        var calcCheck: UInt8 = 0
        for i in MemoryLocations.title.lowerBound..<MemoryLocations.headerChecksum {
            calcCheck = calcCheck &- data[i] &- 1
        }
        return calcCheck == headerChecksum
    }
    
    var checksum: UInt16 {
        var sum: UInt16 = 0
        // Upper byte first
        sum.lowerByte = data[MemoryLocations.globalChecksum.lowerBound+1]
        sum.upperByte = data[MemoryLocations.globalChecksum.lowerBound]
        return sum
    }
}

protocol MemoryController: MemoryMappable {
    func addressFor(address: Address) -> UInt32
}

final class ROM: MemoryMappable {
    private var rawmem: [UInt8] = []
    var header: ROMHeader? = nil
    var mbc: MemoryController? = nil

    func load(url: URL) throws {
        rawmem = try Array<UInt8>(Data(contentsOf: url))
        if rawmem.count > ROMHeader.MemoryLocations.headerEnd {
            let headerData = Array(rawmem[ROMHeader.MemoryLocations.headerStart..<ROMHeader.MemoryLocations.headerEnd])
            self.header = ROMHeader(data: headerData)
        }
        
        _ = self.header?.validate()
        
        if self.header?.cartrigeType == .MBC1 {
            self.mbc = MBC1()
        } else if self.header?.cartrigeType == .MBC1RamBattery {
            self.mbc = MBC1()
        }
        
        _ = self.validate()
    }
    
    func loadEmpty() {
        rawmem = Array<UInt8>(repeating: 0xFF, count: 0x4FFF)
        
        let logo: [UInt8] = [0xce, 0xed, 0x66, 0x66, 0xcc, 0x0d, 0x00, 0x0b, 0x03, 0x73, 0x00, 0x83, 0x00, 0x0c, 0x00, 0x0d, 0x00, 0x08, 0x11, 0x1f, 0x88, 0x89, 0x00, 0x0e, 0xdc, 0xcc, 0x6e, 0xe6, 0xdd, 0xdd, 0xd9, 0x99, 0xbb, 0xbb, 0x67, 0x63, 0x6e, 0x0e, 0xec, 0xcc, 0xdd, 0xdc, 0x99, 0x9f, 0xbb, 0xb9, 0x33, 0x3e]
        for i in 0..<logo.count {
            rawmem[0x104+i] = logo[i]
        }
    }
    
    func read(at address: UInt16) throws -> UInt8 {
        var realAddress = UInt32(address)
        if address >= 0x4000,
           let mbc = mbc {
            realAddress = mbc.addressFor(address: address)
        }
        
        //TODO: remove guard and use assert instead perhaps?
        guard realAddress < rawmem.count else { throw MemoryError.outOfBounds(UInt16(realAddress), 0x00..<UInt16(rawmem.count)) }
        return rawmem[Int(realAddress)]
    }
    
    func write(byte: UInt8, at address: UInt16) throws {
        if let mbc = mbc {
            try mbc.write(byte: byte, at: address)
        } else {
            throw MemoryError.readonly(address)
        }
    }
    
    // The checksum is adding all the bytes of the ROM (except the checksum's ones)
    // and taking the lower 16bits
    func validate() -> Bool {
        guard let header = header else { return true }
        var sum: UInt32 = 0
        for (index, element) in rawmem.enumerated() {
            guard ROMHeader.MemoryLocations.absolute(range: ROMHeader.MemoryLocations.globalChecksum).contains(index) == false else { continue }
            sum += UInt32(element)
        }
        return sum & 0xFFFF == header.checksum
    }
}
