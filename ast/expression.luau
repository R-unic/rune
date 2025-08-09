--!strict
--!native
local meta = require("./meta")
local node = require("./node")

export type Expression = node.Node & {

}

local function expression(): Expression
  return setmetatable(node(), meta.Expression)
end

return expression