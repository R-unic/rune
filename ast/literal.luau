--!strict
--!native
local meta = require("./meta")
local expression = require("./expression")
local token = require("../token")

local Literal = setmetatable({ name = "Literal" }, meta.Expression)
export type Literal = expression.Expression & {
  read token: token.Token;
  read isConstant: boolean;
}

local function literal(token: token.Token): Literal
  return setmetatable({
    token = token,
    isConstant = true
  }, Literal)
end

return literal