--!strict
--!native
local fs = require("@lune/fs") :: fs
local process = require("@lune/process") :: process
local luau = require("@lune/luau") :: luau
local varint = require("./varint")
local tokenize = require("./lexer")
local parse = require("./parser")
local codegen = require("./codegen")
local vm = require("./vm")
local try = require("./try")

local path = process.args[1]
local source = try(fs.readFile, path)
local tokens = tokenize(source)
local ast = parse(tokens)
local bytecode = codegen(ast)
local result = vm.run(bytecode)
print(result)