local _, ns = ...
local auraPanels, auraGeometry, iconCoordinates, tooltipPanels, tooltipOwners, tooltipAlpha = {}, {}, {}, {}, {}, {}
local maskedSwing, fadingFrames = {}, {}
local tooltipLineCounts, tooltipDirty = {}, {}
ns.tooltipStylePasses = 0
ns.swingDisplays = {}
local liveAuras, liveTooltip, liveSwing, liveFade
local swingSources = {{"SwingTimerMainHandFrame", "swingmain"}, {"SwingTimerOffHandFrame", "swingoff"},
    {"SwingTimerRangedFrame", "swingranged"}}
local function Same(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    for key, value in pairs(a) do if not Same(value, b[key]) then return false end end
    for key in pairs(b) do if a[key] == nil then return false end end
    return true
end

-- Settings are written to C_EditMode's private layout copy. Native Lua state
-- (aura maps, layout caches, swing timers) always remains Blizzard-owned.
function ns.ConfigurePresentationSystem(system)
    local enum, pref, wanted, kind = Enum.EditModeSystem, nil, nil, nil
    if enum.AuraFrame and system.system == enum.AuraFrame and Enum.EditModeAuraFrameSetting then
        pref, kind = ns.db.auras, "auras"
        local setting = Enum.EditModeAuraFrameSetting
        -- Native layouts store the slider position, not its displayed percent:
        -- positions 0..15 decode to 50..200%, or 15..60px in three-pixel steps.
        wanted = {[setting.IconSize] = ns.Clamp(math.floor((pref.size - 15) / 3 + 0.5), 0, 15), [setting.IconPadding] = pref.spacing,
            [setting.IconLimitBuffFrame] = pref.columns, [setting.IconLimitDebuffFrame] = pref.columns}
        if setting.Orientation and Enum.AuraFrameOrientation then wanted[setting.Orientation] = Enum.AuraFrameOrientation.Horizontal end
        if Enum.AuraFrameIconDirection then
            if setting.IconWrap then wanted[setting.IconWrap] = Enum.AuraFrameIconDirection.Down end
            if setting.IconDirection then wanted[setting.IconDirection] = Enum.AuraFrameIconDirection.Left end
        end
    elseif enum.SwingTimer and system.system == enum.SwingTimer and Enum.EditModeSwingTimerSetting
        and Enum.EditModeSwingTimerVisibility then
        pref, kind = ns.db.swing, "swing"
        wanted = {[Enum.EditModeSwingTimerSetting.Visibility] = pref.visibility == "always"
            and Enum.EditModeSwingTimerVisibility.Always or Enum.EditModeSwingTimerVisibility.InCombat}
    else return end
    ns.db.backup.presentation = ns.db.backup.presentation or {}
    local key = kind .. ":" .. tostring(system.systemIndex or 0)
    local backup = ns.db.backup.presentation[key]
    if pref.enabled then
        if not backup then
            backup = {settings = {}, anchorInfo = ns.Copy(system.anchorInfo), anchorInfo2 = ns.Copy(system.anchorInfo2),
                isInDefaultPosition = system.isInDefaultPosition}
            for _, setting in ipairs(system.settings or {}) do
                if wanted[setting.setting] ~= nil then backup.settings[setting.setting] = setting.value end
            end
            ns.db.backup.presentation[key] = backup
        end
        return wanted
    elseif backup then
        local changed = false
        if kind == "auras" then
            changed = not Same(system.anchorInfo, backup.anchorInfo) or not Same(system.anchorInfo2, backup.anchorInfo2)
                or system.isInDefaultPosition ~= backup.isInDefaultPosition
            system.anchorInfo, system.anchorInfo2 = ns.Copy(backup.anchorInfo), ns.Copy(backup.anchorInfo2)
            system.isInDefaultPosition = backup.isInDefaultPosition
        end
        return backup.settings, changed
    end
end

function ns.PrepareSwingPreference()
    if not (ns.db.nativeBars and ns.db.nativeBars.profile and C_EditMode and C_EditMode.SaveLayouts) then return end
    if not (SwingTimerMainHandFrame and SwingTimerMainHandFrame.StatusBar and GetCVar and SetCVar) then return end
    local old = GetCVar("showSwingTimer")
    if not ns.Readable(old) then return end
    if ns.db.swing.enabled then
        if ns.db.backup.showSwingTimer == nil then ns.db.backup.showSwingTimer = old end
        if old ~= "1" then SetCVar("showSwingTimer", "1") end
    elseif ns.db.backup.showSwingTimer ~= nil and old ~= ns.db.backup.showSwingTimer then
        SetCVar("showSwingTimer", ns.db.backup.showSwingTimer)
    end
end

local function RememberGeometry(frame)
    if auraGeometry[frame] then return end
    local points = {}
    for i = 1, frame:GetNumPoints() do points[i] = {frame:GetPoint(i)} end
    auraGeometry[frame] = {points = points, scale = frame:GetScale(),
        ignore = frame.GetIgnoreParentScale and frame:GetIgnoreParentScale() or false}
end
local function RestoreAuras()
    for frame, geometry in pairs(auraGeometry) do
        ns.ClearPoints(frame)
        for _, point in ipairs(geometry.points) do ns.SetPoint(frame, unpack(point)) end
        ns.SetScale(frame, geometry.scale)
        if frame.SetIgnoreParentScale then ns.NativeCall(frame.SetIgnoreParentScale, frame, geometry.ignore) end
    end
    for icon, coordinates in pairs(iconCoordinates) do icon:SetTexCoord(unpack(coordinates)) end
    for _, panel in pairs(auraPanels) do panel:Hide() end
end
local function StyleAuraIcons(frame)
    if not (ns.db and ns.db.enabled and liveAuras and liveAuras.enabled and frame and frame.AuraContainer) then return end
    for _, button in ipairs({frame.AuraContainer:GetChildren()}) do
        local icon = button.Icon
        -- Private aura anchors expose Frame handles, not readable textures.
        if icon and icon.GetObjectType and icon:GetObjectType() == "Texture" then
            if not iconCoordinates[icon] and icon.GetTexCoord then iconCoordinates[icon] = {icon:GetTexCoord()} end
            icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            local panel = auraPanels[button]
            if not panel then
                panel = CreateFrame("Frame", nil, button)
                panel:SetPoint("TOPLEFT", icon, "TOPLEFT", -2, 2)
                panel:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -2)
                panel:SetFrameLevel(math.max(0, button:GetFrameLevel() - 1))
                panel:EnableMouse(false)
                auraPanels[button] = panel
            end
            ns.BarPanel(panel) panel:Show()
            if button.Duration then ns.StyleFont(button.Duration, "auras", 11) end
            if button.Count then ns.StyleFont(button.Count, "auras", 10) end
        end
    end
