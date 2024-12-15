local jsonUtils = require('modules/jsonUtils')

local settings = {}
settings.__index = settings

-- Create the single global instance
local instance = nil

-- Loads the settings from the settings.json file
local function loadSettings()
    -- Check if file exists
    local settingsFile = io.open("data/settings.json", "r")
    if not settingsFile then
        return nil
    end
    -- Read the file content
    local settingsString = settingsFile:read("*a")
    settingsFile:close()
    -- Parse JSON into table
    local success, settingsTable = pcall(function()
        return jsonUtils.JSONToTable(settingsString)
    end)
    if not success or not settingsTable then
        print("Failed to parse settings file")
        return nil
    end
    print("Settings file parsed successfully")
    return settingsTable
end

local function init(self)
    local savedSettings = loadSettings()
    if savedSettings then
        self.windows = savedSettings
    else
        self.windows = {}
    end
end

-- returns the single global instance
function settings.getInstance()
    if instance == nil then
        instance = setmetatable({}, settings)
        init(instance)
    end
    return instance
end

local function saveSettings()
    local settingsInst = settings.getInstance()
    
    local settingsTable = settingsInst.windows
    
    local settingsString = jsonUtils.TableToJSON(settingsTable)
    local settingsFile = io.open("data/settings.json", "w")
    if not settingsFile then
        return
    end
    
    local success, errorMsg = pcall(function()
        settingsFile:write(settingsString)
        settingsFile:close()
    end)
    
    if not success then
        print("Failed to write settings: " .. (errorMsg or ""))
    end
end

function settings:update(value)  -- Changed parameter name from 'type' to 'settingType'
    -- Update the value
    self.windows = value
    -- Save after any change
    saveSettings()
end

function settings:save()
    saveSettings()
end

return settings