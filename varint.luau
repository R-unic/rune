local char = string.char
local bor = bit32.bor
local band = bit32.band
local lshift = bit32.lshift
local rshift = bit32.rshift

local function encode(n: number): string
  local bytes: { number } = {}
  repeat
    local byte = bor(band(n, 0x7F), lshift(if n > 0x7F then 1 else 0, 7))
    n = rshift(n, 7)

    table.insert(bytes, char(byte))
  until n == 0

  return table.concat(bytes)
end

local function decode(data: string, offset: number?): (number, number)
  offset = offset or 1 -- Lua strings are 1-indexed
  local result = 0
  local shift = 0
  local pos = offset

  while true do
    local byte = string.byte(data, pos)
    pos += 1
    result += lshift(band(byte, 0x7F), shift) -- take the low 7 bits

    if band(byte, 0x80) == 0 then break end
    shift += 7
  end

  return result, pos
end

return {
  encode = encode,
  decode = decode
}