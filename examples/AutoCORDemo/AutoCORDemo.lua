-- =========================================================================================
-- AutoCORDemo: Windower 4 Addon demonstrating MenuFocus integration
-- Author: Antigravity
-- =========================================================================================

_addon.name = 'AutoCORDemo'
_addon.author = 'Antigravity'
_addon.version = '1.0.0'
_addon.commands = {'acd', 'autocordemo'}

local menu_focus = require('menu_focus')
local texts = require('texts')

-- Local configuration state
local autocor_enabled = false
local roll1 = "Samurai Roll"
local roll2 = "Chaos Roll"
local party_status = {"Off", "Off", "Off", "Off", "Off"}

-- Create default texts HUD (designed to match original Arial layout and solid black bg)
local hud = texts.new({
    pos = { x = 400, y = 300 },
    text = { size = 10, font = 'Arial', color = {r=255, g=255, b=255} },
    bg = { visible = true, alpha = 255, color = {r=0, g=0, b=0} },
    padding = 6
})

-- Define our menu options with callback actions
local menu_items = {
    { name = "AutoCOR", action = "toggle" }
}

-- Render HUD to look 100% identical to original layout, but with selector arrow when focused
local function update_hud()
    local lines = {}
    
    local status_str = autocor_enabled and "On" or "Off"
    if menu_focus.is_focused and menu_focus.current_index == 1 then
        table.insert(lines, "→ AutoCOR [" .. status_str .. "]")
    else
        table.insert(lines, "AutoCOR [" .. status_str .. "]")
    end
    
    table.insert(lines, "Roll 1 [" .. roll1 .. "]")
    table.insert(lines, "Roll 2 [" .. roll2 .. "]")
    table.insert(lines, "AoE:")
    for i = 1, 5 do
        table.insert(lines, "<p" .. i .. "> [" .. party_status[i] .. "]")
    end

    hud:text(table.concat(lines, "\n"))
    hud:show()
end

-- Initialize library
menu_focus.init({
    on_select = function(item, index)
        if item.action == "toggle" then
            autocor_enabled = not autocor_enabled
            windower.add_to_chat(207, "[AutoCORDemo] AutoCOR rolls automation is now " .. (autocor_enabled and "ON" or "OFF"))
            menu_focus.unfocus()
        end
    end,
    on_focus_change = function(focused, index)
        update_hud()
    end
})

menu_focus.set_items(menu_items)
update_hud()

-- Route addon commands
windower.register_event('addon command', function(cmd, ...)
    local args = {...}
    local cmd_lower = cmd and cmd:lower()

    if cmd_lower == 'focus' or cmd_lower == 'open' or cmd_lower == 'toggle' then
        menu_focus.toggle()
    elseif cmd_lower == 'menu_next' then
        menu_focus.next()
    elseif cmd_lower == 'menu_prev' then
        menu_focus.prev()
    elseif cmd_lower == 'menu_up' then
        menu_focus.up()
    elseif cmd_lower == 'menu_down' then
        menu_focus.down()
    elseif cmd_lower == 'menu_left' then
        menu_focus.left()
    elseif cmd_lower == 'menu_right' then
        menu_focus.right()
    elseif cmd_lower == 'menu_select' then
        menu_focus.select()
    elseif cmd_lower == 'menu_close' then
        menu_focus.unfocus()
    end
end)

-- Unload safety
windower.register_event('unload', function()
    menu_focus.unfocus()
    if hud then
        hud:destroy()
    end
end)
