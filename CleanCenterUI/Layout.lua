local _, ns = ...
local barNames = { "MainActionBar", "MultiBarBottomLeft", "MultiBarBottomRight",
    "MultiBarRight", "MultiBarLeft", "MultiBar5", "MultiBar6", "MultiBar7" }
ns.barNames = barNames
ns.actionBorderArt = {}
ns.barAnchors = {}
local barPoll = CreateFrame("Frame")
ns.barPoll = barPoll
function ns.RefreshBarPanels()
    if not ns.db then return end
    for bar, anchor in pairs(ns.barAnchors) do
        anchor:SetShown(ns.db.enabled and bar:IsVisible())
        anchor:SetAlpha(bar:GetAlpha())
    end
end
barPoll:SetScript("OnUpdate", ns.RefreshBarPanels)

local function Quiet(region)
    if region and region.SetAlpha then region:SetAlpha(0) end
end

ns.cooldownWidgets = {}
local countdownUpdating = false
local function CountdownVisibility(widget)
    if countdownUpdating or not ns.db or not ns.db.enabled or not ns.db.modules.bars
        or not ns.cooldownWidgets[widget] then return end
    countdownUpdating = true
    ns.NativeCall(widget.SetHideCountdownNumbers, widget, not ns.db.cooldownNumbers)
    countdownUpdating = false
end

function ns.StyleCooldownNumbers(button, metrics, index)
    -- The normal widget owns the ability countdown. Preserve the native
    -- charge/loss-of-control overlays' choices to avoid duplicate numbers.
    for _, widget in ipairs({button.cooldown or button.Cooldown}) do
        if widget and widget.SetHideCountdownNumbers then
            ns.cooldownWidgets[widget] = true
            CountdownVisibility(widget)
            -- Native CVar changes reset this flag. Reassert only our display
            -- preference, never read/compare remaining time or secret spells.
            ns.Hook(widget, "SetHideCountdownNumbers", CountdownVisibility)
            local text = widget.GetCountdownFontString and widget:GetCountdownFontString()
            if text then
                local height = metrics and metrics.buttonHeight or button:GetHeight()
                local triangle = metrics and metrics.triangle
                ns.StyleFont(text, "cooldowns", ns.Clamp(math.floor(height * 0.4 + 0.5), 10, 20))
                text:SetTextColor(unpack(ns.db.colors.text))
                text:ClearAllPoints()
                local y = triangle and ((index or 1) % 2 == 1 and -height / 6 or height / 6) or 0
                text:SetPoint("CENTER", widget, "CENTER", 0, y)
                -- The engine owns the font string's text, visibility, timing,
                -- charge display and expiry. No duplicate Lua timer is added.
            end
        end
    end
end

