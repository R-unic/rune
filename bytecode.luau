--!strict
--!native
local error = require("./error")
local varint = require("./varint")
local pack = string.pack
local char = string.char
local join = table.concat
local bor = bit32.bor
local lshift = bit32.lshift
local rshift = bit32.rshift
local log = math.log
local floor = math.floor
local min = math.min
local max = math.max

export type LuauConstant = number | boolean | string | nil
export type Instruction ={
  read op: number;
  read A: number;
  read B: number?;
  read C: number?;
  read Bx: number?;
}

local function packInstruction(op: number, A: number, B: number?, C: number?, Bx: number?): string
  if Bx then
    -- ABx format: Bx goes in lower 16 bits (B + C combined)
    local instruction = bor(op, lshift(A, 8), lshift(Bx , 16))
    return pack("<I4", instruction)
  else
    -- ABC format
    local instruction = bor(op, lshift(A, 8), lshift(B or 0, 16), lshift(C or 0, 24))
    return pack("<I4", instruction)
  end
end

local function packInstructionObject(instruction: Instruction): string
  return packInstruction(instruction.op, instruction.A, instruction.B, instruction.C, instruction.Bx)
end

local function packConstant(value: LuauConstant): string
  local ty = typeof(value)
  if ty == "number" then
    return char(3) .. pack("<d", value)
  elseif ty == "boolean" then
    return char(1) .. if value then "\1" else "\0"
  elseif ty == "nil" then
    return char(0)
  elseif typeof(value) == "string" then
    return char(4) .. pack("<I4", string.len(value)) .. value .. "\0"
  else
    return error(`unsupported constant type: {ty}`)
  end
end

local function createHeader(): string
  -- Signature 4 bytes ("Luau")
  -- Version: 4 bytes (1)
  -- Flags: 4 bytes (0)
  local version = pack("<I4", 1)
  local flags = pack("<I4", 0)
  return "Luau" .. version .. flags
end

-- Op-codes that use B and C fields instead of Bx, but use them for things other than register indices
local opsIgnoreBC = {
  [22] = true -- LOP_RETURN
}

local function computeMaxStackSize(instructions: { Instruction }): number
  local maxRegisters = 0
  for _, instruction in instructions do
      local A = instruction.A or 0
      if A > maxRegisters then
        maxRegisters = A
      end

      if instruction.Bx then continue end -- If ABx format, ignore C
      if opsIgnoreBC[instruction.op] then continue end -- ignore B and C

      local B = instruction.B or 0
      local C = instruction.C or 0
      if B > maxRegisters then
        maxRegisters = B
      end
      if C > maxRegisters then
        maxRegisters = C
      end
  end

  return maxRegisters + 1
end

local function processLines(lines: { number }): ({ number }, number)
  -- First pass: adjust span if line deltas exceed 255
  local span = lshift(1, 24)
  local offset = 1
  local count = #lines
  while offset <= count do
    local nextIndex = offset
    local minVal = lines[offset]
    local maxVal = lines[offset]

    while nextIndex <= count and nextIndex < offset + span do
      minVal = min(minVal, lines[nextIndex])
      maxVal = max(maxVal, lines[nextIndex])

      if maxVal - minVal > 255 then break end

      nextIndex += 1
    end

    if nextIndex <= count and (nextIndex - offset) < span then
      -- shrink span to largest power-of-two <= (nextIndex - offset)
      local newSpan = lshift(1, floor(log(nextIndex - offset) / log(2)))
      span = newSpan
    else
      offset += span
    end
  end

  -- Second pass: compute baseline
  local baselineSize = floor((count - 1) / span) + 1
  local baseline = table.create(baselineSize, 0) -- pre-fill with 0

  local baselineIndex = 1
  offset = 1
  while offset <= count do
    local nextIndex = offset
    local minVal = lines[offset]

    while nextIndex <= count and nextIndex < offset + span do
      minVal = min(minVal, lines[nextIndex])
      nextIndex += 1
    end

    baseline[baselineIndex] = minVal
    baselineIndex += 1
    offset += span
  end

  -- Third pass: compute logspan
  local logspan = floor(log(span) / log(2))
  return baseline, logspan
