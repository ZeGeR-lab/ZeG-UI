local _, ns = ...
-- Cosmetic adapter only: no aura/cooldown queries, spell-state reads, native
-- refresh hooks, script replacement, reparenting, or addon fields on native frames.
ns.trackerGroups = {
    {key = "essential", name = "EssentialCooldownViewer", label = "Essential"},
    {key = "utility", name = "UtilityCooldownViewer", label = "Utility"},
    {key = "buffs", name = "BuffIconCooldownViewer", label = "Buff icons"},
    {key = "bars", name = "BuffBarCooldownViewer", label = "Buff bars"},
}
local groups, decorations, fonts, artwork = {}, {}, {}, {}
local itemOrdinal = 0
local shaped, fills, countdowns, maskCache = {}, {}, {}, {}
local opacityItems = {}
function ns.TrackerCountdownVisibilitySupported()
    return UIParent and UIParent.SetAlphaFromBoolean ~= nil
end
local function RestoreItemGeometry(frame, record)
    if not record.compacted then return true end
    if InCombatLockdown() then ns.pending = true return false end
    ns.ClearPoints(frame)
    for _, point in ipairs(record.points) do ns.SetPoint(frame, unpack(point)) end
    record.compacted = nil
    return true
end
local function RestoreItemOpacity(frame)
    local record = opacityItems[frame]
    if record then
        if frame and (not frame.IsForbidden or not frame:IsForbidden()) then frame:SetAlpha(record.alpha) end
        if RestoreItemGeometry(frame, record) then opacityItems[frame] = nil end
    end
end
function ns.UpdateTrackerVisibility()
    for frame, record in pairs(opacityItems) do
        if ns.db and ns.db.enabled and ns.db.trackers.enabled and ns.db.trackers.groups[record.key]
            and (not frame.IsForbidden or not frame:IsForbidden()) then
            local mode = ns.db.trackers.styles[record.key].visibility
            if mode ~= "always" and not ns.unlocked and not ns.blizzardEditing then
                -- Forward an opaque engine display boolean directly to the C++
                -- alpha setter. Never compare timers, spell states or secrets.
                frame:SetAlphaFromBoolean(record.cooldown:IsShown(), mode == "hideCountdown" and 0 or 0.2, record.alpha)
            else frame:SetAlpha(record.alpha) end
        else RestoreItemOpacity(frame) end
    end
    if ns.CompactTrackerLayout then ns.CompactTrackerLayout() end
end
local function ConfigureItemOpacity(frame, style, key)
    if style.visibility == "always" or key == "buffs" or key == "bars" then RestoreItemOpacity(frame) return end
    if not frame.SetAlphaFromBoolean or not frame.Cooldown or not frame.Cooldown.IsShown then return end
    local record = opacityItems[frame]
    if not record then
        record = {alpha = frame:GetAlpha(), cooldown = frame.Cooldown, key = key, points = {}}
        for i = 1, frame:GetNumPoints() do record.points[i] = {frame:GetPoint(i)} end
        for _, group in ipairs(ns.trackerGroups) do if group.key == key then record.owner = _G[group.name] end end
        local x, y = frame:GetCenter()
        local owner = record.owner
        if owner then
            local ox, oy = owner:GetCenter()
            local fs, os = frame:GetEffectiveScale(), owner:GetEffectiveScale()
            if ns.Finite(x) and ns.Finite(y) and ns.Finite(ox) and ns.Finite(oy)
                and ns.Finite(fs) and ns.Finite(os) and os > 0 then
                record.x, record.y = x * fs / os - ox, y * fs / os - oy
            end
        end
        opacityItems[frame] = record
    end
