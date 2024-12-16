local utils = require('modules/utils')
local settings = require('modules/jsonUtils')

-- mod info
CETWM = {
    ready = false,
    windows = {}, -- Store window states: {name = {visible = bool, lastPos = {x,y}, isCollapsed = bool, index = int, locked = bool}}
    -- this table now acts are the "working" or temp dir that then gets merged into the settingService and saved
    overlayOpen = false,
    minWidth = 0
}

local settingsInst = settings:getInstance()
local windowName = ""
local popUpBannedText = ""

local deferredHide = {}
local deferredShow = {}
local deferredLock = {}
local deferredLockPt2 = {}
local deferredRemoval = {}

-- onInit event
registerForEvent('onInit', function() 
    -- set as ready
    CETWM.ready = true
    CETWM.windows = settingsInst.windows
    if CETWM.windows["Window Manager"] == nil then
        local newIndex = utils.tableLength(CETWM.windows) + 1
        CETWM.windows[utils.adjustWindowName("Window Manager")] = {visible = true, lastPos = {x = 100, y = 100}, isCollapsed = false, index = newIndex, locked = false, lastSize = {1,1}}
        settingsInst.update(CETWM.windows)
    end
end)

registerForEvent("onOverlayOpen", function()
    CETWM.overlayOpen = true
end)

registerForEvent("onOverlayClose", function()
    CETWM.overlayOpen = false
end)

---@param name string
local function hideWindowProcess(name)
    local x, y
    local isCollapsed = false
    if ImGui.Begin(name, true) then
        isCollapsed = ImGui.IsWindowCollapsed()
        x, y = ImGui.GetWindowPos()
        ImGui.SetWindowPos(10000, 10000)
        ImGui.End() -- FOR TESTING
    end
    CETWM.windows[name].lastPos = {x,y}
    CETWM.windows[name].isCollapsed = isCollapsed
    settingsInst.update(CETWM.windows)
end

---@param name string
local function showWindowProcess(name)
    local metadata = CETWM.windows[name]
    if ImGui.Begin(name, true) then
        ImGui.SetWindowPos(metadata.lastPos[1], metadata.lastPos[2])
        ImGui.End() -- FOR TESTING
    end
    if CETWM.windows[name].isCollasped then
        if ImGui.Begin(name, false) then
            local s = 1
            ImGui.End() -- FOR TESTING
        end
    end
end

---@param name string
local function showWindow(name)
    table.insert(deferredShow, name)
end

---@param name string
local function hideWindow(name)
    table.insert(deferredHide, name)
end

---@param name string
local function resetWindow(name)
    CETWM.windows[name].lastPos = {200,200}
    CETWM.windows[name].isCollasped = false
    CETWM.windows[name].visible = true
    settingsInst.update(CETWM.windows)
    showWindow(name)
end

---@param name string
local function toggleLock(name)
    table.insert(deferredLock, name)
end

---@param name string
local function toggleLockProcessPt2(name)
    table.insert(deferredLockPt2, name)
end

---@param name string
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
local function toggleLockProcessPt2Process(name)
    local metadata = CETWM.windows[name]
    local PosX, PosY
    local SizeX, SizeY
    local isCollapsed = false
    if ImGui.Begin(name, true) then
        isCollapsed = ImGui.IsWindowCollapsed()
        PosX, PosY = ImGui.GetWindowPos()
        SizeX, SizeY = ImGui.GetWindowSize()
        ImGui.End() -- FOR TESTING
    end
    CETWM.windows[name].lastPos = {PosX, PosY}
    CETWM.windows[name].lastSize = {SizeX, SizeY}
    CETWM.windows[name].isCollapsed = isCollapsed
    CETWM.windows[name].locked = true
    CETWM.windows[name].visible = true
    settingsInst.update(CETWM.windows)
end

