
local settingsService = require("modules/settings")
local utils = require("modules/utils")
local logger = require("modules/logger")

local localization_dir = "data/localization/"

local unchanged_localizations = {}

---@class localizationService
---@field localization string 
---@field localization_strings table
---@field all_localizations table
---@method getInstance localizationService 
---@method setLocalization string

local localizationService = {}
localizationService.__index = localizationService

local settingsInst
local localizationServiceInst

---@return table 
local function list_files()
    local files = {}
    local success, dir_files = pcall(function()
        return dir(localization_dir)
    end)
    if not success then
        logger:error("ERROR: Window Manager could not list localization files!")
        return files
    end
    for _, file in pairs(dir_files) do
        if file.name:lower():match("%.lua$") then
            table.insert(files, utils.remove_extension(file.name))
        end
    end
    return files
end

---@param self localizationService
---@return table | nil
local function processLocalization(self)
    local filename = self.localization
    local en_us_locale = require(localization_dir .. "en-us.lua")
    if en_us_locale == nil then 
        logger:error("ERROR: Window Manager could not find en-us localization file!")
        return nil
    end

    if filename == "en-us" then
        return en_us_locale
    end

    local chosen_locale = require(localization_dir .. filename)
    if chosen_locale == nil then
        logger:error(string.format("ERROR: Window Manager could not find %s localization file, defaulting to en-us!", filename))
        return en_us_locale
    end

    if unchanged_localizations[filename] == nil then
        unchanged_localizations[filename] = utils.deepCopy(chosen_locale)
    end

    local arePartsMissing = false

    for key, value in pairs(en_us_locale) do
        if unchanged_localizations[filename][key] == nil then
            chosen_locale[key] = value
            arePartsMissing = true
        end
    end

    for key, value in pairs(chosen_locale) do
        if string.sub(key, 1, 3) == "err" then
            chosen_locale[key] = string.format("%s\n%s", value, en_us_locale[key])
        end
    end

    if arePartsMissing then
        logger:warn(string.format("WARNING: Window Manager could not find all parts of %s localization file, defaulting some lines to en-us!", filename))
    end
    return chosen_locale
end

---@return void 
function localizationService:refreshLocalization()
    local temp_localization = processLocalization(self)
    if temp_localization then
        self.localization_strings = temp_localization
    else
        logger:error(self.localization_strings.errFailedRefreshLocalization)
        return
    end
    local temp_all_localizations = list_files()
    if temp_all_localizations then
        self.all_localizations = temp_all_localizations
    else
        logger:error(self.localization_strings.errFailedGettingAllLocalizations)
        return
    end
end

---@param language string
---@return void
function localizationService:setLocalization(language)
    self.localization = language
    self:refreshLocalization()
    local temp_settings = settingsInst.settings
    temp_settings.localization = language
    settingsInst:update(temp_settings, "settings")
end

---@return localizationService | nil | bool
local function init(self)
    settingsInst = settingsService:getInstance()
    if settingsInst == nil then
        logger:error("ERROR: Window Manager failed to initialize settings in localization service!")
        return
    end
    self.localization = settingsInst.settings.localization
    self.all_localizations = list_files()
    self.localization_strings = processLocalization(self)
    if self.localization_strings == nil then
        return false
    end
    return true
end

---@return nil | localizationService
function localizationService:getInstance()
    if localizationServiceInst == nil then
        localizationServiceInst = setmetatable({}, localizationService)
        if not init(localizationServiceInst) then
            return
        end
    end
    return localizationServiceInst
end


return localizationService