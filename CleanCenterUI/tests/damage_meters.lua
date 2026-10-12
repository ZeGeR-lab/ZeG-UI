local ns, h, mode, fixture = ...
local function Equal(a, b)
    if rawequal(a, b) then return true end
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    for k, v in pairs(a) do if not Equal(v, b[k]) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end
local function Points(frame)
    local out = {}
    for i, point in ipairs(frame.points) do
        out[i] = {}
        for j, value in ipairs(point) do out[i][j] = value end
    end
    return out
end
local function Fill(row) return row.StatusBar:GetStatusBarTexture() end
local function Poll() ns.meterPoll:GetScript("OnUpdate")(ns.meterPoll, 0.6) end
local function Change(callback) callback() ns.NormalizeCustomization() ns.QueueLayout() h.tick() end
local function Click(page, text)
    for _, child in ipairs({page:GetChildren()}) do
        if child.label and child.label:GetText() == text then child:GetScript("OnClick")(child) return end
    end
    error("Missing meter control: " .. text)
end
if mode == "meters_missing" then
    assert(ns.db.meters.enabled and ns.meterPoll)
    Poll() Change(function() ns.db.meters.enabled = false end)
    return
end
if mode == "meters_late" then
    h.fight(true)
    local window = fixture.window(1)
    local points = Points(window)
    Poll()
    assert(window.Header:GetAlpha() == 0 and Fill(window.rows[1]):GetTexture() == ns.WHITE)
    assert(Equal(points, window.points))
    local late = fixture.row(window.MinimizeContainer.ScrollBox.ScrollTarget)
    h.native(function() window:InitEntry(late, fixture.data()) end)
    assert(Fill(late):GetTexture() == ns.WHITE and late.StatusBar.Background:GetAlpha() == 0)
    local cached = fixture.row(window.MinimizeContainer.SourceWindow.ScrollBox.ScrollTarget)
    h.native(function() window.MinimizeContainer.SourceWindow:InitEntry(cached, fixture.data()) end)
    Poll() assert(Fill(cached):GetTexture() == ns.WHITE)
    return
end
local window, row = fixture.windows[1], fixture.windows[1].rows[1]
if mode == "meters_off" then
    assert(window.Header:GetAlpha() == 0.95 and window.MinimizeContainer.Background:GetAlpha() == 0.7)
    assert(Fill(row):GetAtlas() == "NativeMeterFill" and not ns.hooked[window])
    Change(function() ns.db.meters.enabled = true end)
    assert(window.Header:GetAlpha() == 0 and Fill(row):GetTexture() == ns.WHITE)
    return
end
local points, size, click, parent = Points(window), {window.width, window.height}, row:GetScript("OnClick"), row:GetParent()
assert(window.Header:GetAlpha() == 0 and window.MinimizeContainer.Background:GetAlpha() == 0)
assert(Fill(row):GetTexture() == ns.WHITE and row.StatusBar.Background:GetAlpha() == 0)
assert(Equal(Fill(row).vertexColor, {0.22, 0.7, 0.9, 1}))
assert(row.StatusBar.value and issecretvalue(row.StatusBar.value))
assert(row.StatusBar.Name.text and issecretvalue(row.StatusBar.Name.text))
row:GetScript("OnClick")(row) assert(fixture.clicks == 1)
window:GetScript("OnDragStart")(window) assert(fixture.nativeDrag)
if mode == "meters_native" then
    for _, current in ipairs(fixture.windows) do
        assert(current.Header:GetAlpha() == 0 and Fill(current.rows[1]):GetTexture() == ns.WHITE)
        assert(Fill(current.MinimizeContainer.LocalPlayerEntry):GetTexture() == ns.WHITE)
        assert(Fill(current.MinimizeContainer.SourceWindow.rows[1]):GetTexture() == ns.WHITE)
    end
    local newColor = {0.3, 0.6, 0.2, 1}
    h.native(function() window:InitEntry(row, fixture.data(newColor)) row:UpdateStyle() end)
    assert(Equal(Fill(row).vertexColor, newColor))
    assert(row.StatusBar.Background:GetAlpha() == 0 and row.StatusBar.BackgroundEdge:GetAlpha() == 0)
    local after = h.mutations() Poll() Poll() assert(h.mutations() == after, "Idle discovery rebuilt meter decorations")
    window.MinimizeButton:GetScript("OnClick")(window.MinimizeButton)
    assert(not window.MinimizeContainer:IsShown() and window.Header:GetAlpha() == 0)
