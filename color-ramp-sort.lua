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
		id = "hspace_granularity",
		label = "Hough Space Granularity: ",
		option = "medium",
		options = {"low", "medium", "high"}
	}

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
	local function get_space_parameter(x, y, theta)
		return math.floor(x * math.cos(math.rad(theta)) 
			+ y * math.sin(math.rad(theta))) + _MAX_R
	end

	sort_palette = function()

		-- Get pop-up dialog configurations
		local max_ramp_size = dlg.data.min_ramp_size
		local allow_intersections = dlg.data.allow_intersections
		local hspace_granularity = dlg.data.hspace_granularity

		-- Extract colors from the active palette
		local palette = app.activeSprite.palettes[1]
		local colors = {}
		for i = 1, #palette do
			colors[i] = palette:getColor(i - 1)
		end

		-- Set up the Hough spaces
		local hspace_b = {}
		local hspace_g = {}
		for i = 0, (2 * _MAX_R) do
			hspace_b[i + 1] = {}
			hspace_g[i + 1] = {}
			for j = 0, _MAX_THETA do
				hspace_b[i + 1][j + 1] = 0
				hspace_g[i + 1][j + 1] = 0
			end
		end

		-- Project the colors onto the blue (y = 0) and the green (z = 0) planes.
		-- In each two dimensional case, perform a Hough transform, incrementing
		-- each space cell, by setting the bit corresponding to the color being
		-- transformed.
		for i = 1, #colors do
			local color = colors[i]
			for theta = 0, _MAX_THETA do
				local r_b = get_space_parameter(color.red, color.green, theta)
				hspace_b[r_b + 1][theta + 1] = hspace_b[r_b + 1][theta + 1] + 1 << i
				local r_g = get_space_parameter(color.red, color.blue, theta)
				hspace_g[r_g + 1][theta + 1] = hspace_g[r_g + 1][theta + 1] + 1 << i
			end
		end

	end
end

function exit(plugin)
end