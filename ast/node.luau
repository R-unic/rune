--!strict
--!native
local meta = require("./meta")

export type Node = {

}

local function node(): Node
  return setmetatable({}, meta.Node)
end

return node