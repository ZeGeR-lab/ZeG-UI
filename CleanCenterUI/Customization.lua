local _, ns = ...

ns.defaults.barSettings = {}
for i = 1, 8 do ns.defaults.barSettings[i] = {size = 0, spacing = -1, columns = 12, shape = "inherit", layout = "horizontal", border = "soft", keyPosition = "outside"} end
ns.defaults.editor = {snap = true, grid = 8, guides = true}
ns.defaults.fontFace = "standard"
ns.defaults.fontSettings = {}
for _, key in ipairs({"names", "health", "keybinds", "cooldowns", "casts", "chat", "auras", "tooltip", "swing", "meters"}) do
    ns.defaults.fontSettings[key] = {size = 0, outline = "OUTLINE"}
end
ns.defaults.themePreset, ns.defaults.classAccent = "teal", false
ns.defaults.auras = {enabled = true, size = 27, spacing = 5, columns = 8}
ns.defaults.tooltip = {enabled = true, anchor = "default"}
ns.defaults.swing = {enabled = true, width = 200, height = 6, visibility = "combat", time = false,
    useAccent = true, color = {0.35, 0.8, 0.95, 1}}
ns.defaults.fade = {enabled = false, delay = 3, alpha = 0.25, speed = 0.2, chat = true, bags = true, menu = true}
ns.defaults.meters = {enabled = true, colorMode = "native", color = {0.35, 0.8, 0.95, 1},
    opacity = -1, rowBorders = true, accentLine = true}
ns.defaults.trackers = {enabled = true, autoEnable = false, fontSize = 13, container = true,
    groups = {essential = true, utility = true, buffs = true, bars = true}, styles = {}}
for _, key in ipairs({"essential", "utility", "buffs", "bars"}) do
    ns.defaults.trackers.styles[key] = {scale = 1, fontSize = 0, background = true, skin = "framed", opacity = -1, timers = true, visibility = "always", layout = "fixed", arrangement = "native"}
end
ns.fontFaces = {standard = ns.FONT, friz = "Fonts\\FRIZQT__.TTF", arial = "Fonts\\ARIALN.TTF",
    skurri = "Fonts\\skurri.ttf", morpheus = "Fonts\\MORPHEUS.TTF"}
ns.fontRegistry = {}

function ns.Finite(value)
    return type(value) == "number" and ns.Readable(value) and value == value
        and value ~= math.huge and value ~= -math.huge
end
local function Number(value, default, lo, hi, whole)
    value = tonumber(value)
    if not ns.Finite(value) then value = default end
    value = ns.Clamp(value, lo, hi)
    return whole and math.floor(value + 0.5) or value
