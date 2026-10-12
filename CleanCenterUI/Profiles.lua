local _, ns = ...
local keys = {"rows", "scale", "buttonSize", "gap", "buttonShape", "stanceShape", "compactBags", "menuDock",
    "minimapSize", "cooldownNumbers", "opacity", "borders", "modules", "colors", "unitStyles", "barSettings",
    "editor", "fontFace", "fontSettings", "themePreset", "classAccent", "auras", "tooltip", "swing", "fade", "meters", "trackers"}
local positionKeys = {"player", "target", "pet", "focus", "party1", "party2", "party3", "party4", "party5",
    "bar1", "bar2", "bar3", "bar4", "bar5", "bar6", "bar7", "bar8", "PetActionBar", "StanceBar", "vehicleexit",
    "cast", "targetcast", "focuscast", "chat", "minimap", "quests", "experience", "bags", "menu", "buffs", "debuffs",
    "resource", "alternatepower",
    "tooltip", "swingmain", "swingoff", "swingranged", "trackeressential", "trackerutility", "trackerbuffs", "trackerbars"}
local schema = {}
local function Walk(value, path)
    if type(value) == "table" then
        for key, child in pairs(value) do Walk(child, path .. "." .. tostring(key)) end
    else schema[path] = type(value) end
end
for _, key in ipairs(keys) do Walk(ns.defaults[key], key) end
for _, key in ipairs(positionKeys) do schema["positions." .. key .. ".x"], schema["positions." .. key .. ".y"] = "number", "number" end
local function Get(source, path)
    local value = source
    for part in path:gmatch("[^.]+") do
        if type(value) ~= "table" then return nil end
        value = value[tonumber(part) or part]
    end
    return value
