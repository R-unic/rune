--!strict
--!native
local fs = require("@lune/fs") :: fs
local process = require("@lune/process") :: process
local luau = require("@lune/luau") :: luau
local varint = require("./varint")
local tokenize = require("./lexer")
local parse = require("./parser")
local bytecode = require("./bytecode")
local try = require("./try")

-- local path = process.args[1]
-- local source = try(fs.readFile, path)
-- local tokens = tokenize(source)
-- local ast = parse(tokens)
-- print(ast)

local LOP_LOADN = 4
local LOP_LOADK = 5
local LOP_GETGLOBAL = 7
local LOP_CALL = 21
local LOP_RETURN = 22
local LOP_ADD = 33
local LOP_PREPVARARGS = 65

local helloWorld: { bytecode.Instruction } = {
  {op = LOP_PREPVARARGS, A = 0},
  {op = LOP_GETGLOBAL, A = 0, Bx = 0},
  {op = LOP_LOADK, A = 1, Bx = 1},
  {op = LOP_CALL, A = 0, B = 2, C = 1}
}
local helloWorldConstants: { bytecode.LuauConstant } = {
  "print",
  "Hello, world!"
}

local onePlusTwo: { bytecode.Instruction } = {
  {op = LOP_PREPVARARGS, A = 0},
  {op = LOP_LOADN, A = 0, Bx = 1},
  {op = LOP_LOADN, A = 1, Bx = 2},
  {op = LOP_ADD, A = 2, B = 1, C = 0},
  {op = LOP_RETURN, A = 2, B = 2}
}
local onePlusTwoConstants: { bytecode.LuauConstant } = {}

local get123: { bytecode.Instruction } = {
  {op = LOP_PREPVARARGS, A = 0},
  {op = LOP_LOADN, A = 0, Bx = 123},
  {op = LOP_RETURN, A = 0, B = 2},
}
local get123Constants: { bytecode.LuauConstant } = {}

-- local gen = bytecode.createProto(helloWorld, helloWorldConstants, 3)
-- local gen = bytecode.createProto(onePlusTwo, onePlusTwoConstants, 3)
local gen = bytecode.createProto(get123, get123Constants, 3)
local expected = luau.compile("return 123")

print("expected bytecode:", string.byte(expected, 1, #expected))
print("  result bytecode:", string.byte(gen, 1, #gen))

print("loading genned bytecode...")
local success, fn = pcall(luau.load, gen)
print("loaded genned bytecode")
if success then
  print(fn())
else
  print("[!]", fn)
end