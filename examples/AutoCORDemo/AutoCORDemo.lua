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
local rolls = {
    roll1 = "None",
    roll2 = "None"
}

-- Create default texts HUD
local hud = texts.new({
    pos = { x = 400, y = 300 },
    text = { size = 10, font = 'Consolas', color = {r=255, g=255, b=255} },
    bg = { visible = true, alpha = 220, color = {r=10, g=15, b=25} },
    padding = 12
})

-- Define our menu options with callback actions
local menu_items = {
    { name = "Roll 1: Chaos Roll (Attack)",      action = function() rolls.roll1 = "Chaos Roll" end },
    { name = "Roll 1: Fighter's Roll (Double)",  action = function() rolls.roll1 = "Fighter's Roll" end },
    { name = "Roll 2: Evoker's Roll (Refresh)",   action = function() rolls.roll2 = "Evoker's Roll" end },
    { name = "Roll 2: Tactician's Roll (Regain)", action = function() rolls.roll2 = "Tactician's Roll" end },
    { name = "Exit & Save Settings",             action = "close" }
}

-- Render HUD with highlight cursor
local function update_hud()
    local lines = {
        "=== [ AutoCOR Roll Settings ] ===",
        "Roll 1 Slot : " .. rolls.roll1,
        "Roll 2 Slot : " .. rolls.roll2,
    }

    if menu_focus.is_focused then
        table.insert(lines, "-------------------------------------")
        table.insert(lines, "Select a roll configuration options:")

        local current_idx = menu_focus.current_index
        for i, item in ipairs(menu_items) do
            if i == current_idx then
                table.insert(lines, "  → [ " .. item.name .. " ]")
            else
                table.insert(lines, "    " .. item.name)
            end
        end

        table.insert(lines, "-------------------------------------")
        table.insert(lines, "Navigate : Arrow Keys | Cycle: Numpad 0")
        table.insert(lines, "Select   : Space/NumEnter | Exit: Escape")
    end

    hud:text(table.concat(lines, "\n"))
    hud:show()
end

-- Initialize library
menu_focus.init({
    on_select = function(item, index)
        if item.action == "close" then
            menu_focus.unfocus()
        else
            item.action()
            windower.add_to_chat(207, "[AutoCORDemo] Roll updated! Roll 1: " .. rolls.roll1 .. " | Roll 2: " .. rolls.roll2)
            update_hud()
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
