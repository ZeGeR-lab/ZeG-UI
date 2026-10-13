local addonName, ns = ...
_G.CleanCenterUI = ns
_G.ZeGUI = ns
ns.version = "0.4.13"
ns.WHITE = "Interface\\Buttons\\WHITE8X8"
ns.FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
ns.defaults = {
    enabled = true, rows = 2, scale = 1, buttonSize = 48, gap = 6,
    buttonShape = "square",
    stanceShape = "square", compactBags = true, menuDock = true, minimapSize = 180,
    cooldownNumbers = true,
    opacity = 0.82, borders = true, positions = {}, backup = {},
    modules = { bars = true, units = true, party = true, cast = true,
                chat = true, minimap = true, quests = true,
                xp = true, bags = true, menu = true },
    colors = {
        panel = {0.035, 0.04, 0.05, 1}, border = {0.42, 0.49, 0.54, 0.95},
        text = {0.94, 0.94, 0.94, 1}, accent = {0.35, 0.8, 0.95, 1},
        barBackground = {0.1, 0.11, 0.13, 1},
        experience = {0.50, 0.43, 0.76, 1}, rested = {0.38, 0.67, 0.82, 1},
    },
    unitStyles = {
        player = {width = 286, height = 66, healthHeight = 21, powerHeight = 8, portrait = true,
            classColor = true, powerTypeColor = true, healthColor = {0.28, 0.57, 0.33, 1}, powerColor = {0.2, 0.44, 0.72, 1}},
        target = {width = 286, height = 66, healthHeight = 21, powerHeight = 8, portrait = true,
            classColor = true, powerTypeColor = true, healthColor = {0.28, 0.57, 0.33, 1}, powerColor = {0.2, 0.44, 0.72, 1}},
        pet = {width = 158, height = 40, healthHeight = 12, powerHeight = 3, portrait = false,
            classColor = true, powerTypeColor = true, healthColor = {0.28, 0.57, 0.33, 1}, powerColor = {0.2, 0.44, 0.72, 1}},
        focus = {width = 158, height = 40, healthHeight = 12, powerHeight = 3, portrait = false,
            classColor = true, powerTypeColor = true, healthColor = {0.28, 0.57, 0.33, 1}, powerColor = {0.2, 0.44, 0.72, 1}},
        party = {width = 158, height = 40, healthHeight = 12, powerHeight = 3, portrait = false,
            classColor = true, powerTypeColor = true, healthColor = {0.28, 0.57, 0.33, 1}, powerColor = {0.2, 0.44, 0.72, 1}},
    },
}
ns.movers, ns.originalParents, ns.hooked = {}, {}, {}
ns.fonts = {}
ns.panels = {}
ns.panelTextures, ns.nativePositions, ns.frameScales = {}, {}, {}
local eventFrame = CreateFrame("Frame")
ns.events = eventFrame

function ns.Copy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for k, v in pairs(value) do out[k] = ns.Copy(v) end
    return out
end

local function Merge(target, defaults)
    for k, v in pairs(defaults) do
        if target[k] == nil then
            target[k] = ns.Copy(v)
        elseif type(v) == "table" then
            if type(target[k]) ~= "table" then target[k] = {} end
            Merge(target[k], v)
        end
    end
end

function ns.Clamp(value, lo, hi)
    return math.max(lo, math.min(hi, value))
end

