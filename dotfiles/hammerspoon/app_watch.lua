local M = {}

local app_watch_handlers = {}

---@param app_name string
---@param modifiers string[]
---@param key string
---@param fn fun(app: hs.application)
function M.app_bind(app_name, modifiers, key, fn)
    local handler = hs.hotkey.bind(modifiers, key, function()
        local app = hs.application.frontmostApplication()
        if app and app:name() == app_name then
            fn(app)
        end
    end)
    if app_watch_handlers[app_name] == nil then
        app_watch_handlers[app_name] = {}
    end
    table.insert(app_watch_handlers[app_name], handler)
end

---@param app_name string
---@param fn fun(app: hs.application)
function M.on_activated(app_name, fn)
    local handler = {
        enable = function()
            local app = hs.application.find(app_name, true)
            if app then
                fn(app)
            end
        end,
        disable = function() end,
    }
    if app_watch_handlers[app_name] == nil then
        app_watch_handlers[app_name] = {}
    end
    table.insert(app_watch_handlers[app_name], handler)
end

---@param app_name string
---@param fn fun(app: hs.application)
function M.on_deactivated(app_name, fn)
    local handler = {
        enable = function() end,
        disable = function()
            local app = hs.application.find(app_name, true)
            if app then
                fn(app)
            end
        end,
    }
    if app_watch_handlers[app_name] == nil then
        app_watch_handlers[app_name] = {}
    end
    table.insert(app_watch_handlers[app_name], handler)
end

---@param app_name string
---@param event_type any
---@param app hs.application
---@diagnostic disable-next-line: unused-local
AppBindAppWatcher = hs.application.watcher.new(function(app_name, event_type, app)
    if event_type == hs.application.watcher.activated then
        for name, handlers in pairs(app_watch_handlers) do
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
        if app_watch_handlers[app_name] == nil then
            return
        end
        for _, handler in ipairs(app_watch_handlers[app_name]) do
            handler:disable()
        end
    end
end)
AppBindAppWatcher:start()

return M
