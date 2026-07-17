-- MenuFocus.lua
_addon.name = 'MenuFocus'
_addon.author = 'Antigravity'
_addon.commands = {'menufocus', 'mf', 'addon_message'}
_addon.version = '1.1.0'

local texts = require('texts')
local menu_focus = require('menu_focus')

-- Tracks which addon holds the active focus globally
local active_focus_holder = nil

-- Dynamic registry of currently loaded focusable addons
local active_addons = {
    ['menufocus'] = 'MenuFocus'
}

-- =========================================================================================
-- CONFIGURATION BLOCK: ADD OR MODIFY YOUR SUBMENUS HERE
-- =========================================================================================
-- How to edit submenus:
-- To make a submenu, add a 'submenu' table inside an item.
-- Always include a back option `{ name = "Back to Main", action = "back" }` inside submenus!
-- =========================================================================================
local menu_items = {
    { 
        name = "Travel Options...", 
        submenu = {
            { name = "Use Warp Ring",      action = "/echo Using Warp Ring..." },
            { name = "Cast Warp",          action = "/echo Casting Warp..." },
            { name = "Back to Main",       action = "back" }
        }
    },
    { 
        name = "Buffs & Items...", 
        submenu = {
            { name = "Use Echo Drops",     action = "/item \"Echo Drops\" <me>" },
            { name = "Use Remedy (Mock)",  action = "/echo Using Remedy..." },
            { name = "Back to Main",       action = "back" }
        }
    },
    { name = "Exit Menu", action = "close" }
}
-- =========================================================================================

-- Navigation history tracking stack
local menu_stack = {}
local current_menu = menu_items

-- Sleek visual settings for the HUD window
local hud_settings = {
    pos = {x = 120, y = 350},
    text = {
        size = 11,
        font = 'Consolas',
        red = 230,
        green = 230,
        blue = 240,
        alpha = 255,
        stroke = {
            width = 1,
            red = 0,
            green = 0,
            blue = 0,
            alpha = 220,
        }
    },
    bg = {
        visible = true,
        red = 15,
        green = 15,
        blue = 25,
        alpha = 210, -- Semi-transparent dark mode background
    },
    padding = 10,
}

-- Create the on-screen text object
-- Settings configuration: auto_hide defaults to false (stays visible on screen)
local settings = {
    auto_hide = false,
    cycle_order = { 'MenuFocus', 'AutoCORDemo' }, -- Customizable cycle order
}

local menu_hud = texts.new(hud_settings)

-- Function to redraw the menu HUD based on state and selected index
local function update_hud()
    local text_lines = {}
    
    if menu_focus.is_focused or not settings.auto_hide then
        -- Indicate if we are in a submenu
        if #menu_stack > 0 then
            table.insert(text_lines, "\\cs(100, 220, 255)[ SUB MENU ] (Tab to Cycle)\\cr")
        else
            table.insert(text_lines, "\\cs(100, 220, 255)[ MAIN MENU ] (Tab to Cycle)\\cr")
        end
        table.insert(text_lines, "\\cs(120, 120, 120)---------------------------------------------\\cr")
        for i, item in ipairs(current_menu) do
            if menu_focus.is_focused and i == menu_focus.current_index then
                table.insert(text_lines, " \\cs(50, 255, 100)→ " .. string.format("%2d", i) .. ". " .. item.name .. "\\cr")
            else
                table.insert(text_lines, "   " .. string.format("%2d", i) .. ". " .. item.name)
            end
        end
        table.insert(text_lines, "\\cs(120, 120, 120)---------------------------------------------\\cr")
        
        -- Custom instructions depending on menu depth
        if menu_focus.is_focused then
            if #menu_stack > 0 then
                table.insert(text_lines, "\\cs(255, 255, 100)SPACE/ENTER: Select | ESC: Go Back\\cr")
            else
                table.insert(text_lines, "\\cs(255, 255, 100)SPACE/ENTER: Select | ESC: Close\\cr")
            end
        else
            table.insert(text_lines, "\\cs(255, 150, 100)UNFOCUSED - Type //mf focus to control\\cr")
        end
        
        menu_hud:text(table.concat(text_lines, '\n'))
        menu_hud:show()
    else
        menu_hud:hide()
    end
end