---@param name string
---@param direction int
local function changeWindowIndex(name, direction)
    local currentIndex = CETWM.windows[name].index
    local newIndex = currentIndex + direction

    -- Ensure the new index is within valid bounds
    if newIndex < 1 or newIndex > utils.tableLength(CETWM.windows) then
        return  -- Do nothing if the new index is out of bounds
    end

    -- Temporarily sort CETWM.windows by index
    local sortedWindows = {}
    for windowName, state in pairs(CETWM.windows) do
        table.insert(sortedWindows, {name = windowName, state = state})
    end

    -- Sort windows by their index
    table.sort(sortedWindows, function(a, b)
        return a.state.index < b.state.index
    end)

    -- Find the current and new positions of the windows
    local currentPosition, newPosition
    for i, window in ipairs(sortedWindows) do
        if window.name == name then
            currentPosition = i
        end
        if window.state.index == newIndex then
            newPosition = i
        end
    end

    -- Swap the windows in the sorted list
    if currentPosition and newPosition then
        -- Swap indices in the sorted list
        sortedWindows[currentPosition], sortedWindows[newPosition] = sortedWindows[newPosition], sortedWindows[currentPosition]

        -- Update the CETWM.windows with the new sorted order
        for i, window in ipairs(sortedWindows) do
            CETWM.windows[window.name].index = i
        end
    end

    -- Update the settings
    settingsInst.update(CETWM.windows)
end


---@param name string
---@param state table
local function lockWindowLoop(name, state) 
    if ImGui.Begin(name, true) then 
        -- get current pos and size
        local curPosX, curPosY = ImGui.GetWindowPos()
        local curSizeX, curSizeY = ImGui.GetWindowSize()
        -- reset window pos if changed
        if not (state.lastPos[1] == curPosX and state.lastPos[2] == curPosY) or not state.lastPos[1] == curPosX or not state.lastPos[2] == curPosY then
            ImGui.SetWindowPos(state.lastPos[1], state.lastPos[2])
        end
        -- reset window size if changed
        if not (state.lastSize[1] == curSizeX and state.lastSize[2] == curSizeY) or not state.lastSize[1] == curSizeX or not state.lastSize[2] == curSizeY then
            ImGui.SetWindowSize(state.lastSize[1], state.lastSize[2])
        end
    end
end

---@param name string
local function removeWindowProcessing(name)
    CETWM.windows[name] = nil
    local sortedWindows = utils.sortTable(CETWM.windows)

    for i, entry in ipairs(sortedWindows) do 
        CETWM.windows[entry.name].index = i
    end
    settingsInst.update(CETWM.windows)
end

local function addWindowName()
    local adjustedWindowName = utils.adjustWindowName(windowName)
    if CETWM.windows[adjustedWindowName] == nil then
        if not utils.isBanned(windowName) then
            local newIndex = utils.tableLength(CETWM.windows) + 1
            CETWM.windows[utils.adjustWindowName(adjustedWindowName)] = {visible = true, lastPos = {x = 100, y = 100}, isCollapsed = false, index = newIndex, locked = false}
            settingsInst.update(CETWM.windows)
            popUpBannedText = ""
            windowName = ""
            ImGui.CloseCurrentPopup()
        else
            popUpBannedText = string.format("%s is not an allowed Window Name!", windowName)
        end
    else
        popUpBannedText = windowName.." is already being managed!"
        return
    end
end

local function addWindowTab()
    if ImGui.Button("Add Window") then
        ImGui.OpenPopup("Add Window")
    end
    if ImGui.BeginPopup("Add Window") then
        local text_input_active = false
        windowName, text_input_active =  ImGui.InputText("##WindowNameInPopup", windowName, 100, ImGuiInputTextFlags.EnterReturnsTrue)
        if text_input_active then
            addWindowName()
        end
        if ImGui.Button("Add") then
            addWindowName()
        end
        ImGui.SameLine()
        if ImGui.Button("Close") then
            ImGui.CloseCurrentPopup()
        end
        ImGui.SameLine()
        ImGui.Text(popUpBannedText)
        ImGui.EndPopup()
    end
    ImGui.TextWrapped("Add Windows here by their display name. Disregard icons if they have any.")
    ImGui.TextWrapped("If the window doesn't get affected despite being properly spelled (it's case sensitive), report it so it can be fixed.")
        
    local sortedWindows = utils.sortTable(CETWM.windows)

    for _, window in ipairs(sortedWindows) do
        local name = window.name
        local state = window.state
        -- Move Up Button
        if ImGui.Button(IconGlyphs.ArrowUp .. "##" .. name) then
            changeWindowIndex(name, -1)  -- Move up
        end
        -- Move Down Button
        ImGui.SameLine()
        if ImGui.Button(IconGlyphs.ArrowDown .. "##" .. name) then
            changeWindowIndex(name, 1)  -- Move down
        end

        ImGui.SameLine()
        if ImGui.Button(IconGlyphs.Close .. "##" .. name) then
            if name == "Window Manager" then
                local s = 1
            else
                showWindow(name)
                table.insert(deferredRemoval, name)
            end
        end
        ImGui.SameLine()
        if ImGui.Button(IconGlyphs.Cached .. "##" .. name) then
            resetWindow(name)
        end
        ImGui.SameLine()
        ImGui.Text(name:match("([^#]+)"))
    end 
