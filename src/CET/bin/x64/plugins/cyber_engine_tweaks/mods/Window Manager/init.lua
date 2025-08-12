--[[
                                                
 /      \|        \        \    |  \  _  |  \  \              |  \                          |  \     /  \                                                      
|  ▓▓▓▓▓▓\ ▓▓▓▓▓▓▓▓\▓▓▓▓▓▓▓▓    | ▓▓ / \ | ▓▓\▓▓_______   ____| ▓▓ ______  __   __   __     | ▓▓\   /  ▓▓ ______  _______   ______   ______   ______   ______  
| ▓▓   \▓▓ ▓▓__      | ▓▓       | ▓▓/  ▓\| ▓▓  \       \ /      ▓▓/      \|  \ |  \ |  \    | ▓▓▓\ /  ▓▓▓|      \|       \ |      \ /      \ /      \ /      \ 
| ▓▓     | ▓▓  \     | ▓▓       | ▓▓  ▓▓▓\ ▓▓ ▓▓ ▓▓▓▓▓▓▓\  ▓▓▓▓▓▓▓  ▓▓▓▓▓▓\ ▓▓ | ▓▓ | ▓▓    | ▓▓▓▓\  ▓▓▓▓ \▓▓▓▓▓▓\ ▓▓▓▓▓▓▓\ \▓▓▓▓▓▓\  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\
| ▓▓   __| ▓▓▓▓▓     | ▓▓       | ▓▓ ▓▓\▓▓\▓▓ ▓▓ ▓▓  | ▓▓ ▓▓  | ▓▓ ▓▓  | ▓▓ ▓▓ | ▓▓ | ▓▓    | ▓▓\▓▓ ▓▓ ▓▓/      ▓▓ ▓▓  | ▓▓/      ▓▓ ▓▓  | ▓▓ ▓▓    ▓▓ ▓▓   \▓▓
| ▓▓__/  \ ▓▓_____   | ▓▓       | ▓▓▓▓  \▓▓▓▓ ▓▓ ▓▓  | ▓▓ ▓▓__| ▓▓ ▓▓__/ ▓▓ ▓▓_/ ▓▓_/ ▓▓    | ▓▓ \▓▓▓| ▓▓  ▓▓▓▓▓▓▓ ▓▓  | ▓▓  ▓▓▓▓▓▓▓ ▓▓__| ▓▓ ▓▓▓▓▓▓▓▓ ▓▓      
 \▓▓    ▓▓ ▓▓     \  | ▓▓       | ▓▓▓    \▓▓▓ ▓▓ ▓▓  | ▓▓\▓▓    ▓▓\▓▓    ▓▓\▓▓   ▓▓   ▓▓    | ▓▓  \▓ | ▓▓\▓▓    ▓▓ ▓▓  | ▓▓\▓▓    ▓▓\▓▓    ▓▓\▓▓     \ ▓▓      
  \▓▓▓▓▓▓ \▓▓▓▓▓▓▓▓   \▓▓        \▓▓      \▓▓\▓▓\▓▓   \▓▓ \▓▓▓▓▓▓▓ \▓▓▓▓▓▓  \▓▓▓▓▓\▓▓▓▓      \▓▓      \▓▓ \▓▓▓▓▓▓▓\▓▓   \▓▓ \▓▓▓▓▓▓▓_\▓▓▓▓▓▓▓ \▓▓▓▓▓▓▓\▓▓      
                                                                                                                                   |  \__| ▓▓                  
                                                                                                                                    \▓▓    ▓▓                  
                                                                                                                                     \▓▓▓▓▓▓                   
by: spirit (discord: sprt_)
]]

local version = '1.1.0'

local utils = require('modules/utils')
local settings = require('modules/settings')
local styles = require('data/styles')
local localizationService = require('modules/localization')
local logger = require('modules/logger')

CETWM = {
    ready = false,
    windows = {}, -- Store window states: {name = {visible = bool, lastPos = {x,y}, isCollapsed = bool, index = int, locked = bool, lastSize = {x,y}, disabled = bool}}
    -- this table now acts are the "working" or temp dir that then gets merged into the settingService and saved
    overlayOpen = false,
    minWidth = 0
}

local settingsInst
local localizationInst

local windowName = ""
local popUpBannedText = ""

