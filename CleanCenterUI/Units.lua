local _, ns = ...
ns.unitFrames = {}

local function Bar(parent, height)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetHeight(height)
    bar:SetStatusBarTexture(ns.WHITE)
    local background = bar:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    bar.background = background
    background:SetColorTexture(unpack(ns.db.colors.barBackground))
    return bar
end

local function Update(frame)
    local unit = frame.unit
    -- Native widgets accept secret values. Never compare, divide, format in Lua,
    -- or branch on health/power; Forever restricts these values during combat.
    local health = UnitHealth(unit)
    frame.health:SetMinMaxValues(0, UnitHealthMax(unit))
    frame.health:SetValue(health)
    frame.value:SetFormattedText("%s", health)
    if UnitHealthPercent and CurveConstants and CurveConstants.ScaleTo100 then
        frame.percent:SetFormattedText("%.0f%%", UnitHealthPercent(unit, true, CurveConstants.ScaleTo100))
    else
        frame.percent:SetText("")
    end
    frame.power:SetMinMaxValues(0, UnitPowerMax(unit))
    frame.power:SetValue(UnitPower(unit))
    local name = UnitName(unit)
    frame.name:SetText(name)
    if frame.portrait then SetPortraitTexture(frame.portrait, unit) end
    local style = ns.db.unitStyles[frame.styleKey]
    local _, class = UnitClass(unit)
    local color = style.classColor and ns.Readable(class) and class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if color then
        frame.health:SetStatusBarColor(color.r, color.g, color.b, style.healthColor[4])
    elseif not style.classColor then
        frame.health:SetStatusBarColor(unpack(style.healthColor))
    else
        local reaction = UnitReaction(unit, "player")
        if ns.Readable(reaction) and reaction then
            if reaction <= 3 then frame.health:SetStatusBarColor(0.66, 0.24, 0.24, style.healthColor[4])
            elseif reaction == 4 then frame.health:SetStatusBarColor(0.7, 0.58, 0.25, style.healthColor[4])
            else frame.health:SetStatusBarColor(0.28, 0.57, 0.33, style.healthColor[4]) end
        else
            frame.health:SetStatusBarColor(unpack(style.healthColor))
        end
    end
    local _, token = UnitPowerType(unit)
    local powerColor = style.powerTypeColor and ns.Readable(token) and token and PowerBarColor and PowerBarColor[token]
    if powerColor then
        frame.power:SetStatusBarColor(powerColor.r, powerColor.g, powerColor.b, style.powerColor[4])
    else
        frame.power:SetStatusBarColor(unpack(style.powerColor))
    end
    if frame.offlineText then
        -- Connection/roster state is public; do not infer it from restricted
        -- health, power or range values. Guard optional/restricted API results.
        local exists = UnitExists and UnitExists(unit)
        local connected = UnitIsConnected and UnitIsConnected(unit)
        local offline = ns.Readable(exists) and exists and ns.Readable(connected) and connected == false
        frame.offlineText:SetShown(offline and style.healthHeight >= 10 or false)
        frame.value:SetShown(not offline and style.healthHeight >= 10)
        if offline then
            frame.health:SetStatusBarColor(unpack(ns.db.colors.barBackground))
            frame.power:SetStatusBarColor(unpack(ns.db.colors.barBackground))
            if style.healthHeight < 10 then
                frame.name:SetFormattedText("%s (%s)", name, PLAYER_OFFLINE or "Offline")
            end
        end
    end
end

