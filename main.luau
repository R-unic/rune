--!strict
--!native
local fs = require("@lune/fs") :: fs
local process = require("@lune/process") :: process
local luau = require("@lune/luau") :: luau
local varint = require("./varint")
local tokenize = require("./lexer")
local parse = require("./parser")
local vm = require("./vm")
local try = require("./try")

-- local path = process.args[1]
-- local source = try(fs.readFile, path)
-- local tokens = tokenize(source)
-- local ast = parse(tokens)
-- print(ast)

local ROP_NOOP = 0
local ROP_LOADN = 1
local ROP_RETURN = 2

local instructions: { vm.Instruction } = {
  { opcode = ROP_LOADN, A = 0, B = 69 },
  { opcode = ROP_RETURN, A = 0 }
}

local result = vm.run(instructions)
print(result)