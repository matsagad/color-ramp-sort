-- Polar Coordinate Constraints
local _MAX_R = math.floor(255 * math.sqrt(2))
local _MAX_THETA = 180

-- Helper Functions
local function increment_cell(table, index, amount)
  table[index] = table[index] + amount
end

local function get_space_parameter(x, y, theta, granularity)
  return math.floor(x * math.cos(math.rad(theta)) 
    + y * math.sin(math.rad(theta))) + _MAX_R * granularity
end

local function num_bits_set(bits)
  local count = 0
  while bits > 0 do
    count = count + (bits & 1)
    bits = bits >> 1
  end
  return count
end

local function get_bits_set(bits)
  local bits_set = {}
  local index = 1
  while bits > 0 do
    if bits & 1 == 1 then
      table.insert(bits_set, index)
    end
    index = index + 1
    bits = bits >> 1
  end
  return bits_set
end

local function get_unique_colors(table, row, col)
  local bits = 0
  for i = row - 1, (row + 1) do
    for j = col - 1, (col + 1) do
      bits = bits | table[i][j]
    end
  end
  return bits
end

local function get_in_binary(bits)
  local num = ""
  while bits > 0 do
    num = tostring(bits & 1) .. num
    bits = bits >> 1
  end
  return num
end

function get_similarity_matrix(colors, min_ramp_size, granularity)
  -- Set up the Hough spaces
  local hspace_b, hspace_g = {}, {}
  for i = 0, (2 * _MAX_R * granularity) do
    hspace_b[i + 1] = {}
    hspace_g[i + 1] = {}
    -- Bit map of colors initialized to zero.
    for j = 0, _MAX_THETA do
      hspace_b[i + 1][j + 1] = 0
      hspace_g[i + 1][j + 1] = 0
    end
  end

  -- Project the colors onto the blue (y = 0) and the green (z = 0) planes.
  -- In each two dimensional case, perform a Hough transform for each color,
  -- setting the bits corresponding to it.
  for i = 1, #colors do
    local color = colors[i]
    local hspace_pairs = {[color.green] = hspace_b, [color.blue] = hspace_g}
    for theta = 0, _MAX_THETA do
      for y_value, hspace in pairs(hspace_pairs) do
        local r = get_space_parameter(color.red, y_value, theta, granularity)
        increment_cell(hspace[r + 1], theta + 1, 1 << (i - 1))
      end
    end
  end

  -- Candidate ramp dictionaries which takes a color ramp (bitmap) as a key
  -- and the number of "occurences" as its value.
  local proj_b_ramps, proj_g_ramps = {}, {}
  local ramp_pairs = {{proj_b_ramps, hspace_b}, {proj_g_ramps, hspace_g}}

  -- Traverse the Hough space through a 3x3 window and check if there are at
  -- least min_ramp_size colors incident on it. If so, we consider a ramp
  -- containing these colors, add it to the candidate dictionaries if not
  -- already in it, and increment its value by the number of colors contained.
  for i = 1, (2 * _MAX_R * granularity - 1) do
    for j = 1, (_MAX_THETA - 1) do
      for _, ramp_pair in pairs(ramp_pairs) do
        local ramp = get_unique_colors(ramp_pair[2], i + 1, j + 1)
        local color_count = num_bits_set(ramp)
        if (color_count >= min_ramp_size) then
          if (ramp_pair[1][ramp] == nil) then
            ramp_pair[1][ramp] = color_count
          else
            increment_cell(ramp_pair[1], ramp, color_count)
          end
        end
      end
    end
  end

  -- Process the projected ramp dictionaries into a similarity matrix where the
  -- rows and columns are indexed according to the color's order in the original
  -- palette. The entries correspond to the degree two colors appear together
  -- in a ramp.
  local similarity_matrix = {}
  for i = 1, (#colors - 1) do
    similarity_matrix[i] = {}
    local row = similarity_matrix[i]
    for j = i + 1, #colors do
      row[j] = 0
    end
  end
  
  -- This degree is given by the sum of all the products of the occurences for
  -- each ramp in both dictionaries. This is to avoid false cases with
  -- collinearity in one dimension but not in the other.
  for ramp, count in pairs(proj_b_ramps) do
    if proj_g_ramps[ramp] ~= nil then
      local bits_set = get_bits_set(ramp)
      for i = 1, (#bits_set - 1) do
        local row = similarity_matrix[bits_set[i]]
        for j = i + 1, #bits_set do
          increment_cell(row, bits_set[j], proj_g_ramps[ramp] * count)
        end
      end
    end
  end

  return similarity_matrix
end