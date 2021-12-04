dofile("./hough.lua")
dofile("./clustering.lua")

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

  -- Palette Sorting Logic
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

    -- Perform two Hough transforms to find "collinear enough" colors, count
    -- occurences for when colors are incident in the Hough space, and compile
    -- each pairwise count onto an adjacency matrix.
    local distance_matrix 
      = get_similarity_matrix(colors, min_ramp_size, granularity)

    -- Perform hierarchical clustering to yield pairwise disjoint color ramps
    local ramps = get_ramps_with_hierarchical_clustering(distance_matrix)

    -- TODO: sort colors in each color ramp, sort the color ramps, then set
    -- the active palette to show the color ramps.
    
  end
end

function exit(plugin)
end