ToggleScratchpad = require("scratchpad").toggle_scratchpad

function BundleId(hint)
    return hs.application.find(hint):bundleID()
end
