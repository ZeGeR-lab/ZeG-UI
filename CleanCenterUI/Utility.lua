local _, ns = ...
ns.trackingAnchors = {}
local trackingPoll = CreateFrame("Frame")
ns.trackingPoll = trackingPoll
local SkinTrackingContainer
function ns.RefreshTrackingPanels()
    if not ns.db then return end
    for container, anchor in pairs(ns.trackingAnchors) do
        anchor:SetShown(ns.db.enabled and container:IsVisible())
        anchor:SetAlpha(container:GetAlpha())
        -- Native cached callbacks, pool reuse, or later art/alpha updates can
        -- bypass an instance post-hook. Reassert cosmetic suppression each
        -- presentation tick; never reflow or hide native frames in combat.
        SkinTrackingContainer(container)
    end
end
trackingPoll:SetScript("OnUpdate", ns.RefreshTrackingPanels)

local function Quiet(region)
    if region and region.SetAlpha then region:SetAlpha(0) end
end

local function QuietDividers(frame)
    for _, key in ipairs({ "HorizontalDividersPool", "VerticalDividersPool" }) do
        local pool = frame[key]
        if pool and pool.EnumerateActive then
            for divider in pool:EnumerateActive() do
                Quiet(divider)
                -- Mask the actual pip texture as well as its pooled frame.
                -- A later reset of the frame alpha must not expose its art.
                Quiet(divider.BarDividerTexture)
            end
        end
    end
end

SkinTrackingContainer = function(container)
    if not ns.db or not ns.db.enabled or not ns.db.modules.xp then return end
    -- Blizzard releases and reacquires divider frames during native layout
    -- updates. Their anchors follow the native container, not our fixed strip.
    -- Reapply alpha after updates and on presentation ticks, even in combat.
    -- Do not move/hide protected frames or defer this cosmetic work to reflow.
    Quiet(container.BarFrameTexture)
    QuietDividers(container)
end

local function SkinTrackingFill(bar, isRested)
    local status = bar.StatusBar
    if not status then return end
    status:SetStatusBarTexture(ns.WHITE)
    if status.Background then status.Background:SetColorTexture(unpack(ns.db.colors.barBackground)) end
    if bar.isExpBar then
        if isRested == nil and GetRestState then isRested = GetRestState() == 1 end
        status:SetStatusBarColor(unpack(isRested and ns.db.colors.rested or ns.db.colors.experience))
    end
end

