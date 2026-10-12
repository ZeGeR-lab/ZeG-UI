local _, ns = ...
local targets = {
    {"GamepadMainActionBarFramePageUnitRightClassAction", {"OnEvent", "isFlyoutAction", "flyoutID", "stateDirty", "needsUpdate"}},
    {"GamepadMainActionBarFramePageUnitLeftClassAction", {"OnEvent", "isFlyoutAction", "flyoutID", "stateDirty", "needsUpdate"}},
    {"MainActionBar", {"visibility", "isShownExternal", "systemInfo", "shownButtonContainers"}},
    {"EditModeManagerFrame", {"layoutInfo", "editModeSystemAnchorDirty", "registeredSystemFrames"}},
    {"EssentialCooldownViewer", {"OnEvent", "auraInstanceIDToItemFramesMap"}},
}

function ns.CaptureTaint(stage)
    if not issecurevariable then return end
    ns.taintHistory = ns.taintHistory or {}
    for _, target in ipairs(targets) do
        local frame = _G[target[1]]
        if frame then
            for _, key in ipairs(target[2]) do
                -- Inspect security metadata only. Never read/iterate aura maps
                -- or compare spell/health values from Blizzard's secret state.
                local ok, secure, owner = pcall(issecurevariable, frame, key)
                if ok and not secure then
                    local label = target[1] .. "." .. key
                    if not ns.taintHistory[label] then
                        ns.taintHistory[label] = {stage = stage, owner = owner or "unknown"}
                    end
                end
            end
        end
    end
end

function ns.TaintInfo()
    ns.Info()
    ns.CaptureTaint("diagnostic requested")
    if not issecurevariable then ns.Print("Security metadata API unavailable.") return end
    local labels = {}
    for label in pairs(ns.taintHistory or {}) do labels[#labels + 1] = label end
    table.sort(labels)
    if #labels == 0 then ns.Print("No tainted fields detected in the sampled native state.") end
    for _, label in ipairs(labels) do
        local record = ns.taintHistory[label]
        ns.Print(label .. ": " .. record.owner .. "; first observed " .. record.stage)
    end
    ns.Print("This sample does not replace a full taint log.")
end
