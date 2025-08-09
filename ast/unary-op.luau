--!strict
--!native
local expression = require("./expression")
local token = require("../token")
local util = require("../util-types")

local UnaryOp = {}
export type UnaryOp = expression.Expression & {
  read operand: expression.Expression;
  read operator: token.Token;
}

local function unaryOp(operand: expression.Expression, operator: token.Token): UnaryOp
  local node = expression() :: util.writable<UnaryOp>
  node.operand = operand
  node.operator = operator

  return setmetatable(node, UnaryOp) :: any
end

return unaryOp