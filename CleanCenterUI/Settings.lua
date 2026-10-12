local _, ns = ...

local function Button(parent, text, width, height, click)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width or 100, height or 30)
    ns.Panel(button, 1)
    button.label = ns.Font(button, 13, "CENTER")
    button.label:SetPoint("CENTER")
    button.label:SetText(text)
    button:SetScript("OnClick", click)
    button:SetScript("OnEnter", function() ns.SetBorderColor(button, unpack(ns.db.colors.accent)) end)
    button:SetScript("OnLeave", function() ns.SetBorderColor(button, unpack(ns.db.colors.border)) end)
    parent.controls[#parent.controls + 1] = button
    return button
end

local function Label(parent, text, x, y, size)
    local label = ns.Font(parent, size or 13)
    label:SetPoint("TOPLEFT", x, y)
    label:SetText(text)
    return label
end

local function RestoreBeforeReload()
    ns.restoring = true
    ns.RestoreSavedChanges()
    ns.restoring = false
    ReloadUI()
end

local function ToggleModule(key)
    if InCombatLockdown() then
        ns.Print("Leave combat before switching HUD sections.")
        return
    end
    ns.db.modules[key] = not ns.db.modules[key]
    RestoreBeforeReload()
end

function ns.ResetLayout()
    ns.db.positions = {}
    ns.db.barSettings = ns.Copy(ns.defaults.barSettings)
    ns.db.rows, ns.db.scale = 2, 1
    ns.db.buttonSize, ns.db.opacity, ns.db.borders = 48, 0.82, true
    ns.db.buttonShape = "square"
    ns.db.stanceShape, ns.db.compactBags, ns.db.menuDock = "square", true, true
    ns.db.minimapSize = ns.defaults.minimapSize
    ns.QueueLayout()
    if InCombatLockdown() then ns.Print("Layout reset saved; it will apply after combat.") end
end

function ns.SetStanceShape(shape)
    if shape == "triangle" then shape = "triangles" end
    if shape == "squares" then shape = "square" end
    if shape ~= "square" and shape ~= "triangles" then
        ns.Print("Use /zeg stance square or /zeg stance triangles.") return
    end
    ns.db.stanceShape = shape
    ns.QueueLayout()
end

function ns.SetUtilityMode(key, value)
    if key ~= "compactBags" and key ~= "menuDock" then return end
    ns.db[key] = value
    if key == "menuDock" then ns.db.positions.menu = nil end
    ns.QueueLayout()
end

function ns.SetButtonShape(shape)
    if shape == "triangle" then shape = "triangles" end
    if shape == "squares" then shape = "square" end
    if shape ~= "square" and shape ~= "triangles" then
        ns.Print("Use /zeg shape square or /zeg shape triangles.")
        return
    end
    ns.db.buttonShape = shape
    ns.QueueLayout()
    if InCombatLockdown() then ns.Print("Button shape saved; it will apply after combat.") end
end

function ns.SetEnabled(enabled)
    if InCombatLockdown() then
        ns.Print("Leave combat before enabling or disabling the preset.")
        return
    end
    ns.db.enabled = enabled
    RestoreBeforeReload()
end

function ns.CreateOptions()
    if ns.options then return end
    local window = CreateFrame("Frame", "CleanCenterUIOptions", UIParent)
    ns.options = window
    window.controls = {}
    window:SetSize(540, 712)
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
    Label(window, "ZeG UI", 24, -20, 20)
    Label(window, "A quiet HUD. Make it yours.", 24, -48)
    local close = Button(window, "X", 26, 26, function() window:Hide() end)
    close:SetPoint("TOPRIGHT", -16, -16)
    Label(window, "Visible action bars", 24, -88, 15)
    window.rowButtons = {}
    for row = 1, 8 do
        local count = row
        local button = Button(window, tostring(row), 50, 32, function() ns.SetRows(count) end)
        button:SetPoint("TOPLEFT", 24 + (row - 1) * 59, -112)
        window.rowButtons[row] = button
    end
    Label(window, "12 spell slots per bar. Your placed spells stay in their slots.", 24, -151, 12)

    local function Stepper(text, key, lo, hi, step, y, percent)
        Label(window, text, 24, y + 2)
        local value = Label(window, "", 324, y + 2)
        value:SetWidth(75)
        value:SetJustifyH("CENTER")
        local function Change(delta)
            ns.db[key] = ns.Clamp(ns.db[key] + delta, lo, hi)
            ns.QueueLayout()
        end
        local minus = Button(window, "-", 34, 27, function() Change(-step) end)
        minus:SetPoint("TOPLEFT", 286, y + 7)
        local plus = Button(window, "+", 34, 27, function() Change(step) end)
        plus:SetPoint("TOPLEFT", 405, y + 7)
        window[key .. "Value"] = { text = value, percent = percent }
    end
    Stepper("HUD size", "scale", 0.65, 1.4, 0.05, -190, true)
    Stepper("Button size", "buttonSize", 28, 64, 2, -225, false)
    Stepper("Panel opacity", "opacity", 0.25, 1, 0.05, -260, true)
    Label(window, "Button shape", 24, -298)
    window.shapeButtons = {}
    for i, item in ipairs({{"square", "Squares"}, {"triangles", "Triangles"}}) do
        local shape = item[1]
        local button = Button(window, item[2], 113, 28, function() ns.SetButtonShape(shape) end)
        button:SetPoint("TOPLEFT", 270 + (i - 1) * 123, -290)
        window.shapeButtons[shape] = button
    end
    Label(window, "Triangles alternate up/down. Click their centers.", 24, -329, 12)
    Label(window, "Stances / utilities", 24, -360, 15)
    window.stanceShape = Button(window, "", 152, 28, function()
        ns.SetStanceShape(ns.db.stanceShape == "square" and "triangles" or "square")
    end)
    window.stanceShape:SetPoint("TOPLEFT", 24, -385)
    window.compactBags = Button(window, "", 152, 28, function() ns.SetUtilityMode("compactBags", not ns.db.compactBags) end)
    window.compactBags:SetPoint("TOPLEFT", 190, -385)
    window.menuDock = Button(window, "", 152, 28, function() ns.SetUtilityMode("menuDock", not ns.db.menuDock) end)
    window.menuDock:SetPoint("TOPLEFT", 356, -385)
    Label(window, "Hover bags expand. Center menus sit above EXP.", 24, -422, 12)
    window.cooldownNumbers = Button(window, "", 208, 28, function()
        ns.db.cooldownNumbers = not ns.db.cooldownNumbers
        ns.QueueLayout()
    end)
    window.cooldownNumbers:SetPoint("TOPLEFT", 24, -435)
    window.customize = Button(window, "Customize", 104, 28, function() ns.OpenCustomize() end)
    window.customize:SetPoint("TOPLEFT", 242, -435)
    window.minimapSettings = Button(window, "Minimap settings", 152, 28, ns.OpenMinimapOptions)
    window.minimapSettings:SetPoint("TOPLEFT", 356, -435)
    Label(window, "HUD sections", 24, -467, 15)
    window.moduleButtons = {}
    local sections = { { "bars", "Action bars" }, { "units", "Unit frames" },
        { "party", "Party frames" }, { "cast", "Cast bars" }, { "chat", "Chat" },
        { "minimap", "Minimap" }, { "quests", "Quest tracker" },
        { "xp", "EXP bar" }, { "bags", "Bag bar" }, { "menu", "Micro menu" } }
    for i, section in ipairs(sections) do
        local key, name = section[1], section[2]
        local button = Button(window, name, 113, 28, function() ToggleModule(key) end)
        button:SetPoint("TOPLEFT", 24 + ((i - 1) % 4) * 123, -493 - math.floor((i - 1) / 4) * 36)
        window.moduleButtons[key] = button
    end
    window.borders = Button(window, "Bar borders", 113, 28, function()
        ns.db.borders = not ns.db.borders
        ns.QueueLayout()
    end)
    window.borders:SetPoint("TOPLEFT", 270, -565)
    local appearance = Button(window, "Appearance", 113, 28, function() ns.OpenAppearance("player") end)
    appearance:SetPoint("TOPLEFT", 393, -565)
    Label(window, "Bar count and section changes reload the interface.", 24, -603, 12)
    window.unlock = Button(window, "Unlock panels", 145, 32, function() ns.Unlock(not ns.unlocked) end)
    window.unlock:SetPoint("BOTTOMLEFT", 24, 49)
    local reset = Button(window, "Reset layout", 135, 32, ns.ResetLayout)
    reset:SetPoint("LEFT", window.unlock, "RIGHT", 12, 0)
    window.enabled = Button(window, "", 135, 32, function() ns.SetEnabled(not ns.db.enabled) end)
    window.enabled:SetPoint("LEFT", reset, "RIGHT", 12, 0)
    window.status = Label(window, "", 24, -678, 12)
    window:SetScript("OnShow", function() ns.RefreshOptions() end)
    window:Hide()
    UISpecialFrames = UISpecialFrames or {}
    table.insert(UISpecialFrames, "CleanCenterUIOptions")
end

function ns.RefreshOptions()
    local window = ns.options
    if not window then return end
    ns.Panel(window, 0.98)
    for _, button in ipairs(window.controls) do ns.ThemeButton(button) end
    for row, button in ipairs(window.rowButtons) do
        ns.ThemeButton(button, row == ns.db.rows)
    end
    for shape, button in pairs(window.shapeButtons) do ns.ThemeButton(button, ns.db.buttonShape == shape) end
    window.stanceShape.label:SetText(ns.db.stanceShape == "triangles" and "Stances: triangles" or "Stances: squares")
    window.compactBags.label:SetText(ns.db.compactBags and "Bags: hover" or "Bags: full")
    window.menuDock.label:SetText(ns.db.menuDock and "Menu: center" or "Menu: corner")
    ns.ThemeButton(window.stanceShape, ns.db.stanceShape == "triangles")
    ns.ThemeButton(window.compactBags, ns.db.compactBags)
    ns.ThemeButton(window.menuDock, ns.db.menuDock)
    window.cooldownNumbers.label:SetText(ns.db.cooldownNumbers and "Cooldown numbers: on" or "Cooldown numbers: off")
    ns.ThemeButton(window.cooldownNumbers, ns.db.cooldownNumbers)
    for _, key in ipairs({ "scale", "buttonSize", "opacity" }) do
        local item = window[key .. "Value"]
        if item.percent then item.text:SetFormattedText("%d%%", math.floor(ns.db[key] * 100 + 0.5))
        else item.text:SetFormattedText("%d", ns.db[key]) end
    end
    for key, button in pairs(window.moduleButtons) do
        ns.ThemeButton(button, ns.db.modules[key])
    end
    ns.ThemeButton(window.borders, ns.db.borders)
    window.unlock.label:SetText(ns.unlocked and "Lock panels" or "Unlock panels")
    window.enabled.label:SetText(ns.db.enabled and "Turn preset off" or "Turn preset on")
    if InCombatLockdown() and ns.pending then window.status:SetText("Changes saved. They will apply after combat.")
    elseif ns.blizzardEditing then window.status:SetText("Changes apply after closing Blizzard Edit Mode.")
    elseif ns.nativeReloadScheduled then window.status:SetText("Saving bar count. The interface will reload.")
    elseif ns.nativeBarWarning then window.status:SetText(ns.nativeBarWarning)
    elseif ns.lastError then window.status:SetText("Setup needs attention. Use /zeg info.")
    else window.status:SetText("v" .. ns.version .. "  |  " .. ns.db.rows .. " bars  |  /zeg") end
end

function ns.OpenOptions()
    if ns.unsupported then ns.Info() return end
    if not ns.options then ns.CreateOptions() end
    if ns.appearance then ns.appearance:Hide() end
    if ns.minimapOptions then ns.minimapOptions:Hide() end
    if ns.customize then ns.customize:Hide() end
    ns.options:SetShown(not ns.options:IsShown())
end

SLASH_CLEANCENTERUI1 = "/zeg"
SLASH_CLEANCENTERUI2 = "/ccui"
SLASH_CLEANCENTERUI3 = "/cleancenter"
SlashCmdList.CLEANCENTERUI = function(message)
    local command, args = (message or ""):lower():match("^%s*(%S+)%s*(.-)%s*$")
    if command == "info" then ns.Info() return end
    if command == "taint" then ns.TaintInfo() return end
    if ns.unsupported then ns.Info() return end
    if not command then ns.OpenOptions()
    elseif command == "customize" then ns.OpenCustomize(args)
    elseif command == "profiles" or command == "fonts" or command == "themes" or command == "swing"
        or command == "layout" or command == "auras" or command == "fade" or command == "meters" or command == "trackers" then ns.OpenCustomize(command)
    elseif command == "tooltips" then ns.OpenCustomize("auras")
    elseif command == "theme" then ns.ApplyTheme(args)
    elseif command == "bars" then ns.SetRows(args)
    elseif command == "shape" then ns.SetButtonShape(args)
    elseif command == "stance" then ns.SetStanceShape(args)
    elseif command == "bags" then
        if args ~= "hover" and args ~= "full" then ns.Print("Use /zeg bags hover or /zeg bags full.") return end
        ns.SetUtilityMode("compactBags", args == "hover")
    elseif command == "menu" then
        if args ~= "center" and args ~= "corner" then ns.Print("Use /zeg menu center or /zeg menu corner.") return end
        ns.SetUtilityMode("menuDock", args == "center")
    elseif command == "minimap" then
        if args == "reset" then ns.ResetMinimap()
        elseif args ~= "" then ns.SetMinimapSize(args)
        else ns.OpenMinimapOptions() end
    elseif command == "cooldowns" then
        if args ~= "on" and args ~= "off" then ns.Print("Use /zeg cooldowns on or /zeg cooldowns off.") return end
        ns.db.cooldownNumbers = args == "on"
        ns.QueueLayout()
    elseif command == "appearance" or command == "colors" then ns.OpenAppearance(args)
    elseif command == "unlock" then ns.Unlock(true)
    elseif command == "lock" then ns.Unlock(false)
    elseif command == "reset" then ns.ResetLayout()
    elseif command == "off" then ns.SetEnabled(false)
    elseif command == "on" then ns.SetEnabled(true)
    elseif command == "borders" then
        if args ~= "on" and args ~= "off" then
            ns.Print("Use /zeg borders on or /zeg borders off.")
            return
        end
        ns.db.borders = args == "on"
        ns.QueueLayout()
    elseif command == "scale" or command == "opacity" then
        local value = tonumber(args)
        if not value then ns.Print("Use /zeg " .. command .. " with a number, such as 1 or 0.8.") return end
        local lo, hi = command == "scale" and 0.65 or 0.25, command == "scale" and 1.4 or 1
        ns.db[command] = ns.Clamp(value, lo, hi)
        ns.QueueLayout()
    else
        ns.Print("/zeg | customize | trackers | meters | minimap [120-360/reset] | cooldowns on/off | shape square/triangles | stance square/triangles | bags hover/full | menu center/corner | appearance | bars 1-8 | borders on/off | unlock | lock | reset | scale 0.65-1.4 | opacity 0.25-1 | off | on | info")
    end
end
