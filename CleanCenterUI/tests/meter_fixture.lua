-- Public widget hierarchy modeled from the pinned Forever meter XML. Private
-- meter data and value/text/dimension getters deliberately reject addon reads.
local New, methods, Secret, Native, RequireNative, mode = ...
function methods:GetTextColor() return unpack(self.textColor or {1, 0.8, 0.2, 1}) end
function methods:GetVertexColor() return unpack(self.vertexColor or {1, 1, 1, 1}) end
function methods:GetAtlas() return self.atlas end
function methods:SetTexture(value) self.atlas = nil self.texture = value end
function methods:SetAtlas(value) self.atlas = value self.texture = "AtlasFile:" .. value end
function methods:IsProtected() return self.protected end

local fixture = {windows = {}, clicks = 0}
local function Restricted()
    return setmetatable({}, {__index = function() error("Addon read private meter data") end,
        __pairs = function() error("Addon enumerated private meter data") end})
end
local function Guard(widget)
    widget.GetWidth = function() error("Addon read native meter width") end
    widget.GetHeight = function() error("Addon read native meter height") end
end
local function Data(color)
    return {total = Secret(), maximum = Secret(), name = Secret(), valueText = Secret(),
        color = color or {0.22, 0.7, 0.9, 1}}
end
fixture.data = Data
local function Row(parent)
    local row = New("Button", nil, parent)
    row:SetSize(350, 24) row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -10)
    row.StatusBar = New("StatusBar", nil, row)
    local bar = row.StatusBar
    bar:SetAllPoints(row) Guard(row) Guard(bar)
    bar.Name, bar.Value = bar:CreateFontString(), bar:CreateFontString()
    for _, font in ipairs({bar.Name, bar.Value}) do
        font:SetFont("NativeMeterFont", 12, "") font:SetTextColor(1, 0.8, 0.2, 1)
        font.GetText = function() error("Addon read secret meter text") end
    end
    bar.GetValue = function() error("Addon read secret meter amount") end
    bar.GetMinMaxValues = function() error("Addon read secret meter range") end
    bar.Background, bar.BackgroundEdge = bar:CreateTexture(), bar:CreateTexture()
    bar.Background:SetAlpha(0.6) bar.BackgroundEdge:SetAlpha(0.8)
    local fill = bar:GetStatusBarTexture()
    fill:SetAtlas("NativeMeterFill") fill:SetTexCoord(0.1, 0.9, 0.2, 0.8)
    row.UpdateStyle = function(self)
        RequireNative()
        self.StatusBar.Background:SetAtlas("NativeMeterBackground")
        self.StatusBar.Background:SetAlpha(0.65)
        self.StatusBar.BackgroundEdge:SetAlpha(0.75)
    end
    row.StyleData = Restricted()
    return row
end
fixture.row = Row
local function InitEntry(_, row, data)
    RequireNative()
    row.StatusBar:SetMinMaxValues(0, data.maximum)
    row.StatusBar:SetValue(data.total)
    row.StatusBar.Name:SetText(data.name) row.StatusBar.Value:SetText(data.valueText)
    row.StatusBar:GetStatusBarTexture():SetVertexColor(unpack(data.color))
    row:SetScript("OnClick", function() fixture.clicks = fixture.clicks + 1 end)
end
local function Source(parent)
    local window = New("Frame", nil, parent)
    window:SetSize(320, 200) window:SetPoint("LEFT", parent, "RIGHT", 4, 0)
    window.Background = window:CreateTexture() window.Background:SetAlpha(0.9)
    window.ScrollBox = New("Frame", nil, window)
    window.ScrollBox.ScrollTarget = New("Frame", nil, window.ScrollBox)
    window.rows = {Row(window.ScrollBox.ScrollTarget)}
    window.InitEntry = InitEntry
    InitEntry(window, window.rows[1], Data({0.66, 0.44, 0.22, 1}))
    window.dataProvider = Restricted()
    window.Refresh = function() error("Addon invoked native source refresh") end
    window:Hide() Guard(window)
    return window
end
DamageMeter = New("Frame", "DamageMeter", UIParent)
DamageMeter.windowDataList = Restricted()
DamageMeter.ForEachSessionWindow = function() error("Addon invoked native meter enumeration") end
function fixture.window(index)
    local window
    Native(function()
        window = New("Frame", "DamageMeterSessionWindow" .. index, DamageMeter)
        window:SetSize(400, 200) window:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -20 - index * 30, 220)
        window.Header = window:CreateTexture() window.Header:SetHeight(32) window.Header:SetAlpha(0.95)
        window.SessionTimer = window:CreateFontString()
        window.SessionTimer.GetText = function() error("Addon read secret meter duration") end
        window.SessionDropdown = New("Button", nil, window)
        window.SessionDropdown.SessionName = window.SessionDropdown:CreateFontString()
        window.DamageMeterTypeDropdown = New("Button", nil, window)
        window.DamageMeterTypeDropdown.TypeName = window.DamageMeterTypeDropdown:CreateFontString()
        window.SettingsDropdown = New("Button", nil, window)
        window.SettingsDropdown.Icon = window.SettingsDropdown:CreateTexture()
        window.MinimizeButton = New("Button", nil, window)
        window.MinimizeButton.normalTexture = window.MinimizeButton:CreateTexture()
        window.MinimizeButton.pushedTexture = window.MinimizeButton:CreateTexture()
        window.MinimizeButton.highlightTexture = window.MinimizeButton:CreateTexture()
        window.MinimizeButton:SetScript("OnClick", function(self)
            window.MinimizeContainer:SetShown(not window.MinimizeContainer:IsShown())
        end)
        window.MinimizeContainer = New("Frame", nil, window)
        local container = window.MinimizeContainer
        container:SetAllPoints(window)
        container.Background = container:CreateTexture() container.Background:SetAlpha(0.7)
        container.NotActive = container:CreateFontString()
        container.ScrollBox = New("Frame", nil, container)
        container.ScrollBox.ScrollTarget = New("Frame", nil, container.ScrollBox)
        container.LocalPlayerEntry = Row(container)
        container.LocalPlayerEntry:Hide()
        InitEntry(window, container.LocalPlayerEntry, Data())
        container.SourceWindow = Source(container)
        window.rows = {Row(container.ScrollBox.ScrollTarget), Row(container.ScrollBox.ScrollTarget)}
        InitEntry(window, window.rows[1], Data())
        InitEntry(window, window.rows[2], Data({0.8, 0.3, 0.7, 1}))
        window.InitEntry = InitEntry
        window.Refresh = function() error("Addon invoked native combat refresh") end
        window.dataProvider = Restricted()
        window:SetScript("OnDragStart", function() fixture.nativeDrag = true end)
        Guard(window) Guard(container)
        fixture.windows[index] = window
    end)
    return window
end
if mode ~= "meters_late" and mode ~= "meters_missing" then
    fixture.window(1) fixture.window(2) fixture.window(3)
end
if mode == "meters_missing" then DamageMeter = nil end
if mode == "meters_off" then CleanCenterUIDB = {meters = {enabled = false}} end
if mode == "meters_forbidden" then fixture.windows[2].forbidden = true fixture.windows[3].rows[1].forbidden = true end
return fixture
