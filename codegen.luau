--!strict
--!native
local vm = require("./vm")
local node = require("./ast/node")
local literal = require("./ast/literal")
local binaryOp = require("./ast/binary-op")
local OpCode = require("./opcode")
local Visitor = require("./visitor")
-- local literal = require("./ast/literal")

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

function CodeGen.visitBinaryOpExpression(self: CodeGen, node: binaryOp.BinaryOp): Bytecode
  return {  }
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
  table.insert(self.constants, constant)
  return index
end

function CodeGen._allocRegister(self: CodeGen): number
  local register = self.nextAvailableRegister
  self.nextAvailableRegister = math.min(self.nextAvailableRegister + 1, MAX_REGISTER)
  return register
end

function CodeGen._freeRegister(self: CodeGen): ()
  self.nextAvailableRegister = math.max(self.nextAvailableRegister - 1, 0)
end

return CodeGen