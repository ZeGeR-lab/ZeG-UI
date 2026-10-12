local _, ns = ...
local previousShape, shapeInstalled, masking = nil, false, false
local function SquareShape() return "SQUARE" end
ns.minimapShapeProvider = SquareShape

local function Quiet(region)
    if region and region.SetAlpha then region:SetAlpha(0) end
end

local function QuietHeader(frame)
    if not frame then return end
    for _, region in ipairs({frame:GetRegions()}) do Quiet(region) end
    if frame.NineSlice then
        for _, region in ipairs({frame.NineSlice:GetRegions()}) do Quiet(region) end
    end
end

local function MaskMinimap()
    if masking or not ns.db or not ns.db.enabled or not ns.db.modules.minimap or not Minimap then return end
    masking = true
    -- Camelot changes the stock mask when rotation changes. Keep our square
    -- mask using a public texture asset; no cast/health data or geometry.
    ns.NativeCall(Minimap.SetMaskTexture, Minimap, ns.WHITE)
    masking = false
end

local function SkinMinimapArt()
    if not ns.db or not ns.db.enabled or not ns.db.modules.minimap then return end
    Quiet(MinimapCompassTexture)
    Quiet(MinimapCompassTextureUnderlay)
    Quiet(MinimapBorder)
    Quiet(MinimapBorderTop)
    if MinimapBackdrop then Quiet(MinimapBackdrop.StaticOverlayTexture) end
    -- Hide the header's old art, preserving its clock/other child buttons.
    if MinimapCluster then QuietHeader(MinimapCluster.BorderTop) end
end

function ns.RefreshMinimapIcons()
    if InCombatLockdown() or not LibStub then return end
    local ok, lib = pcall(function() return LibStub("LibDBIcon-1.0", true) end)
    if not ok or not lib or not lib.GetButtonList or not lib.GetMinimapButton then return end
    local listed, names = pcall(lib.GetButtonList, lib)
    if not listed or type(names) ~= "table" then return end
    for _, name in ipairs(names) do
        local button = lib:GetMinimapButton(name)
        if button then
            if lib.SetButtonToPosition then
                -- Use the library's own shape/radius calculation. Angles,
                -- visibility, clicks, tooltips and dragging remain its own.
                local angle = button.db and button.db.minimapPos or button.minimapPos or 225
                pcall(lib.SetButtonToPosition, lib, button, angle)
            elseif lib.Refresh then
                -- Older versions expose Refresh only. Retain exact visibility
                -- and drag scripts, which Refresh otherwise reinitializes.
                local shown = button:IsShown()
                local start, stop = button:GetScript("OnDragStart"), button:GetScript("OnDragStop")
                pcall(lib.Refresh, lib, name)
                button:SetShown(shown)
                button:SetScript("OnDragStart", start)
                button:SetScript("OnDragStop", stop)
            end
        end
    end
end

function ns.RestoreMinimapShape()
    if shapeInstalled and GetMinimapShape == SquareShape then GetMinimapShape = previousShape end
    shapeInstalled = false
end

local function PlaceControl(frame, scale, point, relative, relativePoint, x, y)
    if not frame then return end
    ns.FixedScale(frame, scale)
    ns.ClearPoints(frame)
    ns.SetPoint(frame, point, relative, relativePoint, x or 0, y or 0)
end

