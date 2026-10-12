local _, ns = ...
local prefix = "ZeG UI"

local function PresetCount()
    return Enum.EditModePresetLayoutsMeta and Enum.EditModePresetLayoutsMeta.NumValues
        or Enum.EditModePresetLayouts and Enum.EditModePresetLayouts.NumValues or 3
end

local function FindLayout(info, identity)
    if not identity then return end
    if identity.preset then return identity.preset end
    for i, layout in ipairs(info.layouts) do
        if layout.layoutName == identity.name and layout.layoutType == identity.kind
            and layout.interfaceStyle == identity.style then return i + PresetCount() end
    end
end

local function Identity(layout, index)
    if index <= PresetCount() then return {preset = index} end
    return {name = layout.layoutName, kind = layout.layoutType, style = layout.interfaceStyle}
end

local function SourceLayout(info)
    local index = info.activeLayout - PresetCount()
    if index > 0 then return info.layouts[index] end
    -- This is a read-only lookup. Never change the manager's layoutInfo table.
    if EditModeManagerFrame and EditModeManagerFrame.GetActiveLayoutInfo then
        return EditModeManagerFrame:GetActiveLayoutInfo()
    end
end

local function ConfigureProfile(layout)
    local settings = Enum.EditModeActionBarSetting
    local bars = {}
    for _, name in ipairs(ns.barNames) do
        local bar = _G[name]
        if bar and bar.systemIndex then bars[bar.systemIndex] = true end
    end
    local changed = false
    local desired = {
        [settings.VisibleSetting] = Enum.ActionBarVisibleSetting.Always,
        [settings.AlwaysShowButtons] = 1,
        [settings.Orientation] = Enum.ActionBarOrientation.Horizontal,
        [settings.NumRows] = 1,
        [settings.NumIcons] = 12,
    }
    for _, system in ipairs(layout.systems or {}) do
        local wantedSettings
        if ns.db.modules.bars and system.system == Enum.EditModeSystem.ActionBar and bars[system.systemIndex] then
            wantedSettings = desired
        elseif ns.db.modules.menu and ns.db.menuDock and MicroMenuContainer
            and system.system == MicroMenuContainer.system and Enum.EditModeMicroMenuSetting and Enum.MicroMenuOrientation then
            wantedSettings = {[Enum.EditModeMicroMenuSetting.Orientation] = Enum.MicroMenuOrientation.Horizontal}
        elseif ns.db.modules.bags and ns.db.compactBags and BagsBar
            and system.system == BagsBar.system and Enum.EditModeBagsSetting and Enum.BagsOrientation and Enum.BagsDirection then
            wantedSettings = {[Enum.EditModeBagsSetting.Orientation] = Enum.BagsOrientation.Horizontal,
                [Enum.EditModeBagsSetting.Direction] = Enum.BagsDirection.Left}
        end
        if ns.ConfigurePresentationSystem then
            local presentation, anchorsChanged = ns.ConfigurePresentationSystem(system)
            if presentation then wantedSettings = presentation end
            if anchorsChanged then changed = true end
        end
        if wantedSettings then
            for _, setting in ipairs(system.settings or {}) do
                local wanted = wantedSettings[setting.setting]
                if wanted ~= nil and setting.value ~= wanted then
                    setting.value = wanted
                    changed = true
                end
            end
        end
    end
    for frame, anchor in pairs(ns.nativePositions) do
        for _, system in ipairs(layout.systems or {}) do
            if system.system == frame.system and system.systemIndex == frame.systemIndex then
                if system.isInDefaultPosition ~= false or system.anchorInfo2 ~= nil then
                    system.isInDefaultPosition, system.anchorInfo2 = false, nil
                    changed = true
                end
                local previous = system.anchorInfo or {}
                for key, value in pairs(anchor) do
                    if previous[key] ~= value then changed = true break end
                end
                system.anchorInfo = ns.Copy(anchor)
                break
            end
        end
    end
    return changed
end

local function ScheduleReload()
    if ns.nativeReloadScheduled then return end
    ns.nativeReloadScheduled = true
    local attempts = 0
    local function Check()
        if not ns.db.enabled or not ns.db.modules.bars then
            ns.nativeReloadScheduled = nil
            return
        end
        local current = {GetActionBarToggles()}
        local matched = true
        for i = 1, 7 do
            if current[i] ~= ns.nativeToggleRequest[i] then matched = false break end
        end
        attempts = attempts + 1
        if matched then
            ns.nativeReloadReady = true
            if not InCombatLockdown() and not ns.blizzardEditing then
                ns.Print("Bar settings saved. Reloading the interface.")
                ns.nativeReloadScheduled, ns.nativeReloadReady = nil, nil
                ReloadUI()
                return
            end
        elseif attempts >= 40 then
            ns.nativeReloadScheduled = nil
            ns.nativeBarWarning = "Bar settings are waiting for the server. Use /reload after they sync."
            ns.Print(ns.nativeBarWarning)
            return
        end
        C_Timer.After(0.25, Check)
    end
    C_Timer.After(0.25, Check)
end

