--!strict
--!native
local meta = require("./meta")
local expression = require("./expression")
local token = require("../token")

local BinaryOp = setmetatable({ name = "BinaryOp" }, meta.Expression)
export type BinaryOp = expression.Expression & {
  read left: expression.Expression;
  read operator: token.Token;
  read right: expression.Expression;
}

local function binaryOp(left: expression.Expression, operator: token.Token, right: expression.Expression): BinaryOp
  return setmetatable({
    left = left,
    operator = operator,
    right = right,
  }, BinaryOp)
end

return binaryOp