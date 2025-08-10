--!strict
--!native
local error = require("./error")

type function negate(ty)
  return types.negationof(ty)
end

local function assert<T>(condition: T, message: string?): T & negate<false?>
  if condition then
    return nil :: any
  end
  error(message or "assertion failed!")
  return nil :: any
end

return assert