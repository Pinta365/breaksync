-- Options panel for BreakSync

local addonName, BS = ...

local INDENT = 16
local SECTION_GAP = 24
local AFTER_HEADER = 15
local ROW_CHECK = 28

local function sectionHeader(parent, label, yOffset)
    local fs = parent:CreateFontString(nil, "overlay", "GameFontNormal")
    fs:SetPoint("TOPLEFT", INDENT, yOffset)
    fs:SetText(label)
    local line = parent:CreateTexture(nil, "BACKGROUND")
    line:SetColorTexture(0.4, 0.4, 0.4, 0.6)
    line:SetHeight(1)
    line:SetPoint("LEFT", fs, "RIGHT", 6, 0)
    line:SetPoint("RIGHT", parent, "RIGHT", -INDENT, 0)
    return yOffset - AFTER_HEADER
end

local function checkbox(parent, label, yOffset)
    local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", INDENT, yOffset)
    cb.Text:SetText(label)
    cb.Text:SetFontObject("GameFontHighlightSmall")
    return cb, yOffset - ROW_CHECK
end

local function initOptionsPanel()
    local parent = (Settings and Settings.RegisterCanvasLayoutCategory) and UIParent or nil
    local panel = CreateFrame("Frame", "BreakSyncOptionsPanel", parent)
    panel.name = "BreakSync"

    local header = panel:CreateFontString(nil, "overlay", "GameFontHighlightLarge")
    header:SetPoint("TOPLEFT", INDENT, -INDENT)
    header:SetText("|cff45D388BreakSync|r  |cff888888v" .. (BS.version or "?") .. "|r")

    local y = -46

    -- General section
    y = sectionHeader(panel, "General", y - SECTION_GAP)

    local debugCb
    debugCb, y = checkbox(panel, "Show debug messages", y)
    debugCb:SetScript("OnClick", function(self)
        BreakSyncDB.debug = self:GetChecked()
    end)

    -- Bar section
    y = sectionHeader(panel, "Break Bar", y - SECTION_GAP)

    local hint = panel:CreateFontString(nil, "overlay", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", INDENT, y)
    hint:SetText("Drag the bar on screen to reposition it.")
    hint:SetTextColor(0.7, 0.7, 0.7)
    y = y - 28

    local testBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    testBtn:SetSize(160, 22)
    testBtn:SetPoint("TOPLEFT", INDENT, y)
    testBtn:SetText("Test Break Bar (5 min)")
    testBtn:SetScript("OnClick", function()
        BS.StartBreakBar(300, UnitName("player"))
    end)
    y = y - 34

    local stopBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    stopBtn:SetSize(120, 22)
    stopBtn:SetPoint("TOPLEFT", INDENT, y)
    stopBtn:SetText("Stop Bar")
    stopBtn:SetScript("OnClick", function()
        BS.StopBreakBar()
    end)
    y = y - 44

    -- Reset section
    y = sectionHeader(panel, "Settings", y - SECTION_GAP)

    local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetBtn:SetSize(140, 22)
    resetBtn:SetPoint("TOPLEFT", INDENT, y)
    resetBtn:SetText("Reset to Defaults")
    resetBtn:SetScript("OnClick", function()
        StaticPopup_Show("BREAKSYNC_RESET_CONFIRM")
    end)

    local function RefreshOptions()
        debugCb:SetChecked(BreakSyncDB.debug == true)
    end

    panel:SetScript("OnShow", RefreshOptions)
    RefreshOptions()

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        BS.settingsCategory = category
    else
        InterfaceOptions_AddCategory(panel)
        BS.optionsPanel = panel
    end
end

function BS.InitOptions()
    initOptionsPanel()
end
