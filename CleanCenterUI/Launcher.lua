local _, ns = ...
-- Independent launcher remains available when the UI preset is disabled.
function ns.CreateLauncher()
    if ns.launcher or not Minimap then return end
    local button = CreateFrame("Button", "ZeGUIMinimapButton", Minimap)
    ns.launcher = button
    button:SetSize(30, 30)
    button:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", 5, 5)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(30)
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    ns.Panel(button, 1)
    local label = ns.Font(button, 12, "CENTER")
    label:SetPoint("CENTER") label:SetText("ZeG")
    button:SetScript("OnClick", function(_, mouse)
        if mouse == "RightButton" then ns.OpenCustomize("trackers") else ns.OpenOptions() end
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
end
