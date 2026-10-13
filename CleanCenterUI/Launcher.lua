local _, ns = ...
-- Independent launcher remains available when the UI preset is disabled.
function ns.CreateLauncher()
    if ns.launcher or not Minimap then return end
    local button = CreateFrame("Button", "ZeGUIMinimapButton", UIParent)
    ns.launcher = button
    button:SetSize(20, 20)
    button:SetScale(0.8)
    button:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -4, -4)
    button:SetFrameStrata("HIGH")
    button:SetFrameLevel(30)
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetClampedToScreen(true)
    if button.SetIgnoreParentScale then button:SetIgnoreParentScale(true) end
    ns.Panel(button, 1)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 2, -2) icon:SetPoint("BOTTOMRIGHT", -2, 2)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Gear_01")
    icon:SetVertexColor(0.35, 0.8, 0.95, 1)

    button:SetScript("OnClick", function(_, mouse)
        if mouse == "RightButton" then ns.OpenCustomize("trackers") else ns.OpenCustomize("general") end
    end)
    button:SetScript("OnEnter", function(self)
        ns.SetBorderColor(self, unpack(ns.db.colors.accent))
        if GameTooltip and GameTooltip.SetOwner and GameTooltip.AddLine then
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:AddLine("ZeG UI")
            GameTooltip:AddLine("Left-click: Settings", 1, 1, 1)
            GameTooltip:AddLine("Right-click: Trackers", 1, 1, 1)
            GameTooltip:AddLine("Command: /zeg", 1, 1, 1)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function(self)
        ns.SetBorderColor(self, unpack(ns.db.colors.border))
        if GameTooltip then GameTooltip:Hide() end
    end)
    button:Show()
end

function ns.RefreshLauncher()
    if InCombatLockdown() then return end
    if not ns.launcher then ns.CreateLauncher() end
    local button = ns.launcher
    if not button or not Minimap then return end
    button:ClearAllPoints()
    button:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -4, -4)
    button:SetSize(20,20) button:SetScale(0.8)
    button:SetAlpha(1)
    button:SetFrameStrata("HIGH")
    button:Show()
end
