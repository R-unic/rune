--!strict
--!native
export type OpCode = number -- for hinting

local OpCode = {
  NOOP = 0,
  LOADN = 1,
  LOADK = 2,
  LOADNIL = 3,
  NOT = 4,
  NEGATE = 5,
  ADD = 6,
  SUB = 7,
  MUL = 8,
  DIV = 9,
  POW = 10,
  MOD = 11
}
table.freeze(OpCode)

return OpCode