function ns.BarMetrics(row)
    if not row then
        local widest = ns.BarMetrics(1)
        for i = 2, ns.db.rows do
            local metrics = ns.BarMetrics(i)
            if metrics.width > widest.width then widest = metrics end
        end
        return widest
    end
    local pref = ns.db.barSettings[row]
    local size = pref.size > 0 and pref.size or ns.db.buttonSize
    local shape = pref.shape == "inherit" and ns.db.buttonShape or pref.shape
    local triangle = shape == "triangles"
    local keyInside = pref.keyPosition == "inside"
    local labelHeight = keyInside and 4 or 20
    local height = triangle and math.floor(size * math.sqrt(3) / 2 + 0.5) or size
    local spacing = pref.spacing >= 0 and pref.spacing or (triangle and 2 or ns.db.gap)
    local pitch = (triangle and size / 2 or size) + spacing
    local columns = pref.layout == "vertical" and 1 or pref.layout == "cluster" and math.min(4, pref.columns) or pref.columns
    local lines = math.ceil(12 / columns)
    if pref.layout == "radial" then
        local radius = 2.8 * (size + spacing + 10)
        local extent = 2 * radius + size
        return {width = extent, rowHeight = extent + labelHeight, rowStep = extent + labelHeight + ns.db.gap,
            buttonWidth = size, buttonHeight = height, pitch = size + spacing,
            lineStep = height + labelHeight + spacing, keyInside = keyInside, borderStyle = pref.border, columns = 12, lines = 1,
            triangle = triangle, shaped = triangle or shape == "octagons", shape = shape, radial = true, radius = radius}
    end
    local rowHeight = lines * (height + labelHeight) + (lines - 1) * spacing
    return {width = size + (columns - 1) * pitch, buttonWidth = size, buttonHeight = height,
        pitch = pitch, rowHeight = rowHeight, rowStep = rowHeight + ns.db.gap,
        lineStep = height + labelHeight + spacing, keyInside = keyInside, borderStyle = pref.border, columns = columns, lines = lines, triangle = triangle, shaped = triangle or shape == "octagons", shape = shape}
end

function ns.BarSlot(metrics, index)
    if metrics.radial then
        local angle = math.pi / 2 - (index - 1) * 2 * math.pi / 12
        return metrics.radius + metrics.radius * math.cos(angle), (metrics.keyInside and 2 or 18) + metrics.radius + metrics.radius * math.sin(angle)
    end
    return ((index - 1) % metrics.columns) * metrics.pitch, (metrics.keyInside and 2 or 18) + math.floor((index - 1) / metrics.columns) * metrics.lineStep
end

function ns.BarOffset(row)
    local offset = ns.ActionBottom()
    for i = 1, row - 1 do offset = offset + ns.BarMetrics(i).rowHeight + ns.db.gap end
    return offset
end

function ns.TotalBarHeight()
    local height = 0
    for i = 1, ns.db.rows do height = height + ns.BarMetrics(i).rowHeight end
    return height + (ns.db.rows - 1) * ns.db.gap
end