function ns.SkinActionButton(button, index, metrics)
    if not button then return end
    ns.Decorate(button, "ccuiBackground", 2)
    local icon = button.icon or button.Icon or _G[button:GetName() .. "Icon"]
    if icon then
        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT", 2, -2)
        icon:SetPoint("BOTTOMRIGHT", -2, 2)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    end
    Quiet(button:GetNormalTexture())
    Quiet(button.NormalTexture)
    Quiet(button.SlotArt)
    Quiet(button.SlotBackground)
    Quiet(button.Border)
    local hotkey = button.HotKey or _G[button:GetName() .. "HotKey"]
    if hotkey then
        hotkey:ClearAllPoints()
        if metrics.keyInside then
            if metrics.triangle then
                local edge = index % 2 == 1 and "BOTTOM" or "TOP"
                hotkey:SetPoint(edge, button, edge, 0, index % 2 == 1 and 4 or -4)
            elseif metrics.shape == "octagons" then hotkey:SetPoint("TOP", button, "TOP", 0, -5)
            else hotkey:SetPoint("TOPRIGHT",button,"TOPRIGHT",-4,-4) end
        elseif metrics.triangle then hotkey:SetPoint("TOP", button, "BOTTOM", 0, -3)
        else hotkey:SetPoint("TOPRIGHT", button, "BOTTOMRIGHT", 0, -3) end
        ns.StyleFont(hotkey, "keybinds", metrics.triangle and 10 or 11)
        hotkey:SetTextColor(unpack(ns.db.colors.text))
    end
    local count = button.Count or _G[button:GetName() .. "Count"]
    if count then ns.StyleFont(count, "keybinds", 11) end
    local cooldown = button.cooldown or button.Cooldown
    if cooldown and cooldown.SetSwipeColor then cooldown:SetSwipeColor(0, 0, 0, 0.72) end
    ns.ShapeButton(button, icon, index, metrics)
    local art = ns.actionBorderArt[button]
    if not art then art = button:CreateTexture(nil, "OVERLAY", nil, 7) art:SetAllPoints(button) ns.actionBorderArt[button] = art end
    local kind = metrics.borderStyle or "thin"
    local suffix = kind == "soft" and "Soft" or kind == "bold" and "Bold" or "Thin"
    art:SetTexture("Interface\\AddOns\\CleanCenterUI\\Media\\SquareBorder" .. suffix .. ".tga")
    local c = ns.db.colors.border art:SetVertexColor(c[1],c[2],c[3], ns.db.borders and kind ~= "none" and c[4] or 0)
    art:SetShown(not metrics.shaped and not metrics.triangle)
    ns.SetBorderColor(button.ccuiBackground,0,0,0,0)
    ns.StyleCooldownNumbers(button, metrics, index)
    ns.Hook(button, "UpdateHotkeys", function()
        if hotkey then ns.StyleFont(hotkey, "keybinds", metrics.triangle and 10 or 11) hotkey:SetTextColor(unpack(ns.db.colors.text)) end
    end)
end

ns.buttonEditors = {}
function ns.RefreshButtonEditors()
    for _, entry in pairs(ns.buttonEditors) do
        if not ns.unlocked and entry.dragging then entry.frame:StopMovingOrSizing() entry.dragging = nil end
        entry.frame:SetShown(ns.unlocked and ns.db.enabled and entry.row <= ns.db.rows and ns.db.barSettings[entry.row].individual and entry.bar:IsShown())
    end
end
local function ButtonEditor(button, anchor, bar, row, index, x, y, width, height)
    local entry = ns.buttonEditors[button]
    if not entry then
        local frame = CreateFrame("Frame", nil, anchor)
        entry = {frame = frame, row = row, bar = bar}
        ns.buttonEditors[button] = entry
        frame:SetFrameStrata("DIALOG") frame:SetFrameLevel(100)
        frame:EnableMouse(true) frame:RegisterForDrag("LeftButton") frame:SetMovable(true)
        ns.Panel(frame, 0.5)
        local label = ns.Font(frame, 12, "CENTER") label:SetPoint("CENTER") label:SetText(tostring(index))
        frame:SetScript("OnDragStart", function()
            if InCombatLockdown() then return end
            frame:StartMoving() entry.dragging = true
        end)
        frame:SetScript("OnDragStop", function()
            if not entry.dragging then return end
            entry.dragging = nil frame:StopMovingOrSizing()
            if InCombatLockdown() then ns.QueueLayout() return end
            local fx, fy = frame:GetCenter()
            local bx, by = button:GetCenter()
            if ns.Finite(fx) and ns.Finite(fy) and ns.Finite(bx) and ns.Finite(by) then
                local offset = ns.db.barSettings[row].offsets[index]
                local factor = frame:GetEffectiveScale() / anchor:GetEffectiveScale()
                offset.x = ns.Clamp(offset.x + (fx-bx)*factor, -2000, 2000)
                offset.y = ns.Clamp(offset.y + (fy-by)*factor, -2000, 2000)
            end
            ns.QueueLayout()
        end)
    end
    entry.frame:ClearAllPoints() entry.frame:SetSize(width, height)
    entry.frame:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", x, y)
