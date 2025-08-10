--!strict
--!native
local meta = require("./meta")
local expression = require("./expression")
local token = require("../token")

local UnaryOp = setmetatable({ name = "UnaryOp" }, meta.Expression)
export type UnaryOp = expression.Expression & {
  read operand: expression.Expression;
  read operator: token.Token;
}

local function unaryOp(operand: expression.Expression, operator: token.Token): UnaryOp
  return setmetatable({
    operand = operand,
    operator = operator
  }, UnaryOp)
end

return unaryOp