--!strict
--!native
local syntax = require("./syntax")
local SyntaxKindInverse = syntax.SyntaxKindInverse

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

local tokenMeta = {}
function tokenMeta.__tostring(token: Token): string
  local valueString = if token.value ~= nil then ", " .. tostring(token.value) else ""
  return `Token({SyntaxKindInverse[token.kind]}, '{token.lexeme}', {token.span}{valueString})`
end

local locationMeta = {}
function locationMeta.__tostring(location: Location): string
  return `{location.line}:{location.column}`
end

local locationSpanMeta = {}
function locationSpanMeta.__tostring(span: LocationSpan): string
  return `{span.start}-{span.finish}`
end

local function createToken(kind: syntax.SyntaxKind, span: LocationSpan, lexeme: string, value: TokenValue?): Token
  return setmetatable({
    kind = kind,
    value = value,
    span = span,
    lexeme = lexeme
  }, tokenMeta)
end

local function createLocation(line: number, column: number, position: number): Location
  return setmetatable({
    line = line,
    column = column,
    position = position
  }, locationMeta)
end

local function createLocationSpan(start: Location, finish: Location): LocationSpan
  return setmetatable({
    start = start,
    finish = finish
  }, locationSpanMeta)
end

return {
  createToken = createToken,
  createLocation = createLocation,
  createLocationSpan = createLocationSpan
}