-- BreakSync — Break timer bar that works without DBM or BigWigs.
-- Listens for break timers from BigWigs (BigWigs_StartBreak) and DBM (D5/BT protocol).

local addonName, BS = ...

local frame = CreateFrame("Frame", "BreakSyncFrame")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" and name == addonName then
        BS.InitConfig()
        BS.InitBar()
        BS.InitComms()
        BS.InitOptions()
        BS.InitCommands()
        print("|cff45D388[BreakSync]|r v" .. BS.version .. " loaded. Type |cffFFFFFF/bs|r for commands.")
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
