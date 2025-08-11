--!strict
--!native
local meta = require("./meta")

export type Node = setmetatable<{}, typeof(meta.Node)>

local function node(): Node
  return setmetatable({}, meta.Node)
end

return node