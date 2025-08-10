--!strict
--!native
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

local ROP_NOOP = 0
local ROP_LOADN = 1
local ROP_RETURN = 2

local function pop(state: VmState, register: number): Value
  local value = state.memory[register]
  state.memory[register] = nil
  return value
end

local function pushConstant(state: VmState, register: number, constant: ConstantValue): ()
  state.memory[register] = constant
end

local function execute(state: VmState, instruction: Instruction, returnOutput: (Value) -> ()): ()
  local op = instruction.opcode
  local register = instruction.A

  if op == ROP_NOOP then
    -- do nothing
  elseif op == ROP_LOADN then
    local value = instruction.B
    pushConstant(state, register, value)
  elseif op == ROP_RETURN then
    local value = pop(state, register)
    returnOutput(value)
  end
end

local function run(instructions: { Instruction }): Value
  local count = #instructions
  local state: VmState = {
    count = count,
    memory = {},
    ip = 1
  }

  local active = true
  local returnValue: Value
  local function returnOutput(value: Value): ()
    returnValue = value
    active = false
  end

  while active and state.ip <= count do
    local instruction = instructions[state.ip]
    execute(state, instruction, returnOutput)
    state.ip += 1
  end
  return returnValue
end

return {
  run = run
}