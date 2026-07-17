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
    { name = "AutoCOR", action = "toggle_autocor" },
    { name = "<p1>",    action = "toggle_p1" },
    { name = "<p2>",    action = "toggle_p2" },
    { name = "<p3>",    action = "toggle_p3" },
    { name = "<p4>",    action = "toggle_p4" },
    { name = "<p5>",    action = "toggle_p5" }
}

-- Render HUD to look 100% identical to original layout, but with selector arrow when focused
local function update_hud()
    local lines = {}
    local is_f = menu_focus.is_focused
    local cur = menu_focus.current_index
    
    local c1 = (is_f and cur == 1) and "→ " or "  "
    table.insert(lines, c1 .. "AutoCOR [" .. (autocor_enabled and "On" or "Off") .. "]")
    
    -- Roll slots remain as static readouts (unselectable in focus navigation)
    table.insert(lines, "  Roll 1 [" .. roll1 .. "]")
    table.insert(lines, "  Roll 2 [" .. roll2 .. "]")
    
    table.insert(lines, "  AoE:")
    
    for i = 1, 5 do
        -- Focus index shifts because we skipped Roll 1 and Roll 2
        local c_p = (is_f and cur == (1 + i)) and "→ " or "  "
        table.insert(lines, c_p .. "<p" .. i .. "> [" .. party_status[i] .. "]")
    end

    hud:text(table.concat(lines, "\n"))
    hud:show()
end

-- Initialize library
menu_focus.init({
    on_select = function(item, index)
        if item.action == "toggle_autocor" then
            autocor_enabled = not autocor_enabled
            windower.add_to_chat(207, "[AutoCORDemo] AutoCOR rolls automation is now " .. (autocor_enabled and "ON" or "OFF"))
        elseif item.action:sub(1, 8) == "toggle_p" then
            local slot = tonumber(item.action:sub(9))
            if slot then
                party_status[slot] = (party_status[slot] == "On") and "Off" or "On"
                windower.add_to_chat(207, "[AutoCORDemo] Party slot " .. slot .. " set to " .. party_status[slot])
            end
        end
        update_hud()
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
