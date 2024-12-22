local window_blacklist = {
    ""
}

local window_name_lookup = {
    ["World Inspector"] = "World Inspector##RHT:WorldTools",
    ["Ink Inspector"] = "Ink Inspector##RHT:InkTools:MainWindow",
    ["Hot Reload"] = "Hot Reload##RHT:HotReload",
    ["Simple Utils"] = IconGlyphs.Cog .. " Simple Utils",
    ["No Forced Weapon On Carrying Bodies"] = "No Forced Weapon On Carrying Bodies Mod Window",
    ["No Forced Weapon On Carrying Bodie"] = "No Forced Weapon On Carrying Bodies Mod Window"
}

return {
    window_blacklist = window_blacklist,
    window_name_lookup = window_name_lookup
}