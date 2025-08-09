--!strict
--!native
local expression = require("./expression")
local token = require("../token")
local util = require("../util-types")

local Literal = {}
export type Literal = expression.Expression & {
  read token: token.Token;
}

local function literal(token: token.Token): Literal
  local node = expression() :: util.writable<Literal>
  node.token = token

  return setmetatable(node, Literal) :: any
end

return literal