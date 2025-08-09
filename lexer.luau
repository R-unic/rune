--!strict
--!native
local process = require("@lune/process") :: process
local syntax = require("./syntax")
local SyntaxKind = syntax.SyntaxKind
local SyntaxKindInverse = syntax.SyntaxKindInverse
local unpack = table.unpack

export type Location = {
  read line: number;
  read column: number;
  read position: number;
}

export type LocationSpan = {
  read start: Location;
  read finish: Location;
}

export type TokenValue = string | boolean | number | nil
export type Token = {
  read kind: syntax.SyntaxKind;
  read lexeme: string;
  read span: LocationSpan;
  read value: TokenValue?;
}

export type LexerState = {
  read source: { number };
  read sourceLength: number;
  read tokens: { Token };
  line: number;
  column: number;
  position: number;
  lexemeStartLocation: Location;
}

local function error(message: string): never
  print("[!]", message)
  return process.exit(1)
end

local function isAlphabetic(char: number): boolean
  local matchesUppercase = char >= 65 and char <= 90
  local matchesLowercase = char >= 97 and char <= 122
  return matchesUppercase or matchesLowercase
end

local function isNumeric(char: number): boolean
  return char >= 48 and char <= 57
end

local function isAlphanumeric(char: number): boolean
  return isAlphabetic(char) or isNumeric(char)
end

local function isLineFeed(char: number): boolean
  return char == 10
end

local function isCarriageReturn(char: number): boolean
  return char == 13
end

local function isWhitespace(char: number, carriageReturnIncluded: boolean?): boolean
  return char == 32 or char == 9 or isLineFeed(char) or isCarriageReturn(char)
end

local function isEOF(state: LexerState, position: number?): boolean
  position = position or state.position
  return position > state.sourceLength
end

local function getCharacter(state: LexerState, offset: number?): number
  offset = offset or 0

  local position = state.position
  if isEOF(state, position) then
    error(`attempt to get character out of bounds\nposition: {position}`)
  end

  return state.source[position + offset]
end

local locationMeta = {}
function locationMeta.__tostring(location: Location): string
  return `{location.line}:{location.column}`
end

local function getLocation(state: LexerState): Location
  return setmetatable({
    line = state.line,
    column = state.column,
    position = state.position
  }, locationMeta)
end

local function advance(state: LexerState): number?
  state.position += 1
  state.column += 1

  return if isEOF(state) then nil else getCharacter(state)
end

local function match(state: LexerState, char: string): boolean
  local isMatch = char == string.char(getCharacter(state))
  if isMatch then
    advance(state)
  end
  return isMatch
end

local function getCurrentLexeme(state: LexerState): string
  local lexemeBytes: { number } = {}
  for i = state.lexemeStartLocation.position, state.position - 1 do
    table.insert(lexemeBytes, state.source[i])
  end

  return string.char(unpack(lexemeBytes))
end

local tokenMeta = {}
function tokenMeta.__tostring(token: Token): string
  local valueString = if token.value ~= nil then ", " .. tostring(token.value) else ""
  return `Token({SyntaxKindInverse[token.kind]}, '{token.lexeme}', {token.span}{valueString})`
end

local locationSpanMeta = {}
function locationSpanMeta.__tostring(span: LocationSpan): string
  return `{span.start}-{span.finish}`
end

local function addToken(state: LexerState, kind: syntax.SyntaxKind, value: TokenValue?): ()
  local lexeme = getCurrentLexeme(state)
  local finishLocation = getLocation(state)
  local span: LocationSpan = setmetatable({
    start = state.lexemeStartLocation,
    finish = finishLocation
  }, locationSpanMeta)
  local token: Token = setmetatable({
    kind = kind,
    value = value,
    span = span,
    lexeme = lexeme
  }, tokenMeta)

  table.insert(state.tokens, token)
  state.lexemeStartLocation = finishLocation
end

local function skipNewLines(state: LexerState): ()
  state.line += 1

  local current = getCharacter(state)
  while isLineFeed(current) or isCarriageReturn(current) do
    local isNewLine = isLineFeed(current)

    state.position += 1
    if isNewLine then
      state.line += 1
    end
    current = getCharacter(state)
  end

  state.column = 0
  state.lexemeStartLocation = getLocation(state)
  -- TODO: trivia tokens?
end

local function skipWhitespace(state: LexerState): ()
  if not isEOF(state) then
    local current = getCharacter(state)
    while not isEOF(state) and isWhitespace(current) and not isLineFeed(current) do
      current = advance(state)
      if not current then break end
    end
  end

  state.lexemeStartLocation = getLocation(state)
end

