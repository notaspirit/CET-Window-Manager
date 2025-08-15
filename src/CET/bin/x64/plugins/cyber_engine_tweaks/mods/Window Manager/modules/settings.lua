local jsonUtils = require("modules/jsonUtils")
local logger = require("modules/logger")

---@class settings
local settings = {}
settings.__index = settings

local instance = nil

---@param data table
---@return boolean | nil
local function isOldFormat(data)
    if type(data) ~= "table" then
        return nil
    end
    for _, value in pairs(data) do
        if type(value) == "table" and value.index ~= nil then
            return true
        end
    end
    return false
end

---@param oldSettings table
---@return table | nil
local function migrateSettings(oldSettings)
    local isOldFormat = isOldFormat(oldSettings)
    if isOldFormat == false then
        return oldSettings
    end
    if isOldFormat == nil then
        return nil
    end
    return {
        windows = oldSettings,
        settings = {localization = "en-us", hide_disclaimer = false}
    }
end

---@return table | nil
local function loadSettings()
    local settingsFile = io.open("data/settings.json", "r")
    if not settingsFile then
        return nil
    end
    local settingsString = settingsFile:read("*a")
    settingsFile:close()
    local success, settingsTable = pcall(function()
        return jsonUtils.JSONToTable(settingsString)
    end)
    if not success or not settingsTable or type(settingsTable) ~= "table" then
        logger:error("Failed to parse settings file")
        return nil
    end
    return migrateSettings(settingsTable)
end

local function init(self)
    local savedSettings = loadSettings()
    if not savedSettings then
        self.windows = {}
        self.settings = {localization = "en-us"}
        return
    end
    if savedSettings.windows then
        self.windows = savedSettings.windows
    else
        self.windows = {}
    end
    if savedSettings.settings then
        if savedSettings.settings.localization == nil then
            savedSettings.settings.localization = "en-us"
        end
        self.settings = savedSettings.settings
    else
        self.settings = {localization = "en-us"}
    end
end

---@return settings
function settings:getInstance()
    if instance == nil then
        instance = setmetatable({}, settings)
        init(instance)
    end
    return instance
end

---@return void
local function saveSettings()
    local settingsInst = settings:getInstance()
    
    local settingsTable = {windows = settingsInst.windows, settings = settingsInst.settings}
    
    local settingsString = jsonUtils.TableToJSON(settingsTable)
    local settingsFile = io.open("data/settings.json", "w")
    if not settingsFile then
        logger:error("ERROR: Window Manager failed to open 'data/settings.json' expected file, got nil!")
        return
    end
    
    local success, errorMsg = pcall(function()
        settingsFile:write(settingsString)
        settingsFile:close()
    end)
    
    if not success then
        logger:error("Failed to write settings: " .. (errorMsg or ""))
    end
end

---@param value table
---@param type string
---@return void
function settings:update(value, type)
    if type == "windows" then
        self.windows = value
    end
    if type == "settings" then
        self.settings = value
    end
    saveSettings()
end

---@return void
function settings:save()
    saveSettings()
end
return settings