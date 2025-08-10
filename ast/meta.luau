--!strict
--!native
local Node = { name = "Node" }
local Expression = setmetatable({ name = "Expression" }, Node)
local Statement = setmetatable({ name = "Statement" }, Node)

local function hasMetatable<T>(t: T, mt: { read name: string; }): boolean
  local meta = t
  while true do
    meta = getmetatable(meta) :: { read name: string; }
    if meta.name == mt.name then
      return true
    end
    if meta == nil then break end
  end

  return false
end

local function isNode<T>(t: T & {}): boolean
  return hasMetatable(t, Node)
end

local function isExpression<T>(t: T & {}): boolean
  return isNode(t) and hasMetatable(t, Expression)
end

local function isStatement<T>(t: T & {}): boolean
  return isNode(t) and hasMetatable(t, Statement)
end

return {
  Node = Node,
  Expression = Expression,
  Statement = Statement,
  isNode = isNode,
  isExpression = isExpression,
  isStatement = isStatement
}