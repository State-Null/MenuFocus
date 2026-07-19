-- =========================================================================================
-- menu_focus.lua - Drop-In Gamepad & Keyboard Focus Library for FFXI Windower Addons
-- Version: 1.1.0
-- Author: Antigravity
-- =========================================================================================
-- How to use:
-- 1. Copy menu_focus.lua into your addon's directory.
-- 2. Import it: local menu_focus = require('menu_focus')
-- 3. Initialize it: menu_focus.init({ on_select = select_cb, on_focus_change = focus_cb })
-- 4. Load your menu list: menu_focus.set_items(my_menu_list)
-- 5. Open focus mode: menu_focus.focus()
-- =========================================================================================

local menu_focus = {}

-- Public States (Read-Only for your addon)
menu_focus.is_focused = false      -- True if keyboard/gamepad is currently capturing navigation
menu_focus.current_index = 1       -- The 1-based index of the currently selected menu item
menu_focus.items = {}              -- Active menu items table

-- Private Callbacks
local on_select_cb = nil
local on_focus_change_cb = nil

-- Standard Windower key bindings configuration (State modifier '%' for chat safety)
local default_binds = {
    ['%tab']          = 'menu_next',
    ['%~tab']         = 'menu_prev',     -- Shift + Tab
    ['%enter']        = 'menu_select',   -- Keyboard Enter
    ['%numpadenter']  = 'menu_select',   -- Numpad Enter
    ['%space']        = 'menu_select',   -- Keyboard Space (safe for Compact mode fallback)
    ['%escape']       = 'close',         -- Cancel/Exit
    
    -- Keyboard Arrow keys for navigation
    ['%up']           = 'menu_prev',
    ['%down']         = 'menu_next',
    ['%left']         = 'menu_prev',
    ['%right']        = 'menu_next',
}

-- =========================================================================================
-- PUBLIC API FUNCTIONS
-- =========================================================================================

--- Initializes the menu focus library with callbacks and custom bindings.
-- @param config Table containing:
--   - on_select: function(item, index) called when confirming a selection
--   - on_focus_change: function(is_focused, current_index) called when focus starts/changes/ends (optional)
--   - binds: custom key binding override map (optional)
function menu_focus.init(config)
    on_select_cb = config.on_select
    on_focus_change_cb = config.on_focus_change
    menu_focus.binds = config.binds or default_binds
end

--- Updates the items list managed by the focus helper.
-- Resets the selection index if it falls out of range of the new list.
-- @param new_items Array of menu items
function menu_focus.set_items(new_items)
    menu_focus.items = new_items or {}
    if menu_focus.current_index > #menu_focus.items then
        menu_focus.current_index = math.max(1, #menu_focus.items)
    end
end

--- Opens focus navigation mode.
-- Dynamically binds keyboard Arrow/Tab/Enter/Space/Escape inputs to trigger navigation.
-- Suspension '%' ensures binds are inactive when the chat box is open.
function menu_focus.focus()
    if menu_focus.is_focused then return end
    menu_focus.is_focused = true
    menu_focus.current_index = 1
    
    -- Bind standard navigation keys
    for key, cmd in pairs(menu_focus.binds) do
        windower.send_command('bind ' .. key .. ' ' .. _addon.name .. ' ' .. cmd)
    end
    
    -- Dynamically bind number keys (1-9) matching active item count for instant shortcut select
    for i = 1, math.min(#menu_focus.items, 9) do
        windower.send_command('bind %' .. tostring(i) .. ' ' .. _addon.name .. ' menu_num_select ' .. tostring(i))
    end
    
    if on_focus_change_cb then
        on_focus_change_cb(true, menu_focus.current_index)
    end
end

--- Closes focus navigation mode.
-- Queues a 0.15s delayed unbind to allow the physical confirm key to be released
-- before removing the intercept binds, preventing input leakage to FFXI.
function menu_focus.unfocus()
    if not menu_focus.is_focused then return end
    menu_focus.is_focused = false
    
    -- Delay unbind slightly to swallow the key-up event before restoring normal controls
    windower.send_command('wait 0.15; ' .. _addon.name .. ' clear_binds')
    
    if on_focus_change_cb then
        on_focus_change_cb(false, nil)
    end
end

--- Forcefully clears all custom bindings immediately (used internally and on unload).
function menu_focus.clear_binds()
    if menu_focus.is_focused then return end -- Safety check: abort if refocused
    
    -- Remove navigation binds
    for key, _ in pairs(menu_focus.binds) do
        windower.send_command('unbind ' .. key)
    end
    
    -- Remove dynamic number binds
    for i = 1, math.min(#menu_focus.items, 9) do
        windower.send_command('unbind %' .. tostring(i))
    end
end

--- Forcefully clears all custom bindings immediately on unload.
function menu_focus.unload()
    menu_focus.is_focused = false
    
    -- Remove navigation binds
    for key, _ in pairs(menu_focus.binds) do
        windower.send_command('unbind ' .. key)
    end
    
    -- Remove dynamic number binds
    for i = 1, math.min(#menu_focus.items, 9) do
        windower.send_command('unbind %' .. tostring(i))
    end
end

--- Toggles focus between active and inactive states.
function menu_focus.toggle()
    if menu_focus.is_focused then
        menu_focus.unfocus()
    else
        menu_focus.focus()
    end
end

-- =========================================================================================
-- NAVIGATION RUNTIMES (Usually called from addon command routes)
-- =========================================================================================

--- Cycle highlight cursor to the next option.
function menu_focus.next()
    if not menu_focus.is_focused or #menu_focus.items == 0 then return end
    local current_item = menu_focus.items[menu_focus.current_index]
    if current_item and current_item.navigate_next and current_item:navigate_next() then
        return
    end
    menu_focus.current_index = (menu_focus.current_index % #menu_focus.items) + 1
    if on_focus_change_cb then
        on_focus_change_cb(true, menu_focus.current_index)
    end
end

--- Cycle highlight cursor to the previous option.
function menu_focus.prev()
    if not menu_focus.is_focused or #menu_focus.items == 0 then return end
    local current_item = menu_focus.items[menu_focus.current_index]
    if current_item and current_item.navigate_prev and current_item:navigate_prev() then
        return
    end
    menu_focus.current_index = menu_focus.current_index - 1
    if menu_focus.current_index < 1 then
        menu_focus.current_index = #menu_focus.items
    end
    if on_focus_change_cb then
        on_focus_change_cb(true, menu_focus.current_index)
    end
end

--- Confirm selection at the current highlighted index.
function menu_focus.select()
    if not menu_focus.is_focused or #menu_focus.items == 0 then return end
    local selected = menu_focus.items[menu_focus.current_index]
    if on_select_cb then
        on_select_cb(selected, menu_focus.current_index)
    end
end

--- Direct jump selection (via numeric keys 1-9).
-- @param num The string or number index to select
function menu_focus.num_select(num)
    if not menu_focus.is_focused or #menu_focus.items == 0 then return end
    local index = tonumber(num)
    if index and index >= 1 and index <= #menu_focus.items then
        menu_focus.current_index = index
        menu_focus.select()
    end
end

return menu_focus