end
local function Put(target, path, value)
    local parts = {}
    for part in path:gmatch("[^.]+") do parts[#parts + 1] = tonumber(part) or part end
    for i = 1, #parts - 1 do
        target[parts[i]] = target[parts[i]] or {}
        target = target[parts[i]]
    end
    target[parts[#parts]] = value
end
local allowed = {fontFace = ns.fontFaces, themePreset = {teal = true, gold = true, class = true, custom = true},
    ["meters.colorMode"] = {native = true, accent = true, custom = true},
    ["tooltip.anchor"] = {default = true, cursor = true, fixed = true},
    ["swing.visibility"] = {combat = true, always = true}}
local function Valid(path, value)
    if type(value) ~= schema[path] then return false end
    if type(value) == "number" then return ns.Finite(value) and math.abs(value) <= 10000 end
    if type(value) == "string" then
        if #value > 32 or value:find("[%c|]") then return false end
        if allowed[path] then return allowed[path][value] ~= nil end
        if path:match("%.outline$") then return value == "" or value == "OUTLINE" or value == "THICKOUTLINE" end
        if path:match("[Ss]hape$") then return value == "square" or value == "triangles" or value == "inherit" end
    end
    return true
end
local function Defaults()
    local result = {positions = {}}
    for _, key in ipairs(keys) do result[key] = ns.Copy(ns.defaults[key]) end
    return result
end
function ns.InitializeProfiles()
    CleanCenterUIProfilesDB = type(CleanCenterUIProfilesDB) == "table" and CleanCenterUIProfilesDB or {}
    local db = CleanCenterUIProfilesDB
    db.version = 1
    db.profiles = type(db.profiles) == "table" and db.profiles or {}
    ns.profiles = db.profiles
end
local function Name(value)
    if type(value) ~= "string" then return end
    value = value:match("^%s*(.-)%s*$")
    if #value >= 1 and #value <= 40 and not value:find("[%c|]") then return value end
end
function ns.ProfileNames()
    local names = {}
    for name in pairs(ns.profiles or {}) do if Name(name) then names[#names + 1] = name end end
    table.sort(names)
    return names
end
function ns.CapturePreferences()
    local result = Defaults()
    for path in pairs(schema) do
        local value = Get(ns.db, path)
        if Valid(path, value) then Put(result, path, value) end
    end
    return result
end
function ns.SaveProfile(name)
    name = Name(name)
    if not name then return false, "Use a profile name from 1 to 40 characters." end
    ns.profiles[name] = ns.CapturePreferences()
    ns.db.profileName = name
    return true, "Saved profile: " .. name
end
function ns.DeleteProfile(name)
    name = Name(name)
    if not name or not ns.profiles[name] then return false, "Choose a saved profile." end
    ns.profiles[name] = nil
    return true, "Deleted profile: " .. name
end
local function Encode(value)
    return (value:gsub("([^%w_%.%-])", function(c) return string.format("%%%02X", string.byte(c)) end))
end
function ns.ExportProfile(name)
    local source = name and ns.profiles[name] or ns.CapturePreferences()
    if not source then return nil, "Choose a saved profile." end
    local lines = {}
    for path, kind in pairs(schema) do
        local value = Get(source, path)
        if value ~= nil then
            if not Valid(path, value) then return nil, "This profile contains invalid preferences." end
            local payload = kind == "boolean" and (value and "1" or "0")
                or kind == "number" and string.format("%.9g", value) or Encode(value)
            lines[#lines + 1] = path .. "\t" .. kind:sub(1, 1) .. "\t" .. payload
        end
    end
    table.sort(lines)
    return "CCUI1\n" .. table.concat(lines, "\n")
end
local function DecodeString(value)
    local rest = value:gsub("%%[0-9A-Fa-f][0-9A-Fa-f]", "")
    if rest:find("%%") then return end
    return (value:gsub("%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end))
end
function ns.DecodeProfile(text)
    if type(text) ~= "string" or #text > 65536 then return nil, "Profile text is too large." end
    text = text:gsub("\r\n", "\n"):match("^%s*(.-)%s*$")
    if text:sub(1, 6) ~= "CCUI1\n" then return nil, "Paste a CCUI1 profile export." end
    local result, seen, count = Defaults(), {}, 0
    for line in text:sub(7):gmatch("[^\n]+") do
        count = count + 1
        if count > 1024 then return nil, "Too many profile records." end
        local path, tag, payload = line:match("^([%w_.]+)\t([nbs])\t(.*)$")
        if not path or not schema[path] or seen[path] or schema[path]:sub(1, 1) ~= tag then
            return nil, "Unknown, duplicate or invalid profile record."
        end
        seen[path] = true
        local value
        if tag == "n" then value = tonumber(payload)
        elseif tag == "b" then
            if payload ~= "0" and payload ~= "1" then return nil, "Invalid boolean preference." end
            value = payload == "1"
        else value = DecodeString(payload) end
        if not Valid(path, value) then return nil, "Invalid value for " .. path end
        Put(result, path, value)
    end
    for _, position in pairs(result.positions) do
        if position.x == nil or position.y == nil then return nil, "A position needs both X and Y." end
    end
    return result
end
function ns.ImportProfile(name, text)
    name = Name(name)
    if not name then return false, "Use a profile name from 1 to 40 characters." end
    local result, err = ns.DecodeProfile(text)
    if not result then return false, err end
    ns.profiles[name] = result
    return true, "Imported profile: " .. name .. ". Select Load to apply it."
end
function ns.LoadProfile(name)
    name = Name(name)
    if not name or not ns.profiles[name] then return false, "Choose a saved profile." end
    local text, err = ns.ExportProfile(name)
    if not text then return false, err end
    local config
    config, err = ns.DecodeProfile(text)
    if not config then return false, err end
    ns.pendingProfile = {name = name, config = config}
    ns.pending = true
    if InCombatLockdown() or ns.blizzardEditing then return true, "Profile saved to apply after combat or Edit Mode." end
    ns.ConsumePendingProfile()
    ns.QueueLayout()
    return true, "Loaded profile: " .. name
end
function ns.ConsumePendingProfile()
    if not ns.pendingProfile or InCombatLockdown() or ns.blizzardEditing then return true end
    local pending = ns.pendingProfile
    local reload = false
    for key, value in pairs(pending.config.modules) do if ns.db.modules[key] ~= value then reload = true end end
    if reload and ns.db.enabled then
        ns.restoring = true ns.RestoreSavedChanges() ns.restoring = false
    end
    if ns.CancelAppearanceColor then ns.CancelAppearanceColor() end
    for _, key in ipairs(keys) do ns.db[key] = ns.Copy(pending.config[key]) end
    ns.db.positions = ns.Copy(pending.config.positions)
    ns.db.profileName, ns.pendingProfile = pending.name, nil
    ns.NormalizeCustomization()
    ns.NormalizeAppearance()
    if reload then ReloadUI() return false end
    return true
end
