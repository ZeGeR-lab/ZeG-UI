local _, ns = ...
local pages = {{"profiles", "Profiles"}, {"layout", "Alignment"}, {"bars", "Action bars"}, {"fonts", "Fonts"},
    {"themes", "Themes"}, {"auras", "Buffs / tooltips"}, {"swing", "Swing timer"}, {"fade", "Idle fading"},
    {"meters", "Damage meters"}, {"trackers", "Trackers"}}
local fontKeys = {"names", "health", "keybinds", "cooldowns", "casts", "chat", "auras", "tooltip", "swing", "meters"}
local function Label(parent, text, x, y, size)
    local label = ns.Font(parent, size or 13)
    label:SetPoint("TOPLEFT", x or 0, y or 0) label:SetText(text)
    return label
end
local function Button(parent, text, x, y, width, click)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width or 170, 28) button:SetPoint("TOPLEFT", x, y)
    ns.Panel(button, 1)
    button.label = ns.Font(button, 12, "CENTER") button.label:SetPoint("CENTER") button.label:SetText(text)
    button:SetScript("OnClick", click)
    parent.window.controls[#parent.window.controls + 1] = button
    return button
end
local function Entry(parent, x, y, width)
    local box = CreateFrame("EditBox", nil, parent)
    box:SetSize(width or 80, 28) box:SetPoint("TOPLEFT", x, y)
    box:SetFont(ns.FONT, 13, "OUTLINE") box:SetAutoFocus(false) box:SetMaxLetters(40)
    box:SetTextInsets(6, 6, 3, 3) ns.Panel(box, 0.9)
    return box
end
local function Refresh(parent, callback) parent.window.refreshers[#parent.window.refreshers + 1] = callback end
local function Changed()
    ns.NormalizeCustomization() ns.QueueLayout()
end
local function Number(parent, text, y, get, set, lo, hi, step)
    Label(parent, text, 0, y - 5)
    local box = Entry(parent, 242, y, 80)
    local function Change(value)
        value = tonumber(value)
        if ns.Finite(value) then set(ns.Clamp(value, lo, hi)) Changed() end
    end
    Button(parent, "-", 204, y, 30, function() Change(get() - step) end)
    Button(parent, "+", 330, y, 30, function() Change(get() + step) end)
    local cancelling = false
    box:SetScript("OnEnterPressed", function(self) Change(self:GetText()) self:ClearFocus() ns.RefreshCustomize() end)
    box:SetScript("OnEditFocusLost", function(self) if not cancelling then Change(self:GetText()) end ns.RefreshCustomize() end)
    box:SetScript("OnEscapePressed", function(self) cancelling = true self:ClearFocus() cancelling = false ns.RefreshCustomize() end)
    Refresh(parent, function() if not box:HasFocus() then box:SetText(string.format("%.3g", get())) end end)
    return box
end
local function Toggle(parent, text, y, get, set)
    Label(parent, text, 0, y - 5)
    local button = Button(parent, "", 204, y, 346, function() set(not get()) Changed() end)
    Refresh(parent, function() button.label:SetText(get() and "On" or "Off") ns.ThemeButton(button, get()) end)
    return button
end
local function Choice(parent, text, y, choices, get, set)
    Label(parent, text, 0, y - 5)
    local button = Button(parent, "", 204, y, 346, function()
        local index = 0
        for i, choice in ipairs(choices) do if choice[1] == get() then index = i break end end
        set(choices[index % #choices + 1][1]) Changed()
    end)
    Refresh(parent, function()
        for _, choice in ipairs(choices) do if choice[1] == get() then button.label:SetText(choice[2]) return end end
        button.label:SetText("Select")
    end)
    return button
end
local function Help(parent, text, y)
    local label = Label(parent, text, 0, y, 12) label:SetWidth(548) label:SetHeight(48)
end
local function Status(window, ok, message)
    window.message = message or (ok and "Saved." or "Check the value.")
    ns.RefreshCustomize()
end
local function Move(key)
    ns.selectedMover = key ns.OpenCustomize("layout") ns.Unlock(true)
end

local function Profiles(page)
    local window = page.window
    Label(page, "Profile name", 0, -6)
    window.profileName = Entry(page, 124, 0, 426)
    window.profileName:SetText(ns.db.profileName or "My layout")
    local function Name() return window.profileName:GetText() end
    Button(page, "Save / overwrite", 0, -40, 172, function() Status(window, ns.SaveProfile(Name())) end)
    Button(page, "Load", 189, -40, 172, function() Status(window, ns.LoadProfile(Name())) end)
    Button(page, "Delete", 378, -40, 172, function() Status(window, ns.DeleteProfile(Name())) end)
    local select = Button(page, "Choose a saved profile", 0, -80, 550, function()
        local names = ns.ProfileNames()
        if #names == 0 then Status(window, false, "Save a profile first.") return end
        local index = 0
        for i, name in ipairs(names) do if name == Name() then index = i break end end
        window.profileName:SetText(names[index % #names + 1]) ns.RefreshCustomize()
    end)
    Refresh(page, function() select.label:SetText(#ns.ProfileNames() .. " saved profiles  |  Click to cycle") end)
    local scroll = CreateFrame("ScrollFrame", nil, page, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 0, -190) scroll:SetSize(526, 210)
    local text = CreateFrame("EditBox", nil, scroll)
    text:SetWidth(510) text:SetHeight(210) text:SetMultiLine(true) text:SetFont(ns.FONT, 11, "")
    text:SetAutoFocus(false) text:SetMaxLetters(65536) text:SetTextInsets(6, 6, 6, 6)
    text:SetScript("OnEscapePressed", text.ClearFocus)
    text:SetScript("OnTextChanged", function(self)
        local _, count = self:GetText():gsub("\n", "") self:SetHeight(math.max(210, (count + 2) * 14))
    end)
    scroll:SetScrollChild(text) ns.Panel(scroll, 0.9)
    window.profileText = text
    local function Export(name)
        local value, err = ns.ExportProfile(name)
        if not value then Status(window, false, err) return end
        text:SetText(value) text:SetFocus() text:HighlightText() scroll:SetVerticalScroll(0)
        Status(window, true, "Export ready. Ctrl+C copies the selected text.")
    end
    Button(page, "Export current", 0, -120, 172, function() Export() end)
    Button(page, "Export saved", 189, -120, 172, function() Export(Name()) end)
    Button(page, "Import as named", 378, -120, 172, function() Status(window, ns.ImportProfile(Name(), text:GetText())) end)
    Help(page, "Copy or paste profile text below. Imported profiles are saved before you load them.", -160)
    Help(page, "Profiles are shared across your characters. Spells and keybindings stay in their native slots.", -419)
end
local function Alignment(page)
    local window = page.window
    local function Key()
        if ns.selectedMover and ns.movers[ns.selectedMover] then return ns.selectedMover end
        for key in pairs(ns.movers) do ns.selectedMover = key return key end
        return "player"
    end
    local selection = Button(page, "", 204, 0, 346, function()
        local keys = {} for key in pairs(ns.movers) do keys[#keys + 1] = key end table.sort(keys)
        local index = 0 for i, key in ipairs(keys) do if key == Key() then index = i break end end
        ns.selectedMover = keys[index % math.max(1, #keys) + 1] ns.RefreshCustomize()
    end)
    Label(page, "Panel", 0, -5)
    Refresh(page, function() selection.label:SetText(Key()) end)
    Number(page, "Center X", -42, function() local x = ns.CurrentPosition(Key()) return x end,
        function(x) local _, y = ns.CurrentPosition(Key()) ns.SavePosition(Key(), x, y, false) end, -10000, 10000, 1)
    Number(page, "Center Y", -84, function() local _, y = ns.CurrentPosition(Key()) return y end,
        function(y) local x = ns.CurrentPosition(Key()) ns.SavePosition(Key(), x, y, false) end, -10000, 10000, 1)
    Toggle(page, "Snap dragged panels", -126, function() return ns.db.editor.snap end, function(v) ns.db.editor.snap = v end)
    Toggle(page, "Grid and center guides", -168, function() return ns.db.editor.guides end, function(v) ns.db.editor.guides = v end)
    Number(page, "Grid spacing", -210, function() return ns.db.editor.grid end, function(v) ns.db.editor.grid = v end, 4, 64, 4)
    Button(page, "Mirror player to target", 0, -252, 266, function() ns.MirrorUnitPositions("player") end)
    Button(page, "Mirror target to player", 284, -252, 266, function() ns.MirrorUnitPositions("target") end)
    Button(page, "Center horizontally", 0, -294, 266, function() local _, y = ns.CurrentPosition(Key()) ns.SavePosition(Key(), 0, y, false) end)
    Button(page, "Reset selected position", 284, -294, 266, function() ns.db.positions[Key()] = nil ns.QueueLayout() end)
    local unlock = Button(page, "Unlock panels", 0, -336, 550, function() ns.Unlock(not ns.unlocked) ns.RefreshCustomize() end)
    Refresh(page, function() unlock.label:SetText(ns.unlocked and "Lock panels" or "Unlock panels") end)
    Help(page, "Drag while unlocked. Right-click any mover to select it here. Exact coordinates do not snap.", -386)
end
local function Bars(page)
    local window = page.window window.bar = 1
    Label(page, "Choose the bar to edit", 0, -2)
    for i = 1, 8 do
        local row = i
        local button = Button(page, tostring(i), (i - 1) * 70, -30, 60, function() window.bar = row ns.RefreshCustomize() end)
        Refresh(page, function() ns.ThemeButton(button, window.bar == row) end)
    end
    local function Pref() return ns.db.barSettings[window.bar] end
    Number(page, "Button size (0 = global)", -82, function() return Pref().size end,
        function(v) ns.SetBarPreference(window.bar, "size", v) end, 0, 64, 2)
    Number(page, "Spacing (-1 = global)", -124, function() return Pref().spacing end,
        function(v) ns.SetBarPreference(window.bar, "spacing", v) end, -1, 20, 1)
    Number(page, "Buttons per line", -166, function() return Pref().columns end,
        function(v) ns.SetBarPreference(window.bar, "columns", v) end, 1, 12, 1)
    Choice(page, "Shape", -208, {{"inherit", "Use global shape"}, {"square", "Squares"}, {"triangles", "Alternating triangles"}},
        function() return Pref().shape end, function(v) ns.SetBarPreference(window.bar, "shape", v) end)
    Button(page, "Reset this bar", 0, -260, 266, function() ns.db.barSettings[window.bar] = ns.Copy(ns.defaults.barSettings[1]) Changed() end)
    Button(page, "Use on all bars", 284, -260, 266, function()
        local pref = ns.Copy(Pref()) for i = 1, 8 do ns.db.barSettings[i] = ns.Copy(pref) end Changed()
    end)
    local summary = Label(page, "", 0, -312)
    Refresh(page, function() local m = ns.BarMetrics(window.bar) summary:SetText("12 slots  |  " .. m.columns .. " per line  |  " .. m.lines .. " lines") end)
    Help(page, "All 12 slots remain available. Choose the number of visible bars in the main CCUI menu.", -351)
end
local function Fonts(page)
    local window = page.window window.fontCategory = "names"
    for i, key in ipairs(fontKeys) do
        local category = key
        local button = Button(page, key, ((i - 1) % 3) * 189, -math.floor((i - 1) / 3) * 38, 172,
            function() window.fontCategory = category ns.RefreshCustomize() end)
        Refresh(page, function() ns.ThemeButton(button, window.fontCategory == category) end)
    end
    local function Pref() return ns.db.fontSettings[window.fontCategory] end
    Choice(page, "Font family", -166, {{"standard", "Game default"}, {"friz", "Friz Quadrata"}, {"arial", "Arial"},
        {"skurri", "Skurri"}, {"morpheus", "Morpheus"}}, function() return ns.db.fontFace end, function(v) ns.db.fontFace = v end)
    Number(page, "Size (0 = automatic)", -208, function() return Pref().size end, function(v) Pref().size = v end, 0, 32, 1)
    Choice(page, "Outline", -250, {{"", "None"}, {"OUTLINE", "Outline"}, {"THICKOUTLINE", "Thick outline"}},
        function() return Pref().outline end, function(v) Pref().outline = v end)
    local preview = Label(page, "Player name  92%  12.5  SHIFT-1", 0, -316, 16)
    Refresh(page, function() ns.StyleFont(preview, window.fontCategory, 16) end)
    Button(page, "Reset font settings", 0, -378, 550, function()
        ns.db.fontFace, ns.db.fontSettings = "standard", ns.Copy(ns.defaults.fontSettings) Changed()
    end)
    Help(page, "Each category has its own size and outline. Font family applies across the styled HUD.", -418)
end
local function Themes(page)
    for i, item in ipairs({{"teal", "Charcoal / teal", {0.35, 0.8, 0.95}}, {"gold", "Black / gold", {0.92, 0.73, 0.32}},
        {"class", "Class accent", {0.55, 0.55, 0.55}}}) do
        local key = item[1]
        local button = Button(page, item[2], (i - 1) * 189, 0, 172, function() ns.ApplyTheme(key) end)
        local swatch = page:CreateTexture(nil, "ARTWORK") swatch:SetSize(172, 40)
        swatch:SetPoint("TOPLEFT", (i - 1) * 189, -38) swatch:SetColorTexture(unpack(item[3]))
        Refresh(page, function()
            ns.ThemeButton(button, ns.db.themePreset == key)
            if key == "class" and ns.db.classAccent then swatch:SetColorTexture(unpack(ns.db.colors.accent)) end
        end)
    end
    Help(page, "Presets update HUD colors. Your frame dimensions and custom positions are kept.", -112)
    Button(page, "Choose any HUD colors", 0, -182, 550, function() ns.OpenAppearance("player") end)
    Button(page, "Health / mana / class colors", 0, -224, 550, function() ns.OpenAppearance("player") end)
    Help(page, "Appearance includes RGB, hex and opacity controls. Health bars can use each unit's class color.", -278)
end
local function Auras(page)
    Toggle(page, "Style buffs / debuffs", 0, function() return ns.db.auras.enabled end, function(v) ns.db.auras.enabled = v end)
    Number(page, "Icon size", -42, function() return ns.db.auras.size end, function(v) ns.db.auras.size = v end, 15, 60, 3)
    Number(page, "Icon spacing", -84, function() return ns.db.auras.spacing end, function(v) ns.db.auras.spacing = v end, 5, 15, 1)
    Number(page, "Icons per line", -126, function() return ns.db.auras.columns end, function(v) ns.db.auras.columns = v end, 2, 16, 1)
    Button(page, "Move buffs", 0, -168, 266, function() Move("buffs") end)
    Button(page, "Move debuffs", 284, -168, 266, function() Move("debuffs") end)
    Label(page, "Tooltips", 0, -217, 16)
    Toggle(page, "Match tooltip theme", -250, function() return ns.db.tooltip.enabled end, function(v) ns.db.tooltip.enabled = v end)
    Choice(page, "Tooltip location", -292, {{"default", "Game default"}, {"cursor", "At cursor"}, {"fixed", "Fixed location"}},
        function() return ns.db.tooltip.anchor end, function(v) ns.db.tooltip.anchor = v end)
    Button(page, "Move fixed tooltip location", 0, -338, 550, function() ns.db.tooltip.anchor = "fixed" Changed() Move("tooltip") end)
    Help(page, "Icon sizes use three-pixel steps, from 15 to 60. Buff clicks, duration displays and tooltip contents stay native. Edit fonts on the Fonts page.", -388)
end
local function Swing(page)
    Toggle(page, "Show themed swing timer", 0, function() return ns.db.swing.enabled end, function(v) ns.db.swing.enabled = v end)
    Number(page, "Width", -42, function() return ns.db.swing.width end, function(v) ns.db.swing.width = v end, 100, 600, 10)
    Number(page, "Height", -84, function() return ns.db.swing.height end, function(v) ns.db.swing.height = v end, 4, 24, 1)
    Choice(page, "Native visibility", -126, {{"combat", "In combat"}, {"always", "Always"}},
        function() return ns.db.swing.visibility end, function(v) ns.db.swing.visibility = v end)
    Toggle(page, "Show native time text", -168, function() return ns.db.swing.time end, function(v) ns.db.swing.time = v end)
    Toggle(page, "Use theme accent", -210, function() return ns.db.swing.useAccent end, function(v) ns.db.swing.useAccent = v end)
    Button(page, "Choose swing color", 0, -252, 550, function() ns.PickColor(ns.db.swing, "color", "useAccent") end)
    Button(page, "Move swing timer", 0, -294, 550, function() Move("swingmain") end)
    Help(page, "Uses the game's swing progress. Main hand, off hand and ranged strips appear when their native timer is active.", -345)
end
local function Fading(page)
    Toggle(page, "Fade idle utility panels", 0, function() return ns.db.fade.enabled end, function(v) ns.db.fade.enabled = v end)
    Number(page, "Idle delay (seconds)", -42, function() return ns.db.fade.delay end, function(v) ns.db.fade.delay = v end, 0, 60, 0.5)
    Number(page, "Idle opacity (0 to 1)", -84, function() return ns.db.fade.alpha end, function(v) ns.db.fade.alpha = v end, 0, 1, 0.05)
    Number(page, "Fade duration (seconds)", -126, function() return ns.db.fade.speed end, function(v) ns.db.fade.speed = v end, 0.05, 3, 0.05)
    for i, key in ipairs({"chat", "bags", "menu"}) do
        local group = key
        Toggle(page, "Fade " .. group, -168 - (i - 1) * 42, function() return ns.db.fade[group] end, function(v) ns.db.fade[group] = v end)
    end
    Help(page, "Hover, typing, combat and editing restore full opacity. Action, unit and cast bars remain visible.", -315)
end
local function Meters(page)
    Toggle(page, "Skin built-in damage meters", 0, function() return ns.db.meters.enabled end,
        function(v) ns.db.meters.enabled = v end)
    Choice(page, "Bar colors", -42, {{"native", "Native / class colors"}, {"accent", "UI accent"}, {"custom", "Custom color"}},
        function() return ns.db.meters.colorMode end, function(v) ns.db.meters.colorMode = v end)
    Button(page, "Choose custom bar color", 0, -84, 550, function() ns.PickColor(ns.db.meters, "color") end)
    Number(page, "Opacity (-1 = HUD)", -126, function() return ns.db.meters.opacity end,
        function(v)
            if ns.db.meters.opacity < 0 and v > -1 then v = 0 end
            ns.db.meters.opacity = v
        end, -1, 1, 0.05)
    Toggle(page, "Thin borders around rows", -168, function() return ns.db.meters.rowBorders end,
        function(v) ns.db.meters.rowBorders = v end)
    Toggle(page, "Accent line under header", -210, function() return ns.db.meters.accentLine end,
        function(v) ns.db.meters.accentLine = v end)
    Number(page, "Text size (0 = automatic)", -252, function() return ns.db.fontSettings.meters.size end,
        function(v) ns.db.fontSettings.meters.size = v end, 0, 32, 1)
    Button(page, "Meter fonts / outline", 0, -294, 266, function()
        ns.OpenCustomize("fonts") ns.customize.fontCategory = "meters" ns.RefreshCustomize()
    end)
    Button(page, "Reset meter skin", 284, -294, 266, function()
        ns.CancelAppearanceColor()
        ns.db.meters = ns.Copy(ns.defaults.meters)
        ns.db.fontSettings.meters = ns.Copy(ns.defaults.fontSettings.meters)
        Changed()
    end)
    Help(page, "Uses the HUD panel, border and text colors. Custom bar color applies when Bar colors is set to Custom color.", -344)
    Help(page, "Enable the meter in WoW's options. Use its settings and Edit Mode for class colors, row height, window size and movement.", -404)
end
local function Trackers(page)
    local status = Label(page, "", 0, 0, 12) status:SetWidth(550)
    Refresh(page, function() status:SetText(ns.TrackerStatus()) end)
    Toggle(page, "Skin Blizzard trackers", -36, function() return ns.db.trackers.enabled end,
        function(v) ns.db.trackers.enabled = v end)
    Button(page, "Enable Blizzard tracking", 0, -78, 266, ns.EnableBlizzardTrackers)
    Button(page, "Choose spells in Blizzard", 284, -78, 266, ns.OpenBlizzardTrackers)
    Toggle(page, "Enable tracking on login", -120, function() return ns.db.trackers.autoEnable end,
        function(v) ns.db.trackers.autoEnable = v end)
    Toggle(page, "Group background", -162, function() return ns.db.trackers.container end,
        function(v) ns.db.trackers.container = v end)
    Number(page, "Timer text size", -204, function() return ns.db.trackers.fontSize end,
        function(v) ns.db.trackers.fontSize = v end, 8, 32, 1)
    for i, group in ipairs(ns.trackerGroups) do
        local key = group.key
        Button(page, group.label .. " skin: toggle", 0, -246 - (i - 1) * 34, 266, function()
            ns.db.trackers.groups[key] = not ns.db.trackers.groups[key] Changed()
        end)
        local move = Button(page, "Move group", 284, -246 - (i - 1) * 34, 266, function()
            if not ns.TrackerMoverVisible("tracker" .. key) then ns.Print("Enable Blizzard tracking and this group's skin first.") return end
            ns.Unlock(true)
        end)
        Refresh(page, function()
            move.label:SetText(group.label .. (ns.db.trackers.groups[key] and " | Move" or " | Native"))
        end)
    end
    Button(page, "Reset group positions", 0, -390, 550, function()
        for _, group in ipairs(ns.trackerGroups) do ns.db.positions["tracker" .. group.key] = nil end
        Changed()
    end)
    Help(page, "Blizzard owns spell selection, visibility, icon size and timers. Skin toggles restore native visuals; they do not stop tracking. Move only outside combat.", -428)
end
local builders = {profiles = Profiles, layout = Alignment, bars = Bars, fonts = Fonts, themes = Themes, auras = Auras,
    swing = Swing, fade = Fading, meters = Meters, trackers = Trackers}
function ns.CreateCustomize()
    if ns.customize then return end
    local window = CreateFrame("Frame", "CleanCenterUICustomize", UIParent)
    ns.customize = window window.window = window
    window.controls, window.refreshers, window.pages, window.tabs = {}, {}, {}, {}
    window:SetSize(780, 620) window:SetPoint("CENTER") window:SetFrameStrata("DIALOG") window:SetFrameLevel(125)
    window:SetClampedToScreen(true) window:EnableMouse(true) window:SetMovable(true) window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving) window:SetScript("OnDragStop", window.StopMovingOrSizing)
    ns.Panel(window, 0.98)
    Label(window, "Customize ZeG UI", 24, -20, 20)
    Label(window, "Profiles, layout and finishing touches", 24, -49, 13)
    Button(window, "Main settings", 602, -18, 120, function() window:Hide() ns.OpenOptions() end)
    Button(window, "X", 736, -18, 26, function() window:Hide() end)
    for i, item in ipairs(pages) do
        local key = item[1]
        window.tabs[key] = Button(window, item[2], 24, -91 - (i - 1) * 42, 136, function() ns.OpenCustomize(key) end)
        local page = CreateFrame("Frame", nil, window) page.window = window
        page:SetPoint("TOPLEFT", 194, -91) page:SetSize(550, 466) page:Hide()
        window.pages[key] = page builders[key](page)
    end
    window.status = Label(window, "", 24, -588, 12)
    window.status:SetWidth(730)
    window:SetScript("OnShow", ns.RefreshCustomize)
    window:SetScript("OnHide", function()
        ns.CancelAppearanceColor() window.profileName:ClearFocus() window.profileText:ClearFocus()
    end)
    window:Hide()
    UISpecialFrames = UISpecialFrames or {} table.insert(UISpecialFrames, "CleanCenterUICustomize")
end
function ns.RefreshCustomize()
    local window = ns.customize
    if not window then return end
    local height = UIParent:GetHeight()
    if ns.Finite(height) then window:SetScale(math.min(1, math.max(0.5, (height - 36) / 620))) end
    ns.Panel(window, 0.98)
    for _, button in ipairs(window.controls) do ns.ThemeButton(button) end
    for key, button in pairs(window.tabs) do
        ns.ThemeButton(button, window.page == key) window.pages[key]:SetShown(window.page == key)
    end
    for _, refresh in ipairs(window.refreshers) do refresh() end
    if InCombatLockdown() and (ns.pending or ns.pendingProfile) then window.status:SetText("Changes saved. They apply after combat.")
    elseif ns.blizzardEditing then window.status:SetText("Changes apply when Blizzard Edit Mode closes.")
    else window.status:SetText(window.message or "v" .. ns.version .. "  |  Changes save automatically.") end
end
function ns.OpenCustomize(page)
    if ns.unsupported then ns.Info() return end
    ns.CreateCustomize()
    if ns.options then ns.options:Hide() end
    if ns.appearance then ns.appearance:Hide() end
    if ns.minimapOptions then ns.minimapOptions:Hide() end
    ns.customize.page = builders[page] and page or ns.customize.page or "profiles"
    ns.customize:Show() ns.RefreshCustomize()
end
