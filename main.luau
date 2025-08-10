--!strict
--!native
local fs = require("@lune/fs") :: fs
local process = require("@lune/process") :: process
local tokenize = require("./lexer")
local parse = require("./parser")
local CodeGen = require("./codegen")
local vm = require("./vm")
local try = require("./try")

local path = process.args[1]
local source = try(fs.readFile, path)
local tokens = tokenize(source)
local ast = parse(tokens)
local codegen = CodeGen.new()
local bytecode, constants = codegen:generate(ast)
print("constants:", constants)
print("instructions:", bytecode)
local result = vm.run(bytecode, constants)
print(result)