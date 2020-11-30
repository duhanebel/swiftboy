
ops = ["RLC", "RRC",
       "RL", "RR",
       "SLA", "SRA",
       "SWAP", "SRL",
       "BIT 0", "BIT 1",
       "BIT 2", "BIT 3",
       "BIT 4", "BIT 5",
       "BIT 6", "BIT 7",
       "RES 0", "RES 1",
       "RES 2", "RES 3",
       "RES 4", "RES 5",
       "RES 6", "RES 7",
       "SET 0", "SET 1",
       "SET 2", "SET 3",
       "SET 4", "SET 5",
       "SET 6", "SET 7"]

regs = [ "B", "C", "D", "E", "H", "L", "(HL)", "A"]

puts "extension Instruction {"
puts "     static var allExtInstructions: [Instruction] = ["
(0...0x3F).each do |i|
  op = ops[i / regs.size]
  reg = regs[i % regs.size]
  if reg != "(HL)"
    puts "        Instruction(asm: \"#{op} #{reg}\", opcode: 0x#{sprintf("%02x",i).upcase}, cycles: 8, execute: { cpu in cpu.#{op.downcase}(&cpu.registers.#{reg}) }),"
  else
    puts "        Instruction(asm: \"#{op} #{reg}\", opcode: 0x#{sprintf("%02x",i).upcase}, cycles: 16, execute: { cpu in var val = cpu.read(at: cpu.registers.HL); cpu.#{op.downcase}(&val); cpu.write(byte: val, at: cpu.registers.HL) }),"
  end
  puts "" if i % regs.size == regs.size-1
end

(0x40...0xFF).each do |i|
  op_name = ops[i / regs.size]
  reg = regs[i % regs.size]
  op = op_name.split.first
  bit = op_name.split.last
  if reg != "(HL)"
    puts "        Instruction(asm: \"#{op} #{bit}, #{reg}\", opcode: 0x#{sprintf("%02x",i).upcase}, cycles: 8, execute: { cpu in cpu.#{op.downcase}(#{bit}, of: &cpu.registers.#{reg}) }),"
  else
    if op == "SET"
      cost = 12
    else
      cost = 16
    end
    puts "        Instruction(asm: \"#{op} #{bit}, #{reg}\", opcode: 0x#{sprintf("%02x",i).upcase}, cycles: #{cost}, execute: { cpu in var val = cpu.read(at: cpu.registers.HL); cpu.#{op.downcase}(#{bit}, of: &val); cpu.write(byte: val, at: cpu.registers.HL) }),"
  end
  puts "" if i % regs.size == regs.size-1

end
puts "    ]"
puts "}"



