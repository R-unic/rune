export type function writable(ty)
  if not ty:is("table") then
    error("Can only call writable on tables.")
  end

  for property, propTy in ty:properties() do
    ty:setwriteproperty(property, propTy.read)
  end

  return ty
end

return nil