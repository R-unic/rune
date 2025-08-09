--!strict
--!native
export type function gurantee(ty)
  if ty:is("union") then
    local newComponents: { type } = {}
    for _, component in ty:components() do
      if component.tag == "nil" then continue end
      table.insert(newComponents, component)
    end
    return types.unionof(table.unpack(newComponents))
  end

  return ty
end

export type function writable(ty)
  local isTable = ty:is("table")
  if not isTable then
    local intersection = ty:is("intersection")
    if intersection or ty:is("union") then
      local allWritable: { type } = {}
      for _, componentTy in ty:components() do
        table.insert(allWritable, writable(componentTy))
      end

      return if intersection then
        types.intersectionof(table.unpack(allWritable))
      else
        types.unionof(table.unpack(allWritable))
    end
    error("Can only call writable on tables.")
  end

  for property, propTy in ty:properties() do
    ty:setwriteproperty(property, propTy.read)
  end

  return ty
end

return nil