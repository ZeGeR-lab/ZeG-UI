-- Behavior checks on top of the strict native-widget / secret-value simulator.
local ns, h, mode = ...
local function Equal(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    for key, value in pairs(a) do if not Equal(value, b[key]) then return false end end
    for key in pairs(b) do if a[key] == nil then return false end end
    return true
end
local function Close(a, b) return math.abs(a - b) < 0.00001 end
local function Click(page, text)
    for _, button in ipairs({page:GetChildren()}) do
        if button.label and button.label:GetText() == text then button:GetScript("OnClick")(button) return button end
    end
    error("Missing control: " .. text)
end
local function Setting(kind, index, key)
    for _, system in ipairs(h.layout().systems) do
        if system.system == kind and system.systemIndex == index then
            for _, setting in ipairs(system.settings) do if setting.setting == key then return setting.value end end
        end
    end
end
local function AuraPixels(frame)
    for _, button in ipairs({frame.AuraContainer:GetChildren()}) do
        if button.Icon and button.Icon:GetObjectType() == "Texture" then
            return button.Icon:GetWidth() * button.Icon:GetEffectiveScale() / ns.root:GetEffectiveScale()
        end
    end
    error("Missing native aura icon")
end
if mode == "custom_patterns" then
    local bar = MainActionBar
    local click = bar.actionButtons[1]:GetScript("OnClick")
    ns.SetBarPreference(1, "columns", 1) h.tick()
    local m = ns.BarMetrics(1)
    assert(m.columns == 1 and m.lines == 12)
    local tall = m.rowHeight
    ns.SetBarPreference(1,"keyPosition","inside")
    ns.SetBarPreference(1,"border","bold") h.tick()
    assert(ns.BarMetrics(1).rowHeight < tall)
    assert(bar.actionButtons[1].HotKey:GetPoint() == "TOPRIGHT")
    assert(ns.actionBorderArt[bar.actionButtons[1]]:GetTexture():find("SquareBorderBold.tga",1,true))
    local _, _, _, x1, y1 = bar.actionButtons[1]:GetPoint()
    local _, _, _, x2, y2 = bar.actionButtons[2]:GetPoint()
    assert(x1 == x2 and y2 > y1)
    ns.SetBarPreference(1, "shape", "octagons")
    ns.SetBarPreference(1, "columns", 4) h.tick()
    assert(ns.BarMetrics(1).columns == 4)
    assert(ns.buttonShapes[bar.actionButtons[1]].mask.texture:find("Octagon.tga", 1, true))
    ns.SetBarPreference(1, "columns", 12)
    ns.SetBarPreference(1, "individual", true)
    ns.db.barSettings[1].offsets[1] = {x = 37, y = -22}
    h.tick()
    local gx, gy = ns.BarSlot(ns.BarMetrics(1), 1)
    local _, relative, _, ix, iy = bar.actionButtons[1]:GetPoint()
    assert(relative == ns.barAnchors[bar] and ix == gx+37 and iy == gy-22)
    ns.Unlock(true)
    assert(ns.buttonEditors[bar.actionButtons[1]].frame:IsShown())
    local editor = ns.buttonEditors[bar.actionButtons[1]].frame
    local originalCenter = editor.GetCenter
    local bx, by = bar.actionButtons[1]:GetCenter()
    editor.GetCenter = function() return bx+20, by-10 end
    editor:GetScript("OnDragStart")() editor:GetScript("OnDragStop")() h.tick()
    editor.GetCenter = originalCenter
    assert(ns.db.barSettings[1].offsets[1].x == 57 and ns.db.barSettings[1].offsets[1].y == -32)
    ns.Unlock(false)
    assert(not ns.buttonEditors[bar.actionButtons[1]].frame:IsShown())
    local highlight = ns.buttonShapes[bar.actionButtons[1]].highlight.region
    assert(highlight.allPoints == bar.actionButtons[1])
    assert(bar.actionButtons[1]:GetScript("OnClick") == click)
    assert(ns.SaveProfile("Patterns"))
    local encoded = assert(ns.ExportProfile("Patterns"))
    assert(encoded:find("individual",1,true) and encoded:find("octagons",1,true))
    h.fight(true) local before = h.mutations()
    ns.SetBarPreference(1,"individual",false) h.tick()
    assert(h.mutations() == before)
    h.fight(false) h.tick()
    assert(({bar.actionButtons[1]:GetPoint()})[4] == gx)
    ns.SetBarPreference(1,"shape","square") h.tick()
    assert(not ns.buttonShapes[bar.actionButtons[1]].active)
    assert(not ns.pending)
    for i = 1, 100 do
        bar.actionButtons[1]:UpdateHotkeys() bar:UpdateShownButtons() bar:UpdateGridLayout()
    end
    assert(not ns.pending, "Ordinary action updates still requested a full HUD rebuild")
    ns.db.rows = 4 ns.QueueLayout() h.tick() ns.Unlock(true)
    local mover = ns.movers.bar4
    assert(mover and mover:IsShown() and mover.height == 22)
    assert(({mover:GetPoint()})[3] == "TOPLEFT", "Whole-bar handle still overlaps the button editors")
    mover:GetScript("OnDragStart")()
    assert(ns.IsDraggingLayout())
    ns.QueueLayout() h.tick() assert(ns.pending, "A layout rebuild ran during a bar drag")
    mover:GetScript("OnDragStop")() h.tick()
    assert(not ns.IsDraggingLayout() and ns.db.positions.bar4, "Bar 4 drag did not save")
    local anchor = ns.barAnchors[MultiBarRight]
    assert(({MultiBarRight.actionButtons[1]:GetPoint()})[2] == anchor)
    ns.Unlock(false)
elseif mode == "custom_profiles" then
    ns.db.unitStyles.player.classColor = false ns.db.unitStyles.player.portrait = false
    ns.db.unitStyles.player.healthColor = {0.17, 0.41, 0.83, 0.7}
    ns.db.fontSettings.health.size = 18 ns.db.fade.enabled = false
    ns.db.barSettings[3] = {size = 36, spacing = 2, columns = 6, shape = "triangles"}
    ns.db.positions.StanceBar, ns.db.positions.experience = {x = -341, y = -117}, {x = 0, y = -474}
    ns.db.positions.player = {x = -301, y = -77}
    assert(ns.SaveProfile("Main"))
    local original = ns.CapturePreferences()
    local encoded = assert(ns.ExportProfile("Main"))
    assert(not encoded:find("backup") and not encoded:find("nativeBars") and not encoded:find("\nenabled\tb", 1, true))
    assert(ns.ImportProfile("Shared", encoded))
    assert(Equal(ns.profiles.Shared, original), "Profile export lost false flags or custom positions")
    local account = CleanCenterUIProfilesDB ns.InitializeProfiles()
    assert(CleanCenterUIProfilesDB == account and ns.profiles == account.profiles)
    local backup, native = ns.db.backup, ns.db.nativeBars
    ns.db.positions = {} ns.db.fontSettings.health.size = 10 ns.db.rows = 1 ns.db.unitStyles.player.classColor = true
    assert(ns.LoadProfile("Shared")) h.tick()
    assert(Equal(ns.CapturePreferences(), original))
    assert(ns.db.backup == backup and ns.db.nativeBars == native and ns.db.enabled)
    assert(ns.DeleteProfile("Main") and not ns.profiles.Main and ns.profiles.Shared)
    ns.profiles.Shared.modules.chat = false
    local reload = h.reloads() assert(ns.LoadProfile("Shared"))
    assert(h.reloads() == reload + 1 and not ns.db.modules.chat, "Module profile change did not restore then reload")
elseif mode == "custom_profile_validation" then
    assert(ns.SaveProfile("Safe"))
    local before = ns.CapturePreferences()
    local texts = {"return os.execute('bad')", "CCUI1\nbackup.chat.width\tn\t1", "CCUI1\nrows\tn\tNaN",
        "CCUI1\nrows\tn\t1e309", "CCUI1\nrows\tn\t2\nrows\tn\t3", "CCUI1\nrows\tb\t1",
        "CCUI1\nmodules.chat\tb\tmaybe", "CCUI1\nfontFace\ts\t%GG", "CCUI1\nfontFace\ts\t%00",
        "CCUI1\nfontFace\ts\tunknown", "CCUI1\npositions.player.x\tn\t123", string.rep("x", 65537)}
    for _, value in ipairs(texts) do assert(not ns.ImportProfile("Bad", value)) end
    assert(not ns.profiles.Bad and Equal(ns.CapturePreferences(), before))
    assert(not ns.SaveProfile(" ") and not ns.SaveProfile(string.rep("a", 41)))
    assert(ns.ImportProfile("Partial", "CCUI1\nmodules.chat\tb\t0\nrows\tn\t3"))
    assert(ns.profiles.Partial.rows == 3 and ns.profiles.Partial.modules.chat == false and ns.profiles.Partial.buttonSize == 48)
    ns.profiles.Safe.rows = 0/0 assert(not ns.LoadProfile("Safe"))
elseif mode == "custom_profile_combat" then
    ns.db.barSettings[1].size = 60 ns.db.positions.player = {x = -400, y = -170}
    assert(ns.SaveProfile("Large"))
    ns.db.barSettings[1].size = 0 ns.db.positions.player = nil ns.QueueLayout() h.tick()
    local width = MainActionBar.actionButtons[1]:GetWidth()
    h.fight(true) local before = h.mutations()
    assert(ns.LoadProfile("Large")) h.tick()
    assert(ns.pendingProfile and ns.db.barSettings[1].size == 0 and h.mutations() == before)
    assert(MainActionBar.actionButtons[1]:GetWidth() == width)
    h.fight(false) h.tick()
    assert(not ns.pendingProfile and MainActionBar.actionButtons[1]:GetWidth() == 60 and ns.db.positions.player.x == -400)
    EventRegistry:TriggerEvent("EditMode.Enter")
    assert(ns.LoadProfile("Large") and ns.pendingProfile)
    EventRegistry:TriggerEvent("EditMode.Exit") h.tick() assert(not ns.pendingProfile)
elseif mode == "custom_alignment" then
    assert(not ns.db.editor.snap and not ns.db.editor.guides)
    ns.db.editor.snap, ns.db.editor.guides, ns.db.editor.grid = true, true, 8
    assert(ns.SavePosition("player", 31, -44, false))
    ns.MirrorUnitPositions("player") h.tick()
    assert(ns.db.positions.target.x == -31 and ns.db.positions.target.y == -44)
    local mover, frame = ns.movers.player, ns.movers.player.target
    local rx, ry = ns.root:GetCenter() local previous = frame.GetCenter
    frame.GetCenter = function() return rx + 51, ry - 27 end
    ns.Unlock(true) assert(ns.guides:IsShown() and #ns.guides.lines > 2)
    mover:GetScript("OnDragStart")() mover:GetScript("OnDragStop")() h.tick()
    frame.GetCenter = previous
    assert(ns.db.positions.player.x == 51 and ns.db.positions.player.y == -27)
    assert(not ns.SavePosition("player", 0/0, 5, false))
    ns.SavePosition("target",49,17,true)
    assert(ns.db.positions.target.x == 48 and ns.db.positions.target.y == 16, "Gentle snap missed a nearby grid line")
    IsAltKeyDown = function() return true end
    ns.SavePosition("target",49,17,true)
    assert(ns.db.positions.target.x == 49 and ns.db.positions.target.y == 17, "Alt did not bypass snapping")
    IsAltKeyDown = nil
    ns.db.editor.snap = false ns.SavePosition("target", 35, 19, true)
    assert(ns.db.positions.target.x == 35 and ns.db.positions.target.y == 19)
    h.fight(true) assert(not ns.guides:IsShown() and not mover:IsShown())
elseif mode == "custom_bars" then
    local first = MainActionBar.actionButtons[1]
    local click, parent = first:GetScript("OnClick"), first:GetParent()
    ns.SetBarPreference(1, "size", 36) ns.SetBarPreference(1, "columns", 6)
    ns.SetBarPreference(1, "spacing", 3) ns.SetBarPreference(1, "shape", "triangles")
    ns.SetBarPreference(2, "size", 54) ns.SetBarPreference(2, "columns", 4) h.tick()
    assert(#MainActionBar.actionButtons == 12 and #MultiBarBottomLeft.actionButtons == 12)
    assert(first:GetWidth() == 36 and MultiBarBottomLeft.actionButtons[1]:GetWidth() == 54)
    local _, _, _, x1, y1 = first:GetPoint()
    local _, _, _, x7, y7 = MainActionBar.actionButtons[7]:GetPoint()
    assert(x1 == x7 and y7 > y1, "Wrapped slots were hidden instead of placed on a second line")
    assert(MainActionBar.actionButtons[12]:IsVisible())
    assert(first:GetParent() == parent and first:GetScript("OnClick") == click)
    click(first) assert(first.nativeClicks == 1)
    ns.SetBarPreference(1, "spacing", 20) h.tick()
    local left, right = first:GetHitRectInsets() assert(left >= 0 and right >= 0)
    assert(Setting(0, 1, 1) == 1 and Setting(0, 1, 2) == 12, "Native paging settings were replaced by custom wrapping")
    ns.SetBarPreference(9, "size", 30) ns.SetBarPreference(1, "size", 0/0)
    assert(ns.db.barSettings[1].size == 36)
elseif mode == "custom_bars_combat" then
    ns.SetBarPreference(1, "columns", 6) ns.SetBarPreference(2, "size", 40) h.tick()
    local rects = {}
    for row = 1, 2 do for i, button in ipairs(_G[h.bars[row]].actionButtons) do rects[button] = {h.rect(button)} end end
    h.fight(true) local before = h.mutations()
    ns.SetBarPreference(1, "size", 64) ns.SetBarPreference(1, "columns", 4) h.tick()
    assert(h.mutations() == before, "Preference change moved protected bars during combat")
    for button, rect in pairs(rects) do
        local actual = {h.rect(button)} for i = 1, 4 do assert(Close(rect[i], actual[i]), "Wrapped bar shifted in combat") end
        assert(button:IsVisible(), "Action slot disappeared in combat")
    end
    h.fight(false) h.tick()
    assert(MainActionBar.actionButtons[1]:GetWidth() == 64 and ns.BarMetrics(1).columns == 4)
elseif mode == "custom_fonts" then
    ns.db.fontFace = "arial"
    ns.db.fontSettings.names = {size = 17, outline = "THICKOUTLINE"}
    ns.db.fontSettings.health = {size = 14, outline = ""}
    ns.db.fontSettings.cooldowns.size = 20 ns.db.fontSettings.chat.size = 16
    ns.QueueLayout() h.tick()
    assert(ns.unitFrames.player.name.font[1] == ns.fontFaces.arial and ns.unitFrames.player.name.font[2] == 17)
    assert(ns.unitFrames.player.value.font[2] == 14 and ns.unitFrames.player.value.font[3] == "")
    assert(ns.unitFrames.player.name.font[3] == "THICKOUTLINE")
    assert(MainActionBar.actionButtons[1].cooldown:GetCountdownFontString().font[2] == 20)
    assert(ChatFrame1.font[2] == 16 and ns.castDisplays.cast.Text.font[2] == 12)
    ns.db.fontSettings.names.size = 0 ns.QueueLayout() h.tick() assert(ns.unitFrames.player.name.font[2] == 14)
    ns.db.auras.enabled = false ns.db.tooltip.enabled = false ns.QueueLayout() h.tick()
    assert(GameTooltipTextLeft1.font[1] == "NativeTooltipFont" and GameTooltipTextLeft1.font[2] == 14)
elseif mode == "custom_themes" then
    ns.db.positions.player = {x = -373, y = -119} ns.db.unitStyles.player.width = 353
    ns.ApplyTheme("gold") h.tick()
    assert(ns.db.colors.accent[1] == 0.92 and ns.db.colors.panel[1] == 0.025)
    assert(ns.db.unitStyles.player.width == 353 and ns.db.positions.player.x == -373)
    ns.ApplyTheme("class") h.tick()
    assert(ns.db.classAccent and ns.db.colors.accent[1] == RAID_CLASS_COLORS.PALADIN.r)
    ns.PickColor(ns.db.colors, "accent")
    ColorPickerFrame.r, ColorPickerFrame.g, ColorPickerFrame.b, ColorPickerFrame.a = 0.12, 0.23, 0.34, 0.8
    ColorPickerFrame.info.swatchFunc() h.tick()
    assert(not ns.db.classAccent and ns.db.themePreset == "custom" and ns.db.colors.accent[1] == 0.12)
    ColorPickerFrame:OnCancel() h.tick() assert(ns.db.classAccent and ns.db.themePreset == "class")
    ns.ApplyTheme("teal") h.tick() assert(ns.db.colors.accent[2] == 0.8 and not ns.db.classAccent)
elseif mode == "custom_auras" then
    ns.db.auras.size, ns.db.auras.spacing, ns.db.auras.columns = 42, 9, 5 ns.QueueLayout() h.tick()
    assert(BuffFrame.AuraContainer.iconScale == 1.4 and BuffFrame.AuraContainer.iconPadding == 9)
    assert(Close(AuraPixels(BuffFrame), 42) and Close(AuraPixels(DebuffFrame), 42))
    assert(Setting(5, 1, 0) == 9 and Setting(5, 2, 3) == 5)
    assert(BuffFrame:GetParent() == UIParent and DebuffFrame:GetParent() == UIParent)
    local _, relative = DebuffFrame:GetPoint() assert(relative == BuffFrame, "Debuffs do not follow growing buff rows")
    for button, handlers in pairs(h.nativeAuraHandlers) do
        assert(button:GetScript("OnClick") == handlers.click and button:GetScript("OnEnter") == handlers.enter)
        assert(button.Icon.texCoord[1] == 0.07 and button.Duration.font[1] == ns.fontFaces[ns.db.fontFace])
        assert(issecretvalue(button.Duration:GetText()) and button.DebuffBorder:GetAlpha() == 1)
    end
    h.fight(true) local before = h.mutations()
    ns.db.auras.size = 30 ns.QueueLayout() h.tick() h.poll()
    assert(h.mutations() == before and Setting(5, 1, 0) == 9)
    h.fight(false) h.tick() assert(Setting(5, 1, 0) == 5)
    ns.db.auras.enabled = false ns.QueueLayout() h.tick()
    assert(Setting(5, 1, 0) == 5 and Setting(5, 1, 1) == 8 and Setting(5, 1, 2) == 6)
    for button in pairs(h.nativeAuraHandlers) do assert(button.Icon.texCoord[1] == 0 and button.Duration.font[1] == "NativeAuraFont") end
elseif mode == "custom_aura_sizes" or mode == "custom_aura_sizes_scaled" then
    assert(ns.defaults.auras.size == 27 and ns.db.auras.size == 27)
    assert(Close(AuraPixels(BuffFrame), 27) and Close(AuraPixels(DebuffFrame), 27))
    assert(ns.db.positions.buffs.x == 550 and ns.db.positions.buffs.y == 280)
    -- Reproduce an already-saved 0.4.0/0.4.1 profile: percentages were
    -- interpreted as slider positions and clamped to 200% / 60px.
    h.native(function()
        local layouts = C_EditMode.GetLayouts()
        local layout = layouts.layouts[layouts.activeLayout - 3]
        for _, system in ipairs(layout.systems) do
            if system.system == 5 then
                for _, setting in ipairs(system.settings) do if setting.setting == 0 then setting.value = 93 end end
            end
        end
        C_EditMode.SaveLayouts(layouts)
    end)
    assert(Close(AuraPixels(BuffFrame), 60), "Native slider fixture did not reproduce oversized buffs")
    ns.QueueLayout() h.tick()
    assert(Close(AuraPixels(BuffFrame), 27) and Close(AuraPixels(DebuffFrame), 27))
    for size = 15, 60, 3 do
        ns.db.auras.size = size ns.NormalizeCustomization() ns.QueueLayout() h.tick()
        assert(Close(AuraPixels(BuffFrame), size) and Close(AuraPixels(DebuffFrame), size),
            "Buff size differs from its HUD pixel setting")
        assert(Setting(5, 1, 0) >= 0 and Setting(5, 1, 0) <= 15)
    end
    ns.db.auras.size = 28 ns.NormalizeCustomization() ns.QueueLayout() h.tick()
    assert(ns.db.auras.size == 27 and Close(AuraPixels(BuffFrame), 27))
    assert(ns.ImportProfile("Legacy buffs", "CCUI1\nauras.size\tn\t28"))
    assert(ns.LoadProfile("Legacy buffs")) h.tick()
    assert(ns.db.auras.size == 27 and Close(AuraPixels(BuffFrame), 27))
    ns.OpenCustomize("auras")
    local page = ns.customize.pages.auras
    local plus, minus
    for _, child in ipairs({page:GetChildren()}) do
        if child.label and child.points[1][5] == -42 then
            if child.label:GetText() == "+" then plus = child
            elseif child.label:GetText() == "-" then minus = child end
        end
    end
    assert(plus and minus)
    plus:GetScript("OnClick")(plus) h.tick()
    assert(ns.db.auras.size == 30 and Close(AuraPixels(BuffFrame), 30))
    minus:GetScript("OnClick")(minus) h.tick()
    assert(ns.db.auras.size == 27 and Close(AuraPixels(BuffFrame), 27))
    EventRegistry:TriggerEvent("EditMode.Enter")
    ns.db.auras.size = 36 ns.NormalizeCustomization() ns.QueueLayout() h.tick()
    assert(Close(AuraPixels(BuffFrame), 27))
    EventRegistry:TriggerEvent("EditMode.Exit") h.tick()
    assert(Close(AuraPixels(BuffFrame), 36))
    ns.db.auras.enabled = false ns.QueueLayout() h.tick()
    assert(Setting(5, 1, 0) == 5, "Original native aura slider was not restored")
    for button, handlers in pairs(h.nativeAuraHandlers) do
        assert(Close(button:GetScale(), 1) and button.Icon:GetWidth() == 30,
            "Original native aura icon size was not restored")
        assert(button:GetScript("OnClick") == handlers.click and button:GetScript("OnEnter") == handlers.enter)
    end
elseif mode == "custom_tooltips" then
    local passes = ns.tooltipStylePasses
    for i = 1, 200 do GameTooltip:Show() end
    assert(ns.tooltipStylePasses == passes, "Hover Show events repeatedly rebuilt tooltip skin")
    h.poll() local settled = ns.tooltipStylePasses
    for i = 1, 200 do GameTooltip:Show() end
    h.poll() assert(ns.tooltipStylePasses == settled, "Stable tooltip was restyled by polling")
    local owner = MainActionBar.actionButtons[1]
    GameTooltip.secretLayout = true GameTooltip:SetOwner(owner, "ANCHOR_NONE") GameTooltip:Show()
    ns.db.tooltip.anchor = "cursor" ns.QueueLayout() h.tick() h.poll()
    local point, relative, _, x, y = GameTooltip:GetPoint()
    assert(point == "BOTTOMLEFT" and relative == UIParent and x == 668 and y == 438)
    assert(GameTooltip.owner == owner and GameTooltip.NineSlice:GetAlpha() == 0)
    assert(issecretvalue(GameTooltipTextLeft1:GetText()))
    ns.db.tooltip.anchor = "fixed" ns.db.positions.tooltip = {x = 472, y = -199} ns.QueueLayout() h.tick()
    local _, anchor = GameTooltip:GetPoint() assert(anchor == ns.tooltipAnchor)
    ns.db.fontSettings.tooltip.size = 19 ns.QueueLayout() h.tick() assert(GameTooltipTextLeft1.font[2] == 19)
    ns.db.fontSettings.tooltip.size = 0 ns.QueueLayout() h.tick() assert(GameTooltipTextLeft1.font[2] == 14)
    ns.db.tooltip.enabled = false ns.QueueLayout() h.tick()
    assert(GameTooltip.NineSlice:GetAlpha() == 0.85 and not GameTooltip.ccuiTooltipPanel:IsShown())
elseif mode == "custom_swing" then
    local source, display = SwingTimerMainHandFrame, ns.swingDisplays.swingmain
    assert(display and source:GetParent() == UIParent and GetCVar("showSwingTimer") == "1")
    assert(not display:IsShown() and Setting(20,1,0) == 1)
    h.fight(true) local before = h.mutations()
    h.native(function() source.StatusBar:SetMinMaxValues(h.secret(), h.secret()) source.StatusBar:SetValue(h.secret()) end)
    h.poll()
    assert(display:IsShown() and issecretvalue(display.fill.value) and issecretvalue(display.fill.range[2]))
    for _, value in ipairs({0,0.2,0.4,0.9,1}) do source.StatusBar:SetMinMaxValues(0,1) source.StatusBar:SetValue(value) h.poll() assert(display.fill.value == value) end
    source.StatusBar:SetAlpha(0.4) h.poll() assert(display.fill:GetAlpha() == 0.4 and display:GetAlpha() == 1)
    assert(source.StatusBar:GetStatusBarTexture():GetAlpha() == 0 and h.mutations() == before)
    local handlers = h.nativeSwingHandlers[source]
    assert(source:GetScript("OnEvent") == handlers.event and source:GetScript("OnUpdate") == handlers.update)
    ns.db.swing.enabled = false ns.QueueLayout() h.tick() source.StatusBar:SetValue(0.7) h.poll()
    assert(display.fill.value == 0.7, "Combat-deferred swing toggle froze progress")
    h.fight(false) h.tick() assert(not display:IsShown() and source.Background:GetAlpha() == 1 and GetCVar("showSwingTimer") == "0")
    ns.db.swing.enabled, ns.db.swing.visibility, ns.db.swing.time = true, "always", true ns.QueueLayout() h.tick() h.poll()
    assert(display:IsShown() and display.time:IsShown() and issecretvalue(display.time:GetText()))
elseif mode == "custom_fading" then
    ns.db.fade.enabled, ns.db.fade.delay, ns.db.fade.speed, ns.db.fade.alpha = true, 1, 0.5, 0.2
    ns.QueueLayout() h.tick()
    local action, health = MainActionBar:GetAlpha(), ns.unitFrames.player:GetAlpha()
    local before = h.mutations()
    h.poll(1.25) assert(Close(ChatFrame1:GetAlpha(), 0.6))
    h.poll(0.25) assert(Close(ChatFrame1:GetAlpha(), 0.2) and Close(BagsBar:GetAlpha(), 0.2))
    assert(MainActionBar:GetAlpha() == action and ns.unitFrames.player:GetAlpha() == health and h.mutations() == before)
    h.hover(ChatFrame1) h.poll(0.1) assert(ChatFrame1:GetAlpha() == 1) h.hover(nil)
    if not ChatFrame1EditBox then ChatFrame1EditBox = CreateFrame("EditBox", nil, UIParent) end
    ChatFrame1EditBox:SetFocus() h.poll(2) assert(ChatFrame1:GetAlpha() == 1) ChatFrame1EditBox:ClearFocus()
    h.native(function() ns.bagFlyout:Show() end) h.hover(ns.bagFlyout) h.poll(2) assert(BagsBar:GetAlpha() == 1)
    h.hover(nil) h.poll(2) assert(Close(BagsBar:GetAlpha(),0.2))
    h.fight(true) before = h.mutations() h.poll(0.1)
    assert(ChatFrame1:GetAlpha() == 1 and BagsBar:GetAlpha() == 1 and h.mutations() == before)
    h.fight(false) h.poll(2) assert(Close(ChatFrame1:GetAlpha(),0.2))
    ns.OpenCustomize("fade") h.poll(0.1) assert(ChatFrame1:GetAlpha() == 1) ns.customize:Hide()
    ns.db.fade.enabled = false ns.QueueLayout() h.tick() assert(ChatFrame1:GetAlpha() == 1 and BagsBar:GetAlpha() == 1)
elseif mode == "custom_ui" then
    local keys = {"profiles","layout","bars","fonts","themes","auras","swing","fade"}
    for _, key in ipairs(keys) do
        ns.OpenCustomize(key)
        assert(ns.customize:IsShown() and ns.customize.pages[key]:IsShown())
        for other, page in pairs(ns.customize.pages) do assert(page:IsShown() == (other == key)) end
    end
    ns.OpenCustomize("profiles") ns.customize.profileName:SetText("UI saved")
    Click(ns.customize.pages.profiles, "Save / overwrite") assert(ns.profiles["UI saved"])
    Click(ns.customize.pages.profiles, "Export current") assert(ns.customize.profileText:GetText():match("^CCUI1\n"))
    ns.customize.profileName:SetText("UI imported") Click(ns.customize.pages.profiles, "Import as named")
    assert(ns.profiles["UI imported"] and ns.db.profileName == "UI saved")
    Click(ns.customize.pages.profiles, "Load") h.tick() assert(ns.db.profileName == "UI imported")
    ns.OpenCustomize("bars") Click(ns.customize.pages.bars,"6") assert(ns.customize.bar == 6)
    ns.OpenCustomize("themes") Click(ns.customize.pages.themes,"Black / gold") h.tick() assert(ns.db.themePreset == "gold")
    Click(ns.customize.pages.themes, "Choose any HUD colors")
    assert(ns.appearance:IsShown() and not ns.customize:IsShown())
    ns.OpenCustomize("auras") Click(ns.customize.pages.auras,"Move fixed tooltip location") h.tick()
    assert(ns.db.tooltip.anchor == "fixed" and ns.selectedMover == "tooltip" and ns.unlocked)
    SlashCmdList.CLEANCENTERUI("fonts") assert(ns.customize.page == "fonts")
    ns.OpenCustomize("trackers")
    assert(ns.customize.width == 750 and ns.customize.height == 520 and ns.customize:GetScale() <= 0.85)
    assert(ns.customize.tabs.trackers.activeRail:IsShown() and not ns.customize.tabs.general.activeRail:IsShown())
    assert(ns.customize.pages.trackers.viewport.scrollChild == ns.customize.pages.trackers)
    assert(ns.customize.frameLock:IsShown())
    ns.Unlock(false)
    ns.customize.frameLock:GetScript("OnClick")() assert(ns.unlocked and ns.customize.frameLock.label:GetText() == "Lock frames")
    ns.customize.frameLock:GetScript("OnClick")() assert(not ns.unlocked)
    ns.OpenOptions() assert(not ns.customize:IsShown())
    ns.options.customize:GetScript("OnClick")() assert(ns.customize:IsShown() and not ns.options:IsShown())
else error("Unknown customization test") end
