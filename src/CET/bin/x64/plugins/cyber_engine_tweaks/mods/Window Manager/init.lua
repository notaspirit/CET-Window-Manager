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

local utils = require('modules/utils')
local settings = require('modules/settings')
local styles = require('data/styles')
local localizationService = require('modules/localization')
local logger = require('modules/logger')
local windowManager = require('modules/windowManager')
local ui = require('modules/ui')

CETWM = {
    version = "2.0.0",
    ready = false,
    windows = {}, -- Store window states: {name = {visible = bool, lastPos = {x,y}, isCollapsed = bool, index = int, locked = bool, lastSize = {x,y}, disabled = bool}}
    -- this table now acts are the "working" or temp dir that then gets merged into the settingService and saved
    overlayOpen = false,
    minWidth = 0,

    settingsInst = nil,
    localizationInst = nil,

    deferredHide = {},
    deferredShow = {},
    deferredLock = {},
    deferredLockPt2 = {},
    defferredSetSelfPos = {},
    requestWindowPos = false,
    requestedNameSwitch = '',
    requestedLanguageSwitch = '',
    deferredSetSelfPos = {}
}

local settingsInst
local localizationInst

local framesToWaitBeforeLoading = 5

---@return boolean
local function checkPackages()
    local hasError = false
    local packages = {utils, settings, styles, localizationService, logger, windowManager, ui}
    for _, package in ipairs(packages) do
        if package == nil then
            hasError = true
            print("ERROR: Window Manager failed to intilize package: " .. tostring(_))
            spdlog.error("ERROR: Window Manager failed to intilize package: " .. tostring(_))
        end
    end

    if not RedCetWM then
        hasError = true
        print("ERROR: Could not find Red4Ext module, make sure you have Red4Ext installed!")
        spdlog.error("ERROR: Could not find Red4Ext module, make sure you have Red4Ext installed!")
    end

    if hasError then
        return false
    end
    return true
end

---@return void
local function initWindowManagerWindows()
    if CETWM.windows[localizationInst.localization_strings.modName] == nil then
        local newIndex = utils.tableLength(CETWM.windows) + 1
        CETWM.windows[localizationInst.localization_strings.modName] = {visible = true, lastPos = {x = 100, y = 100}, isCollapsed = false, index = newIndex, locked = false, lastSize = {1,1}}
        settingsInst:update(CETWM.windows, "windows")
    end
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

    CETWM.settingsInst = settingsInst
    CETWM.localizationInst = localizationInst

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
            windowManager.loadWindowsFromFile()
        end
    end

    ui.drawUI()

    -- all of these functions *HAVE* to be at the end of the draw call otherwise you will get flickering in the UI 
    ---> don't call `ImGui.Begin()` while within another `ImGui.Begin()`
    windowManager.lockWindowLoop()
    windowManager.processDeferred()
end)
