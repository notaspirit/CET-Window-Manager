local utils = require('modules/utils')
local settings = require('modules/jsonUtils')

-- mod info
CETWM = {
    ready = false,
    windows = {}, -- Store window states: {name = {visible = bool, lastPos = {x,y}, isCollapsed = bool}}
    -- this table now acts are the "working" or temp dir that then gets merged into the settingService and saved
    overlayOpen = false,
    minWidth = 0
}

local settingsInst = settings:getInstance()
local windowName = ""
local popUpBannedText = ""


-- onInit event
registerForEvent('onInit', function() 
    -- set as ready
    CETWM.ready = true
    CETWM.windows = settingsInst.windows
end)

registerForEvent("onOverlayOpen", function()
    CETWM.overlayOpen = true
end)

registerForEvent("onOverlayClose", function()
    CETWM.overlayOpen = false
end)

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
    CETWM.windows[name].lastPos = {x,y}
    CETWM.windows[name].isCollapsed = isCollapsed
    settingsInst.update(CETWM.windows)
end

---@param name string
---@param metadata table
local function showWindow(name, metadata)
    if ImGui.Begin(name, true) then
        ImGui.SetWindowPos(metadata.lastPos[1], metadata.lastPos[2])
    end
    if CETWM.windows[name].isCollasped then
        if ImGui.Begin(name, false) then
            local s = 1
        end
    end

end

---@param name string
---@param metadata table
local function resetWindow(name, metadata)
    CETWM.windows[name].lastPos = {200,200}
    CETWM.windows[name].isCollasped = false
    CETWM.windows[name].visible = true
    settingsInst.update(CETWM.windows)
    showWindow(name, CETWM.windows[name])
end

local function addWindowTab()
    if ImGui.Button("Add Window") then
        ImGui.OpenPopup("Add Window")
    end
    if ImGui.BeginPopup("Add Window") then
        windowName, text_input_active = ImGui.InputText("Window Name", windowName, 100)
        if ImGui.Button("Add") then
            if not utils.isBanned(windowName) then
                CETWM.windows[utils.adjustWindowName(windowName)] = {visible = true, lastPos = {x = 100, y = 100}, isCollapsed = false}
                settingsInst.update(CETWM.windows)
                popUpBannedText = ""
                windowName = ""
                ImGui.CloseCurrentPopup()
            else
                popUpBannedText = string.format("%s is not an allowed Window Name!", windowName)
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
    ImGui.TextWrapped("Add Windows here by their display name. Disregard icons if they have any.")
    ImGui.TextWrapped("If the window doesn't get affected despite being properly spelled (it's case sensitive), report it so it can be fixed.")
    for name, state in pairs(CETWM.windows) do
        if ImGui.Button(IconGlyphs.Close .. "##" .. name) then
            CETWM.windows[name] = nil
            settingsInst.update(CETWM.windows)
        end
        ImGui.SameLine()
        if ImGui.Button(IconGlyphs.Cached .. "##" .. name) then
            resetWindow(name, state)
        end
        ImGui.SameLine()
        ImGui.Text(name)
    end 
end

local function manageWindowsTab()
    CETWM.minWidth = utils.longestStringLenghtPX(CETWM.windows)

    -- colors for when the window is visible
    r = 0.22
    g = 0.48
    b = 0.8
    for name, state in pairs(CETWM.windows) do
        if state.visible then
            -- Light color when enabled (you can adjust these RGB values)
            ImGui.PushStyleColor(ImGuiCol.Button, r, g, b, 1.0)
            ImGui.PushStyleColor(ImGuiCol.ButtonHovered, r*1.2, g*1.2, b*1.2, 1.0)
            ImGui.PushStyleColor(ImGuiCol.ButtonActive, r*0.8, g*0.8, b*0.8, 1.0)
        else
            -- Dark color when disabled
            ImGui.PushStyleColor(ImGuiCol.Button, 0.2, 0.2, 0.2, 1.0)
            ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 0.3, 0.3, 0.3, 1.0)
            ImGui.PushStyleColor(ImGuiCol.ButtonActive, 0.4, 0.4, 0.4, 1.0)
        end
        
        if ImGui.Button(name, CETWM.minWidth, 0) then
            state.visible = not state.visible  -- Toggle visibility
            settingsInst.update(CETWM.windows)
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
    if ImGui.Begin("Window Manager", true, ImGuiWindowFlags.NoScrollbar) then
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
