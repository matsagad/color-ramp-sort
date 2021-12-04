-- Basic Tree Data Structure for the Dendogram
Tree = {}

function Tree:create(value, left, right)
	local tree = setmetatable({}, Tree)
	tree.value = value
	tree.left = left
	tree.right = right
	return tree
end

-- TODO: implement other relevant methods