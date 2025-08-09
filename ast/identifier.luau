--!strict
--!native
local expression = require("./expression")
local token = require("../token")
local util = require("../util-types")

local Identifier = {}
export type Identifier = expression.Expression & {
  read token: token.Token;
}

local function identifier(token: token.Token): Identifier
  local node = expression() :: util.writable<Identifier>
  node.token = token

  return setmetatable(node, Identifier) :: any
end

return identifier