local function Style(frame)
    local style = ns.db.unitStyles[frame.styleKey]
    frame:SetSize(style.width, style.height)
    local inset = style.portrait and 48 or 6
    frame.portrait:SetSize(math.min(36, style.height - 12), math.min(36, style.height - 12))
    frame.portrait:SetShown(style.portrait)
    frame.name:ClearAllPoints()
    frame.name:SetPoint("TOPLEFT", inset, -5)
    frame.name:SetPoint("TOPRIGHT", -6, -5)
    frame.health:ClearAllPoints()
    frame.health:SetHeight(style.healthHeight)
    frame.health:SetPoint("TOPLEFT", inset, frame.compact and -21 or -25)
    frame.health:SetPoint("TOPRIGHT", -6, frame.compact and -21 or -25)
    frame.power:SetHeight(style.powerHeight)
    frame.health.background:SetColorTexture(unpack(ns.db.colors.barBackground))
    frame.power.background:SetColorTexture(unpack(ns.db.colors.barBackground))
    frame.value:SetShown(style.healthHeight >= 10)
    frame.percent:SetShown(not frame.compact and style.healthHeight >= 10)
    ns.Panel(frame)
end

local function CreateUnit(unit, key, compact, visibility)
    local frame = CreateFrame("Button", "CleanCenterUI_" .. key, ns.root,
        "SecureUnitButtonTemplate")
    frame.unit, frame.key, frame.compact = unit, key, compact
    frame.styleKey = key:match("^party") and "party" or key
    frame:SetSize(compact and 158 or 286, compact and 40 or 66)
    frame:SetAttribute("unit", unit)
    frame:SetAttribute("*type1", "target")
    frame:SetAttribute("*type2", "togglemenu")
    frame:RegisterForClicks("AnyUp")
    ns.Panel(frame)
    frame.portrait = frame:CreateTexture(nil, "ARTWORK")
    frame.portrait:SetSize(36, 36)
    frame.portrait:SetPoint("LEFT", 6, -5)
    frame.portrait:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    local inset = compact and 6 or 48
    frame.name = ns.Font(frame, compact and 12 or 14, nil, "names")
    frame.name:SetPoint("TOPLEFT", inset, -5)
    frame.name:SetPoint("TOPRIGHT", -6, -5)
    frame.health = Bar(frame, compact and 12 or 21)
    frame.health:SetPoint("TOPLEFT", inset, compact and -21 or -25)
    frame.health:SetPoint("TOPRIGHT", -6, compact and -21 or -25)
    frame.power = Bar(frame, compact and 3 or 8)
    frame.power:SetPoint("TOPLEFT", frame.health, "BOTTOMLEFT", 0, -2)
    frame.power:SetPoint("TOPRIGHT", frame.health, "BOTTOMRIGHT", 0, -2)
    frame.value = ns.Font(frame.health, compact and 10 or 12, "RIGHT", "health")
    frame.value:SetPoint("RIGHT", -3, 0)
    frame.percent = ns.Font(frame.health, compact and 10 or 12, nil, "health")
    frame.percent:SetPoint("LEFT", 3, 0)
    if compact then frame.percent:Hide() end
    if frame.styleKey == "party" then
        frame.offlineText = ns.Font(frame.health, 10, "CENTER", "health")
        frame.offlineText:SetPoint("CENTER")
        frame.offlineText:SetText(PLAYER_OFFLINE or "Offline")
        frame.offlineText:Hide()
    end
    frame:SetScript("OnEvent", function() Update(frame) end)
    frame:HookScript("OnShow", function()
        Update(frame)
        if ns.RefreshBarEditors then ns.RefreshBarEditors() end
    end)
    frame:HookScript("OnHide", function()
        if ns.RefreshBarEditors then ns.RefreshBarEditors() end
    end)
    frame:SetScript("OnEnter", function()
        ns.SetBorderColor(frame, unpack(ns.db.colors.accent))
        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
        GameTooltip:SetUnit(unit)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        ns.SetBorderColor(frame, unpack(ns.db.colors.border))
        GameTooltip:Hide()
    end)
    for _, event in ipairs({ "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_POWER_UPDATE",
        "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER", "UNIT_NAME_UPDATE", "UNIT_LEVEL",
        "UNIT_PORTRAIT_UPDATE", "UNIT_FACTION", "UNIT_FLAGS", "UNIT_CONNECTION" }) do
        frame:RegisterUnitEvent(event, unit)
    end
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    if visibility then RegisterStateDriver(frame, "visibility", visibility)
    else RegisterUnitWatch(frame) end
    if ClickCastFrames then ClickCastFrames[frame] = true end
    ns.unitFrames[key] = frame
    ns.AddMover(frame, key, key:gsub("^%l", string.upper))
    if ns.AddBarEditors then ns.AddBarEditors(frame) end
    Style(frame)
    Update(frame)
    return frame