end

local function createPrototype(
  instructions: { Instruction },
  constants: { LuauConstant },
  parameterCount: number?,
  isVararg: number?
): string
  local instructionsBinary: { string } = {}
  local constantsBinary: { string } = {}
  for _, instruction in instructions do
    table.insert(instructionsBinary, packInstructionObject(instruction))
  end
  for _, constant in constants do
    table.insert(constantsBinary, packConstant(constant))
  end

  local maxStackSize = char(computeMaxStackSize(instructions) + 5)
  local nParameters = char(parameterCount or 0)
  local nUpvalues = char(0)
  local isVarargByte = char(isVararg or 0)
  local flags = char(1)
  local fullTypeInfoSize = varint.encode(1)
  local funcTypeInfoSize = varint.encode(0)
  local typedUpvalsSize = varint.encode(0)
  local typedLocalsSize = varint.encode(1)
  local localType = char(2)
  local localReg = char(0)
  local nInstructions = varint.encode(#instructions)
  local instructionsBlob = join(instructionsBinary)
  local nConstants = varint.encode(#constants)
  local constantsBlob = join(constantsBinary)
  local nChildPrototypes = varint.encode(0)
  local lineDefined = varint.encode(0)
  local name = varint.encode(0)
  local doLineInfo = true
  local doDebugInfo = false
  local hasLines = char(if doLineInfo then 1 else 0)
  local hasDebug = char(if doDebugInfo then 1 else 0)

  -- debug/line table: Luau expects a little blob here if hasLines is set.
  local lineNumbers: { number } = {}
  for i = 1, #instructions do
    table.insert(lineNumbers, 1) -- pretend every instr is line 1
  end
  local lineCount = #lineNumbers
  local success, baseLine, logSpan = pcall(processLines, lineNumbers)
  if not success then
    return error("failed to process lines: " .. tostring(baseLine))
  end

  local baseLine: { number } = baseLine
  local linesBinary: { string } = { char(logSpan) }
  local lastOffset = 0
  for i = 1, lineCount do
    local delta = lineNumbers[i] - baseLine[rshift(i - 1, logSpan) + 1]
    if not (delta >= 0 and delta <= 255) then
      error("delta out of one-byte range")
    end

    table.insert(linesBinary, char(delta - lastOffset))
    lastOffset = delta
  end

  local lastLine = 0
  for i = 1, #baseLine do
    local base = baseLine[i]
    table.insert(linesBinary, pack("<I4", base - lastLine))
    lastLine = base
  end
  local linesBlob = join(linesBinary)

  -- build debug blob: source name (varint + bytes), lines blob, maybe locals / upvalues sizes
  -- The exact layout is the same structure Luau writes when emitting debug info. Minimal safe choice:
  local debugLocals = varint.encode(0)
  local debugUpvals = varint.encode(0)
  local debugBlob = join({ debugLocals, debugUpvals })

  return join({
    maxStackSize, nParameters, nUpvalues, isVarargByte, flags,
    fullTypeInfoSize, funcTypeInfoSize, typedUpvalsSize, typedLocalsSize, localType, localReg,
    nInstructions, instructionsBlob,
    nConstants, constantsBlob,
    nChildPrototypes, lineDefined, name,
    hasLines, if doLineInfo then linesBlob else "",
    hasDebug, if doDebugInfo then debugBlob else ""
  })
end

local function createFile(
  instructions: { Instruction },
  constants: { LuauConstant },
  nParameters: number?,
  isVararg: number?
): string
  return join({
    createHeader(),
    createPrototype(instructions, constants, nParameters, isVararg)
  })
end

return {
  createFile = createFile,
  createProto = createPrototype
}