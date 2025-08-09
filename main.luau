local fs = require("@lune/fs") :: fs
local process = require("@lune/process") :: process
local tokenize = require("./lexer")
local try = require("./try")

local path = process.args[1]
local source = try(fs.readFile, path)
local tokens = tokenize(source)
print(tokens)