--!strict
--!native
local error = require("./error")

local function assert(condition: unknown, message: string?): ()
  if condition then return end
  error(message or "assertion failed!")
end

return assert