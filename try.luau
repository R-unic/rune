local process = require("@lune/process") :: process

local function try<R, A...>(f: (A...) -> R, ...: A...): R
  local success, result = pcall(f, ...)
  if not success then
    print("[!]", tostring(result))
    process.exit(1)
  end
  return result
end

return try