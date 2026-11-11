-- agentmux labels its panes with the editor block ID. Keeping the pairing on
-- the block makes it survive config reloads without a registration service.
rex.action({
	name = "agentmux_return",
	title = "Return to AgentMux Editor",
	run = function(ctx)
		if not ctx.block_id then
			return { handled = false }
		end
		local result, err = rex.session.describe_block({ block_id = ctx.block_id })
		if err then
			rex.log("warn", err)
			return { handled = false }
		end
		local editor = result.block.label:match("^agentmux:(block:.+)$")
		if not editor then
			return { handled = false }
		end
		local focused
		focused, err = rex.session.focus_block({ block_id = editor })
		if err then
			rex.log("warn", "agentmux: " .. err)
			return { handled = false }
		end
		return { handled = focused ~= nil }
	end,
})

rex.bind("ctrl+.", function()
	-- In the editor, fall through so Neovim can lazily start/focus its agent.
	local result = rex.invoke("agentmux_return")
	return result ~= nil and result.handled == true
end)

-- Quick navigation: cycle tabs, jump to the first two tabs, or open the
-- session switcher.
rex.bind("ctrl+space>n", "client.tab.next")
rex.bind("ctrl+space>p", "client.tab.previous")
rex.bind("ctrl+space>1", "client.tab.goto", { index = 1 })
rex.bind("ctrl+space>2", "client.tab.goto", { index = 2 })

-- Match the server's session order, including sidebar reordering.
rex.action({
	name = "session_goto",
	title = "Go to Session by Number",
	args = { index = "integer" },
	run = function(ctx, args)
		local listed, err = rex.call("session.list", {})
		if err then
			error(err, 0)
		end
		local session = (listed.sessions or {})[args.index]
		if session then
			rex.client.queue("session.select", { session_id = session.session_id })
		end
	end,
})

for index = 1, 9 do
	rex.bind("ctrl+" .. index, "session_goto", { index = index })
end

-- Show the sesh picker in a floating terminal so fzf does not cover the tab.
rex.action({
	name = "sesh_picker",
	title = "Toggle Sesh Picker",
	run = function(ctx)
		local listed, list_err = rex.session.list_blocks({})
		if list_err then
			error(list_err, 0)
		end
		local window_id
		for _, block in ipairs(listed.blocks or {}) do
			if block.block_id == ctx.block_id then
				window_id = block.window_id
				break
			end
		end
		local closed = false
		for _, block in ipairs(listed.blocks or {}) do
			if
				block.label == "Sesh Picker"
				and block.placement == "placed"
				and (not window_id or block.window_id == window_id)
			then
				local _, close_err = rex.call("block.close", {
					session_id = ctx.session_id,
					block_id = block.block_id,
				})
				if close_err then
					error(close_err, 0)
				end
				closed = true
			end
		end
		if closed then
			return
		end
		local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
		local command = { "python3", config_home .. "/rex/sesh-picker.py" }
		if ctx.client_id then
			table.insert(command, ctx.client_id)
		end
		local _, err = rex.session.new_layer({
			bounds = { 0.225, 0.12, 0.55, 0.76 },
			focus = true,
			layout = rex.layout.block({
				flavor = "com.superlogical.terminal.shell",
				label = "Sesh Picker",
				options = { command = command },
			}),
		})
		if err then
			error(err, 0)
		end
	end,
})

rex.bind("cmd+k", "sesh_picker")
rex.bind("ctrl+alt+k", "sesh_picker")
rex.bind("ctrl+space>t", "sesh_picker")
rex.bind("ctrl+space>s", "sesh_picker")

-- Quake-style scratch terminal, one per session like the tmux __popup
-- sessions. Hiding detaches the block (the shell keeps running); showing moves
-- it into the current tab and floats it there.
local QUICK_TERMINAL_LABEL = "Quick Terminal"
local QUICK_TERMINAL_BOUNDS = { 0.15, 0.15, 0.7, 0.7 }

local function must(result, err)
	if err then
		error(err, 0)
	end
	return result
end

rex.action({
	name = "quick_terminal",
	title = "Toggle Quick Terminal",
	run = function(ctx)
		local sid = ctx.session_id
		local view = must(rex.call("session.view", { session_id = sid }))

		-- Where each placed block lives, and which tab the key was pressed in.
		local located = {}
		for _, w in ipairs(view.windows or {}) do
			for _, layer in ipairs(w.layers or {}) do
				for _, block in ipairs(layer.blocks or {}) do
					located[block.block_id] = { window = w, layer = layer }
				end
			end
		end
		local here = ctx.block_id and located[ctx.block_id] and located[ctx.block_id].window
		if not here then
			for _, w in ipairs(view.windows or {}) do
				if w.window_id == view.active_window_id then
					here = w
				end
			end
		end
		if not here then
			return
		end

		-- The session's quick terminal, placed or detached.
		local quick
		for _, block in ipairs(must(rex.session.list_blocks({})).blocks or {}) do
			if block.label == QUICK_TERMINAL_LABEL then
				quick = block.block_id
				break
			end
		end

		if not quick then
			must(rex.session.new_layer({
				window_id = here.window_id,
				bounds = QUICK_TERMINAL_BOUNDS,
				focus = true,
				layout = rex.layout.block({
					flavor = "com.superlogical.terminal.shell",
					label = QUICK_TERMINAL_LABEL,
				}),
			}))
			return
		end

		local where = located[quick]
		if where and where.window.window_id == here.window_id then
			if where.layer.kind == "floating" and here.focused_block_id == quick then
				must(rex.call("session.detach_block", { session_id = sid, block_id = quick }))
			else
				must(rex.session.focus_block({ block_id = quick }))
			end
			return
		end

		-- Detached or in another tab: bring it here. move_block can only place
		-- it beside a block, so split it into this tab's layout, then float it.
		local anchor
		for _, block in ipairs((here.layers[1] or {}).blocks or {}) do
			if block.block_id ~= quick then
				anchor = block.block_id
				break
			end
		end
		if not anchor then
			error("quick_terminal: no tiled pane in this tab to anchor to", 0)
		end
		must(rex.call("session.move_block", {
			session_id = sid,
			block_id = quick,
			anchor_block_id = anchor,
		}))
		must(rex.call("session.float_block", {
			session_id = sid,
			block_id = quick,
			bounds = QUICK_TERMINAL_BOUNDS,
		}))
		must(rex.session.focus_block({ block_id = quick }))
	end,
})

rex.bind("alt+i", "quick_terminal")
