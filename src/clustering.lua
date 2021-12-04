dofile("./tree.lua")

local function get_key_value_max(row)
  local max_key, max_value = 1, row[1]
  for key, value in pairs(row) do
    if value > max_value then
      max_key, max_value = key, value
    end
  end
  return max_key, max_value
end

local function get_dendogram(matrix)

  -- Make upper-triangular matrix whole
  matrix[#matrix + 1] = {}
  for i = 1, #matrix do
    local row = matrix[i]
    for j = i + 1, #matrix do
      matrix[j][i] = row[j]
    end
  end
  for i = 1, #matrix do
    matrix[i][i] = 0
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

    -- Connect nodes as part of the dendogram
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
      row_b[i], matrix[i][color_b] = 0, 0
    end
    row_a[color_a] = 0

    -- Update arrays noting down most similar node
    closest_node[color_b], max_similarity[color_b] = -1, -1
    for i = 1, #matrix do
      if closest_node[i] == color_b then
        closest_node[i], max_similarity[i] = get_key_value_max(matrix[i])
      end
    end
  end

  -- Find the root of the dendogram
  local root
  for i = 1, #matrix do
    if trees[i] ~= nil then
      root = trees[i]
      break
    end
  end

  return root
end

function get_ramps_with_hierarchical_clustering(similarity_matrix)
  local root = get_dendogram(similarity_matrix)

  -- TODO: cut the dendogram where apprioriate

  return nil
end
