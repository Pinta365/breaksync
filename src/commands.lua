-- Slash commands for BreakSync

local addonName, BS = ...

StaticPopupDialogs["BREAKSYNC_RESET_CONFIRM"] = {
    text = "Reset all BreakSync settings to defaults and reload the UI?",
    button1 = "Reset",
    button2 = "Cancel",
    OnAccept = function()
        wipe(BreakSyncDB)
        ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

-- In 12.0 addon messages are blocked while a mythic keystone run, a PvP match or an
-- instance encounter is in progress. SendAddonMessage doesn't error — it returns this code.
local LOCKDOWN_RESULT = Enum.SendAddonMessageResult and Enum.SendAddonMessageResult.AddOnMessageLockdown

-- Break timer that was blocked by a lockdown, waiting for the restriction to lift.
local pendingSeconds = nil

-- Returns true if the message reached the group. The local bar is started by the caller
-- either way, so a blocked send degrades to a local-only timer rather than nothing.
local function SendBreakToGroup(seconds, quiet)
    if not IsInGroup() then return end
    local name = UnitName("player")
    local realm = GetRealmName():gsub("[%s%-]+", "")
    local msg = string.format("%s-%s\t1\tBT\t%d", name, realm, seconds)
    local channel = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "RAID"
    local result = C_ChatInfo.SendAddonMessage("D5", msg, channel)

    if type(result) ~= "number" or result == 0 then
        pendingSeconds = nil
        return true
    end

    BS.Debug("SendAddonMessage failed, error:", result)

    if LOCKDOWN_RESULT and result == LOCKDOWN_RESULT then
        pendingSeconds = seconds
        if not quiet then
            print("|cff45D388[BreakSync]|r |cffFFD100Can't sync a break timer during an encounter, keystone or PvP match|r — showing it locally only. It will be sent when the restriction lifts.")
        end
    elseif not quiet then
        print(string.format("|cff45D388[BreakSync]|r |cffFF4444Couldn't send the break timer to your group|r (error %d) — showing it locally only.", result))
    end
    return false
end

-- Retry a blocked break timer once addon comms are allowed again.
local function ResendPendingBreak()
    local seconds = pendingSeconds
    if not seconds then return end
    pendingSeconds = nil

    if seconds > 0 then
        -- Send what's actually left, not the original duration.
        local tbl = BreakSyncDB and BreakSyncDB.breakTime
        if not tbl or not BS.IsBarRunning() then return end  -- break already ended or was cancelled
        seconds = math.floor(tbl[2] - (time() - tbl[1]))
        if seconds < 1 then return end
    elseif BS.IsBarRunning() then
        -- A blocked cancel, but a bar is running now — that's a newer break, possibly
        -- someone else's. Don't propagate a stale cancel to the group.
        return
    end

    if SendBreakToGroup(seconds, true) then
        print("|cff45D388[BreakSync]|r Restriction lifted — break timer sent to your group.")
    end
end

if Enum.AddOnRestrictionState then
    local restrictionFrame = CreateFrame("Frame")
    restrictionFrame:RegisterEvent("ADDON_RESTRICTION_STATE_CHANGED")
    restrictionFrame:SetScript("OnEvent", function(_, _, _, state)
        -- IsAddOnRestrictionActive always reports false during this event's dispatch,
        -- so trust the state payload instead of re-querying it here.
        if state == Enum.AddOnRestrictionState.Inactive then
            ResendPendingBreak()
        end
    end)
end

local function CanStartBreak()
    if not IsInGroup() then return true end
    return UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
end

function BS.InitCommands()
    local function printHelp()
        local c = "|cff45D388[BreakSync]|r"
        local cmd = "|cffFFFFFF"
        local sep = "|r — "
        print(c .. " commands |cff888888(/bs or /breaksync)|r:")
        print(cmd .. "/bs break <min>" .. sep .. "start a break timer (1-60 min)")
        print(cmd .. "/bs stop"        .. sep .. "cancel the current break timer")
        print(cmd .. "/bs test"        .. sep .. "show a 5-minute test bar")
        print(cmd .. "/bs debug"       .. sep .. "toggle debug output")
        print(cmd .. "/bs reset"       .. sep .. "reset settings to defaults")
    end

    SlashCmdList["BREAKSYNC"] = function(msg)
        local cmd, arg = msg:match("^%s*(%S*)%s*(.-)%s*$")
        cmd = cmd:lower()

        if cmd == "break" then
            if not CanStartBreak() then
                print("|cff45D388[BreakSync]|r Requires raid leader or assist.")
                return
            end
            local minutes = tonumber(arg)
            if not minutes or minutes < 1 or minutes > 60 then
                print("|cff45D388[BreakSync]|r Usage: /bs break <minutes> (1–60)")
                return
            end
            local seconds = math.floor(minutes * 60)
            BS.StartBreakBar(seconds, UnitName("player"))
            print(string.format("|cff45D388[BreakSync]|r Break timer started — %d min", minutes))
            SendBreakToGroup(seconds)

        elseif cmd == "stop" then
            if not CanStartBreak() then
                print("|cff45D388[BreakSync]|r Requires raid leader or assist.")
                return
            end
            BS.StopBreakBar()
            print("|cff45D388[BreakSync]|r Break timer cancelled.")
            if IsInGroup() then
                SendBreakToGroup(0)
            end

        elseif cmd == "test" then
            BS.StartBreakBar(300, UnitName("player"), true)
            print("|cff45D388[BreakSync]|r Test break bar shown (5 min).")

        elseif cmd == "debug" then
            BreakSyncDB.debug = not BreakSyncDB.debug
            print("|cff45D388[BreakSync]|r Debug", BreakSyncDB.debug and "|cff00FF00ON|r" or "|cffFF4444OFF|r")

        elseif cmd == "reset" then
            StaticPopup_Show("BREAKSYNC_RESET_CONFIRM")

        else
            printHelp()
        end
    end

    SLASH_BREAKSYNC1 = "/breaksync"
    SLASH_BREAKSYNC2 = "/bs"
end
