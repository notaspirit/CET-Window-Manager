local windowManager = require("modules/windowManager")
local utils = require("modules/utils")
local styles = require("data/styles")
local logger = require("modules/logger")

local dragging_index = nil
local dragging_section = nil  -- "favorites" or "regular"
local cachedFavorites = {}
local cachedRegular = {}
local cachedFilteredFavorites = {}
local cachedFilteredRegular = {}
local cachedSearchQuery = ""
local cacheInvalid = true

local widestSettingsLabel = nil

local function calculateButtonWidth(isOmitted)
    if CETWM.settingsInst.settings.allow_window_resizing then
        local availWidth = ImGui.GetContentRegionAvail()
        local padding = ImGui.GetStyle().FramePadding.x * 2
        local itemSpacing = ImGui.GetStyle().ItemSpacing.x
        local iconGlphyWidth, _ = ImGui.CalcTextSize(IconGlyphs.Star)
        if not isOmitted then
            return math.max(0, availWidth - padding - (itemSpacing * 3) - (iconGlphyWidth * 2))
        else
            return math.max(0, availWidth)
        end
    else
        return utils.longestStringLenghtPX(CETWM.windows, true)
    end
end

---@return void
local function modSettingsTab()
    if not widestSettingsLabel then
        widestSettingsLabel = math.max(
            ImGui.CalcTextSize(CETWM.localizationInst.localization_strings.allowWindowResizing),
            ImGui.CalcTextSize(CETWM.localizationInst.localization_strings.hideScrollbar)
        )
    end

    ImGui.Text(CETWM.localizationInst.localization_strings.hideScrollbar)
    ImGui.SameLine()
    ImGui.SetCursorPosX(widestSettingsLabel + 30)
    CETWM.settingsInst.settings.hide_scrollbar = ImGui.Checkbox("##hideScrollbar", CETWM.settingsInst.settings.hide_scrollbar)

    ImGui.Text(CETWM.localizationInst.localization_strings.allowWindowResizing)
    ImGui.SameLine()
    ImGui.SetCursorPosX(widestSettingsLabel + 30)
    CETWM.settingsInst.settings.allow_window_resizing = ImGui.Checkbox("##allowWindowResizing", CETWM.settingsInst.settings.allow_window_resizing)
    
    ImGui.Separator()

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
                widestSettingsLabel = nil
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
    CETWM.minWidth = calculateButtonWidth(false)

    local sortedWindows = utils.sortTable(CETWM.windows)

    -- Separate non-omitted windows into favorites and regular
    local onlyUnomitedWindows = {}
    for _, window in ipairs(sortedWindows) do
        if not window.state.disabled then
            table.insert(onlyUnomitedWindows, window)
        end
    end

    if (cacheInvalid) then
        -- If cache is invalid, recalculate favorites and regular lists
        cachedFavorites = {}
        cachedRegular = {}
        
        local favoritesList = {}
        local regularList = {}
        
        for _, window in ipairs(onlyUnomitedWindows) do
            if window.state.favorite then
                table.insert(favoritesList, window)
            else
                table.insert(regularList, window)
            end
        end
        
        -- Sort each list by index
        table.sort(favoritesList, function(a, b) return (a.state.favoritesIndex or a.state.index) < (b.state.favoritesIndex or b.state.index) end)
        table.sort(regularList, function(a, b) return a.state.index < b.state.index end)
        
        cachedFavorites = favoritesList
        cachedRegular = regularList
    end
    
    -- Search and sort controls
    local availWidth = ImGui.GetContentRegionAvail()
    local sortAZWidth, _ = ImGui.CalcTextSize(CETWM.localizationInst.localization_strings.sortAZ)
    local sortZAWidth, _ = ImGui.CalcTextSize(CETWM.localizationInst.localization_strings.sortZA)
    local iconGlphyWidth, _ = ImGui.CalcTextSize(IconGlyphs.Star)
    local framePadding = ImGui.GetStyle().FramePadding
    local itemSpacing = ImGui.GetStyle().ItemSpacing
    
    -- Calculate button widths (text + padding on both sides)
    local buttonAZWidth = sortAZWidth + framePadding.x
    local buttonZAWidth = sortZAWidth + framePadding.x
    local buttonIconWidth = iconGlphyWidth + framePadding.x
    
    -- Calculate input width: available - 2 buttons - spacing between elements
    local inputWidth = availWidth - buttonAZWidth - buttonZAWidth - itemSpacing.x * 3
    
    ImGui.SetNextItemWidth(inputWidth)
    CETWM.searchQuery, _ = ImGui.InputTextWithHint("##UnomittedWindowsSearch", CETWM.localizationInst.localization_strings.search, CETWM.searchQuery, 1024)
    ImGui.SameLine()
    
    if ImGui.Button(CETWM.localizationInst.localization_strings.sortAZ) then
        -- Sort both sections by name
        table.sort(cachedFavorites, function(a, b) return a.name < b.name end)
        table.sort(cachedRegular, function(a, b) return a.name < b.name end)
        
        -- Update favoritesIndex for favorites section
        for i, window in ipairs(cachedFavorites) do
            CETWM.windows[window.name].favoritesIndex = i
        end
        
        -- Update index for regular section  
        for i, window in ipairs(cachedRegular) do
            CETWM.windows[window.name].index = i
        end
        
        CETWM.settingsInst:update(CETWM.windows, "windows")
        cacheInvalid = true
    end
    
    ImGui.SameLine()
    if ImGui.Button(CETWM.localizationInst.localization_strings.sortZA) then
        -- Sort both sections by name in reverse
        table.sort(cachedFavorites, function(a, b) return a.name > b.name end)
        table.sort(cachedRegular, function(a, b) return a.name > b.name end)
        
        -- Update favoritesIndex for favorites section
        for i, window in ipairs(cachedFavorites) do
            CETWM.windows[window.name].favoritesIndex = i
        end
        
        -- Update index for regular section
        for i, window in ipairs(cachedRegular) do
            CETWM.windows[window.name].index = i
        end
        
        CETWM.settingsInst:update(CETWM.windows, "windows")
        cacheInvalid = true
    end

    if CETWM.searchQuery ~= cachedSearchQuery or cacheInvalid then
        -- Search query changed or cache invalidated, recalculate filtered windows
        cachedSearchQuery = CETWM.searchQuery
        cacheInvalid = false
        cachedFilteredFavorites = {}
        cachedFilteredRegular = {}
        local searchLower = CETWM.searchQuery:lower()
        
        for _, window in ipairs(cachedFavorites) do
            if searchLower == "" or window.name:lower():find(searchLower, 1, true) then
                table.insert(cachedFilteredFavorites, window)
            end
        end
        
        for _, window in ipairs(cachedRegular) do
            if searchLower == "" or window.name:lower():find(searchLower, 1, true) then
                table.insert(cachedFilteredRegular, window)
            end
        end
    end

    -- Helper function to draw a section
    local function drawWindowsSection(sectionWindows, isFavorite)

        if isFavorite then
            styles.button_styled_light()
        else
            styles.button_styled_dark()
        end

        if ImGui.Button(string.format("%s##fav_%s", (isFavorite and IconGlyphs.Star or IconGlyphs.StarOutline), (isFavorite and "toggleAllFavoritesPlaceHolder" or "toggleAllRegularPlaceHolder"))) then
            windowManager.toggleAllFavorites(sectionWindows, isFavorite, not isFavorite)
            cacheInvalid = true
        end
        ImGui.PopStyleColor(3)
        ImGui.SameLine()

        -- Check states for this section
        local allLocked = true
        local allVisible = true
        for _, window in ipairs(sectionWindows) do
            if not window.state.locked then
                allLocked = false
            end
            if not window.state.visible then
                allVisible = false
            end
        end
        
        -- Toggle all lock button
        if allLocked then
            styles.button_styled_light()
        else
            styles.button_styled_dark()
        end
        
        local lockButtonLabel = isFavorite and (allLocked and IconGlyphs.Lock or IconGlyphs.LockOpenVariant) .. "##toggleAllLockFavorites" or (allLocked and IconGlyphs.Lock or IconGlyphs.LockOpenVariant) .. "##toggleAllLock"
        if ImGui.Button(lockButtonLabel) then
            windowManager.toggleAllLocks(sectionWindows, not allLocked)
        end
        ImGui.PopStyleColor(3)
        ImGui.SameLine()
        
        -- Toggle all visibility button
        if allVisible then
            styles.button_styled_light()
        else
            styles.button_styled_dark()
        end
        
        local toggleLabel = isFavorite and "Toggle All##toggleAllVisibilityFavorites" or "Toggle All##toggleAllVisibility"
        if ImGui.Button(toggleLabel, CETWM.minWidth, 0) then
            windowManager.toggleAllVisibility(sectionWindows, not allVisible)
        end
        ImGui.PopStyleColor(3)

        ImGui.Separator()

        local topY
        local itemHeight

        for i, window in ipairs(sectionWindows) do
            ImGui.PushID((isFavorite and "fav_" or "reg_") .. i)

            ImGui.BeginGroup()

            local name = window.name
            local state = window.state
            
            -- Favorite button
            if state.favorite then
                styles.button_styled_light()
            else
                styles.button_styled_dark()
            end

            if ImGui.Button(string.format("%s##fav_%s", (state.favorite and IconGlyphs.Star or IconGlyphs.StarOutline), name)) then
                windowManager.toggleFavorite(name)
                cacheInvalid = true
            end

            ImGui.PopStyleColor(3)
            ImGui.SameLine()

             -- Lock button
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
                    cacheInvalid = true
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
                        cacheInvalid = true
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
                    dragging_section = isFavorite and "favorites" or "regular"
                end
            end

            ImGui.PopID()
        end

        -- Handle drop
        if dragging_index and dragging_section == (isFavorite and "favorites" or "regular") and not ImGui.IsMouseDragging(0) then
            local insert_index = nil
            local mouse_x, mouse_y = ImGui.GetMousePos()
            insert_index = math.floor(((mouse_y - topY) / itemHeight) + 0.5) + 1

            if insert_index < 1 then
                insert_index = 1
            elseif insert_index > utils.tableLength(sectionWindows) then
                insert_index = utils.tableLength(sectionWindows)
            end

            if insert_index then
                local dragged_item = table.remove(sectionWindows, dragging_index)
                table.insert(sectionWindows, insert_index, dragged_item)

                -- Update indices based on section
                if isFavorite then
                    for i, window in ipairs(sectionWindows) do
                        CETWM.windows[window.name].favoritesIndex = i
                    end
                else
                    for i, window in ipairs(sectionWindows) do
                        CETWM.windows[window.name].index = i
                    end
                end
            end

            CETWM.settingsInst:update(CETWM.windows, "windows")
            dragging_index = nil
            dragging_section = nil
        end

        return topY, itemHeight
    end

    local fullWidthButton = availWidth

    -- Draw Favorites Section
    if utils.tableLength(cachedFilteredFavorites) > 0 then
        ImGui.BeginGroup()
        ImGui.Button(CETWM.localizationInst.localization_strings.favorites .. "##favorites", fullWidthButton, 0)
        ImGui.EndGroup()
        drawWindowsSection(cachedFilteredFavorites, true)
        ImGui.Separator()
    end

    -- Draw Regular Windows Section
    ImGui.BeginGroup()
    if utils.tableLength(cachedFilteredFavorites) > 0 then
        ImGui.Button(CETWM.localizationInst.localization_strings.windows .. "##windows", fullWidthButton, 0)
    end
    ImGui.EndGroup()
    drawWindowsSection(cachedFilteredRegular, false)

    -- Reset dragging if mouse was released and no drop occurred
    if dragging_index and not ImGui.IsMouseDragging(0) then
        dragging_index = nil
        dragging_section = nil
    end
end

---@return void
local function drawOmittedWindows()
    CETWM.minWidth = calculateButtonWidth(true)
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
                cacheInvalid = true
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

    local WMFlags = bit32.bor(
        CETWM.settingsInst.settings.allow_window_resizing and 0 or ImGuiWindowFlags.AlwaysAutoResize,
        CETWM.settingsInst.settings.hide_scrollbar and ImGuiWindowFlags.NoScrollbar or 0
        )
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