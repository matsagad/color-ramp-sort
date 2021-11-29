function init(plugin)

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
		onclick = function()
			-- Perform the sorting algorithm.
		end
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
			dlg:show()
		end
	}
end

function exit(plugin)
end