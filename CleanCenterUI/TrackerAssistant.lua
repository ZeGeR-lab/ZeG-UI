local _, ns = ...
local descriptions = {
    essential = "A visible icon row for important abilities. Choose your offensive or defensive spells in Blizzard's editor.",
    utility = "A second icon row for utility or defensive abilities. Blizzard decides which spells are available.",
    buffs = "Buff icons for supported effects. Configure active-only visibility in Blizzard's settings when offered.",
    bars = "Timer bars for supported buffs. Blizzard owns their durations, ordering and visibility.",
}
local function Label(parent, text, x, y, width, size)
    local label = ns.Font(parent, size or 13)
    label:SetPoint("TOPLEFT", x, y) label:SetWidth(width or 540) label:SetText(text)
    return label
end
local function Button(parent, text, x, y, width, click)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, 30) button:SetPoint("TOPLEFT", x, y)
    ns.Panel(button, 1)
    button.label = ns.Font(button, 12, "CENTER") button.label:SetPoint("CENTER") button.label:SetText(text)
    button:SetScript("OnClick", click)
    return button
end
local function Group(key)
    for _, group in ipairs(ns.trackerGroups) do if group.key == key then return group end end
end
local function ClassName()
    if not UnitClass then return "your character" end
    local _, token = UnitClass("player")
    if not ns.Readable(token) or type(token) ~= "string" then return "your character" end
    return (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token]) or token
end
function ns.CommitTrackerAssistant()
    local window = ns.trackerAssistant
    if not window or not Group(window.group) then return false end
    ns.db.trackers.enabled = true
    ns.db.trackers.groups[window.group] = true
    ns.db.trackers.styles[window.group] = ns.Copy(window.draft)
    ns.NormalizeCustomization() ns.QueueLayout()
    window.saved = true
    return true