end
local function PlaceBar(bar, row)
    -- Keep the full stock bar and its button containers together. Blizzard keeps
    -- ownership of paging, keybindings, drag/drop, cooldowns and secure clicks.
    if bar.attachedFrame then return end -- e.g. a temporary vehicle attachment
    ns.Reparent(bar, ns.root)
    ns.SetScale(bar, 1)
    -- Keep layout preferences in our own database. Writing native fields such
    -- as numRows/visibility taints the state Edit Mode subsequently reads.
    local metrics = ns.BarMetrics(row)
    local size, height, width = metrics.buttonWidth, metrics.buttonHeight, metrics.width
    local anchor = ns.barAnchors[bar]
    if not anchor then
        anchor = CreateFrame("Frame", nil, ns.root)
        anchor:EnableMouse(false)
        ns.barAnchors[bar] = anchor
        ns.AddMover(anchor, "bar" .. row, "Action bar " .. row)
    end
    anchor:SetSize(width, metrics.rowHeight)
    ns.Position(anchor, "bar" .. row, "BOTTOM", 0, ns.BarOffset(row))
    ns.SetSize(bar, width, metrics.rowHeight)
    ns.Position(bar, "bar" .. row, "BOTTOM", 0, ns.BarOffset(row))
    -- The border is attached to the fixed presentation anchor, not to a
    -- native frame whose combat layout can be replaced by the client.
    bar.ccuiPanel = ns.Decorate(anchor, "ccuiPanel", 4)
    local padding = metrics.keyInside and 1 or 4
    bar.ccuiPanel:ClearAllPoints()
    bar.ccuiPanel:SetPoint("TOPLEFT",anchor,"TOPLEFT",-padding,padding)
    bar.ccuiPanel:SetPoint("BOTTOMRIGHT",anchor,"BOTTOMRIGHT",padding,-padding)
    bar:EnableMouse(false)
    Quiet(bar.BorderArt)
    Quiet(bar.EndCaps)
    Quiet(bar.ActionBarPageNumber)
    if bar.HorizontalDividersPool then
        for divider in bar.HorizontalDividersPool:EnumerateActive() do Quiet(divider) end
    end
    if bar.VerticalDividersPool then
        for divider in bar.VerticalDividersPool:EnumerateActive() do Quiet(divider) end
    end
    for i, button in ipairs(bar.actionButtons or {}) do
        local container = button.container or button:GetParent()
        ns.SetSize(container, size, height)
        ns.ClearPoints(container)
        local x, y = ns.BarSlot(metrics, i)
        local pref = ns.db.barSettings[row]
        if pref.individual then x, y = x + pref.offsets[i].x, y + pref.offsets[i].y end
        ns.SetPoint(container, "BOTTOMLEFT", bar, "BOTTOMLEFT", x, y)
        ns.FixedScale(button)
        ns.SetSize(button, size, height)
        ns.ClearPoints(button)
        -- Native grid updates reposition containers, never these button
        -- anchors. Keep both native parents so action/paging code is retained.
        ns.SetPoint(button, "BOTTOMLEFT", anchor, "BOTTOMLEFT", x, y)
        ns.SkinActionButton(button, i, metrics)
        ButtonEditor(button, anchor, bar, row, i, x, y, size, height)
    end
    ns.Hook(bar, "SetPoint", ns.QueueLayout)
    ns.Hook(bar, "UpdateGridLayout", function()
        if ns.applying or ns.restoring or InCombatLockdown() then return end
        local first = bar.actionButtons and bar.actionButtons[1]
        if first then
            local point, relative = first:GetPoint()
            if ns.Readable(point) and ns.Readable(relative) and relative == anchor then return end
        end
        ns.QueueLayout()
    end)
    -- Visibility changes are mirrored by the panel poll without a full rebuild.
    -- Visibility is mirrored by RefreshBarPanels; it does not need a full reflow.
    ns.RefreshBarPanels()
    ns.RefreshButtonEditors()
end

