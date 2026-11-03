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
