-- app specific bindings
local app_bind_handlers = {}

local function app_bind(app_name, modifiers, key, fn)
    local handler = hs.hotkey.bind(modifiers, key, fn)
    if app_bind_handlers[app_name] == nil then
        app_bind_handlers[app_name] = {}
    end
    table.insert(app_bind_handlers[app_name], handler)
end

-- to make scratchpad work better
app_bind("Messenger", { "cmd" }, "w", function()
    local app = hs.application.frontmostApplication()
    local num_windows = #app:allWindows()
    if num_windows == 1 then
        app:hide()
    else
        app:focusedWindow():close()
    end
end)

---@diagnostic disable-next-line: unused-local
App_watcher = hs.application.watcher.new(function(app_name, event_type, app)
    if event_type == hs.application.watcher.activated then
        for name, handlers in pairs(app_bind_handlers) do
            if name == app_name then
                for _, handler in ipairs(handlers) do
                    handler:enable()
                end
            else
                for _, handler in ipairs(handlers) do
                    handler:disable()
                end
            end
        end
    elseif event_type == hs.application.watcher.deactivated then
        if app_bind_handlers[app_name] == nil then
            return
        end
        for _, handler in ipairs(app_bind_handlers[app_name]) do
            handler:disable()
        end
    end
end)
App_watcher:start()
