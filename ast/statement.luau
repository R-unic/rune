--!strict
--!native
local meta = require("./meta")
local node = require("./node")

export type Statement = node.Node & {

}

local function statement(): Statement
  return setmetatable({}, meta.Statement)
end

return statement