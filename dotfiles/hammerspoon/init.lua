require("hs.ipc")
require("reload")

pcall(require, "nix_path")
NIX_PATH = NIX_PATH or ""
PATH = NIX_PATH .. ":" .. os.getenv("PATH")

hs.application.enableSpotlightForNameSearches(true)

Wallpaper = require("wallpaper")
ToggleScratchpad = require("scratchpad")

require("bindings")
require("app_bindings")
