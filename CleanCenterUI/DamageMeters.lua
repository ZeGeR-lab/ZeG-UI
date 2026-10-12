local _, ns = ...

-- Skin widgets only. Do not call meter refresh/configuration methods, inspect
-- combat sources, change native scripts, or store fields on Blizzard frames.
local live
local windows, entries, panels = {}, {}, {}
local quiet, fonts, tints, fills = {}, {}, {}, {}

local function Usable(widget)
    return widget and (not widget.IsForbidden or not widget:IsForbidden())
end
local function Write(record, callback)
    record.writing = true
    callback()
    record.writing = nil
end

local function Quiet(region)
    if not Usable(region) or not region.SetAlpha then return end
    local record = quiet[region]
    if not record then
        record = {alpha = region:GetAlpha()}
        quiet[region] = record
        ns.Hook(region, "SetAlpha", function(_, alpha)
            if record.writing then return end
            record.alpha = alpha
            if live then Write(record, function() region:SetAlpha(0) end) end
        end)
    end
    Write(record, function() region:SetAlpha(0) end)
end

local function ApplyFont(font, record)
    if not live then return end
    Write(record, function()
        if font:SetFont(live.face, live.fontSize > 0 and live.fontSize or record.base, live.outline) == false then
            font:SetFont(ns.FONT, live.fontSize > 0 and live.fontSize or record.base, live.outline)
        end
        font:SetTextColor(unpack(live.colors.text))
    end)
end
local function Font(font, base)
    if not Usable(font) or not font.SetFont or not font.GetTextColor then return end
    local record = fonts[font]
    if not record then
        record = {font = {font:GetFont()}, color = {font:GetTextColor()}, base = base or 13}
        fonts[font] = record
        ns.Hook(font, "SetFont", function(_, ...)
            if record.writing then return end
            record.font = {...}
            ApplyFont(font, record)
        end)
        ns.Hook(font, "SetTextColor", function(_, ...)
            if record.writing then return end
            record.color = {...}
            ApplyFont(font, record)
        end)
    end
    ApplyFont(font, record)
end

local function Tint(region, palette)
    if not Usable(region) or not region.GetVertexColor then return end
    local record = tints[region]
    if not record then
        record = {color = {region:GetVertexColor()}, palette = palette}
        tints[region] = record
        ns.Hook(region, "SetVertexColor", function(_, ...)
            if record.writing then return end
            record.color = {...}
            if live then Write(record, function() region:SetVertexColor(unpack(live.colors[record.palette])) end) end
        end)
    end
    Write(record, function() region:SetVertexColor(unpack(live.colors[record.palette])) end)
end

local function ApplyFill(texture, record)
    if not live then return end
    Write(record, function()
        texture:SetTexture(ns.WHITE)
        texture:SetTexCoord(0, 1, 0, 1)
        local color = record.color
        if live.colorMode == "accent" then color = live.colors.accent
        elseif live.colorMode == "custom" then color = live.color end
        -- Native class colors may be secret. Forward them without comparing,
        -- formatting, doing arithmetic, or looking up an actor's class.
        texture:SetVertexColor(unpack(color))
    end)
end
local function Fill(bar)
    local texture = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
    if not Usable(texture) or not texture.GetTexture or not texture.GetVertexColor then return end
    local record = fills[texture]
    if not record then
        local atlas = texture.GetAtlas and texture:GetAtlas()
        record = {texture = {texture:GetTexture()}, atlas = ns.Readable(atlas) and atlas and {atlas} or nil,
            coords = {texture:GetTexCoord()}, color = {texture:GetVertexColor()}}
        fills[texture] = record
        ns.Hook(texture, "SetTexture", function(_, ...)
            if record.writing then return end
            record.texture, record.atlas = {...}, nil
            ApplyFill(texture, record)
        end)
        ns.Hook(texture, "SetAtlas", function(_, ...)
            if record.writing then return end
            record.atlas = {...}
            ApplyFill(texture, record)
        end)
        ns.Hook(texture, "SetTexCoord", function(_, ...)
            if record.writing then return end
            record.coords = {...}
            ApplyFill(texture, record)
        end)
        ns.Hook(texture, "SetVertexColor", function(_, ...)
            if record.writing then return end
            record.color = {...}
            ApplyFill(texture, record)
        end)
    end
    ApplyFill(texture, record)