local function readIdentifier(state: LexerState): ()
  if not isEOF(state) then
    local current = getCharacter(state)
    while not isEOF(state) and isAlphanumeric(current) or string.char(current) == "_" do
      current = advance(state)
      if not current then break end
    end
  end

  local kind = SyntaxKind.Identifier
  local value: TokenValue?
  local lexeme = getCurrentLexeme(state)
  if lexeme == "true" or lexeme == "false" then
    kind = SyntaxKind.BoolLiteral
    value = lexeme == "true"
  end

  addToken(state, kind, value)
end

local function readNumber(state: LexerState): ()
  local usedDecimal = false
  if not isEOF(state) then
    local current = getCharacter(state)
    while not isEOF(state) and isNumeric(current) or string.char(current) == "." do
      if string.char(current) == "." then
        if usedDecimal then
          error("malformed number")
        end
        usedDecimal = true
      end
      current = advance(state)
      if not current then break end
    end
  end

  local kind = if usedDecimal then
    SyntaxKind.FloatLiteral
  else
    SyntaxKind.IntLiteral

  local lexeme = getCurrentLexeme(state)
  addToken(state, kind, tonumber(lexeme))
end

local function readString(state: LexerState, terminator: number): ()
  if not isEOF(state) then
    local current = getCharacter(state)
    while not isEOF(state) and current ~= terminator do
      current = advance(state)
      if not current then break end
    end
    advance(state)
  end

  local lexeme = getCurrentLexeme(state)
  local value = string.sub(lexeme, 2, string.len(lexeme) - 1)
  addToken(state, SyntaxKind.StringLiteral, value)
end

local singleCharMap = {
  ["?"] = SyntaxKind.Question,
  [","] = SyntaxKind.Comma,
  ["."] = SyntaxKind.Dot,
  ["&"] = SyntaxKind.Ampersand,
  ["|"] = SyntaxKind.Pipe,
  ["("] = SyntaxKind.LParen,
  [")"] = SyntaxKind.RParen,
  ["["] = SyntaxKind.LBracket,
  ["]"] = SyntaxKind.RBracket,
  ["{"] = SyntaxKind.LBrace,
  ["}"] = SyntaxKind.RBrace
}

local function lex(state: LexerState): ()
  local byte = getCharacter(state)
  local char = string.char(byte)
  advance(state)

  if char == "+" then
    local kind = SyntaxKind.Plus
    if match(state, "+") then
      kind = SyntaxKind.PlusPlus
    elseif match(state, "=") then
      kind = SyntaxKind.PlusEquals
    end
    addToken(state, kind)
  elseif char == "-" then
    local kind = SyntaxKind.Minus
    if match(state, "-") then
      kind = SyntaxKind.MinusMinus
    elseif match(state, "=") then
      kind = SyntaxKind.MinusEquals
    end
    addToken(state, kind)
  elseif char == "*" then
    local kind = SyntaxKind.Star
    if match(state, "=") then
      kind = SyntaxKind.StarEquals
    end
    addToken(state, kind)
  elseif char == "/" then
    local kind = SyntaxKind.Slash
    if match(state, "=") then
      kind = SyntaxKind.SlashEquals
    end
    addToken(state, kind)
  elseif char == "<" then
    local kind = SyntaxKind.LArrow
    if match(state, "=") then
      kind = SyntaxKind.LTE
    end
    addToken(state, kind)
  elseif char == ">" then
    local kind = SyntaxKind.RArrow
    if match(state, "=") then
      kind = SyntaxKind.GTE
    end
    addToken(state, kind)
  elseif char == "\r" then
    lex(state)
  elseif char == "\n" then
    skipNewLines(state)
  elseif char == "'" or char == '"' then
    readString(state, byte)
  elseif isNumeric(byte) then
    readNumber(state)
  elseif isAlphabetic(byte) or char == "_" then
    readIdentifier(state)
  elseif isWhitespace(byte) then
    skipWhitespace(state)
  else
    local kind = singleCharMap[string.char(byte)]
    if kind ~= nil then
      return addToken(state, kind)
    end

    error(`unexpected character: {char}`)
  end
end

local function tokenize(source: string): { Token }
  local sourceLength = #source
  local sourceBytes = table.pack(string.byte(source, 1, sourceLength))
  local tokens = {}
  local state: LexerState = {
    source = sourceBytes,
    sourceLength = sourceLength,
    tokens = tokens,
    line = 1,
    column = 0,
    position = 1,
    lexemeStartLocation = {} :: Location
  }

  state.lexemeStartLocation = getLocation(state)
  while not isEOF(state) do
    lex(state)
  end

  return tokens
end

return tokenize