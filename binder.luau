--!strict
--!native
local node = require("./ast/node")
local literal = require("./ast/literal")
local unaryOp = require("./ast/unary-op")
local binaryOp = require("./ast/binary-op")
local symbol = require("./symbol")
local syntax = require("./syntax")
local Visitor = require("./visitor")
local SyntaxKind = syntax.SyntaxKind

local Binder = setmetatable({}, Visitor)
Binder.__index = Binder

type Symbol = symbol.Symbol
export type function Bound(ty)
  if not ty:is("table") then
    local intersection = ty:is("intersection")
    if intersection or ty:is("union") then
      local all: { type } = {}
      for _, componentTy in ty:components() do
        table.insert(all, Bound(componentTy))
      end

      return if intersection then
        types.intersectionof(table.unpack(all))
      else
        types.unionof(table.unpack(all))
      end
      return ty
    end

  for prop, info in ty:properties() do
    if info.read then
      ty:setreadproperty(prop, Bound(info.read))
    end
    if info.write then
      ty:setwriteproperty(prop, Bound(info.write))
    end
  end

  return types.intersectionof(ty, types.newtable({
    [types.singleton("symbol")] = types.copy(Symbol)
  }))
end
export type Binder = typeof(Binder) & Visitor.Visitor<Bound<node.Node>> & {

}

local function bindSymbol<T>(node: T, name: string?, ty: string, isConstant: boolean?): Bound<T>
  local bound = node :: Bound<node.Node>
  bound.symbol = symbol(name, ty, isConstant)

  return bound :: any
end

function Binder.new(): Binder
  return setmetatable({}, Binder) :: any
end

function Binder.bind<T>(self: Binder, node: node.Node & T): Bound<T>
  return self:visit(node)
end

function Binder.visitLiteralExpression(self: Binder, node: Bound<literal.Literal>): Bound<literal.Literal>
  return bindSymbol(node, nil, type(node.token.value), true)
end

function Binder.visitUnaryOpExpression(self: Binder, node: Bound<unaryOp.UnaryOp>): Bound<unaryOp.UnaryOp>
  local operand = self:bind(node.operand)
  local resultType = if node.operator.kind == SyntaxKind.Minus then "number" else "boolean"
  if not operand.symbol then
    return node
  end

  return bindSymbol(node, nil, resultType, operand.symbol.isConstant)
end

function Binder.visitBinaryOpExpression(self: Binder, node: Bound<binaryOp.BinaryOp>): Bound<binaryOp.BinaryOp>
  local left = self:bind(node.left)
  if not left.symbol then
    return node
  end
  local right = self:bind(node.right)
  if not right.symbol then
    return node
  end
  local resultType = "number"
  if node.operator.kind == SyntaxKind.Plus and (left.symbol.type == "string" or right.symbol.type == "string") then
    resultType = "string"
  end

  return bindSymbol(node, nil, resultType, left.symbol.isConstant and right.symbol.isConstant)
end

return Binder