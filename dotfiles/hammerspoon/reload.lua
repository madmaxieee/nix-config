local ReloadConfiguration = hs.loadSpoon("ReloadConfiguration")
ReloadConfiguration.watch_paths = { hs.configdir }
ReloadConfiguration:start()
