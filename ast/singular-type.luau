--!strict
--!native
local meta = require("./meta")
local typeRef = require("./type-ref")
local token = require("../token")

local SingularType = setmetatable({ name = "SingularType" }, meta.TypeRef)
export type SingularType = typeRef.TypeRef & {
  read name: token.Token;
}

local function singularType(name: token.Token): SingularType
  return setmetatable({ name = name }, SingularType)
end

return singularType