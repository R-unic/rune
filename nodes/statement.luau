local meta = require("./meta")

export type Statement = {

}

local function statement(): Statement
  return setmetatable({}, meta.Statement)
end

return statement