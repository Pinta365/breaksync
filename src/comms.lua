-- Comms for BreakSync — listens for break timers from DBM and BigWigs

local addonName, BS = ...

-- Both BigWigs and DBM use the "D5" addon message prefix for break timers.
-- Message format: "{Name}-{Realm}\t{version}\tBT\t{seconds}"
-- seconds == 0 means cancel.
local DBM_PREFIX = "D5"

local lastBreak = 0  -- simple throttle

local function OnBreakMessage(seconds, sender)
    if seconds <= 0 then
        BS.StopBreakBar()
        return
    end
    if seconds < 60 or seconds > 3600 then return end  -- 1 min – 1 hr

    local now = GetTime()
    if now - lastBreak < 0.5 then return end  -- throttle duplicate fires
    lastBreak = now

    BS.StartBreakBar(seconds, sender)
    print(string.format("|cff45D388[BreakSync]|r Break timer started by |cffFFFFFF%s|r — %d min",
        Ambiguate(sender or "unknown", "short"),
        math.ceil(seconds / 60)))
end

-- CHAT_MSG_ADDON handler (D5 prefix = DBM protocol, used by both DBM and BigWigs)
local commsFrame = CreateFrame("Frame")

commsFrame:SetScript("OnEvent", function(self, event, prefix, msg, channel, sender)
    if event ~= "CHAT_MSG_ADDON" then return end
    if prefix ~= DBM_PREFIX then return end

    -- Format: "Name-Realm\tVersion\tCommand\tValue"
    local _, _, cmd, value = strsplit("\t", msg)
    if cmd ~= "BT" then return end

    local seconds = tonumber(value)
    if not seconds then return end
    OnBreakMessage(seconds, sender)
end)

-- Register to receive D5 addon messages from BigWigs/DBM
local function RegisterCommsPrefix()
    local ok = C_ChatInfo.RegisterAddonMessagePrefix(DBM_PREFIX)
    if not ok then
        BS.Debug("Warning: could not register addon prefix", DBM_PREFIX)
    end
    commsFrame:RegisterEvent("CHAT_MSG_ADDON")
end

-- Optional BigWigs callback hook — catches local break timers when BigWigs is installed.
-- BigWigs fires BigWigs_StartBreak even in solo, before any addon message is sent.
local function HookBigWigs()
    if not BigWigsLoader or not BigWigsLoader.RegisterMessage then return end

    BigWigsLoader.RegisterMessage("BreakSync", "BigWigs_StartBreak", function(_, module, seconds, nick, isDBM, reboot)
        if reboot then return end  -- resuming from a reload — BigWigs already has the bar
        if seconds and seconds > 0 then
            OnBreakMessage(seconds, nick)
        end
    end)

    BigWigsLoader.RegisterMessage("BreakSync", "BigWigs_StopBreak", function()
        BS.StopBreakBar()
    end)

    BS.Debug("BigWigs callback hooks registered")
end

function BS.InitComms()
    RegisterCommsPrefix()

    -- BigWigs may or may not be loaded yet; hook if available now,
    -- and also watch for it loading after BreakSync.
    HookBigWigs()

    -- Watch for BigWigs loading after us
    local watchFrame = CreateFrame("Frame")
    watchFrame:RegisterEvent("ADDON_LOADED")
    watchFrame:SetScript("OnEvent", function(self, event, name)
        if name == "BigWigs" then
            HookBigWigs()
            self:UnregisterEvent("ADDON_LOADED")
        end
    end)

    BS.Debug("Comms initialized — listening on prefix:", DBM_PREFIX)
end
