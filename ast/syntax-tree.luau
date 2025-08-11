--!strict
--!native
local meta = require("./meta")
local statement = require("./statement")

local SyntaxTree = setmetatable({ name = "SyntaxTree" }, meta.Statement)
export type SyntaxTree = statement.Statement & {
  read statements: { statement.Statement };
}

local function syntaxTree(statements: { statement.Statement }): SyntaxTree
  return setmetatable({ statements = statements }, SyntaxTree)
end

return syntaxTree