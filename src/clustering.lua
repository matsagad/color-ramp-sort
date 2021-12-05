dofile("./tree.lua")

-- Helper functions
local function get_key_value_max(row)
  local max_key, max_value = 1, row[1]
  for key, value in pairs(row) do
    if value > max_value then
      max_key, max_value = key, value
    end
  end
  return max_key, max_value
end

local function get_dendrogram(matrix)
  -- Make upper-triangular matrix whole
  matrix[#matrix + 1] = {}
  for i = 1, #matrix do
    local row = matrix[i]
    for j = i + 1, #matrix do
      matrix[j][i] = row[j]
    end
  end
  for i = 1, #matrix do
    matrix[i][i] = -1
  end

  -- Create arrays to note down most similar node
  local closest_node, max_similarity = {}, {}
  for i = 1, #matrix do
    closest_node[i], max_similarity[i] = get_key_value_max(matrix[i])
  end

  -- Set up array of trees for each color
  local trees = {}
  for i = 1, #matrix do
    trees[i] = nil
  end

  -- Keep combining clusters until there is one cluster left with all colors
  for _ = 1, (#matrix - 1) do
    local color_a, similarity = get_key_value_max(max_similarity)
    local color_b = closest_node[color_a]
    local row_a, row_b = matrix[color_a], matrix[color_b]
    
    -- Connect nodes as part of the dendrogram
    for color = color_a, color_b, (color_b - color_a) do
      if trees[color] == nil then
        trees[color] = Tree:create(color, nil, nil)
      end
    end
    trees[color_a] = Tree:create(nil, trees[color_a], trees[color_b])
    trees[color_b] = nil

    -- Update matrix entries by way of average linkage and zero out rows and
    -- columns of color_b
    for i = 1, #matrix do
      row_a[i] = (row_a[i] + row_b[i]) / 2
      row_b[i], matrix[i][color_b] = -1, -1
    end
    row_a[color_a] = -1

    -- Update arrays noting down most similar node
    closest_node[color_b], max_similarity[color_b] = -1, -1
    for i = 1, #matrix do
      if closest_node[i] == color_b then
        closest_node[i], max_similarity[i] = get_key_value_max(matrix[i])
      end
    end
  end

  -- Find the root of the dendrogram
  local root
  for i = 1, #matrix do
    if trees[i] ~= nil then
      root = trees[i]
      break
    end
  end

  return root
end

-- Global configurations
local min_ramp_size, stack_outliers, exclude_outliers = 2, false, true

local function put_outliers_in_ramps(ramps, outliers)
  if stack_outliers and next(outliers) ~= nil then
    table.insert(ramps, outliers)
  else
    for _, outlier in pairs(outliers) do
      table.insert(ramps, { outlier })
    end
  end
end

local function get_ramps_from_tree(root, ramps, outliers)
  -- If root is nil, add all outliers as individual ramps
  if root == nil then
    put_outliers_in_ramps(ramps, outliers)
    return ramps
  -- If root is "skewed-full", then all its leaves are part of a single ramp
  elseif root:is_skewed_full() then
    table.insert(ramps, root:flatten())
    put_outliers_in_ramps(ramps, outliers)
    return ramps
  end

  if not root:is_leaf() then
    local left_count = root.left:leaves_count()
    local right_count = root.right:leaves_count()

    -- If exactly one child does not have enough colors to form a ramp, then 
    -- all its colors are considered outliers, and the other child is traversed
    -- instead. If both do not have enough colors, their colors are merged.
    -- If even then there are not enough colors, outliers are included one at a
    -- time until either the minimum ramp size is reached or there are no more
    -- outliers (that is if the excluding outliers option is turned off).
    if left_count < min_ramp_size then
      if right_count >= min_ramp_size then
        outliers = merge(outliers, root.left:flatten())
        return get_ramps_from_tree(root.right, ramps, outliers)
      end
      local merged = merge(root.left:flatten(), root.right:flatten())
      if left_count + right_count < min_ramp_size then
        if not exclude_outliers then
          while #merged < min_ramp_size and #outliers > 0 do
            table.insert(merged, outliers[#outliers])
            table.remove(outliers, #outliers)
          end
        end
      end
      table.insert(ramps, merged)
      put_outliers_in_ramps(ramps, outliers)
      return ramps
    end
    if right_count < min_ramp_size then
      outliers = merge(outliers, root.right:flatten())
      return get_ramps_from_tree(root.left, ramps, outliers)
    end
    
    -- It can be assumed at this point that both children have enough colors to
    -- form a ramp. If they are "skewed-full" then they are immediately
    -- flattened and considered as a ramp.
    local children = { root.left, root.right }
    for index, child in pairs(children) do
      if child:is_skewed_full() then
        table.insert(ramps, child:flatten())
        return get_ramps_from_tree(children[3 - index], ramps, outliers)
      end
    end

    -- If none of the children are "skewed-full" but can have enough colors
    -- to form a ramp, then each outliers is considered as a single ramp and
    -- the children are traversed separately.
    put_outliers_in_ramps(ramps, outliers)
    local ramps_left = get_ramps_from_tree(root.left, ramps, {})
    return get_ramps_from_tree(root.right, ramps_left, {})
  end

  put_outliers_in_ramps(ramps, outliers)
  return ramps
end

function get_clusters(matrix, config)
  -- Set global variables
  min_ramp_size = config[1]
  stack_outliers = config[2]
  exclude_outliers = config[4]

  -- Find ramps by hierarchical clustering
  local root = get_dendrogram(matrix)
  local ramps = get_ramps_from_tree(root, {}, {})

  return ramps
end
