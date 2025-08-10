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
  MOD = 11,
  ADDK = 12,
  SUBK = 13,
  MULK = 14,
  DIVK = 15,
  POWK = 16,
  MODK = 17
}
table.freeze(OpCode)

type OpName = keyof<typeof(OpCode)>

local OpCodeInverse: { [number]: OpName } = {}
for k, v in OpCode :: { [OpName]: OpCode } do
  OpCodeInverse[v] = k
end
table.freeze(OpCodeInverse)

return {
  OpCode = OpCode,
  OpCodeInverse = OpCodeInverse
}