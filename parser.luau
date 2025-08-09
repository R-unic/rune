--!strict
--!native
local syntax = require("./syntax")
local token = require("./token")
local error = require("./error")
local node = require("./ast/node")
local expression = require("./ast/expression")
local statement = require("./ast/statement")
local literal = require("./ast/literal")
local identifier = require("./ast/identifier")
local unaryOp = require("./ast/unary-op")
local binaryOp = require("./ast/binary-op")
local SyntaxKind = syntax.SyntaxKind
local SyntaxKindInverse = syntax.SyntaxKindInverse

type ParseFunction = (ParseState) -> expression.Expression
type ParseState = {
  read tokens: { token.Token };
  read tokensLength: number;
  position: number;
}

local function peek(state: ParseState, offset: number): token.Token?
  return state.tokens[state.position + offset]
end

local function getCurrent(state: ParseState): token.Token
  return peek(state, 0) :: any
end

local function getPrevious(state: ParseState): token.Token
  return peek(state, -1) :: any
end

local function isEOF(state: ParseState): boolean
  return state.position > state.tokensLength
end

local function advance(state: ParseState): token.Token?
  local current = getCurrent(state)
  state.position += 1
  return current
end

local function match(state: ParseState, ...: syntax.SyntaxKind): boolean
  local kinds = {...}
  local current = getCurrent(state)
  local isMatch = false
  for _, kind in kinds do
    isMatch = isMatch or (current ~= nil and current.kind == kind)
  end

  if isMatch then
    advance(state)
  end

  return isMatch
end

local literalKinds = {
  [SyntaxKind.IntLiteral] = true,
  [SyntaxKind.FloatLiteral] = true,
  [SyntaxKind.BoolLiteral] = true,
  [SyntaxKind.StringLiteral] = true
}

local function parsePrimary(state: ParseState): expression.Expression
  local token = advance(state)
  if not token then
    return error("no next token")
  end

  local kind = token.kind
  if literalKinds[kind] then
    return literal(token)
  elseif kind == SyntaxKind.Identifier then
    return identifier(token)
  end

  return error(`unexpected token: {SyntaxKindInverse[kind]}`)
end

local function parseUnary(state: ParseState): expression.Expression
  if match(state, SyntaxKind.Bang, SyntaxKind.Minus) then
    local operator = getPrevious(state)
    local operand = parseUnary(state)
    return unaryOp(operand, operator)
  end

  return parsePrimary(state)
end

local function createBinaryOpParser(
  parseOperand: ParseFunction,
  ...: syntax.SyntaxKind
): ParseFunction
  local kinds = {...}
  return function(state: ParseState): expression.Expression
    local left = parseOperand(state)
    while match(state, table.unpack(kinds)) do
      local operator = getPrevious(state)
      local right = parseOperand(state)
      left = binaryOp(left, operator, right)
    end

    return left
  end
end

local parseExponentation = createBinaryOpParser(parseUnary, SyntaxKind.Carat)
local parseMultiplication = createBinaryOpParser(parseExponentation, SyntaxKind.Star, SyntaxKind.Slash)
local parseAddition = createBinaryOpParser(parseMultiplication, SyntaxKind.Plus, SyntaxKind.Minus)
local parseComparison = createBinaryOpParser(parseAddition, SyntaxKind.EqualsEquals, SyntaxKind.BangEquals, SyntaxKind.LArrow, SyntaxKind.RArrow, SyntaxKind.LTE, SyntaxKind.GTE)
local parseAnd = createBinaryOpParser(parseComparison, SyntaxKind.Ampersand)
local parseOr = createBinaryOpParser(parseAnd, SyntaxKind.Pipe)

local function parseExpression(state: ParseState): expression.Expression
  return parseOr(state)
end

local function parse(tokens: { token.Token }): node.Node
  local state: ParseState = {
    tokens = tokens,
    tokensLength = #tokens,
    position = 1
  }

  return parseExpression(state)
end

return parse