--!strict
--!native
local error = require("./error")
local vm = require("./vm")
local node = require("./ast/node")
local literal = require("./ast/literal")
local unaryOp = require("./ast/unary-op")
local binaryOp = require("./ast/binary-op")
local syntax = require("./syntax")
local op = require("./opcode")
local Visitor = require("./visitor")
local OpCode = op.OpCode
local SyntaxKind = syntax.SyntaxKind
local SyntaxKindInverse = syntax.SyntaxKindInverse
local clone = table.clone
local insert = table.insert

local function zip<T>(a: { T }, ...: { T }): { T }
  local result = clone(a)
  for i = 1, select("#", ...) do
    local t = select(i, ...)
    for _, v in t do
      insert(result, v)
    end
  end
  return result
end

export type Bytecode = { vm.Instruction }

local CodeGen = setmetatable({}, Visitor)
CodeGen.__index = CodeGen

local MAX_REGISTER = 16

export type CodeGen = typeof(CodeGen) & {
  read constants: { vm.ConstantValue };
  nextAvailableRegister: number;
}

function CodeGen.new(): CodeGen
  return setmetatable({
    constants = {},
    nextAvailableRegister = 0
  }, CodeGen) :: any
end

function CodeGen.generate(self: CodeGen, node: node.Node): (Bytecode, { vm.ConstantValue })
  local instructions = Visitor.visit(self, node)
  return instructions, self.constants
end

local binarySyntaxOpMap = {
  [SyntaxKind.Plus] = OpCode.ADD,
  [SyntaxKind.Minus] = OpCode.SUB,
  [SyntaxKind.Star] = OpCode.MUL,
  [SyntaxKind.Slash] = OpCode.DIV,
  [SyntaxKind.Carat] = OpCode.POW,
  [SyntaxKind.Percent] = OpCode.MOD
}
function CodeGen.visitBinaryOpExpression(self: CodeGen, node: binaryOp.BinaryOp): Bytecode
  local operator = node.operator.kind
  local opcode = binarySyntaxOpMap[operator]
  if not opcode then
    error("unsupported binary operator: " .. SyntaxKindInverse[operator])
  end

  local left = self:visit(node.left)
  local register = self:_allocRegister()
  local right = self:visit(node.right)
  local c = register + 1
  local isConstant = (node.right :: literal.Literal).isConstant
  if isConstant then
    print("right is constant")
    opcode = 2 * opcode - (opcode - OpCode.ADD)
    c = #self.constants - 1
  end

  self:_freeRegister()
  local instruction: vm.Instruction = { opcode = opcode, A = register, B = register, C = c }
  return zip(left, if isConstant then {} else right, { instruction })
end

local unarySyntaxOpMap = {
  [SyntaxKind.Bang] = OpCode.NOT,
  [SyntaxKind.Minus] = OpCode.NEGATE
}
function CodeGen.visitUnaryOpExpression(self: CodeGen, node: unaryOp.UnaryOp): Bytecode
  local operator = node.operator.kind
  local opcode = unarySyntaxOpMap[operator]
  if not opcode then
    error("unsupported unary operator: " .. SyntaxKindInverse[operator])
  end

  local register = self:_allocRegister()
  self:_freeRegister()

  local operand = self:visit(node.operand)
  local instruction: vm.Instruction = { opcode = opcode, A = register, B = register }
  return zip(operand, { instruction })
end

function CodeGen.visitLiteralExpression(self: CodeGen, node: literal.Literal): Bytecode
  local value = node.token.value
  local register = self:_allocRegister()
  self:_freeRegister()

  local constantIndex = self:_pushConstant(value)
  return { {opcode = OpCode.LOADK, A = register, B = constantIndex} }
end

function CodeGen._pushConstant(self: CodeGen, constant: vm.ConstantValue): number
  local index = #self.constants
  insert(self.constants, constant)
  return index
end

function CodeGen._allocRegister(self: CodeGen): number
  local register = self.nextAvailableRegister
  self.nextAvailableRegister = math.min(self.nextAvailableRegister + 1, MAX_REGISTER)
  return register
end

function CodeGen._freeRegister(self: CodeGen, count: number?): ()
  count = count or 1
  self.nextAvailableRegister = math.max(self.nextAvailableRegister - count, 0)
end

return CodeGen