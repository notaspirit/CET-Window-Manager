local windowManager = require("modules/windowManager")
local utils = require("modules/utils")
local styles = require("data/styles")
local logger = require("modules/logger")

local dragging_index = nil

---@return void
local function modSettingsTab()
    if ImGui.Button(CETWM.localizationInst.localization_strings.loadWindows) then
        windowManager.loadWindowsFromFile();
    end

    if ImGui.BeginMenu(CETWM.localizationInst.localization_strings.localization) then
        for _, language in ipairs(CETWM.localizationInst.all_localizations) do
            if ImGui.Selectable(language) then
                if language == CETWM.settingsInst.settings.localization then
                    goto continue
                end
                windowManager.requestSwitchWindowName(CETWM.localizationInst.localization_strings.modName)
                CETWM.requestedLanguageSwitch = language
                ::continue::
            end
        end
        ImGui.EndMenu()
    end

    ImGui.Text(CETWM.localizationInst.localization_strings.version .. ": " .. CETWM.version)
    ImGui.SameLine()
    ImGui.Text(CETWM.localizationInst.localization_strings.by .. ": sprt_")
end


---@return void
local function drawUnomittedWindows()
    CETWM.minWidth = utils.longestStringLenghtPX(CETWM.windows, false)
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
            windowManager.toggleLock(name)
        end

        ImGui.PopStyleColor(3)
        ImGui.SameLine()

        if state.visible then
            styles.button_styled_light()
        else
            styles.button_styled_dark()
        end
        
        if ImGui.Button(utils.getWindowDisplayName(window.name), CETWM.minWidth, 0) then
            if not (name == CETWM.localizationInst.localization_strings.modName) then
                state.visible = not state.visible 
                CETWM.settingsInst:update(CETWM.windows, "windows")
                if not state.visible then
                    windowManager.hideWindow(name)
                else 
                    windowManager.showWindow(name)
                end
            end
        end
        ImGui.PopStyleColor(3)

        if (ImGui.BeginPopupContextItem("Window Context Menu##" .. window.name, ImGuiPopupFlags.MouseButtonRight)) then
            ImGui.Text(utils.getWindowDisplayName(window.name))
            if ImGui.Button(IconGlyphs.Cached .. CETWM.localizationInst.localization_strings.resetWindow .. "##" .. utils.getWindowDisplayName(window.name)) then
                windowManager.resetWindow(window.name)
            end

            if (not (window.name == CETWM.localizationInst.localization_strings.modName)) then
                if ImGui.Button(IconGlyphs.EyeOff .. CETWM.localizationInst.localization_strings.omit .. "##" .. utils.getWindowDisplayName(window.name)) then
                    CETWM.windows[window.name].disabled = true
                    CETWM.settingsInst:update(CETWM.windows, "windows")
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

        CETWM.settingsInst:update(CETWM.windows, "windows")
        dragging_index = nil
    end

end

---@return void
local function drawOmittedWindows()
    CETWM.minWidth = utils.longestStringLenghtPX(CETWM.windows, true)
    local sortedWindows = utils.sortTableByName(CETWM.windows)

    local onlyOmitedWindows = {}
    for _, window in ipairs(sortedWindows) do
        if window.state.disabled then
            table.insert(onlyOmitedWindows, window)
        end
    end

    for i, window in ipairs(onlyOmitedWindows) do
        styles.button_styled_dark()
        ImGui.Button(utils.getWindowDisplayName(window.name), CETWM.minWidth, 0)
        ImGui.PopStyleColor(3)

        if (ImGui.BeginPopupContextItem("Window Context Menu##" .. utils.getWindowDisplayName(window.name), ImGuiPopupFlags.MouseButtonRight)) then
            ImGui.Text(utils.getWindowDisplayName(window.name))
            if ImGui.Button(IconGlyphs.Eye .. CETWM.localizationInst.localization_strings.unomit .. "##" .. utils.getWindowDisplayName(window.name)) then
                CETWM.windows[window.name].disabled = false
                CETWM.settingsInst:update(CETWM.windows, "windows")
            end
            ImGui.EndPopup()
        end
    end
end

---@return void
local function manageWindowsTab()
    if ImGui.BeginTabBar("WindowManagerTabBar") then
        if ImGui.BeginTabItem(CETWM.localizationInst.localization_strings.UnomittedWindows) then
            drawUnomittedWindows()
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem(CETWM.localizationInst.localization_strings.OmittedWindows) then
            drawOmittedWindows()
            ImGui.EndTabItem()
        end
        ImGui.EndTabBar()
    end
end

---@return void
local function drawUI()
    local WMFlags = bit32.bor(ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoScrollbar)
    if ImGui.Begin(CETWM.localizationInst.localization_strings.modName, true, WMFlags) then
        if (CETWM.deferredSetSelfPos[1] or CETWM.deferredSetSelfPos[2]) then
            ImGui.SetWindowPos(CETWM.deferredSetSelfPos[1], CETWM.deferredSetSelfPos[2])
            CETWM.deferredSetSelfPos = {}
        end
        if CETWM.requestWindowPos then
            CETWM.localizationInst:setLocalization(CETWM.requestedLanguageSwitch)
            local curPosX, curPosY = ImGui.GetWindowPos()
            table.insert(CETWM.deferredSetSelfPos, curPosX)
            table.insert(CETWM.deferredSetSelfPos, curPosY)
            CETWM.windows[CETWM.localizationInst.localization_strings.modName] = CETWM.windows[CETWM.requestedNameSwitch]
            CETWM.windows[CETWM.requestedNameSwitch] = nil
            CETWM.settingsInst:update(CETWM.windows, "windows")
            CETWM.requestWindowPos = false
        end
        if ImGui.BeginTabBar("TabList1") then
            if ImGui.BeginTabItem(CETWM.localizationInst.localization_strings.tabToggle) then
                manageWindowsTab()
                ImGui.EndTabItem()
            end
            if ImGui.BeginTabItem(CETWM.localizationInst.localization_strings.tabSettings) then
                modSettingsTab()
                ImGui.EndTabItem()
            end
            ImGui.EndTabBar()
        end
        ImGui.End()
    end
end

---@return void 
local function drawFailedInitUI()
    local WMFlags = bit32.bor(ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoScrollbar)
    if ImGui.Begin(CETWM.localizationInst.localization_strings.modName, true, WMFlags) then
        ImGui.Text(CETWM.localizationInst.localization_strings.failedToLoadRedCetWM)
        ImGui.End()
    end
end

return {
    drawUI = drawUI,
    drawFailedInitUI = drawFailedInitUI,
}