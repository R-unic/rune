--!strict
--!native
local assert = require("./assert")
local error = require("./error")
local op = require("./opcode")
local OpCode = op.OpCode
local OpCodeInverse = op.OpCodeInverse

export type Instruction = {
  read opcode: number;
  read A: number;
  read B: number?;
  read C: number?;
}

export type ConstantValue = string | number | boolean | nil
export type Value = ConstantValue

type VmState = {
  read count: number;
  read constants: { ConstantValue };
  read memory: { Value };
  ip: number;
}

local function keys<K, V>(t: { [K]: V }): { K }
  local result: { K } = {}
  for k in t do
    table.insert(result, k)
  end
  return result
end

local function pop(state: VmState, register: number, replacer: ((Value) -> Value)?): Value
  replacer = replacer or function(): Value return nil end
  local value = state.memory[register]
  state.memory[register] = replacer(value)
  return value
end

local function push(state: VmState, register: number, constant: Value): ()
  state.memory[register] = constant
end

type BinaryOpInfo = {
  read acceptedTypes: { [string]: boolean };
  read execute: (Value, Value) -> Value;
}

local binaryOps: { [op.OpCode]: BinaryOpInfo } = {
  [OpCode.ADD] = {
    acceptedTypes = {
      number = true,
      string = true
    },
    execute = function(a, b): string | number
      if type(a) == "string" or type(b) == "string" then
        return tostring(a) .. tostring(b)
      end

      return a :: number + b :: number
    end
  },
  [OpCode.SUB] = {
    acceptedTypes = { number = true },
    execute = function(a, b): number
      return a :: number - b :: number
    end
  },
  [OpCode.MUL] = {
    acceptedTypes = { number = true },
    execute = function(a, b): number
      return a :: number * b :: number
    end
  },
  [OpCode.DIV] = {
    acceptedTypes = { number = true },
    execute = function(a, b): number
      return a :: number / b :: number
    end
  },
  [OpCode.POW] = {
    acceptedTypes = { number = true },
    execute = function(a, b): number
      return a :: number ^ b :: number
    end
  },
  [OpCode.MOD] = {
    acceptedTypes = { number = true },
    execute = function(a, b): number
      return a :: number % b :: number
    end
  }
}

local constantBinaryOps: { [op.OpCode]: BinaryOpInfo } = {}
for opcode, v in binaryOps do
  constantBinaryOps[2 * opcode - (opcode - OpCode.ADD)] = v
end

local function execute(state: VmState, instruction: Instruction): ()
  local op = instruction.opcode
  local register = instruction.A

  if op == OpCode.NOOP then
    -- do nothing
  elseif op == OpCode.LOADN then
    local value = instruction.B
    push(state, register, value)
  elseif op == OpCode.LOADK then
    local index = instruction.B :: number
    local value = state.constants[index + 1]
    push(state, register, value)
  elseif op == OpCode.NEGATE then
    local sourceRegister = instruction.B :: number
    local value = pop(state, sourceRegister) :: number
    assert(type(value) == "number", "expected operand value for NEGATE to be a number")

    push(state, register, -value)
  elseif op == OpCode.NOT then
    local sourceRegister = instruction.B :: number
    local value = pop(state, sourceRegister)

    push(state, register, not value)
  else
    local binaryOp = binaryOps[op]
    if binaryOp then
      local leftRegister = instruction.B :: number
      local rightRegister = instruction.C :: number
      local left = pop(state, leftRegister)
      local right = pop(state, rightRegister)
      local acceptedTypes = binaryOp.acceptedTypes
      local acceptedTypeNames = table.concat(keys(acceptedTypes), ", ")
      assert(acceptedTypes[type(left)], "expected left value for " .. op .. " to be (" .. acceptedTypeNames .. "), got " .. type(left))
      assert(acceptedTypes[type(right)], "expected right value for " .. op .. " to be (" .. acceptedTypeNames .. "), got " .. type(right))

      local result = binaryOp.execute(left, right)
      return push(state, register, result)
    end

    local constantBinaryOp = constantBinaryOps[op]
    if constantBinaryOp then
      local leftRegister = instruction.B :: number
      local constantIndex = instruction.C :: number
      local left = pop(state, leftRegister)
      local right = state.constants[constantIndex + 1]
      local acceptedTypes = constantBinaryOp.acceptedTypes
      local acceptedTypeNames = table.concat(keys(acceptedTypes), ", ")
      assert(acceptedTypes[type(left)], "expected left value for " .. op .. " to be (" .. acceptedTypeNames .. "), got " .. type(left))
      assert(acceptedTypes[type(right)], "expected right value for " .. op .. " to be (" .. acceptedTypeNames .. "), got " .. type(right))

      local result = constantBinaryOp.execute(left, right)
      return push(state, register, result)
    end

    error("unhandled opcode: " .. OpCodeInverse[op])
  end
end

local function run(instructions: { Instruction }, constants: { ConstantValue }): Value
  local count = #instructions
  local state: VmState = {
    count = count,
    constants = constants,
    memory = {},
    ip = 1
  }

  while state.ip <= count do
    local instruction = instructions[state.ip]
    execute(state, instruction)
    state.ip += 1
  end

  return state.memory[#state.memory]
end

return {
  run = run
}