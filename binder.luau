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

export type Bound<T> = T & { symbol: symbol.Symbol }
export type Binder = typeof(Binder) & Visitor.Visitor<Bound<node.Node>> & {

}

local function bindSymbol<T>(node: T, name: string?, ty: string, isConstant: boolean?): Bound<T>
  local bound = node :: Bound<T>
  bound.symbol = symbol(name, ty, isConstant)
  return bound
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

  return bindSymbol(node, nil, resultType, operand.symbol.isConstant)
end

function Binder.visitBinaryOpExpression(self: Binder, node: Bound<binaryOp.BinaryOp>): Bound<binaryOp.BinaryOp>
  local left = self:bind(node.left)
  local right = self:bind(node.right)
  local resultType = "number"
  if node.operator.kind == SyntaxKind.Plus and (left.symbol.type == "string" or right.symbol.type == "string") then
    resultType = "string"
  end

  return bindSymbol(node, nil, resultType, left.symbol.isConstant and right.symbol.isConstant)
end

return Binder