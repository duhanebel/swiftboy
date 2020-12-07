
//
//  Instruction.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto.
//
//  NOTE: This file is AUTOGENERATED by the script at Scripts/generate_ext_instructions_set.rb
//        and it will be overwritten when building the project.
        
        
extension Instruction {
     static var allExtInstructions: [Instruction] = [
        Instruction(asm: "RLC B", opcode: 0x00, cycles: 8, execute: { cpu in cpu.registers.B = cpu.rlc(cpu.registers.B) }),
        Instruction(asm: "RLC C", opcode: 0x01, cycles: 8, execute: { cpu in cpu.registers.C = cpu.rlc(cpu.registers.C) }),
        Instruction(asm: "RLC D", opcode: 0x02, cycles: 8, execute: { cpu in cpu.registers.D = cpu.rlc(cpu.registers.D) }),
        Instruction(asm: "RLC E", opcode: 0x03, cycles: 8, execute: { cpu in cpu.registers.E = cpu.rlc(cpu.registers.E) }),
        Instruction(asm: "RLC H", opcode: 0x04, cycles: 8, execute: { cpu in cpu.registers.H = cpu.rlc(cpu.registers.H) }),
        Instruction(asm: "RLC L", opcode: 0x05, cycles: 8, execute: { cpu in cpu.registers.L = cpu.rlc(cpu.registers.L) }),
        Instruction(asm: "RLC (HL)", opcode: 0x06, cycles: 16, execute: { cpu in var val =  cpu.rlc(cpu.read(at: cpu.registers.HL)); cpu.write(byte: val, at: cpu.registers.HL) }),
        Instruction(asm: "RLC A", opcode: 0x07, cycles: 8, execute: { cpu in cpu.registers.A = cpu.rlc(cpu.registers.A) }),

        Instruction(asm: "RRC B", opcode: 0x08, cycles: 8, execute: { cpu in cpu.registers.B = cpu.rrc(cpu.registers.B) }),
        Instruction(asm: "RRC C", opcode: 0x09, cycles: 8, execute: { cpu in cpu.registers.C = cpu.rrc(cpu.registers.C) }),
        Instruction(asm: "RRC D", opcode: 0x0A, cycles: 8, execute: { cpu in cpu.registers.D = cpu.rrc(cpu.registers.D) }),
        Instruction(asm: "RRC E", opcode: 0x0B, cycles: 8, execute: { cpu in cpu.registers.E = cpu.rrc(cpu.registers.E) }),
        Instruction(asm: "RRC H", opcode: 0x0C, cycles: 8, execute: { cpu in cpu.registers.H = cpu.rrc(cpu.registers.H) }),
        Instruction(asm: "RRC L", opcode: 0x0D, cycles: 8, execute: { cpu in cpu.registers.L = cpu.rrc(cpu.registers.L) }),
        Instruction(asm: "RRC (HL)", opcode: 0x0E, cycles: 16, execute: { cpu in var val =  cpu.rrc(cpu.read(at: cpu.registers.HL)); cpu.write(byte: val, at: cpu.registers.HL) }),
        Instruction(asm: "RRC A", opcode: 0x0F, cycles: 8, execute: { cpu in cpu.registers.A = cpu.rrc(cpu.registers.A) }),

        Instruction(asm: "RL B", opcode: 0x10, cycles: 8, execute: { cpu in cpu.registers.B = cpu.rl(cpu.registers.B) }),
        Instruction(asm: "RL C", opcode: 0x11, cycles: 8, execute: { cpu in cpu.registers.C = cpu.rl(cpu.registers.C) }),
        Instruction(asm: "RL D", opcode: 0x12, cycles: 8, execute: { cpu in cpu.registers.D = cpu.rl(cpu.registers.D) }),
        Instruction(asm: "RL E", opcode: 0x13, cycles: 8, execute: { cpu in cpu.registers.E = cpu.rl(cpu.registers.E) }),
        Instruction(asm: "RL H", opcode: 0x14, cycles: 8, execute: { cpu in cpu.registers.H = cpu.rl(cpu.registers.H) }),
        Instruction(asm: "RL L", opcode: 0x15, cycles: 8, execute: { cpu in cpu.registers.L = cpu.rl(cpu.registers.L) }),
        Instruction(asm: "RL (HL)", opcode: 0x16, cycles: 16, execute: { cpu in var val =  cpu.rl(cpu.read(at: cpu.registers.HL)); cpu.write(byte: val, at: cpu.registers.HL) }),
        Instruction(asm: "RL A", opcode: 0x17, cycles: 8, execute: { cpu in cpu.registers.A = cpu.rl(cpu.registers.A) }),

        Instruction(asm: "RR B", opcode: 0x18, cycles: 8, execute: { cpu in cpu.registers.B = cpu.rr(cpu.registers.B) }),
        Instruction(asm: "RR C", opcode: 0x19, cycles: 8, execute: { cpu in cpu.registers.C = cpu.rr(cpu.registers.C) }),
        Instruction(asm: "RR D", opcode: 0x1A, cycles: 8, execute: { cpu in cpu.registers.D = cpu.rr(cpu.registers.D) }),
        Instruction(asm: "RR E", opcode: 0x1B, cycles: 8, execute: { cpu in cpu.registers.E = cpu.rr(cpu.registers.E) }),
        Instruction(asm: "RR H", opcode: 0x1C, cycles: 8, execute: { cpu in cpu.registers.H = cpu.rr(cpu.registers.H) }),
        Instruction(asm: "RR L", opcode: 0x1D, cycles: 8, execute: { cpu in cpu.registers.L = cpu.rr(cpu.registers.L) }),
        Instruction(asm: "RR (HL)", opcode: 0x1E, cycles: 16, execute: { cpu in var val =  cpu.rr(cpu.read(at: cpu.registers.HL)); cpu.write(byte: val, at: cpu.registers.HL) }),
        Instruction(asm: "RR A", opcode: 0x1F, cycles: 8, execute: { cpu in cpu.registers.A = cpu.rr(cpu.registers.A) }),

        Instruction(asm: "SLA B", opcode: 0x20, cycles: 8, execute: { cpu in cpu.registers.B = cpu.sla(cpu.registers.B) }),
        Instruction(asm: "SLA C", opcode: 0x21, cycles: 8, execute: { cpu in cpu.registers.C = cpu.sla(cpu.registers.C) }),
        Instruction(asm: "SLA D", opcode: 0x22, cycles: 8, execute: { cpu in cpu.registers.D = cpu.sla(cpu.registers.D) }),
        Instruction(asm: "SLA E", opcode: 0x23, cycles: 8, execute: { cpu in cpu.registers.E = cpu.sla(cpu.registers.E) }),
        Instruction(asm: "SLA H", opcode: 0x24, cycles: 8, execute: { cpu in cpu.registers.H = cpu.sla(cpu.registers.H) }),
        Instruction(asm: "SLA L", opcode: 0x25, cycles: 8, execute: { cpu in cpu.registers.L = cpu.sla(cpu.registers.L) }),
        Instruction(asm: "SLA (HL)", opcode: 0x26, cycles: 16, execute: { cpu in var val =  cpu.sla(cpu.read(at: cpu.registers.HL)); cpu.write(byte: val, at: cpu.registers.HL) }),
        Instruction(asm: "SLA A", opcode: 0x27, cycles: 8, execute: { cpu in cpu.registers.A = cpu.sla(cpu.registers.A) }),

        Instruction(asm: "SRA B", opcode: 0x28, cycles: 8, execute: { cpu in cpu.registers.B = cpu.sra(cpu.registers.B) }),
        Instruction(asm: "SRA C", opcode: 0x29, cycles: 8, execute: { cpu in cpu.registers.C = cpu.sra(cpu.registers.C) }),
        Instruction(asm: "SRA D", opcode: 0x2A, cycles: 8, execute: { cpu in cpu.registers.D = cpu.sra(cpu.registers.D) }),
        Instruction(asm: "SRA E", opcode: 0x2B, cycles: 8, execute: { cpu in cpu.registers.E = cpu.sra(cpu.registers.E) }),
        Instruction(asm: "SRA H", opcode: 0x2C, cycles: 8, execute: { cpu in cpu.registers.H = cpu.sra(cpu.registers.H) }),
        Instruction(asm: "SRA L", opcode: 0x2D, cycles: 8, execute: { cpu in cpu.registers.L = cpu.sra(cpu.registers.L) }),
        Instruction(asm: "SRA (HL)", opcode: 0x2E, cycles: 16, execute: { cpu in var val =  cpu.sra(cpu.read(at: cpu.registers.HL)); cpu.write(byte: val, at: cpu.registers.HL) }),
        Instruction(asm: "SRA A", opcode: 0x2F, cycles: 8, execute: { cpu in cpu.registers.A = cpu.sra(cpu.registers.A) }),

        Instruction(asm: "SWAP B", opcode: 0x30, cycles: 8, execute: { cpu in cpu.registers.B = cpu.swap(cpu.registers.B) }),
        Instruction(asm: "SWAP C", opcode: 0x31, cycles: 8, execute: { cpu in cpu.registers.C = cpu.swap(cpu.registers.C) }),
        Instruction(asm: "SWAP D", opcode: 0x32, cycles: 8, execute: { cpu in cpu.registers.D = cpu.swap(cpu.registers.D) }),
        Instruction(asm: "SWAP E", opcode: 0x33, cycles: 8, execute: { cpu in cpu.registers.E = cpu.swap(cpu.registers.E) }),
        Instruction(asm: "SWAP H", opcode: 0x34, cycles: 8, execute: { cpu in cpu.registers.H = cpu.swap(cpu.registers.H) }),
        Instruction(asm: "SWAP L", opcode: 0x35, cycles: 8, execute: { cpu in cpu.registers.L = cpu.swap(cpu.registers.L) }),
        Instruction(asm: "SWAP (HL)", opcode: 0x36, cycles: 16, execute: { cpu in var val =  cpu.swap(cpu.read(at: cpu.registers.HL)); cpu.write(byte: val, at: cpu.registers.HL) }),
        Instruction(asm: "SWAP A", opcode: 0x37, cycles: 8, execute: { cpu in cpu.registers.A = cpu.swap(cpu.registers.A) }),

        Instruction(asm: "SRL B", opcode: 0x38, cycles: 8, execute: { cpu in cpu.registers.B = cpu.srl(cpu.registers.B) }),
        Instruction(asm: "SRL C", opcode: 0x39, cycles: 8, execute: { cpu in cpu.registers.C = cpu.srl(cpu.registers.C) }),
        Instruction(asm: "SRL D", opcode: 0x3A, cycles: 8, execute: { cpu in cpu.registers.D = cpu.srl(cpu.registers.D) }),
        Instruction(asm: "SRL E", opcode: 0x3B, cycles: 8, execute: { cpu in cpu.registers.E = cpu.srl(cpu.registers.E) }),
        Instruction(asm: "SRL H", opcode: 0x3C, cycles: 8, execute: { cpu in cpu.registers.H = cpu.srl(cpu.registers.H) }),
        Instruction(asm: "SRL L", opcode: 0x3D, cycles: 8, execute: { cpu in cpu.registers.L = cpu.srl(cpu.registers.L) }),
        Instruction(asm: "SRL (HL)", opcode: 0x3E, cycles: 16, execute: { cpu in var val =  cpu.srl(cpu.read(at: cpu.registers.HL)); cpu.write(byte: val, at: cpu.registers.HL) }),
        Instruction(asm: "BIT 0, B", opcode: 0x40, cycles: 8, execute: { cpu in cpu.bit(0, of: cpu.registers.B) }),
        Instruction(asm: "BIT 0, C", opcode: 0x41, cycles: 8, execute: { cpu in cpu.bit(0, of: cpu.registers.C) }),
        Instruction(asm: "BIT 0, D", opcode: 0x42, cycles: 8, execute: { cpu in cpu.bit(0, of: cpu.registers.D) }),
        Instruction(asm: "BIT 0, E", opcode: 0x43, cycles: 8, execute: { cpu in cpu.bit(0, of: cpu.registers.E) }),
        Instruction(asm: "BIT 0, H", opcode: 0x44, cycles: 8, execute: { cpu in cpu.bit(0, of: cpu.registers.H) }),
        Instruction(asm: "BIT 0, L", opcode: 0x45, cycles: 8, execute: { cpu in cpu.bit(0, of: cpu.registers.L) }),
        Instruction(asm: "BIT 0, (HL)", opcode: 0x46, cycles: 16, execute: { cpu in  cpu.bit(0, of: cpu.read(at: cpu.registers.HL)) }),
        Instruction(asm: "BIT 0, A", opcode: 0x47, cycles: 8, execute: { cpu in cpu.bit(0, of: cpu.registers.A) }),

        Instruction(asm: "BIT 1, B", opcode: 0x48, cycles: 8, execute: { cpu in cpu.bit(1, of: cpu.registers.B) }),
        Instruction(asm: "BIT 1, C", opcode: 0x49, cycles: 8, execute: { cpu in cpu.bit(1, of: cpu.registers.C) }),
        Instruction(asm: "BIT 1, D", opcode: 0x4A, cycles: 8, execute: { cpu in cpu.bit(1, of: cpu.registers.D) }),
        Instruction(asm: "BIT 1, E", opcode: 0x4B, cycles: 8, execute: { cpu in cpu.bit(1, of: cpu.registers.E) }),
        Instruction(asm: "BIT 1, H", opcode: 0x4C, cycles: 8, execute: { cpu in cpu.bit(1, of: cpu.registers.H) }),
        Instruction(asm: "BIT 1, L", opcode: 0x4D, cycles: 8, execute: { cpu in cpu.bit(1, of: cpu.registers.L) }),
        Instruction(asm: "BIT 1, (HL)", opcode: 0x4E, cycles: 16, execute: { cpu in  cpu.bit(1, of: cpu.read(at: cpu.registers.HL)) }),
        Instruction(asm: "BIT 1, A", opcode: 0x4F, cycles: 8, execute: { cpu in cpu.bit(1, of: cpu.registers.A) }),

        Instruction(asm: "BIT 2, B", opcode: 0x50, cycles: 8, execute: { cpu in cpu.bit(2, of: cpu.registers.B) }),
        Instruction(asm: "BIT 2, C", opcode: 0x51, cycles: 8, execute: { cpu in cpu.bit(2, of: cpu.registers.C) }),
        Instruction(asm: "BIT 2, D", opcode: 0x52, cycles: 8, execute: { cpu in cpu.bit(2, of: cpu.registers.D) }),
        Instruction(asm: "BIT 2, E", opcode: 0x53, cycles: 8, execute: { cpu in cpu.bit(2, of: cpu.registers.E) }),
        Instruction(asm: "BIT 2, H", opcode: 0x54, cycles: 8, execute: { cpu in cpu.bit(2, of: cpu.registers.H) }),
        Instruction(asm: "BIT 2, L", opcode: 0x55, cycles: 8, execute: { cpu in cpu.bit(2, of: cpu.registers.L) }),
        Instruction(asm: "BIT 2, (HL)", opcode: 0x56, cycles: 16, execute: { cpu in  cpu.bit(2, of: cpu.read(at: cpu.registers.HL)) }),
        Instruction(asm: "BIT 2, A", opcode: 0x57, cycles: 8, execute: { cpu in cpu.bit(2, of: cpu.registers.A) }),

        Instruction(asm: "BIT 3, B", opcode: 0x58, cycles: 8, execute: { cpu in cpu.bit(3, of: cpu.registers.B) }),
        Instruction(asm: "BIT 3, C", opcode: 0x59, cycles: 8, execute: { cpu in cpu.bit(3, of: cpu.registers.C) }),
        Instruction(asm: "BIT 3, D", opcode: 0x5A, cycles: 8, execute: { cpu in cpu.bit(3, of: cpu.registers.D) }),
        Instruction(asm: "BIT 3, E", opcode: 0x5B, cycles: 8, execute: { cpu in cpu.bit(3, of: cpu.registers.E) }),
        Instruction(asm: "BIT 3, H", opcode: 0x5C, cycles: 8, execute: { cpu in cpu.bit(3, of: cpu.registers.H) }),
        Instruction(asm: "BIT 3, L", opcode: 0x5D, cycles: 8, execute: { cpu in cpu.bit(3, of: cpu.registers.L) }),
        Instruction(asm: "BIT 3, (HL)", opcode: 0x5E, cycles: 16, execute: { cpu in  cpu.bit(3, of: cpu.read(at: cpu.registers.HL)) }),
        Instruction(asm: "BIT 3, A", opcode: 0x5F, cycles: 8, execute: { cpu in cpu.bit(3, of: cpu.registers.A) }),

        Instruction(asm: "BIT 4, B", opcode: 0x60, cycles: 8, execute: { cpu in cpu.bit(4, of: cpu.registers.B) }),
        Instruction(asm: "BIT 4, C", opcode: 0x61, cycles: 8, execute: { cpu in cpu.bit(4, of: cpu.registers.C) }),
        Instruction(asm: "BIT 4, D", opcode: 0x62, cycles: 8, execute: { cpu in cpu.bit(4, of: cpu.registers.D) }),
        Instruction(asm: "BIT 4, E", opcode: 0x63, cycles: 8, execute: { cpu in cpu.bit(4, of: cpu.registers.E) }),
        Instruction(asm: "BIT 4, H", opcode: 0x64, cycles: 8, execute: { cpu in cpu.bit(4, of: cpu.registers.H) }),
        Instruction(asm: "BIT 4, L", opcode: 0x65, cycles: 8, execute: { cpu in cpu.bit(4, of: cpu.registers.L) }),
        Instruction(asm: "BIT 4, (HL)", opcode: 0x66, cycles: 16, execute: { cpu in  cpu.bit(4, of: cpu.read(at: cpu.registers.HL)) }),
        Instruction(asm: "BIT 4, A", opcode: 0x67, cycles: 8, execute: { cpu in cpu.bit(4, of: cpu.registers.A) }),

        Instruction(asm: "BIT 5, B", opcode: 0x68, cycles: 8, execute: { cpu in cpu.bit(5, of: cpu.registers.B) }),
        Instruction(asm: "BIT 5, C", opcode: 0x69, cycles: 8, execute: { cpu in cpu.bit(5, of: cpu.registers.C) }),
        Instruction(asm: "BIT 5, D", opcode: 0x6A, cycles: 8, execute: { cpu in cpu.bit(5, of: cpu.registers.D) }),
        Instruction(asm: "BIT 5, E", opcode: 0x6B, cycles: 8, execute: { cpu in cpu.bit(5, of: cpu.registers.E) }),
        Instruction(asm: "BIT 5, H", opcode: 0x6C, cycles: 8, execute: { cpu in cpu.bit(5, of: cpu.registers.H) }),
        Instruction(asm: "BIT 5, L", opcode: 0x6D, cycles: 8, execute: { cpu in cpu.bit(5, of: cpu.registers.L) }),
        Instruction(asm: "BIT 5, (HL)", opcode: 0x6E, cycles: 16, execute: { cpu in  cpu.bit(5, of: cpu.read(at: cpu.registers.HL)) }),
        Instruction(asm: "BIT 5, A", opcode: 0x6F, cycles: 8, execute: { cpu in cpu.bit(5, of: cpu.registers.A) }),

        Instruction(asm: "BIT 6, B", opcode: 0x70, cycles: 8, execute: { cpu in cpu.bit(6, of: cpu.registers.B) }),
        Instruction(asm: "BIT 6, C", opcode: 0x71, cycles: 8, execute: { cpu in cpu.bit(6, of: cpu.registers.C) }),
        Instruction(asm: "BIT 6, D", opcode: 0x72, cycles: 8, execute: { cpu in cpu.bit(6, of: cpu.registers.D) }),
        Instruction(asm: "BIT 6, E", opcode: 0x73, cycles: 8, execute: { cpu in cpu.bit(6, of: cpu.registers.E) }),
        Instruction(asm: "BIT 6, H", opcode: 0x74, cycles: 8, execute: { cpu in cpu.bit(6, of: cpu.registers.H) }),
        Instruction(asm: "BIT 6, L", opcode: 0x75, cycles: 8, execute: { cpu in cpu.bit(6, of: cpu.registers.L) }),
        Instruction(asm: "BIT 6, (HL)", opcode: 0x76, cycles: 16, execute: { cpu in  cpu.bit(6, of: cpu.read(at: cpu.registers.HL)) }),
        Instruction(asm: "BIT 6, A", opcode: 0x77, cycles: 8, execute: { cpu in cpu.bit(6, of: cpu.registers.A) }),

        Instruction(asm: "BIT 7, B", opcode: 0x78, cycles: 8, execute: { cpu in cpu.bit(7, of: cpu.registers.B) }),
        Instruction(asm: "BIT 7, C", opcode: 0x79, cycles: 8, execute: { cpu in cpu.bit(7, of: cpu.registers.C) }),
        Instruction(asm: "BIT 7, D", opcode: 0x7A, cycles: 8, execute: { cpu in cpu.bit(7, of: cpu.registers.D) }),
        Instruction(asm: "BIT 7, E", opcode: 0x7B, cycles: 8, execute: { cpu in cpu.bit(7, of: cpu.registers.E) }),
        Instruction(asm: "BIT 7, H", opcode: 0x7C, cycles: 8, execute: { cpu in cpu.bit(7, of: cpu.registers.H) }),
        Instruction(asm: "BIT 7, L", opcode: 0x7D, cycles: 8, execute: { cpu in cpu.bit(7, of: cpu.registers.L) }),
        Instruction(asm: "BIT 7, (HL)", opcode: 0x7E, cycles: 16, execute: { cpu in  cpu.bit(7, of: cpu.read(at: cpu.registers.HL)) }),
        Instruction(asm: "BIT 7, A", opcode: 0x7F, cycles: 8, execute: { cpu in cpu.bit(7, of: cpu.registers.A) }),

        Instruction(asm: "RES 0, B", opcode: 0x80, cycles: 8, execute: { cpu in cpu.registers.B = cpu.res(0, of: cpu.registers.B) }),
        Instruction(asm: "RES 0, C", opcode: 0x81, cycles: 8, execute: { cpu in cpu.registers.C = cpu.res(0, of: cpu.registers.C) }),
        Instruction(asm: "RES 0, D", opcode: 0x82, cycles: 8, execute: { cpu in cpu.registers.D = cpu.res(0, of: cpu.registers.D) }),
        Instruction(asm: "RES 0, E", opcode: 0x83, cycles: 8, execute: { cpu in cpu.registers.E = cpu.res(0, of: cpu.registers.E) }),
        Instruction(asm: "RES 0, H", opcode: 0x84, cycles: 8, execute: { cpu in cpu.registers.H = cpu.res(0, of: cpu.registers.H) }),
        Instruction(asm: "RES 0, L", opcode: 0x85, cycles: 8, execute: { cpu in cpu.registers.L = cpu.res(0, of: cpu.registers.L) }),
        Instruction(asm: "RES 0, (HL)", opcode: 0x86, cycles: 16, execute: { cpu in var val =  cpu.res(0, of: cpu.read(at: cpu.registers.HL)); cpu.write(byte: val, at: cpu.registers.HL) }),
        Instruction(asm: "RES 0, A", opcode: 0x87, cycles: 8, execute: { cpu in cpu.registers.A = cpu.res(0, of: cpu.registers.A) }),

        Instruction(asm: "RES 1, B", opcode: 0x88, cycles: 8, execute: { cpu in cpu.registers.B = cpu.res(1, of: cpu.registers.B) }),
        Instruction(asm: "RES 1, C", opcode: 0x89, cycles: 8, execute: { cpu in cpu.registers.C = cpu.res(1, of: cpu.registers.C) }),
        Instruction(asm: "RES 1, D", opcode: 0x8A, cycles: 8, execute: { cpu in cpu.registers.D = cpu.res(1, of: cpu.registers.D) }),
        Instruction(asm: "RES 1, E", opcode: 0x8B, cycles: 8, execute: { cpu in cpu.registers.E = cpu.res(1, of: cpu.registers.E) }),
        Instruction(asm: "RES 1, H", opcode: 0x8C, cycles: 8, execute: { cpu in cpu.registers.H = cpu.res(1, of: cpu.registers.H) }),
        Instruction(asm: "RES 1, L", opcode: 0x8D, cycles: 8, execute: { cpu in cpu.registers.L = cpu.res(1, of: cpu.registers.L) }),
        Instruction(asm: "RES 1, (HL)", opcode: 0x8E, cycles: 16, execute: { cpu in var val =  cpu.res(1, of: cpu.read(at: cpu.registers.HL)); cpu.write(byte: val, at: cpu.registers.HL) }),
        Instruction(asm: "RES 1, A", opcode: 0x8F, cycles: 8, execute: { cpu in cpu.registers.A = cpu.res(1, of: cpu.registers.A) }),

        Instruction(asm: "RES 2, B", opcode: 0x90, cycles: 8, execute: { cpu in cpu.registers.B = cpu.res(2, of: cpu.registers.B) }),
        Instruction(asm: "RES 2, C", opcode: 0x91, cycles: 8, execute: { cpu in cpu.registers.C = cpu.res(2, of: cpu.registers.C) }),
        Instruction(asm: "RES 2, D", opcode: 0x92, cycles: 8, execute: { cpu in cpu.registers.D = cpu.res(2, of: cpu.registers.D) }),
        Instruction(asm: "RES 2, E", opcode: 0x93, cycles: 8, execute: { cpu in cpu.registers.E = cpu.res(2, of: cpu.registers.E) }),
        Instruction(asm: "RES 2, H", opcode: 0x94, cycles: 8, execute: { cpu in cpu.registers.H = cpu.res(2, of: cpu.registers.H) }),
        Instruction(asm: "RES 2, L", opcode: 0x95, cycles: 8, execute: { cpu in cpu.registers.L = cpu.res(2, of: cpu.registers.L) }),
        Instruction(asm: "RES 2, (HL)", opcode: 0x96, cycles: 16, execute: { cpu in var val =  cpu.res(2, of: cpu.read(at: cpu.registers.HL)); cpu.write(byte: val, at: cpu.registers.HL) }),
        Instruction(asm: "RES 2, A", opcode: 0x97, cycles: 8, execute: { cpu in cpu.registers.A = cpu.res(2, of: cpu.registers.A) }),

        Instruction(asm: "RES 3, B", opcode: 0x98, cycles: 8, execute: { cpu in cpu.registers.B = cpu.res(3, of: cpu.registers.B) }),
        Instruction(asm: "RES 3, C", opcode: 0x99, cycles: 8, execute: { cpu in cpu.registers.C = cpu.res(3, of: cpu.registers.C) }),
        Instruction(asm: "RES 3, D", opcode: 0x9A, cycles: 8, execute: { cpu in cpu.registers.D = cpu.res(3, of: cpu.registers.D) }),
        Instruction(asm: "RES 3, E", opcode: 0x9B, cycles: 8, execute: { cpu in cpu.registers.E = cpu.res(3, of: cpu.registers.E) }),
        Instruction(asm: "RES 3, H", opcode: 0x9C, cycles: 8, execute: { cpu in cpu.registers.H = cpu.res(3, of: cpu.registers.H) }),
        Instruction(asm: "RES 3, L", opcode: 0x9D, cycles: 8, execute: { cpu in cpu.registers.L = cpu.res(3, of: cpu.registers.L) }),
        Instruction(asm: "RES 3, (HL)", opcode: 0x9E, cycles: 16, execute: { cpu in var val =  cpu.res(3, of: cpu.read(at: cpu.registers.HL)); cpu.write(byte: val, at: cpu.registers.HL) }),
        Instruction(asm: "RES 3, A", opcode: 0x9F, cycles: 8, execute: { cpu in cpu.registers.A = cpu.res(3, of: cpu.registers.A) }),

        Instruction(asm: "RES 4, B", opcode: 0xA0, cycles: 8, execute: { cpu in cpu.registers.B = cpu.res(4, of: cpu.registers.B) }),
        Instruction(asm: "RES 4, C", opcode: 0xA1, cycles: 8, execute: { cpu in cpu.registers.C = cpu.res(4, of: cpu.registers.C) }),
        Instruction(asm: "RES 4, D", opcode: 0xA2, cycles: 8, execute: { cpu in cpu.registers.D = cpu.res(4, of: cpu.registers.D) }),
        Instruction(asm: "RES 4, E", opcode: 0xA3, cycles: 8, execute: { cpu in cpu.registers.E = cpu.res(4, of: cpu.registers.E) }),
        Instruction(asm: "RES 4, H", opcode: 0xA4, cycles: 8, execute: { cpu in cpu.registers.H = cpu.res(4, of: cpu.registers.H) }),
        Instruction(asm: "RES 4, L", opcode: 0xA5, cycles: 8, execute: { cpu in cpu.registers.L = cpu.res(4, of: cpu.registers.L) }),
        Instruction(asm: "RES 4, (HL)", opcode: 0xA6, cycles: 16, execute: { cpu in var val =  cpu.res(4, of: cpu.read(at: cpu.registers.HL)); cpu.write(byte: val, at: cpu.registers.HL) }),
        Instruction(asm: "RES 4, A", opcode: 0xA7, cycles: 8, execute: { cpu in cpu.registers.A = cpu.res(4, of: cpu.registers.A) }),

        Instruction(asm: "RES 5, B", opcode: 0xA8, cycles: 8, execute: { cpu in cpu.registers.B = cpu.res(5, of: cpu.registers.B) }),
        Instruction(asm: "RES 5, C", opcode: 0xA9, cycles: 8, execute: { cpu in cpu.registers.C = cpu.res(5, of: cpu.registers.C) }),
        Instruction(asm: "RES 5, D", opcode: 0xAA, cycles: 8, execute: { cpu in cpu.registers.D = cpu.res(5, of: cpu.registers.D) }),
        Instruction(asm: "RES 5, E", opcode: 0xAB, cycles: 8, execute: { cpu in cpu.registers.E = cpu.res(5, of: cpu.registers.E) }),
        Instruction(asm: "RES 5, H", opcode: 0xAC, cycles: 8, execute: { cpu in cpu.registers.H = cpu.res(5, of: cpu.registers.H) }),
        Instruction(asm: "RES 5, L", opcode: 0xAD, cycles: 8, execute: { cpu in cpu.registers.L = cpu.res(5, of: cpu.registers.L) }),
        Instruction(asm: "RES 5, (HL)", opcode: 0xAE, cycles: 16, execute: { cpu in var val =  cpu.res(5, of: cpu.read(at: cpu.registers.HL)); cpu.write(byte: val, at: cpu.registers.HL) }),
        Instruction(asm: "RES 5, A", opcode: 0xAF, cycles: 8, execute: { cpu in cpu.registers.A = cpu.res(5, of: cpu.registers.A) }),

        Instruction(asm: "RES 6, B", opcode: 0xB0, cycles: 8, execute: { cpu in cpu.registers.B = cpu.res(6, of: cpu.registers.B) }),
        Instruction(asm: "RES 6, C", opcode: 0xB1, cycles: 8, execute: { cpu in cpu.registers.C = cpu.res(6, of: cpu.registers.C) }),
        Instruction(asm: "RES 6, D", opcode: 0xB2, cycles: 8, execute: { cpu in cpu.registers.D = cpu.res(6, of: cpu.registers.D) }),
        Instruction(asm: "RES 6, E", opcode: 0xB3, cycles: 8, execute: { cpu in cpu.registers.E = cpu.res(6, of: cpu.registers.E) }),
        Instruction(asm: "RES 6, H", opcode: 0xB4, cycles: 8, execute: { cpu in cpu.registers.H = cpu.res(6, of: cpu.registers.H) }),
        Instruction(asm: "RES 6, L", opcode: 0xB5, cycles: 8, execute: { cpu in cpu.registers.L = cpu.res(6, of: cpu.registers.L) }),
        Instruction(asm: "RES 6, (HL)", opcode: 0xB6, cycles: 16, execute: { cpu in var val =  cpu.res(6, of: cpu.read(at: cpu.registers.HL)); cpu.write(byte: val, at: cpu.registers.HL) }),
        Instruction(asm: "RES 6, A", opcode: 0xB7, cycles: 8, execute: { cpu in cpu.registers.A = cpu.res(6, of: cpu.registers.A) }),

        Instruction(asm: "RES 7, B", opcode: 0xB8, cycles: 8, execute: { cpu in cpu.registers.B = cpu.res(7, of: cpu.registers.B) }),
        Instruction(asm: "RES 7, C", opcode: 0xB9, cycles: 8, execute: { cpu in cpu.registers.C = cpu.res(7, of: cpu.registers.C) }),
        Instruction(asm: "RES 7, D", opcode: 0xBA, cycles: 8, execute: { cpu in cpu.registers.D = cpu.res(7, of: cpu.registers.D) }),
        Instruction(asm: "RES 7, E", opcode: 0xBB, cycles: 8, execute: { cpu in cpu.registers.E = cpu.res(7, of: cpu.registers.E) }),
        Instruction(asm: "RES 7, H", opcode: 0xBC, cycles: 8, execute: { cpu in cpu.registers.H = cpu.res(7, of: cpu.registers.H) }),
        Instruction(asm: "RES 7, L", opcode: 0xBD, cycles: 8, execute: { cpu in cpu.registers.L = cpu.res(7, of: cpu.registers.L) }),
        Instruction(asm: "RES 7, (HL)", opcode: 0xBE, cycles: 16, execute: { cpu in var val =  cpu.res(7, of: cpu.read(at: cpu.registers.HL)); cpu.write(byte: val, at: cpu.registers.HL) }),
        Instruction(asm: "RES 7, A", opcode: 0xBF, cycles: 8, execute: { cpu in cpu.registers.A = cpu.res(7, of: cpu.registers.A) }),

        Instruction(asm: "SET 0, B", opcode: 0xC0, cycles: 8, execute: { cpu in cpu.registers.B = cpu.set(0, of: cpu.registers.B) }),
        Instruction(asm: "SET 0, C", opcode: 0xC1, cycles: 8, execute: { cpu in cpu.registers.C = cpu.set(0, of: cpu.registers.C) }),
        Instruction(asm: "SET 0, D", opcode: 0xC2, cycles: 8, execute: { cpu in cpu.registers.D = cpu.set(0, of: cpu.registers.D) }),
        Instruction(asm: "SET 0, E", opcode: 0xC3, cycles: 8, execute: { cpu in cpu.registers.E = cpu.set(0, of: cpu.registers.E) }),
        Instruction(asm: "SET 0, H", opcode: 0xC4, cycles: 8, execute: { cpu in cpu.registers.H = cpu.set(0, of: cpu.registers.H) }),
        Instruction(asm: "SET 0, L", opcode: 0xC5, cycles: 8, execute: { cpu in cpu.registers.L = cpu.set(0, of: cpu.registers.L) }),
        Instruction(asm: "SET 0, (HL)", opcode: 0xC6, cycles: 12, execute: { cpu in var val =  cpu.set(0, of: cpu.read(at: cpu.registers.HL)); cpu.write(byte: val, at: cpu.registers.HL) }),
        Instruction(asm: "SET 0, A", opcode: 0xC7, cycles: 8, execute: { cpu in cpu.registers.A = cpu.set(0, of: cpu.registers.A) }),

        Instruction(asm: "SET 1, B", opcode: 0xC8, cycles: 8, execute: { cpu in cpu.registers.B = cpu.set(1, of: cpu.registers.B) }),
        Instruction(asm: "SET 1, C", opcode: 0xC9, cycles: 8, execute: { cpu in cpu.registers.C = cpu.set(1, of: cpu.registers.C) }),
        Instruction(asm: "SET 1, D", opcode: 0xCA, cycles: 8, execute: { cpu in cpu.registers.D = cpu.set(1, of: cpu.registers.D) }),
        Instruction(asm: "SET 1, E", opcode: 0xCB, cycles: 8, execute: { cpu in cpu.registers.E = cpu.set(1, of: cpu.registers.E) }),
        Instruction(asm: "SET 1, H", opcode: 0xCC, cycles: 8, execute: { cpu in cpu.registers.H = cpu.set(1, of: cpu.registers.H) }),
        Instruction(asm: "SET 1, L", opcode: 0xCD, cycles: 8, execute: { cpu in cpu.registers.L = cpu.set(1, of: cpu.registers.L) }),
        Instruction(asm: "SET 1, (HL)", opcode: 0xCE, cycles: 12, execute: { cpu in var val =  cpu.set(1, of: cpu.read(at: cpu.registers.HL)); cpu.write(byte: val, at: cpu.registers.HL) }),
        Instruction(asm: "SET 1, A", opcode: 0xCF, cycles: 8, execute: { cpu in cpu.registers.A = cpu.set(1, of: cpu.registers.A) }),

        Instruction(asm: "SET 2, B", opcode: 0xD0, cycles: 8, execute: { cpu in cpu.registers.B = cpu.set(2, of: cpu.registers.B) }),
        Instruction(asm: "SET 2, C", opcode: 0xD1, cycles: 8, execute: { cpu in cpu.registers.C = cpu.set(2, of: cpu.registers.C) }),
        Instruction(asm: "SET 2, D", opcode: 0xD2, cycles: 8, execute: { cpu in cpu.registers.D = cpu.set(2, of: cpu.registers.D) }),
        Instruction(asm: "SET 2, E", opcode: 0xD3, cycles: 8, execute: { cpu in cpu.registers.E = cpu.set(2, of: cpu.registers.E) }),
        Instruction(asm: "SET 2, H", opcode: 0xD4, cycles: 8, execute: { cpu in cpu.registers.H = cpu.set(2, of: cpu.registers.H) }),
        Instruction(asm: "SET 2, L", opcode: 0xD5, cycles: 8, execute: { cpu in cpu.registers.L = cpu.set(2, of: cpu.registers.L) }),
        Instruction(asm: "SET 2, (HL)", opcode: 0xD6, cycles: 12, execute: { cpu in var val =  cpu.set(2, of: cpu.read(at: cpu.registers.HL)); cpu.write(byte: val, at: cpu.registers.HL) }),
        Instruction(asm: "SET 2, A", opcode: 0xD7, cycles: 8, execute: { cpu in cpu.registers.A = cpu.set(2, of: cpu.registers.A) }),

        Instruction(asm: "SET 3, B", opcode: 0xD8, cycles: 8, execute: { cpu in cpu.registers.B = cpu.set(3, of: cpu.registers.B) }),
        Instruction(asm: "SET 3, C", opcode: 0xD9, cycles: 8, execute: { cpu in cpu.registers.C = cpu.set(3, of: cpu.registers.C) }),
        Instruction(asm: "SET 3, D", opcode: 0xDA, cycles: 8, execute: { cpu in cpu.registers.D = cpu.set(3, of: cpu.registers.D) }),
        Instruction(asm: "SET 3, E", opcode: 0xDB, cycles: 8, execute: { cpu in cpu.registers.E = cpu.set(3, of: cpu.registers.E) }),
        Instruction(asm: "SET 3, H", opcode: 0xDC, cycles: 8, execute: { cpu in cpu.registers.H = cpu.set(3, of: cpu.registers.H) }),
        Instruction(asm: "SET 3, L", opcode: 0xDD, cycles: 8, execute: { cpu in cpu.registers.L = cpu.set(3, of: cpu.registers.L) }),
        Instruction(asm: "SET 3, (HL)", opcode: 0xDE, cycles: 12, execute: { cpu in var val =  cpu.set(3, of: cpu.read(at: cpu.registers.HL)); cpu.write(byte: val, at: cpu.registers.HL) }),
        Instruction(asm: "SET 3, A", opcode: 0xDF, cycles: 8, execute: { cpu in cpu.registers.A = cpu.set(3, of: cpu.registers.A) }),

        Instruction(asm: "SET 4, B", opcode: 0xE0, cycles: 8, execute: { cpu in cpu.registers.B = cpu.set(4, of: cpu.registers.B) }),
        Instruction(asm: "SET 4, C", opcode: 0xE1, cycles: 8, execute: { cpu in cpu.registers.C = cpu.set(4, of: cpu.registers.C) }),
        Instruction(asm: "SET 4, D", opcode: 0xE2, cycles: 8, execute: { cpu in cpu.registers.D = cpu.set(4, of: cpu.registers.D) }),
        Instruction(asm: "SET 4, E", opcode: 0xE3, cycles: 8, execute: { cpu in cpu.registers.E = cpu.set(4, of: cpu.registers.E) }),
        Instruction(asm: "SET 4, H", opcode: 0xE4, cycles: 8, execute: { cpu in cpu.registers.H = cpu.set(4, of: cpu.registers.H) }),
        Instruction(asm: "SET 4, L", opcode: 0xE5, cycles: 8, execute: { cpu in cpu.registers.L = cpu.set(4, of: cpu.registers.L) }),
        Instruction(asm: "SET 4, (HL)", opcode: 0xE6, cycles: 12, execute: { cpu in var val =  cpu.set(4, of: cpu.read(at: cpu.registers.HL)); cpu.write(byte: val, at: cpu.registers.HL) }),
        Instruction(asm: "SET 4, A", opcode: 0xE7, cycles: 8, execute: { cpu in cpu.registers.A = cpu.set(4, of: cpu.registers.A) }),

        Instruction(asm: "SET 5, B", opcode: 0xE8, cycles: 8, execute: { cpu in cpu.registers.B = cpu.set(5, of: cpu.registers.B) }),
        Instruction(asm: "SET 5, C", opcode: 0xE9, cycles: 8, execute: { cpu in cpu.registers.C = cpu.set(5, of: cpu.registers.C) }),
        Instruction(asm: "SET 5, D", opcode: 0xEA, cycles: 8, execute: { cpu in cpu.registers.D = cpu.set(5, of: cpu.registers.D) }),
        Instruction(asm: "SET 5, E", opcode: 0xEB, cycles: 8, execute: { cpu in cpu.registers.E = cpu.set(5, of: cpu.registers.E) }),
        Instruction(asm: "SET 5, H", opcode: 0xEC, cycles: 8, execute: { cpu in cpu.registers.H = cpu.set(5, of: cpu.registers.H) }),
        Instruction(asm: "SET 5, L", opcode: 0xED, cycles: 8, execute: { cpu in cpu.registers.L = cpu.set(5, of: cpu.registers.L) }),
        Instruction(asm: "SET 5, (HL)", opcode: 0xEE, cycles: 12, execute: { cpu in var val =  cpu.set(5, of: cpu.read(at: cpu.registers.HL)); cpu.write(byte: val, at: cpu.registers.HL) }),
        Instruction(asm: "SET 5, A", opcode: 0xEF, cycles: 8, execute: { cpu in cpu.registers.A = cpu.set(5, of: cpu.registers.A) }),

        Instruction(asm: "SET 6, B", opcode: 0xF0, cycles: 8, execute: { cpu in cpu.registers.B = cpu.set(6, of: cpu.registers.B) }),
        Instruction(asm: "SET 6, C", opcode: 0xF1, cycles: 8, execute: { cpu in cpu.registers.C = cpu.set(6, of: cpu.registers.C) }),
        Instruction(asm: "SET 6, D", opcode: 0xF2, cycles: 8, execute: { cpu in cpu.registers.D = cpu.set(6, of: cpu.registers.D) }),
        Instruction(asm: "SET 6, E", opcode: 0xF3, cycles: 8, execute: { cpu in cpu.registers.E = cpu.set(6, of: cpu.registers.E) }),
        Instruction(asm: "SET 6, H", opcode: 0xF4, cycles: 8, execute: { cpu in cpu.registers.H = cpu.set(6, of: cpu.registers.H) }),
        Instruction(asm: "SET 6, L", opcode: 0xF5, cycles: 8, execute: { cpu in cpu.registers.L = cpu.set(6, of: cpu.registers.L) }),
        Instruction(asm: "SET 6, (HL)", opcode: 0xF6, cycles: 12, execute: { cpu in var val =  cpu.set(6, of: cpu.read(at: cpu.registers.HL)); cpu.write(byte: val, at: cpu.registers.HL) }),
        Instruction(asm: "SET 6, A", opcode: 0xF7, cycles: 8, execute: { cpu in cpu.registers.A = cpu.set(6, of: cpu.registers.A) }),

        Instruction(asm: "SET 7, B", opcode: 0xF8, cycles: 8, execute: { cpu in cpu.registers.B = cpu.set(7, of: cpu.registers.B) }),
        Instruction(asm: "SET 7, C", opcode: 0xF9, cycles: 8, execute: { cpu in cpu.registers.C = cpu.set(7, of: cpu.registers.C) }),
        Instruction(asm: "SET 7, D", opcode: 0xFA, cycles: 8, execute: { cpu in cpu.registers.D = cpu.set(7, of: cpu.registers.D) }),
        Instruction(asm: "SET 7, E", opcode: 0xFB, cycles: 8, execute: { cpu in cpu.registers.E = cpu.set(7, of: cpu.registers.E) }),
        Instruction(asm: "SET 7, H", opcode: 0xFC, cycles: 8, execute: { cpu in cpu.registers.H = cpu.set(7, of: cpu.registers.H) }),
        Instruction(asm: "SET 7, L", opcode: 0xFD, cycles: 8, execute: { cpu in cpu.registers.L = cpu.set(7, of: cpu.registers.L) }),
        Instruction(asm: "SET 7, (HL)", opcode: 0xFE, cycles: 12, execute: { cpu in var val =  cpu.set(7, of: cpu.read(at: cpu.registers.HL)); cpu.write(byte: val, at: cpu.registers.HL) }),
    ]
}