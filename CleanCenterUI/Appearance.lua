local _, ns = ...
local order = {"player", "target", "pet", "focus", "party"}
local names = {player = "Player", target = "Target", pet = "Pet", focus = "Focus", party = "Party"}
local dimensions = {width = {100, 600}, healthHeight = {6, 200}, powerHeight = {2, 50}}

function ns.StyleKey(key)
    if type(key) ~= "string" then return "player" end
    if key:match("^party%d*$") then return "party" end
    return names[key] and key or "player"
end

local function Overhead(key)
    -- Header, a two-pixel gap, and bottom padding. The bars always fit inside
    -- the frame; changing total height resizes health, retaining power height.
    return (key == "player" or key == "target") and 37 or 25
end

local function NormalizeColor(color, fallback)
    if type(color) ~= "table" then color = ns.Copy(fallback) end
    for i = 1, 4 do color[i] = ns.Clamp(tonumber(color[i]) or fallback[i], 0, 1) end
    return color
end

function ns.NormalizeAppearance()
    for key, color in pairs(ns.defaults.colors) do
        ns.db.colors[key] = NormalizeColor(ns.db.colors[key], color)
    end
    for _, key in ipairs(order) do
        local style, default = ns.db.unitStyles[key], ns.defaults.unitStyles[key]
        for field, range in pairs(dimensions) do
            style[field] = ns.Clamp(math.floor(tonumber(style[field]) or default[field]), range[1], range[2])
        end
        style.height = Overhead(key) + style.healthHeight + style.powerHeight
        style.portrait = style.portrait == true
        style.classColor = style.classColor == true
        style.powerTypeColor = style.powerTypeColor == true
        style.healthColor = NormalizeColor(style.healthColor, default.healthColor)
        style.powerColor = NormalizeColor(style.powerColor, default.powerColor)
    end
end

function ns.SetUnitDimension(key, field, value)
    key, value = ns.StyleKey(key), tonumber(value)
    if not value or value ~= value then return end
    local style = ns.db.unitStyles[key]
    if field == "height" then
        style.healthHeight = ns.Clamp(math.floor(value) - Overhead(key) - style.powerHeight, 6, 200)
    elseif dimensions[field] then
        local range = dimensions[field]
        style[field] = ns.Clamp(math.floor(value), range[1], range[2])
    else return end
    style.height = Overhead(key) + style.healthHeight + style.powerHeight
    ns.QueueLayout()
end

-- The native picker includes RGB/hex entry and an alpha slider. No palette
-- presets restrict the user's color choice. Preview is reversible on Cancel.
function ns.PickColor(container, field, automaticField)
    ns.CancelAppearanceColor()
    if not ColorPickerFrame and C_AddOns and C_AddOns.LoadAddOn and not InCombatLockdown() then
        C_AddOns.LoadAddOn("Blizzard_ColorPickerFrame")
    end
    local picker = ColorPickerFrame
    if not picker or not picker.SetupColorPickerAndShow then
        ns.Print("The game's color picker is unavailable. Try again outside combat.")
        return
    end
    local old, oldAutomatic = ns.Copy(container[field]), automaticField and container[automaticField]
    local palette = container == ns.db.colors
    local oldPreset, oldClassAccent = ns.db.themePreset, ns.db.classAccent
    local session, initializing = {}, true
    ns.colorSession = session
    local function Changed()
        if initializing then return end
        local r, g, b = picker:GetColorRGB()
        container[field] = {r, g, b, picker:GetColorAlpha()}
        if automaticField then container[automaticField] = false end
        if palette then
            ns.db.themePreset = "custom"
            if field == "accent" then ns.db.classAccent = false end
        end
        ns.QueueLayout()
    end
    picker:SetupColorPickerAndShow({r = old[1], g = old[2], b = old[3], opacity = old[4],
        hasOpacity = true, swatchFunc = Changed, opacityFunc = Changed, extraInfo = session,
        cancelFunc = function()
            container[field] = ns.Copy(old)
            if automaticField then container[automaticField] = oldAutomatic end
            if palette then ns.db.themePreset, ns.db.classAccent = oldPreset, oldClassAccent end
            ns.QueueLayout()
        end})
    initializing = false
