--!strict
--!native
local meta = require("./meta")
local expression = require("./expression")
local statement = require("./statement")
local typeRef = require("./type-ref")
local token = require("../token")

local VarDeclaration = setmetatable({ name = "VarDeclaration" }, meta.Statement)
export type VarDeclaration = statement.Statement & {
  read letKeyword: token.Token;
  read name: token.Token;
  read type: typeRef.TypeRef?;
  read initializer: expression.Expression?;
}

local function varDeclaration(
  letKeyword: token.Token,
  name: token.Token,
  type: typeRef.TypeRef?,
  initializer: expression.Expression?
): VarDeclaration
  return setmetatable({
    letKeyword = letKeyword,
    name = name,
    type = type,
    initializer = initializer
  }, VarDeclaration)
end

return varDeclaration