local deferredHide = {}
local deferredShow = {}
local deferredLock = {}
local deferredLockPt2 = {}
local deferredRemoval = {}
local deferredSetSelfPos = {}
local requestWindowPos = false
local requestedNameSwitch = ''
local requestedLanguageSwitch = ''

local dragging_index = nil

local sideButtonWidth = 0

local framesToWaitBeforeLoading = 5

---@return boolean
local function checkPackages()
    local hasError = false
    local packages = {utils, settings, styles, localizationService, logger}
    for _, package in ipairs(packages) do
        if package == nil then
            hasError = true
            print("ERROR: Window Manager failed to intilize package: " .. tostring(_))
            spdlog.error("ERROR: Window Manager failed to intilize package: " .. tostring(_))
        end
    end
    if hasError then
        return false
    end
    return true
end

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
    settingsInst:update(CETWM.windows, "windows")
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
    table.insert(deferredShow, name)
end

---@param name string
---@return void
local function hideWindow(name)
    table.insert(deferredHide, name)
end

---@param name string
---@return void
local function resetWindow(name)
    CETWM.windows[name].lastPos = {200,200}
    CETWM.windows[name].isCollapsed = false
    CETWM.windows[name].visible = true
    settingsInst:update(CETWM.windows, "windows")
    showWindow(name)
end

---@param name string
---@return void
local function toggleLock(name)
    table.insert(deferredLock, name)
end

---@param name string
---@return void
local function toggleLockProcessPt2(name)
    table.insert(deferredLockPt2, name)
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
    settingsInst:update(CETWM.windows, "windows")
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
    settingsInst:update(CETWM.windows, "windows")
end

---@return void
local function addWindowName()
    local adjustedWindowName = utils.adjustWindowName(windowName)
    if not (CETWM.windows[adjustedWindowName] == nil) then
        popUpBannedText = string.format("%s %s", windowName, localizationInst.localization_strings.alreadyManaged)
        return
    end

    if utils.isBanned(windowName) then
        popUpBannedText = string.format("%s %s", windowName, localizationInst.localization_strings.disallowedName)
        return
    end

    local newIndex = utils.tableLength(CETWM.windows) + 1
    CETWM.windows[utils.adjustWindowName(adjustedWindowName)] = {visible = true, lastPos = {x = 100, y = 100}, isCollapsed = false, index = newIndex, locked = false}
    settingsInst:update(CETWM.windows, "windows")
    popUpBannedText = ""
    windowName = ""
    ImGui.CloseCurrentPopup()
end


---@return void
local function processDeferred()
    for _, name in ipairs(deferredHide) do
        hideWindowProcess(name)
    end
    deferredHide = {} 

    for _, name in ipairs(deferredLock) do
        toggleLockProcess(name)
    end
    deferredLock = {}  

    for _, name in ipairs(deferredShow) do
        showWindowProcess(name)
    end
    deferredShow = {} 

    for _, name in ipairs(deferredLockPt2) do
        toggleLockProcessPt2Process(name)
    end
    deferredLockPt2 = {}

    for _, name in ipairs(deferredRemoval) do
        removeWindowProcessing(name)
    end
    deferredRemoval = {}
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
        settingsInst:update(CETWM.windows, "windows")
    end
end

