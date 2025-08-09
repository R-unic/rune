--!strict
--!native
local expression = require("./expression")
local token = require("../token")
local util = require("../util-types")

local Literal = {}
export type Literal = {
  read token: token.Token;
}

local function literal(token: token.Token): Literal
  local node = setmetatable(expression(), Literal) :: util.writable<Literal>
  node.token = token

  return node
end

return literal