--!strict
--!native
export type OpCode = number -- for hinting

local OpCode = {
  NOOP = 0,
  LOADN = 1,
  LOADK = 2,
  LOADNIL = 3,
}
table.freeze(OpCode)

return OpCode