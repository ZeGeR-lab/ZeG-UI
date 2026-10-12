-- Deliberately strict about protected layout changes and secret-value arithmetic.
-- This is a simulator, not a replacement for actual WoW testing.
local combat, mutations, reloads, addonMutations = false, 0, 0, 0
unpack = table.unpack
local nativeWrapperCalls, nativeCalls = 0, 0
local nativeContext, nativeRefresh = false, nil
local nativeBarStates = {}
local errors, timers = {}, {}
local rested = false
local secretMeta = { secret = true }
for _, key in ipairs({ "__add", "__sub", "__mul", "__div", "__lt", "__le", "__tostring" }) do
    secretMeta[key] = function() error("Secret value accessed in Lua") end
end
local function Secret() return setmetatable({}, secretMeta) end
function issecretvalue(v) return getmetatable(v) == secretMeta end

local methods = {}
local SecureRun
local function Mutate(frame)
    if combat and frame.protected and not nativeContext then error("Protected layout changed during combat") end
    mutations = mutations + 1
    if not nativeContext then addonMutations = addonMutations + 1 end
end
local function New(kind, name, parent, template)
    local frame = setmetatable({ kind = kind, name = name, parent = parent, scale = 1,
        width = 100, height = 40, shown = true, points = {}, scripts = {}, attributes = {}, children = {},
        protected = template and template:find("Secure") ~= nil }, { __index = methods })
    if name then _G[name] = frame end
    if parent then table.insert(parent.children, frame) end
    return frame
end
function CreateFrame(kind, name, parent, template)
    local frame = New(kind, name, parent or UIParent, template)
    if template and template:find("SecureHandlerEnterLeaveTemplate") then
        frame.scripts.OnEnter = function(self, motion)
            if motion and self.attributes._onenter then SecureRun(self.attributes._onenter, self, self) end
        end
    end
    return frame
end
function methods:SetParent(parent)
    Mutate(self)
    if self.parent then
        for i, child in ipairs(self.parent.children) do
            if child == self then table.remove(self.parent.children, i) break end
        end
    end
    self.parent = parent
    if parent then table.insert(parent.children, self) end
