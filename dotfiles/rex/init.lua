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
rex.bind("ctrl+space>s", "session.switch")