function ns.PrepareNativeBars()
    ns.nativeBarsReady = false
    local modules = ns.db.modules
    if not (modules.bars or modules.xp or modules.bags or modules.menu or modules.minimap or modules.quests
        or ns.db.auras.enabled or ns.db.swing.enabled) then return end
    if InputUtil and InputUtil.IsGamepadUIEnabled and InputUtil.IsGamepadUIEnabled() then
        ns.nativeBarWarning = "Gamepad interface active; Blizzard manages its action bars."
        return
    end
    if not (C_EditMode and C_EditMode.GetLayouts and C_EditMode.SaveLayouts
        and C_EditMode.SetActiveLayout and C_EditMode.OnLayoutAdded
        and GetActionBarToggles and SetActionBarToggles and Enum
        and Enum.EditModeActionBarSetting and Enum.EditModeSystem
        and Enum.ActionBarVisibleSetting and Enum.ActionBarOrientation) then
        ns.nativeBarWarning = "Native bar configuration is unavailable; Blizzard bar visibility is retained."
        return
    end
    local info = C_EditMode.GetLayouts()
    if not (info and type(info.layouts) == "table" and type(info.activeLayout) == "number") then return end
    local source = info and SourceLayout(info)
    if not (source and source.systems) then return end -- native startup not finished
    ns.db.nativeBars = ns.db.nativeBars or {}
    local saved = ns.db.nativeBars
    if not saved.original then saved.original = Identity(source, info.activeLayout) end
    local index = FindLayout(info, saved.profile)
    if not index then
        local character = Enum.EditModeLayoutType.Character
        local count, used = 0, {}
        for _, layout in ipairs(info.layouts) do
            used[layout.layoutName] = true
            if layout.layoutType == character then count = count + 1 end
        end
        local limit = Constants and Constants.EditModeConsts and Constants.EditModeConsts.EditModeMaxLayoutsPerType or 5
        if count >= limit then
            ns.nativeBarWarning = "A character Edit Mode layout slot is needed for ZeG UI."
            if not ns.nativeCapacityReported then ns.Print(ns.nativeBarWarning) ns.nativeCapacityReported = true end
            return
        end
        local name, suffix = prefix, 1
        while used[name] do suffix = suffix + 1 name = prefix .. " " .. suffix end
        local layout = {layoutName = name, layoutType = character,
            interfaceStyle = source.interfaceStyle, systems = ns.Copy(source.systems)}
        ConfigureProfile(layout)
        -- C_EditMode consumes a private data copy and notifies Blizzard through
        -- its native event. Addon code never edits live frame/manager settings.
        info = ns.Copy(info)
        info.layouts[#info.layouts + 1] = layout
        index = #info.layouts + PresetCount()
        C_EditMode.SaveLayouts(info)
        C_EditMode.OnLayoutAdded(index, true, false)
        saved.profile = Identity(layout, index)
    else
        local layout = info.layouts[index - PresetCount()]
        if ConfigureProfile(layout) then C_EditMode.SaveLayouts(info) end
        if info.activeLayout ~= index then C_EditMode.SetActiveLayout(index) end
    end
    if not modules.bars then return end
    local current = {GetActionBarToggles()}
    local wanted, changed, newRequest = {}, false, not ns.nativeToggleRequest
    for i = 1, 7 do
        local key = "PROXY_SHOW_ACTIONBAR_" .. (i + 1)
        if ns.db.backup[key] == nil then ns.db.backup[key] = current[i] end
        wanted[i] = i + 1 <= ns.db.rows
        if current[i] ~= wanted[i] then changed = true end
        if ns.nativeToggleRequest and ns.nativeToggleRequest[i] ~= wanted[i] then newRequest = true end
    end
    if changed and newRequest then
        -- One bulk C call avoids the native proxy-setting cache and updater.
        SetActionBarToggles(unpack(wanted))
        ns.nativeToggleRequest = wanted
        ns.nativeBarWarning = "Bar count saved; the interface reloads once native settings sync."
        ScheduleReload()
    elseif not changed then
        ns.nativeBarWarning = nil
        ns.nativeToggleRequest = wanted
    end
    ns.nativeBarsReady = true
end

function ns.SyncNativePositions()
    if not (C_EditMode and C_EditMode.GetLayouts and C_EditMode.SaveLayouts) then return false end
    local saved = ns.db.nativeBars
    if not (saved and saved.profile) then return false end
    local info = C_EditMode.GetLayouts()
    if not info then return false end
    local index = FindLayout(info, saved.profile)
    if not index or index ~= info.activeLayout then return false end
    local layout = info.layouts[index - PresetCount()]
    if not layout or not ConfigureProfile(layout) then return false end
    C_EditMode.SaveLayouts(info)
    return true
end

function ns.RestoreNativeBars()
    if GetActionBarToggles and SetActionBarToggles then
        local values = {GetActionBarToggles()}
        for i = 1, 7 do
            local value = ns.db.backup["PROXY_SHOW_ACTIONBAR_" .. (i + 1)]
            if value ~= nil then values[i] = value end
        end
        SetActionBarToggles(unpack(values))
    end
    if C_EditMode and C_EditMode.GetLayouts and C_EditMode.SetActiveLayout then
        local saved = ns.db.nativeBars
        local info = C_EditMode.GetLayouts()
        if not info then return end
        local original = saved and FindLayout(info, saved.original)
        if original and info.activeLayout == FindLayout(info, saved.profile) then C_EditMode.SetActiveLayout(original) end
    end
end
