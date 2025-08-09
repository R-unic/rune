--!strict
--!native
local fs = require("@lune/fs") :: fs
local process = require("@lune/process") :: process
local tokenize = require("./lexer")
local parse = require("./parser")
local try = require("./try")

local path = process.args[1]
local source = try(fs.readFile, path)
local tokens = tokenize(source)
local ast = parse(tokens)
print(ast)