end
function ns.ApplyAuras()
    liveAuras = ns.Copy(ns.db.auras)
    if not liveAuras.enabled then RestoreAuras() return end
    for _, info in ipairs({{"BuffFrame", "buffs", -20}, {"DebuffFrame", "debuffs", -130}}) do
        local frame = _G[info[1]]
        if frame and frame.AuraContainer then
            RememberGeometry(frame)
            ns.FixedScale(frame)
            if info[2] == "debuffs" and BuffFrame and BuffFrame.AuraContainer and not ns.db.positions.debuffs then
                -- Engine anchors follow the native aura grid as rows grow.
                ns.ClearPoints(frame)
                ns.SetPoint(frame, "TOPRIGHT", BuffFrame, "BOTTOMRIGHT", 0, -24)
                ns.nativePositions[frame] = {point = "TOPRIGHT", relativeTo = "BuffFrame", relativePoint = "BOTTOMRIGHT",
                    offsetX = 0, offsetY = -24 * ns.root:GetScale()}
            else
                ns.Position(frame, info[2], "TOPRIGHT", ns.db.modules.minimap and -(ns.db.minimapSize + 65) or -24, info[3])
            end
            ns.AddMover(frame, info[2], info[2] == "buffs" and "Buffs" or "Debuffs")
            ns.Hook(frame, "SetPoint", ns.QueueLayout)
            ns.Hook(frame, "UpdateGridLayout", StyleAuraIcons)
            StyleAuraIcons(frame)
        end
    end
end

local function TooltipAllowed(frame)
    if not frame then return false end
    if frame.IsForbidden then
        local forbidden = frame:IsForbidden()
        if not ns.Readable(forbidden) or forbidden then return false end
    end
    return true
