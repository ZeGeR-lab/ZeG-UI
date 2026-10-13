local _, ns = ...
-- Shared slider for addon-owned menus. Native UI layout remains deferred by
-- QueueLayout while in combat; slider interaction only saves preferences.
function ns.SettingSlider(parent, x, y, width, lo, hi, step, get, set, changed, title)
    local slider = CreateFrame("Slider", nil, parent)
    slider:SetSize(width, 18) slider:SetPoint("TOPLEFT", x, y - 24)
    slider:SetOrientation("HORIZONTAL") slider:SetMinMaxValues(lo, hi) slider:SetValueStep(step)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("LEFT", 0, 0) track:SetPoint("RIGHT", 0, 0) track:SetHeight(4)
    track:SetColorTexture(unpack(ns.db.colors.border))
    local thumb = slider:CreateTexture(nil, "OVERLAY") thumb:SetSize(12, 18)
    thumb:SetColorTexture(unpack(ns.db.colors.accent)) slider:SetThumbTexture(thumb)
    local label = ns.Font(parent, 12) label:SetPoint("TOPLEFT", x, y) label:SetWidth(width)
    slider.valueLabel = label
    local refreshing = false
    function slider:RefreshValue()
        refreshing = true self:SetValue(get()) refreshing = false
        label:SetText((title or "Scale") .. ": " .. math.floor(get() * 100 + 0.5) .. "%")
        track:SetColorTexture(unpack(ns.db.colors.border)) thumb:SetColorTexture(unpack(ns.db.colors.accent))
    end
    slider:SetScript("OnValueChanged", function(_, value)
        if refreshing or not ns.Finite(value) then return end
        value = ns.Clamp(math.floor(value / step + 0.5) * step, lo, hi)
        set(value)
        label:SetText((title or "Scale") .. ": " .. math.floor(value * 100 + 0.5) .. "%")
        if changed then changed() end
    end)
    slider:RefreshValue()
    return slider
end

ns.lockControls = {}
function ns.FrameLockButton(parent, x, y, width)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width or 140, 28) button:SetPoint("TOPLEFT", x, y)
    ns.Panel(button, 1)
    button.label = ns.Font(button, 12, "CENTER") button.label:SetPoint("CENTER")
    button:SetScript("OnClick", function() ns.Unlock(not ns.unlocked) ns.RefreshLockControls() end)
    ns.lockControls[#ns.lockControls+1] = button
    ns.RefreshLockControls()
    return button
end
function ns.RefreshLockControls()
    for _, button in ipairs(ns.lockControls) do
        button.label:SetText(ns.unlocked and "Lock frames" or "Unlock frames")
        ns.ThemeButton(button, ns.unlocked)
    end
end
