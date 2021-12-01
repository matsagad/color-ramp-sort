function init(plugin)

  local sort_palette

  -- Aseprite Pop-up Dialog
  local dlg = Dialog{title = "Color Ramp Sort"}
  
  dlg:slider {
    id = "min_ramp_size",
    label = "Min. Ramp Size: ",
    min = 3,
    value = 3
  }

  dlg:check {
    id = "allow_intersections",
    text = "Allow Intersections",
    selected = false,
    focus = false
  }

  dlg:separator {
    id = "separator",
    text = "Advanced"
  }

  dlg:combobox {
    id = "granularity",
    label = "Hough Space Granularity: ",
    option = "medium",
    options = {"low", "medium", "high"}
  }

  local _GRAN_SIZE = {["low"] = 1, ["medium"] = 2, ["high"] = 3}

  dlg:button {
    id = "color_ramp_sort",
    text = "Sort",
    onclick = function() app.transaction(sort_palette()) end
  }

  dlg:button {
    id = "cancel",
    text = "Cancel",
    onclick = function() dlg:close() end
  }

  plugin:newCommand{
    id = "color_ramp_sort_popup",
    title = "Sort by Color Ramp",
    group = "palette_main",
    onclick = function() dlg:show() end
  }

  -- Polar Coordinate Constraints
  local _MAX_R = math.floor(255 * math.sqrt(2))
  local _MAX_THETA = 180

  -- Palette Sorting Logic
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

  local function get_unique_colors(table, row, col)
    local bits = 0

    for i = row - 1, (row + 1) do
      for j = col - 1, (col + 1) do
        bits = bits | table[i][j]
      end
    end

    return bits
  end

  sort_palette = function()
    
    -- Get pop-up dialog configurations
    local min_ramp_size = dlg.data.min_ramp_size
    local allow_intersections = dlg.data.allow_intersections
    local granularity = _GRAN_SIZE[dlg.data.granularity]

    -- Extract colors from the active palette
    local palette = app.activeSprite.palettes[1]
    local colors = {}
    for i = 1, #palette do
      colors[i] = palette:getColor(i - 1)
    end

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
    -- In each two dimensional case, perform a Hough transform, and setting the
    -- bit corresponding to the color being transformed.
    for i = 1, #colors do
      local color = colors[i]
      local hspace_pairs = {[color.green] = hspace_b, [color.blue] = hspace_g}
      for theta = 0, _MAX_THETA do
        for y_value, hspace in pairs(hspace_pairs) do
          local r = get_space_parameter(color.red, y_value, theta, granularity)
          hspace[r + 1][theta + 1] = hspace[r + 1][theta + 1] + (1 << i)
        end
      end
    end

    -- Traverse the hough space through a 3x3 window and check if there are at
    -- least min_ramp_size colors incident on it. If so, add them onto the
    -- candidate dictionary and increment their value.
    local proj_b_ramps, proj_g_ramps = {}, {}
    local ramp_pairs = {{proj_b_ramps, hspace_b}, {proj_g_ramps, hspace_g}}
    for i = 1, (2 * _MAX_R * granularity - 1) do
      for j = 1, (_MAX_THETA - 1) do
        for _, ramp_pair in pairs(ramp_pairs) do
          local unique_colors = get_unique_colors(ramp_pair[2], i + 1, j + 1)
          local unique_color_count = num_bits_set(unique_colors)
          if (unique_color_count >= min_ramp_size) then
            if (ramp_pair[1][unique_colors] == nil) then
              ramp_pair[1][unique_colors] = 1
            else
              ramp_pair[1][unique_colors] = ramp_pair[1][unique_colors] + 1
            end
          end
        end
      end
    end
    
  end
end

function exit(plugin)
end