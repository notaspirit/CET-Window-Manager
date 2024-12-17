local r_enabled, g_enabled, b_enabled = 0.22, 0.48, 0.8
local r_disabled, g_disabled, b_disabled = 0.2, 0.2, 0.2
local hover_multiplier = 1.2
local active_multiplier = 1.2

return {
    button_styled_enabled = {
        Button = {r = r_enabled, g = g_enabled, b = b_enabled, a = 1.0},
        ButtonHovered = {r = r_enabled * hover_multiplier, g = g_enabled * hover_multiplier, b = b_enabled * hover_multiplier, a = 1.0},
        ButtonActive = {r = r_enabled * active_multiplier, g = g_enabled * active_multiplier, b = b_enabled * active_multiplier, a = 1.0}
    },
    button_styled_disabled = {
        Button = {r = r_disabled, g = g_disabled, b = b_disabled, a = 1.0},
        ButtonHovered = {r = r_disabled * hover_multiplier, g = g_disabled * hover_multiplier, b = b_disabled * hover_multiplier, a = 1.0},
        ButtonActive = {r = r_disabled * active_multiplier, g = g_disabled * active_multiplier, b = b_disabled * active_multiplier, a = 1.0}
    }
}