end
local function StyleTooltip(frame)
    if not (ns.db and ns.db.enabled and liveTooltip and liveTooltip.enabled and TooltipAllowed(frame)) then return end
    local panel = tooltipPanels[frame]
    if not panel then
        panel = ns.Decorate(frame, "ccuiTooltipPanel", 0, 0.97)
        panel:SetFrameStrata("TOOLTIP")
        tooltipPanels[frame] = panel
    end
    local count = frame.GetNumLines and frame:GetNumLines()
    local restyle = tooltipDirty[frame] or (ns.Finite(count) and tooltipLineCounts[frame] ~= count)
    if restyle then
    tooltipDirty[frame] = nil tooltipLineCounts[frame] = ns.Finite(count) and count or nil
    ns.tooltipStylePasses = ns.tooltipStylePasses + 1
    ns.BarPanel(panel, 0.97) panel:Show()
    if frame.NineSlice then
        if tooltipAlpha[frame] == nil then
            local alpha = frame.NineSlice:GetAlpha()
            tooltipAlpha[frame] = ns.Finite(alpha) and alpha or 1
        end
        frame.NineSlice:SetAlpha(0)
    end
    local name = frame:GetName()
    if name and ns.Finite(count) then
        for i = 1, math.min(80, count) do
            for _, side in ipairs({"Left", "Right"}) do
                local font = _G[name .. "Text" .. side .. i]
                if font then
                    local record = ns.fontRegistry[font]
                    local _, size = font:GetFont()
                    ns.StyleFont(font, "tooltip", record and record.original[2] or (ns.Finite(size) and size or 12))
                end
            end
        end
    end
    end
    -- ItemRef and shopping tooltips keep Blizzard's placement relationship.
    if frame ~= GameTooltip or not tooltipOwners[frame] then return end
    if liveTooltip.anchor == "cursor" and GetCursorPosition then
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        if ns.Finite(x) and ns.Finite(y) and ns.Finite(scale) and scale > 0 then
            ns.ClearPoints(frame) ns.SetPoint(frame, "BOTTOMLEFT", UIParent, "BOTTOMLEFT", x / scale + 18, y / scale + 18)
        end
    elseif liveTooltip.anchor == "fixed" and ns.tooltipAnchor then
        ns.ClearPoints(frame) ns.SetPoint(frame, "BOTTOMRIGHT", ns.tooltipAnchor, "BOTTOMRIGHT")
    end
end
function ns.ApplyTooltips()
    liveTooltip = ns.Copy(ns.db.tooltip)
    if not liveTooltip.enabled then
        for frame, panel in pairs(tooltipPanels) do
            panel:Hide()
            if frame.NineSlice then frame.NineSlice:SetAlpha(tooltipAlpha[frame] or 1) end
        end
        return
    end
    if not ns.tooltipAnchor then
        ns.tooltipAnchor = CreateFrame("Frame", nil, ns.root)
        ns.tooltipAnchor:SetSize(280, 28) ns.tooltipAnchor:EnableMouse(false)
        ns.AddMover(ns.tooltipAnchor, "tooltip", "Tooltip location")
    end
    ns.Position(ns.tooltipAnchor, "tooltip", "BOTTOMRIGHT", -24, 190)
    for _, name in ipairs({"GameTooltip", "ItemRefTooltip", "ShoppingTooltip1", "ShoppingTooltip2"}) do
        local frame = _G[name]
        if TooltipAllowed(frame) then
            tooltipDirty[frame] = true
            ns.Hook(frame, "SetOwner", function(self, owner) tooltipOwners[self] = owner end)
            ns.Hook(frame, "Show", function(self)
                -- Native action tooltips may Show on every hover update. The
                -- actual skin is cached and refreshed by the presentation poll.
                if not tooltipPanels[self] then tooltipDirty[self] = true StyleTooltip(self) end
            end)
            StyleTooltip(frame)
        end
    end
end

local function MaskRegion(region)
    if not region then return end
    if maskedSwing[region] == nil then
        local alpha = region:GetAlpha()
        maskedSwing[region] = ns.Finite(alpha) and alpha or 1
    end
    region:SetAlpha(0)
end
local function MaskSwing(source)
    local bar = source.StatusBar
    MaskRegion(source.Background) MaskRegion(source.Border)
    MaskRegion(bar:GetStatusBarTexture()) MaskRegion(bar.Pip) MaskRegion(bar.TypeLabel)
    MaskRegion(bar.TimeLabel) MaskRegion(bar.TypeLabelShadow)
end
local function RefreshSwing(display)
    local source, bar = display.source, display.source.StatusBar
    display:SetShown(source:IsVisible())
    display:SetAlpha(source:GetAlpha())
    -- Forward possibly secret widget values directly into engine widgets.
    display.fill:SetMinMaxValues(bar:GetMinMaxValues())
    display.fill:SetValue(bar:GetValue())
    display.fill:SetAlpha(bar:GetAlpha())
    if bar.TimeLabel then display.time:SetText(bar.TimeLabel:GetText()) end
    MaskSwing(source)
end
local function RestoreSwing()
    for _, display in pairs(ns.swingDisplays) do display:Hide() end
    for region, alpha in pairs(maskedSwing) do region:SetAlpha(alpha) end