end
function ns.CompactTrackerLayout()
    if not ns.db or InCombatLockdown() or ns.blizzardEditing then return end
    for _, group in ipairs(ns.trackerGroups) do
        local style = ns.db.trackers.styles[group.key]
        local compact = ns.db.enabled and ns.db.trackers.enabled and ns.db.trackers.groups[group.key]
            and style.arrangement == "native" and style.visibility == "hideCountdown" and style.layout == "compactOutOfCombat" and not ns.unlocked
        local slots, readable = {}, true
        for frame, record in pairs(opacityItems) do
            if record.key == group.key then
                if compact then
                    local counting = record.cooldown:IsShown()
                    if not ns.Readable(counting) or not ns.Finite(record.x) or not ns.Finite(record.y) then readable = false
                    else slots[#slots+1] = {frame = frame, record = record, counting = counting} end
                else RestoreItemGeometry(frame, record) end
            end
        end
        if compact and readable then
            table.sort(slots, function(a, b)
                local ay, by = math.floor(a.record.y + 0.5), math.floor(b.record.y + 0.5)
                if ay ~= by then return ay > by end
                return a.record.x < b.record.x
            end)
            local nextSlot = 1
            for _, slot in ipairs(slots) do
                if not slot.counting then
                    local target = slots[nextSlot].record
                    ns.ClearPoints(slot.frame)
                    ns.SetPoint(slot.frame, "CENTER", slot.record.owner, "CENTER", target.x, target.y)
                    slot.record.compacted = true
                    nextSlot = nextSlot + 1
                else RestoreItemGeometry(slot.frame, slot.record) end
            end
        elseif compact then
            -- Do not retain stale compaction when readable state disappears.
            for frame, record in pairs(opacityItems) do
                if record.key == group.key then RestoreItemGeometry(frame, record) end
            end
        end
    end
end
local media = "Interface\\AddOns\\CleanCenterUI\\Media\\"
local function ShapeTexture(texture, anchor, shape)
    if not texture or not texture.AddMaskTexture or not texture.GetParent then return end
    local record = shaped[texture]
    if not record then
        local parent = texture:GetParent()
        if not parent or not parent.CreateMaskTexture then return end
        record = {native = {}, coords = texture.GetTexCoord and {texture:GetTexCoord()} or nil}
        if texture.GetNumMaskTextures and texture.GetMaskTexture then
            local count = texture:GetNumMaskTextures()
            if ns.Finite(count) then
                for i = 1, count do record.native[#record.native+1] = texture:GetMaskTexture(i) end
            end
        end
        record.mask = maskCache[texture]
        if not record.mask then
            record.mask = parent:CreateMaskTexture(nil, "ARTWORK") maskCache[texture] = record.mask
        end
        record.mask:SetAllPoints(anchor)
        shaped[texture] = record
        for _, mask in ipairs(record.native) do texture:RemoveMaskTexture(mask) end
        texture:AddMaskTexture(record.mask)
    end
    record.mask:SetTexture(shape == "round" and media .. "CircleMask.tga" or shape == "octagons" and media .. "Octagon.tga" or ns.WHITE, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
end
local function FlatFill(bar, style)
    if not bar or not bar.GetStatusBarTexture then return end
    local texture = bar:GetStatusBarTexture()
    if not texture or not texture.GetTexture or not texture.GetVertexColor then return end
    if not fills[texture] then
        local atlas = texture.GetAtlas and texture:GetAtlas()
        fills[texture] = {texture = texture:GetTexture(), atlas = ns.Readable(atlas) and atlas or nil,
            color = {texture:GetVertexColor()}, coords = {texture:GetTexCoord()}}
    end
    texture:SetTexture(ns.WHITE) texture:SetTexCoord(0, 1, 0, 1)
    if style.skin == "minimal" then texture:SetVertexColor(unpack(fills[texture].color))
    else texture:SetVertexColor(unpack(ns.db.colors.accent)) end
end

local function Usable(frame)
    return frame and (not frame.IsForbidden or not frame:IsForbidden())
end
local function Enabled()
    return C_CVar and C_CVar.GetCVarBool and C_CVar.GetCVarBool("cooldownViewerEnabled")
end
local function Available()
    if C_CooldownViewer and C_CooldownViewer.IsCooldownViewerAvailable then
        return C_CooldownViewer.IsCooldownViewerAvailable()
    end
    for _, group in ipairs(ns.trackerGroups) do if Usable(_G[group.name]) then return true end end
    return false
end
function ns.TrackerStatus()
    if not Available() then return "Blizzard Cooldown Manager is unavailable on this client/character." end
    local count = 0
    for _, group in ipairs(ns.trackerGroups) do if Usable(_G[group.name]) then count = count + 1 end end
    return (Enabled() and "Blizzard tracking enabled" or "Blizzard tracking disabled") .. " | " .. count .. "/4 groups available"
end
function ns.EnableBlizzardTrackers()
    if InCombatLockdown() or ns.blizzardEditing then ns.Print("Enable tracking outside combat and Edit Mode.") return end
    if not Available() then ns.Print(ns.TrackerStatus()) return end
    if not C_CVar or not C_CVar.SetCVar then ns.Print("Enable Cooldown Manager in WoW's Options.") return end
    C_CVar.SetCVar("cooldownViewerEnabled", "1")
    if C_AddOns and C_AddOns.LoadAddOn then C_AddOns.LoadAddOn("Blizzard_CooldownViewer") end
    ns.QueueLayout()
end
function ns.OpenBlizzardTrackers()
    if InCombatLockdown() then ns.Print("Open Blizzard's tracker settings outside combat.") return end
    -- Leave native layout mutations to the built-in editor, opened by the player.
    if CooldownViewerSettings and CooldownViewerSettings.Show then CooldownViewerSettings:Show()
    else ns.Print("Open WoW Options, search for Cooldown Manager, then choose its settings.") end
end
local function Borders(parent)
    local edges = {}
    for i, pair in ipairs({{"TOPLEFT", "TOPRIGHT"}, {"BOTTOMLEFT", "BOTTOMRIGHT"},
        {"TOPLEFT", "BOTTOMLEFT"}, {"TOPRIGHT", "BOTTOMRIGHT"}}) do
        local edge = parent:CreateTexture(nil, "OVERLAY", nil, 7)
        edge:SetPoint(pair[1]) edge:SetPoint(pair[2])
        if i <= 2 then edge:SetHeight(1) else edge:SetWidth(1) end
        edges[i] = edge
    end
    return edges
end
local function Font(font, style)
    if not Usable(font) or not font.GetFont then return end
    if not fonts[font] then fonts[font] = {font = {font:GetFont()}, color = {font:GetTextColor()}} end
    font:SetFont(ns.fontFaces[ns.db.fontFace] or ns.FONT, style.fontSize > 0 and style.fontSize or ns.db.trackers.fontSize, "OUTLINE")
    font:SetTextColor(unpack(ns.db.colors.text))
end
local function QuietOverlay(region)
    if not Usable(region) or not region.GetAtlas then return end
    local atlas = region:GetAtlas()
    -- Cosmetic atlas names only; preserve proc glows, range warnings, debuff borders,
    -- icons, cooldown swipes, masks, stacks and all native visibility decisions.
    if ns.Readable(atlas) and (atlas == "UI-HUD-CoolDownManager-IconOverlay" or atlas == "UI-HUD-CoolDownManager-Bar-BG") then
        if not artwork[region] then artwork[region] = {alpha = region:GetAlpha()} end
        region:SetAlpha(0)
    end
end
local function SkinTree(frame, depth, owner, style, key)
    if not Usable(frame) then return end
    if frame.GetRegions then
        for _, region in ipairs({frame:GetRegions()}) do
            if region.GetObjectType and region:GetObjectType() == "FontString" then Font(region, style)
            else QuietOverlay(region) end
        end
    end
    if frame.Icon and (frame.Cooldown or frame.Bar) then
        local record = decorations[frame]
        if not record then
            itemOrdinal = itemOrdinal + 1
            record = {frame = frame, edges = Borders(frame), owner = owner, ordinal = itemOrdinal, points = {}}
            for i = 1, frame:GetNumPoints() do record.points[i] = {frame:GetPoint(i)} end
            record.ring = frame:CreateTexture(nil, "OVERLAY", nil, 7)
            local anchor = frame.Bar and frame.Icon or frame
            record.ring:SetAllPoints(anchor) record.ring:SetTexture(media .. "CircleBorder.tga")
            record.tile = frame:CreateTexture(nil, "BACKGROUND", nil, -1) record.tile:SetAllPoints(frame)
            decorations[frame] = record
        end
        local round, c = style.skin == "round" or style.skin == "octagons", ns.db.colors.border
        record.ring:SetTexture(media .. (style.skin == "octagons" and "OctagonBorder.tga" or "CircleBorder.tga"))
        local bordered = ns.db.borders and style.skin ~= "minimal"
        for _, edge in ipairs(record.edges) do
            edge:SetColorTexture(c[1], c[2], c[3], bordered and c[4] or 0)
            edge:SetShown(not round or frame.Bar ~= nil)
        end
        record.ring:SetVertexColor(c[1], c[2], c[3], bordered and c[4] or 0)
        record.ring:SetShown(round)
        record.tile:SetColorTexture(unpack(ns.db.colors.barBackground))
        record.tile:SetShown(style.skin == "tiles")
        local icon = frame.Icon.Icon or frame.Icon
        local anchor = frame.Bar and frame.Icon or frame
        ShapeTexture(icon, anchor, style.skin)
        if frame.Cooldown then
            local cooldown = frame.Cooldown
            if cooldown.GetSwipeTexture then
                local swipe = cooldown:GetSwipeTexture()
                if type(swipe) ~= "string" then ShapeTexture(swipe, anchor, style.skin) end
            end
            if cooldown.GetHideCountdownNumbers and cooldown.SetHideCountdownNumbers then
                local hidden = cooldown:GetHideCountdownNumbers()
                if ns.Readable(hidden) then
                    countdowns[cooldown] = hidden
                    cooldown:SetHideCountdownNumbers(not style.timers)
                end
            end
        end
        FlatFill(frame.Bar, style)
        ConfigureItemOpacity(frame, style, key)
    end
    if depth > 0 and frame.GetChildren then
        for _, child in ipairs({frame:GetChildren()}) do SkinTree(child, depth - 1, owner, style, key) end
    end
end
local function NativePoints(frame)
    local result = {}
    for i = 1, frame:GetNumPoints() do result[i] = {frame:GetPoint(i)} end
    return result
end
local function RestoreGroup(frame, record)
    record.panel:Hide()
    if record.arranged then ns.SetSize(frame, record.width, record.height) record.arranged = nil end
    if record.scaled then ns.SetScale(frame, record.scale) record.scaled = nil end
    if record.moved then
        ns.ClearPoints(frame)
        for _, point in ipairs(record.points) do ns.SetPoint(frame, unpack(point)) end
        record.moved = nil
    end
end
local function RestoreCosmetics()
    for _, record in pairs(decorations) do
        for _, edge in ipairs(record.edges) do edge:Hide() end
        record.ring:Hide() record.tile:Hide()
        if record.arranged then
            ns.ClearPoints(record.frame)
            for _, point in ipairs(record.points) do ns.SetPoint(record.frame, unpack(point)) end
            record.arranged = nil
        end
    end
    for texture, record in pairs(shaped) do
        if Usable(texture) then
            texture:RemoveMaskTexture(record.mask)
            for _, mask in ipairs(record.native) do texture:AddMaskTexture(mask) end
            if record.coords then texture:SetTexCoord(unpack(record.coords)) end
        end
    end
    for texture, record in pairs(fills) do
        if Usable(texture) then
            if record.atlas and texture.SetAtlas then texture:SetAtlas(record.atlas) else texture:SetTexture(record.texture) end
            texture:SetTexCoord(unpack(record.coords)) texture:SetVertexColor(unpack(record.color))
        end
    end
    for cooldown, hidden in pairs(countdowns) do
        if Usable(cooldown) then cooldown:SetHideCountdownNumbers(hidden) end
    end
    shaped, fills, countdowns = {}, {}, {}
    for font, record in pairs(fonts) do
        if Usable(font) then font:SetFont(unpack(record.font)) font:SetTextColor(unpack(record.color)) end
    end
    for region, record in pairs(artwork) do if Usable(region) then region:SetAlpha(record.alpha) end end
    fonts, artwork = {}, {}
end
function ns.RestoreTrackers()
    if InCombatLockdown() then return end
    RestoreCosmetics()
    for frame in pairs(opacityItems) do RestoreItemOpacity(frame) end
    for frame, record in pairs(groups) do if Usable(frame) then RestoreGroup(frame, record) end end
end
function ns.TrackerMoverVisible(key)
    if not ns.db or not ns.db.trackers.enabled or not Enabled() then return false end
    for _, group in ipairs(ns.trackerGroups) do
        if key == "tracker" .. group.key then return ns.db.trackers.groups[group.key] and Usable(_G[group.name]) end
    end
    return false
end
local function ArrangeTracker(viewer, style, groupRecord)
    if style.arrangement == "native" then return end
    local items, maxWidth, maxHeight = {}, 0, 0
    for frame, record in pairs(decorations) do
        if record.owner == viewer then
            local shown = frame:IsShown()
            if not ns.Readable(shown) then return end
            if shown then
                local width, height = frame:GetWidth(), frame:GetHeight()
                if not ns.Finite(width) or not ns.Finite(height) or width <= 0 or height <= 0 then return end
                maxWidth, maxHeight = math.max(maxWidth,width), math.max(maxHeight,height)
                items[#items+1] = {frame=frame, record=record}
            end
        end
    end
    if #items == 0 then return end
    table.sort(items, function(a,b) return a.record.ordinal < b.record.ordinal end)
    local spacing, count = 6, #items
    local columns = style.arrangement == "vertical" and 1 or style.arrangement == "cluster" and math.min(4,count) or count
    local rows = math.ceil(count / columns)
    local width, height = columns*(maxWidth+spacing)-spacing+8, rows*(maxHeight+spacing)-spacing+8
    local radius
    if style.arrangement == "radial" and count > 1 then
        radius = (math.max(maxWidth,maxHeight)+spacing)*math.sqrt(2)/(2*math.sin(math.pi/count))
        width, height = 2*radius+maxWidth+8, 2*radius+maxHeight+8
    end
    ns.SetSize(viewer,width,height) groupRecord.arranged = true
    for i,item in ipairs(items) do
        local x,y = 4+((i-1)%columns)*(maxWidth+spacing), 4+math.floor((i-1)/columns)*(maxHeight+spacing)
        if radius then
            local angle = math.pi/2-(i-1)*2*math.pi/count
            x,y = 4+radius+radius*math.cos(angle), 4+radius+radius*math.sin(angle)
        end
        ns.ClearPoints(item.frame) ns.SetPoint(item.frame,"BOTTOMLEFT",viewer,"BOTTOMLEFT",x,y)
        item.record.arranged = true
    end
end
function ns.ApplyTrackers()
    if not ns.db or InCombatLockdown() or ns.blizzardEditing then return end
    if not ns.db.enabled or not ns.db.trackers.enabled then ns.RestoreTrackers() return end
    if ns.db.trackers.autoEnable and Available() and not Enabled() then ns.EnableBlizzardTrackers() end
    RestoreCosmetics()
    for frame, record in pairs(groups) do
        if record.arranged then ns.SetSize(frame, record.width, record.height) record.arranged = nil end
    end
    for _, group in ipairs(ns.trackerGroups) do
        local frame, key = _G[group.name], "tracker" .. group.key
        if Usable(frame) then
            local record = groups[frame]
            if ns.db.trackers.groups[group.key] and Enabled() then
                if not record then
                    local panel = CreateFrame("Frame", nil, frame)
                    panel:SetAllPoints(frame) panel:EnableMouse(false)
                    local level = frame:GetFrameLevel()
                    if ns.Finite(level) then panel:SetFrameLevel(math.max(0, level - 1)) end
                    ns.Panel(panel, ns.db.opacity)
                    record = {panel = panel, points = NativePoints(frame), scale = frame:GetScale(), width = frame:GetWidth(), height = frame:GetHeight()} groups[frame] = record
                    ns.AddMover(frame, key, "Tracker: " .. group.label)
                end
                local style = ns.db.trackers.styles[group.key]
                local saved = ns.db.positions[key]
                if saved then
                    ns.ClearPoints(frame) ns.SetPoint(frame, "CENTER", ns.root, "CENTER", saved.x, saved.y)
                    record.moved = true
                elseif record.moved then RestoreGroup(frame, record) end
                if ns.Finite(record.scale) then
                    ns.SetScale(frame, record.scale * style.scale)
                    record.scaled = style.scale ~= 1
                end
                local opacity = style.opacity >= 0 and style.opacity or ns.db.opacity
                ns.Panel(record.panel, opacity)
                record.panel:SetShown(ns.db.trackers.container and style.background and style.visibility == "always")
                SkinTree(frame, 4, frame, style, group.key)
                if ns.Finite(record.width) and ns.Finite(record.height) then ArrangeTracker(frame,style,record) end
            elseif record then RestoreGroup(frame, record) end
        end
    end
    ns.UpdateTrackerVisibility()
end
-- Discover newly allocated cosmetic widgets outside combat without hooking
-- Blizzard's secure tracking callbacks. Native timers keep running independently.
local poll, elapsed = CreateFrame("Frame"), 0
poll:SetScript("OnUpdate", function(_, dt)
    elapsed = elapsed + dt
    if elapsed < 1 then return end
    elapsed = 0
    if not ns.db or ns.unsupported or not ns.db.enabled or not ns.db.trackers.enabled
        or InCombatLockdown() or ns.blizzardEditing or ns.unlocked then return end
    local function HasNewWidget(frame, depth)
        if not Usable(frame) then return false end
        if frame.Icon and (frame.Cooldown or frame.Bar) and not decorations[frame] then return true end
        if depth > 0 and frame.GetChildren then
            for _, child in ipairs({frame:GetChildren()}) do if HasNewWidget(child, depth-1) then return true end end
        end
        return false
    end
    for _, group in ipairs(ns.trackerGroups) do
        local frame = _G[group.name]
        if ns.db.trackers.groups[group.key] and Usable(frame) and (not groups[frame] or HasNewWidget(frame, 4)) then
            ns.QueueLayout() return
        end
    end
end)

-- Visibility-only updates may run in combat. No protected layout changes,
-- native callbacks, spell queries, or visibility-state branching are involved.
local visibilityPoll, visibilityElapsed = CreateFrame("Frame"), 0
ns.trackerVisibilityPoll = visibilityPoll
visibilityPoll:SetScript("OnUpdate", function(_, dt)
    visibilityElapsed = visibilityElapsed + dt
    if visibilityElapsed < 0.1 then return end
    visibilityElapsed = 0
    ns.UpdateTrackerVisibility()
end)
