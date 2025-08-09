local meta = require("./meta")

export type Expression = {

}

local function expression(): Expression
  return setmetatable({}, meta.Expression)
end

return expression