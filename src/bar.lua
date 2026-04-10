-- Break timer bar for BreakSync

local addonName, BS = ...

local BREAK_ICON = 134062  -- Interface\Icons\inv_misc_fork&knife

local bar = nil
local totalSeconds = 0
local elapsedSeconds = 0
local running = false

local function SecondsToString(s)
    s = math.max(0, s)
    if s >= 60 then
        return string.format("%d:%02d", math.floor(s / 60), s % 60)
    end
    return tostring(math.ceil(s))
end

local function OnUpdate(self, dt)
    if not running then return end
    elapsedSeconds = elapsedSeconds + dt
    local remaining = totalSeconds - elapsedSeconds
    if remaining <= 0 then
        running = false
        self:SetScript("OnUpdate", nil)
        bar.frame:Hide()
        BreakSyncDB.breakTime = nil
        return
    end
    bar.statusbar:SetValue(remaining)
    bar.timeText:SetText(SecondsToString(remaining))
end

function BS.StartBreakBar(seconds, nick, reboot)
    if not bar then return end

    totalSeconds = seconds
    elapsedSeconds = 0
    running = true

    if not reboot then
        BreakSyncDB.breakTime = {time(), seconds, nick}
    end

    local db = BreakSyncDB
    bar.statusbar:SetMinMaxValues(0, seconds)
    bar.statusbar:SetValue(seconds)
    bar.timeText:SetText(SecondsToString(seconds))
    bar.nickText:SetText(nick and ("|cffaaaaaa" .. Ambiguate(nick, "short") .. "|r") or "")

    bar.frame:SetScript("OnUpdate", OnUpdate)
    bar.frame:Show()
    BS.Debug("Break timer started:", seconds, "sec by", nick)
end

function BS.StopBreakBar()
    running = false
    if bar then
        bar.frame:SetScript("OnUpdate", nil)
        bar.frame:Hide()
    end
    BreakSyncDB.breakTime = nil
    BS.Debug("Break timer stopped")
end

function BS.ResumeBreakBar()
    if not BreakSyncDB then return end
    local tbl = BreakSyncDB.breakTime
    if not tbl then return end
    local startTimestamp, totalSec, nick = tbl[1], tbl[2], tbl[3]
    local remaining = totalSec - (time() - startTimestamp)
    if remaining <= 0 then
        BreakSyncDB.breakTime = nil
        BS.Debug("Saved break timer has expired, clearing.")
        return
    end
    BS.StartBreakBar(remaining, nick, true)
    BS.Debug("Resumed break bar:", math.ceil(remaining), "sec remaining")
end

function BS.IsBarRunning()
    return running
end

function BS.InitBar()
    if bar then return end

    local db = BreakSyncDB
    local W = db.barWidth
    local H = db.barHeight
    local ICON_SIZE = H - 2

    -- Outer container
    local f = CreateFrame("Frame", "BreakSyncBar", UIParent, "BackdropTemplate")
    f:SetSize(W, H + 2)
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(100)
    f:SetClampedToScreen(true)
    f:SetPoint(db.barPoint, UIParent, db.barPoint, db.barX, db.barY)

    f:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile     = false,
        edgeSize = 1,
    })
    f:SetBackdropColor(0, 0, 0, 0.85)
    f:SetBackdropBorderColor(0.15, 0.15, 0.15, 1)

    -- Drag to reposition
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        BreakSyncDB.barPoint = point
        BreakSyncDB.barX = math.floor(x + 0.5)
        BreakSyncDB.barY = math.floor(y + 0.5)
        BS.Debug("Bar moved to", point, x, y)
    end)

    -- Icon (left edge)
    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("LEFT", f, "LEFT", 2, 0)
    icon:SetTexture(BREAK_ICON)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- StatusBar (fills the rest of the frame)
    local sb = CreateFrame("StatusBar", nil, f)
    sb:SetPoint("LEFT", icon, "RIGHT", 2, 0)
    sb:SetPoint("RIGHT", f, "RIGHT", -2, 0)
    sb:SetHeight(H)
    sb:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    sb:SetStatusBarColor(0.1, 0.6, 0.1, 1)
    sb:SetMinMaxValues(0, 1)
    sb:SetValue(1)

    -- StatusBar background fill
    local sbBg = sb:CreateTexture(nil, "BACKGROUND", nil, -8)
    sbBg:SetAllPoints(sb)
    sbBg:SetColorTexture(0.05, 0.05, 0.05, 1)

    -- "Break time" label (left)
    local label = sb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", sb, "LEFT", 8, 0)
    label:SetText("Break time")
    label:SetShadowOffset(1, -1)

    -- Sender name (right of label, muted color)
    local nickText = sb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nickText:SetPoint("LEFT", label, "RIGHT", 6, 0)
    nickText:SetText("")

    -- Time remaining (right side)
    local timeText = sb:CreateFontString(nil, "OVERLAY")
    timeText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    timeText:SetPoint("RIGHT", sb, "RIGHT", -8, 0)
    timeText:SetText("")

    f:Hide()

    bar = {
        frame     = f,
        icon      = icon,
        statusbar = sb,
        label     = label,
        nickText  = nickText,
        timeText  = timeText,
    }
end
