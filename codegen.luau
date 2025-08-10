--!strict
--!native
local error = require("./error")
local vm = require("./vm")
local node = require("./ast/node")
local literal = require("./ast/literal")
local unaryOp = require("./ast/unary-op")
local binaryOp = require("./ast/binary-op")
local syntax = require("./syntax")
local Visitor = require("./visitor")
local OpCode = require("./opcode")
local SyntaxKind = syntax.SyntaxKind
local SyntaxKindInverse = syntax.SyntaxKindInverse
local clone = table.clone
local insert = table.insert

local function zip<T>(a: { T }, b: { T }): { T }
  local result = clone(a)
  for _, v in b do
    insert(result, v)
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

function CodeGen.visit(self: CodeGen, node: node.Node): (Bytecode, { vm.ConstantValue })
  local instructions = Visitor.visit(self, node)
  return instructions, self.constants
end

local syntaxOpMap = {
  [SyntaxKind.Bang] = OpCode.NOT,
  [SyntaxKind.Minus] = OpCode.NEGATE
}

function CodeGen.visitUnaryOpExpression(self: CodeGen, node: unaryOp.UnaryOp): Bytecode
  local operator = node.operator.kind
  local opcode = syntaxOpMap[operator]
  if not opcode then
    error("unsupported unary operator: " .. SyntaxKindInverse[operator])
  end

  local register = self:_allocRegister()
  self:_freeRegister()

  local operandBytecode = self:visit(node.operand)
  local instruction: vm.Instruction = { opcode = opcode, A = register, B = register }
  return zip(operandBytecode, { instruction })
end

function CodeGen.visitLiteralExpression(self: CodeGen, node: literal.Literal): Bytecode
  local value = node.token.value
  local register = self:_allocRegister()
  if type(value) == "number" then
    return { {opcode = OpCode.LOADN, A = register, B = value } }
  elseif type(value) == "nil" then
    return { {opcode = OpCode.LOADNIL, A = register } }
  end

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