function ns.TrackingHeight()
    if not ns.db.modules.xp or not StatusTrackingBarManager then return 0 end
    return math.max(1, #(StatusTrackingBarManager.barContainers or {})) * 16 - 4
end

function ns.MeasureUtilities()
    local menu = MicroMenu or MicroMenuContainer
    if not ns.db.modules.menu or not menu then ns.menuMetrics = nil return end
    local width, height = menu:GetWidth(), menu:GetHeight()
    if not ns.Readable(width) or width <= 0 then width = 360 end
    if not ns.Readable(height) or height <= 0 then height = 46 end
    if menu == MicroMenu and menu ~= MicroMenuContainer then
        local childScale = menu:GetScale()
        if ns.Readable(childScale) and childScale > 0 then width, height = width * childScale, height * childScale end
    end
    local scale = math.min(0.65, (ns.BarMetrics().width - 12) / (width + 10))
    ns.menuMetrics = {width = width * scale, height = height * scale,
        outerHeight = (height + 10) * scale, scale = scale,
        bottom = 18 + ns.TrackingHeight() + 6 + 5 * scale}
end

function ns.ActionBottom()
    if ns.db.menuDock and ns.db.modules.menu and ns.menuMetrics and not ns.db.positions.menu then
        return math.max(55, 18 + ns.TrackingHeight() + 6 + ns.menuMetrics.outerHeight + 12)
    end
    return 55
end

function ns.Print(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff8cc8dfZeG UI:|r " .. message)
    end
end

function ns.Readable(value)
    return not (issecretvalue and issecretvalue(value))
end

function ns.Font(parent, size, justify, category)
    local font = parent:CreateFontString(nil, "OVERLAY")
    font:SetFont(ns.FONT, size or 13, "OUTLINE")
    font:SetTextColor(unpack((ns.db or ns.defaults).colors.text))
    font:SetJustifyH(justify or "LEFT")
    ns.fonts[#ns.fonts + 1] = font
    if ns.StyleFont then ns.StyleFont(font, category, size or 13) end
    return font
end

function ns.SetPanelColor(frame, ...)
    local textures = ns.panelTextures[frame]
    if textures then textures.background:SetColorTexture(...) end
end

function ns.SetBorderColor(frame, ...)
    local textures = ns.panelTextures[frame]
    if textures then
        for _, edge in ipairs(textures.edges) do edge:SetColorTexture(...) end
    end
end

function ns.Panel(frame, alpha)
    -- Engine anchors size these textures. BackdropTemplate computes UVs from
    -- GetWidth/GetHeight in Lua, which fails on secret native layout dimensions.
    if not ns.panelTextures[frame] then
        local background = frame:CreateTexture(nil, "BACKGROUND")
        background:SetPoint("TOPLEFT", 1, -1)
        background:SetPoint("BOTTOMRIGHT", -1, 1)
        local edges = {}
        for i, anchors in ipairs({{"TOPLEFT", "TOPRIGHT"}, {"BOTTOMLEFT", "BOTTOMRIGHT"},
            {"TOPLEFT", "BOTTOMLEFT"}, {"TOPRIGHT", "BOTTOMRIGHT"}}) do
            local edge = frame:CreateTexture(nil, "BORDER")
            edge:SetPoint(anchors[1])
            edge:SetPoint(anchors[2])
            if i <= 2 then edge:SetHeight(1) else edge:SetWidth(1) end
            edges[i] = edge
        end
        ns.panelTextures[frame] = {background = background, edges = edges}
    end
    local palette = ns.db.colors
    local c = palette.panel
    ns.SetPanelColor(frame, c[1], c[2], c[3], c[4] * (alpha or ns.db.opacity))
    ns.SetBorderColor(frame, unpack(palette.border))
    ns.panels[frame] = {alpha = alpha, bar = false}
end

function ns.BarPanel(frame, alpha)
    ns.Panel(frame, alpha)
    local c = ns.db.colors.border
    ns.SetBorderColor(frame, c[1], c[2], c[3], ns.db.borders and c[4] or 0)
    ns.panels[frame].bar = true
end

-- Decorative panels never receive mouse input or replace native button scripts.
function ns.Decorate(frame, field, padding, alpha)
    local panel = frame[field]
    if not panel then
        panel = CreateFrame("Frame", nil, frame)
        panel.ignoreInLayout = true
        panel:SetPoint("TOPLEFT", -padding, padding)
        panel:SetPoint("BOTTOMRIGHT", padding, -padding)
        panel:SetFrameLevel(math.max(0, frame:GetFrameLevel() - 1))
        -- Native tracking fills use LOW strata, even when their manager uses
        -- MEDIUM. Keep our backdrop behind both so it cannot cover the fill.
        panel:SetFrameStrata("BACKGROUND")
        panel:EnableMouse(false)
        frame[field] = panel
    end
    ns.BarPanel(panel, alpha)
    return panel
end

function ns.Hook(object, method, callback)
    if not object or type(object[method]) ~= "function" then return end
    ns.hooked[object] = ns.hooked[object] or {}
    if ns.hooked[object][method] then return end
    ns.hooked[object][method] = true
    hooksecurefunc(object, method, callback)
end

function ns.RememberParent(frame)
    if not ns.originalParents[frame] then ns.originalParents[frame] = frame:GetParent() end
end

-- Edit Mode wraps SetPoint/ClearAllPoints/SetScale with Lua methods that write
-- shared snapping and manager state. Our geometry must bypass those wrappers;
-- their Base methods are the original widget methods installed by Blizzard.
function ns.SetPoint(frame, ...)
    ns.NativeCall(frame.SetPointBase or frame.SetPoint, frame, ...)
end

function ns.ClearPoints(frame)
    ns.NativeCall(frame.ClearAllPointsBase or frame.ClearAllPoints, frame)
end

function ns.SetScale(frame, value)
    ns.frameScales[frame] = value
    ns.NativeCall(frame.SetScaleBase or frame.SetScale, frame, value)
end

function ns.SetSize(frame, width, height)
    ns.NativeCall(frame.SetSize, frame, width, height)
end

function ns.FixedScale(frame, localScale)
    -- Visuals remain native children for visibility and event ownership, but
    -- their geometry must not inherit a moving/rescaled native bar hierarchy.
    ns.NativeCall(frame.SetIgnoreParentScale, frame, true)
    localScale = localScale or 1
    ns.SetScale(frame, ns.root:GetEffectiveScale() * localScale)
    ns.frameScales[frame] = localScale
end

function ns.NativeCall(func, ...)
    -- A call barrier is not a license to write Blizzard's shared Lua state.
    -- Use only widget Base methods here; native configuration uses C APIs.
    if securecallfunction then return securecallfunction(func, ...) end
    return func(...)
end

function ns.HideStock(frame)
    if not frame then return end
    ns.RememberParent(frame)
    if frame:GetParent() ~= ns.hidden then ns.NativeCall(frame.SetParent, frame, ns.hidden) end
end

function ns.MaskStockUnit(frame)
    if not frame then return end
    -- Target/focus spell bars call methods on their real unit-frame parent.
    -- Keep that parent alive; hide its artwork rather than moving the cast bar.
    ns.RememberParent(frame)
    local original = ns.originalParents[frame]
    if frame:GetParent() ~= original then ns.NativeCall(frame.SetParent, frame, original) end
    frame:EnableMouse(false)
    for _, region in ipairs({frame:GetRegions()}) do region:SetAlpha(0) end
    for _, child in ipairs({frame:GetChildren()}) do
        if child ~= frame.spellbar then
            child:SetAlpha(0)
            child:EnableMouse(false)
        end
    end
end

-- These frames stay alive; their original event handlers and secure actions are retained.
function ns.Reparent(frame, parent)
    if not frame then return end
    ns.RememberParent(frame)
    if frame:GetParent() ~= parent then ns.NativeCall(frame.SetParent, frame, parent) end
end

function ns.Position(frame, key, point, x, y)
    local saved = ns.db.positions[key]
    ns.ClearPoints(frame)
    if saved then
        ns.SetPoint(frame, "CENTER", ns.root, "CENTER", saved.x, saved.y)
        ns.RecordNativePosition(frame, "CENTER", "CENTER", saved.x, saved.y)
    else
        ns.SetPoint(frame, point, ns.root, point, x, y)
        ns.RecordNativePosition(frame, point, point, x, y)
    end
end

function ns.RecordNativePosition(frame, point, relativePoint, x, y)
    -- Single systems (bags, micro menu, minimap) have no systemIndex.
    if frame.system == nil then return end
    local scale = ns.root:GetScale() * (ns.frameScales[frame] or 1)
    ns.nativePositions[frame] = {point = point, relativeTo = "UIParent", relativePoint = relativePoint,
        offsetX = x * scale, offsetY = y * scale}
end

function ns.QueueLayout()
    if not ns.db or ns.applying or ns.restoring then return end
    if ns.db.enabled then ns.pending = true end
    if ns.RefreshOptions then ns.RefreshOptions() end
    if ns.RefreshAppearance then ns.RefreshAppearance() end
    if ns.RefreshMinimapOptions then ns.RefreshMinimapOptions() end
    if ns.RefreshCustomize then ns.RefreshCustomize() end
end

function ns.AddMover(frame, key, label)
    if ns.movers[key] then return end
    local mover = CreateFrame("Frame", nil, UIParent)
    mover.target = frame
    mover:SetAllPoints(frame)
    mover:SetFrameStrata("DIALOG")
    mover:EnableMouse(true)
    mover:RegisterForDrag("LeftButton")
    ns.Panel(mover, 0.62)
    ns.SetBorderColor(mover, unpack(ns.db.colors.accent))
    local text = ns.Font(mover, 12, "CENTER")
    text:SetPoint("CENTER")
    text:SetText(label)
    mover:SetScript("OnDragStart", function()
        if InCombatLockdown() then return end
        frame:SetMovable(true)
        frame:StartMoving()
        mover.dragging = true
    end)
    mover:SetScript("OnDragStop", function()
        if not mover.dragging then return end
        mover.dragging = nil
        frame:StopMovingOrSizing()
        local x, y = frame:GetCenter()
        local rx, ry = ns.root:GetCenter()
        if not (ns.Readable(x) and ns.Readable(y) and ns.Readable(rx) and ns.Readable(ry)) then
            ns.QueueLayout()
            return
        end
        -- GetCenter is reported in each frame's coordinate system.
        local factor = frame:GetEffectiveScale() / ns.root:GetEffectiveScale()
        ns.SavePosition(key, x * factor - rx, y * factor - ry, true)
    end)
    mover:SetScript("OnMouseUp", function(_, button)
        if button == "RightButton" then ns.selectedMover = key ns.OpenCustomize("layout") end
    end)
    mover:Hide()
    ns.movers[key] = mover
end

function ns.Unlock(value)
    if InCombatLockdown() then
        ns.Print("Leave combat before moving panels.")
        return
    end
    if value and ns.blizzardEditing then
        ns.Print("Close Blizzard Edit Mode before unlocking these panels.")
        return
    end
    ns.unlocked = value
    ns.RefreshMovers()
    if ns.RefreshOptions then ns.RefreshOptions() end
end

function ns.RefreshMovers()
    for key, mover in pairs(ns.movers) do
        local row = tonumber(key:match("^bar(%d+)$"))
        local visible = ns.unlocked and ns.db.enabled and (not row or row <= ns.db.rows)
        if key == "buffs" or key == "debuffs" then visible = visible and ns.db.auras.enabled
        elseif key == "tooltip" then visible = visible and ns.db.tooltip.enabled and ns.db.tooltip.anchor == "fixed"
        elseif key:match("^tracker") then visible = visible and ns.TrackerMoverVisible and ns.TrackerMoverVisible(key)
        elseif key:match("^swing") then visible = visible and ns.db.swing.enabled end
        mover:SetScale(ns.root:GetScale())
        mover:SetShown(visible or false)
        ns.Panel(mover, 0.62)
        ns.SetBorderColor(mover, unpack(ns.db.colors.accent))
    end
    if ns.RefreshBarEditors then ns.RefreshBarEditors() end
    if ns.RefreshGuides then ns.RefreshGuides() end
end

function ns.ResizeRoot()
    local scale = (UIParent:GetHeight() / 1080) * ns.db.scale
    ns.root:SetScale(scale)
    ns.root:SetSize(UIParent:GetWidth() / scale, UIParent:GetHeight() / scale)
    ns.root:ClearAllPoints()
    ns.root:SetPoint("CENTER", UIParent, "CENTER")
end

function ns.Apply()
    if ns.ConsumePendingProfile and not ns.ConsumePendingProfile() then return end
    if not ns.db or not ns.db.enabled then return end
    if InCombatLockdown() or ns.blizzardEditing then ns.pending = true return end
    ns.pending, ns.applying = false, true
    local ok, err = pcall(function()
        if ns.CaptureTaint then ns.CaptureTaint("before reflow") end
        if ns.ResolveThemeAccent then ns.ResolveThemeAccent() end
        if ns.PrepareNativeBars then ns.PrepareNativeBars() end
        if ns.PrepareSwingPreference then ns.PrepareSwingPreference() end
        if ns.CaptureTaint then ns.CaptureTaint("after native configuration") end
        ns.ResizeRoot()
        ns.MeasureUtilities()
        ns.nativePositions = {}
        for _, font in ipairs(ns.fonts) do font:SetTextColor(unpack(ns.db.colors.text)) end
        for panel, style in pairs(ns.panels) do
            if style.bar then ns.BarPanel(panel, style.alpha) else ns.Panel(panel, style.alpha) end
        end
        if ns.ApplyUnits then ns.ApplyUnits() end
        if ns.CaptureTaint then ns.CaptureTaint("after unit frames") end
        if ns.ApplyLayout then ns.ApplyLayout() end
        if ns.ApplyTrackers then ns.ApplyTrackers() end
        if ns.SyncNativePositions and ns.SyncNativePositions() then
            -- The C API invokes Blizzard's native placement before returning.
            -- Reapply our sizes/parenting once, after its settings are committed.
            if ns.ApplyLayout then ns.ApplyLayout() end
            if ns.ApplyTrackers then ns.ApplyTrackers() end
        end
        if ns.CaptureTaint then ns.CaptureTaint("after layout") end
        if ns.RefreshFonts then ns.RefreshFonts() end
        if ns.ApplyDamageMeters then ns.ApplyDamageMeters() end
        if ns.ApplyIdleFading then ns.ApplyIdleFading() end
        if ns.RefreshLauncher then ns.RefreshLauncher() end
    end)
    ns.applying = false
    if not ok then
        ns.lastError = tostring(err)
        ns.Print("Setup needs attention. Open /ccui info for details.")
        geterrorhandler()(err)
    end
    ns.RefreshMovers()
    if ns.RefreshOptions then ns.RefreshOptions() end
    if ns.RefreshAppearance then ns.RefreshAppearance() end
    if ns.RefreshMinimapOptions then ns.RefreshMinimapOptions() end
    if ns.RefreshCustomize then ns.RefreshCustomize() end
end

function ns.SetRows(count)
    count = tonumber(count)
    if not count or count ~= math.floor(count) or count < 1 or count > 8 then
        ns.Print("Choose a whole number of bars from 1 to 8.")
        return
    end
    ns.db.rows = count
    ns.QueueLayout()
    if InCombatLockdown() then ns.Print("Bar change saved; it will apply after combat.") end
end

function ns.Info()
    local version, build, _, interface = GetBuildInfo()
    ns.Print("v" .. ns.version .. "; client " .. version .. "; build " .. build .. "; interface " .. interface)
    ns.Print("MainActionBar: " .. tostring(MainActionBar ~= nil) .. "; native bar profile ready: " .. tostring(ns.nativeBarsReady == true))
    ns.Print("Health display API: " .. tostring(UnitHealthPercent ~= nil) .. "; visible bars: " .. ns.db.rows)
    ns.Print("Tracking bars: " .. tostring(StatusTrackingBarManager ~= nil) .. "; bags: " .. tostring(BagsBar ~= nil) .. "; micro menu: " .. tostring(MicroMenu ~= nil))
    if ns.lastError then ns.Print("Last setup error: " .. ns.lastError) end
    if ns.nativeBarWarning then ns.Print(ns.nativeBarWarning) end
end

local function Initialize()
    CleanCenterUIDB = type(CleanCenterUIDB) == "table" and CleanCenterUIDB or {}
    ns.db = CleanCenterUIDB
    Merge(ns.db, ns.defaults)
    if ns.NormalizeCustomization then ns.NormalizeCustomization() end
    if ns.InitializeProfiles then ns.InitializeProfiles() end
    ns.db.rows = ns.Clamp(math.floor(tonumber(ns.db.rows) or 2), 1, 8)
    ns.db.scale = ns.Clamp(tonumber(ns.db.scale) or 1, 0.65, 1.4)
    ns.db.buttonSize = ns.Clamp(tonumber(ns.db.buttonSize) or 48, 28, 64)
    ns.db.minimapSize = ns.Clamp(math.floor(tonumber(ns.db.minimapSize) or 180), 120, 360)
    if ns.db.buttonShape ~= "triangles" then ns.db.buttonShape = "square" end
    if ns.db.stanceShape ~= "triangles" then ns.db.stanceShape = "square" end
    ns.db.opacity = ns.Clamp(tonumber(ns.db.opacity) or 0.82, 0.25, 1)
    if ns.NormalizeAppearance then ns.NormalizeAppearance() end
    local _, _, _, interface = GetBuildInfo()
    if interface < 16000 or interface >= 17000 or not MainActionBar then
        ns.unsupported = true
        ns.Print("This test build targets WoW Forever's current UI. Use /ccui info to report your client.")
        return
    end
    ns.root = CreateFrame("Frame", "CleanCenterUIRoot", UIParent)
    ns.hidden = CreateFrame("Frame", "CleanCenterUIHidden", UIParent)
    ns.hidden:Hide()
    ns.ResizeRoot()
    if ns.CreateOptions then ns.CreateOptions() end
    if ns.CreateLauncher then ns.CreateLauncher() end
    -- EventRegistry callbacks run after Blizzard's own Edit Mode work. Do not
    -- hook its enter/exit scripts, modify its state, or reapply geometry mid-edit.
    if EventRegistry and EventRegistry.RegisterCallback then
        EventRegistry:RegisterCallback("EditMode.Enter", function()
            ns.blizzardEditing = true
            ns.Unlock(false)
        end, ns)
        EventRegistry:RegisterCallback("EditMode.Exit", function()
            ns.blizzardEditing = false
            ns.QueueLayout()
        end, ns)
    end
    if ns.db.enabled then
        ns.Apply()
        -- Reflow once Blizzard's startup and Edit Mode placement have finished.
        C_Timer.After(1, ns.QueueLayout)
        if not ns.db.installed then
            ns.db.installed = true
            ns.Print("Preset applied. /ccui opens settings; /ccui unlock moves panels.")
        end
    end
end

eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
eventFrame:RegisterEvent("UI_SCALE_CHANGED")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then Initialize() return end
    if not ns.db or ns.unsupported then return end
    if event == "PLAYER_LOGOUT" then
        -- Keep native preferences during reload/login. Explicit /ccui off
        -- restores the original layout and toggles before disabling the preset.
        return
    end
    if event == "PLAYER_REGEN_DISABLED" then
        -- Secure frames cannot be moved while fighting; stop an active edit session first.
        ns.unlocked = false
        for _, mover in pairs(ns.movers) do
            if mover.dragging then mover.target:StopMovingOrSizing() mover.dragging = nil end
            mover:Hide()
        end
        if ns.RefreshBarEditors then ns.RefreshBarEditors() end
        if ns.RefreshAppearance then ns.RefreshAppearance() end
        if ns.guides then ns.guides:Hide() end
        return
    end
    ns.QueueLayout()
end)
eventFrame:SetScript("OnUpdate", function()
    if ns.pendingProfile and not ns.unsupported and not InCombatLockdown() and not ns.blizzardEditing then
        if not ns.ConsumePendingProfile() then return end
    end
    if ns.pending and ns.db and ns.db.enabled and not ns.unsupported and not ns.blizzardEditing and not InCombatLockdown() then ns.Apply() end
end)
