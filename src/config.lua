-- Configuration for BreakSync

local addonName, BS = ...

BS.name = addonName
BS.title = C_AddOns.GetAddOnMetadata(addonName, "Title")
BS.version = C_AddOns.GetAddOnMetadata(addonName, "Version")

BS.defaultSettings = {
    debug        = false,
    barWidth     = 420,
    barHeight    = 30,
    barPoint     = "CENTER",
    barX         = 0,
    barY         = 140,
    -- appearance
    barR         = 0.1,
    barG         = 0.6,
    barB         = 0.1,
    barAlpha     = 0.85,
    barFontSize  = 14,
    barShowIcon  = true,
}

-- Style presets: {r, g, b, alpha, width, height, fontSize, showIcon}
BS.stylePresets = {
    BreakSync = { r=0.1,  g=0.6,  b=0.1,  alpha=0.85, width=420, height=30, fontSize=14, showIcon=true  },
    BigWigs   = { r=0.33, g=0.33, b=0.93, alpha=0.80, width=180, height=18, fontSize=10, showIcon=true  },
    DBM       = { r=0.1,  g=0.8,  b=0.1,  alpha=0.80, width=183, height=20, fontSize=13, showIcon=false },
}

function BS.InitConfig()
    BreakSyncDB = BreakSyncDB or {}

    for key, value in pairs(BS.defaultSettings) do
        if BreakSyncDB[key] == nil then
            BreakSyncDB[key] = value
        end
    end
end