local function Experience()
    local manager = StatusTrackingBarManager
    if not ns.db.modules.xp or not manager then return end
    local width = ns.BarMetrics().width
    local containers = manager.barContainers or {}
    if not ns.experienceAnchor then
        ns.experienceAnchor = CreateFrame("Frame", nil, ns.root)
        ns.experienceAnchor:EnableMouse(false)
        ns.AddMover(ns.experienceAnchor, "experience", "EXP / tracking bars")
    end
    local presentation = ns.experienceAnchor
    presentation:SetSize(width, math.max(1, #containers) * 16 - 4)
    ns.Position(presentation, "experience", "BOTTOM", 0, 18)
    ns.Reparent(manager, ns.root)
    ns.SetScale(manager, 1)
    ns.SetSize(manager, width, math.max(1, #containers) * 16 - 4)
    ns.Position(manager, "experience", "BOTTOM", 0, 18)
    -- Keep containers parented to their native manager. GetStatusTrackingManager
    -- relies on that parent, and Blizzard retains ownership of XP, resting,
    -- tooltips, level-up animations, and max-level visibility.
    for index, container in ipairs(containers) do
        local anchor = ns.trackingAnchors[container]
        if not anchor then
            anchor = CreateFrame("Frame", nil, presentation)
            anchor:EnableMouse(false)
            ns.trackingAnchors[container] = anchor
        end
        anchor:SetSize(width, 12)
        anchor:ClearAllPoints()
        anchor:SetPoint("BOTTOMLEFT", presentation, "BOTTOMLEFT", 0, (index - 1) * 16)
        ns.Reparent(container, manager)
        ns.SetScale(container, 1)
        ns.SetSize(container, width, 12)
        ns.ClearPoints(container)
        ns.SetPoint(container, "BOTTOMLEFT", manager, "BOTTOMLEFT", 0, (index - 1) * 16)
        local saved = ns.db.positions.experience
        if saved then
            ns.RecordNativePosition(container, "BOTTOMLEFT", "CENTER", saved.x - width / 2,
                saved.y - (math.max(1, #containers) * 16 - 4) / 2 + (index - 1) * 16)
        else
            ns.RecordNativePosition(container, "BOTTOMLEFT", "BOTTOM", -width / 2, 18 + (index - 1) * 16)
        end
        SkinTrackingContainer(container)
        container.ccuiPanel = ns.Decorate(anchor, "ccuiPanel", 1)
        for _, bar in pairs(container.bars or {}) do
            if bar.StatusBar then
                ns.FixedScale(bar)
                ns.SetSize(bar, width - 2, 10)
                ns.ClearPoints(bar)
                ns.SetPoint(bar, "BOTTOMLEFT", anchor, "BOTTOMLEFT", 1, 1)
                ns.SetSize(bar.StatusBar, width - 2, 10)
                ns.ClearPoints(bar.StatusBar)
                ns.SetPoint(bar.StatusBar, "BOTTOMLEFT", bar, "BOTTOMLEFT")
                SkinTrackingFill(bar)
                if bar.ExhaustionLevelFillBar then bar.ExhaustionLevelFillBar:SetHeight(10) end
                if bar.ExhaustionTick then bar.ExhaustionTick:SetSize(8, 12) end
                local text = bar.OverlayFrame and bar.OverlayFrame.Text
                if text then
                    text:SetFont(ns.FONT, 10, "OUTLINE")
                    text:SetTextColor(unpack(ns.db.colors.text))
                end
                -- These callbacks only recolor existing native widgets; no
                -- protected positioning or value arithmetic is done in combat.
                ns.Hook(bar, "UpdateStatusBarTextures", SkinTrackingFill)
                ns.Hook(bar, "Update", function() SkinTrackingFill(bar) end)
            end
        end
        ns.Hook(container, "SetPoint", ns.QueueLayout)
        ns.Hook(container, "SetSize", ns.QueueLayout)
        ns.Hook(container, "UpdateDividers", SkinTrackingContainer)
        ns.Hook(container, "UpdateStatusBarTextures", SkinTrackingContainer)
    end
    ns.Hook(manager, "SetPoint", ns.QueueLayout)
    ns.Hook(manager, "CheckForLayoutChange", ns.QueueLayout)
    ns.RefreshTrackingPanels()
end

local function SkinUtilityButton(button)
    if not button then return end
    ns.Decorate(button, "ccuiPanel", 1)
    -- Micro-button normal textures contain the actual menu icons; bag buttons
    -- also use native art for empty slots. Keep those and their hover/click art.
end

-- Decorative presentation follows native visibility; no combat positioning.
local utilityPoll = CreateFrame("Frame")
ns.utilityPoll = utilityPoll
utilityPoll:SetScript("OnUpdate", function()
    if ns.menuAnchor and ns.menuSource then
        ns.menuAnchor:SetShown(ns.db.enabled and ns.menuSource:IsVisible())
        ns.menuAnchor:SetAlpha(ns.menuSource:GetAlpha())
    end
    if ns.bagAnchor and BagsBar then
        ns.bagAnchor:SetShown(ns.db.enabled and BagsBar:IsVisible())
        ns.bagAnchor:SetAlpha(BagsBar:GetAlpha())
    end
end)

local function MicroMenuPanel()
    if not ns.db.modules.menu then return nil end
    local container = MicroMenuContainer or MicroMenu
    local metrics = ns.menuMetrics
    if not container or not metrics then return nil end
    local menu = MicroMenu or container
    if not ns.menuAnchor then
        ns.menuAnchor = CreateFrame("Frame", nil, ns.root)
        ns.menuAnchor:EnableMouse(false)
        ns.AddMover(ns.menuAnchor, "menu", "Micro menu")
    end
    local anchor = ns.menuAnchor
    anchor:SetSize(metrics.width, metrics.height)
    if ns.db.menuDock then ns.Position(anchor, "menu", "BOTTOM", 0, metrics.bottom)
    else ns.Position(anchor, "menu", "BOTTOMRIGHT", -22, 18) end
    ns.Reparent(container, ns.root)
    ns.FixedScale(container, metrics.scale)
    ns.ClearPoints(container)
    ns.SetPoint(container, "BOTTOMLEFT", anchor, "BOTTOMLEFT")
    local saved = ns.db.positions.menu
    if saved then
        ns.RecordNativePosition(container, "CENTER", "CENTER", saved.x / metrics.scale, saved.y / metrics.scale)
    elseif ns.db.menuDock then
        ns.RecordNativePosition(container, "BOTTOM", "BOTTOM", 0, metrics.bottom / metrics.scale)
    else
        ns.RecordNativePosition(container, "BOTTOMRIGHT", "BOTTOMRIGHT", -22 / metrics.scale, 18 / metrics.scale)
    end
    ns.menuSource = container
    Quiet(menu.BorderArt)
    Quiet(menu.BackgroundArt)
    if menu.GetChildren then
        for _, child in ipairs({menu:GetChildren()}) do
            if child.layoutIndex then SkinUtilityButton(child) end
        end
    end
    ns.Decorate(menu, "ccuiPanel", 5)
    ns.Hook(menu, "Layout", ns.QueueLayout)
    ns.Hook(container, "Layout", ns.QueueLayout)
    ns.Hook(container, "SetPoint", ns.QueueLayout)
    return container
end

local function BagButtons()
    local buttons = {}
    if MainMenuBarBagManager and MainMenuBarBagManager.EnumerateBagButtons then
        for _, button in MainMenuBarBagManager:EnumerateBagButtons() do buttons[#buttons + 1] = button end
    else
        for _, name in ipairs({"MainMenuBarBackpackButton", "CharacterBag0Slot", "CharacterBag1Slot",
            "CharacterBag2Slot", "CharacterBag3Slot", "CharacterReagentBag0Slot",
            "KeyRingButton"}) do
            local button = _G[name]
            if button then buttons[#buttons + 1] = button end
        end
    end
    return buttons
end

local function ExpandNativeBags()
    if not (GetCVar and SetCVar) then return end
    if ns.db.backup.expandBagBar == nil then ns.db.backup.expandBagBar = GetCVar("expandBagBar") end
    if GetCVar("expandBagBar") ~= "1" then SetCVar("expandBagBar", "1") end
end

function ns.RestoreBagPreference()
    if SetCVar and ns.db.backup.expandBagBar ~= nil then SetCVar("expandBagBar", ns.db.backup.expandBagBar) end
end

local openBags = [[
    local flyout = self:GetFrameRef("flyout")
    if self:GetAttribute("compact") then
        flyout:Show()
        flyout:RegisterAutoHide(0.30)
        flyout:AddToAutoHide(self:GetFrameRef("dock"))
    end
]]

local function CompactBags(buttons, backpack)
    if not ns.bagDock then
        ns.bagDock = CreateFrame("Frame", "CleanCenterUIBagDock", BagsBar, "SecureHandlerEnterLeaveTemplate")
        ns.bagDock:EnableMouse(true)
        ns.bagFlyout = CreateFrame("Frame", "CleanCenterUIBagFlyout", BagsBar, "SecureHandlerEnterLeaveTemplate")
        ns.bagFlyout:EnableMouse(true)
        ns.bagFlyout:SetClampedToScreen(true)
        for _, header in ipairs({ns.bagDock, ns.bagFlyout}) do
            -- AddToAutoHide accepts explicitly protected handles only. Native
            -- bag buttons can be ordinary widgets, even under a secure parent.
            header:SetFrameRef("flyout", ns.bagFlyout)
            header:SetFrameRef("dock", ns.bagDock)
            header:SetAttribute("_onenter", openBags)
        end
    end
    local dock, flyout = ns.bagDock, ns.bagFlyout
    dock:SetAttribute("compact", true)
    flyout:SetAttribute("compact", true)
    dock:Show()
    if BagSlotCluster then ns.Reparent(BagSlotCluster, flyout) end
    dock:ClearAllPoints()
    dock:SetAllPoints(backpack)
    -- Native clicks/drag scripts stay in place; the protected header opens only
    -- a visibility gate. Native bag event state and item handling are untouched.
    ns.Reparent(backpack, dock)
    for _, button in ipairs(buttons) do
        -- Parent headers handle visibility; native tooltip/click/drag scripts
        -- remain untouched. Motion propagates through each real bag button.
        if button.SetPropagateMouseMotion then button:SetPropagateMouseMotion(true) end
        if button ~= backpack then ns.Reparent(button, flyout) end
    end
    local count = math.max(0, #buttons - 1)
    flyout:SetSize(math.max(1, count * 49 - 4), 45)
    flyout:ClearAllPoints()
    flyout:SetPoint("RIGHT", backpack, "LEFT", -4, 0)
    ns.Decorate(dock, "ccuiPanel", 3)
    ns.Decorate(flyout, "ccuiPanel", 3)
    flyout:Hide()
    ExpandNativeBags()
end

local function BagsPanel()
    if not ns.db.modules.bags or not BagsBar then return end
    local buttons = BagButtons()
    local backpack = MainMenuBarBackpackButton or buttons[1]
    if not backpack then return end
    ns.Reparent(BagsBar, ns.root)
    ns.FixedScale(BagsBar, 0.7)
    if not ns.bagAnchor then
        ns.bagAnchor = CreateFrame("Frame", nil, ns.root)
        ns.bagAnchor:EnableMouse(false)
        ns.AddMover(ns.bagAnchor, "bags", "Bag bar")
    end
    local compact = ns.db.compactBags and SecureHandlerSetFrameRef ~= nil and backpack.SetPropagateMouseMotion ~= nil
    local bottom = 18
    if not ns.db.menuDock and ns.menuMetrics then bottom = bottom + ns.menuMetrics.outerHeight + 8 end
    ns.bagAnchor:SetSize((compact and 45 or #buttons * 49 - 4) * 0.7, 45 * 0.7)
    ns.Position(ns.bagAnchor, "bags", "BOTTOMRIGHT", -22, bottom)
    ns.ClearPoints(BagsBar)
    ns.SetPoint(BagsBar, "BOTTOMRIGHT", ns.bagAnchor, "BOTTOMRIGHT")
    local saved = ns.db.positions.bags
    if saved then ns.RecordNativePosition(BagsBar, "CENTER", "CENTER", saved.x / 0.7, saved.y / 0.7)
    else ns.RecordNativePosition(BagsBar, "BOTTOMRIGHT", "BOTTOMRIGHT", -22 / 0.7, bottom / 0.7) end
    Quiet(BagsBar.BorderArt)
    QuietDividers(BagsBar)
    Quiet(BagBarExpandToggle)
    if BagBarExpandToggle then BagBarExpandToggle:EnableMouse(false) end
    if compact then
        CompactBags(buttons, backpack)
        if BagsBar.ccuiPanel then BagsBar.ccuiPanel:Hide() end
    else
        if ns.bagDock then
            ns.bagDock:SetAttribute("compact", false)
            ns.bagFlyout:SetAttribute("compact", false)
            ns.bagDock:Hide() ns.bagFlyout:Hide()
            if BagSlotCluster then ns.Reparent(BagSlotCluster, ns.originalParents[BagSlotCluster] or BagsBar) end
            for _, button in ipairs(buttons) do ns.Reparent(button, ns.originalParents[button] or BagsBar) end
        end
        ExpandNativeBags()
        ns.Decorate(BagsBar, "ccuiPanel", 3):Show()
    end
    -- Place buttons outside combat. The native layout uses the same horizontal,
    -- left-facing arrangement in the private profile, and still owns bag state.
    ns.SetSize(BagsBar, #buttons * 49 - 4, 45)
    for index, button in ipairs(buttons) do
        ns.FixedScale(button, 0.7)
        ns.SetSize(button, 45, 45)
        ns.ClearPoints(button)
        if button == backpack then
            ns.SetPoint(button, "BOTTOMRIGHT", ns.bagAnchor, "BOTTOMRIGHT")
        elseif compact then
            ns.SetPoint(button, "RIGHT", ns.bagFlyout, "RIGHT", -(index - 2) * 49, 0)
        else
            ns.SetPoint(button, "RIGHT", backpack, "LEFT", -4 - (index - 2) * 49, 0)
        end
        SkinUtilityButton(button)
    end
    ns.Hook(BagsBar, "Layout", ns.QueueLayout)
    ns.Hook(BagsBar, "SetPoint", ns.QueueLayout)
end

function ns.ApplyUtility()
    Experience()
    MicroMenuPanel()
    BagsPanel()
end
