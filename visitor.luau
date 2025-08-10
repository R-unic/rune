--!strict
--!native
local node = require("./ast/node")
local literal = require("./ast/literal")
local binaryOp = require("./ast/binary-op")
local astMeta = require("./ast/meta")
local isExpression = astMeta.isExpression

local Visitor = {}
Visitor.__index = Visitor

export type Visitor<T> = setmetatable<{}, typeof(Visitor)>

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
  return self[functionName](self, node)
end

function Visitor.visitLiteralExpression<T...>(self: Visitor<T...>, node: literal.Literal): T...
  return nil
end

function Visitor.visitBinaryOpExpression<T...>(self: Visitor<T...>, node: binaryOp.BinaryOp): T...
  return nil
end

return Visitor -- hopefully the only class