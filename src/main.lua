dofile("./hough.lua")
dofile("./clustering.lua")

function init(plugin)

  local sort_palette

  -- Aseprite Pop-up Dialog
  local dlg = Dialog{ title = "Color Ramp Sort" }
  
  dlg :label { text = "Min. Ramp Size: " }
      :slider {
        id = "min_ramp_size",
        min = 2,
        value = 2
      }

  -- Sorting Method Function Hash Map
  local _SORT_METHOD = {
    ["Hue"] = function(c) return c.hue end,
    ["Saturation"] = function(c) return c.saturation end,
    ["Brightness"] = function(c) return c.lightness end,
    ["Red"] = function(c) return c.red end,
    ["Green"] = function(c) return c.green end,
    ["Blue"] = function(c) return c.blue end,
    ["R+G+B"] = function(c) return c.red+ c.green + c.blue end,
    ["R^2+G^2+B^2"] = function(c) 
      return c.red ^ 2 + c.green ^ 2 + c.blue ^ 2
    end
  }

  dlg :label { text = "Sort Ramps Internally And Externally By: " }
      :combobox {
        id = "internal_sort",
        option = "Medium",
        options = {
          "Hue", 
          "Saturation", 
          "Brightness", 
          "Red",
          "Green",
          "Blue",
          "R+G+B",
          "R^2+G^2+B^2"
        }
      }

  dlg:combobox {
        id = "external_sort",
        option = "Medium",
        options = {
          "Hue", 
          "Saturation", 
          "Brightness", 
          "Red",
          "Green",
          "Blue",
          "R+G+B",
          "R^2+G^2+B^2"
        }
      }

  dlg:check {
    id = "stack_outliers",
    text = "Collect Outliers In A Ramp",
    selected = false,
    focus = false
  }

  dlg:separator {
    id = "separator",
    text = "Advanced"
  }

  local _GRAN_SIZE = { ["Low"] = 1, ["Medium"] = 2, ["High"] = 3 }

  dlg :label { text = "Space Granularity: " }
      :combobox {
        id = "granularity",
        option = "Medium",
        options = { "Low", "Medium", "High" }
      }

  dlg:check {
    id = "exclude_outliers",
    text = "Exclude Outliers From Ramps",
    selected = true,
    focus = false
  }

  dlg:button {
    id = "color_ramp_sort",
    text = "Sort",
    onclick = function() sort_palette() end
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
    onclick = function() 
      dlg:modify{ id = "min_ramp_size", max = #app.activeSprite.palettes[1] }
      dlg:show() 
    end
  }

  local function ramp_value(indices, ext_value, colors)
    local max_value = ext_value(colors[indices[1]])
    for _, index in pairs(indices) do
      local curr_value = ext_value(colors[index])
      if curr_value > max_value then
        max_value = curr_value
      end
    end
    return max_value
  end

  -- Palette Sorting Logic
  sort_palette = function()
    -- Get pop-up dialog configurations
    local config = {
      dlg.data.min_ramp_size,
      dlg.data.stack_outliers,
      _GRAN_SIZE[dlg.data.granularity],
      dlg.data.exclude_outliers
    }
    local internal_sort = dlg.data.internal_sort
    local external_sort = dlg.data.external_sort

    -- Extract colors from the active palette
    local palette = app.activeSprite.palettes[1]
    local colors = {}
    for i = 1, #palette do
      colors[i] = palette:getColor(i - 1)
    end

    -- Perform two Hough transforms to find "collinear enough" colors, count
    -- occurences for when colors are incident in the Hough space, and compile
    -- each pairwise count onto an adjacency matrix.
    local matrix = get_similarity_matrix(colors, config)

    -- Perform hierarchical clustering to yield pairwise disjoint color ramps
    local ramps = get_clusters(matrix, config)

    -- Get sorting internal and external sorting methods
    local int_value = _SORT_METHOD[internal_sort]
    local ext_value = _SORT_METHOD[external_sort]

    -- Sort colors in each ramp
    for _, ramp in pairs(ramps) do
      table.sort(ramp, function(a, b)
        return int_value(colors[a]) < int_value(colors[b]) 
      end)
    end

    -- Sort color ramps
    table.sort(ramps, function(a, b)
      return ramp_value(a, ext_value, colors) < ramp_value(b, ext_value, colors) 
    end)
    
    -- Reorder colors in the active palette
    app.transaction(function()
        local index = 0
        for i = 1, #ramps do
          local ramp = ramps[i]
          for j = 1, #ramp do
            palette:setColor(index, colors[ramp[j]])
            index = index + 1
          end
        end
      end
    )
  end
end

function exit(plugin)
end