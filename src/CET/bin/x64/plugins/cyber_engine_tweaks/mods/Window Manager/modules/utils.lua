
local window_lookup = require("data/window_lookup")


---@param table table
---@param value any
local function isInTable(table, value)
    for _, v in ipairs(table) do
        if v == value then
            return true
        end 
    end 
    return false
end

---@param input string 
local function isBanned(input)
    if isInTable(window_lookup.window_blacklist, input) then
        return true
    end
    return false
end

---@param input table
local function tableLength(input)
    local count = 0
    for _ in pairs(input) do 
        count = count + 1
    end 
    return count
end

---@param inputName string
local function adjustWindowName(inputName)
    local displayName = inputName:match("^%s*(.-)%s*$")
    return window_lookup.window_name_lookup[displayName] or displayName
end

---@return string
---@param name string
local function getWindowDisplayName(name)
    return name:gsub("##", "\r#\r#\r")
end

---@param windowTable table
local function longestStringLengthPx(windowTable, disabled)
    local maxLength = 0
    for name, state in pairs(windowTable) do
        if not (disabled == state.disabled) then
            goto contine2
        end
        local displayName = getWindowDisplayName(name)
        local instanceLength = ImGui.CalcTextSize(displayName)
        if instanceLength > maxLength then
            maxLength = instanceLength
        end
        ::contine2::
    end
    return maxLength + 10
end

---@param tableInput table
local function sortTable(tableInput)
    -- Create a temporary table to sort windows by index
    local sortedWindows = {}
    for name, state in pairs(tableInput) do
        table.insert(sortedWindows, {name = name, state = state})
    end
    -- Sort the windows based on the index
    table.sort(sortedWindows, function(a, b) return a.state.index < b.state.index end)
    return sortedWindows
end

local function sortTableByName(tableInput)
    -- Create a temporary table to sort windows by name
    local sortedWindows = {}
    for name, state in pairs(tableInput) do
        table.insert(sortedWindows, {name = name, state = state})
    end
    -- Sort the windows based on the name
    table.sort(sortedWindows, function(a, b) return a.name < b.name end)
    return sortedWindows
end

---@param filename string
local function remove_extension(filename)
    return filename:match("(.+)%..+$") or filename
end

---@param tableInput table
local function deepCopy(tableInput)
    local newTable = {}
    for key, value in pairs(tableInput) do
        if type(value) == "table" then
            newTable[key] = deepCopy(value)
        else
            newTable[key] = value
        end
    end
    return newTable
end

local utils = {
    isBanned = isBanned,
    isInTable = isInTable,
    tableLength = tableLength,
    adjustWindowName = adjustWindowName,
    longestStringLenghtPX = longestStringLengthPx,
    sortTable = sortTable,
    sortTableByName = sortTableByName,
    remove_extension = remove_extension,
    deepCopy = deepCopy,
    getWindowDisplayName = getWindowDisplayName
}

return utils