local function VehicleExit()
    local button = MainMenuBarVehicleLeaveButton
    if not button then return end
    local row = ns.db.rows
    local metrics = ns.BarMetrics(row)
    local size = ns.Clamp(math.floor(ns.db.buttonSize * 0.75 + 0.5), 28, 44)
    if not ns.vehicleExitAnchor then
        ns.vehicleExitAnchor = CreateFrame("Frame", "CleanCenterUIVehicleExitAnchor", ns.root)
        ns.vehicleExitAnchor:EnableMouse(false)
        ns.vehicleExitAnchor:SetClampedToScreen(true)
        ns.AddMover(ns.vehicleExitAnchor, "vehicleexit", "Flight / vehicle exit")
    end
    local anchor = ns.vehicleExitAnchor
    anchor:SetSize(size, size)
    -- Sit beside the highest selected row, clear of the stance/form row.
    -- Follow a moved action row using its saved HUD coordinates, not a native
    -- action-bar parent that Blizzard can move or rescale during combat.
    local movedRow = ns.db.positions["bar" .. row]
    local relativePoint = movedRow and "CENTER" or "BOTTOM"
    local x = (movedRow and movedRow.x or 0) - metrics.width / 2 - 14 - size / 2
    local y = movedRow and (movedRow.y - metrics.rowHeight / 2)
        or ns.BarOffset(row)
    y = y + 18 + metrics.buttonHeight / 2
    if row == 1 and (ns.stanceCount or 0) > 0 then
        y = y + metrics.rowHeight + size / 2 + 12 - (18 + metrics.buttonHeight / 2)
    end
    local saved = ns.db.positions.vehicleexit
    if saved then relativePoint, x, y = "CENTER", saved.x, saved.y end
    ns.ClearPoints(anchor)
    ns.SetPoint(anchor, "CENTER", ns.root, relativePoint, x, y)
    -- Preserve native parent, visibility, events, taxi landing request,
    -- disabled/pending state, vehicle exit and tooltips. Only geometry/art.
    ns.FixedScale(button)
    ns.SetSize(button, size, size)
    ns.ClearPoints(button)
    ns.SetPoint(button, "CENTER", anchor, "CENTER")
    ns.RecordNativePosition(button, "CENTER", relativePoint, x, y)
    ns.Decorate(button, "ccuiBackground", 2)
    for _, texture in ipairs({button:GetNormalTexture(), button.GetPushedTexture and button:GetPushedTexture()}) do
        texture:ClearAllPoints()
        texture:SetPoint("TOPLEFT", button, "TOPLEFT", 4, -4)
        texture:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -4, 4)
    end
    local highlight = button.GetHighlightTexture and button:GetHighlightTexture() or button.Highlight
    if highlight then
        highlight:ClearAllPoints()
        highlight:SetPoint("TOPLEFT", button, "TOPLEFT", 4, -4)
        highlight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -4, 4)
        highlight:SetVertexColor(unpack(ns.db.colors.accent))
    end
    ns.Hook(button, "SetPoint", ns.QueueLayout)
end