end

local function NewPanel(parent, top, bottom)
    -- No native dimension reads or BackdropTemplate UV calculations.
    if InCombatLockdown() and parent.IsProtected and parent:IsProtected() then
        ns.pending = true
        return
    end
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", top or parent, "TOPLEFT")
    panel:SetPoint("BOTTOMRIGHT", bottom or top or parent, "BOTTOMRIGHT")
    local level = parent:GetFrameLevel()
    if ns.Finite(level) then panel:SetFrameLevel(math.max(0, level - 1)) end
    panel:EnableMouse(false)
    ns.BarPanel(panel, live.opacity)
    panels[panel] = true
    return panel
end
local function Panel(panel)
    if not panel then return end
    local c, b = live.colors.panel, live.colors.border
    ns.panels[panel].alpha = live.opacity
    ns.SetPanelColor(panel, c[1], c[2], c[3], c[4] * live.opacity)
    ns.SetBorderColor(panel, b[1], b[2], b[3], live.borders and b[4] or 0)
    panel:Show()
end
local function Edges(parent)
    local result = {}
    for i, anchors in ipairs({{"TOPLEFT", "TOPRIGHT"}, {"BOTTOMLEFT", "BOTTOMRIGHT"},
        {"TOPLEFT", "BOTTOMLEFT"}, {"TOPRIGHT", "BOTTOMRIGHT"}}) do
        local edge = parent:CreateTexture(nil, "OVERLAY", nil, 1)
        edge:SetPoint(anchors[1]) edge:SetPoint(anchors[2])
        if i <= 2 then edge:SetHeight(1) else edge:SetWidth(1) end
        result[i] = edge
    end
    return result
end

local function Entry(entry)
    if not live or not Usable(entry) or not Usable(entry.StatusBar) then return end
    local bar = entry.StatusBar
    if not bar.Name or not bar.Value then return end
    local record = entries[entry]
    if not record then
        local background = bar:CreateTexture(nil, "BACKGROUND", nil, -1)
        background:SetAllPoints(bar)
        record = {background = background, edges = Edges(bar)}
        entries[entry] = record
        ns.Hook(entry, "UpdateStyle", function() if live then Entry(entry) end end)
    end
    Quiet(bar.Background) Quiet(bar.BackgroundEdge)
    Fill(bar) Font(bar.Name) Font(bar.Value)
    record.background:SetColorTexture(unpack(live.colors.barBackground))
    record.background:Show()
    local c = live.colors.border
    for _, edge in ipairs(record.edges) do
        edge:SetColorTexture(c[1], c[2], c[3], live.borders and live.rowBorders and c[4] or 0)
        edge:Show()
    end
end
local function ScanRows(frame, depth, refresh)
    if not Usable(frame) then return end
    if frame.StatusBar then
        if refresh or not entries[frame] then Entry(frame) end
        return
    end
    if depth == 0 or not frame.GetChildren then return end
    for _, child in ipairs({frame:GetChildren()}) do ScanRows(child, depth - 1, refresh) end
end
local function Controls(window)
    Font(window.SessionTimer)
    Font(window.SessionDropdown and window.SessionDropdown.SessionName)
    Font(window.DamageMeterTypeDropdown and window.DamageMeterTypeDropdown.TypeName)
    Font(window.MinimizeContainer and window.MinimizeContainer.NotActive)
    Tint(window.SettingsDropdown and window.SettingsDropdown.Icon, "text")
    for _, button in ipairs({window.MinimizeButton or false, window.CloseButton or false}) do
        if button then
            Tint(button:GetNormalTexture(), "text")
            Tint(button:GetPushedTexture(), "text")
            Tint(button:GetHighlightTexture(), "accent")
        end
    end
end
local function Source(window, refresh)
    if not Usable(window) then return end
    local record = windows[window]
    if record and not refresh then ScanRows(window.ScrollBox, 3) return end
    if not record then
        local panel = NewPanel(window)
        if not panel then return end
        record = {body = panel}
        windows[window] = record
    end
    Quiet(window.Background) Panel(record.body) Controls(window)
    ScanRows(window.ScrollBox, 3)