elseif mode == "meters_colors" then
    Change(function() ns.db.meters.colorMode = "accent" end)
    assert(Equal(Fill(row).vertexColor, ns.db.colors.accent))
    ns.ApplyTheme("gold") h.tick() assert(Equal(Fill(row).vertexColor, ns.db.colors.accent))
    Change(function() ns.db.meters.colorMode = "custom" ns.db.meters.color = {0.17, 0.38, 0.88, 0.6} end)
    assert(Equal(Fill(row).vertexColor, ns.db.meters.color))
    h.native(function() window:InitEntry(row, fixture.data({0.8, 0.2, 0.3, 1})) end)
    assert(Equal(Fill(row).vertexColor, ns.db.meters.color))
    Change(function() ns.db.meters.colorMode = "native" end)
    assert(Equal(Fill(row).vertexColor, {0.8, 0.2, 0.3, 1}))
elseif mode == "meters_secret" then
    local color = {h.secret(), h.secret(), h.secret(), h.secret()}
    h.fight(true)
    h.native(function() window:InitEntry(row, fixture.data(color)) end)
    for i = 1, 4 do assert(Fill(row).vertexColor[i] == color[i]) end
    Poll()
    h.fight(false)
    Change(function() ns.db.meters.colorMode = "accent" end)
    assert(Equal(Fill(row).vertexColor, ns.db.colors.accent))
    Change(function() ns.db.meters.colorMode = "native" end)
    for i = 1, 4 do assert(Fill(row).vertexColor[i] == color[i]) end
    Change(function() ns.db.meters.enabled = false end)
    for i = 1, 4 do assert(Fill(row).vertexColor[i] == color[i]) end
elseif mode == "meters_restore" then
    Change(function() ns.db.meters.colorMode = "accent" end)
    h.native(function()
        window.Header:SetAlpha(0.85) row:UpdateStyle()
        row.StatusBar.Name:SetFont("UpdatedNativeFont", 17, "THICKOUTLINE")
        row.StatusBar.Name:SetTextColor(0.4, 0.5, 0.6, 0.7)
        Fill(row):SetAtlas("ChangedNativeFill") Fill(row):SetTexCoord(0.2, 0.8, 0.3, 0.7)
        Fill(row):SetVertexColor(0.75, 0.25, 0.5, 1)
    end)
    Change(function() ns.db.meters.enabled = false end)
    assert(window.Header:GetAlpha() == 0.85 and row.StatusBar.Background:GetAlpha() == 0.65)
    assert(row.StatusBar.BackgroundEdge:GetAlpha() == 0.75 and Fill(row):GetAtlas() == "ChangedNativeFill")
    assert(Equal({row.StatusBar.Name:GetFont()}, {"UpdatedNativeFont", 17, "THICKOUTLINE"}))
    assert(Equal(row.StatusBar.Name.textColor, {0.4, 0.5, 0.6, 0.7}))
    assert(Equal(Fill(row).vertexColor, {0.75, 0.25, 0.5, 1}))
    for panel in pairs(ns.panels) do
        if panel:GetParent() == window or panel:GetParent() == window.MinimizeContainer then assert(not panel:IsShown()) end
    end
    Change(function() ns.db.meters.enabled = true end)
    assert(window.Header:GetAlpha() == 0 and Fill(row):GetTexture() == ns.WHITE)
    ns.SetEnabled(false)
    assert(window.Header:GetAlpha() == 0.85 and Fill(row):GetAtlas() == "ChangedNativeFill")
