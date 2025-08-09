local process = require("@lune/process") :: process

local argParser = {}

type ParsedValue = string | number | boolean
export type ParseResult<K> = { [K]: ParsedValue } | string
export type Option = {
  shortName: string;
  longName: string?;
  description: string;
  required: boolean?;
  type: "string" | "number" | "boolean";
}

function argParser.parse<K>(options: { [K]: Option }): (boolean, ParseResult<K>)
  local success = true
  local result: { [K]: ParsedValue } = {}
  for name, info in options do
    if info.type == "boolean" then
      result[name] = false
    end

    local parameterType: string?
    for _, arg in process.args do
      local matchesShortName = arg == "-" .. info.shortName
      local matchesLongName = not info.longName or arg == "--" .. info.longName
      if parameterType then
        local value: ParsedValue = arg
        if parameterType == "number" then
          value = tonumber(value) :: number
        end
        result[name] = value
        parameterType = nil
      end

      if not matchesShortName and not matchesLongName then
        continue
      end

      if info.type == "boolean" then
        result[name] = true
        continue
      end

      parameterType = info.type
    end
  end

  for name, info in options do
    if info.required and info.type ~= "boolean" and result[name] == nil then
      success = false;
      result = "[!] Missing required argument: " .. name
    end
  end

  return success, result
end

return argParser