end

function ns.CancelAppearanceColor()
    local picker, session = ColorPickerFrame, ns.colorSession
    if picker and session and picker:IsShown() and picker:GetExtraInfo() == session then
        picker:OnCancel()
    end
    ns.colorSession = nil
end

function ns.ThemeButton(button, selected)
    ns.Panel(button, 1)
    if selected then
        local p, a = ns.db.colors.panel, ns.db.colors.accent
        ns.SetPanelColor(button, p[1] * 0.7 + a[1] * 0.3, p[2] * 0.7 + a[2] * 0.3,
            p[3] * 0.7 + a[3] * 0.3, p[4])
    end
end

local function Label(parent, text, x, y, size)
    local label = ns.Font(parent, size or 13)
    label:SetPoint("TOPLEFT", x, y)
    label:SetText(text)
    return label
end

local function Button(parent, text, width, click)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, 28)
    ns.Panel(button, 1)
    button.label = ns.Font(button, 12, "CENTER")
    button.label:SetPoint("CENTER")
    button.label:SetText(text)
    button:SetScript("OnClick", click)
    button:SetScript("OnEnter", function() ns.SetBorderColor(button, unpack(ns.db.colors.accent)) end)
    button:SetScript("OnLeave", function() ns.SetBorderColor(button, unpack(ns.db.colors.border)) end)
    parent.controls[#parent.controls + 1] = button
    return button
end

local function ColorButton(parent, text, width, getter, click)
    local button = Button(parent, text, width, click)
    button.label:ClearAllPoints()
    button.label:SetPoint("LEFT", 32, 0)
    button.swatch = button:CreateTexture(nil, "ARTWORK")
    button.swatch:SetSize(18, 18)
    button.swatch:SetPoint("LEFT", 7, 0)
    button.colorGetter = getter
    return button
end

function ns.CreateAppearance()
    if ns.appearance then return end
    local window = CreateFrame("Frame", "CleanCenterUIAppearance", UIParent)
    ns.appearance = window
    window.key, window.controls, window.dimensions, window.tabs = "player", {}, {}, {}
    window:SetSize(620, 630)
    window:SetScale(math.min(1, (UIParent:GetHeight() - 40) / 630))
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetFrameLevel(120)
    window:SetClampedToScreen(true)
    window:EnableMouse(true)
    window:SetMovable(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    ns.Panel(window, 0.98)
    Label(window, "Frame appearance", 24, -20, 20)
    Label(window, "Sizes and colors are saved for this character.", 24, -49, 12)
    local close = Button(window, "X", 26, function() window:Hide() end)
    close:SetPoint("TOPRIGHT", -16, -16)
    for i, key in ipairs(order) do
        local chosen = key
        local button = Button(window, names[key], 104, function() ns.OpenAppearance(chosen) end)
        button:SetPoint("TOPLEFT", 24 + (i - 1) * 112, -80)
        window.tabs[key] = button
    end
    window.heading = Label(window, "", 24, -126, 15)
    local function Dimension(text, field, step, x, y)
        Label(window, text, x, y, 12)
        local function Change(delta)
            ns.SetUnitDimension(window.key, field, ns.db.unitStyles[window.key][field] + delta)
        end
        local minus = Button(window, "-", 26, function() Change(-step) end)
        minus:SetPoint("TOPLEFT", x + 142, y + 5)
        local entry = CreateFrame("EditBox", nil, window)
        entry:SetSize(58, 28)
        entry:SetPoint("TOPLEFT", x + 173, y + 5)
        entry:SetFont(ns.FONT, 13, "OUTLINE")
        entry:SetTextColor(unpack(ns.db.colors.text))
        entry:SetJustifyH("CENTER")
        entry:SetAutoFocus(false)
        entry:SetNumeric(true)
        entry:SetMaxLetters(4)
        entry:SetTextInsets(3, 3, 0, 0)
        ns.Panel(entry, 1)
        local function Commit()
            ns.SetUnitDimension(window.key, field, entry:GetText())
            entry:ClearFocus()
            ns.RefreshAppearance()
        end
        entry:SetScript("OnEnterPressed", Commit)
        entry:SetScript("OnEditFocusLost", function()
            ns.SetUnitDimension(window.key, field, entry:GetText())
            ns.RefreshAppearance()
        end)
        entry:SetScript("OnEscapePressed", function()
            -- Reset the draft first so focus loss cannot commit an escaped edit.
            entry:SetText(tostring(ns.db.unitStyles[window.key][field]))
            entry:ClearFocus()
            ns.RefreshAppearance()
        end)
        local plus = Button(window, "+", 26, function() Change(step) end)
        plus:SetPoint("TOPLEFT", x + 236, y + 5)
        window.dimensions[field] = entry
    end
    Dimension("Frame width", "width", 4, 24, -165)
    Dimension("Frame height", "height", 2, 24, -207)
    Dimension("Health height", "healthHeight", 1, 324, -165)
    Dimension("Mana / power height", "powerHeight", 1, 324, -207)
    local function Toggle(field)
        ns.CancelAppearanceColor()
        local style = ns.db.unitStyles[window.key]
        style[field] = not style[field]
        ns.QueueLayout()
    end
    window.class = Button(window, "", 272, function() Toggle("classColor") end)
    window.class:SetPoint("TOPLEFT", 24, -249)
    window.powerType = Button(window, "", 272, function() Toggle("powerTypeColor") end)
    window.powerType:SetPoint("TOPLEFT", 324, -249)
    window.healthColor = ColorButton(window, "Custom health color", 272,
        function() return ns.db.unitStyles[window.key].healthColor end,
        function() ns.PickColor(ns.db.unitStyles[window.key], "healthColor", "classColor") end)
    window.healthColor:SetPoint("TOPLEFT", 24, -287)
    window.powerColor = ColorButton(window, "Custom mana / power color", 272,
        function() return ns.db.unitStyles[window.key].powerColor end,
        function() ns.PickColor(ns.db.unitStyles[window.key], "powerColor", "powerTypeColor") end)
    window.powerColor:SetPoint("TOPLEFT", 324, -287)
    window.portrait = Button(window, "", 272, function() Toggle("portrait") end)
    window.portrait:SetPoint("TOPLEFT", 24, -327)
    local reset = Button(window, "Reset this frame", 272, function()
        ns.CancelAppearanceColor()
        ns.db.unitStyles[window.key] = ns.Copy(ns.defaults.unitStyles[window.key])
        ns.QueueLayout()
    end)
    reset:SetPoint("TOPLEFT", 324, -327)
    Label(window, "HUD color scheme", 24, -378, 15)
    local palette = {{"panel", "Panel background"}, {"border", "Borders"}, {"text", "Text"},
        {"accent", "Highlights"}, {"barBackground", "Empty bars"}, {"experience", "EXP"}, {"rested", "Rested EXP"}}
    for i, item in ipairs(palette) do
        local field = item[1]
        local button = ColorButton(window, item[2], 182,
            function() return ns.db.colors[field] end,
            function() ns.PickColor(ns.db.colors, field) end)
        button:SetPoint("TOPLEFT", 24 + ((i - 1) % 3) * 194, -410 - math.floor((i - 1) / 3) * 36)
    end
    local paletteReset = Button(window, "Reset HUD colors", 182, function()
        ns.CancelAppearanceColor()
        ns.db.colors = ns.Copy(ns.defaults.colors)
        ns.db.themePreset, ns.db.classAccent = "teal", false
        ns.QueueLayout()
    end)
    paletteReset:SetPoint("TOPLEFT", 218, -482)
    Label(window, "Frame height resizes health; bar heights resize the frame to fit.", 24, -533, 12)
    Label(window, "Unlock panels, then click a bar to edit it. Drag the name area to move.", 24, -553, 12)
    window.status = Label(window, "", 24, -594, 12)
    window:SetScript("OnShow", ns.RefreshAppearance)
    window:SetScript("OnHide", ns.CancelAppearanceColor)
    window:Hide()
    table.insert(UISpecialFrames, "CleanCenterUIAppearance")
end

function ns.RefreshAppearance()
    local window = ns.appearance
    if not window or not window:IsShown() then return end
    ns.Panel(window, 0.98)
    local style = ns.db.unitStyles[window.key]
    window.heading:SetText(names[window.key] .. (window.key == "party" and " frames (all five)" or " frame"))
    for _, button in ipairs(window.controls) do
        ns.ThemeButton(button)
        if button.colorGetter then button.swatch:SetColorTexture(unpack(button.colorGetter())) end
    end
    for key, button in pairs(window.tabs) do ns.ThemeButton(button, key == window.key) end
    for field, entry in pairs(window.dimensions) do
        if not entry:HasFocus() then entry:SetText(tostring(style[field])) end
        ns.Panel(entry, 1)
        entry:SetTextColor(unpack(ns.db.colors.text))
    end
    window.class.label:SetText("Class-colored health: " .. (style.classColor and "On" or "Off"))
    window.powerType.label:SetText("Power type colors: " .. (style.powerTypeColor and "On" or "Off"))
    window.portrait.label:SetText("Portrait / player icon: " .. (style.portrait and "Shown" or "Hidden"))
    ns.ThemeButton(window.class, style.classColor)
    ns.ThemeButton(window.powerType, style.powerTypeColor)
    ns.ThemeButton(window.portrait, style.portrait)
    local border = ns.db.colors.border
    ns.SetBorderColor(window.healthColor, unpack(window.section == "health" and ns.db.colors.accent or border))
    ns.SetBorderColor(window.powerColor, unpack(window.section == "power" and ns.db.colors.accent or border))
    if InCombatLockdown() and ns.pending then window.status:SetText("Saved. Changes apply after combat.")
    elseif ns.blizzardEditing then window.status:SetText("Changes apply after closing Blizzard Edit Mode.")
    else window.status:SetText("Color picker: RGB / hex + transparency. Cancel restores the previous color.") end
end

function ns.OpenAppearance(key, section)
    if ns.unsupported or not ns.db then return end
    ns.CancelAppearanceColor()
    if not ns.appearance then ns.CreateAppearance() end
    -- Commit or discard focused input before changing its owning frame.
    for _, entry in pairs(ns.appearance.dimensions) do entry:ClearFocus() end
    ns.appearance.key, ns.appearance.section = ns.StyleKey(key), section
    if ns.options then ns.options:Hide() end
    if ns.customize then ns.customize:Hide() end
    ns.appearance:Show()
    ns.RefreshAppearance()
end

-- These are independent, non-secure edit overlays. The secure unit button's
-- targeting, context menu, and click-casting attributes remain intact.
function ns.AddBarEditors(frame)
    frame.editors = {}
    for _, section in ipairs({"health", "power"}) do
        local chosen = section
        local editor = CreateFrame("Button", nil, UIParent)
        editor:SetAllPoints(frame[section])
        editor:SetFrameStrata("DIALOG")
        editor:SetFrameLevel(80)
        editor:EnableMouse(true)
        editor:RegisterForClicks("LeftButtonUp")
        ns.Panel(editor, 0.12)
        ns.SetBorderColor(editor, unpack(ns.db.colors.accent))
        editor:SetScript("OnClick", function()
            if ns.unlocked and not InCombatLockdown() then ns.OpenAppearance(frame.styleKey, chosen) end
        end)
        editor:Hide()
        frame.editors[section] = editor
    end
end

function ns.RefreshBarEditors()
    for _, frame in pairs(ns.unitFrames) do
        for _, editor in pairs(frame.editors or {}) do
            editor:SetScale(ns.root:GetScale())
            editor:SetShown(ns.unlocked and ns.db.enabled and not ns.blizzardEditing
                and not InCombatLockdown() and frame:IsShown() or false)
            ns.Panel(editor, 0.12)
            ns.SetBorderColor(editor, unpack(ns.db.colors.accent))
        end
    end
end