elseif mode == "meters_combat" then
    h.fight(true)
    Change(function() ns.db.meters.colorMode = "custom" ns.db.meters.color = {1, 0, 0, 0.5} ns.db.fontSettings.meters.size = 20 end)
    h.native(function() window:InitEntry(row, fixture.data({0.2, 0.3, 0.4, 1})) end)
    assert(Equal(Fill(row).vertexColor, {0.2, 0.3, 0.4, 1}) and select(2, row.StatusBar.Name:GetFont()) == 13)
    h.fight(false) h.tick()
    assert(Equal(Fill(row).vertexColor, ns.db.meters.color) and select(2, row.StatusBar.Name:GetFont()) == 20)
    EventRegistry:TriggerEvent("EditMode.Enter")
    Change(function() ns.db.meters.enabled = false end)
    assert(window.Header:GetAlpha() == 0)
    EventRegistry:TriggerEvent("EditMode.Exit") h.tick()
    assert(window.Header:GetAlpha() == 0.95)
elseif mode == "meters_profiles" then
    Change(function() ns.db.meters.colorMode = "custom" ns.db.meters.color = {0.4, 0.6, 0.2, 0}
        ns.db.meters.opacity = 0.4 ns.db.meters.rowBorders = false ns.db.fontSettings.meters.size = 18 end)
    assert(ns.SaveProfile("Meters"))
    local exported = assert(ns.ExportProfile("Meters"))
    assert(ns.ImportProfile("Imported", exported) and ns.profiles.Imported.meters.color[4] == 0)
    Change(function() ns.db.meters = ns.Copy(ns.defaults.meters) end)
    assert(ns.LoadProfile("Imported")) h.tick()
    assert(Equal(Fill(row).vertexColor, {0.4, 0.6, 0.2, 0}) and ns.db.fontSettings.meters.size == 18)
    assert(ns.ImportProfile("Old", "CCUI1\nrows\tn\t3"))
    assert(ns.profiles.Old.meters.enabled and ns.profiles.Old.meters.colorMode == "native")
    assert(not ns.ImportProfile("Bad", "CCUI1\nmeters.colorMode\ts\tunknown"))
elseif mode == "meters_ui" then
    SlashCmdList.CLEANCENTERUI("meters") assert(ns.customize.page == "meters")
    local page = ns.customize.pages.meters
    Click(page, "Native / class colors") h.tick()
    assert(ns.db.meters.colorMode == "accent" and Equal(Fill(row).vertexColor, ns.db.colors.accent))
    ns.RefreshCustomize() Click(page, "UI accent") h.tick()
    assert(ns.db.meters.colorMode == "custom")
    Click(page, "Choose custom bar color")
    ColorPickerFrame.r, ColorPickerFrame.g, ColorPickerFrame.b, ColorPickerFrame.a = 0.1, 0.2, 0.3, 0.4
    ColorPickerFrame.info.swatchFunc() h.tick()
    assert(Equal(Fill(row).vertexColor, {0.1, 0.2, 0.3, 0.4}))
    ColorPickerFrame:OnCancel() h.tick()
    assert(Equal(ns.db.meters.color, ns.defaults.meters.color))
    local opacityControl
    for _, child in ipairs({page:GetChildren()}) do
        if child.label and child.label:GetText() == "+" and child.points[1][5] == -126 then
            opacityControl = child
            child:GetScript("OnClick")(child) h.tick()
            assert(ns.db.meters.opacity == 0, "Opacity increment cannot leave HUD mode")
            child:GetScript("OnClick")(child) h.tick()
            assert(ns.db.meters.opacity == 0.05)
        end
    end
    assert(opacityControl, "Missing meter opacity control")
    Click(page, "Meter fonts / outline")
    assert(ns.customize.page == "fonts" and ns.customize.fontCategory == "meters")
    ns.OpenCustomize("meters") Click(page, "Reset meter skin") h.tick()
    assert(Equal(ns.db.meters, ns.defaults.meters) and ns.db.fontSettings.meters.size == 0)
elseif mode == "meters_forbidden" then
    assert(fixture.windows[2].Header:GetAlpha() == 0.95)
    assert(Fill(fixture.windows[3].rows[1]):GetAtlas() == "NativeMeterFill")
    Poll()
else error("Unknown meter scenario") end
assert(Equal(window.points, points) and Equal({window.width, window.height}, size) and row:GetParent() == parent,
    "Meter skin changed native geometry or ownership")
assert(window:GetScript("OnDragStart") and row:GetScript("OnClick"), "Meter skin removed native input")
