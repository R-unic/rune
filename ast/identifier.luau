--!strict
--!native
local meta = require("./meta")
local expression = require("./expression")
local token = require("../token")

local Identifier = setmetatable({ name = "Identifier" }, meta.Expression)
export type Identifier = expression.Expression & {
  read token: token.Token;
}

local function identifier(token: token.Token): Identifier
  return setmetatable({ token = token }, Identifier)
end

return identifier