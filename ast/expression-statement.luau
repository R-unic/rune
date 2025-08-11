--!strict
--!native
local meta = require("./meta")
local expression = require("./expression")
local statement = require("./statement")

local ExpressionStatement = setmetatable({ name = "ExpressionStatement" }, meta.Statement)
export type ExpressionStatement = statement.Statement & {
  read expression: expression.Expression;
}

local function expressionStatement(expression: expression.Expression): ExpressionStatement
  return setmetatable({ expression = expression }, ExpressionStatement)
end

return expressionStatement