local function Bars()
    if not ns.db.modules.bars or not ns.nativeBarsReady then return end
    for row, name in ipairs(barNames) do
        local bar = _G[name]
        if bar then
            PlaceBar(bar, row)
        end
    end
    local width = ns.BarMetrics().width
    if ns.ApplyStances then ns.ApplyStances() end
    VehicleExit()
    local bar = PetActionBar
    if bar then
        local buttons = bar.actionButtons or {}
        local size, gap = 28, 4
        local petWidth = math.max(size, #buttons * (size + gap) - gap)
        if not ns.petAnchor then
            ns.petAnchor = CreateFrame("Frame", nil, ns.root)
            ns.petAnchor:EnableMouse(false)
            ns.AddMover(ns.petAnchor, "PetActionBar", "Pet actions")
        end
        local anchor = ns.petAnchor
        anchor:SetSize(petWidth, size + 14)
        ns.Position(anchor, "PetActionBar", "BOTTOM", 0, ns.ActionBottom() + ns.BarHeight() + 9)
        ns.Reparent(bar, ns.root)
        ns.SetScale(bar, 1)
        ns.SetSize(bar, petWidth, size + 14)
        ns.Position(bar, "PetActionBar", "BOTTOM", 0, ns.ActionBottom() + ns.BarHeight() + 9)
        for i, button in ipairs(buttons) do
            ns.FixedScale(button)
            ns.SetSize(button, size, size)
            ns.ClearPoints(button)
            ns.SetPoint(button, "BOTTOMLEFT", anchor, "BOTTOMLEFT", (i - 1) * (size + gap), 12)
            ns.SkinActionButton(button, i, {triangle = false, buttonWidth = size, buttonHeight = size})
        end
        ns.Hook(bar, "SetPoint", ns.QueueLayout)
        ns.Hook(bar, "UpdateGridLayout", ns.QueueLayout)
        -- Pet ability updates must not rebuild the entire HUD.
        -- Geometry changes are covered by UpdateGridLayout and SetPoint.
    end
end

-- Native cast bars keep their parents, scripts, timing and secret state. These
-- independent displays forward widget values directly to widgets; they never
-- calculate cast times or inherit native aura-container layout restrictions.
ns.castDisplays = {}
local castPoll = CreateFrame("Frame")
ns.castPoll = castPoll
local function MaskCast(source)
    local fill = source:GetStatusBarTexture()
    if fill then Quiet(fill) end
    for _, region in ipairs({source:GetRegions()}) do Quiet(region) end
    for _, child in ipairs({source:GetChildren()}) do Quiet(child) end
    for _, field in ipairs({"Border", "BorderShield", "Flash", "StandardGlow", "StageGlow", "Spark", "Icon", "Text"}) do
        Quiet(source[field])
    end
end
local function RefreshCast(display)
    local source = display.source
    display:SetShown(source:IsVisible())
    display:SetAlpha(source:GetAlpha())
    display:SetMinMaxValues(source:GetMinMaxValues())
    display:SetValue(source:GetValue())
    -- MaskCast hides the stock fill. Its getter can report that zero alpha on
    -- later ticks, which must not make our separate progress fill invisible.
    -- Forward RGB directly (including secret RGB), but keep fill opacity local;
    -- native whole-bar fade still comes from source:GetAlpha() above.
    local r, g, b = source:GetStatusBarColor()
    display:SetStatusBarColor(r, g, b, 1)
    if source.Text then display.Text:SetText(source.Text:GetText()) end
    if source.Icon then display.Icon:SetTexture(source.Icon:GetTexture()) end
    MaskCast(source)
end
castPoll:SetScript("OnUpdate", function()
    if not ns.db or not ns.db.enabled then return end
    for _, display in pairs(ns.castDisplays) do RefreshCast(display) end
end)
local function CastBar(source, key, x, y, width)
    if not source then return end
    local display = ns.castDisplays[key]
    if not display then
        display = CreateFrame("StatusBar", nil, ns.root)
        display.source = source
        display:SetStatusBarTexture(ns.WHITE)
        display.Text = ns.Font(display, 12, nil, "casts")
        display.Text:SetPoint("LEFT", 4, 0)
        display.Icon = display:CreateTexture(nil, "ARTWORK")
        display.Icon:SetSize(22, 22)
        display.Icon:SetPoint("RIGHT", display, "LEFT", -6, 0)
        display.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        local iconFrame = CreateFrame("Frame", nil, display)
        iconFrame:SetPoint("TOPLEFT", display.Icon, "TOPLEFT", -1, 1)
        iconFrame:SetPoint("BOTTOMRIGHT", display.Icon, "BOTTOMRIGHT", 1, -1)
        iconFrame:SetFrameLevel(math.max(0, display:GetFrameLevel() - 1))
        iconFrame:SetFrameStrata("BACKGROUND")
        iconFrame:EnableMouse(false)
        display.ccuiIconFrame = iconFrame
        ns.castDisplays[key] = display
        ns.AddMover(display, key, key == "cast" and "Player cast bar" or "Target / focus cast bar")
    end
    display:SetSize(width, 18)
    ns.Position(display, key, "BOTTOM", x, y)
    ns.Decorate(display, "ccuiBackground", 3)
    ns.BarPanel(display.ccuiIconFrame)
    RefreshCast(display)
end

local function Casting()
    if not ns.db.modules.cast then return end
    CastBar(PlayerCastingBarFrame or CastingBarFrame, "cast", 0,
        ns.UnitBottom() + math.max(ns.db.unitStyles.player.height, ns.db.unitStyles.target.height) + 22, 340)
    if ns.db.modules.units then
        CastBar(TargetFrame and TargetFrame.spellbar or TargetFrameSpellBar,
            "targetcast", ns.UnitX(), ns.UnitBottom() - 26, ns.db.unitStyles.target.width - 8)
        CastBar(FocusFrame and FocusFrame.spellbar or FocusFrameSpellBar,
            "focuscast", ns.UnitX() + 63, ns.UnitBottom() + ns.db.unitStyles.target.height - 13, ns.db.unitStyles.focus.width)
    end
end

local function SaveChat(frame)
    if ns.db.backup.chat then return end
    local saved = { points = {}, width = frame:GetWidth(), height = frame:GetHeight(), scale = frame:GetScale() }
    for i = 1, frame:GetNumPoints() do
        local point, relative, relativePoint, x, y = frame:GetPoint(i)
        saved.points[i] = { point, relative and relative:GetName() or "UIParent", relativePoint, x, y }
    end
    ns.db.backup.chat = saved
end

local function Chat()
    if not ns.db.modules.chat or not ChatFrame1 then return end
    SaveChat(ChatFrame1)
    ns.Reparent(ChatFrame1, ns.root)
    ns.SetScale(ChatFrame1, 1)
    ns.SetSize(ChatFrame1, 410, 126)
    ChatFrame1:SetClampedToScreen(true)
    ns.StyleFont(ChatFrame1, "chat", 13)
    ChatFrame1:SetFading(true)
    ChatFrame1:SetTimeVisible(45)
    ns.Position(ChatFrame1, "chat", "BOTTOMLEFT", 24, 55)
    Quiet(ChatFrame1Background)
    if ChatFrame1ButtonFrame then ChatFrame1ButtonFrame:SetAlpha(0.18) end
    ns.Hook(ChatFrame1, "SetPoint", ns.QueueLayout)
    ns.AddMover(ChatFrame1, "chat", "Chat")
end

local function MapAndQuests()
    if ns.ApplyMinimap then ns.ApplyMinimap() end
    if ns.db.modules.quests and ObjectiveTrackerFrame then
        ns.Reparent(ObjectiveTrackerFrame, ns.root)
        ns.SetScale(ObjectiveTrackerFrame, 0.88)
        ObjectiveTrackerFrame:SetWidth(300)
        -- Offsets are measured in the scaled tracker's coordinate system.
        -- Reserve the map's full HUD height when it is enlarged.
        local bottom = ns.db.modules.minimap and ((48 + ns.db.minimapSize + 32) / 0.88) or 260
        ns.Position(ObjectiveTrackerFrame, "quests", "TOPRIGHT", -20, -bottom)
        ns.Hook(ObjectiveTrackerFrame, "SetPoint", ns.QueueLayout)
        ns.AddMover(ObjectiveTrackerFrame, "quests", "Quest tracker")
    end
    -- Preserve the standard aura frame and its tooltip/right-click behavior.
    if not ns.ApplyAuras and ns.db.modules.minimap and BuffFrame then
        ns.Reparent(BuffFrame, ns.root)
        ns.SetScale(BuffFrame, 0.85)
        ns.Position(BuffFrame, "buffs", "TOPRIGHT", -(ns.db.minimapSize + 65) / 0.85, -20)
        ns.Hook(BuffFrame, "SetPoint", ns.QueueLayout)
    end
end

function ns.RestoreSavedChanges()
    if InCombatLockdown() then return false end
    if ns.RestoreBagPreference then ns.RestoreBagPreference() end
    if ns.RestoreMinimapShape then ns.RestoreMinimapShape() end
    if ns.RestoreNativeBars then ns.RestoreNativeBars() end
    if ns.RestorePresentation then ns.RestorePresentation() end
    local chat = ns.db.backup.chat
    if chat and ChatFrame1 then
        ns.NativeCall(ChatFrame1.SetParent, ChatFrame1, UIParent)
        ns.SetScale(ChatFrame1, chat.scale)
        ns.SetSize(ChatFrame1, chat.width, chat.height)
        ns.ClearPoints(ChatFrame1)
        for _, point in ipairs(chat.points) do
            ns.SetPoint(ChatFrame1, point[1], _G[point[2]] or UIParent, point[3], point[4], point[5])
        end
    end
    return true
end

function ns.ApplyLayout()
    Bars()
    if ns.CaptureTaint then ns.CaptureTaint("after action bars") end
    Casting()
    Chat()
    MapAndQuests()
    if ns.ApplyUtility then ns.ApplyUtility() end
    if ns.ApplyAuras then ns.ApplyAuras() end
    if ns.ApplyTooltips then ns.ApplyTooltips() end
    if ns.ApplySwing then ns.ApplySwing() end
end
