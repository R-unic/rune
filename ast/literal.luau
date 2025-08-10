--!strict
--!native
local meta = require("./meta")
local expression = require("./expression")
local token = require("../token")

local Literal = setmetatable({ name = "Literal" }, meta.Expression)
export type Literal = expression.Expression & {
  read token: token.Token;
}

local function literal(token: token.Token): Literal
  return setmetatable({ token = token }, Literal)
end

return literal