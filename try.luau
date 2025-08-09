--!strict
--!native
local process = require("@lune/process") :: process

local function try<A..., R...>(f: (A...) -> R..., ...: A...): R...
  local success, result = table.unpack({ pcall(f, ...) })
  if not success then
    print("[!]", tostring(result))
    process.exit(1)
  end
  return result :: any
end

return try