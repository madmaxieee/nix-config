hs.loadSpoon "EmmyLua"

require "hs.ipc"
require "reload"

pcall(require, "nix_path")

NIX_PATH = NIX_PATH or nil
if NIX_PATH then
    PATH = table.concat({ NIX_PATH, "/opt/homebrew/bin", os.getenv "PATH" }, ":")
else
    PATH = table.concat({ "/opt/homebrew/bin", os.getenv "PATH" }, ":")
end

hs.application.enableSpotlightForNameSearches(true)

hs.window.animationDuration = 0

require "bindings"
require "globals"
