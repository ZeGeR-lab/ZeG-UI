local _, ns = ...
local media = "Interface\\AddOns\\CleanCenterUI\\Media\\"
ns.buttonShapes = {}

local function RememberFlag(widget, method)
    if widget[method] then
        local value = widget[method](widget)
        if ns.Readable(value) then return value end
    end
    return true
end

local function MaskRegion(state, region)
    if region and region.AddMaskTexture and not state.masked[region] then
        local parent = region:GetParent()
        local mask = state.mask
        if parent ~= state.button and parent and parent.CreateMaskTexture then
            mask = state.childMasks[parent]
            if not mask then
                mask = parent:CreateMaskTexture(nil, "ARTWORK")
                mask:SetAllPoints(state.button)
                state.childMasks[parent] = mask
            end
            mask:SetTexture(state.fillTexture, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        end
        region:AddMaskTexture(mask)
        state.masked[region] = mask
    end
end

local function MaskAnimationTree(state, frame, depth)
    if not frame or frame == state.panel or (frame.IsForbidden and frame:IsForbidden()) then return end
    -- Native casts use nested Fill/EndBurst/interrupt frames, separate from the
    -- cooldown widget. Clip their textures while preserving native timing/scripts.
    if frame.GetRegions then
        for _, region in ipairs({frame:GetRegions()}) do
            if region.GetObjectType and region:GetObjectType() == "Texture" then MaskRegion(state, region) end
        end
    end
    if depth > 0 and frame.GetChildren then
        for _, child in ipairs({frame:GetChildren()}) do MaskAnimationTree(state, child, depth - 1) end
    end
end

function ns.ShapeButton(button, icon, index, metrics)
    local state = ns.buttonShapes[button]
    if not metrics.triangle then
        if not state or not state.active then return end
        for region, mask in pairs(state.masked) do region:RemoveMaskTexture(mask) end
        state.masked = {}
        state.panel:Hide()
        state.border:Hide()
        button.ccuiBackground:Show()
        ns.NativeCall(button.SetHitRectInsets, button, unpack(state.hitInsets))
        for cooldown, original in pairs(state.cooldowns) do
            cooldown:SetSwipeTexture(ns.WHITE, 0, 0, 0, 0.72)
            if cooldown.SetDrawEdge then cooldown:SetDrawEdge(original.edge) end
            if cooldown.SetDrawBling then cooldown:SetDrawBling(original.bling) end
        end
        if button.Count then
            button.Count:ClearAllPoints()
            for _, point in ipairs(state.countPoints) do button.Count:SetPoint(unpack(point)) end
        end
        state.active = false
        return
    end

    if not state then
        state = {button = button, childMasks = {}, masked = {}, cooldowns = {}, countPoints = {}, hitInsets = {0, 0, 0, 0}}
        if button.GetHitRectInsets then
            local insets = {button:GetHitRectInsets()}
            for i = 1, 4 do if ns.Readable(insets[i]) and type(insets[i]) == "number" then state.hitInsets[i] = insets[i] end end
        end
        if button.Count then
            for i = 1, button.Count:GetNumPoints() do state.countPoints[i] = {button.Count:GetPoint(i)} end
        end
        state.mask = button:CreateMaskTexture(nil, "ARTWORK")
        state.mask:SetAllPoints(button)
        state.panel = CreateFrame("Frame", nil, button)
        state.panel.ignoreInLayout = true
        state.panel:SetAllPoints(button)
        state.panel:SetFrameLevel(math.max(0, button:GetFrameLevel() - 1))
        state.panel:SetFrameStrata("BACKGROUND")
        state.panel:EnableMouse(false)
        state.fill = state.panel:CreateTexture(nil, "BACKGROUND")
        state.fill:SetAllPoints(state.panel)
        state.border = button:CreateTexture(nil, "OVERLAY", nil, 7)
        state.border:SetAllPoints(button)
        ns.buttonShapes[button] = state
    end
    local direction = index % 2 == 1 and "Up" or "Down"
    local fill = media .. "Triangle" .. direction .. ".tga"
    state.fillTexture = fill
    for _, mask in pairs(state.childMasks) do mask:SetTexture(fill, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE") end
    state.mask:SetTexture(fill, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    state.fill:SetTexture(fill)
    local palette = ns.db.colors
    local c = palette.panel
    state.fill:SetVertexColor(c[1], c[2], c[3], c[4] * ns.db.opacity)
    state.border:SetTexture(media .. "Triangle" .. direction .. "Border.tga")
    c = palette.border
    state.border:SetVertexColor(c[1], c[2], c[3], ns.db.borders and c[4] or 0)
    state.panel:Show()
    state.border:Show()
    button.ccuiBackground:Hide()
    MaskRegion(state, icon)
    -- Clip native hover, press, checked, and flash art without changing its
    -- texture, event handler, visibility, action slot, or animation state.
    for _, field in ipairs({"HighlightTexture", "PushedTexture", "CheckedTexture",
        "Flash", "SpellHighlightTexture", "NewActionTexture"}) do
        MaskRegion(state, button[field])
    end
    for _, field in ipairs({"cooldown", "chargeCooldown", "lossOfControlCooldown"}) do
        local cooldown = button[field] or (field == "cooldown" and button.Cooldown)
        if cooldown then
            if not state.cooldowns[cooldown] then
                state.cooldowns[cooldown] = {edge = RememberFlag(cooldown, "GetDrawEdge"),
                    bling = RememberFlag(cooldown, "GetDrawBling")}
            end
            cooldown:SetSwipeTexture(fill, 0, 0, 0, 0.72)
            -- Native radial edges and completion flares extend outside the shape.
            -- Countdown numbers and native cooldown timing remain enabled.
            if cooldown.SetDrawEdge then cooldown:SetDrawEdge(false) end
            if cooldown.SetDrawBling then cooldown:SetDrawBling(false) end
        end
    end
    for _, child in ipairs({button:GetChildren()}) do MaskAnimationTree(state, child, 4) end
    -- WoW buttons have rectangular hit regions. Give each overlapping frame
    -- a disjoint center column, leaving a one-pixel gap between click regions.
    -- Secure native buttons still receive clicks and item/spell drag operations.
    local inset = (metrics.buttonWidth - metrics.pitch) / 2 + 0.5
    ns.NativeCall(button.SetHitRectInsets, button, math.max(0, inset), math.max(0, inset), 0, 0)
    if button.Count then
        button.Count:ClearAllPoints()
        local edge = direction == "Up" and "BOTTOM" or "TOP"
        button.Count:SetPoint(edge, button, edge, 0, direction == "Up" and 2 or -2)
        ns.StyleFont(button.Count, "keybinds", 10)
    end
    state.active = true
end
