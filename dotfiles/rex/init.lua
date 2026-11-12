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

-- Quick navigation: cycle tabs, focus adjacent panes, jump to tabs 1-9, or
-- zoom the focused pane.
rex.bind("ctrl+space>n", "client.tab.next")
rex.bind("ctrl+space>p", "client.tab.previous")
rex.bind("ctrl+space>z", "pane.zoom")

for _, binding in ipairs({
	{ "h", "left" },
	{ "j", "down" },
	{ "k", "up" },
	{ "l", "right" },
}) do
	rex.bind("ctrl+space>" .. binding[1], "pane.focus", { direction = binding[2], wrap = false })
end

for index = 1, 9 do
	rex.bind("ctrl+space>" .. index, "client.tab.goto", { index = index })
end

-- ctrl+1..9 goes to the Nth session on the machine you're looking at, and
-- ctrl+space>tab cycles to the next machine (this server, then each other host).
--
-- Keys are resolved by the server the app treats as home (the Mac's), even in
-- a remote host's session, so this Lua runs on the Mac. Findings from
-- rex_debug dumps:
--   * In a remote session ctx.server names that host and rex.call goes there;
--     rex.servers() lists only the other hosts, never this one.
--   * rex.client.queue("session.select") can't select another host's
--     session. Ask the app's client on that host instead (client.perform).
--   * This server's own sessions are only reachable from a remote session
--     through its rex CLI, which isn't on the server's PATH on macOS.
local function session_ids(api)
	local listed = api.call("session.list", {})
	local ids = {}
	for _, s in ipairs((listed and listed.sessions) or {}) do
		table.insert(ids, s.session_id)
	end
	return ids
end

local rex_cli_path
local function rex_cli()
	if rex_cli_path then
		return rex_cli_path
	end
	local script = [[
for p in "$REX_BIN_DIR/rex" "$HOME/.local/bin/rex" /opt/homebrew/bin/rex /usr/local/bin/rex; do
	[ -x "$p" ] && { echo "$p"; exit 0; }
done
command -v rex && exit 0
find /Applications "$HOME/Applications" -maxdepth 6 -type f -name rex -path '*Rex*' -perm -u+x 2>/dev/null | head -n 1
]]
	local result = rex.exec({ "sh", "-c", script }, { timeout = 5 })
	local path = result and result.ok and result.stdout:match("^%s*(.-)%s*$")
	if path and path ~= "" then
		rex_cli_path = path
	end
	return rex_cli_path
end

-- The app's client ID differs per host; pick the newest app client there.
local function app_client_on(api)
	local listed = api.call("client.list", {})
	local best
	for _, c in ipairs((listed and listed.clients) or {}) do
		if c.info and c.info.kind == "app" and (not best or (c.connected_at or "") > (best.connected_at or "")) then
			best = c
		end
	end
	return best and best.client_id
end

-- Show session_id, which lives on host `server` (nil = this server).
local function select_session(ctx, server, session_id)
	if server then
		local api = rex.server(server)
		local client_id = app_client_on(api)
		if not client_id then
			error("no app client on " .. server, 0)
		end
		local _, err = api.call("client.perform", {
			client_id = client_id,
			action = "session.select",
			args = { session_id = session_id },
		})
		if err then
			error(err, 0)
		end
	elseif ctx.server and rex_cli() then
		-- From a remote session, go through this server's CLI to select one of
		-- its own sessions.
		local result, err = rex.exec(
			{ rex_cli(), "-C", ctx.client_id, "do", "session.select", "session_id=" .. session_id },
			{ timeout = 5 }
		)
		if not (result and result.ok) then
			error(err or (result and result.stderr) or "session.select failed", 0)
		end
	else
		rex.client.queue("session.select", { session_id = session_id })
	end
end

-- The session last shown on each machine ("" = this server), so switching
-- machines returns where you were. It also covers this server's sessions when
-- they can't be listed from a remote session. Reset by a config reload.
local last_session = {}
local function remember(ctx)
	if ctx.session_id then
		last_session[ctx.server or ""] = ctx.session_id
	end
end

local function host_api(server)
	return server and rex.server(server) or rex
end

local function local_session_ids(ctx)
	if not ctx.server then
		return session_ids(rex)
	end
	local cli = rex_cli()
	local result = cli and rex.exec({ cli, "ls", "--json", "--short=false" }, { timeout = 3 })
	local ok, listed = pcall(rex.json.decode, result and result.ok and result.stdout or "")
	local ids = {}
	for _, s in ipairs((ok and listed and listed.sessions) or {}) do
		table.insert(ids, s.session_id)
	end
	return ids
end

rex.action({
	name = "session_goto",
	title = "Go to Session by Number on This Machine",
	args = { index = "integer" },
	run = function(ctx, args)
		-- rex.call already targets the session's host.
		local session_id = session_ids(rex)[args.index]
		if session_id then
			remember(ctx)
			select_session(ctx, ctx.server, session_id)
		end
	end,
})

rex.action({
	name = "host_next",
	title = "Go to Next Machine",
	run = function(ctx)
		remember(ctx)
		local hosts = { false }
		for _, label in ipairs(rex.servers and rex.servers() or {}) do
			table.insert(hosts, label)
		end
		local current = 1
		for i, host in ipairs(hosts) do
			if host == (ctx.server or false) then
				current = i
			end
		end
		-- Try each other machine in turn, skipping ones without sessions.
		for step = 1, #hosts - 1 do
			local host = hosts[(current - 1 + step) % #hosts + 1] or nil
			local ids = host and session_ids(host_api(host)) or local_session_ids(ctx)
			local target = last_session[host or ""]
			local known = not ids[1] -- can't list: trust the remembered one
			for _, id in ipairs(ids) do
				known = known or id == target
			end
			target = (target and known) and target or ids[1]
			if target then
				select_session(ctx, host, target)
				return
			end
		end
		if #hosts > 1 then
			error("no other machine with a known session; switch from this Mac once first", 0)
		end
	end,
})

for index = 1, 9 do
	rex.bind("ctrl+" .. index, "session_goto", { index = index })
end
rex.bind("ctrl+space>tab", "host_next")

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
		-- This Lua runs on the server that owns the keymap (the Mac's, when
		-- the Mac app is attached to a remote host), but the layer's command
		-- runs on the session's host. Resolve the path there, not here.
		local command = {
			"sh",
			"-c",
			'exec python3 "${XDG_CONFIG_HOME:-$HOME/.config}/rex/sesh-picker.py" "$@"',
			"sesh-picker",
		}
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

-- The local directory a pane is working in, or nil. Reads the foreground
-- process's real cwd rather than the OSC 7 report, which a remote shell can
-- send too. For a pane running ssh, that is where ssh was started.
local function block_dir(sid, block_id)
	local p = block_id and rex.call("block.method", { session_id = sid, block_id = block_id, method = "process" })
	local fg = p and (p.foreground or p.child)
	return fg and fg.cwd
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
			-- Start in the focused pane's directory. Later toggles leave it
			-- wherever it was.
			local dir = block_dir(sid, here.focused_block_id)
			must(rex.session.new_layer({
				window_id = here.window_id,
				bounds = QUICK_TERMINAL_BOUNDS,
				focus = true,
				layout = rex.layout.block({
					flavor = "com.superlogical.terminal.shell",
					label = QUICK_TERMINAL_LABEL,
					options = { cwd = dir },
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