end

local function manageWindowsTab()
    CETWM.minWidth = utils.longestStringLenghtPX(CETWM.windows)

    -- colors for when the window is visible
    local r = 0.22
    local g = 0.48
    local b = 0.8
    
    local sortedWindows = utils.sortTable(CETWM.windows)

    for _, window in ipairs(sortedWindows) do
        local name = window.name
        local state = window.state

        if state.locked then
            -- Light color when enabled (you can adjust these RGB values)
            ImGui.PushStyleColor(ImGuiCol.Button, r, g, b, 1.0)
            ImGui.PushStyleColor(ImGuiCol.ButtonHovered, r*1.2, g*1.2, b*1.2, 1.0)
            ImGui.PushStyleColor(ImGuiCol.ButtonActive, r*1.2, g*1.2, b*1.2, 1.0)
        else
            -- Dark color when disabled
            ImGui.PushStyleColor(ImGuiCol.Button, 0.2, 0.2, 0.2, 1.0)
            ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 0.3, 0.3, 0.3, 1.0)
            ImGui.PushStyleColor(ImGuiCol.ButtonActive, 0.3, 0.3, 0.3, 1.0)
        end

        if ImGui.Button(string.format("%s##%s", (state.locked and IconGlyphs.Lock or IconGlyphs.LockOpenVariant), name)) then
            toggleLock(name)
        end
        ImGui.PopStyleColor(3)
        ImGui.SameLine()
        if state.visible then
            -- Light color when enabled (you can adjust these RGB values)
            ImGui.PushStyleColor(ImGuiCol.Button, r, g, b, 1.0)
            ImGui.PushStyleColor(ImGuiCol.ButtonHovered, r*1.2, g*1.2, b*1.2, 1.0)
            ImGui.PushStyleColor(ImGuiCol.ButtonActive, r*1.2, g*1.2, b*1.2, 1.0)
        else
            -- Dark color when disabled
            ImGui.PushStyleColor(ImGuiCol.Button, 0.2, 0.2, 0.2, 1.0)
            ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 0.3, 0.3, 0.3, 1.0)
            ImGui.PushStyleColor(ImGuiCol.ButtonActive, 0.3, 0.3, 0.3, 1.0)
        end
        
        if ImGui.Button(name, CETWM.minWidth, 0) then
            if name == "Window Manager" then
                local s = 1
            else
                state.visible = not state.visible  -- Toggle visibility
                settingsInst.update(CETWM.windows)
                if not state.visible then
                    hideWindow(name)
                else 
                    showWindow(name)
                end
            end
        end
        ImGui.PopStyleColor(3)  -- Pop all 3 style colors we pushed
    end
end

-- onDraw event to render ImGui windows
registerForEvent("onDraw", function()
    if not CETWM.overlayOpen then return end
    local WMFlags = bit32.bor(ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoScrollbar)
    if ImGui.Begin("Window Manager", true, WMFlags) then
        if ImGui.BeginTabBar("TabList1") then
            if ImGui.BeginTabItem("Toggle") then
                manageWindowsTab()
                ImGui.EndTabItem()
            end
            if ImGui.BeginTabItem("Settings") then
                addWindowTab()
                ImGui.EndTabItem()
            end
        end
        ImGui.End()
    end
    for name, state in pairs(CETWM.windows) do
        if state.visible and state.locked then
            lockWindowLoop(name, state)
        end
    end
    -- Process all deferred hide actions
    for _, name in ipairs(deferredHide) do
        hideWindowProcess(name)
    end
    deferredHide = {}  -- Clear the deferred hide actions
    -- Process all deferred lock actions
    for _, name in ipairs(deferredLock) do
        toggleLockProcess(name)
    end
    deferredLock = {}  -- Clear the deferred show actions
    -- Process all deferred show actions
    for _, name in ipairs(deferredShow) do
        showWindowProcess(name)
    end
    deferredShow = {}  -- Clear the deferred show actions
    -- Process all deferred show actions
    for _, name in ipairs(deferredLockPt2) do
        toggleLockProcessPt2Process(name)
    end
    deferredLockPt2 = {}  -- Clear the deferred show actions

    for _, name in ipairs(deferredRemoval) do
        removeWindowProcessing(name)
    end
    deferredRemoval = {}
end)
