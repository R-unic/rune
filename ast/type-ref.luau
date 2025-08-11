--!strict
--!native
local meta = require("./meta")
local node = require("./node")

export type TypeRef = node.Node & {

}

local function typeRef(): TypeRef
  return setmetatable({}, meta.TypeRef)
end

return typeRef