end

local function ClassResource()
    local resource = PlayerFrame and PlayerFrame.classPowerBar
    if resource and ns.db.modules.units then
        ns.Reparent(resource, ns.root)
        ns.SetScale(resource, 1)
        ns.Position(resource, "resource", "BOTTOM", 0, ns.UnitBottom() + 12)
        ns.Hook(resource, "SetPoint", ns.QueueLayout)
    end
    local alternate = PlayerFrameAlternatePowerBarArea
    if alternate and ns.db.modules.units then
        ns.Reparent(alternate, ns.root)
        ns.SetScale(alternate, 0.9)
        ns.Position(alternate, "alternatepower", "BOTTOM", 0, ns.UnitBottom() + 64)
    end
end

function ns.BarHeight()
    local rows = ns.db.modules.bars and ns.db.rows or 1
    return ns.TotalBarHeight()
end

function ns.UnitBottom()
    return ns.ActionBottom() + ns.BarHeight() + 54
end

function ns.UnitX()
    return math.max(257, math.max(ns.db.unitStyles.player.width, ns.db.unitStyles.target.width) / 2 + 114)
end

function ns.ApplyUnits()
    if ns.db.modules.units then
        for _, entry in ipairs({ { "player", false }, { "target", false }, { "pet", true }, { "focus", true } }) do
            if not ns.unitFrames[entry[1]] then CreateUnit(entry[1], entry[1], entry[2]) end
            Style(ns.unitFrames[entry[1]])
        end
        ns.Position(ns.unitFrames.player, "player", "BOTTOM", -ns.UnitX(), ns.UnitBottom())
        ns.Position(ns.unitFrames.target, "target", "BOTTOM", ns.UnitX(), ns.UnitBottom())
        ns.Position(ns.unitFrames.pet, "pet", "BOTTOM", -ns.UnitX() - 63, ns.UnitBottom() + ns.db.unitStyles.player.height + 12)
        ns.Position(ns.unitFrames.focus, "focus", "BOTTOM", ns.UnitX() + 63, ns.UnitBottom() + ns.db.unitStyles.target.height + 12)
        ClassResource()
        ns.HideStock(PlayerFrame)
        ns.MaskStockUnit(TargetFrame)
        ns.HideStock(PetFrame)
        ns.MaskStockUnit(FocusFrame)
        if not ns.db.modules.cast then
            -- A disabled styling module still leaves the game's casts visible
            -- next to our unit frames, using Blizzard's unmodified artwork.
            local bar = PlayerCastingBarFrame or CastingBarFrame
            if bar then
                ns.Position(bar, "cast", "BOTTOM", 0,
                    ns.UnitBottom() + math.max(ns.db.unitStyles.player.height, ns.db.unitStyles.target.height) + 22)
            end
        end
    end
    if ns.db.modules.party then
        for i = 1, 5 do
            local key = "party" .. i
            local unit = i == 1 and "player" or "party" .. (i - 1)
            if not ns.unitFrames[key] then
                local condition = "[group:party,@" .. unit .. ",exists] show; hide"
                CreateUnit(unit, key, true, condition)
            end
            Style(ns.unitFrames[key])
            ns.Position(ns.unitFrames[key], key, "LEFT", 20, 70 - (i - 1) * (ns.db.unitStyles.party.height + 6))
        end
        ns.HideStock(PartyFrame)
        -- Raid frames remain Blizzard's; this first build replaces the five-person party only.
    end
    for _, frame in pairs(ns.unitFrames) do
        Style(frame)
        Update(frame)
        if ClickCastFrames then ClickCastFrames[frame] = true end
    end
end
