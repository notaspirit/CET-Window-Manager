local r_enabled, g_enabled, b_enabled = 0.22, 0.48, 0.8
local r_disabled, g_disabled, b_disabled = 0.2, 0.2, 0.2
local hover_multiplier = 1.2
local active_multiplier = 1.2

local button_styled_enabled = {
    Button = {r = r_enabled, g = g_enabled, b = b_enabled, a = 1.0},
    ButtonHovered = {r = r_enabled * hover_multiplier, g = g_enabled * hover_multiplier, b = b_enabled * hover_multiplier, a = 1.0},
    ButtonActive = {r = r_enabled * active_multiplier, g = g_enabled * active_multiplier, b = b_enabled * active_multiplier, a = 1.0}
}
local button_styled_disabled = {
    Button = {r = r_disabled, g = g_disabled, b = b_disabled, a = 1.0},
    ButtonHovered = {r = r_disabled * hover_multiplier, g = g_disabled * hover_multiplier, b = b_disabled * hover_multiplier, a = 1.0},
    ButtonActive = {r = r_disabled * active_multiplier, g = g_disabled * active_multiplier, b = b_disabled * active_multiplier, a = 1.0}
}

local function button_styled_light()
    ImGui.PushStyleColor(ImGuiCol.Button, button_styled_enabled.Button.r, button_styled_enabled.Button.g, button_styled_enabled.Button.b, button_styled_enabled.Button.a)
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, button_styled_enabled.ButtonHovered.r, button_styled_enabled.ButtonHovered.g, button_styled_enabled.ButtonHovered.b, button_styled_enabled.ButtonHovered.a)
    ImGui.PushStyleColor(ImGuiCol.ButtonActive, button_styled_enabled.ButtonActive.r, button_styled_enabled.ButtonActive.g, button_styled_enabled.ButtonActive.b, button_styled_enabled.ButtonActive.a)
end

local function button_styled_dark()
    ImGui.PushStyleColor(ImGuiCol.Button, button_styled_disabled.Button.r, button_styled_disabled.Button.g, button_styled_disabled.Button.b, button_styled_disabled.Button.a)
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, button_styled_disabled.ButtonHovered.r, button_styled_disabled.ButtonHovered.g, button_styled_disabled.ButtonHovered.b, button_styled_disabled.ButtonHovered.a)
    ImGui.PushStyleColor(ImGuiCol.ButtonActive, button_styled_disabled.ButtonActive.r, button_styled_disabled.ButtonActive.g, button_styled_disabled.ButtonActive.b, button_styled_disabled.ButtonActive.a)
end


return {
    button_styled_light = button_styled_light,
    button_styled_dark = button_styled_dark
}