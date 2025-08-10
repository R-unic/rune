--!strict
--!native
local assert = require("./assert")
local OpCode = require("./opcode")

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
  read memory: { Value };
  ip: number;
}

local function pop(state: VmState, register: number, replacer: ((Value) -> Value)?): Value
  replacer = replacer or function(): Value return nil end
  local value = state.memory[register]
  state.memory[register] = replacer(value)
  return value
end

local function push(state: VmState, register: number, constant: Value): ()
  state.memory[register] = constant
end

local function execute(state: VmState, instruction: Instruction): ()
  local op = instruction.opcode
  local register = instruction.A

  if op == OpCode.NOOP then
    -- do nothing
  elseif op == OpCode.LOADN then
    local value = instruction.B
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
  end
end

local function run(instructions: { Instruction }): Value
  local count = #instructions
  local state: VmState = {
    count = count,
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