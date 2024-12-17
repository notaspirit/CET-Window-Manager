
-- Helper function to escape special characters in strings
---@param str string
---@return string, int
local function escapeString(str)
    return str:gsub("\\", "\\\\")  -- Escape backslashes
              :gsub('"', '\\"')    -- Escape double quotes
              :gsub("\b", "\\b")   -- Escape backspace
              :gsub("\f", "\\f")   -- Escape form feed
              :gsub("\n", "\\n")   -- Escape newline
              :gsub("\r", "\\r")   -- Escape carriage return
              :gsub("\t", "\\t")   -- Escape tab
end

-- Converts a table to a JSON string
---@param value table | int | string | boolean
---@param indentLevel any
---@return string
function TableToJSON(value, indentLevel)
    indentLevel = indentLevel or 0
    local indent = string.rep("  ", indentLevel)  -- Two spaces per indent level
    local nextIndent = string.rep("  ", indentLevel + 1)

    if type(value) == "table" then
        local jsonStr = {}
        local isArray = #value > 0  -- Check if it's an array (list)

        for key, val in pairs(value) do
            if isArray then
                jsonStr[#jsonStr + 1] = nextIndent .. TableToJSON(val, indentLevel + 1)  -- Append JSON string for array
            else
                jsonStr[#jsonStr + 1] = string.format('%s"%s": %s', nextIndent, tostring(key), TableToJSON(val, indentLevel + 1))
            end
        end

        if isArray then
            return "[\n" .. table.concat(jsonStr, ",\n") .. "\n" .. indent .. "]"  -- Array format
        else
            return "{\n" .. table.concat(jsonStr, ",\n") .. "\n" .. indent .. "}"  -- Object format
        end
    elseif type(value) == "string" then
        return string.format('"%s"', escapeString(value))  -- Use escapeString to handle special characters
    elseif type(value) == "number" or type(value) == "boolean" then
        return tostring(value)  -- Directly return numbers and booleans
    else
        return "null"  -- Handle nil values
    end
end

-- Convert JSON string to Lua table
---@param jsonStr string
---@return table | string | int | boolean | nil
function JSONToTable(jsonStr)
    -- Remove whitespace
    jsonStr = jsonStr:gsub("^%s*(.-)%s*$", "%1")
    
    local pos = 1
    
    local function parseValue()
        local char = jsonStr:sub(pos, pos)
        
        -- Parse null
        if jsonStr:sub(pos, pos + 3) == "null" then
            pos = pos + 4
            return nil
        end
        
        -- Parse boolean
        if jsonStr:sub(pos, pos + 3) == "true" then
            pos = pos + 4
            return true
        end
        if jsonStr:sub(pos, pos + 4) == "false" then
            pos = pos + 5
            return false
        end
        
        -- Parse number
        local num = jsonStr:match("^-?%d+%.?%d*[eE]?[+-]?%d*", pos)
        if num then
            pos = pos + #num
            return tonumber(num)
        end
        
        -- Parse string
        if char == '"' then
            local value = ""
            pos = pos + 1
            while pos <= #jsonStr do
                char = jsonStr:sub(pos, pos)
                if char == '"' then
                    pos = pos + 1
                    return value
                end
                if char == '\\' then
                    pos = pos + 1
                    char = jsonStr:sub(pos, pos)
                    if char == 'n' then char = '\n'
                    elseif char == 'r' then char = '\r'
                    elseif char == 't' then char = '\t'
                    elseif char == 'b' then char = '\b'
                    elseif char == 'f' then char = '\f'
                    end
                end
                value = value .. char
                pos = pos + 1
            end
        end
        
        -- Parse array
        if char == '[' then
            pos = pos + 1
            local arr = {}
            while pos <= #jsonStr do
                char = jsonStr:sub(pos, pos)
                if char == ']' then
                    pos = pos + 1
                    return arr
                end
                if char ~= ',' and char ~= ' ' and char ~= '\n' and char ~= '\r' and char ~= '\t' then
                    table.insert(arr, parseValue())
                end
                pos = pos + 1
            end
        end
        
        -- Parse object
        if char == '{' then
            pos = pos + 1
            local obj = {}
            while pos <= #jsonStr do
                char = jsonStr:sub(pos, pos)
                if char == '}' then
                    pos = pos + 1
                    return obj
                end
                if char == '"' then
                    local key = parseValue()
                    -- Skip whitespace and colon
                    while jsonStr:sub(pos, pos):match("[ :\n\r\t]") do
                        pos = pos + 1
                    end
                    obj[key] = parseValue()
                end
                pos = pos + 1
            end
        end
    end
    
    return parseValue()
end

local jsonUtils = {
    JSONToTable = JSONToTable,
    TableToJSON = TableToJSON

}

---@class settings
local settings = {}
settings.__index = settings

-- Create the single global instance
local instance = nil

-- Loads the settings from the settings.json file
---@return table | nil
local function loadSettings()
    -- Check if file exists
    local settingsFile = io.open("data/settings.json", "r")
    if not settingsFile then
        print("ERROR: Failed to open 'data/settings.json' expected file, got nil!")
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
---@return settings
function settings.getInstance()
    if instance == nil then
        instance = setmetatable({}, settings)
        init(instance)
    end
    return instance
end

---@return void
local function saveSettings()
    local settingsInst = settings.getInstance()
    
    local settingsTable = settingsInst.windows
    
    local settingsString = jsonUtils.TableToJSON(settingsTable)
    local settingsFile = io.open("data/settings.json", "w")
    if not settingsFile then
        print("ERROR: Failed to open 'data/settings.json' expected file, got nil!")
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

---@param value any
---@return void
function settings:update(value)  -- Changed parameter name from 'type' to 'settingType'
    -- Update the value
    self.windows = value
    -- Save after any change
    saveSettings()
end

---@return void
function settings:save()
    saveSettings()
end

return settings