end
function ns.NormalizeCustomization()
    local db = ns.db
    db.trackers.fontSize = Number(db.trackers.fontSize, 13, 8, 32, true)
    for key in pairs(ns.defaults.trackers.styles) do
        local style = db.trackers.styles[key]
        if style.arrangement ~= "horizontal" and style.arrangement ~= "vertical" and style.arrangement ~= "cluster" and style.arrangement ~= "radial" then style.arrangement = "native" end
        if key == "bars" and style.arrangement == "radial" then style.arrangement = "vertical" end
        if style.layout ~= "compactOutOfCombat" then style.layout = "fixed" end
        if style.visibility ~= "hideCountdown" and style.visibility ~= "dimCountdown" then style.visibility = "always" end
        if key == "buffs" or key == "bars" then style.visibility = "always" end
        if style.skin ~= "minimal" and style.skin ~= "round" and style.skin ~= "tiles" and style.skin ~= "octagons" then style.skin = "framed" end
        style.opacity = Number(style.opacity, -1, -1, 1)
        if style.opacity < 0 then style.opacity = -1 end
        style.scale = Number(style.scale, 1, 0.25, 2.5)
        style.fontSize = Number(style.fontSize, 0, 0, 32, true)
        if style.fontSize > 0 then style.fontSize = math.max(8, style.fontSize) end
    end
    db.rows = Number(db.rows, 2, 1, 8, true)
    db.scale = Number(db.scale, 1, 0.65, 1.4)
    db.buttonSize = Number(db.buttonSize, 48, 28, 64, true)
    db.gap = Number(db.gap, 6, 0, 20)
    db.opacity = Number(db.opacity, 0.82, 0.25, 1)
    db.minimapSize = Number(db.minimapSize, 180, 120, 360, true)
    for i = 1, 8 do
        local bar = db.barSettings[i]
        bar.size = Number(bar.size, 0, 0, 64, true)
        if bar.size > 0 then bar.size = math.max(28, bar.size) end
        bar.spacing = Number(bar.spacing, -1, -1, 20)
        if bar.layout ~= "vertical" and bar.layout ~= "cluster" and bar.layout ~= "radial" then bar.layout = "horizontal" end
        if bar.border ~= "thin" and bar.border ~= "bold" and bar.border ~= "none" then bar.border = "soft" end
        if bar.keyPosition ~= "inside" then bar.keyPosition = "outside" end
        bar.columns = Number(bar.columns, 12, 1, 12, true)
        if bar.shape ~= "square" and bar.shape ~= "triangles" and bar.shape ~= "octagons" then bar.shape = "inherit" end
    end
    db.editor.grid = Number(db.editor.grid, 8, 4, 64, true)
    if not ns.fontFaces[db.fontFace] then db.fontFace = "standard" end
    for category in pairs(ns.defaults.fontSettings) do
        local font = db.fontSettings[category]
        font.size = Number(font.size, 0, 0, 32, true)
        if font.size > 0 then font.size = math.max(8, font.size) end
        if font.outline ~= "" and font.outline ~= "THICKOUTLINE" then font.outline = "OUTLINE" end
    end
    db.auras.size = 15 + 3 * math.floor((Number(db.auras.size, 27, 15, 60) - 15) / 3 + 0.5)
    db.auras.spacing = Number(db.auras.spacing, 5, 5, 15, true)
    db.auras.columns = Number(db.auras.columns, 8, 2, 16, true)
    if db.tooltip.anchor ~= "cursor" and db.tooltip.anchor ~= "fixed" then db.tooltip.anchor = "default" end
    -- Apply this layout change once to existing characters, including saved movers.
    if not db.swing.centerGapLayout then
        db.positions.swingmain, db.positions.swingoff, db.positions.swingranged = nil, nil, nil
        db.swing.width = math.min(Number(db.swing.width, 200, 100, 600, true), 200)
        db.swing.centerGapLayout = true
    end
    db.swing.width = Number(db.swing.width, 200, 100, 600, true)
    db.swing.height = Number(db.swing.height, 6, 4, 24, true)
    if db.swing.visibility ~= "always" then db.swing.visibility = "combat" end
    for i = 1, 4 do db.swing.color[i] = Number(db.swing.color[i], ns.defaults.swing.color[i], 0, 1) end
    db.fade.delay = Number(db.fade.delay, 3, 0, 60)
    db.fade.alpha = Number(db.fade.alpha, 0.25, 0, 1)
    db.fade.speed = Number(db.fade.speed, 0.2, 0.05, 3)
    db.meters.opacity = Number(db.meters.opacity, -1, -1, 1)
    if db.meters.opacity < 0 then db.meters.opacity = -1 end
    if db.meters.colorMode ~= "accent" and db.meters.colorMode ~= "custom" then db.meters.colorMode = "native" end
    for i = 1, 4 do db.meters.color[i] = Number(db.meters.color[i], ns.defaults.meters.color[i], 0, 1) end
    for key, position in pairs(db.positions) do
        if type(position) ~= "table" or not ns.Finite(position.x) or not ns.Finite(position.y)
            or math.abs(position.x) > 10000 or math.abs(position.y) > 10000 then db.positions[key] = nil end
    end
end

function ns.StyleFont(font, category, base)
    if not font or not font.SetFont or not ns.db then return end
    local record = ns.fontRegistry[font]
    if not record then
        record = {original = font.GetFont and {font:GetFont()} or {ns.FONT, base or 13, "OUTLINE"}}
        ns.fontRegistry[font] = record
    end
    record.category, record.base = category or "interface", base or record.base or 13
    local enabled = ns.db.enabled
    if category == "auras" then enabled = enabled and ns.db.auras.enabled
    elseif category == "tooltip" then enabled = enabled and ns.db.tooltip.enabled
    elseif category == "swing" then enabled = enabled and ns.db.swing.enabled
    elseif category == "chat" then enabled = enabled and ns.db.modules.chat end
    if not enabled and record.original[1] then font:SetFont(unpack(record.original)) return end
    local pref = ns.db.fontSettings[category]
    local face = pref and ns.fontFaces[ns.db.fontFace] or ns.FONT
    local size = pref and pref.size > 0 and pref.size or record.base
    if font:SetFont(face, size, pref and pref.outline or "OUTLINE") == false then
        font:SetFont(ns.FONT, size, pref and pref.outline or "OUTLINE")
    end
end
function ns.RefreshFonts()
    for font, record in pairs(ns.fontRegistry) do ns.StyleFont(font, record.category, record.base) end
end
function ns.SetBarPreference(row, key, value)
    if not ns.Finite(row) or row ~= math.floor(row) or row < 1 or row > 8 then return end
    if key == "shape" then
        if value ~= "inherit" and value ~= "square" and value ~= "triangles" and value ~= "octagons" then return end
    elseif key == "border" then
        if value ~= "thin" and value ~= "soft" and value ~= "bold" and value ~= "none" then return end
    elseif key == "keyPosition" then
        if value ~= "inside" and value ~= "outside" then return end
    elseif key == "layout" then
        if value ~= "horizontal" and value ~= "vertical" and value ~= "cluster" and value ~= "radial" then return end
    elseif key == "size" or key == "spacing" or key == "columns" then
        value = tonumber(value)
        if not ns.Finite(value) then return end
    else return end
    ns.db.barSettings[row][key] = value
    ns.NormalizeCustomization()
    ns.QueueLayout()
