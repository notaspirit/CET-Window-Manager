local logger = require("modules/logger")
local utils = require("modules/utils")

---@param name string
---@return void
local function hideWindowProcess(name)
    local x, y
    local isCollapsed = false
    if ImGui.Begin(name, true) then
        isCollapsed = ImGui.IsWindowCollapsed()
        x, y = ImGui.GetWindowPos()
        ImGui.SetWindowPos(10000, 10000)
        ImGui.SetWindowCollapsed(true)
        ImGui.End()
    end
    CETWM.windows[name].lastPos = {x,y}
    CETWM.windows[name].isCollapsed = isCollapsed
    CETWM.settingsInst:update(CETWM.windows, "windows")
end

---@param name string
---@return void
local function showWindowProcess(name)
    local metadata = CETWM.windows[name]
    if ImGui.Begin(name, true) then
        ImGui.SetWindowPos(metadata.lastPos[1], metadata.lastPos[2])
        if metadata.isCollapsed then
            ImGui.SetWindowCollapsed(true)
        else 
            ImGui.SetWindowCollapsed(false)
        end
        ImGui.End()
    end
end

---@param name string
---@return void
local function showWindow(name)
    table.insert(CETWM.deferredShow, name)
end

---@param name string
---@return void
local function hideWindow(name)
    table.insert(CETWM.deferredHide, name)
end

---@param name string
---@return void
local function resetWindow(name)
    CETWM.windows[name].lastPos = {200,200}
    CETWM.windows[name].isCollapsed = false
    CETWM.windows[name].visible = true
    CETWM.settingsInst:update(CETWM.windows, "windows")
    showWindow(name)
end

---@param name string
---@return void
local function toggleLock(name)
    table.insert(CETWM.deferredLock, name)
end

---@param name string
---@return void
local function toggleLockProcessPt2(name)
    table.insert(CETWM.deferredLockPt2, name)
end

---@param name string
---@return void
local function toggleLockProcess(name)
    local metadata = CETWM.windows[name]
    if metadata.locked then
        CETWM.windows[name].locked = false
        return
    end
    if not metadata.visible then
        showWindow(name)
    end
    toggleLockProcessPt2(name)
end

---@param name string 
---@return void
local function toggleLockProcessPt2Process(name)
    local PosX, PosY
    local SizeX, SizeY
    local isCollapsed = false
    if ImGui.Begin(name, true) then
        isCollapsed = ImGui.IsWindowCollapsed()
        PosX, PosY = ImGui.GetWindowPos()
        SizeX, SizeY = ImGui.GetWindowSize()
        ImGui.End()
    end
    CETWM.windows[name].lastPos = {PosX, PosY}
    CETWM.windows[name].lastSize = {SizeX, SizeY}
    CETWM.windows[name].isCollapsed = isCollapsed
    CETWM.windows[name].locked = true
    CETWM.windows[name].visible = true
    CETWM.settingsInst:update(CETWM.windows, "windows")
end

---@return void
local function lockWindowLoop()
    for name, state in pairs(CETWM.windows) do
        if not (state.visible and state.locked) then goto continue end

        if ImGui.Begin(name, true) then 
            local curPosX, curPosY = ImGui.GetWindowPos()
            local curSizeX, curSizeY = ImGui.GetWindowSize()

            local isMoved = not (state.lastPos[1] == curPosX and state.lastPos[2] == curPosY) or not state.lastPos[1] == curPosX or not state.lastPos[2] == curPosY
            if isMoved then
                ImGui.SetWindowPos(state.lastPos[1], state.lastPos[2])
            end

            local isResized = not (state.lastSize[1] == curSizeX and state.lastSize[2] == curSizeY) or not state.lastSize[1] == curSizeX or not state.lastSize[2] == curSizeY
            if isResized then
                ImGui.SetWindowSize(state.lastSize[1], state.lastSize[2])
            end
            ImGui.End()
        end

        ::continue::
    end
end

---@param name string
---@return void
local function removeWindowProcessing(name)
    CETWM.windows[name] = nil
    local sortedWindows = utils.sortTable(CETWM.windows)

    for i, entry in ipairs(sortedWindows) do 
        CETWM.windows[entry.name].index = i
    end
    CETWM.settingsInst:update(CETWM.windows, "windows")
end

---@return void
local function processDeferred()
    for _, name in ipairs(CETWM.deferredHide) do
        hideWindowProcess(name)
    end
    CETWM.deferredHide = {} 

    for _, name in ipairs(CETWM.deferredLock) do
        toggleLockProcess(name)
    end
    CETWM.deferredLock = {}  

    for _, name in ipairs(CETWM.deferredShow) do
        showWindowProcess(name)
    end
    CETWM.deferredShow = {} 

    for _, name in ipairs(CETWM.deferredLockPt2) do
        toggleLockProcessPt2Process(name)
    end
    CETWM.deferredLockPt2 = {}

    for _, name in ipairs(CETWM.deferredRemoval) do
        removeWindowProcessing(name)
    end
    CETWM.deferredRemoval = {}
end

---@return void 
local function loadWindowsFromFile()
    if not RedCetWM then
        logger:error("ERROR: RedCetWM is not available, cannot load windows from file!")
        return
    end

    local layoutstring = RedCetWM.GetWindowLayout()
    if not layoutstring or layoutstring == "" then
        logger:info("No window layout found, skipping load.")
        return
    end

    local layoutLines = {}
    for line in layoutstring:gmatch("[^\n]+") do
        table.insert(layoutLines, line)
    end
    local addedWindows = false;
    for i, line in ipairs(layoutLines) do
        if not (line:find("[Window]", 1, true) == 1) then
            goto continue1
        end
        local name = line:match("%[Window%]%[(.-)%]")
        
        if CETWM.windows[name] then
            goto continue1
        end

        local posX, posY = layoutLines[i + 1]:match("Pos=(%d+),(%d+)")
        local sizeX, sizeY = layoutLines[i + 2]:match("Size=(%d+),(%d+)")
        local collapsed = layoutLines[i + 3]:match("Collapsed=(%d+)")

        if not posX then
            posX = "100"
        end

        if not posY then
            posY = "100"
        end

        if not sizeX then
            sizeX = "200"
        end

        if not sizeY then
            sizeY = "200"
        end

        if not collapsed then
            collapsed = "0"
        end

        CETWM.windows[name] = {
            visible = true,
            lastPos = {x = tonumber(posX), y = tonumber(posY)},
            isCollapsed = (collapsed == "1"),
            index = 1,
            locked = false,
            lastSize = {tonumber(sizeX), tonumber(sizeY)},
            disabled = false
        }
        addedWindows = true
        ::continue1::
    end

    if addedWindows then
        CETWM.settingsInst:update(CETWM.windows, "windows")
    end
end

---@param oldName string
---@return void
local function requestSwitchWindowName(oldName)
    CETWM.requestedNameSwitch = oldName
    CETWM.requestWindowPos = true
end

return {
    hideWindowProcess = hideWindowProcess,
    showWindowProcess = showWindowProcess,
    showWindow = showWindow,
    hideWindow = hideWindow,
    resetWindow = resetWindow,
    toggleLock = toggleLock,
    toggleLockProcess = toggleLockProcess,
    toggleLockProcessPt2 = toggleLockProcessPt2,
    lockWindowLoop = lockWindowLoop,
    processDeferred = processDeferred,
    loadWindowsFromFile = loadWindowsFromFile,
    requestSwitchWindowName = requestSwitchWindowName,
}