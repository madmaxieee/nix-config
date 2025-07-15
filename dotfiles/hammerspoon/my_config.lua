local M = {
    message_app = "Messenger",
    browser = "Arc",
    note_app = "Heptabase",
    terminal_app = "kitty",
    ai_app = "",
}

local extra_config = {}

local success, _ = pcall(function()
    extra_config = require "extra_config"
end)

if not success then
    return M
end

for key, _ in pairs(M) do
    if extra_config[key] then
        M[key] = extra_config[key]
    end
    if M[key] == "" then
        M[key] = nil
    end
end

return M
