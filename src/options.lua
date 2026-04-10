-- Options panel for BreakSync

local addonName, BS = ...

local INDENT = 16
local SECTION_GAP = 24
local AFTER_HEADER = 15
local ROW_CHECK = 28
local ROW_SLIDER = 50

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

-- Creates a labelled slider. Returns slider, yOffset-after.
-- min/max/step are numeric. formatFn(val) → string for the value label.
local function makeSlider(parent, label, yOffset, minVal, maxVal, step, formatFn)
    local ROW = ROW_SLIDER

    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lbl:SetPoint("TOPLEFT", INDENT, yOffset)
    lbl:SetText(label)

    local valLbl = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    valLbl:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -INDENT, yOffset)
    valLbl:SetText("")

    local sl = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    sl:SetPoint("TOPLEFT", INDENT, yOffset - 14)
    sl:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -INDENT - 60, yOffset - 14)
    sl:SetMinMaxValues(minVal, maxVal)
    sl:SetValueStep(step)
    sl:SetObeyStepOnDrag(true)
    sl.Low:SetText(formatFn(minVal))
    sl.High:SetText(formatFn(maxVal))

    sl:SetScript("OnValueChanged", function(self, val)
        valLbl:SetText(formatFn(val))
    end)

    return sl, valLbl, yOffset - ROW
end

-- Small inline color swatch button
local function colorSwatch(parent, r, g, b, yOffset, xOffset, onChange)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(20, 20)
    btn:SetPoint("TOPLEFT", xOffset, yOffset + 3)

    local border = btn:CreateTexture(nil, "BACKGROUND")
    border:SetAllPoints()
    border:SetColorTexture(0, 0, 0, 1)

    local bg = btn:CreateTexture(nil, "ARTWORK")
    bg:SetPoint("TOPLEFT", 1, -1)
    bg:SetPoint("BOTTOMRIGHT", -1, 1)
    bg:SetColorTexture(r, g, b, 1)
    btn.bg = bg

    btn:SetScript("OnClick", function(self)
        local r0, g0, b0 = self.bg:GetVertexColor()
        ColorPickerFrame:SetupColorPickerAndShow({
            r           = r0,
            g           = g0,
            b           = b0,
            hasOpacity  = false,
            swatchFunc  = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                self.bg:SetColorTexture(nr, ng, nb, 1)
                onChange(nr, ng, nb)
            end,
            cancelFunc  = function()
                self.bg:SetColorTexture(r0, g0, b0, 1)
                onChange(r0, g0, b0)
            end,
        })
    end)

    function btn:SetSwatch(nr, ng, nb)
        self.bg:SetColorTexture(nr, ng, nb, 1)
    end

    return btn
end