---@return void
local function drawUnomittedWindows()
    CETWM.minWidth = utils.longestStringLenghtPX(CETWM.windows)
    local sortedWindows = utils.sortTable(CETWM.windows)

    local onlyUnomitedWindows = {}
    for _, window in ipairs(sortedWindows) do
        if not window.state.disabled then
            table.insert(onlyUnomitedWindows, window)
        end
    end

    local topY
    local itemHeight

    for i, window in ipairs(onlyUnomitedWindows) do
        ImGui.PushID(i)

        ImGui.BeginGroup()

        local name = window.name
        local state = window.state

        if state.locked then
            styles.button_styled_light()
        else
            styles.button_styled_dark()
        end


        if ImGui.Button(string.format("%s##%s", (state.locked and IconGlyphs.Lock or IconGlyphs.LockOpenVariant), name)) then
            toggleLock(name)
        end

        -- Get the bounding box of the item
        local sideButtonX1, sideButtonY1 = ImGui.GetItemRectMin()
        local sideButtonX2, sideButtonY2 = ImGui.GetItemRectMax()
        sideButtonWidth = (sideButtonX2 - sideButtonX1) + ImGui.GetStyle().ItemSpacing.x

        ImGui.PopStyleColor(3)
        ImGui.SameLine()

        if state.visible then
            styles.button_styled_light()
        else
            styles.button_styled_dark()
        end
        
        if ImGui.Button(name, CETWM.minWidth, 0) then
            if not (name == localizationInst.localization_strings.modName) then
                state.visible = not state.visible 
                settingsInst:update(CETWM.windows, "windows")
                if not state.visible then
                    hideWindow(name)
                else 
                    showWindow(name)
                end
            end
        end
        ImGui.PopStyleColor(3)

        if (ImGui.BeginPopupContextItem("Window Context Menu##" .. window.name, ImGuiPopupFlags.MouseButtonRight)) then
            ImGui.Text(string.match(name, "^(.-)##") or name)
            if ImGui.Button(IconGlyphs.Cached .. localizationInst.localization_strings.resetWindow .. "##" .. window.name) then
                resetWindow(window.name)
            end

            if (not (window.name == localizationInst.localization_strings.modName)) then
                if ImGui.Button(IconGlyphs.EyeOff .. localizationInst.localization_strings.omit .. "##" .. window.name) then
                    CETWM.windows[window.name].disabled = true
                    settingsInst:update(CETWM.windows, "windows")
                end 
            end

            ImGui.EndPopup()
        end
        ImGui.EndGroup()

        -- Get the bounding box of the item
        local item_x1, item_y1 = ImGui.GetItemRectMin()
        local item_x2, item_y2 = ImGui.GetItemRectMax()
        local item_height = item_y2 - item_y1
        item_height = item_height + ImGui.GetStyle().ItemSpacing.y
        
        topY = topY or item_y1
        itemHeight = itemHeight or item_height

        -- Start dragging
        if ImGui.IsItemActive() and ImGui.IsMouseDragging(0) then
            if not dragging_index then
                dragging_index = i
            end
        end

        ImGui.PopID()
    end

    -- Handle drop
    if dragging_index and not ImGui.IsMouseDragging(0) then
        local insert_index = nil
        local mouse_x, mouse_y = ImGui.GetMousePos()
        insert_index = math.floor(((mouse_y - topY) / itemHeight) + 0.5) + 1

        if insert_index < 1 then
            insert_index = 1
        elseif insert_index > utils.tableLength(onlyUnomitedWindows) then
            insert_index = utils.tableLength(onlyUnomitedWindows)
        end

        if insert_index then
            local dragged_item = table.remove(onlyUnomitedWindows, dragging_index)
            table.insert(onlyUnomitedWindows, insert_index, dragged_item)

            for i, window in ipairs(onlyUnomitedWindows) do
                CETWM.windows[window.name].index = i
            end
        end

        settingsInst:update(CETWM.windows, "windows")
        dragging_index = nil
    end

end

---@return void
local function drawOmittedWindows()
    CETWM.minWidth = utils.longestStringLenghtPX(CETWM.windows)
    local sortedWindows = utils.sortTable(CETWM.windows)

    local onlyOmitedWindows = {}
    for _, window in ipairs(sortedWindows) do
        if window.state.disabled then
            table.insert(onlyOmitedWindows, window)
        end
    end

    for i, window in ipairs(onlyOmitedWindows) do
            styles.button_styled_dark()
            ImGui.Button(window.name, (CETWM.minWidth + sideButtonWidth), 0)
            ImGui.PopStyleColor(3)

            if (ImGui.BeginPopupContextItem("Window Context Menu##" .. window.name, ImGuiPopupFlags.MouseButtonRight)) then
                ImGui.Text(string.match(window.name, "^(.-)##") or window.name)
                if ImGui.Button(IconGlyphs.Eye .. localizationInst.localization_strings.unomit .. "##" .. window.name) then
                    CETWM.windows[window.name].disabled = false
                    settingsInst:update(CETWM.windows, "windows")
                end
                ImGui.EndPopup()
            end
        end
end

---@return void
local function manageWindowsTab()
    if ImGui.BeginTabBar("WindowManagerTabBar") then
        if ImGui.BeginTabItem(localizationInst.localization_strings.UnomittedWindows) then
            drawUnomittedWindows()
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem(localizationInst.localization_strings.OmittedWindows) then
            drawOmittedWindows()
            ImGui.EndTabItem()
        end
        ImGui.EndTabBar()
    end
