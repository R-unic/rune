--!strict
--!native
local node = require("./ast/node")
local astMeta = require("./ast/meta")
local isExpression = astMeta.isExpression

local Visitor = {}
Visitor.__index = Visitor

export type Visitor<T...> = setmetatable<{}, typeof(Visitor)>

function Visitor.new<T...>(): Visitor<T...>
  return setmetatable({}, Visitor)
end

function Visitor.visit<T...>(self: Visitor<T...>, node: node.Node): T...
  local kind = if isExpression(node) then
    "Expression"
  else
    "Statement"

  local nodeMeta = (getmetatable(node) :: any) :: { name: string }
  local functionName = `visit{nodeMeta.name}{kind}`
  local f = (self :: { [string]: (...unknown) -> T... })[functionName]
  if not f then
    return nil :: any
  end
  return f(self, node)
end

return Visitor -- hopefully the only class