function ns.ApplyMinimap()
    if not ns.db.modules.minimap or not MinimapCluster or not Minimap or not Minimap.SetMaskTexture then return end
    if InCombatLockdown() or ns.blizzardEditing then ns.pending = true return end
    if not ns.minimapBaseSize then
        local width = Minimap:GetWidth()
        ns.minimapBaseSize = ns.Readable(width) and type(width) == "number" and width > 0 and width or 198
    end
    local size, base = ns.db.minimapSize, ns.minimapBaseSize
    local scale = size / base
    if not shapeInstalled then previousShape, shapeInstalled = GetMinimapShape, true end
    GetMinimapShape = SquareShape
    if not ns.minimapAnchor then
        ns.minimapAnchor = CreateFrame("Frame", "CleanCenterUIMinimapAnchor", ns.root)
        ns.minimapAnchor:EnableMouse(false)
        ns.minimapAnchor:SetClampedToScreen(true)
        ns.AddMover(ns.minimapAnchor, "minimap", "Minimap")
    end
    local anchor = ns.minimapAnchor
    anchor:SetSize(size, size)
    ns.Position(anchor, "minimap", "TOPRIGHT", -20, -48)
    ns.Reparent(MinimapCluster, ns.root)
    ns.FixedScale(MinimapCluster, scale)
    ns.ClearPoints(MinimapCluster)
    ns.SetPoint(MinimapCluster, "CENTER", anchor, "CENTER")
    local saved = ns.db.positions.minimap
    if saved then
        ns.RecordNativePosition(MinimapCluster, "CENTER", "CENTER", saved.x / scale, saved.y / scale)
    else
        ns.RecordNativePosition(MinimapCluster, "CENTER", "TOPRIGHT", (-20 - size / 2) / scale, (-48 - size / 2) / scale)
    end
    -- Keep Blizzard's map/container parents and native input/event scripts.
    -- The rendered map has an independent anchor and ignores parent scale.
    ns.FixedScale(Minimap, scale)
    ns.SetSize(Minimap, base, base)
    ns.ClearPoints(Minimap)
    ns.SetPoint(Minimap, "CENTER", anchor, "CENTER")
    MaskMinimap()
    ns.Decorate(Minimap, "ccuiPanel", 3)
    local header = MinimapCluster.BorderTop
    if header then
        PlaceControl(header, scale, "BOTTOMLEFT", Minimap, "TOPLEFT", 0, 4)
        ns.SetSize(header, base, 22)
        ns.Decorate(header, "ccuiPanel", 0)
        local zone = MinimapCluster.ZoneTextButton
        PlaceControl(zone, scale, "LEFT", header, "LEFT", 4, 0)
        if zone then ns.SetSize(zone, math.max(60, base - 42), 18) end
        if MinimapZoneText then MinimapZoneText:SetWidth(math.max(60, base - 44)) end
        PlaceControl(GameTimeFrame, scale, "RIGHT", header, "RIGHT", -4, 0)
        PlaceControl(AddonCompartmentFrame, scale, "BOTTOMRIGHT", header, "TOPRIGHT", 0, 4)
    end
    PlaceControl(MinimapCluster.Tracking, scale, "TOPRIGHT", Minimap, "TOPLEFT", -5, 0)
    PlaceControl(MinimapCluster.IndicatorFrame, scale, "TOPRIGHT", Minimap, "TOPLEFT", -5, -24)
    PlaceControl(MinimapCluster.InstanceDifficulty, scale, "BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", -4, 4)
    PlaceControl(Minimap.ZoomHitArea, scale, "BOTTOMRIGHT", Minimap, "BOTTOMRIGHT")
    PlaceControl(Minimap.ZoomIn, scale, "BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", -4, 19)
    PlaceControl(Minimap.ZoomOut, scale, "BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", -22, 4)
    PlaceControl(ExpansionLandingPageMinimapButton, scale, "BOTTOMLEFT", Minimap, "BOTTOMLEFT", -15, -15)
    SkinMinimapArt()
    ns.Hook(Minimap, "SetMaskTexture", MaskMinimap)
    ns.Hook(MinimapCluster, "SetPoint", ns.QueueLayout)
    ns.Hook(Minimap, "SetSize", ns.QueueLayout)
    ns.Hook(Minimap, "SetPoint", ns.QueueLayout)
    ns.RefreshMinimapIcons()
end

local poll = CreateFrame("Frame")
ns.minimapPoll = poll
poll:SetScript("OnUpdate", function()
    if not ns.minimapAnchor or not Minimap then return end
    ns.minimapAnchor:SetShown(ns.db.enabled and ns.db.modules.minimap and Minimap:IsVisible())
    SkinMinimapArt()
end)

function ns.SetMinimapSize(value)
    value = tonumber(value)
    if not value then ns.Print("Choose a minimap size from 120 to 360.") return end
    ns.db.minimapSize = ns.Clamp(math.floor(value + 0.5), 120, 360)
    ns.QueueLayout()
end

function ns.ResetMinimap()
    ns.db.minimapSize, ns.db.positions.minimap = ns.defaults.minimapSize, nil
    ns.QueueLayout()
end

