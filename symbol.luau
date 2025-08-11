export type Symbol = {
  read name: string;
  read type: string;
  read declaredType: string?;
  read isConstant: boolean;
}

local function symbol(name: string?, ty: string, isConstant: boolean?, isDeclaredType: boolean?): Symbol
  if isConstant == nil then
    isConstant = false
  end
  if isDeclaredType == nil then
    isDeclaredType = false
  end

  local sym = {
    name = name,
    type = ty,
    isConstant = isConstant
  }

  if isDeclaredType then
    sym.declaredType = ty
  end

  return sym
end

return symbol