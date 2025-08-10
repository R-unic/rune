export type Symbol = {
  read name: string;
  read type: string;
  read isConstant: boolean;
}

local function symbol(name: string?, ty: string, isConstant: boolean?): Symbol
  if isConstant == nil then
    isConstant = false
  end

  return {
    name = name,
    type = ty,
    isConstant = isConstant
  }
end

return symbol