end
function ns.RefreshTrackerAssistant()
    local w = ns.trackerAssistant
    if not w then return end
    local group = Group(w.group)
    w.heading:SetText("Tracker Setup  |  " .. w.step .. " / 4")
    for i, page in ipairs(w.pages) do page:SetShown(w.step == i) end
    w.back:SetShown(w.step > 1)
    w.next.label:SetText(w.step == 4 and "Save group style" or "Next")
    w.subtitle:SetText(ClassName() .. "  |  " .. ns.TrackerStatus())
    for key, button in pairs(w.groupButtons) do ns.ThemeButton(button, key == w.group) end
    w.description:SetText(descriptions[w.group])
    w.styleTitle:SetText(group.label .. (w.group == "bars" and " — timer bars" or " — icons"))
    w.size.label:SetText("Group size: " .. math.floor(w.draft.scale * 100 + 0.5) .. "%")
    w.font.label:SetText("Timer / text size: " .. w.draft.fontSize)
    w.background.label:SetText("Group background: " .. (w.draft.background and "On" or "Off"))
    ns.ThemeButton(w.background, w.draft.background)
    w.preset.label:SetText("Skin: " .. w.draft.skin)
    w.opacity.label:SetText("Background opacity: " .. (w.draft.opacity < 0 and "HUD" or math.floor(w.draft.opacity*100+0.5) .. "%"))
    w.timers.label:SetText("Icon timers: " .. (w.draft.timers and "On" or "Off"))
    w.timers:SetShown(w.group ~= "bars")
    local modes = {always = "Always show", hideCountdown = "Hide during countdown", dimCountdown = "Dim during countdown"}
    w.visibility.label:SetText(ns.TrackerCountdownVisibilitySupported() and (modes[w.draft.visibility] or modes.always) or "Countdown hiding unavailable")
    w.visibility:SetShown(w.group == "essential" or w.group == "utility")
    w.layout.label:SetText(w.draft.layout == "compactOutOfCombat" and "Compact outside combat" or "Fixed slots")
    w.layout:SetShown(w.group == "essential" or w.group == "utility")
    w.preview:SetScale(w.draft.scale)
    ns.Panel(w.preview, w.draft.opacity >= 0 and w.draft.opacity or ns.db.opacity)
    local color = ns.db.colors.panel
    local opacity = w.draft.opacity >= 0 and w.draft.opacity or ns.db.opacity
    ns.SetPanelColor(w.preview, color[1], color[2], color[3], w.draft.background and color[4] * opacity or 0)
    ns.SetBorderColor(w.preview, unpack(w.draft.background and ns.db.colors.border or {0, 0, 0, 0}))
    for i, item in ipairs(w.previewItems) do
        item:ClearAllPoints()
        item:SetPoint("TOPLEFT", w.preview, "TOPLEFT", w.group == "bars" and 10 or 10 + (i-1)*54, w.group == "bars" and -10 - (i-1)*50 or -10)
        item.previewMask:SetTexture(w.draft.skin == "round" and "Interface\\AddOns\\CleanCenterUI\\Media\\CircleMask.tga" or ns.WHITE)
        item.ring:SetShown(w.draft.skin == "round")
        ns.SetBorderColor(item, unpack((w.draft.skin == "minimal" or w.draft.skin == "round") and {0,0,0,0} or ns.db.colors.border))
        local alpha = (w.group == "essential" or w.group == "utility") and w.draft.visibility ~= "always" and i == 1
            and (w.draft.visibility == "hideCountdown" and 0 or 0.2) or 1
        item:SetAlpha(alpha)
        item.time:SetShown(w.group == "bars" or w.draft.timers)
        item.bar:SetShown(w.group == "bars")
        item.name:SetShown(w.group == "bars")
        item.time:SetFont(ns.FONT, w.draft.fontSize, "OUTLINE")
    end
    w.spells:SetText("For " .. group.label .. ": select the spells or buffs you want in Blizzard's editor. ZeG UI will style that existing group. Selection is not completed by saving this wizard.")
    w.summary:SetText(group.label .. ": " .. math.floor(w.draft.scale * 100 + 0.5) .. "% size, " .. w.draft.fontSize .. " pt text, " .. w.draft.skin .. " skin, " .. (modes[w.draft.visibility] or modes.always) .. ", " .. (w.draft.layout == "compactOutOfCombat" and "compact outside combat, " or "fixed slots, ") .. (w.draft.background and "background on." or "background off.") .. "\n\nSave styling, then unlock and drag the native group. Repeat this assistant for your other groups.")
    w.status:SetText(w.saved and "Style saved. Configure spells in Blizzard, then place the group." or "Preview uses sample icons and durations. Nothing changes until you save.")
