--!strict
--!native
local expression = require("./expression")
local token = require("../token")
local util = require("../util-types")

local BinaryOp = {}
export type BinaryOp = expression.Expression & {
  read left: expression.Expression;
  read operator: token.Token;
  read right: expression.Expression;
}

local function binaryOp(left: expression.Expression, operator: token.Token, right: expression.Expression): BinaryOp
  local node = expression() :: util.writable<BinaryOp>
  node.left = left
  node.operator = operator
  node.right = right

  return setmetatable(node, BinaryOp) :: any
end

return binaryOp