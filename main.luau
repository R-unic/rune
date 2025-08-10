--!strict
--!native
local fs = require("@lune/fs") :: fs
local process = require("@lune/process") :: process
local tokenize = require("./lexer")
local parse = require("./parser")
local CodeGen = require("./codegen")
local vm = require("./vm")
local try = require("./try")
local op = require("./opcode")
local OpCodeInverse = op.OpCodeInverse

local path = process.args[1]
local source = try(fs.readFile, path)
local tokens = tokenize(source)
local ast = parse(tokens)
local codegen = CodeGen.new()
local bytecode, constants = codegen:generate(ast)

local spaceLength = 12
local function stringify(instruction: vm.Instruction): string
  local opName = OpCodeInverse[instruction.opcode]
  local remainingLength = spaceLength - string.len(opName)
  return opName
    .. string.rep(" ", remainingLength) .. "A: " .. instruction.A
    .. "   " .. "B: " .. (instruction.B or 0)
    .. "   " .. "C: " .. (instruction.C or 0)
end
print("constants:", constants)
print("instructions:")
for i, instruction in bytecode do
  print(i - 1 .. ":", stringify(instruction))
end
local result = vm.run(bytecode, constants)
print(result)