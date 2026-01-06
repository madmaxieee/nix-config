ToggleAppScratchpad = require("scratchpad").toggle_app_scratchpad

function BundleId(hint)
    return hs.application.find(hint):bundleID()
end
