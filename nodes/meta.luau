local Node = {}
local Expression = setmetatable({}, Node)
local Statement = setmetatable({}, Node)

local function hasMetatable<T>(t: T & {}, mt: {}): boolean
  local meta = getmetatable(t)
  local match = meta == mt
  while meta do
    meta = getmetatable(meta)
    match = match or meta == mt
  end

  return match
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