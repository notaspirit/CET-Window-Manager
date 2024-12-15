local utils = require("modules/utils")
local settingsService = require("modules/settings")

-- mod info
CETWM = {
    ready = false,
    windows = {}, -- Store window states: {name = {visible = bool, lastPos = {x,y}, isCollapsed = bool}}
    overlayOpen = false,
    minWidth = 100
}

local settingsInst = settingsService.getInstance()
local windowName = ""
local popUpBannedText = ""

-- print on load
print('My Mod is loaded!')

-- onInit event
registerForEvent('onInit', function() 
    -- set as ready
    CETWM.ready = true
    -- print on initialize
    print('My Mod is initialized!')
end)

registerForEvent("onOverlayOpen", function()
    CETWM.overlayOpen = true
end)

registerForEvent("onOverlayClose", function()
    CETWM.overlayOpen = false
end)

local function addWindowTab()
    if ImGui.Button("Add Window") then
        ImGui.OpenPopup("Add Window")
    end
    if ImGui.BeginPopup("Add Window") then
        windowName, text_input_active = ImGui.InputText("Window Name", windowName, 100)
        if ImGui.Button("Add") then
            print("Add Button Pressed")
            print("Input is " .. windowName)
            if not utils.isBanned(windowName) then
                print("Input is Valid!")
                CETWM.windows[utils.adjustWindowName(windowName)] = {visible = true, lastPos = {x = 100, y = 100}, isCollapsed = false}
                popUpBannedText = ""
                windowName = ""
                ImGui.CloseCurrentPopup()
            else
                print("Input is not valid!")
                popUpBannedText = string.format("%s is not an allowed Window Name!", windowName)
                print(popUpBannedText)
                end
        end
        ImGui.SameLine()
        if ImGui.Button("Close") then
            ImGui.CloseCurrentPopup()
        end
        ImGui.SameLine()
        ImGui.Text(popUpBannedText)
        ImGui.EndPopup()
    end
    for name, state in pairs(CETWM.windows) do
        if ImGui.Button("Remove##" .. name) then
            CETWM.windows[name] = nil
        end
        ImGui.SameLine()
        ImGui.Text(name)
    end
end

---@param name string
---@param metadata table
local function hideWindow(name, metadata)
    local x, y
    local isCollapsed = false
    if ImGui.Begin(name, true) then
        isCollapsed = ImGui.IsWindowCollapsed()
        x, y = ImGui.GetWindowPos()
        ImGui.SetWindowPos(10000, 10000)
    end
    print("Got Current Pos: X: %d, Y: %d", x, y)
    CETWM.windows[name].lastPos = {x,y}
    CETWM.windows[name].isCollapsed = isCollapsed
end

---@param name string
---@param metadata table
local function showWindow(name, metadata)
    print("Finished loading lastPos:", metadata.lastPos[1], metadata.lastPos[2])
    if ImGui.Begin(name, true) then
        ImGui.SetWindowPos(metadata.lastPos[1], metadata.lastPos[2])
    end
    if CETWM.windows[name].isCollasped then
        if ImGui.Begin(name, false) then
            local s = 1
        end
    end

end

local function manageWindowsTab()
    for name, state in pairs(CETWM.windows) do
        if state.visible then
            -- Light color when enabled (you can adjust these RGB values)
            ImGui.PushStyleColor(ImGuiCol.Button, 0.4, 0.4, 0.4, 1.0)
            ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 0.5, 0.5, 0.5, 1.0)
            ImGui.PushStyleColor(ImGuiCol.ButtonActive, 0.6, 0.6, 0.6, 1.0)
        else
            -- Dark color when disabled
            ImGui.PushStyleColor(ImGuiCol.Button, 0.2, 0.2, 0.2, 1.0)
            ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 0.3, 0.3, 0.3, 1.0)
            ImGui.PushStyleColor(ImGuiCol.ButtonActive, 0.4, 0.4, 0.4, 1.0)
        end
        
        ImGui.PushItemWidth(CETWM.minWidth)
        if ImGui.Button(name) then
            state.visible = not state.visible  -- Toggle visibility
            if not state.visible then
                hideWindow(name, state)
            else 
                showWindow(name, state)
            end
        end
        
        ImGui.PopStyleColor(3)  -- Pop all 3 style colors we pushed
    end
end

-- onDraw event to render ImGui windows
registerForEvent("onDraw", function()
    if not CETWM.overlayOpen then return end
    if ImGui.Begin("Window Manager", true, ImGuiWindowFlags.None) then
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
end)