end

---@return void
local function initWindowManagerWindows()
    if CETWM.windows[localizationInst.localization_strings.modName] == nil then
        local newIndex = utils.tableLength(CETWM.windows) + 1
        CETWM.windows[localizationInst.localization_strings.modName] = {visible = true, lastPos = {x = 100, y = 100}, isCollapsed = false, index = newIndex, locked = false, lastSize = {1,1}}
        settingsInst:update(CETWM.windows, "windows")
    end
end

---@param oldName string
---@return void
local function requestSwitchWindowName(oldName)
    requestedNameSwitch = oldName
    requestWindowPos = true
end

---@return void
local function modSettingsTab()
    if ImGui.Button(localizationInst.localization_strings.loadWindows) then
        loadWindowsFromFile();
    end

    if ImGui.BeginMenu(localizationInst.localization_strings.localization) then
        for _, language in ipairs(localizationInst.all_localizations) do
            if ImGui.Selectable(language) then
                if language == settingsInst.settings.localization then
                    goto continue
                end
                requestSwitchWindowName(localizationInst.localization_strings.modName)
                requestedLanguageSwitch = language
                ::continue::
            end
        end
        ImGui.EndMenu()
    end

    ImGui.Text(localizationInst.localization_strings.version .. ": " .. version)
    ImGui.SameLine()
    ImGui.Text(localizationInst.localization_strings.by .. ": sprt_")
end



registerForEvent('onInit', function() 
    if checkPackages() == false then
        print("ERROR: Window Manager failed to intilize packages!")
        spdlog.error("ERROR: Window Manager failed to intilize packages!")
        return 
    end

    settingsInst = settings:getInstance()
    localizationInst = localizationService:getInstance()
    if not localizationInst then
        logger:error("ERROR: Window Manager failed to intilize localization service!")
        return
    end
    CETWM.ready = true
    CETWM.windows = settingsInst.windows
    initWindowManagerWindows()
    logger:info(localizationInst.localization_strings.finalInit)
end)

registerForEvent("onOverlayOpen", function()
    CETWM.overlayOpen = true
end)

registerForEvent("onOverlayClose", function()
    CETWM.overlayOpen = false
end)

registerForEvent("onDraw", function()
    if not CETWM.overlayOpen then return end
    if not CETWM.ready then return end

    if framesToWaitBeforeLoading >= 0 then
        framesToWaitBeforeLoading = framesToWaitBeforeLoading - 1
        if framesToWaitBeforeLoading == 0 then
            loadWindowsFromFile()
        end
    end

    local WMFlags = bit32.bor(ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoScrollbar)
    if ImGui.Begin(localizationInst.localization_strings.modName, true, WMFlags) then
        if (deferredSetSelfPos[1] or deferredSetSelfPos[2]) then
            ImGui.SetWindowPos(deferredSetSelfPos[1], deferredSetSelfPos[2])
            deferredSetSelfPos = {}
        end
        if requestWindowPos then
            localizationInst:setLocalization(requestedLanguageSwitch)
            local curPosX, curPosY = ImGui.GetWindowPos()
            table.insert(deferredSetSelfPos, curPosX)
            table.insert(deferredSetSelfPos, curPosY)
            CETWM.windows[localizationInst.localization_strings.modName] = CETWM.windows[requestedNameSwitch]
            CETWM.windows[requestedNameSwitch] = nil
            settingsInst:update(CETWM.windows, "windows")
            requestWindowPos = false
        end
        if ImGui.BeginTabBar("TabList1") then
            if ImGui.BeginTabItem(localizationInst.localization_strings.tabToggle) then
                manageWindowsTab()
                ImGui.EndTabItem()
            end
            if ImGui.BeginTabItem(localizationInst.localization_strings.tabSettings) then
                modSettingsTab()
                ImGui.EndTabItem()
            end
            ImGui.EndTabBar()
        end
        ImGui.End()
    end
    -- all of these functions *HAVE* to be at the end of the draw call otherwise you will get flickering in the UI 
    ---> don't call `ImGui.Begin()` while within another `ImGui.Begin()`
    lockWindowLoop()
    processDeferred()
end)