end
local function Session(window, refresh)
    if not live or not Usable(window) or not Usable(window.Header) or not Usable(window.MinimizeContainer) then return end
    local container = window.MinimizeContainer
    local record = windows[window]
    if record and not refresh then
        if not entries[container.LocalPlayerEntry] then Entry(container.LocalPlayerEntry) end
        ScanRows(container.ScrollBox, 3)
        Source(container.SourceWindow)
        return
    end
    if not record then
        local header = NewPanel(window, window.Header)
        if not header then return end
        local body = NewPanel(container)
        if not body then header:Hide() return end
        -- The container fills the full window. Start its backdrop below the
        -- header, and let its native visibility hide it when minimized.
        body:ClearAllPoints()
        body:SetPoint("TOPLEFT", window.Header, "BOTTOMLEFT")
        body:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT")
        local line = header:CreateTexture(nil, "OVERLAY")
        line:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 1, 0)
        line:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -1, 0)
        line:SetHeight(1)
        record = {header = header, body = body, line = line}
        windows[window] = record
        ns.Hook(window, "InitEntry", function(_, entry) if live and not entries[entry] then Entry(entry) end end)
    end
    Quiet(window.Header) Quiet(container.Background)
    Panel(record.header) Panel(record.body) Controls(window)
    local c = live.colors.accent
    record.line:SetColorTexture(c[1], c[2], c[3], live.accentLine and c[4] or 0)
    Entry(container.LocalPlayerEntry)
    ScanRows(container.ScrollBox, 3)
    Source(container.SourceWindow, refresh)
end
local function Discover(refresh)
    -- These public window names are created by the current Forever client.
    -- Avoid its windowDataList, combat data providers and internal frame pools.
    for i = 1, 3 do Session(_G["DamageMeterSessionWindow" .. i], refresh) end
end

function ns.RestoreDamageMeters()
    live = nil
    for region, record in pairs(quiet) do
        if Usable(region) then Write(record, function() region:SetAlpha(record.alpha) end) end
    end
    for font, record in pairs(fonts) do
        if Usable(font) then Write(record, function()
            font:SetFont(unpack(record.font)) font:SetTextColor(unpack(record.color))
        end) end
    end
    for region, record in pairs(tints) do
        if Usable(region) then Write(record, function() region:SetVertexColor(unpack(record.color)) end) end
    end
    for texture, record in pairs(fills) do
        if Usable(texture) then Write(record, function()
            if record.atlas then texture:SetAtlas(unpack(record.atlas)) else texture:SetTexture(unpack(record.texture)) end
            texture:SetTexCoord(unpack(record.coords)) texture:SetVertexColor(unpack(record.color))
        end) end
    end
    for panel in pairs(panels) do panel:Hide() end
    for _, record in pairs(entries) do
        record.background:Hide()
        for _, edge in ipairs(record.edges) do edge:Hide() end
    end
end
function ns.ApplyDamageMeters()
    if not ns.db.enabled or not ns.db.meters.enabled then ns.RestoreDamageMeters() return end
    local pref, font = ns.db.meters, ns.db.fontSettings.meters
    live = {colorMode = pref.colorMode, color = ns.Copy(pref.color), colors = ns.Copy(ns.db.colors),
        opacity = pref.opacity >= 0 and pref.opacity or ns.db.opacity,
        borders = ns.db.borders, rowBorders = pref.rowBorders, accentLine = pref.accentLine,
        face = ns.fontFaces[ns.db.fontFace], fontSize = font.size, outline = font.outline}
    Discover(true)
    for entry in pairs(entries) do Entry(entry) end
end

-- Catch windows loaded/created after login, and rows materialized by scrolling
-- or a cached native initializer. This is bounded widget discovery, not a
-- combat-log poll. Existing artwork updates are handled by secure post-hooks.
local poll, since = CreateFrame("Frame"), 0
ns.meterPoll = poll
poll:SetScript("OnUpdate", function(_, elapsed)
    if not live or not ns.db or not ns.db.enabled or ns.restoring or ns.blizzardEditing then return end
    since = since + (ns.Finite(elapsed) and elapsed or 0)
    if since < 0.5 then return end
    since = 0
    Discover()
end)