function ns.RefreshMinimapOptions()
    local window = ns.minimapOptions
    if not window then return end
    ns.Panel(window, 0.98)
    for _, button in ipairs(window.controls) do ns.ThemeButton(button) end
    if not window.sizeEntry:HasFocus() then window.sizeEntry:SetText(tostring(ns.db.minimapSize)) end
    if InCombatLockdown() and ns.pending then window.status:SetText("Size saved. Applies after combat.")
    elseif ns.blizzardEditing then window.status:SetText("Applies after closing Blizzard Edit Mode.")
    else window.status:SetText("Size follows your overall HUD scale.") end
end

function ns.OpenMinimapOptions()
    if ns.customize then ns.customize:Hide() end
    if ns.unsupported then ns.Info() return end
    if not ns.minimapOptions then
        local window = CreateFrame("Frame", "CleanCenterUIMinimapOptions", UIParent)
        ns.minimapOptions = window
        window.controls = {}
        window:SetSize(420, 270)
        window:SetPoint("CENTER")
        window:SetFrameStrata("DIALOG")
        window:SetFrameLevel(125)
        window:SetClampedToScreen(true)
        window:EnableMouse(true)
        window:SetMovable(true)
        window:RegisterForDrag("LeftButton")
        window:SetScript("OnDragStart", window.StartMoving)
        window:SetScript("OnDragStop", window.StopMovingOrSizing)
        local function Label(text, x, y, size)
            local label = ns.Font(window, size or 13)
            label:SetPoint("TOPLEFT", x, y) label:SetText(text)
            return label
        end
        local function Button(text, width, x, y, click)
            local button = CreateFrame("Button", nil, window)
            button:SetSize(width, 30) button:SetPoint("TOPLEFT", x, y)
            ns.Panel(button, 1)
            button.label = ns.Font(button, 13, "CENTER")
            button.label:SetPoint("CENTER") button.label:SetText(text)
            button:SetScript("OnClick", click)
            window.controls[#window.controls + 1] = button
            return button
        end
        Label("Square minimap", 24, -20, 20)
        Label("Size (120-360)", 24, -82)
        Button("X", 26, 378, -16, function() window:Hide() end)
        window.minus = Button("-", 30, 210, -74, function() ns.SetMinimapSize(ns.db.minimapSize - 10) end)
        window.plus = Button("+", 30, 318, -74, function() ns.SetMinimapSize(ns.db.minimapSize + 10) end)
        local entry = CreateFrame("EditBox", nil, window)
        window.sizeEntry = entry
        entry:SetSize(68, 30) entry:SetPoint("TOPLEFT", 245, -74)
        entry:SetFont(ns.FONT, 13, "OUTLINE") entry:SetTextColor(unpack(ns.db.colors.text))
        entry:SetJustifyH("CENTER") entry:SetAutoFocus(false)
        entry:SetNumeric(true) entry:SetMaxLetters(3) entry:SetTextInsets(3, 3, 0, 0)
        ns.Panel(entry, 1)
        entry:SetScript("OnEnterPressed", function() ns.SetMinimapSize(entry:GetText()) entry:ClearFocus() ns.RefreshMinimapOptions() end)
        entry:SetScript("OnEditFocusLost", function() ns.SetMinimapSize(entry:GetText()) ns.RefreshMinimapOptions() end)
        entry:SetScript("OnEscapePressed", function() entry:SetText(tostring(ns.db.minimapSize)) entry:ClearFocus() ns.RefreshMinimapOptions() end)
        window.move = Button("Move minimap", 165, 24, -130, function() window:Hide() ns.Unlock(true) end)
        window.reset = Button("Reset minimap", 165, 210, -130, ns.ResetMinimap)
        Label("Move: unlock panels, drag Minimap, then lock.", 24, -180, 12)
        Label("Compatible addon icons follow the square shape.", 24, -203, 12)
        window.status = Label("", 24, -236, 12)
        window:SetScript("OnShow", ns.RefreshMinimapOptions)
        window:Hide()
        UISpecialFrames[#UISpecialFrames + 1] = "CleanCenterUIMinimapOptions"
    end
    if ns.options then ns.options:Hide() end
    if ns.appearance then ns.appearance:Hide() end
    ns.RefreshMinimapOptions()
    ns.minimapOptions:SetShown(not ns.minimapOptions:IsShown())
end
