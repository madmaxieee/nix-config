local M = {
    message_app = "Messenger",
    browser = "Arc",
    note_app = "Heptabase",
}

local extra_config = {}

local success, _ = pcall(function()
    extra_config = require("extra_config")
end)

if not success then
    return M
end

for key, _ in pairs(M) do
    print(key .. " " .. extra_config[key])
    if extra_config[key] ~= nil then
        M[key] = extra_config[key]
    end
end

return M
