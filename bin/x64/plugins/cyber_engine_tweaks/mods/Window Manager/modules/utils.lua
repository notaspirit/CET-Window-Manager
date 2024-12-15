local window_blacklist = {
    "Window Manager",
    ""
}

local window_name_lookup = {
    ["World Inspector"] = "World Inspector##RHT:WorldTools",
    ["Ink Inspector"] = "Ink Inspector##RHT:InkTools:MainWindow",
    ["Hot Reload"] = "Hot Reload##RHT:HotReload"
}

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
    if isInTable(window_blacklist, input) then
        print('Input is in the banned list!')
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

---@param displayName string
local function adjustWindowName(displayName) 
    return window_name_lookup[displayName] or displayName
end

---@param windowTable table
local function longestStringLenghtPx(windowTable)
    local maxLength = 0
    for name, state in pairs(windowTable) do
        local instanceLength = ImGui.CalcTextSize(name)
        if instanceLength > maxLength then
            maxLength = instanceLength
        end
    end
    return maxLength
end

local utils = {
    isBanned = isBanned,
    isInTable = isInTable,
    tableLength = tableLength,
    adjustWindowName = adjustWindowName,
    longestStringLenghtPX = longestStringLenghtPx
}

return utils