end
function ns.OpenTrackerAssistant()
    if ns.unsupported or not ns.db then return end
    if InCombatLockdown() then ns.Print("Open tracker setup outside combat.") return end
    if not ns.trackerAssistant then
        local w = CreateFrame("Frame", "ZeGUITrackerAssistant", UIParent)
        ns.trackerAssistant = w
        w:SetSize(620, 660) w:SetPoint("CENTER") w:SetFrameStrata("DIALOG") w:SetFrameLevel(150)
        w:SetClampedToScreen(true) ns.Panel(w, 0.98)
        w.heading = Label(w, "", 24, -20, 550, 20)
        w.subtitle = Label(w, "", 24, -52, 560, 12)
        Button(w, "X", 568, -18, 28, function() w:Hide() end)
        w.pages = {}
        for i = 1, 4 do
            local page = CreateFrame("Frame", nil, w)
            page:SetPoint("TOPLEFT", 24, -92) page:SetSize(572, 466) w.pages[i] = page
        end
        local first = w.pages[1]
        Label(first, "1. Which group would you like to set up?", 0, 0)
        w.groupButtons = {}
        for i, group in ipairs(ns.trackerGroups) do
            local key = group.key
            w.groupButtons[key] = Button(first, group.label .. (key == "bars" and " — timers" or " — icons"), 0, -36 - (i-1)*38, 550, function()
                w.group = key w.saved = false
                w.draft = ns.Copy(ns.db.trackers.styles[key])
                if w.draft.fontSize == 0 then w.draft.fontSize = ns.db.trackers.fontSize end
                ns.RefreshTrackerAssistant()
            end)
        end
        w.description = Label(first, "", 0, -208, 550)
        Label(first, "These are Blizzard's four native groups. Spell availability depends on your class, specialization and client.", 0, -274, 550, 12)
        local style = w.pages[2]
        w.styleTitle = Label(style, "", 0, 0, 550, 16)
        w.size = Button(style, "", 0, -36, 270, function()
            local sizes = {0.8, 1, 1.2, 1.4} local current = 0
            for i, size in ipairs(sizes) do if math.abs(w.draft.scale - size) < 0.01 then current = i end end
            w.saved = false w.draft.scale = sizes[current % #sizes + 1] ns.RefreshTrackerAssistant()
        end)
        w.font = Button(style, "", 284, -36, 266, function()
            w.saved = false w.draft.fontSize = w.draft.fontSize >= 24 and 10 or w.draft.fontSize + 2 ns.RefreshTrackerAssistant()
        end)
        w.preset = Button(style, "", 0, -78, 270, function()
            local choices = {"framed", "minimal", "round", "tiles"} local index = 0
            for i, value in ipairs(choices) do if value == w.draft.skin then index = i end end
            w.saved = false w.draft.skin = choices[index % #choices + 1] ns.RefreshTrackerAssistant()
        end)
        w.opacity = Button(style, "", 284, -78, 266, function()
            w.saved = false w.draft.opacity = w.draft.opacity >= 1 and -1 or math.min(1, math.max(0, w.draft.opacity) + 0.2) ns.RefreshTrackerAssistant()
        end)
        w.timers = Button(style, "", 0, -162, 270, function() w.saved = false w.draft.timers = not w.draft.timers ns.RefreshTrackerAssistant() end)
        w.visibility = Button(style, "", 284, -162, 266, function()
            if not ns.TrackerCountdownVisibilitySupported() then ns.Print("This client does not expose the required opacity setter. Icons remain visible.") return end
            local modes = {"always", "dimCountdown", "hideCountdown"} local index = 0
            for i, mode in ipairs(modes) do if mode == w.draft.visibility then index = i end end
            w.saved = false w.draft.visibility = modes[index % #modes + 1] ns.RefreshTrackerAssistant()
        end)
        w.background = Button(style, "", 0, -120, 270, function() w.saved = false w.draft.background = not w.draft.background ns.RefreshTrackerAssistant() end)
        w.layout = Button(style, "", 284, -120, 266, function()
            w.saved = false w.draft.layout = w.draft.layout == "fixed" and "compactOutOfCombat" or "fixed"
            ns.RefreshTrackerAssistant()
        end)
        Label(style, "Sample preview — not live combat tracking", 0, -204, 550, 12)
        w.preview = CreateFrame("Frame", nil, style)
        w.preview:SetSize(310, 116) w.preview:SetPoint("TOPLEFT", 4, -232) ns.Panel(w.preview, 0.9)
        w.previewItems = {}
        for i = 1, 2 do
            local item = CreateFrame("Frame", nil, w.preview)
            item:SetSize(38, 38) item:SetPoint("TOPLEFT", 10, -10 - (i-1)*50)
            ns.Panel(item, 1)
            local icon = item:CreateTexture(nil, "ARTWORK") icon:SetAllPoints(item)
            item.previewMask = item:CreateMaskTexture(nil, "ARTWORK") item.previewMask:SetAllPoints(item)
            icon:AddMaskTexture(item.previewMask)
            item.ring = item:CreateTexture(nil, "OVERLAY", nil, 7) item.ring:SetAllPoints(item)
            item.ring:SetTexture("Interface\\AddOns\\CleanCenterUI\\Media\\CircleBorder.tga") item.ring:SetVertexColor(unpack(ns.db.colors.border))
            icon:SetTexture(i == 1 and "Interface\\Icons\\Spell_Holy_PowerWordShield" or "Interface\\Icons\\Spell_Nature_TimeStop")
            item.time = ns.Font(item, 13, "CENTER") item.time:SetPoint("CENTER") item.time:SetText(i == 1 and "12" or "5")
            item.bar = item:CreateTexture(nil, "ARTWORK") item.bar:SetPoint("LEFT", item, "RIGHT", 6, 0)
            item.bar:SetSize(i == 1 and 224 or 118, 22) item.bar:SetColorTexture(unpack(ns.db.colors.accent))
            item.name = Label(item, i == 1 and "Sample buff" or "Sample effect", 48, -4, 200, 12)
            w.previewItems[i] = item
        end
        Label(style, "Hide/dim follows the native countdown display, including buff or charge timers where used. Compaction works only outside combat with readable state; combat slots stay fixed. Backgrounds are suppressed in hide/dim modes.", 0, -414, 550, 12)
        local native = w.pages[3]
        Label(native, "3. Choose monitored spells and notifications", 0, 0, 550, 16)
        w.spells = Label(native, "", 0, -40, 550)
        Button(native, "Enable Blizzard tracking", 0, -120, 270, function() ns.EnableBlizzardTrackers() ns.RefreshTrackerAssistant() end)
        Button(native, "Open Blizzard spell settings", 284, -120, 266, ns.OpenBlizzardTrackers)
        Label(native, "Want icons only while active? Use Blizzard's visibility controls where offered. A permanent icon row uses the Essential or Utility group.", 0, -174, 550, 13)
        Label(native, "Sounds and visual notifications: configure the options offered by Blizzard's editor. ZeG UI does not add its own event-triggered alerts in this build.", 0, -242, 550, 13)
        Label(native, "Custom fades and popups are not implemented. Timer and stack visibility remain Blizzard settings.", 0, -310, 550, 12)
        local finish = w.pages[4]
        Label(finish, "4. Save and place your group", 0, 0, 550, 16)
        w.summary = Label(finish, "", 0, -46, 550)
        Button(finish, "Unlock group placement", 0, -178, 270, function()
            if not w.saved then ns.Print("Save this group's style first.") return end
            if not ns.TrackerMoverVisible("tracker" .. w.group) then ns.Print(ns.TrackerStatus()) return end
            w:Hide() ns.OpenCustomize("trackers") ns.Unlock(true)
        end)
        Button(finish, "Advanced tracker settings", 284, -178, 266, function() w:Hide() ns.OpenCustomize("trackers") end)
        Label(finish, "Use /zeg lock when finished. To select different spells for this group, return to Blizzard's editor. Setting up a group does not duplicate or move spells between native groups.", 0, -238, 550, 13)
        w.back = Button(w, "Back", 24, -578, 110, function() w.step = math.max(1, w.step-1) ns.RefreshTrackerAssistant() end)
        w.next = Button(w, "Next", 392, -578, 204, function()
            if w.step == 4 then ns.CommitTrackerAssistant() else w.step = w.step+1 end
            ns.RefreshTrackerAssistant()
        end)
        w.status = Label(w, "", 24, -622, 570, 12)
        UISpecialFrames = UISpecialFrames or {} table.insert(UISpecialFrames, "ZeGUITrackerAssistant")
        w:Hide()
    end
    local w = ns.trackerAssistant
    w.step, w.group, w.saved = 1, "buffs", false
    w.draft = ns.Copy(ns.db.trackers.styles.buffs)
    if w.draft.fontSize == 0 then w.draft.fontSize = ns.db.trackers.fontSize end
    if ns.customize then ns.customize:Hide() end
    if ns.options then ns.options:Hide() end
    w:Show() ns.RefreshTrackerAssistant()
end
