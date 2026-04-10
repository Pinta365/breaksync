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

local function SendBreakToGroup(seconds)
    if not IsInGroup() then return end
    local name = UnitName("player")
    local realm = GetRealmName():gsub("[%s%-]+", "")
    local msg = string.format("%s-%s\t1\tBT\t%d", name, realm, seconds)
    local channel = IsInGroup(2) and "INSTANCE_CHAT" or "RAID"
    local result = C_ChatInfo.SendAddonMessage("D5", msg, channel)
    if type(result) == "number" and result ~= 0 then
        BS.Debug("SendAddonMessage failed, error:", result)
    end
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
