--!strict
--!native
local meta = require("./meta")
local node = require("./node")

export type Expression = node.Node & {

}

local function expression(): Expression
  return setmetatable({}, meta.Expression)
end

return expression