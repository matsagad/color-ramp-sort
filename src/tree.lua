-- Helper function
function merge(array_a, array_b)
  for _, value in pairs(array_b) do
    table.insert(array_a, value)
  end
  return array_a
end

-- Basic Tree Data Structure for the Dendrogram
Tree = {}
Tree.__index = Tree

function Tree:create(value, left, right)
  local tree = setmetatable({}, Tree)
  tree.value = value
  tree.left = left
  tree.right = right
  return tree
end

function Tree:is_leaf()
  return self.left == nil and self.right == nil
end

-- Let us define a tree to be "skewed-full" if every node except the leaves
-- has exactly two children with at least one of them being a leaf node.
function Tree:is_skewed_full()
  if self.left ~= null and self.right ~= null then
    -- Check at least one child is a leaf
    if self.left:is_leaf() then
      if self.right:is_leaf() then
        return true
      end
      return self.right:is_skewed_full()
    end
    if self.right:is_leaf() then
      return self.left:is_skewed_full()
    end
  end
  return false
end

function Tree:flatten()
  local values = {}
  for _, child in pairs({self.left, self.right}) do
    if child ~= nil then
      if child:is_leaf() then
        table.insert(values, child.value)
      else
        merge(values, child:flatten())
      end
    end
  end
  return values
end

function Tree:leaves_count()
  if self:is_leaf() then
    return 1
  elseif self.left == nil then
    return self.right:leaves_count()
  elseif self.right == nil then
    return self.left:leaves_count()
  else
    return self.left:leaves_count() + self.right:leaves_count()
  end
end