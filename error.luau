--!strict
--!native
local process = require("@lune/process") :: process

local function error(message: string): never
  print("[!]", message)
  return process.exit(1)
end

return error