end
function methods:GetObjectType() return self.kind end
function methods:IsForbidden() return self.forbidden or false end
function methods:GetIgnoreParentScale() return self.ignoreParentScale or false end
function methods:GetFont() return unpack(self.font or {"NativeFont", 13, ""}) end
function methods:SetFocus() self.focused = true end
function methods:HighlightText() self.highlighted = true end
function methods:SetScrollChild(child) self.scrollChild = child end
function methods:SetVerticalScroll(value) self.scroll = value end
function methods:SetMultiLine(value) self.multiLine = value end
function methods:GetNumLines() return self.lineCount or 0 end
function methods:SetOwner(owner, anchor) self.owner, self.ownerAnchor = owner, anchor end
function methods:GetTexCoord() return unpack(self.texCoord or {0,1,0,1}) end
function methods:SetTexCoord(...) self.texCoord = {...} end
function methods:GetParent() return self.parent end
function methods:GetChildren()
    local children = {}
    for _, child in ipairs(self.children) do
        if child.kind ~= "Texture" and child.kind ~= "FontString" then children[#children + 1] = child end
    end
    return table.unpack(children)
end
function methods:GetRegions()
    local regions = {}
    for _, child in ipairs(self.children) do
        if child.kind == "Texture" or child.kind == "FontString" then regions[#regions + 1] = child end
    end
    return table.unpack(regions)
end
function methods:GetAlpha() return self.alpha or 1 end
function methods:SetAlpha(value) self.alpha = value end
function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function methods:GetMinMaxValues() return table.unpack(self.range or {0, 1}) end
function methods:GetValue() return self.value or 0 end
function methods:GetStatusBarColor()
    local color = self.barColor or {1, 0.7, 0, 1}
    -- Exercise the presentation boundary when the native getter reports the
    -- alpha of its deliberately masked fill, rather than an unmodified cache.
    if self.reportFillAlpha then return color[1], color[2], color[3], self:GetStatusBarTexture():GetAlpha() end
    return table.unpack(color)
end
function methods:GetStatusBarTexture()
    if not self.fillTexture then self.fillTexture = self:CreateTexture() end
    return self.fillTexture
end
function methods:SetTexture(value) self.texture = value end
function methods:SetMaskTexture(value) self.maskTexture = value end
function methods:GetTexture() return self.texture end
function methods:GetName() return self.name end
function methods:SetScale(value) Mutate(self) self.scale = value end
function methods:GetScale() return self.scale end
function methods:SetIgnoreParentScale(value) Mutate(self) self.ignoreParentScale = value end
function methods:GetEffectiveScale()
    if self.ignoreParentScale then return self.scale end
    return self.scale * (self.parent and self.parent:GetEffectiveScale() or 1)
end
function methods:SetSize(w, h) Mutate(self) self.width, self.height = w, h end
function methods:SetWidth(w) Mutate(self) self.width = w end
function methods:SetHeight(h) Mutate(self) self.height = h end
function methods:GetWidth() return self.secretLayout and Secret() or self.width end
function methods:GetHeight() return self.secretLayout and Secret() or self.height end
function methods:GetCenter() return self.width / 2, self.height / 2 end
function methods:ClearAllPoints() Mutate(self) self.points = {} end
function methods:SetPoint(point, relative, relativePoint, x, y)
    Mutate(self)
    if type(relative) == "number" then x, y, relative, relativePoint = relative, relativePoint, self.parent, point end
    local info = { point, relative or self.parent, relativePoint or point, x or 0, y or 0 }
    for i, old in ipairs(self.points) do
        if old[1] == point then self.points[i] = info return end
    end
    table.insert(self.points, info)
end
function methods:GetPoint(i) local p = self.points[i or 1] if p then return table.unpack(p) end end
function methods:GetNumPoints() return #self.points end
function methods:SetAllPoints(frame) self.allPoints = frame or self.parent end
function methods:SetAttribute(key, value) Mutate(self) self.attributes[key] = value end
function methods:GetAttribute(key) return self.attributes[key] end
function methods:SetFrameRef(key, value) Mutate(self) self.frameRefs = self.frameRefs or {} self.frameRefs[key] = value end
function methods:GetFrameRef(key) return self.frameRefs and self.frameRefs[key] end
function methods:SetPropagateMouseMotion(value) Mutate(self) self.propagateMotion = value end
function methods:GetChecked() return self.checked or false end
function methods:SetChecked(value) self.checked = value end
function methods:SetScript(key, fn) self.scripts[key] = fn end
function methods:GetScript(key) return self.scripts[key] end
function methods:HookScript(key, fn)
    local old = self.scripts[key]
    self.scripts[key] = function(...) if old then old(...) end fn(...) end
end
function methods:Show() self:SetShown(true) end
function methods:Hide() self:SetShown(false) end
function methods:IsShown() return self.shown end
function methods:SetShown(value)
    if value ~= self.shown then
        assert(not (combat and self.protected and not nativeContext), "Protected visibility changed from insecure combat code")
        self.shown = value
        local script = self.scripts[value and "OnShow" or "OnHide"]
        if script then script(self) end
    end
end
function methods:SetText(value) self.text = value end
function methods:GetText() return self.text or "" end
function methods:HasFocus() return self.focused or false end
function methods:ClearFocus()
    if self.focused then
        self.focused = false
        if self.scripts.OnEditFocusLost then self.scripts.OnEditFocusLost(self) end
    end
end
function methods:SetFormattedText(fmt, ...) self.format, self.formatArgs = fmt, {...} end
function methods:SetValue(value) assert(self.kind == "StatusBar") self.value = value end
function methods:SetMinMaxValues(lo, hi) assert(self.kind == "StatusBar") self.range = {lo, hi} end
function methods:SetStatusBarTexture(value) assert(self.kind == "StatusBar") self.texture = value end
function methods:SetStatusBarColor(...) self.barColor = {...} end
function methods:GetNormalTexture() return self.normalTexture end
function methods:GetPushedTexture() return self.pushedTexture end
function methods:GetHighlightTexture() return self.highlightTexture end
function methods:Enable() self.enabled = true end
function methods:Disable() self.enabled = false end
function methods:IsEnabled() return self.enabled ~= false end
function methods:SetHitRectInsets(...) Mutate(self) self.hitInsets = {...} end
function methods:GetHitRectInsets() return unpack(self.hitInsets or {0, 0, 0, 0}) end
function methods:SetVertexColor(...) self.vertexColor = {...} end
function methods:CreateMaskTexture(name) return New("MaskTexture", name, self) end
function methods:AddMaskTexture(mask) self.masks = self.masks or {} self.masks[mask] = true end
function methods:RemoveMaskTexture(mask) if self.masks then self.masks[mask] = nil end end
function methods:SetSwipeTexture(texture, ...) self.swipeTexture, self.swipeColor = texture, {...} end
function methods:SetDrawEdge(value) self.drawEdge = value end
function methods:GetDrawEdge() return self.drawEdge ~= false end
function methods:SetDrawBling(value) self.drawBling = value end
function methods:GetDrawBling() return self.drawBling ~= false end
function methods:SetHideCountdownNumbers(value) self.hideNumbers = value end
function methods:GetCountdownFontString()
    if not self.countdownText then self.countdownText = self:CreateFontString() end
    return self.countdownText
end
function methods:SetCooldown(start, duration, rate)
    assert(nativeContext, "Addon replaced native cooldown timing")
    self.nativeCooldown = {start, duration, rate}
end
function methods:GetCooldownTimes() error("Addon read cooldown times") end
function methods:SetFrameStrata(value) self.strata = value end
function methods:GetFrameStrata() return self.strata or (self.parent and self.parent:GetFrameStrata()) or "MEDIUM" end
function methods:EnableMouse(value) self.mouseEnabled = value end
function methods:SetTextColor(...) self.textColor = {...} end
function methods:SetColorTexture(...) self.colorTexture = {...} end
function methods:SetFont(...) self.font = {...} end
function methods:GetFrameLevel() return 10 end
function methods:GetShowGrid() return self.grid or false end
function methods:SetShowGrid(value)
    assert(nativeContext, "Addon invoked Blizzard's Lua grid updater")
    self.grid = value
    for _, button in ipairs(self.actionButtons or {}) do button.grid = value end
end
function methods:UpdateHotkeys() end
function methods:UpdateGridLayout() end
function methods:UpdateShownButtons() end
function methods:UpdateVisibility() end
function methods:SetLook() end
function methods:Layout() end
function methods:UpdateDividers() end
function methods:CheckForLayoutChange() end
function methods:SetBackdrop() error("Lua backdrop sizing is unsafe for secret layout") end
function methods:SetBackdropColor() error("Use engine-anchored panel textures") end
function methods:SetBackdropBorderColor() error("Use engine-anchored border textures") end
function methods:CreateTexture(name) return New("Texture", name, self) end
function methods:CreateFontString(name) return New("FontString", name, self) end
function methods:RegisterEvent(event) self.events = self.events or {} self.events[event] = true end
function methods:RegisterUnitEvent(event, unit) self:RegisterEvent(event) end
function methods:AddMessage(value) self.messages = self.messages or {} table.insert(self.messages, value) end
for _, name in ipairs({ "SetJustifyH", "SetAutoFocus", "SetNumeric", "SetMaxLetters", "SetTextInsets",
    "SetFrameLevel", "SetClampedToScreen",
    "RegisterForDrag", "RegisterForClicks", "SetMovable", "StartMoving",
    "StopMovingOrSizing", "SetFading", "SetTimeVisible", "SetSwipeColor", "SetUnit" }) do
    methods[name] = function() end
end
function hooksecurefunc(object, method, callback)
    local original = assert(object[method], "Hooked a missing method")
    object[method] = function(...) local values = {original(...)} callback(...) return table.unpack(values) end
end
function securecallfunction(fn, ...)
    nativeCalls = nativeCalls + 1
    return fn(...)
end
-- Run production snippets using only visibility/auto-hide frame handles.
local secureHandles = {}
local function Handle(frame)
    if secureHandles[frame] then return secureHandles[frame] end
    local handle = {}
    secureHandles[frame] = handle
    function handle:GetAttribute(key) return frame:GetAttribute(key) end
    function handle:GetFrameRef(key) return Handle(assert(frame:GetFrameRef(key))) end
    function handle:Show() methods.SetShown(frame, true) end
    function handle:Hide() methods.SetShown(frame, false) end
    function handle:RegisterAutoHide(delay) frame.autoHideDelay = delay frame.autoHideRefs = {[frame] = true} end
    function handle:AddToAutoHide(other)
        for target, candidate in pairs(secureHandles) do
            if candidate == other then
                -- RestrictedFrames.lua resolves this with onlyProtected=true;
                -- inherited protection and an ordinary native widget fail.
                assert(target.protected, "Invalid frame handle for AddToAutoHide")
                frame.autoHideRefs[target] = true return
            end
        end
        error("Invalid secure auto-hide handle")
    end
    return handle
end
SecureRun = function(body, owner, trigger)
    local fn = assert(load(body, "secure hover snippet", "t", {control = Handle(owner), self = Handle(trigger)}))
    local old = nativeContext nativeContext = true
    fn()
    nativeContext = old
end
function SecureHandlerWrapScript(frame, script, owner, body)
    assert(not combat and owner.protected, "Secure wrap installed in combat or without protected owner")
    local original = frame.scripts[script]
    frame.scripts[script] = function(self, motion, ...)
        if motion then SecureRun(body, owner, self) end
        if original then original(self, motion, ...) end
    end
end
function SecureHandlerSetFrameRef(frame, key, ref) frame:SetFrameRef(key, ref) end
local function MouseEnter(frame)
    if frame.scripts.OnEnter then frame.scripts.OnEnter(frame, true) end
    if frame.propagateMotion and frame:GetParent() then MouseEnter(frame:GetParent()) end
end
local function AutoHide(flyout, hovered)
    for frame in pairs(flyout.autoHideRefs or {}) do
        if hovered == frame or hovered and hovered:GetParent() == frame then return end
    end
    local old = nativeContext nativeContext = true
    flyout:Hide()
    nativeContext = old
end
EventRegistry = { callbacks = {} }
function EventRegistry:RegisterCallback(event, callback, owner)
    self.callbacks[event] = function(...) callback(owner, ...) end
end
function EventRegistry:TriggerEvent(event) if self.callbacks[event] then self.callbacks[event]() end end
function InCombatLockdown() return combat end
function GetBuildInfo() return "1.60.1", "70124", "Oct 1 2026", TEST_MODE == "unsupported" and 120100 or 16001 end
function geterrorhandler() return function(err) table.insert(errors, err) end end
function UnitHealth() return Secret() end
function UnitHealthMax() return Secret() end
function UnitPower() return Secret() end
function UnitPowerMax() return Secret() end
function UnitHealthPercent() return Secret() end
function UnitName() return Secret() end
function UnitClass(unit) return Secret(), unit == "player" and "PALADIN" or nil end
function UnitPowerType() return 0, "MANA" end
function UnitReaction() return Secret() end
local disconnected, missingUnits, secretConnections = {}, {}, {}
function UnitExists(unit) return not missingUnits[unit] end
function UnitIsConnected(unit) return secretConnections[unit] and Secret() or not disconnected[unit] end
PLAYER_OFFLINE = "Offline"
function SetPortraitTexture() end
function RegisterUnitWatch(frame) frame.protected = true end
function RegisterStateDriver(frame, kind, condition) frame.protected = true frame.driver = condition end
function ReloadUI()
    reloads = reloads + 1
    if nativeRefresh then nativeRefresh() end
end
function FCF_SavePositionAndDimensions() end
function GetRestState() return rested and 1 or 2 end
local numForms = TEST_MODE == "druid_forms" and 6 or TEST_MODE == "no_forms" and 0 or 3
function GetNumShapeshiftForms() return numForms end
local bagPreference, swingPreference = "0", "0"
function GetCVar(key)
    assert(key == "expandBagBar" or key == "showSwingTimer")
    if key == "showSwingTimer" then return swingPreference end
    return bagPreference
end
function SetCVar(key, value)
    assert((key == "expandBagBar" or key == "showSwingTimer") and not combat)
    if key == "showSwingTimer" then swingPreference = value if nativeRefresh then nativeRefresh() end
    else bagPreference = value end
end
local hoveredFrame
function MouseIsOver(frame) return hoveredFrame == frame end
function GetCursorPosition() return 650, 420 end
C_Timer = { After = function(_, fn) table.insert(timers, fn) end }
CurveConstants = { ScaleTo100 = {} }
RAID_CLASS_COLORS = { PALADIN = { r = 0.96, g = 0.55, b = 0.73 } }
PowerBarColor = { MANA = { r = 0.2, g = 0.45, b = 0.8 } }
ClickCastFrames, SlashCmdList, UISpecialFrames = {}, {}, {}
ACTION_BUTTON_SHOW_GRID_REASON_CVAR = 1

UIParent = New("Frame", "UIParent") UIParent:SetSize(1920, 1080)
DEFAULT_CHAT_FRAME = New("Frame")
GameTooltip = New("GameTooltip", "GameTooltip", UIParent)
GameTooltip.lineCount = 2
GameTooltip.NineSlice = New("Frame", nil, GameTooltip) GameTooltip.NineSlice:SetAlpha(0.85)
for i = 1, 2 do
    local text = GameTooltip:CreateFontString("GameTooltipTextLeft" .. i)
    text:SetFont("NativeTooltipFont", i == 1 and 14 or 12, "") text:SetText(Secret())
end
ColorPickerFrame = New("Frame", "ColorPickerFrame", UIParent)
ColorPickerFrame:Hide()
function ColorPickerFrame:SetupColorPickerAndShow(info)
    self.info, self.r, self.g, self.b, self.a = info, info.r, info.g, info.b, info.opacity
    -- Native setup can invoke color callbacks before the initial alpha is set.
    self.a = 0.01
    info.swatchFunc()
    self.a = info.opacity
    self:Show()
end
function ColorPickerFrame:GetColorRGB() return self.r, self.g, self.b end
function ColorPickerFrame:GetColorAlpha() return self.a end
function ColorPickerFrame:GetExtraInfo() return self.info.extraInfo end
function ColorPickerFrame:OnCancel() self.info.cancelFunc() self:Hide() end
function ColorPickerFrame:OnOkay() self.info.swatchFunc() self:Hide() end
local function Pick(r, g, b, a)
    ColorPickerFrame.r, ColorPickerFrame.g, ColorPickerFrame.b, ColorPickerFrame.a = r, g, b, a
    ColorPickerFrame.info.swatchFunc()
    ColorPickerFrame.info.opacityFunc()
end
local barNames = { "MainActionBar", "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight",
                   "MultiBarLeft", "MultiBar5", "MultiBar6", "MultiBar7" }
for index, name in ipairs(barNames) do
    local bar = New("Frame", name, UIParent)
    bar.protected = true
    bar.actionButtons = {}
    for slot = 1, 12 do
        local container = New("Frame", nil, bar) container.protected = true
        local button = New("CheckButton", name .. "Button" .. slot, container)
        button.protected = true
        button.container, button.actionSlot = container, (index - 1) * 12 + slot
        button.icon = button:CreateTexture()
        button.normalTexture = button:CreateTexture()
        button.HotKey = button:CreateFontString()
        button.Count = button:CreateFontString()
        button.Count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
        for _, field in ipairs({"HighlightTexture", "PushedTexture", "CheckedTexture", "Flash"}) do
            button[field] = button:CreateTexture()
            button[field]:SetTexture("Native" .. field)
        end
        button.cooldown = New("Cooldown", nil, button)
        button.cooldown:SetHideCountdownNumbers(true)
        button.cooldown:SetDrawEdge(false)
        button.lossOfControlCooldown = New("Cooldown", nil, button)
        button.chargeCooldown = New("Cooldown", nil, button)
        button.chargeCooldown:SetHideCountdownNumbers(true)
        button:SetScript("OnClick", function(self) self.nativeClicks = (self.nativeClicks or 0) + 1 end)
        button:SetScript("OnReceiveDrag", function(self) self.nativeDrags = (self.nativeDrags or 0) + 1 end)
        bar.actionButtons[slot] = button
    end
end
local settings, originalSettings = {}, {}
for i = 2, 8 do
    local key = "PROXY_SHOW_ACTIONBAR_" .. i
    settings[key] = i == 4 -- a non-default original setting must be restored
    originalSettings[key] = settings[key]
end
Settings = {
    GetValue = function(key) return settings[key] end,
    SetValue = function() error("Addon wrote native proxy-setting state") end,
}
function MultiActionBar_Update() error("Addon invoked Blizzard's Lua visibility updater") end
function GetActionBarToggles()
    local values = {}
    for i = 2, 8 do values[i - 1] = settings["PROXY_SHOW_ACTIONBAR_" .. i] end
    return unpack(values)
end
local toggleWrites = 0
function SetActionBarToggles(...)
    assert(not combat, "Native preferences changed during combat")
    toggleWrites = toggleWrites + 1
    local values = {...}
    assert(#values == 7, "Incomplete native toggle mask")
    for i = 2, 8 do settings["PROXY_SHOW_ACTIONBAR_" .. i] = values[i - 1] end
end
for _, name in ipairs({ "PlayerFrame", "TargetFrame", "PetFrame", "FocusFrame", "PartyFrame",
    "MinimapCluster", "ObjectiveTrackerFrame", "BuffFrame", "MicroMenuContainer", "BagsBar",
    "StanceBar", "PetActionBar", "ChatFrame1", "ChatFrame1Background", "ChatFrame1ButtonFrame" }) do
    New("Frame", name, UIParent)
end
MainMenuBarVehicleLeaveButton = New("Button", "MainMenuBarVehicleLeaveButton", MainActionBar)
MainMenuBarVehicleLeaveButton.protected = true
MainMenuBarVehicleLeaveButton:SetSize(32, 32)
MainMenuBarVehicleLeaveButton:SetPoint("BOTTOMLEFT", MainActionBar, "BOTTOMLEFT")
MainMenuBarVehicleLeaveButton:Hide()
local nativeExitButton = MainMenuBarVehicleLeaveButton
nativeExitButton.normalTexture, nativeExitButton.pushedTexture, nativeExitButton.highlightTexture =
    nativeExitButton:CreateTexture(), nativeExitButton:CreateTexture(), nativeExitButton:CreateTexture()
nativeExitButton.normalTexture:SetTexture("NativeExitUp")
nativeExitButton.pushedTexture:SetTexture("NativeExitDown")
local onTaxi, inVehicle, earlyLandingRequests, vehicleExitRequests = false, false, 0, 0
nativeExitButton:SetScript("OnClick", function(self)
    if not self:IsEnabled() then return end
    if onTaxi then earlyLandingRequests = earlyLandingRequests + 1 self:Disable()
    elseif inVehicle then vehicleExitRequests = vehicleExitRequests + 1 end
end)
nativeExitButton:SetScript("OnEnter", function(self)
    self.nativeTooltip = onTaxi and "Land at next stop" or "Leave vehicle"
end)
nativeExitButton:SetScript("OnLeave", function(self) self.nativeTooltip = nil end)
nativeExitButton:SetScript("OnEvent", function(self)
    self:SetShown(onTaxi or inVehicle)
    if onTaxi or inVehicle then self:Enable() end
end)
local exitHandlers = {click = nativeExitButton:GetScript("OnClick"), enter = nativeExitButton:GetScript("OnEnter"),
    leave = nativeExitButton:GetScript("OnLeave"), event = nativeExitButton:GetScript("OnEvent")}
local function Travel(taxi, vehicle)
    onTaxi, inVehicle = taxi, vehicle
    local old = nativeContext nativeContext = true
    nativeExitButton.scripts.OnEvent(nativeExitButton, "VEHICLE_UPDATE")
    nativeContext = old
end
ChatFrame1:SetSize(350, 160)
ChatFrame1:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 10, 20)
-- Native minimap hierarchy and input: the map widget remains in its original
-- container, independent of the presentation anchor and managed cluster.
MinimapContainer = New("Frame", "MinimapContainer", MinimapCluster)
Minimap = New("Minimap", "Minimap", MinimapContainer)
Minimap.protected = true
Minimap:SetSize(198, 198)
Minimap:SetPoint("CENTER", MinimapContainer, "CENTER")
Minimap:SetMaskTexture("StockRoundMask")
Minimap.ZoomHitArea = New("Frame", nil, Minimap)
Minimap.ZoomIn, Minimap.ZoomOut = New("Button", nil, Minimap), New("Button", nil, Minimap)
MinimapCluster.BorderTop = New("Frame", nil, MinimapCluster)
MinimapCluster.BorderTop.art = MinimapCluster.BorderTop:CreateTexture()
MinimapCluster.BorderTop.NineSlice = New("Frame", nil, MinimapCluster.BorderTop)
MinimapCluster.BorderTop.NineSlice.art = MinimapCluster.BorderTop.NineSlice:CreateTexture()
MinimapCluster.ZoneTextButton = New("Button", nil, MinimapCluster)
MinimapZoneText = MinimapCluster.ZoneTextButton:CreateFontString("MinimapZoneText")
for _, field in ipairs({"Tracking", "IndicatorFrame", "InstanceDifficulty"}) do
    MinimapCluster[field] = New("Frame", nil, MinimapCluster)
end
GameTimeFrame = New("Button", "GameTimeFrame", MinimapCluster)
AddonCompartmentFrame = New("Button", "AddonCompartmentFrame", MinimapCluster)
MinimapBackdrop = New("Frame", "MinimapBackdrop", Minimap)
MinimapBackdrop.StaticOverlayTexture = MinimapBackdrop:CreateTexture()
MinimapCompassTexture = MinimapBackdrop:CreateTexture("MinimapCompassTexture")
MinimapCompassTextureUnderlay = MinimapBackdrop:CreateTexture("MinimapCompassTextureUnderlay")
ExpansionLandingPageMinimapButton = New("Button", "ExpansionLandingPageMinimapButton", MinimapBackdrop)
local nativeMapHandlers = {}
for _, frame in ipairs({Minimap, GameTimeFrame, MinimapCluster.ZoneTextButton, Minimap.ZoomIn, Minimap.ZoomOut,
    AddonCompartmentFrame, ExpansionLandingPageMinimapButton}) do
    frame:SetScript("OnClick", function(self) self.nativeClicked = true end)
    frame:SetScript("OnEnter", function(self) self.nativeTooltip = true end)
    nativeMapHandlers[frame] = {parent = frame:GetParent(), click = frame:GetScript("OnClick"), enter = frame:GetScript("OnEnter")}
end
local originalShape = function() return "ROUND" end
GetMinimapShape = originalShape
local dbIcons, iconNames, nativeIconHandlers = {}, {}, {}
local function NewDBIcon(name, angle, hidden)
    local button = New("Button", "MockDBIcon" .. name, Minimap)
    button.db = {minimapPos = angle, hide = false, lock = true}
    button:SetSize(31, 31) button:SetShown(not hidden)
    for _, script in ipairs({"OnClick", "OnEnter", "OnDragStart", "OnDragStop"}) do
        button:SetScript(script, function(self) self.nativeIconAction = script end)
    end
    dbIcons[name] = button iconNames[#iconNames + 1] = name
    nativeIconHandlers[button] = {shown = button:IsShown(), db = button.db, angle = angle,
        click = button:GetScript("OnClick"), enter = button:GetScript("OnEnter"),
        start = button:GetScript("OnDragStart"), stop = button:GetScript("OnDragStop")}
    return button
end
NewDBIcon("Corner", 45, false) NewDBIcon("Opposite", 225, false) NewDBIcon("Hidden", 0, true)
local dbIconLibrary = {}
function dbIconLibrary:GetButtonList() return iconNames end
function dbIconLibrary:GetMinimapButton(name) return dbIcons[name] end
local function IconPosition(button, angle)
    local radians, radius = math.rad(angle), Minimap:GetWidth() / 2 + 5
    local x, y = math.cos(radians) * radius, math.sin(radians) * radius
    if GetMinimapShape() == "SQUARE" then
        local diagonal = math.sqrt(2) * radius - 10
        x = math.max(-radius, math.min(radius, math.cos(radians) * diagonal))
        y = math.max(-radius, math.min(radius, math.sin(radians) * diagonal))
    end
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
    button.nativeShape = GetMinimapShape()
end
function dbIconLibrary:SetButtonToPosition(button, angle) IconPosition(button, angle) end
function dbIconLibrary:Refresh(name)
    local button = dbIcons[name]
    IconPosition(button, button.db.minimapPos)
    button:SetShown(not button.db.hide)
    button:SetScript("OnDragStart", nil) button:SetScript("OnDragStop", nil)
end
LibStub = function(name, silent) assert(name == "LibDBIcon-1.0" and silent) return dbIconLibrary end
PlayerFrame.classPowerBar = New("Frame", nil, PlayerFrame)
PlayerFrameAlternatePowerBarArea = New("Frame", "PlayerFrameAlternatePowerBarArea", PlayerFrame)
for _, name in ipairs({ "PlayerCastingBarFrame", "TargetFrameSpellBar", "FocusFrameSpellBar" }) do
    local bar = New("StatusBar", name, UIParent)
    bar.Icon, bar.Text = bar:CreateTexture(), bar:CreateFontString()
    bar.reportFillAlpha = TEST_MODE:match("^cast_fill_masked") ~= nil
end
TargetFrame.spellbar, FocusFrame.spellbar = TargetFrameSpellBar, FocusFrameSpellBar
TargetFrameSpellBar:SetParent(TargetFrame)
FocusFrameSpellBar:SetParent(FocusFrame)
for _, frame in ipairs({TargetFrame, FocusFrame}) do
    frame.nativeArt = New("Frame", nil, frame)
    function frame:ShouldAnchorSpellBarToAuraContainer() return true end
    frame.spellbar:SetScript("OnShow", function(self)
        assert(self:GetParent():ShouldAnchorSpellBarToAuraContainer(), "Native cast parent contract broken")
        self.secretLayout = true
    end)
end

-- Model the geometry wrappers installed by Blizzard's OnSystemLoad. Invoking
-- them from addon layout code mutates shared Edit Mode state. The new layout
-- must use the untouched Base widget methods, and leave native Lua fields alone.
local function InstallEditMode(frame, actionBar)
    frame.SetPointBase, frame.ClearAllPointsBase, frame.SetScaleBase = methods.SetPoint, methods.ClearAllPoints, methods.SetScale
    frame.SetPoint = function(self, ...)
        nativeWrapperCalls = nativeWrapperCalls + 1
        return self:SetPointBase(...)
    end
    frame.ClearAllPoints = function(self)
        nativeWrapperCalls = nativeWrapperCalls + 1
        return self:ClearAllPointsBase()
    end
    frame.SetScale = function(self, value)
        nativeWrapperCalls = nativeWrapperCalls + 1
        return self:SetScaleBase(value)
    end
    if actionBar then
        local state = {numRows = 3, isHorizontal = false, addButtonsToRight = false,
            addButtonsToTop = false, buttonPadding = 17, visibility = "OutOfCombat", isShownExternal = true,
            hideBarArt = false, enableDividers = true, numButtonsShowable = 7}
        nativeBarStates[frame] = state
        setmetatable(frame, {
            __index = function(_, key) if state[key] ~= nil then return state[key] end return methods[key] end,
            __newindex = function(self, key, value)
                assert(state[key] == nil, "Modified native Edit Mode state: " .. key)
                rawset(self, key, value)
            end,
        })
        frame.IsShownBase, frame.SetShownBase = methods.IsShown, methods.SetShown
        frame.SetShown = function() error("Addon invoked the native Lua visibility wrapper") end
        frame.Show, frame.Hide = frame.SetShown, frame.SetShown
    end
end
-- Public native aura and swing widgets; private data is deliberately unreadable.
DebuffFrame = New("Frame", "DebuffFrame", UIParent, "SecureFrameTemplate")
local forbiddenAuraMap = setmetatable({}, {__index = function() error("Private aura map read") end,
    __newindex = function() error("Private aura map written") end, __pairs = function() error("Private aura map iterated") end})
local nativeAuraHandlers = {}
for _, frame in ipairs({BuffFrame, DebuffFrame}) do
    frame.protected = true
    frame.AuraContainer = New("Frame", nil, frame)
    frame.auraFrames = forbiddenAuraMap
    for i = 1, 3 do
        local button = New("Button", nil, frame.AuraContainer)
        button:SetSize(30, 40)
        button.Icon = button:CreateTexture() button.Icon:SetSize(30,30)
        button.Duration, button.Count = button:CreateFontString(), button:CreateFontString()
        button.Duration:SetFont("NativeAuraFont",11,"") button.Count:SetFont("NativeAuraFont",10,"")
        button.Duration:SetText(Secret()) button.Count:SetText(Secret())
        button.DebuffBorder = button:CreateTexture()
        button:SetScript("OnClick", function() end) button:SetScript("OnEnter", function() end)
        nativeAuraHandlers[button] = {click = button:GetScript("OnClick"), enter = button:GetScript("OnEnter")}
    end
    local private = New("Frame", nil, frame.AuraContainer) private.Icon = New("Frame", nil, private)
end
local nativeSwingHandlers = {}
for _, name in ipairs({"SwingTimerMainHandFrame", "SwingTimerOffHandFrame", "SwingTimerRangedFrame"}) do
    local frame = New("Frame", name, UIParent, "SecureFrameTemplate")
    frame.StatusBar = New("StatusBar", nil, frame)
    frame.StatusBar:SetMinMaxValues(0,1) frame.StatusBar:SetValue(0.4)
    frame.Background, frame.Border = frame:CreateTexture(), frame:CreateTexture()
    for _, key in ipairs({"Pip", "TypeLabelShadow"}) do frame.StatusBar[key] = frame.StatusBar:CreateTexture() end
    frame.StatusBar.TypeLabel, frame.StatusBar.TimeLabel = frame.StatusBar:CreateFontString(), frame.StatusBar:CreateFontString()
    frame.StatusBar.TimeLabel:SetText(Secret())
    frame:SetScript("OnEvent", function() end) frame:SetScript("OnUpdate", function() end)
    nativeSwingHandlers[frame] = {event = frame:GetScript("OnEvent"), update = frame:GetScript("OnUpdate")}
    InstallEditMode(frame)
end
InstallEditMode(DebuffFrame)
for i, name in ipairs(barNames) do InstallEditMode(_G[name], true) _G[name].system, _G[name].systemIndex = 0, i end
for _, name in ipairs({"PlayerCastingBarFrame", "TargetFrameSpellBar", "FocusFrameSpellBar",
    "ChatFrame1", "MinimapCluster", "ObjectiveTrackerFrame", "BuffFrame", "StanceBar", "PetActionBar",
    "BagsBar", "MicroMenuContainer", "MainMenuBarVehicleLeaveButton"}) do InstallEditMode(_G[name]) end
StanceBar.actionButtons = {}
for i = 1, 10 do
    local container = New("Frame", nil, StanceBar)
    local button = New("CheckButton", "StanceButton" .. i, container, "SecureFrameTemplate")
    button.container, button.index = container, i
    button.icon, button.normalTexture = button:CreateTexture(), button:CreateTexture()
    button.HotKey, button.Count = button:CreateFontString(), button:CreateFontString()
    button.CheckedTexture = button:CreateTexture()
    button.cooldown = New("Cooldown", nil, button)
    button.checked = i == 1
    button:SetShown(i <= numForms)
    button:SetScript("OnClick", function(self) self.nativeFormSelected = self.index end)
    button:SetScript("OnEnter", function(self) self.nativeFormTooltip = true end)
    StanceBar.actionButtons[i] = button
end
StanceBar:SetShown(numForms > 0)
function StanceBar:Update() end

-- Model native controls with independent event/click handlers so styling must
-- preserve their ownership and live behavior, rather than merely draw a bar.
StatusTrackingBarManager = New("Frame", "StatusTrackingBarManager", UIParent)
InstallEditMode(StatusTrackingBarManager)
EssentialCooldownViewer = New("Frame", "EssentialCooldownViewer", UIParent)
EssentialCooldownViewer:SetScript("OnEvent", function(self) self.nativeAuraUpdates = (self.nativeAuraUpdates or 0) + 1 end)
local nativeCooldownEvent = EssentialCooldownViewer.scripts.OnEvent
EssentialCooldownViewer.auraInstanceIDToItemFramesMap = setmetatable({}, {
    __index = function() error("Forbidden native aura table indexed") end,
    __pairs = function() error("Forbidden native aura table iterated") end,
})
GamepadMainActionBarFramePageUnitRightClassAction = New("Button", "GamepadMainActionBarFramePageUnitRightClassAction", UIParent)
local classFlyout = GamepadMainActionBarFramePageUnitRightClassAction
classFlyout.isFlyoutAction, classFlyout.flyoutID = true, 269
classFlyout.OnEvent = function(self) self.nativeUpdates = (self.nativeUpdates or 0) + 1 end
classFlyout:SetScript("OnEvent", classFlyout.OnEvent)
local nativeFlyoutEvent = classFlyout.OnEvent
local injectedTaint = {}
function issecurevariable(frame, key)
    local owner = injectedTaint[frame] and injectedTaint[frame][key]
    return not owner, owner
end

-- Model only the public C API data/event contract, not WoW's taint engine.
Enum = {
    EditModePresetLayoutsMeta = {NumValues = 3}, EditModeLayoutType = {Preset = 0, Account = 1, Character = 2},
    EditModeSystem = {ActionBar = 0, AuraFrame = 5, VehicleLeaveButton = 9, SwingTimer = 20}, ActionBarVisibleSetting = {Always = 0, InCombat = 1, OutOfCombat = 2, Hidden = 3},
    ActionBarOrientation = {Horizontal = 0, Vertical = 1},
    EditModeActionBarSetting = {Orientation = 0, NumRows = 1, NumIcons = 2, VisibleSetting = 5, AlwaysShowButtons = 9},
    EditModeAuraFrameSetting = {IconSize = 0, IconPadding = 1, IconLimitBuffFrame = 2, IconLimitDebuffFrame = 3},
    EditModeSwingTimerSetting = {Visibility = 0}, EditModeSwingTimerVisibility = {Always = 0, InCombat = 1, Hidden = 2},
    EditModeBagsSetting = {Orientation = 0, Direction = 1, Size = 2, BagSlotPadding = 3},
    BagsOrientation = {Horizontal = 0, Vertical = 1}, BagsDirection = {Left = 0, Right = 1},
    EditModeMicroMenuSetting = {Orientation = 0, Order = 1, Size = 2},
    MicroMenuOrientation = {Horizontal = 0, Vertical = 1},
}
Constants = {EditModeConsts = {EditModeMaxLayoutsPerType = 5}}
InputUtil = {IsGamepadUIEnabled = function() return TEST_MODE == "gamepad_active" end}
local function Copy(value)
    if type(value) ~= "table" then return value end
    local out = {} for k, v in pairs(value) do out[k] = Copy(v) end return out
end
local originalLayout = {layoutName = "My original layout", layoutType = 1, systems = {}}
for i = 1, 8 do
    originalLayout.systems[i] = {system = 0, systemIndex = i, anchorInfo = {point = "BOTTOM", relativeTo = "UIParent"},
        isInDefaultPosition = true, settings = {{setting = 0, value = 1}, {setting = 1, value = 3}, {setting = 2, value = 7},
            {setting = 5, value = 2}, {setting = 9, value = 0}, {setting = 4, value = 17}}}
end
originalLayout.systems[9] = {system = 99, systemIndex = 1, settings = {{setting = 5, value = 2}}}
local layoutStore = {activeLayout = TEST_MODE == "preset_layout" and 1 or 4, layouts = {Copy(originalLayout)}}
if TEST_MODE == "full_profiles" then
    for i = 1, 5 do local layout = Copy(originalLayout) layout.layoutName = "Character " .. i layout.layoutType = 2 layoutStore.layouts[#layoutStore.layouts + 1] = layout end
end
local nativeSaves = 0
local managedFrames = {}
local nativeContainer = New("Frame", "MockBottomManagedFrameContainer", UIParent)
local function NativeArrangement()
    local old = nativeContext nativeContext = true
    local layout = layoutStore.layouts[layoutStore.activeLayout - 3] or originalLayout
    for _, frame in ipairs(managedFrames) do
        for _, system in ipairs(layout.systems) do
            if system.system == frame.system and system.systemIndex == frame.systemIndex
                and (system.isInDefaultPosition ~= false or (TEST_MODE:match("^combat_parent_shift") or TEST_MODE == "custom_bars_combat") and combat
                    and frame ~= nativeExitButton) then
                if frame.actionButtons then methods.SetParent(frame, nativeContainer) end
                methods.SetScale(frame, 0.73)
                for i, button in ipairs(frame.actionButtons or {}) do
                    methods.ClearAllPoints(button.container)
                    methods.SetPoint(button.container, "BOTTOMLEFT", frame, "BOTTOMLEFT", (i - 1) * 50, 0)
                end
                methods.ClearAllPoints(frame)
                methods.SetPoint(frame, "BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -80, 20)
                break
            end
        end
    end
    nativeContext = old
end
-- Leaving default native positioning is meaningful for this managed button.
-- The forced-action-bar cases still move its original parent during combat.
nativeExitButton:SetScript("OnShow", NativeArrangement)
local function NativeVisibility()
    local old = nativeContext nativeContext = true
    for i, name in ipairs(barNames) do
        local bar, state = _G[name], nativeBarStates[_G[name]]
        local enabled = i == 1 or settings["PROXY_SHOW_ACTIONBAR_" .. i]
        local visible = enabled and (state.visibility == "Always" or state.visibility == "OutOfCombat" and not combat
            or state.visibility == "InCombat" and combat)
        methods.SetShown(bar, visible)
    end
    for _, name in ipairs({"SwingTimerMainHandFrame", "SwingTimerOffHandFrame", "SwingTimerRangedFrame"}) do
        local frame = _G[name]
        if frame then methods.SetShown(frame, swingPreference == "1" and name == "SwingTimerMainHandFrame"
            and (frame.nativeVisibility == 0 or frame.nativeVisibility == 1 and combat)) end
    end
    nativeContext = old
end
nativeRefresh = function()
    nativeContext = true
    local layout = layoutStore.layouts[layoutStore.activeLayout - 3] or originalLayout
    for _, system in ipairs(layout.systems) do
        if system.system == 0 then
            local bar = _G[barNames[system.systemIndex]]
            local state = nativeBarStates[bar]
            for _, setting in ipairs(system.settings) do
                if setting.setting == 5 then state.visibility = ({[0] = "Always", [1] = "InCombat", [2] = "OutOfCombat", [3] = "Hidden"})[setting.value]
                elseif setting.setting == 1 then state.numRows = setting.value
                elseif setting.setting == 2 then state.numButtonsShowable = setting.value
                elseif setting.setting == 0 then state.isHorizontal = setting.value == 0
                elseif setting.setting == 9 then bar:SetShowGrid(setting.value == 1) end
            end
        elseif system.system == 5 then
            local frame = system.systemIndex == 1 and BuffFrame or DebuffFrame
            if frame then
                for _, setting in ipairs(system.settings) do
                    if setting.setting == 0 then
                        -- Native ConvertValueDefault decodes a slider position:
                        -- 50..200 percent in ten-percent steps, then scales 30px icons.
                        frame.AuraContainer.iconScale = math.max(50, math.min(200, setting.value * 10 + 50)) / 100
                        for _, button in ipairs({frame.AuraContainer:GetChildren()}) do
                            if button.Icon and button.Icon:GetObjectType() == "Texture" then
                                methods.SetScale(button, frame.AuraContainer.iconScale)
                            end
                        end
                    elseif setting.setting == 1 then frame.AuraContainer.iconPadding = setting.value
                    else frame.AuraContainer.iconStride = setting.value end
                end
            end
        elseif system.system == 20 then
            local frame = _G[({"SwingTimerMainHandFrame", "SwingTimerOffHandFrame", "SwingTimerRangedFrame"})[system.systemIndex]]
            if frame then frame.nativeVisibility = system.settings[1].value end
        end
    end
    NativeVisibility()
    NativeArrangement()
    nativeContext = false
end
C_EditMode = {}
function C_EditMode.GetLayouts() return Copy(layoutStore) end
function C_EditMode.SaveLayouts(info)
    assert(not combat, "Native layout saved during combat")
    nativeSaves = nativeSaves + 1
    layoutStore = Copy(info) nativeRefresh()
end
function C_EditMode.SetActiveLayout(index)
    assert(not combat, "Native layout selected during combat")
    assert(index <= #layoutStore.layouts + 3)
    layoutStore.activeLayout = index nativeRefresh()
end
function C_EditMode.OnLayoutAdded(index, activate) if activate then C_EditMode.SetActiveLayout(index) end end
EditModeManagerFrame = {GetActiveLayoutInfo = function() return Copy(originalLayout) end}
if TEST_MODE == "missing_native_api" then C_EditMode = nil end
StatusTrackingBarManager.barContainers = {}
local trackingBars = {}
local xp, xpMax, leveled = 250, 1000, false
for i = 1, 2 do
    local container = New("Frame", nil, StatusTrackingBarManager)
    container.bars = {}
    container.BarFrameTexture = container:CreateTexture()
    -- Reacquisition can create fresh frames or restore their default alpha.
    -- Divider cosmetics must be fixed immediately, without an out-of-combat tick.
    container.HorizontalDividersPool = {active = {}}
    function container.HorizontalDividersPool:EnumerateActive()
        local index = 0
        return function() index = index + 1 return self.active[index] end
    end
    function container:UpdateDividers(count)
        assert(nativeContext, "Addon invoked native divider layout")
        local pool = self.HorizontalDividersPool
        pool.active = {}
        for j = 1, count - 1 do
            local divider = New("Frame", nil, self)
            divider.protected = true
            divider.BarDividerTexture = divider:CreateTexture()
            divider.BarDividerTexture:SetAlpha(1)
            divider:SetAlpha(1)
            divider:SetPoint("LEFT", self, "LEFT", self.width * j / count, 0)
            divider:Show()
            pool.active[#pool.active + 1] = divider
        end
        self.BarFrameTexture:SetAlpha(1)
    end
    -- Native mixins/previously cached callbacks can retain the original method
    -- rather than dispatch through a later per-instance post-hook.
    container.nativeDividerUpdater = container.UpdateDividers
    function container:GetStatusTrackingManager() return self:GetParent() end
    for index = 1, 2 do
        local bar = New("Frame", nil, container)
        bar.isExpBar = index == 1
        bar.StatusBar = New("StatusBar", nil, bar)
        bar.StatusBar.Background = bar.StatusBar:CreateTexture()
        bar.OverlayFrame = New("Frame", nil, bar)
        bar.OverlayFrame.Text = bar.OverlayFrame:CreateFontString()
        bar.ExhaustionLevelFillBar = bar:CreateTexture()
        bar.ExhaustionTick = New("Button", nil, bar)
        function bar:UpdateStatusBarTextures()
            self.StatusBar:SetStatusBarTexture("NativeExperienceAtlas")
            self.StatusBar:SetStatusBarColor(1, 1, 1)
        end
        function bar:Update()
            self.StatusBar:SetMinMaxValues(0, xpMax)
            self.StatusBar:SetValue(xp)
            self:UpdateStatusBarTextures()
        end
        function bar:UpdateTick() self.tickUpdates = (self.tickUpdates or 0) + 1 end
        bar:SetScript("OnEvent", function(self) self:Update() end)
        bar:SetScript("OnEnter", function(self) self.tooltipUsed = true end)
        container.bars[index] = bar
        table.insert(trackingBars, bar)
    end
    table.insert(StatusTrackingBarManager.barContainers, container)
end
-- Real native containers are Edit Mode systems, separate from the XP manager.
local function RegisterManaged(frame, system, index)
    frame.system, frame.systemIndex = system, index
    managedFrames[#managedFrames + 1] = frame
    if system ~= 0 then
        local info = {system = system, systemIndex = index, isInDefaultPosition = true,
            anchorInfo = {point = "BOTTOMRIGHT", relativeTo = "UIParent"}, settings = {}}
        if frame == BagsBar then info.settings = {{setting = 0, value = 1}, {setting = 1, value = 1}}
        elseif frame == MicroMenuContainer then info.settings = {{setting = 0, value = 1}}
        elseif frame == BuffFrame or frame == DebuffFrame then info.settings = {{setting = 0, value = 5}, {setting = 1, value = 8}, {setting = frame == BuffFrame and 2 or 3, value = 6}}
        elseif system == 20 then info.settings = {{setting = 0, value = 2}} end
        originalLayout.systems[#originalLayout.systems + 1] = Copy(info)
        for _, layout in ipairs(layoutStore.layouts) do layout.systems[#layout.systems + 1] = Copy(info) end
    end
end
for i, name in ipairs(barNames) do RegisterManaged(_G[name], 0, i) end
for i, name in ipairs({"BagsBar", "MicroMenuContainer", "MinimapCluster", "ObjectiveTrackerFrame", "BuffFrame"}) do
    RegisterManaged(_G[name], i, name == "BuffFrame" and 1 or nil)
end
RegisterManaged(DebuffFrame, 5, 2)
for i, name in ipairs({"SwingTimerMainHandFrame", "SwingTimerOffHandFrame", "SwingTimerRangedFrame"}) do RegisterManaged(_G[name], 20, i) end
for i, container in ipairs(StatusTrackingBarManager.barContainers) do RegisterManaged(container, 6, i) end
RegisterManaged(nativeExitButton, Enum.EditModeSystem.VehicleLeaveButton, nil)
function StatusTrackingBarManager:UpdateBarsShown()
    for _, container in ipairs(self.barContainers) do
        container:SetShown(not leveled)
        container.bars[1]:SetShown(not leveled)
    end
    self:CheckForLayoutChange()
end
MicroMenu = New("Frame", "MicroMenu", MicroMenuContainer)
MicroMenu:SetSize(336, 46)
MicroMenuContainer:SetSize(336, 46)
MicroMenu.BorderArt = MicroMenu:CreateTexture()
MicroMenu.BackgroundArt = MicroMenu:CreateTexture()
local microButtons, bagButtons, nativeBagHandlers = {}, {}, {}
for i = 1, 4 do
    local button = New("Button", "MockMicroButton" .. i, MicroMenu)
    button.layoutIndex = i
    button.normalTexture = button:CreateTexture()
    button:SetScript("OnClick", function(self) self.clicked = true end)
    button:SetScript("OnEnter", function(self) self.tooltipUsed = true end)
    table.insert(microButtons, button)
end
for i = 1, 5 do
    local button = New("Button", "MockBagButton" .. i, BagsBar)
    button:SetScript("OnClick", function(self) self.clicked = true end)
    button:SetScript("OnReceiveDrag", function(self) self.dragReceived = true end)
    button:SetScript("OnEnter", function(self) self.tooltipUsed = true end)
    nativeBagHandlers[button] = {click = button.scripts.OnClick, drag = button.scripts.OnReceiveDrag, enter = button.scripts.OnEnter}
    table.insert(bagButtons, button)
end
MainMenuBarBagManager = { EnumerateBagButtons = function() return ipairs(bagButtons) end }
MainMenuBarBackpackButton = bagButtons[1]
local bagManager = MainMenuBarBagManager
if TEST_MODE == "missing_optional" then
    MinimapCluster, Minimap, ObjectiveTrackerFrame, BuffFrame, MicroMenuContainer, BagsBar = nil, nil, nil, nil, nil, nil
    DebuffFrame, SwingTimerMainHandFrame, SwingTimerOffHandFrame, SwingTimerRangedFrame = nil, nil, nil, nil
    ChatFrame1, PlayerCastingBarFrame, TargetFrameSpellBar, FocusFrameSpellBar = nil, nil, nil, nil
    TargetFrame.spellbar, FocusFrame.spellbar = nil, nil
    StatusTrackingBarManager, MicroMenu, MainMenuBarBagManager, MainMenuBarBackpackButton, StanceBar = nil, nil, nil, nil, nil
    Settings = nil
    MainMenuBarVehicleLeaveButton = nil
elseif TEST_MODE == "disabled" then
    CleanCenterUIDB = { enabled = false }
elseif TEST_MODE == "modules_off" then
    CleanCenterUIDB = { modules = { bars = false, units = false, party = false, cast = false,
        chat = false, minimap = false, quests = false, xp = false, bags = false, menu = false } }
elseif TEST_MODE == "utility_only" then
    CleanCenterUIDB = { modules = { bars = false, units = false, party = false, cast = false,
        chat = false, minimap = false, quests = false, xp = true, bags = true, menu = true } }
elseif TEST_MODE == "xp_off" then
    CleanCenterUIDB = { modules = { xp = false } }
elseif TEST_MODE == "menu_off" then
    CleanCenterUIDB = { modules = { menu = false } }
elseif TEST_MODE == "cast_off" then
    CleanCenterUIDB = { modules = { cast = false } }
elseif TEST_MODE == "cast_fill_masked" or TEST_MODE == "cast_fill_masked_scaled" then
    CleanCenterUIDB = {compactBags = false, scale = TEST_MODE == "cast_fill_masked_scaled" and 0.8 or 1}
elseif TEST_MODE == "druid_forms" then
    CleanCenterUIDB = {stanceShape = "triangles"}
elseif TEST_MODE == "utility_modes" then
    CleanCenterUIDB = {compactBags = false, menuDock = false}
elseif TEST_MODE == "bag_fallback" then
    SecureHandlerSetFrameRef = nil
elseif TEST_MODE == "menu_scaled" then
    MicroMenu:SetScale(1.5)
    CleanCenterUIDB = {buttonShape = "triangles", scale = 0.8}
elseif TEST_MODE == "combat_parent_shift_triangles" then
    CleanCenterUIDB = {buttonShape = "triangles"}
elseif TEST_MODE == "combat_parent_shift_triangles_scaled" then
    CleanCenterUIDB = {buttonShape = "triangles", scale = 0.8}
elseif TEST_MODE == "combat_parent_shift_scaled" then
    CleanCenterUIDB = {scale = 0.8}
elseif TEST_MODE == "xp_late_refresh" or TEST_MODE == "xp_late_refresh_scaled" then
    CleanCenterUIDB = {buttonShape = "triangles", scale = TEST_MODE == "xp_late_refresh_scaled" and 0.8 or 1}
elseif TEST_MODE == "migration" then
    CleanCenterUIDB = { rows = 3, scale = 0.9, installed = true,
        positions = {menu = {x = 500, y = -420}}, modules = {party = false} }
elseif TEST_MODE == "appearance_migration" then
    CleanCenterUIDB = {installed = true, unitStyles = {player = {
        width = 344, healthHeight = 30, powerHeight = 10, classColor = false, portrait = false,
        healthColor = {0.7, 0.2, 0.8, 0.6}, powerColor = {0.2, 0.8, 0.4, 0.9}}},
        colors = {border = {0.8, 0.2, 0.4, 0.7}}}
elseif TEST_MODE == "minimap_scaled" then
    CleanCenterUIDB = {scale = 0.8, minimapSize = 250, positions = {minimap = {x = 640, y = 310}}}
elseif TEST_MODE == "minimap_legacy_icons" then
    dbIconLibrary.SetButtonToPosition = false
elseif TEST_MODE == "minimap_no_icons" then
    LibStub = nil
elseif TEST_MODE == "minimap_missing_api" then
    Minimap.SetMaskTexture = false
elseif TEST_MODE == "minimap_migration" then
    CleanCenterUIDB = {minimapSize = 999, cooldownNumbers = false, positions = {minimap = {x = 620, y = 280}}}
elseif TEST_MODE == "party_offline" then
    disconnected.party1 = true
elseif TEST_MODE == "cooldown_numbers" then
    CleanCenterUIDB = {cooldownNumbers = false, buttonShape = "triangles"}
elseif TEST_MODE == "vehicle_exit" then
    CleanCenterUIDB = {buttonShape = "triangles"}
elseif TEST_MODE == "vehicle_exit_scaled" then
    CleanCenterUIDB = {buttonShape = "triangles", scale = 0.8,
        positions = {bar2 = {x = 40, y = -240}, vehicleexit = {x = -330, y = -240}}}
elseif TEST_MODE == "custom_aura_sizes" or TEST_MODE == "custom_aura_sizes_scaled" then
    CleanCenterUIDB = {installed = true, auras = {size = 28},
        scale = TEST_MODE == "custom_aura_sizes_scaled" and 0.8 or 1,
        positions = {buffs = {x = 550, y = 280}}}
end
if TEST_MODE == "modules_off" or TEST_MODE == "utility_only" then
    CleanCenterUIDB.auras, CleanCenterUIDB.swing = {enabled = false}, {enabled = false}
end
local trackerFixture
if TEST_MODE == "trackers_native" then
    function methods:SetAtlas(atlas) self.atlas = atlas end
    function methods:GetAtlas() return self.atlas end
    function methods:GetTextColor() return unpack(self.textColor or {1,1,1,1}) end
    local enabled = true
    C_CVar = {GetCVarBool = function() return enabled end, SetCVar = function(_, value) enabled = value == "1" end}
    C_CooldownViewer = {IsCooldownViewerAvailable = function() return true end}
    trackerFixture = New("Frame", "EssentialCooldownViewer", UIParent)
    trackerFixture.protected = true
    trackerFixture:SetPoint("CENTER", UIParent, "CENTER", 180, 100)
    local item = New("Frame", nil, trackerFixture)
    item.Icon = item:CreateTexture(nil, "ARTWORK")
    item.Cooldown = New("Cooldown", nil, item)
    item.Cooldown.timer = Secret()
    item.overlay = item:CreateTexture(nil, "OVERLAY")
    item.overlay:SetAtlas("UI-HUD-CoolDownManager-IconOverlay")
    item.text = item:CreateFontString(nil, "OVERLAY")
    item.text:SetFont("NativeFont", 17, "")
    trackerFixture.item = item
end
local ns = {}
local meterFixture
if TEST_MODE:match("^meters_") then
    local function Native(callback)
        local previous = nativeContext nativeContext = true callback() nativeContext = previous
    end
    meterFixture = assert(loadfile(ADDON_ROOT .. "/tests/meter_fixture.lua"))(New, methods, Secret, Native,
        function() assert(nativeContext, "Addon invoked native meter data code") end, TEST_MODE)
end
for line in io.lines(ADDON_ROOT .. "/CleanCenterUI.toc") do
    local file = line:match("^([%w_]+%.lua)$")
    if file then assert(loadfile(ADDON_ROOT .. "/" .. file))("CleanCenterUI", ns) end
end
local function Event(event) ns.events.scripts.OnEvent(ns.events, event) end
local function Tick() ns.events.scripts.OnUpdate(ns.events) end
local function Border(frame) return ns.panelTextures[frame].edges[1].colorTexture end
local function Timers()
    local pending = timers timers = {}
    for _, timer in ipairs(pending) do timer() end
end
if C_EditMode and TEST_MODE == "normal" then
    nativeRefresh()
    combat = true NativeVisibility() NativeArrangement()
    assert(MainActionBar:GetParent() == nativeContainer, "Simulator did not reproduce combat repositioning")
    assert(not MainActionBar:IsShown(), "The simulator did not reproduce the original combat-visibility conflict")
    combat = false NativeVisibility()
end
Event("PLAYER_LOGIN")
Timers() Tick()
assert(#errors == 0, errors[1])
assert(nativeWrapperCalls == 0, "Layout invoked Blizzard Edit Mode geometry wrappers")
if TEST_MODE == "unsupported" or not ns.db.enabled or not ns.db.modules.minimap then
    assert(GetMinimapShape == originalShape and Minimap.maskTexture == "StockRoundMask",
        "Disabled minimap styling changed the stock mask/shape provider")
    assert(Minimap:GetParent() == MinimapContainer and not ns.minimapAnchor)
end
if TEST_MODE == "unsupported" or not ns.db.enabled or not ns.db.modules.bars or not ns.nativeBarsReady then
    assert(not ns.vehicleExitAnchor and not nativeExitButton.ccuiBackground and nativeExitButton:GetParent() == MainActionBar,
        "Disabled action-bar styling modified the exit button")
end
if TEST_MODE == "unsupported" then
    assert(ns.unsupported and not ns.root)
    assert(PlayerFrame:GetParent() == UIParent)
    return
elseif TEST_MODE == "disabled" then
    assert(ns.db.enabled == false and next(ns.unitFrames) == nil)
    assert(PlayerFrame:GetParent() == UIParent)
    assert(settings.PROXY_SHOW_ACTIONBAR_4 == true)
    assert(StatusTrackingBarManager:GetParent() == UIParent)
    ns.OpenAppearance("player")
    ns.SetUnitDimension("player", "width", 320)
    assert(ns.appearance.dimensions.width:GetText() == "320" and not ns.pending,
        "Appearance preferences cannot be edited while the preset is disabled")
    return
elseif TEST_MODE == "modules_off" then
    assert(PlayerFrame:GetParent() == UIParent)
    assert(MainActionBar:GetParent() == UIParent)
    assert(settings.PROXY_SHOW_ACTIONBAR_4 == true)
    assert(StatusTrackingBarManager:GetParent() == UIParent)
    assert(BagsBar:GetParent() == UIParent and MicroMenuContainer:GetParent() == UIParent)
    return
elseif TEST_MODE == "utility_only" then
    assert(MainActionBar:GetParent() ~= ns.root)
    assert(layoutStore.layouts[#layoutStore.layouts].systems[1].settings[4].value == 2, "Utility-only styling changed action-bar visibility")
    assert(StatusTrackingBarManager:GetParent() == ns.root)
    assert(MicroMenuContainer:GetParent() == ns.root and BagsBar:GetParent() == ns.root)
    assert(ns.movers.experience and ns.movers.menu and ns.movers.bags)
    assert(settings.PROXY_SHOW_ACTIONBAR_4 == true)
    return
elseif TEST_MODE == "cast_off" then
    assert(next(ns.castDisplays) == nil)
    assert(TargetFrameSpellBar:GetParent() == TargetFrame and FocusFrameSpellBar:GetParent() == FocusFrame)
    TargetFrameSpellBar:Hide()
    TargetFrameSpellBar:Show()
    assert(TargetFrameSpellBar.secretLayout, "Native OnShow did not run when styling was off")
    return
elseif TEST_MODE == "gamepad_active" or TEST_MODE == "missing_native_api" or TEST_MODE == "full_profiles" then
    assert(not ns.nativeBarsReady and MainActionBar:GetParent() == UIParent)
    assert(settings.PROXY_SHOW_ACTIONBAR_4 == true and toggleWrites == 0)
    assert(classFlyout.OnEvent == nativeFlyoutEvent and classFlyout:GetParent() == UIParent)
    assert(nativeSaves == 0 and #errors == 0)
    return
elseif TEST_MODE == "migration" then
    assert(ns.db.rows == 3 and ns.db.scale == 0.9 and not ns.db.modules.party)
    assert(ns.db.modules.xp and ns.db.modules.bags and ns.db.modules.menu and ns.db.borders)
    local _, _, _, menuX, menuY = ns.menuAnchor:GetPoint()
    assert(menuX == 500 and menuY == -420, "Existing utility position was lost on upgrade")
    assert(ns.db.unitStyles.player.width == 286 and ns.db.colors.text[1] == 0.94)
    assert(ns.db.buttonShape == "square", "Upgrade unexpectedly changed button shape")
    return
elseif TEST_MODE == "appearance_migration" then
    local style = ns.db.unitStyles.player
    assert(style.width == 344 and style.healthHeight == 30 and style.powerHeight == 10)
    assert(not style.classColor and not style.portrait and style.powerTypeColor)
    assert(style.healthColor[4] == 0.6 and ns.db.colors.border[4] == 0.7)
    assert(ns.unitFrames.player:GetHeight() == 77 and not ns.unitFrames.player.portrait:IsShown())
    return
end
assert(ns.db.rows == 2)
assert(ns.nativeBarsReady and layoutStore.activeLayout == #layoutStore.layouts + 3)
assert(layoutStore.layouts[1].systems[1].settings[4].value == 2, "Original combat-visibility preference overwritten")
assert(layoutStore.layouts[1].systems[1].settings[2].value == 3, "Original row layout overwritten")
assert(layoutStore.layouts[#layoutStore.layouts].systems[9].settings[1].value == 2, "Unrelated native system changed")
local savesBeforeReflow = nativeSaves
ns.Apply()
assert(nativeSaves == savesBeforeReflow, "Unchanged reflow rewrote native layouts")
local shownBeforeFight = {}
for i, name in ipairs(barNames) do shownBeforeFight[i] = _G[name]:IsShown() end
-- Resolve screen coordinates, rather than merely comparing a stored point.
-- This detects movement inherited through a reparented/scaled native hierarchy.
local pointFractions = {BOTTOMLEFT={0,0}, BOTTOM={0.5,0}, BOTTOMRIGHT={1,0},
    LEFT={0,0.5}, CENTER={0.5,0.5}, RIGHT={1,0.5}, TOPLEFT={0,1}, TOP={0.5,1}, TOPRIGHT={1,1}}
local function Rect(frame)
    local scale = frame:GetEffectiveScale()
    local width, height = frame.width * scale, frame.height * scale
    if frame == UIParent then return 0, 0, width, height end
    if frame.allPoints then return Rect(frame.allPoints) end
    local point, relative, relativePoint, x, y = frame:GetPoint()
    if not point then return Rect(frame:GetParent()) end
    local rx, ry, rw, rh = Rect(relative)
    local p, r = pointFractions[point], pointFractions[relativePoint]
    return rx + rw * r[1] + x * scale - width * p[1], ry + rh * r[2] + y * scale - height * p[2], width, height
end
if TEST_MODE == "trackers_native" then
    assert(SLASH_CLEANCENTERUI1 == "/zeg" and SLASH_CLEANCENTERUI2 == "/ccui")
    assert(ns.launcher and ns.launcher:GetParent() == Minimap)
    ns.launcher:GetScript("OnClick")(ns.launcher, "LeftButton")
    assert(ns.options:IsShown())
    ns.launcher:GetScript("OnClick")(ns.launcher, "RightButton")
    assert(ns.customize:IsShown() and ns.customize.page == "trackers")
    ns.customize:Hide()
    local frame, item = trackerFixture, trackerFixture.item
    assert(ns.TrackerMoverVisible("trackeressential"))
    assert(not ns.TrackerMoverVisible("trackerutility"))
    assert(item.overlay:GetAlpha() == 0)
    assert(({item.text:GetFont()})[2] == 13)
    assert(item:GetParent() == frame and frame:GetParent() == UIParent)
    ns.db.positions.trackeressential = {x = -220, y = 120}
    ns.QueueLayout() Tick()
    assert(({frame:GetPoint()})[4] == -220)
    local before = addonMutations
    combat = true ns.db.trackers.enabled = false ns.ApplyTrackers()
    assert(addonMutations == before, "Tracker mutated protected frames during combat")
    combat = false ns.ApplyTrackers()
    assert(({frame:GetPoint()})[4] == 180)
    assert(item.overlay:GetAlpha() == 1 and ({item.text:GetFont()})[2] == 17)
    ns.db.trackers.enabled = true ns.db.trackers.groups.essential = false
    ns.ApplyTrackers() assert(item.overlay:GetAlpha() == 1)
    ns.db.trackers.groups.essential = true ns.ApplyTrackers()
    assert(ns.SaveProfile("Tracker test"))
    local encoded = assert(ns.ExportProfile("Tracker test"))
    assert(encoded:find("trackeressential", 1, true))
    assert(encoded:find("trackers.fontSize", 1, true))
    C_CVar.SetCVar("cooldownViewerEnabled", "0")
    assert(ns.TrackerStatus():find("disabled"))
    ns.EnableBlizzardTrackers() assert(C_CVar.GetCVarBool("cooldownViewerEnabled"))
    assert(#errors == 0, errors[1])
    return
end
if TEST_MODE:match("^custom_") or TEST_MODE:match("^meters_") then
    local harness = {rect = Rect, secret = Secret, nativeAuraHandlers = nativeAuraHandlers,
        nativeSwingHandlers = nativeSwingHandlers, bars = barNames}
    function harness.tick()
        Tick() assert(#errors == 0, errors[1]) assert(nativeWrapperCalls == 0)
    end
    function harness.fight(value)
        combat = value NativeVisibility() NativeArrangement()
        Event(value and "PLAYER_REGEN_DISABLED" or "PLAYER_REGEN_ENABLED")
    end
    function harness.native(callback)
        local before = nativeContext nativeContext = true callback() nativeContext = before
    end
    function harness.poll(elapsed) ns.presentationPoll.scripts.OnUpdate(ns.presentationPoll, elapsed or 0.3) end
    function harness.hover(frame) hoveredFrame = frame end
    function harness.mutations() return addonMutations end
    function harness.reloads() return reloads end
    function harness.layout() return layoutStore.layouts[layoutStore.activeLayout - 3] end
    local testFile = meterFixture and "damage_meters.lua" or "customizations.lua"
    assert(loadfile(ADDON_ROOT .. "/tests/" .. testFile))(ns, harness, TEST_MODE, meterFixture)
    assert(#errors == 0, errors[1])
    return
end
local function CheckVehicleExit()
    if not ns.vehicleExitAnchor then return end
    local frame, anchor = MainMenuBarVehicleLeaveButton, ns.vehicleExitAnchor
    local x, y, w, h = Rect(frame)
    local ax, ay, aw, ah = Rect(anchor)
    assert(math.abs(x - ax) < 0.00001 and math.abs(y - ay) < 0.00001
        and math.abs(w - aw) < 0.00001 and math.abs(h - ah) < 0.00001 and w == h)
    assert(frame:GetParent() == MainActionBar and frame:GetScript("OnClick") == exitHandlers.click
        and frame:GetScript("OnEnter") == exitHandlers.enter and frame:GetScript("OnLeave") == exitHandlers.leave
        and frame:GetScript("OnEvent") == exitHandlers.event, "Exit layout changed native input or ownership")
    assert(frame:GetNormalTexture():GetTexture() == "NativeExitUp" and frame:GetPushedTexture():GetTexture() == "NativeExitDown")
    local border = Border(frame.ccuiBackground)
    assert(border[1] == ns.db.colors.border[1] and frame:GetHighlightTexture().vertexColor[1] == ns.db.colors.accent[1])
    if not ns.db.positions.vehicleexit then
        local left, bottom, _, rowHeight = Rect(ns.barAnchors[_G[barNames[ns.db.rows]]])
        assert(x + w < left - 6 * ns.root:GetEffectiveScale(), "Exit button/border clips the action row")
        if ns.db.rows == 1 and (ns.stanceCount or 0) > 0 then
            assert(y > bottom + rowHeight, "Single-row exit button overlaps stance/form buttons")
        else
            assert(y < bottom + rowHeight and y + h > bottom + 18 * ns.root:GetEffectiveScale(),
                "Exit button is not aligned beside the ability icons")
        end
        if ns.stanceAnchor and (ns.stanceCount or 0) > 0 and not ns.db.positions.StanceBar then
            local sx, sy, sw, sh = Rect(ns.stanceAnchor)
            assert(x + w < sx or x > sx + sw or y > sy + sh or y + h < sy,
                "Exit button overlaps the default stance/form panel")
        end
    end
    local profile = layoutStore.layouts[#layoutStore.layouts]
    for _, system in ipairs(profile.systems) do
        if system.system == Enum.EditModeSystem.VehicleLeaveButton then
            assert(system.isInDefaultPosition == false, "Exit button still uses native automatic placement")
        end
    end
end
CheckVehicleExit()
if TEST_MODE:match("^vehicle_exit") then
    local saved, movedRow = ns.db.positions.vehicleexit, ns.db.positions.bar2
    if TEST_MODE == "vehicle_exit_scaled" then
        assert(saved.x == -330 and movedRow.x == 40 and ns.db.scale == 0.8)
        ns.db.positions.vehicleexit = nil ns.QueueLayout() Tick() CheckVehicleExit()
    end
    for _, shape in ipairs({"square", "triangles"}) do
        ns.SetButtonShape(shape) Tick()
        for _, rows in ipairs({1, 2, 3, 8}) do
            ns.SetRows(rows) Tick() Timers() CheckVehicleExit()
        end
    end
    ns.SetRows(2) ns.SetButtonShape("triangles") Tick() Timers()
    Travel(true, false) CheckVehicleExit()
    assert(nativeExitButton:IsVisible(), "Native taxi exit visibility was lost")
    nativeExitButton.scripts.OnEnter(nativeExitButton)
    assert(nativeExitButton.nativeTooltip == "Land at next stop")
    nativeExitButton.scripts.OnClick(nativeExitButton)
    assert(earlyLandingRequests == 1 and not nativeExitButton:IsEnabled(), "Native early-landing request/pending state was lost")
    nativeExitButton.scripts.OnClick(nativeExitButton)
    assert(earlyLandingRequests == 1, "The pending native exit button accepted a duplicate request")
    ns.Apply() CheckVehicleExit()
    assert(not nativeExitButton:IsEnabled(), "Exit restyling canceled the native pending state")
    Travel(false, false) assert(not nativeExitButton:IsShown(), "Addon forced taxi button to remain visible")
    Travel(false, true) nativeExitButton.scripts.OnEnter(nativeExitButton)
    assert(nativeExitButton.nativeTooltip == "Leave vehicle")
    nativeExitButton.scripts.OnClick(nativeExitButton) assert(vehicleExitRequests == 1)
    Travel(false, false)
    local getCenter = ns.vehicleExitAnchor.GetCenter
    local rx, ry = ns.root:GetCenter()
    ns.vehicleExitAnchor.GetCenter = function() return rx - 370, ry - 320 end
    ns.Unlock(true)
    ns.movers.vehicleexit.scripts.OnDragStart() ns.movers.vehicleexit.scripts.OnDragStop() Tick()
    ns.vehicleExitAnchor.GetCenter = getCenter
    assert(ns.db.positions.vehicleexit.x == ns.SnapCoordinate(-370) and ns.db.positions.vehicleexit.y == -320)
    ns.SetButtonShape("square") Tick() CheckVehicleExit()
    assert(ns.db.positions.vehicleexit.x == ns.SnapCoordinate(-370), "Exit style/size change removed its saved position")
    ns.db.positions.vehicleexit, ns.db.positions.bar2 = saved, movedRow
    ns.SetButtonShape("triangles") Tick() ns.Unlock(false) CheckVehicleExit()
end
local function CheckMinimap()
    if not ns.minimapAnchor then return end
    local x, y, w, h = Rect(Minimap)
    local ax, ay, aw, ah = Rect(ns.minimapAnchor)
    assert(math.abs(w - ns.db.minimapSize * ns.root:GetEffectiveScale()) < 0.00001 and w == h,
        "Minimap size did not match the requested HUD size")
    assert(math.abs(x - ax) < 0.00001 and math.abs(y - ay) < 0.00001
        and math.abs(w - aw) < 0.00001 and math.abs(h - ah) < 0.00001,
        "Minimap did not follow its independent mover anchor")
    assert(Minimap:GetParent() == MinimapContainer and Minimap.maskTexture == ns.WHITE)
    assert(GetMinimapShape() == "SQUARE" and ns.movers.minimap.target == ns.minimapAnchor)
    assert(MinimapCompassTexture:GetAlpha() == 0 and MinimapBackdrop.StaticOverlayTexture:GetAlpha() == 0)
    assert(MinimapCluster.BorderTop.art:GetAlpha() == 0 and MinimapCluster.BorderTop.NineSlice.art:GetAlpha() == 0)
    assert(GameTimeFrame:IsVisible() and AddonCompartmentFrame:IsVisible(), "Native map controls were masked")
    if not ns.db.positions.minimap then
        if ObjectiveTrackerFrame and ns.db.modules.quests and not ns.db.positions.quests then
            local _, qy, _, qh = Rect(ObjectiveTrackerFrame)
            assert(qy + qh < y - 12 * ns.root:GetEffectiveScale(), "Default quest tracker overlaps the resized minimap")
        end
        if BuffFrame and not ns.db.positions.buffs then
            local bx, _, bw = Rect(BuffFrame)
            assert(bx + bw < x - 10 * ns.root:GetEffectiveScale(), "Default buffs overlap the resized minimap")
        end
    end
    for frame, handlers in pairs(nativeMapHandlers) do
        assert(frame:GetParent() == handlers.parent and frame:GetScript("OnClick") == handlers.click
            and frame:GetScript("OnEnter") == handlers.enter, "Minimap styling replaced native input or parents")
    end
    if LibStub then
        for _, button in pairs(dbIcons) do
            local before = nativeIconHandlers[button]
            assert(button.nativeShape == "SQUARE" and button:IsShown() == before.shown)
            assert(button.db == before.db and button.db.minimapPos == before.angle and button.db.hide == false and button.db.lock == true)
            assert(button:GetScript("OnClick") == before.click and button:GetScript("OnEnter") == before.enter
                and button:GetScript("OnDragStart") == before.start and button:GetScript("OnDragStop") == before.stop,
                "Square icon refresh changed visibility, saved angle, or handlers")
        end
        local _, _, _, ix, iy = dbIcons.Corner:GetPoint()
        assert(ix > 90 and iy > 90, "Shape-aware addon icon retained its circular position")
    end
end
CheckMinimap()
if TEST_MODE:match("^minimap_") and ns.minimapAnchor then
    if TEST_MODE == "minimap_migration" then
        assert(ns.db.minimapSize == 360 and ns.db.positions.minimap.x == 620 and not ns.db.cooldownNumbers)
    end
    local mapHandlers = Minimap:GetScript("OnClick")
    local icon = LibStub and NewDBIcon("Late", 135, false)
    Event("ADDON_LOADED") Tick()
    if icon then assert(icon.nativeShape == "SQUARE", "Late-loaded addon icon did not use square placement") end
    ns.OpenMinimapOptions()
    local window = ns.minimapOptions
    assert(window:IsShown() and window.sizeEntry:GetText() == tostring(ns.db.minimapSize))
    window.sizeEntry:SetText("240") window.sizeEntry.scripts.OnEnterPressed()
    Tick() CheckMinimap()
    assert(ns.db.minimapSize == 240)
    window.plus.scripts.OnClick() Tick() assert(ns.db.minimapSize == 250)
    window.minus.scripts.OnClick() Tick() assert(ns.db.minimapSize == 240)
    SlashCmdList.CLEANCENTERUI("minimap 2") Tick() assert(ns.db.minimapSize == 120)
    SlashCmdList.CLEANCENTERUI("minimap 999") Tick() assert(ns.db.minimapSize == 360)
    window.sizeEntry.focused = true window.sizeEntry:SetText("199")
    ns.SetMinimapSize(230) Tick()
    assert(window.sizeEntry:GetText() == "199", "Minimap size editor lost an unfinished edit")
    window.sizeEntry.scripts.OnEscapePressed()
    assert(ns.db.minimapSize == 230 and window.sizeEntry:GetText() == "230", "Escape committed the minimap draft")
    local rootX, rootY = ns.root:GetCenter()
    local center = ns.minimapAnchor.GetCenter
    ns.minimapAnchor.GetCenter = function() return rootX + 650, rootY + 250 end
    window.move.scripts.OnClick()
    assert(ns.unlocked and ns.movers.minimap:IsShown() and not window:IsShown())
    ns.movers.minimap.scripts.OnDragStart() ns.movers.minimap.scripts.OnDragStop() Tick()
    ns.minimapAnchor.GetCenter = center
    assert(ns.db.positions.minimap.x == ns.SnapCoordinate(650) and ns.db.positions.minimap.y == ns.SnapCoordinate(250), "Minimap drag was not saved in HUD coordinates")
    ns.SetMinimapSize(270) Tick() CheckMinimap()
    assert(ns.db.positions.minimap.x == ns.SnapCoordinate(650) and Minimap:GetScript("OnClick") == mapHandlers)
    local count, wasPending = mutations, ns.pending
    MinimapCompassTexture:SetAlpha(1) MinimapBackdrop.StaticOverlayTexture:SetAlpha(1)
    Minimap:SetMaskTexture("StockRotatedMask")
    ns.minimapPoll.scripts.OnUpdate()
    assert(Minimap.maskTexture == ns.WHITE and MinimapCompassTexture:GetAlpha() == 0,
        "Native rotation reset the square mask or round artwork")
    assert(mutations == count and ns.pending == wasPending, "Cosmetic map refresh moved native frames")
    combat = true Event("PLAYER_REGEN_DISABLED")
    local oldSize, before = Minimap:GetScale(), mutations
    ns.SetMinimapSize(210) Tick()
    assert(ns.pending and Minimap:GetScale() == oldSize and mutations == before and not ns.movers.minimap:IsShown(),
        "Minimap resize was not deferred during combat")
    Minimap:SetMaskTexture("StockRoundMask") ns.minimapPoll.scripts.OnUpdate()
    assert(Minimap.maskTexture == ns.WHITE and mutations == before)
    combat = false Event("PLAYER_REGEN_ENABLED") Tick() CheckMinimap()
    EventRegistry:TriggerEvent("EditMode.Enter") before = mutations
    ns.SetMinimapSize(220) Tick()
    assert(ns.pending and mutations == before, "Minimap resized during native Edit Mode")
    EventRegistry:TriggerEvent("EditMode.Exit") Tick() CheckMinimap()
    local savedOther = ns.db.positions.player
    SlashCmdList.CLEANCENTERUI("minimap reset") Tick() CheckMinimap()
    assert(ns.db.minimapSize == 180 and not ns.db.positions.minimap and ns.db.positions.player == savedOther)
    ns.Unlock(false)
elseif TEST_MODE == "minimap_missing_api" then
    assert(not ns.minimapAnchor and GetMinimapShape == originalShape and Minimap:GetParent() == MinimapContainer)
end

-- Disconnect/reconnect, roster reuse and secret-health data change only our
-- status presentation. Secure unit targeting, positions and native party code
-- are never touched by these updates.
if ns.unitFrames.party2 then
    local frame = ns.unitFrames.party2
    assert(frame.events.UNIT_CONNECTION and frame.unit == "party1")
    if TEST_MODE == "party_offline" then
        assert(frame.offlineText:IsShown() and frame.offlineText:GetText() == "Offline" and not frame.value:IsShown())
        disconnected.party1 = false frame.scripts.OnEvent(frame, "UNIT_CONNECTION", "party1")
    end
    for i = 2, 5 do
        frame = ns.unitFrames["party" .. i]
        local unit, before, shown = frame.unit, mutations, frame:IsShown()
        combat = true disconnected[unit] = true
        frame.scripts.OnEvent(frame, "UNIT_CONNECTION", unit)
        assert(frame.offlineText:IsShown() and not frame.value:IsShown()
            and frame.health.barColor[1] == ns.db.colors.barBackground[1])
        assert(frame:GetAttribute("unit") == unit and frame:GetAttribute("*type1") == "target"
            and frame:IsShown() == shown and mutations == before, "Offline display modified secure unit state in combat")
        disconnected[unit] = false frame.scripts.OnEvent(frame, "UNIT_CONNECTION", unit)
        assert(not frame.offlineText:IsShown() and frame.value:IsShown()
            and frame.power.barColor[1] == PowerBarColor.MANA.r, "Reconnecting did not restore party health/power presentation")
        combat = false
    end
    frame = ns.unitFrames.party2
    disconnected.party1 = true missingUnits.party1 = true
    frame.scripts.OnEvent(frame, "GROUP_ROSTER_UPDATE")
    assert(not frame.offlineText:IsShown(), "Empty roster slot was labeled Offline")
    missingUnits.party1 = nil secretConnections.party1 = true
    frame.scripts.OnEvent(frame, "UNIT_CONNECTION", "party1")
    assert(not frame.offlineText:IsShown(), "Restricted connection state was compared in Lua")
    secretConnections.party1 = nil
    if TEST_MODE == "party_offline" then
        ns.db.unitStyles.party.healthHeight = 8 ns.Apply()
        assert(not frame.offlineText:IsShown() and frame.name.format == "%s (%s)"
            and issecretvalue(frame.name.formatArgs[1]) and frame.name.formatArgs[2] == "Offline",
            "Thin party health bar did not retain a readable Offline indicator")
        ns.db.unitStyles.party.healthHeight = ns.defaults.unitStyles.party.healthHeight
    end
    disconnected.party1 = nil ns.Apply()
end

local function CheckCooldownNumbers()
    for _, name in ipairs(barNames) do
        for _, button in ipairs(_G[name].actionButtons) do
            assert(button.cooldown.hideNumbers == not ns.db.cooldownNumbers)
            assert(button.chargeCooldown.hideNumbers == true, "Ability countdown added duplicate charge numbers")
            assert(not button.cooldown.nativeCooldown, "Styling replaced native cooldown timing")
        end
    end
    for _, button in ipairs(StanceBar and StanceBar.actionButtons or {}) do
        assert(button.cooldown.hideNumbers == not ns.db.cooldownNumbers)
    end
end
CheckCooldownNumbers()
if TEST_MODE == "cooldown_numbers" then
    assert(not ns.db.cooldownNumbers)
    ns.OpenOptions() ns.options.cooldownNumbers.scripts.OnClick() Tick() CheckCooldownNumbers()
    assert(ns.db.cooldownNumbers and ns.options.cooldownNumbers.label:GetText() == "Cooldown numbers: on")
    local first, second = MainActionBar.actionButtons[1], MainActionBar.actionButtons[2]
    local _, _, _, _, upY = first.cooldown:GetCountdownFontString():GetPoint()
    local _, _, _, _, downY = second.cooldown:GetCountdownFontString():GetPoint()
    assert(upY < 0 and downY > 0, "Countdown labels did not sit inside alternating triangles")
    local click, drag, parent = first:GetScript("OnClick"), first:GetScript("OnReceiveDrag"), first:GetParent()
    combat = true
    local before = mutations
    nativeContext = true first.cooldown:SetCooldown(Secret(), Secret(), Secret()) nativeContext = false
    first.cooldown:GetCountdownFontString():SetText(Secret())
    first.cooldown:SetHideCountdownNumbers(true)
    assert(not first.cooldown.hideNumbers and issecretvalue(first.cooldown.nativeCooldown[2])
        and issecretvalue(first.cooldown:GetCountdownFontString():GetText()) and mutations == before,
        "Native timer reset was not corrected without touching secret timing or combat geometry")
    assert(first:GetScript("OnClick") == click and first:GetScript("OnReceiveDrag") == drag and first:GetParent() == parent)
    first.cooldown.nativeCooldown = nil
    combat = false
    SlashCmdList.CLEANCENTERUI("cooldowns off") Tick() CheckCooldownNumbers()
    first.cooldown:SetHideCountdownNumbers(false)
    assert(first.cooldown.hideNumbers, "Native countdown reset lost the off preference")
    SlashCmdList.CLEANCENTERUI("cooldowns on") Tick() CheckCooldownNumbers()
end
-- A docked menu, including its themed padding, must fit strictly between the
-- tracking presentation and the lowest action-row border at any HUD scale.
local function CheckMenuGap()
    if not ns.menuAnchor or not ns.db.menuDock or ns.db.positions.menu then return end
    local mx, my, mw, mh = Rect(ns.menuAnchor)
    local scale = ns.root:GetEffectiveScale()
    local padding = 5 * ns.menuMetrics.scale * scale
    if ns.experienceAnchor then
        local _, ey, _, eh = Rect(ns.experienceAnchor)
        assert(my - padding > ey + eh, "Menu overlaps EXP/tracking strips")
    end
    local _, ay = Rect(ns.barAnchors[MainActionBar])
    assert(my + mh + padding < ay - 4 * scale, "Menu overlaps action-row border")
    assert(mw + 2 * padding <= ns.BarMetrics().width * scale, "Menu is wider than the HUD")
end
CheckMenuGap()
if ns.bagAnchor and ns.menuAnchor and not ns.db.menuDock and not ns.db.positions.bags and not ns.db.positions.menu then
    local _, by = Rect(ns.bagAnchor)
    local _, my, _, mh = Rect(ns.menuAnchor)
    assert(by > my + mh, "Corner menu overlaps the bag bar")
end
if ns.stanceAnchor then
    assert(ns.stanceAnchor:IsShown() == (numForms > 0), "Stance row is shown without forms")
    for i, button in ipairs(StanceBar.actionButtons) do
        assert(button:GetParent() == button.container, "Stance was detached from its native action container")
        assert(button.index == i and button:IsShown() == (i <= numForms), "Native class form availability changed")
    end
    local selected = StanceBar.actionButtons[1]
    ns.RefreshStanceHighlights()
    assert(ns.stanceHighlights[selected][1]:IsShown(), "Active stance has no theme highlight")
    selected.scripts.OnClick(selected) selected.scripts.OnEnter(selected)
    assert(selected.nativeFormSelected == 1 and selected.nativeFormTooltip, "Native stance behavior changed")
end
local function CheckCastFill()
    if not ns.db.modules.cast then return end
    for key, display in pairs(ns.castDisplays) do
        local source = display.source
        local nativeParent, nativeScript = source:GetParent(), source.scripts.OnUpdate
        local point, before = {display:GetPoint()}, mutations
        source:SetAlpha(1)
        source:SetStatusBarColor(0.16, 0.68, 0.91, 1)
        source:SetMinMaxValues(0, 4)
        source.Text:SetText("Test cast") source.Icon:SetTexture(1234)
        source:Show()
        for _, values in ipairs({{0, 1, 2, 3, 4}, {4, 3, 2, 1, 0}}) do
            for _, value in ipairs(values) do
                -- Advance native widget state, as casting/channeling code does.
                source:SetValue(value)
                ns.castPoll.scripts.OnUpdate(ns.castPoll)
                ns.castPoll.scripts.OnUpdate(ns.castPoll)
                assert(display.value == value and display.range[2] == 4, "Cast/channel progress stopped: " .. key)
                assert(display.barColor[1] == 0.16 and display.barColor[4] == 1,
                    "Themed cast fill inherited masked native transparency: " .. key)
                assert(source:GetStatusBarTexture():GetAlpha() == 0, "Stock cast artwork was exposed")
                assert(display:GetStatusBarTexture():GetAlpha() == 1, "Themed cast fill is transparent")
                assert(display:IsVisible() and display:GetAlpha() == 1)
            end
        end
        source:SetStatusBarColor(0.9, 0.12, 0.1, 1)
        source:SetValue(4) source:SetAlpha(0.35)
        ns.castPoll.scripts.OnUpdate(ns.castPoll)
        assert(display.barColor[1] == 0.9 and display.barColor[4] == 1 and display:GetAlpha() == 0.35,
            "Native interrupt color or whole-bar fade was lost")
        source:Hide() ns.castPoll.scripts.OnUpdate(ns.castPoll)
        assert(not display:IsShown(), "Ended cast stayed visible")
        assert(source:GetParent() == nativeParent and source.scripts.OnUpdate == nativeScript,
            "Cast test replaced native ownership")
        for i, value in ipairs(point) do assert(({display:GetPoint()})[i] == value, "Cast progress moved its display") end
        assert(mutations == before, "Cast progress changed layout")
        source:SetAlpha(1)
    end
end
CheckCastFill()
if ns.bagDock then
    assert(ns.bagDock.protected and ns.bagFlyout.protected and not MainMenuBarBackpackButton.protected,
        "Auto-hide test did not distinguish explicit headers from ordinary native bags")
    assert(MainMenuBarBackpackButton:IsVisible(), "Collapsed backpack is not clickable")
    for i = 2, #bagButtons do assert(not bagButtons[i]:IsVisible(), "Collapsed bag slots remain visible") end
    local click, drag = bagButtons[2].scripts.OnClick, bagButtons[2].scripts.OnReceiveDrag
    for _, inCombat in ipairs({false, true}) do
        combat = inCombat
        local beforeHover = mutations
        MouseEnter(MainMenuBarBackpackButton)
        assert(ns.bagFlyout:IsShown() and ns.bagFlyout.autoHideDelay == 0.30)
        assert(MainMenuBarBackpackButton.tooltipUsed, "Parent hover header suppressed the native tooltip")
        for frame in pairs(ns.bagFlyout.autoHideRefs) do assert(frame.protected, "Auto-hide registered an ordinary native bag") end
        for i = 2, #bagButtons do
            local button = bagButtons[i]
            assert(button:IsVisible(), "Hover did not expose every native bag slot")
            MouseEnter(button)
            AutoHide(ns.bagFlyout, button)
            assert(ns.bagFlyout:IsShown(), "Flyout closed while hovering a bag")
        end
        bagButtons[2].scripts.OnClick(bagButtons[2]) bagButtons[2].scripts.OnReceiveDrag(bagButtons[2])
        assert(bagButtons[2].clicked and bagButtons[2].dragReceived)
        assert(click == bagButtons[2].scripts.OnClick and drag == bagButtons[2].scripts.OnReceiveDrag)
        for _, button in ipairs(bagButtons) do
            local original = nativeBagHandlers[button]
            assert(button.scripts.OnClick == original.click and button.scripts.OnReceiveDrag == original.drag
                and button.scripts.OnEnter == original.enter, "Hover replaced a native bag script")
        end
        AutoHide(ns.bagFlyout, MainMenuBarBackpackButton)
        assert(ns.bagFlyout:IsShown(), "Flyout closed while returning to the backpack")
        AutoHide(ns.bagFlyout, nil)
        assert(not ns.bagFlyout:IsShown(), "Flyout did not collapse after leaving")
        assert(mutations == beforeHover, "Hover changed geometry or secure configuration")
    end
    combat = false
    -- Toggling modes in combat must retain the existing secure setup until the
    -- normal out-of-combat reflow, then restore parents and full bag visibility.
    local beforeMode = mutations
    combat = true
    ns.SetUtilityMode("compactBags", false) Tick()
    assert(ns.pending and mutations == beforeMode and ns.bagDock:GetAttribute("compact"))
    combat = false Event("PLAYER_REGEN_ENABLED") Tick()
    for _, button in ipairs(bagButtons) do assert(button:IsVisible() and button:GetParent() == BagsBar) end
    ns.SetUtilityMode("compactBags", true) Tick()
    assert(MainMenuBarBackpackButton:IsVisible() and not bagButtons[2]:IsVisible())
end
local function CheckTriangleClicks()
    local width = ns.barAnchors[MainActionBar]:GetWidth()
    assert(width < 12 * ns.db.buttonSize + 11 * ns.db.gap, "Triangle row did not become compact")
    local previousRight
    for i, button in ipairs(MainActionBar.actionButtons) do
        local left, bottom, w, h = Rect(button)
        local scale = button:GetEffectiveScale()
        local insetLeft, insetRight, insetTop, insetBottom = button:GetHitRectInsets()
        local clickLeft, clickRight = left + insetLeft * scale, left + w - insetRight * scale
        assert(clickRight > clickLeft and h > (insetTop + insetBottom) * scale, "Button has no usable center")
        if previousRight then assert(clickLeft > previousRight, "Adjacent triangle click regions overlap") end
        previousRight = clickRight
        -- A center click must match precisely one native action button.
        local x, y = (clickLeft + clickRight) / 2, bottom + h / 2
        local hits = 0
        for _, candidate in ipairs(MainActionBar.actionButtons) do
            local cx, cy, cw, ch = Rect(candidate)
            local cs = candidate:GetEffectiveScale()
            local a, b, c, d = candidate:GetHitRectInsets()
            if x >= cx + a * cs and x <= cx + cw - b * cs
                and y >= cy + d * cs and y <= cy + ch - c * cs then
                hits = hits + 1
                assert(candidate == button, "Triangle center selected the neighboring ability")
            end
        end
        assert(hits == 1, "Triangle center did not map to one native button")
        local state = ns.buttonShapes[button]
        assert(state and state.active and button.icon.masks[state.mask])
        assert(state.mask.texture:find(i % 2 == 1 and "TriangleUp.tga" or "TriangleDown.tga", 1, true))
        assert(button.HighlightTexture.masks[state.mask] and button.Flash.masks[state.mask])
        assert(button.HighlightTexture:GetTexture() == "NativeHighlightTexture", "Native hover art was replaced")
        assert(button.cooldown.swipeTexture == state.mask.texture and button.lossOfControlCooldown.swipeTexture == state.mask.texture)
        assert(button.cooldown.drawEdge == false and button.cooldown.drawBling == false)
        assert(not button.ccuiBackground:IsShown() and state.border:IsShown())
    end
    if ns.experienceAnchor then assert(ns.experienceAnchor:GetWidth() == width, "Triangle EXP and action widths differ") end
end
if ns.db.buttonShape == "triangles" then CheckTriangleClicks() end
local visualPositions = {}
if ns.vehicleExitAnchor then
    Travel(true, false)
    visualPositions[MainMenuBarVehicleLeaveButton] = {Rect(MainMenuBarVehicleLeaveButton)}
    visualPositions[ns.vehicleExitAnchor] = {Rect(ns.vehicleExitAnchor)}
end
if ns.stanceAnchor then
    visualPositions[ns.stanceAnchor] = {Rect(ns.stanceAnchor)}
    for _, button in ipairs(StanceBar.actionButtons) do visualPositions[button] = {Rect(button)} end
end
if ns.menuAnchor then visualPositions[ns.menuAnchor] = {Rect(ns.menuAnchor)} end
if ns.minimapAnchor then
    visualPositions[Minimap] = {Rect(Minimap)}
    visualPositions[GameTimeFrame] = {Rect(GameTimeFrame)}
    visualPositions[ns.minimapAnchor] = {Rect(ns.minimapAnchor)}
end
for i, name in ipairs(barNames) do
    local bar = _G[name]
    visualPositions[ns.barAnchors[bar]] = {Rect(ns.barAnchors[bar])}
    for _, button in ipairs(bar.actionButtons) do visualPositions[button] = {Rect(button)} end
end
if ns.experienceAnchor then
    visualPositions[ns.experienceAnchor] = {Rect(ns.experienceAnchor)}
    for _, container in ipairs(StatusTrackingBarManager.barContainers) do
        visualPositions[ns.trackingAnchors[container]] = {Rect(ns.trackingAnchors[container])}
        for _, bar in pairs(container.bars) do
            visualPositions[bar] = {Rect(bar)}
            visualPositions[bar.StatusBar] = {Rect(bar.StatusBar)}
        end
    end
end
local positionsBeforeFight = {}
for _, frame in ipairs(managedFrames) do
    if ns.nativePositions[frame] then
        positionsBeforeFight[frame] = {parent = frame:GetParent(), point = {frame:GetPoint()}}
    end
end
combat = true NativeVisibility() NativeArrangement() Event("PLAYER_REGEN_DISABLED")
ns.barPoll.scripts.OnUpdate(ns.barPoll)
ns.trackingPoll.scripts.OnUpdate(ns.trackingPoll)
CheckCastFill()
local afterNativeMovement = mutations
Tick()
assert(mutations == afterNativeMovement, "Addon tried to restore protected geometry in combat")
if ns.vehicleExitAnchor then
    local before = addonMutations
    Travel(false, false) assert(not nativeExitButton:IsShown())
    Travel(true, false) CheckVehicleExit()
    nativeExitButton.scripts.OnEnter(nativeExitButton)
    nativeExitButton.scripts.OnClick(nativeExitButton)
    assert(nativeExitButton.nativeTooltip == "Land at next stop" and not nativeExitButton:IsEnabled())
    assert(addonMutations == before, "Showing/clicking the themed exit button moved protected geometry in combat")
end
if StatusTrackingBarManager and ns.db.modules.xp then
    for _, container in ipairs(StatusTrackingBarManager.barContainers) do
        assert(container:GetStatusTrackingManager() == StatusTrackingBarManager, "Combat lost native XP manager ownership")
        local beforeDividerRefresh = mutations
        local wasPending = ns.pending
        nativeContext = true container:UpdateDividers(25) nativeContext = false
        local afterDividerRefresh = mutations
        assert(afterDividerRefresh > beforeDividerRefresh, "Native pool refresh was not reproduced")
        assert(container.BarFrameTexture.alpha == 0, "Native EXP border escaped its theme")
        for divider in container.HorizontalDividersPool:EnumerateActive() do
            assert(divider:GetAlpha() == 0, "New EXP divider stayed visible during combat")
        end
        assert(ns.pending == wasPending, "Divider styling queued protected geometry instead of applying immediately")
        if TEST_MODE:match("^xp_late_refresh") then
            -- Recreate markers across a stock-width container without invoking
            -- the hooked instance method. This reproduces the visible spill.
            nativeContext = true
            container:SetSize(1200, 12)
            container.nativeDividerUpdater(container, 20)
            nativeContext = false
            container.secretLayout = true
            local afterLateRefresh, pendingBeforePoll = mutations, ns.pending
            local status = container.bars[1].StatusBar
            local nativeValue, nativeEvent, nativeHover = status:GetValue(), container.bars[1].scripts.OnEvent, container.bars[1].scripts.OnEnter
            ns.trackingPoll.scripts.OnUpdate(ns.trackingPoll)
            assert(container.BarFrameTexture:GetAlpha() == 0, "Late native refresh exposed the EXP border")
            for divider in container.HorizontalDividersPool:EnumerateActive() do
                assert(divider:GetAlpha() == 0 and divider.BarDividerTexture:GetAlpha() == 0,
                    "Late native refresh exposed an EXP pip beyond the themed strip")
                -- A reused frame can have its frame/texture alpha reset after
                -- the layout hook. The next presentation tick must restore it.
                divider:SetAlpha(1) divider.BarDividerTexture:SetAlpha(1)
            end
            container.BarFrameTexture:SetAlpha(1)
            ns.RefreshTrackingPanels()
            for divider in container.HorizontalDividersPool:EnumerateActive() do
                assert(divider:GetAlpha() == 0 and divider.BarDividerTexture:GetAlpha() == 0,
                    "EXP pip alpha reset escaped continuous suppression")
            end
            assert(mutations == afterLateRefresh and ns.pending == pendingBeforePoll,
                "Continuous EXP styling moved/hid protected frames or queued layout")
            assert(status:GetValue() == nativeValue and container.bars[1].scripts.OnEvent == nativeEvent
                and container.bars[1].scripts.OnEnter == nativeHover, "EXP pip styling altered progress or native input")
            container.secretLayout = false
        end
    end
    trackingBars[1].scripts.OnEvent(trackingBars[1], "PLAYER_XP_UPDATE")
    trackingBars[1].scripts.OnEnter(trackingBars[1])
    assert(trackingBars[1].tooltipUsed and trackingBars[1].StatusBar.value == xp, "Combat lost native XP updates/tooltip")
end
for frame, old in pairs(visualPositions) do
    local current = {Rect(frame)}
    for i, value in ipairs(old) do assert(math.abs(current[i] - value) < 0.00001, "Visible HUD inherited native combat movement") end
end
if ns.db.buttonShape == "triangles" then CheckTriangleClicks() end
CheckMenuGap()
if TEST_MODE:match("^combat_parent_shift") then
    assert(MainActionBar:GetParent() == nativeContainer, "Forced combat override did not move native bar")
    assert(MainActionBar:GetScale() == 0.73, "Forced combat override did not rescale native bar")
    assert(MainActionBar.actionButtons[1]:GetParent() == MainActionBar.actionButtons[1].container)
end
for frame, previous in pairs(TEST_MODE:match("^combat_parent_shift") and {} or positionsBeforeFight) do
    assert(frame:GetParent() == previous.parent, "Combat changed native managed parent")
    local current = {frame:GetPoint()}
    for i, value in ipairs(previous.point) do assert(current[i] == value, "Combat moved a configured panel") end
end
-- Native target/focus OnShow still runs under its original parent, even when
-- aura layout dimensions and cast values become secret. Presenters stay fixed.
if TargetFrameSpellBar then
    for _, source in ipairs({PlayerCastingBarFrame, TargetFrameSpellBar, FocusFrameSpellBar}) do
        source:Hide()
        source:SetMinMaxValues(Secret(), Secret())
        source:SetValue(Secret())
        source:SetStatusBarColor(Secret(), Secret(), Secret(), Secret())
        source.Text:SetText(Secret())
        source.Icon:SetTexture(Secret())
        source:Show()
    end
    local display = ns.castDisplays.targetcast
    local oldPoint = {display:GetPoint()}
    ns.castPoll.scripts.OnUpdate(ns.castPoll)
    assert(TargetFrameSpellBar:GetParent() == TargetFrame and FocusFrameSpellBar:GetParent() == FocusFrame)
    assert(issecretvalue(display.value) and issecretvalue(display.range[2]) and issecretvalue(display.Text:GetText()))
    assert(issecretvalue(display.barColor[1]) and display.barColor[4] == 1,
        "Secret RGB did not reach the cast widget with independent fill opacity")
    assert(TargetFrameSpellBar.secretLayout and TargetFrame.nativeArt.alpha == 0)
    assert(display:IsVisible(), "Target cast presenter stopped updating")
    for i, value in ipairs(oldPoint) do assert(({display:GetPoint()})[i] == value, "Cast moved on native OnShow") end
    TargetFrameSpellBar:Hide()
    ns.castPoll.scripts.OnUpdate(ns.castPoll)
    assert(not display:IsShown(), "Cast presenter did not stop with native cast")
    ns.castPoll.scripts.OnUpdate(ns.castPoll)
end
for i, name in ipairs(barNames) do assert(_G[name]:IsShown() == shownBeforeFight[i], "Bar disappeared when combat began") end
combat = false NativeVisibility() Event("PLAYER_REGEN_ENABLED") Tick()
if ns.stanceAnchor then
    local oldShape = ns.db.stanceShape
    local oldActionShape = ns.db.buttonShape
    local nativeClick = StanceBar.actionButtons[1].scripts.OnClick
    ns.SetStanceShape("triangles") Tick()
    assert(ns.db.buttonShape == oldActionShape, "Stance shape changed the main action-button shape")
    local first, second = StanceBar.actionButtons[1], StanceBar.actionButtons[2]
    assert(ns.buttonShapes[first].active and ns.buttonShapes[second].active)
    assert(ns.buttonShapes[first].mask.texture:find("TriangleUp.tga", 1, true)
        and ns.buttonShapes[second].mask.texture:find("TriangleDown.tga", 1, true))
    assert(first.scripts.OnClick == nativeClick and first:GetParent() == first.container)
    ns.SetStanceShape("square") Tick()
    assert(not ns.buttonShapes[first].active and first.hitInsets[1] == 0)
    ns.SetStanceShape(oldShape) Tick()
end
-- Exercise both shape directions, reversible masking, native click ownership,
-- border colors, settings UI, and a shape change requested during combat.
local button = MainActionBar.actionButtons[1]
local nativeClick, nativeDrag = button.scripts.OnClick, button.scripts.OnReceiveDrag
SlashCmdList.CLEANCENTERUI("shape triangles") Tick()
CheckTriangleClicks()
assert(button.scripts.OnClick == nativeClick and button.scripts.OnReceiveDrag == nativeDrag)
button.scripts.OnClick(button) button.scripts.OnReceiveDrag(button)
assert(button.nativeClicks == 1 and button.nativeDrags == 1)
SlashCmdList.CLEANCENTERUI("borders off") Tick()
assert(ns.buttonShapes[button].border.vertexColor[4] == 0)
SlashCmdList.CLEANCENTERUI("borders on") Tick()
assert(ns.buttonShapes[button].border.vertexColor[4] == ns.db.colors.border[4])
local beforeShapeChange = mutations
combat = true
ns.SetButtonShape("square") Tick()
assert(ns.pending and mutations == beforeShapeChange and ns.buttonShapes[button].active,
    "Combat shape change modified protected geometry")
combat = false Event("PLAYER_REGEN_ENABLED") Tick()
assert(not ns.buttonShapes[button].active and next(button.icon.masks) == nil)
assert(button.ccuiBackground:IsShown() and not ns.buttonShapes[button].border:IsShown())
assert(button.width == 48 and button.height == 48)
assert(button.hitInsets[1] == 0 and button.hitInsets[2] == 0)
assert(button.cooldown.drawEdge == false and button.cooldown.drawBling == true, "Square mode did not restore native cooldown flags")
assert(button.lossOfControlCooldown.drawEdge == true)
assert(button.Count:GetPoint() == "BOTTOMRIGHT", "Square mode lost stack-count placement")
assert(ns.barAnchors[MainActionBar]:GetWidth() == 642)
ns.options.shapeButtons.triangles.scripts.OnClick() Tick()
assert(ns.db.buttonShape == "triangles")
ns.options.shapeButtons.square.scripts.OnClick() Tick()
assert(ns.db.buttonShape == "square")
ns.SetButtonShape("hexagon") assert(ns.db.buttonShape == "square")
assert(classFlyout.OnEvent == nativeFlyoutEvent and classFlyout.scripts.OnEvent == nativeFlyoutEvent)
assert(classFlyout:GetParent() == UIParent and not classFlyout.ccuiBackground)
classFlyout.scripts.OnEvent(classFlyout, "UNIT_AURA") assert(classFlyout.nativeUpdates == 1)
injectedTaint[classFlyout] = {stateDirty = "SomeOtherAddon"}
SlashCmdList.CLEANCENTERUI("taint")
assert(ns.taintHistory[classFlyout:GetName() .. ".stateDirty"].owner == "SomeOtherAddon")
injectedTaint[classFlyout] = nil
assert(ns.unitFrames.player:GetParent() == ns.root)
assert(PlayerFrame:GetParent() == ns.hidden)
assert(ns.unitFrames.player.health.value and issecretvalue(ns.unitFrames.player.health.value))
assert(ns.unitFrames.player.name.text and issecretvalue(ns.unitFrames.player.name.text))
assert(PlayerFrame.classPowerBar:GetParent() == ns.root)
assert(ClickCastFrames[ns.unitFrames.target])
if StatusTrackingBarManager and ns.db.modules.xp then
    assert(StatusTrackingBarManager:GetParent() == ns.root)
    assert(StatusTrackingBarManager:GetWidth() == ns.BarMetrics().width)
    for _, container in ipairs(StatusTrackingBarManager.barContainers) do
        assert(container:GetStatusTrackingManager() == StatusTrackingBarManager, "Tracking manager parent lost")
        assert(container.ccuiPanel:GetFrameStrata() == "BACKGROUND", "Backdrop would cover native LOW-strata XP")
    end
    local bar = trackingBars[1]
    xp = 600
    bar.scripts.OnEvent(bar, "PLAYER_XP_UPDATE")
    assert(bar.StatusBar.value == 600 and bar.StatusBar.texture == ns.WHITE, "XP stopped updating or lost skin")
    bar.scripts.OnEnter(bar)
    assert(bar.tooltipUsed)
    rested = true
    combat = true
    bar:UpdateStatusBarTextures(true)
    assert(bar.StatusBar.barColor[1] == 0.38, "Rested styling did not survive a combat update")
    combat = false
    leveled = true
    StatusTrackingBarManager:UpdateBarsShown() Tick()
    assert(not StatusTrackingBarManager.barContainers[1]:IsShown(), "Max-level native hiding was overridden")
    ns.RefreshTrackingPanels()
    assert(not ns.trackingAnchors[StatusTrackingBarManager.barContainers[1]]:IsShown(), "Tracking border remained at level cap")
    leveled = false
    StatusTrackingBarManager:UpdateBarsShown() Tick()
elseif TEST_MODE == "xp_off" then
    assert(StatusTrackingBarManager:GetParent() == UIParent and not ns.movers.experience)
end
if MicroMenuContainer and ns.db.modules.menu then
    assert(MicroMenuContainer:GetParent() == ns.root and MicroMenu:GetParent() == MicroMenuContainer)
    for _, button in ipairs(microButtons) do
        assert(button.ccuiPanel and button.ccuiPanel.mouseEnabled == false)
        button.scripts.OnClick(button)
        button.scripts.OnEnter(button)
        assert(button.clicked and button.tooltipUsed, "Native micro button handlers changed")
    end
elseif TEST_MODE == "menu_off" then
    assert(MicroMenuContainer:GetParent() ~= ns.root and not ns.movers.menu)
end
if BagsBar then
    assert(BagsBar:GetParent() == ns.root and MainMenuBarBagManager == bagManager)
    for _, button in ipairs(bagButtons) do
        assert(button:GetParent() == (ns.bagDock and (button == MainMenuBarBackpackButton and ns.bagDock or ns.bagFlyout) or BagsBar)
            and button.ccuiPanel.mouseEnabled == false)
        button.scripts.OnClick(button)
        button.scripts.OnReceiveDrag(button)
        assert(button.clicked and button.dragReceived, "Native bag handlers changed")
    end
    if TEST_MODE == "menu_off" then
        local _, _, _, _, bagY = BagsBar:GetPoint()
        local _, _, _, _, anchorY = ns.bagAnchor:GetPoint()
        assert(anchorY == 18, "Bag-only layout reserves an absent menu")
    end
end
for i, name in ipairs(barNames) do
    for slot, button in ipairs(_G[name].actionButtons) do
        assert(button.actionSlot == (i - 1) * 12 + slot, "Action slots changed")
        assert(button:GetParent() == button.container, "Secure button was detached from its container")
    end
end
if Settings then
    assert(settings.PROXY_SHOW_ACTIONBAR_2 == true)
    assert(settings.PROXY_SHOW_ACTIONBAR_3 == false)
end
for _, count in ipairs({1, 3, 8, 2}) do
    ns.SetRows(count) Tick() Timers()
    for i = 2, 8 do assert(_G[barNames[i]]:IsShown() == (i <= count), "Incorrect visible bar count") end
    ns.RefreshBarPanels()
    for i, name in ipairs(barNames) do assert(ns.barAnchors[_G[name]]:IsShown() == (i <= count), "Extra row border remained visible") end
end
local before = mutations
combat = true
ns.SetRows(3) Tick()
assert(ns.pending and mutations == before, "Combat changes were not deferred")
assert(MultiBarBottomRight:IsShown() == false)
combat = false
Event("PLAYER_REGEN_ENABLED") Tick()
Timers()
assert(not ns.pending and MultiBarBottomRight:IsShown())
SlashCmdList.CLEANCENTERUI("borders off") Tick()
assert(Border(MainActionBar.ccuiPanel)[4] == 0)
assert(Border(MainActionBar.actionButtons[1].ccuiBackground)[4] == 0)
SlashCmdList.CLEANCENTERUI("borders on") Tick()
assert(Border(MainActionBar.ccuiPanel)[4] == 0.95)
before = mutations
combat = true
SlashCmdList.CLEANCENTERUI("borders off") Tick()
assert(ns.pending and mutations == before and Border(MainActionBar.ccuiPanel)[4] == 0.95)
combat = false
Event("PLAYER_REGEN_ENABLED") Tick()
assert(Border(MainActionBar.ccuiPanel)[4] == 0)
SlashCmdList.CLEANCENTERUI("borders on") Tick()
if PlayerCastingBarFrame then assert(Border(ns.castDisplays.cast.ccuiBackground)[4] == 0.95) end
if StatusTrackingBarManager and ns.db.modules.xp then
    assert(Border(StatusTrackingBarManager.barContainers[1].ccuiPanel)[4] == 0.95)
    ns.db.positions.experience = {x = 10, y = -400}
    ns.db.positions.menu = {x = 650, y = -420}
    ns.db.positions.bags = {x = 660, y = -370}
    ns.QueueLayout() Tick()
    local _, _, _, xpX, xpY = StatusTrackingBarManager:GetPoint()
    assert(xpX == 10 and xpY == -400)
    ns.db.buttonSize = 40
    ns.QueueLayout() Tick()
    assert(StatusTrackingBarManager:GetWidth() == ns.BarMetrics().width, "XP width did not follow resized ability bars")
    ns.db.buttonSize = 48
    ns.QueueLayout() Tick()
end
for _, invalid in ipairs({ "0", "9", "2.5", "abc" }) do ns.SetRows(invalid) assert(ns.db.rows == 3) end
local savedX, savedY = -300, -240
ns.db.positions.player = { x = savedX, y = savedY }
UIParent:SetSize(2560, 1440)
Event("DISPLAY_SIZE_CHANGED") Tick()
assert(ns.root:GetScale() == 1440 / 1080 * ns.db.scale)
local point, relative, relativePoint, x, y = ns.unitFrames.player:GetPoint(1)
assert(point == "CENTER" and relative == ns.root and x == savedX and y == savedY)
SlashCmdList.CLEANCENTERUI("bars 1") Tick()
assert(ns.db.rows == 1)
ns.ResetLayout() Tick()
assert(ns.db.rows == 2 and next(ns.db.positions) == nil)
ns.Unlock(true) assert(ns.unlocked)
assert(ns.movers.bar1:IsShown() and ns.movers.bar2:IsShown())
assert(not ns.movers.bar3:IsShown() and not ns.movers.bar8:IsShown())
Event("PLAYER_REGEN_DISABLED") assert(not ns.unlocked)
-- The bar edit overlays only receive clicks while explicitly unlocked.
local player, target = ns.unitFrames.player, ns.unitFrames.target
assert(not player.editors.health:IsShown() and not player.editors.power:IsShown())
ns.Unlock(true)
assert(player.editors.health:IsShown() and player.editors.power:IsShown())
player.editors.health.scripts.OnClick(player.editors.health)
assert(ns.appearance:IsShown() and ns.appearance.key == "player" and ns.appearance.section == "health")
assert(player:GetAttribute("*type1") == "target" and player:GetAttribute("*type2") == "togglemenu")
player.editors.power.scripts.OnClick(player.editors.power)
assert(ns.appearance.section == "power")
target.editors.health.scripts.OnClick(target.editors.health)
assert(ns.appearance.key == "target")
ns.OpenAppearance("player")
local window = ns.appearance
local entry = window.dimensions.width
entry.focused = true
entry:SetText("360")
entry.scripts.OnEnterPressed(entry) Tick()
assert(player:GetWidth() == 360 and not entry:HasFocus())
ns.SetUnitDimension("player", "healthHeight", 36)
ns.SetUnitDimension("player", "powerHeight", 14) Tick()
assert(player.health:GetHeight() == 36 and player.power:GetHeight() == 14 and player:GetHeight() == 87)
ns.SetUnitDimension("player", "height", 99) Tick()
assert(player:GetHeight() == 99 and player.health:GetHeight() == 48 and player.power:GetHeight() == 14)
window.portrait.scripts.OnClick() Tick()
assert(not player.portrait:IsShown())
-- Mock SetPoint resolves numeric offsets as the second argument.
local _, _, _, healthInset = player.health:GetPoint()
assert(healthInset == 6, "Hidden portrait still consumes bar space")
window.portrait.scripts.OnClick() Tick()
local _, _, _, restoredInset = player.health:GetPoint()
assert(player.portrait:IsShown() and restoredInset == 48)
local previous = ns.Copy(ns.db.unitStyles.player.healthColor)
window.healthColor.scripts.OnClick()
assert(ns.db.unitStyles.player.healthColor[4] == previous[4], "Picker setup corrupted alpha")
Pick(0.13, 0.27, 0.89, 0.65) Tick()
assert(not ns.db.unitStyles.player.classColor)
assert(player.health.barColor[1] == 0.13 and player.health.barColor[4] == 0.65)
assert(target.health.barColor[1] ~= 0.13, "Player color leaked to target")
ColorPickerFrame:OnCancel() Tick()
assert(ns.db.unitStyles.player.classColor and player.health.barColor[1] == RAID_CLASS_COLORS.PALADIN.r)
assert(ns.db.unitStyles.player.healthColor[4] == previous[4])
window.healthColor.scripts.OnClick()
Pick(0.9, 0.12, 0.38, 0.8)
ColorPickerFrame:OnOkay() Tick()
assert(player.health.barColor[3] == 0.38 and not ns.db.unitStyles.player.classColor)
window.class.scripts.OnClick() Tick()
assert(player.health.barColor[1] == RAID_CLASS_COLORS.PALADIN.r)
window.powerColor.scripts.OnClick()
Pick(0.2, 0.9, 0.45, 0.7)
ColorPickerFrame:OnOkay() Tick()
assert(not ns.db.unitStyles.player.powerTypeColor and player.power.barColor[2] == 0.9)
window.powerType.scripts.OnClick() Tick()
assert(player.power.barColor[2] == PowerBarColor.MANA.g)
-- Exact transparency (including zero) and HUD palette colors reach widgets.
ns.PickColor(ns.db.colors, "border") Pick(0.66, 0.18, 0.44, 0.4)
ColorPickerFrame:OnOkay() Tick()
assert(Border(MainActionBar.ccuiPanel)[1] == 0.66 and Border(MainActionBar.ccuiPanel)[4] == 0.4)
assert(Border(player)[3] == 0.44)
ns.PickColor(ns.db.colors, "text") Pick(0.7, 0.8, 0.9, 0.8)
ColorPickerFrame:OnOkay() Tick()
assert(player.name.textColor[1] == 0.7 and player.name.textColor[4] == 0.8)
ns.PickColor(ns.db.colors, "barBackground") Pick(0.15, 0.23, 0.31, 0)
ColorPickerFrame:OnOkay() Tick()
assert(player.health.background.colorTexture[4] == 0)
if StatusTrackingBarManager and ns.db.modules.xp then
    ns.PickColor(ns.db.colors, "rested") Pick(0.87, 0.28, 0.76, 0.9)
    ColorPickerFrame:OnOkay() Tick()
    assert(trackingBars[1].StatusBar.barColor[1] == 0.87)
end
-- One party style updates all five members and their automatic spacing.
ns.SetUnitDimension("party3", "healthHeight", 22) Tick()
for i = 1, 5 do assert(ns.unitFrames["party" .. i].health:GetHeight() == 22) end
local _, _, _, _, party1Y = ns.unitFrames.party1:GetPoint()
local _, _, _, _, party2Y = ns.unitFrames.party2:GetPoint()
assert(party1Y - party2Y == ns.db.unitStyles.party.height + 6)
ns.SetUnitDimension("player", "width", 9999) Tick()
assert(player:GetWidth() == 600)
entry.focused = true entry:SetText("480") entry.scripts.OnEscapePressed(entry) Tick()
assert(player:GetWidth() == 600, "Escape committed an unfinished size edit")
-- Geometry is deferred during either combat or Blizzard Edit Mode.
ns.Unlock(true)
combat = true Event("PLAYER_REGEN_DISABLED")
assert(not player.editors.health:IsShown() and not player.editors.power:IsShown())
before = mutations
ns.SetUnitDimension("player", "healthHeight", 50) Tick()
assert(ns.pending and player.health:GetHeight() == 48 and mutations == before)
player.editors.power.scripts.OnClick(player.editors.power)
assert(ns.appearance.key == "player" and ns.appearance.section == nil)
assert(EssentialCooldownViewer:GetParent() == UIParent and EssentialCooldownViewer.scripts.OnEvent == nativeCooldownEvent)
nativeCooldownEvent(EssentialCooldownViewer, "UNIT_AURA", "player")
assert(EssentialCooldownViewer.nativeAuraUpdates == 1)
combat = false Event("PLAYER_REGEN_ENABLED") Tick()
assert(player.health:GetHeight() == 50)
ns.Unlock(true)
EventRegistry:TriggerEvent("EditMode.Enter")
assert(ns.blizzardEditing and not ns.unlocked and not player.editors.health:IsShown())
before = mutations
ns.SetUnitDimension("player", "healthHeight", 52) Tick()
assert(player.health:GetHeight() == 50 and mutations == before)
EventRegistry:TriggerEvent("EditMode.Exit") Tick()
assert(not ns.blizzardEditing and player.health:GetHeight() == 52)
assert(nativeWrapperCalls == 0 and nativeCalls > 0)
assert(EssentialCooldownViewer.scripts.OnEvent == nativeCooldownEvent)
ns.OpenAppearance("party4", "health")
assert(ns.appearance.key == "party")
ns.ResetLayout() Tick()
assert(ns.db.unitStyles.player.width == 600, "Layout reset unexpectedly removed appearance settings")
ns.OpenAppearance("player")
for _, button in ipairs(window.controls) do
    if button.label:GetText() == "Reset this frame" then button.scripts.OnClick() break end
end
Tick()
assert(player:GetWidth() == 286 and player:GetHeight() == 66 and player.portrait:IsShown())
assert(ns.db.unitStyles.party.healthHeight == 22, "Frame reset leaked to another frame")
assert(ns.db.colors.border[1] == 0.66, "Frame reset unexpectedly removed HUD colors")
for _, button in ipairs(window.controls) do
    if button.label:GetText() == "Reset HUD colors" then button.scripts.OnClick() break end
end
Tick()
assert(ns.db.colors.border[1] == ns.defaults.colors.border[1])
assert(ns.db.unitStyles.party.healthHeight == 22, "Color reset unexpectedly removed frame sizes")
ns.OpenOptions() assert(ns.options:IsShown())
ns.Info()
local activeBeforeLogout = layoutStore.activeLayout
Event("PLAYER_LOGOUT")
assert(layoutStore.activeLayout == activeBeforeLogout, "Logout unexpectedly reset the active native profile")
local reloadsBeforeDisable = reloads
ns.SetEnabled(false)
assert(not ns.db.enabled and reloads == reloadsBeforeDisable + 1)
assert(GetMinimapShape == originalShape, "Turning the addon off did not restore the previous minimap shape provider")
for key, value in pairs(originalSettings) do assert(settings[key] == value, "Original setting lost: " .. key) end
assert(layoutStore.activeLayout == (TEST_MODE == "preset_layout" and 1 or 4), "Original native profile not restored")
assert(bagPreference == "0", "Original native bag-expansion preference was not restored")
if ChatFrame1 then
    assert(ChatFrame1:GetWidth() == 350 and ChatFrame1:GetHeight() == 160)
    assert(ChatFrame1:GetParent() == UIParent)
end
assert(#errors == 0, errors[1])
