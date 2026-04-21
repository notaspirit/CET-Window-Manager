local windowManager = require("modules/windowManager")
local utils = require("modules/utils")
local styles = require("data/styles")
local logger = require("modules/logger")

local dragging_index = nil
local dragging_section = nil  -- "favorites" or "regular"
local drag_drop_line_y = nil  -- Y position for the drop indicator line
local drag_item_name = nil  -- Name of item being dragged
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
            -- Skip rendering the dragged item
            local is_dragging_this_item = dragging_index == i and dragging_section == (isFavorite and "favorites" or "regular")
            
            if not is_dragging_this_item then
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
                        drag_item_name = window.name
                    end
                end

                ImGui.PopID()
            end
        end

        -- Calculate drop line position if dragging
        if dragging_index and dragging_section == (isFavorite and "favorites" or "regular") and ImGui.IsMouseDragging(0) then
            local mouse_x, mouse_y = ImGui.GetMousePos()
            local drop_index = math.floor(((mouse_y - topY) / itemHeight) + 0.5) + 1
            
            if drop_index < 1 then
                drop_index = 1
            elseif drop_index > utils.tableLength(sectionWindows) then
                drop_index = utils.tableLength(sectionWindows)
            end
            
            -- Calculate the Y position for the drop line
            if drop_index <= utils.tableLength(sectionWindows) then
                drag_drop_line_y = topY + (drop_index - 1) * itemHeight
            else
                drag_drop_line_y = topY + (utils.tableLength(sectionWindows)) * itemHeight
            end
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
            drag_drop_line_y = nil
            drag_item_name = nil
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
        drag_drop_line_y = nil
        drag_item_name = nil
    end
end

--- Draw drag and drop visuals
---@return void
local function drawDragVisuals()
    if not dragging_index or not drag_item_name then
        return
    end

    local drawList = ImGui.GetForegroundDrawList()
    local mouse_x, mouse_y = ImGui.GetMousePos()
    local mouse_y_offset = 10

    -- Draw blue drop indicator line
    if drag_drop_line_y then
        local content_min_x, content_min_y = ImGui.GetWindowContentRegionMin()
        local content_max_x, content_max_y = ImGui.GetWindowContentRegionMax()
        local win_x, win_y = ImGui.GetWindowPos()
        local line_x1 = win_x + content_min_x
        local line_x2 = win_x + content_max_x
        local blue = ImGui.GetColorU32(0, 0.5, 1, 1)
        ImGui.ImDrawListAddLine(drawList, line_x1, drag_drop_line_y - (ImGui.GetStyle().ItemSpacing.y / 2), line_x2, drag_drop_line_y - (ImGui.GetStyle().ItemSpacing.y / 2), blue, 2)
    end

    -- Draw dragged item representation following cursor
    if drag_item_name then
        -- Find the window state for the dragged item
        local window = CETWM.windows[drag_item_name]
        if not window then return end
        local state = window.state or window

        local isFavorite = state.favorite or false
        local isLocked = state.locked or false
        local isVisible = state.visible or false

        local displayName = utils.getWindowDisplayName(drag_item_name)

        -- Style colors (mirrors styles.lua values)
        local r_en, g_en, b_en = 0.22, 0.48, 0.8
        local r_dis, g_dis, b_dis = 0.2, 0.2, 0.2
        local alpha = 0.85

        local col_enabled  = ImGui.GetColorU32(r_en,  g_en,  b_en,  alpha)
        local col_disabled = ImGui.GetColorU32(r_dis, g_dis, b_dis, alpha)
        local col_border   = ImGui.GetColorU32(0.26, 0.26, 0.29, 0.9)
        local col_text     = ImGui.GetColorU32(1.0, 1.0, 1.0, 1.0)

        local padding   = ImGui.GetStyle().FramePadding
        local spacing   = ImGui.GetStyle().ItemSpacing
        local pad_x     = padding.x
        local pad_y     = padding.y
        local rounding  = ImGui.GetStyle().FrameRounding

        -- Measure glyphs and name text
        local fav_icon  = isFavorite and IconGlyphs.Star or IconGlyphs.StarOutline
        local lock_icon = isLocked   and IconGlyphs.Lock or IconGlyphs.LockOpenVariant

        local fav_w,  fav_h  = ImGui.CalcTextSize(fav_icon)
        local lock_w, lock_h = ImGui.CalcTextSize(lock_icon)
        local name_w, name_h = ImGui.CalcTextSize(displayName)

        -- Fallback if CalcTextSize returns non-numbers
        fav_w  = type(fav_w)  == "number" and fav_w  or 16
        lock_w = type(lock_w) == "number" and lock_w or 16
        name_w = type(name_w) == "number" and name_w or 100
        local text_h = type(fav_h) == "number" and fav_h or 16

        -- Button dimensions (text + horizontal padding on each side)
        local btn_h      = text_h + pad_y * 2
        local fav_btn_w  = fav_w  + pad_x * 2
        local lock_btn_w = lock_w + pad_x * 2
        local name_btn_w = CETWM.minWidth  -- match the list width

        -- Total row dimensions
        local total_w = fav_btn_w + spacing.x + lock_btn_w + spacing.x + name_btn_w
        local total_h = btn_h

        -- Top-left origin of the ghost row
        local ox = mouse_x + 8
        local oy = mouse_y + mouse_y_offset

        -- Helper: draw one button rect + text, returns next x
        local function drawBtn(x, y, w, h, bgColor, icon, r)
            ImGui.ImDrawListAddRectFilled(drawList, x, y, x + w, y + h, bgColor, r)
            local tw, th = ImGui.CalcTextSize(icon)
            tw = type(tw) == "number" and tw or 16
            th = type(th) == "number" and th or 16
            ImGui.ImDrawListAddText(drawList, x + (w - tw) * 0.5, y + (h - th) * 0.5, col_text, icon)
            return x + w + spacing.x
        end

        -- Row background
        local row_pad = 4
        local col_row_bg = ImGui.GetColorU32(0.0, 0.0, 0.0, 0.92)
        ImGui.ImDrawListAddRectFilled(drawList,
            ox - row_pad, oy - row_pad,
            ox + total_w + row_pad, oy + total_h + row_pad,
            col_row_bg, rounding)
        ImGui.ImDrawListAddRect(drawList,
            ox - row_pad, oy - row_pad,
            ox + total_w + row_pad, oy + total_h + row_pad,
            col_border, rounding, 0, 1)

        -- Draw favourite button
        local cur_x = ox
        cur_x = drawBtn(cur_x, oy, fav_btn_w, btn_h,
            isFavorite and col_enabled or col_disabled,
            fav_icon, rounding)

        -- Draw lock button
        cur_x = drawBtn(cur_x, oy, lock_btn_w, btn_h,
            isLocked and col_enabled or col_disabled,
            lock_icon, rounding)

        -- Draw name/visibility button (uses minWidth like the real list)
        drawBtn(cur_x, oy, name_btn_w, btn_h,
            isVisible and col_enabled or col_disabled,
            displayName, rounding)
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

        drawDragVisuals()

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