end
function ns.ApplySwing()
    liveSwing = ns.Copy(ns.db.swing)
    if not liveSwing.enabled then RestoreSwing() return end
    local height = liveSwing.height
    -- Center the strips in the gap between the player and target frames.
    local base = ns.UnitBottom() + 30
    local textSize = ns.db.fontSettings.swing.size > 0 and ns.db.fontSettings.swing.size or 10
    for i, info in ipairs(swingSources) do
        local source = _G[info[1]]
        if source and source.StatusBar then
            local display = ns.swingDisplays[info[2]]
            if not display then
                display = CreateFrame("Frame", nil, ns.root)
                display.source = source display:EnableMouse(false)
                display.fill = CreateFrame("StatusBar", nil, display)
                display.fill:SetAllPoints(display) display.fill:SetStatusBarTexture(ns.WHITE)
                display.time = ns.Font(display, 10, "RIGHT", "swing")
                display.time:SetPoint("BOTTOMRIGHT", display, "TOPRIGHT", 0, 2)
                ns.swingDisplays[info[2]] = display
                ns.AddMover(display, info[2], "Swing timer " .. tostring(i))
            end
            display:SetSize(liveSwing.width, height)
            ns.Position(display, info[2], "BOTTOM", 0, base + (i - 1) * (height + 6 + (liveSwing.time and textSize or 0)))
            ns.BarPanel(display)
            display.fill:SetStatusBarColor(unpack(liveSwing.useAccent and ns.db.colors.accent or liveSwing.color))
            display.time:SetShown(liveSwing.time)
            RefreshSwing(display)
        end
    end
end

local function Hover(frame)
    if not frame or not frame:IsVisible() or not MouseIsOver then return false end
    local over = MouseIsOver(frame)
    return ns.Readable(over) and over or false
end
local function RestoreFading()
    for frame, state in pairs(fadingFrames) do frame:SetAlpha(state.original) end
    fadingFrames = {}
end
function ns.ApplyIdleFading()
    liveFade = ns.Copy(ns.db.fade)
    if not liveFade.enabled then RestoreFading() return end
    local wanted = {}
    for _, info in ipairs({{ChatFrame1, "chat"}, {BagsBar, "bags"}, {MicroMenuContainer or MicroMenu, "menu"}}) do
        local frame, key = info[1], info[2]
        if frame and ns.db.modules[key] and liveFade[key] then
            wanted[frame] = true
            if not fadingFrames[frame] then
                local alpha = frame:GetAlpha()
                fadingFrames[frame] = {original = ns.Finite(alpha) and alpha or 1, factor = 1, idle = 0, key = key}
            end
        end
    end
    for frame, state in pairs(fadingFrames) do
        if not wanted[frame] then frame:SetAlpha(state.original) fadingFrames[frame] = nil end
    end
end
local function WindowOpen(frame) return frame and frame:IsShown() end
local function FadeUpdate(elapsed)
    if not (liveFade and liveFade.enabled) then return end
    local force = InCombatLockdown() or ns.unlocked or ns.blizzardEditing or WindowOpen(ns.options)
        or WindowOpen(ns.appearance) or WindowOpen(ns.minimapOptions) or WindowOpen(ns.customize)
    for frame, state in pairs(fadingFrames) do
        local active = force or Hover(frame)
        if state.key == "bags" then active = active or Hover(ns.bagDock) or Hover(ns.bagFlyout)
        elseif state.key == "chat" then
            active = active or Hover(ChatFrame1ButtonFrame)
            local edit = ChatFrame1EditBox
            if edit and edit.HasFocus then local focused = edit:HasFocus() active = active or (ns.Readable(focused) and focused) end
        end
        if active then
            state.factor, state.idle = 1, 0
        else
            state.idle = state.idle + elapsed
            if state.idle > liveFade.delay then
                local amount = ns.Clamp((state.idle - liveFade.delay) / liveFade.speed, 0, 1)
                state.factor = 1 + (liveFade.alpha - 1) * amount
            end
        end
        frame:SetAlpha(state.original * state.factor)
    end
end
function ns.RestorePresentation()
    if ns.RestoreTrackers then ns.RestoreTrackers() end
    if ns.RestoreDamageMeters then ns.RestoreDamageMeters() end
    RestoreFading() RestoreSwing() RestoreAuras()
    for frame, panel in pairs(tooltipPanels) do
        panel:Hide()
        if frame.NineSlice then frame.NineSlice:SetAlpha(tooltipAlpha[frame] or 1) end
    end
    if ns.db.backup.showSwingTimer ~= nil and SetCVar then SetCVar("showSwingTimer", ns.db.backup.showSwingTimer) end
end
local poll, elapsedSince = CreateFrame("Frame"), 0
ns.presentationPoll = poll
poll:SetScript("OnUpdate", function(_, elapsed)
    if not ns.db or not ns.db.enabled or ns.restoring then return end
    elapsed = ns.Finite(elapsed) and elapsed or 0
    if liveSwing and liveSwing.enabled then for _, display in pairs(ns.swingDisplays) do RefreshSwing(display) end end
    FadeUpdate(elapsed)
    elapsedSince = elapsedSince + elapsed
    if elapsedSince >= 0.25 then
        elapsedSince = 0
        StyleAuraIcons(BuffFrame) StyleAuraIcons(DebuffFrame)
        for frame in pairs(tooltipPanels) do if frame:IsShown() then StyleTooltip(frame) end end
    end
end)
