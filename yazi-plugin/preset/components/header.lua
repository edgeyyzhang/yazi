Header = {}

function Header:cwd()
	local cwd = cx.active.current.cwd

	local span
	if not cwd.is_search then
		span = ui.Span(utils.readable_path(tostring(cwd)))
	else
		span = ui.Span(string.format("%s (search: %s)", utils.readable_path(tostring(cwd)), cwd.frag))
	end
	return span:style(THEME.manager.cwd)
end

function Header:tabs()
	local spans = {}
	for i = 1, #cx.tabs do
		local text = i
		if THEME.manager.tab_width > 2 then
			text = utils.truncate(text .. " " .. cx.tabs[i]:name(), THEME.manager.tab_width)
		end
		if i == cx.tabs.idx + 1 then
			spans[#spans + 1] = ui.Span(" " .. text .. " "):style(THEME.manager.tab_active)
		else
			spans[#spans + 1] = ui.Span(" " .. text .. " "):style(THEME.manager.tab_inactive)
		end
	end
	return ui.Line(spans)
end


function Header:permissions()
	local h = cx.active.current.hovered
	if h == nil then
		return ui.Span("")
	end

	local perm = h:permissions()
	if perm == nil then
		return ui.Span("")
	end

	local spans = {}
	for i = 1, #perm do
		local c = perm:sub(i, i)
		local style = THEME.status.permissions_t
		if c == "-" then
			style = THEME.status.permissions_s
		elseif c == "r" then
			style = THEME.status.permissions_r
		elseif c == "w" then
			style = THEME.status.permissions_w
		elseif c == "x" or c == "s" or c == "S" or c == "t" or c == "T" then
			style = THEME.status.permissions_x
		end
		spans[i] = ui.Span(c):style(style)
	end
	return ui.Line(spans)
end

function Header:percentage()
	local percent = 0
	local cursor = cx.active.current.cursor
	local length = #cx.active.current.files
	if cursor ~= 0 and length ~= 0 then
		percent = math.floor((cursor + 1) * 100 / length)
	end

	if percent == 0 then
		percent = "  Top"
	else
		percent = string.format(" %3d%%", percent)
	end

	return ui.Line {
		-- ui.Span(" " .. THEME.status.separator_open):fg(THEME.status.separator_style.fg),
		-- ui.Span(percent):fg(style.bg):bg(THEME.status.separator_style.bg),
        ui.Span(percent):style({fg="#FEFC67"})
	}
end

function Header:position()
	local cursor = cx.active.current.cursor
	local length = #cx.active.current.files

	return ui.Line {
		-- ui.Span(string.format(" %2d/%-2d ", cursor + 1, length)):style(style),
		-- ui.Span(THEME.status.separator_close):fg(style.bg),
        ui.Span(string.format(" %2d/%-2d ", cursor + 1, length)):style({fg="#FEFC67"})
	}
end

function Header:progress(area, offset)
	local progress = cx.tasks.progress
	local left = progress.total - progress.succ
	if left == 0 then
		return {}
	end

	local gauge = ui.Gauge(ui.Rect {
		x = math.max(0, area.w - offset - 21),
		y = area.y,
		w = math.max(0, math.min(20, area.w - offset - 1)),
		h = 1,
	})

	if progress.fail == 0 then
		gauge = gauge:gauge_style(THEME.status.progress_normal)
	else
		gauge = gauge:gauge_style(THEME.status.progress_error)
	end

	local percent = 99
	if progress.found ~= 0 then
		percent = math.min(99, progress.processed * 100 / progress.found)
	end

	return {
		gauge
			:percent(percent)
			:label(ui.Span(string.format("%3d%%, %d left", percent, left)):style(THEME.status.progress_label)),
	}
end

function Header:render(area)
	local chunks = ui.Layout()
		:direction(ui.Direction.HORIZONTAL)
		:constraints({ ui.Constraint.Percentage(50), ui.Constraint.Percentage(50) })
		:split(area)

	local left = ui.Line { self:cwd() }
	local right = ui.Line { self:permissions(), self:percentage(), self:position()}
    local progress = self:progress(area, right:width())
	return {
		ui.Paragraph(chunks[1], { left }),
		ui.Paragraph(chunks[2], { right }):align(ui.Alignment.RIGHT),
        table.unpack(progress),
	}
end
