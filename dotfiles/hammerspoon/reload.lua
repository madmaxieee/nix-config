local ReloadConfiguration = hs.loadSpoon "ReloadConfiguration"
if ReloadConfiguration then
    ReloadConfiguration.watch_paths = { hs.configdir }
    ReloadConfiguration:start()
end