local function initOptionsPanel()
    local parent = (Settings and Settings.RegisterCanvasLayoutCategory) and UIParent or nil
    local panel = CreateFrame("Frame", "BreakSyncOptionsPanel", parent)
    panel.name = "BreakSync"

    local header = panel:CreateFontString(nil, "overlay", "GameFontHighlightLarge")
    header:SetPoint("TOPLEFT", INDENT, -INDENT)
    header:SetText("|cff45D388BreakSync|r  |cff888888v" .. (BS.version or "?") .. "|r")

    local y = -46

    -- ── General ──────────────────────────────────────────────────────────────
    y = sectionHeader(panel, "General", y - SECTION_GAP)

    local debugCb
    debugCb, y = checkbox(panel, "Show debug messages", y)
    debugCb:SetScript("OnClick", function(self)
        BreakSyncDB.debug = self:GetChecked()
    end)

    -- ── Break Bar ─────────────────────────────────────────────────────────────
    y = sectionHeader(panel, "Break Bar", y - SECTION_GAP)

    local hint = panel:CreateFontString(nil, "overlay", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", INDENT, y)
    hint:SetText("Drag the bar on screen to reposition it.")
    hint:SetTextColor(0.7, 0.7, 0.7)
    y = y - 24

    local testBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    testBtn:SetSize(160, 22)
    testBtn:SetPoint("TOPLEFT", INDENT, y)
    testBtn:SetText("Test Break Bar (5 min)")
    testBtn:SetScript("OnClick", function()
        BS.StartBreakBar(300, UnitName("player"), true)
    end)

    local stopBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    stopBtn:SetSize(100, 22)
    stopBtn:SetPoint("LEFT", testBtn, "RIGHT", 8, 0)
    stopBtn:SetText("Stop Bar")
    stopBtn:SetScript("OnClick", function()
        BS.StopBreakBar()
    end)
    y = y - 36

    -- Width slider
    local widthSlider, widthLbl
    widthSlider, widthLbl, y = makeSlider(panel, "Bar Width", y, 150, 700, 10, function(v) return math.floor(v) .. "px" end)
    widthSlider:SetScript("OnValueChanged", function(self, val)
        val = math.floor(val / 10 + 0.5) * 10
        widthLbl:SetText(val .. "px")
        BreakSyncDB.barWidth = val
        BS.RefreshBarAppearance()
    end)

    -- Height slider
    local heightSlider, heightLbl
    heightSlider, heightLbl, y = makeSlider(panel, "Bar Height", y, 14, 60, 2, function(v) return math.floor(v) .. "px" end)
    heightSlider:SetScript("OnValueChanged", function(self, val)
        val = math.floor(val / 2 + 0.5) * 2
        heightLbl:SetText(val .. "px")
        BreakSyncDB.barHeight = val
        BS.RefreshBarAppearance()
    end)

    -- Font size slider
    local fontSlider, fontLbl
    fontSlider, fontLbl, y = makeSlider(panel, "Font Size", y, 10, 22, 1, function(v) return math.floor(v) .. "pt" end)
    fontSlider:SetScript("OnValueChanged", function(self, val)
        val = math.floor(val + 0.5)
        fontLbl:SetText(val .. "pt")
        BreakSyncDB.barFontSize = val
        BS.RefreshBarAppearance()
    end)

    -- Background opacity slider
    local alphaSlider, alphaLbl
    alphaSlider, alphaLbl, y = makeSlider(panel, "Background Opacity", y, 0, 1, 0.05, function(v) return math.floor(v * 100 + 0.5) .. "%" end)
    alphaSlider:SetScript("OnValueChanged", function(self, val)
        val = math.floor(val / 0.05 + 0.5) * 0.05
        alphaLbl:SetText(math.floor(val * 100 + 0.5) .. "%")
        BreakSyncDB.barAlpha = val
        BS.RefreshBarAppearance()
    end)

    -- Color swatch + label
    local colorLbl = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colorLbl:SetPoint("TOPLEFT", INDENT, y)
    colorLbl:SetText("Bar Color")
    y = y - 18

    local swatch = colorSwatch(panel, 0.1, 0.6, 0.1, y, INDENT, function(r, g, b)
        BreakSyncDB.barR, BreakSyncDB.barG, BreakSyncDB.barB = r, g, b
        BS.RefreshBarAppearance()
    end)
    y = y - 30

    -- Show icon checkbox
    local iconCb
    iconCb, y = checkbox(panel, "Show break icon", y)
    iconCb:SetScript("OnClick", function(self)
        BreakSyncDB.barShowIcon = self:GetChecked()
        BS.RefreshBarAppearance()
    end)
    y = y - 4

    -- ── Style Presets ─────────────────────────────────────────────────────────
    y = sectionHeader(panel, "Style Presets", y - SECTION_GAP)

    local presetLbl = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    presetLbl:SetPoint("TOPLEFT", INDENT, y)
    presetLbl:SetText("Apply a preset style:")
    presetLbl:SetTextColor(0.7, 0.7, 0.7)
    y = y - 26

    local function applyPreset(name)
        local p = BS.stylePresets[name]
        if not p then return end
        BreakSyncDB.barR, BreakSyncDB.barG, BreakSyncDB.barB = p.r, p.g, p.b
        BreakSyncDB.barAlpha    = p.alpha
        BreakSyncDB.barWidth    = p.width
        BreakSyncDB.barHeight   = p.height
        BreakSyncDB.barFontSize = p.fontSize
        BreakSyncDB.barShowIcon = p.showIcon
        BS.RefreshBarAppearance()
        -- refresh all controls
        widthSlider:SetValue(p.width)
        heightSlider:SetValue(p.height)
        fontSlider:SetValue(p.fontSize)
        alphaSlider:SetValue(p.alpha)
        swatch:SetSwatch(p.r, p.g, p.b)
        iconCb:SetChecked(p.showIcon)
    end

    local presetNames = {"BreakSync", "BigWigs", "DBM"}
    local prevBtn = nil
    for _, name in ipairs(presetNames) do
        local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        btn:SetSize(90, 22)
        if prevBtn then
            btn:SetPoint("LEFT", prevBtn, "RIGHT", 8, 0)
        else
            btn:SetPoint("TOPLEFT", INDENT, y)
        end
        btn:SetText(name)
        btn:SetScript("OnClick", function() applyPreset(name) end)
        prevBtn = btn
    end
    y = y - 36

    -- ── Settings ──────────────────────────────────────────────────────────────
    y = sectionHeader(panel, "Settings", y - SECTION_GAP)

    local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetBtn:SetSize(140, 22)
    resetBtn:SetPoint("TOPLEFT", INDENT, y)
    resetBtn:SetText("Reset to Defaults")
    resetBtn:SetScript("OnClick", function()
        StaticPopup_Show("BREAKSYNC_RESET_CONFIRM")
    end)

    local function RefreshOptions()
        local db = BreakSyncDB
        debugCb:SetChecked(db.debug == true)
        widthSlider:SetValue(db.barWidth)
        heightSlider:SetValue(db.barHeight)
        fontSlider:SetValue(db.barFontSize)
        alphaSlider:SetValue(db.barAlpha)
        swatch:SetSwatch(db.barR, db.barG, db.barB)
        iconCb:SetChecked(db.barShowIcon ~= false)
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
