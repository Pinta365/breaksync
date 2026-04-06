-- Configuration for BreakSync

local addonName, BS = ...

BS.name = addonName
BS.title = C_AddOns.GetAddOnMetadata(addonName, "Title")
BS.version = C_AddOns.GetAddOnMetadata(addonName, "Version")

BS.defaultSettings = {
    debug    = false,
    barWidth  = 420,
    barHeight = 30,
    barPoint  = "CENTER",
    barX      = 0,
    barY      = 140,
}

function BS.InitConfig()
    BreakSyncDB = BreakSyncDB or {}

    for key, value in pairs(BS.defaultSettings) do
        if BreakSyncDB[key] == nil then
            BreakSyncDB[key] = value
        end
    end
end
