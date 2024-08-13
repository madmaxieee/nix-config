local ReloadConfiguration = hs.loadSpoon("ReloadConfiguration")
local home = os.getenv("HOME")
ReloadConfiguration.watch_paths = {
    hs.configdir,
    home .. "/dotfiles/.hammerspoon",
}
ReloadConfiguration:start()