end
function ns.SnapCoordinate(value)
    return math.floor(value / ns.db.editor.grid + 0.5) * ns.db.editor.grid
end
function ns.SavePosition(key, x, y, snap)
    if not ns.movers[key] or not ns.Finite(x) or not ns.Finite(y) then return false end
    x, y = ns.Clamp(x, -10000, 10000), ns.Clamp(y, -10000, 10000)
    if snap and ns.db.editor.snap then x, y = ns.SnapCoordinate(x), ns.SnapCoordinate(y) end
    ns.db.positions[key] = {x = x, y = y}
    ns.QueueLayout()
    return true
end
function ns.CurrentPosition(key)
    if ns.db.positions[key] then return ns.db.positions[key].x, ns.db.positions[key].y end
    local mover = ns.movers[key]
    if not mover then return 0, 0 end
    local frame = mover.target
    local x, y, rx, ry = frame:GetCenter()
    rx, ry = ns.root:GetCenter()
    if not (ns.Finite(x) and ns.Finite(y) and ns.Finite(rx) and ns.Finite(ry)) then return 0, 0 end
    local factor = frame:GetEffectiveScale() / ns.root:GetEffectiveScale()
    if not ns.Finite(factor) then return 0, 0 end
    return x * factor - rx, y * factor - ry
end
function ns.MirrorUnitPositions(source)
    if source ~= "player" and source ~= "target" then return end
    if InCombatLockdown() and not ns.db.positions[source] then ns.Print("Leave combat before capturing a frame position.") return end
    local x, y = ns.CurrentPosition(source)
    ns.SavePosition(source == "player" and "target" or "player", -x, y, false)
end
function ns.RefreshGuides()
    if not ns.root then return end
    if not ns.guides then
        ns.guides = CreateFrame("Frame", nil, ns.root)
        ns.guides:SetAllPoints(ns.root)
        ns.guides:SetFrameStrata("BACKGROUND")
        ns.guides:EnableMouse(false)
        ns.guides.lines = {}
    end
    local guides = ns.guides
    for _, line in ipairs(guides.lines) do line:Hide() end
    local visible = ns.unlocked and ns.db.enabled and ns.db.editor.guides and not InCombatLockdown()
    guides:SetShown(visible or false)
    if not visible then return end
    local w, h = ns.root:GetWidth(), ns.root:GetHeight()
    if not ns.Finite(w) or not ns.Finite(h) then return end
    local grid = ns.db.editor.grid
    local stride = grid * math.max(1, math.ceil((w + h) / (grid * 500)))
    local count = 0
    local function Line(vertical, offset, center)
        count = count + 1
        local line = guides.lines[count]
        if not line then line = guides:CreateTexture(nil, "BACKGROUND") guides.lines[count] = line end
        line:ClearAllPoints()
        if vertical then
            line:SetPoint("TOP", guides, "TOP", offset, 0) line:SetPoint("BOTTOM", guides, "BOTTOM", offset, 0)
            line:SetWidth(center and 2 or 1)
        else
            line:SetPoint("LEFT", guides, "LEFT", 0, offset) line:SetPoint("RIGHT", guides, "RIGHT", 0, offset)
            line:SetHeight(center and 2 or 1)
        end
        local c = ns.db.colors.accent
        line:SetColorTexture(c[1], c[2], c[3], center and 0.65 or 0.1) line:Show()
    end
    for x = stride, w / 2, stride do Line(true, x) Line(true, -x) end
    for y = stride, h / 2, stride do Line(false, y) Line(false, -y) end
    Line(true, 0, true) Line(false, 0, true)
end
function ns.ResolveThemeAccent()
    if not ns.db.classAccent then return end
    local _, token = UnitClass("player")
    if ns.Readable(token) and token and RAID_CLASS_COLORS and RAID_CLASS_COLORS[token] then
        local c = RAID_CLASS_COLORS[token]
        ns.db.colors.accent = {c.r, c.g, c.b, 1}
    end
end
function ns.ApplyTheme(name)
    if name ~= "teal" and name ~= "gold" and name ~= "class" then return end
    if ns.CancelAppearanceColor then ns.CancelAppearanceColor() end
    ns.db.colors = ns.Copy(ns.defaults.colors)
    ns.db.themePreset, ns.db.classAccent = name, name == "class"
    if name == "gold" then
        ns.db.colors.panel = {0.025, 0.022, 0.018, 1}
        ns.db.colors.border = {0.5, 0.43, 0.27, 0.95}
        ns.db.colors.accent = {0.92, 0.73, 0.32, 1}
        ns.db.colors.experience = {0.72, 0.53, 0.23, 1}
        ns.db.colors.rested = {0.91, 0.77, 0.45, 1}
    end
    ns.ResolveThemeAccent()
    ns.QueueLayout()
end