-- Initialize the focus helper
menu_focus.init({
    on_focus_change = function(focused, index)
        if focused then
            menu_hud:bg_color(15, 25, 45) -- Focused state
            menu_hud:bg_alpha(230)
        else
            -- Reset stack on close
            menu_stack = {}
            current_menu = menu_items
            menu_focus.set_items(current_menu)
            
            menu_hud:bg_color(15, 15, 25) -- Inactive state
            menu_hud:bg_alpha(210)
        end
        update_hud()
    end,
    on_select = function(item, index)
        if item.submenu then
            -- Open Submenu: Save current parent to history stack
            table.insert(menu_stack, current_menu)
            current_menu = item.submenu
            menu_focus.set_items(current_menu)
            menu_focus.current_index = 1
            update_hud()
        elseif item.action == "back" then
            -- Pop navigation history
            if #menu_stack > 0 then
                current_menu = table.remove(menu_stack)
                menu_focus.set_items(current_menu)
                menu_focus.current_index = 1
                update_hud()
            else
                menu_focus.unfocus()
            end
        elseif item.action == "close" then
            menu_focus.unfocus()
        else
            -- Execute final action
            windower.send_command('input ' .. item.action)
            menu_focus.unfocus() -- Auto-unfocus on selection
        end
    end
})

-- Load top-level menu items into focus helper
menu_focus.set_items(current_menu)

-- Initialize display
update_hud()

-- Addon commands
windower.register_event('addon command', function(cmd, ...)
    local args = {...}
    local cmd_lower = cmd and cmd:lower()
    
    if cmd_lower == 'focus' or cmd_lower == 'open' then
        menu_focus.focus()
    elseif cmd_lower == 'unfocus' or cmd_lower == 'close' or cmd_lower == 'menu_close' then
        -- Cancel command acts as 'back' if inside a submenu, or closes if at main menu
        if #menu_stack > 0 then
            current_menu = table.remove(menu_stack)
            menu_focus.set_items(current_menu)
            menu_focus.current_index = 1
            update_hud()
        else
            menu_focus.unfocus()
        end
    elseif cmd_lower == 'toggle' then
        if menu_focus.is_focused then
            menu_focus.unfocus()
        else
            menu_focus.focus()
        end
    elseif cmd_lower == 'cycle' then
        -- Build the resolved cycle order from configured settings and dynamically registered active_addons
        local resolved_cycle = {}
        local seen = {}
        
        -- First, add addons in the defined settings.cycle_order if they are currently loaded/active
        for _, name in ipairs(settings.cycle_order) do
            local name_lower = name:lower()
            if active_addons[name_lower] and not seen[name_lower] then
                table.insert(resolved_cycle, active_addons[name_lower])
                seen[name_lower] = true
            end
        end
        
        -- Next, add any other active addons not in settings.cycle_order (alphabetized fallback)
        local extra = {}
        for name_lower, name in pairs(active_addons) do
            if not seen[name_lower] then
                table.insert(extra, name)
            end
        end
        table.sort(extra)
        for _, name in ipairs(extra) do
            table.insert(resolved_cycle, name)
        end
        
        if #resolved_cycle > 0 then
            local next_addon = nil
            if not active_focus_holder then
                next_addon = resolved_cycle[1]
            else
                local idx = nil
                for i, name in ipairs(resolved_cycle) do
                    if name:lower() == active_focus_holder:lower() then
                        idx = i
                        break
                    end
                end
                
                if not idx then
                    next_addon = resolved_cycle[1]
                else
                    local next_idx = (idx % #resolved_cycle) + 1
                    next_addon = resolved_cycle[next_idx]
                end
            end
            
            if next_addon then
                windower.send_command('menu_focus_event mf_force_focus ' .. next_addon)
            end
        end
    elseif cmd_lower == 'mf_register' then
        local sender = args[1]
        if sender then
            active_addons[sender:lower()] = sender
        end
    elseif cmd_lower == 'mf_unregister' then
        local sender = args[1]
        if sender then
            active_addons[sender:lower()] = nil
        end
    elseif cmd_lower == 'mf_ping' then
        local sender = args[1]
        if sender ~= _addon.name then
            windower.send_command('menu_focus_event mf_register MenuFocus')
        end
    elseif cmd_lower == 'addon_message' then
        local sender = args[1]
        local event_type = args[2]
        if event_type == 'focus' then
            if active_focus_holder and active_focus_holder:lower() ~= sender:lower() then
                windower.send_command('lua c ' .. active_focus_holder .. ' unfocus')
            end
            active_focus_holder = sender
        elseif event_type == 'unfocus' then
            if active_focus_holder and active_focus_holder:lower() == sender:lower() then
                active_focus_holder = nil
            end
        end
    elseif cmd_lower == 'autohide' then
        settings.auto_hide = not settings.auto_hide
        update_hud()
        windower.add_to_chat(207, "[MenuFocus] Auto-hide set to: " .. tostring(settings.auto_hide))
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
    elseif cmd_lower == 'menu_num_select' then
        local num = args[1]
        menu_focus.num_select(num)
    elseif cmd_lower == 'clear_binds' then
        menu_focus.clear_binds()
    elseif cmd_lower == 'dummy' then
        -- Do nothing
    else
        windower.add_to_chat(207, "MenuFocus Commands: //mf focus (or toggle)")
    end
end)

-- Make sure to clean up if the addon is unloaded
windower.register_event('unload', function()
    menu_hud:destroy()
    menu_focus.unfocus()
end)
