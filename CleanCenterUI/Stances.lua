local _, ns = ...
ns.stanceHighlights = {}
local poll = CreateFrame("Frame")
ns.stancePoll = poll

function ns.RefreshStanceHighlights()
    for button, textures in pairs(ns.stanceHighlights) do
        -- Forward the native checked state to textures without inspecting a
        -- potentially secret boolean or touching native stance/cooldown state.
        for _, texture in ipairs(textures) do texture:SetShown(button:GetChecked()) end
    end
end
poll:SetScript("OnUpdate", ns.RefreshStanceHighlights)

local function Highlight(button, triangle, index)
    local all = button.ccuiStanceHighlight
    if not all then
        all = {}
        local shape = button:CreateTexture(nil, "OVERLAY", nil, 7)
        shape:SetAllPoints(button)
        all.triangle = shape
        all.edges = {}
        for i, anchors in ipairs({{"TOPLEFT", "TOPRIGHT"}, {"BOTTOMLEFT", "BOTTOMRIGHT"},
            {"TOPLEFT", "BOTTOMLEFT"}, {"TOPRIGHT", "BOTTOMRIGHT"}}) do
            local edge = button:CreateTexture(nil, "OVERLAY", nil, 7)
            edge:SetPoint(anchors[1]) edge:SetPoint(anchors[2])
            if i <= 2 then edge:SetHeight(2) else edge:SetWidth(2) end
            all.edges[i] = edge
        end
        button.ccuiStanceHighlight = all
    end
    all.triangle:Hide()
    for _, edge in ipairs(all.edges) do edge:Hide() end
    local color = ns.db.colors.accent
    if triangle then
        all.triangle:SetTexture("Interface\\AddOns\\CleanCenterUI\\Media\\Triangle"
            .. (index % 2 == 1 and "Up" or "Down") .. "Border.tga")
        all.triangle:SetVertexColor(unpack(color))
        ns.stanceHighlights[button] = {all.triangle}
    else
        for _, edge in ipairs(all.edges) do edge:SetColorTexture(unpack(color)) end
        ns.stanceHighlights[button] = all.edges
    end
end

function ns.ApplyStances()
    local bar = StanceBar
    if not bar or not ns.db.modules.bars or not ns.nativeBarsReady then return end
    local buttons = bar.actionButtons or {}
    local count = GetNumShapeshiftForms and GetNumShapeshiftForms() or #buttons
    if not ns.Readable(count) or type(count) ~= "number" then return end
    count = ns.Clamp(math.floor(count), 0, #buttons)
    ns.stanceCount = count
    local size = ns.Clamp(math.floor(ns.db.buttonSize * 0.7 + 0.5), 24, 40)
    local triangle = ns.db.stanceShape == "triangles"
    local height = triangle and math.floor(size * math.sqrt(3) / 2 + 0.5) or size
    local pitch = triangle and (size / 2 + 2) or (size + 4)
    local width = size + math.max(0, count - 1) * pitch
    local metrics = {triangle = triangle, buttonWidth = size, buttonHeight = height, pitch = pitch}
    if not ns.stanceAnchor then
        ns.stanceAnchor = CreateFrame("Frame", nil, ns.root)
        ns.stanceAnchor:EnableMouse(false)
        ns.AddMover(ns.stanceAnchor, "StanceBar", "Stances / forms")
    end
    local anchor = ns.stanceAnchor
    ns.barAnchors[bar] = anchor
    anchor:SetSize(width, height + 18)
    local x, y = -ns.BarMetrics().width / 2 - width / 2 - 18, ns.ActionBottom()
    ns.Position(anchor, "StanceBar", "BOTTOM", x, y)
    ns.Reparent(bar, ns.root)
    ns.SetScale(bar, 1)
    ns.SetSize(bar, width, height + 18)
    ns.Position(bar, "StanceBar", "BOTTOM", x, y)
    bar.ccuiPanel = ns.Decorate(anchor, "ccuiPanel", 4)
    if bar.Background then bar.Background:SetAlpha(0) end
    if bar.BorderArt then bar.BorderArt:SetAlpha(0) end
    for index, button in ipairs(buttons) do
        ns.FixedScale(button)
        ns.SetSize(button, size, height)
        ns.ClearPoints(button)
        ns.SetPoint(button, "BOTTOMLEFT", anchor, "BOTTOMLEFT", (index - 1) * pitch, 14)
        ns.SkinActionButton(button, index, metrics)
        Highlight(button, triangle, index)
    end
    ns.Hook(bar, "Update", ns.QueueLayout)
    ns.Hook(bar, "UpdateGridLayout", ns.QueueLayout)
    ns.Hook(bar, "SetPoint", ns.QueueLayout)
    ns.RefreshStanceHighlights()
    ns.RefreshBarPanels()
end
