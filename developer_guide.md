# Developer Integration Guide: FFXI Addon Gamepad or Keyboard Only Navigation

The `menu_focus` library is a drop-in Lua component designed for FFXI Windower 4 addon developers. It allows you to add native gamepad or keyboard only navigation (D-pad, Arrow Keys, Tab, Space, Enter, Escape) to any text HUD or graphical UI with **zero programming complexity**, **no key collisions**, and **complete chat safety**.

---

## 1. Quick Start: 3-Step Setup

### Step 1: Copy the Library
Copy the [menu_focus.lua](file:///C:/Windower4/addons/MenuFocus/menu_focus.lua) file directly into your addon's root folder.

### Step 2: Initialize in Your Addon
At the top of your main addon script (`YourAddon.lua`), load the library and register your selection callback:

```lua
local menu_focus = require('menu_focus')

-- 1. Initialize callbacks
menu_focus.init({
    on_select = function(item, index)
        -- This runs when the player presses Space, Enter, or a number key (1-9)
        windower.add_to_chat(207, "Selected item: " .. item.name)
        
        -- Custom action execution:
        if item.action == "close" then
            menu_focus.unfocus()
        else
            windower.send_command('input ' .. item.action)
            menu_focus.unfocus() -- Close menu after selection
        end
    end,
    on_focus_change = function(focused, index)
        -- Optional: Redraw your UI to show/hide the cursor highlight at 'index'
        update_my_hud() 
    end
})

-- 2. Populate your list
local my_items = {
    { name = "Use Warp Ring", action = "/item \"Warp Ring\" <me>" },
    { name = "Use Remedy",    action = "/item \"Remedy\" <me>" },
    { name = "Exit Menu",     action = "close" }
}
menu_focus.set_items(my_items)
```

### Step 3: Route Addon Commands
To let the player activate focus, route the keys to the library inside your addon command handler:

```lua
windower.register_event('addon command', function(cmd, ...)
    local args = {...}
    local cmd_lower = cmd and cmd:lower()
    
    if cmd_lower == 'focus' or cmd_lower == 'open' then
        menu_focus.focus()
    elseif cmd_lower == 'unfocus' or cmd_lower == 'close' or cmd_lower == 'menu_close' then
        menu_focus.unfocus()
    elseif cmd_lower == 'menu_next' then
        menu_focus.next()
    elseif cmd_lower == 'menu_prev' then
        menu_focus.prev()
    elseif cmd_lower == 'menu_select' then
        menu_focus.select()
    elseif cmd_lower == 'menu_num_select' then
        menu_focus.num_select(args[1])
    elseif cmd_lower == 'clear_binds' then
        menu_focus.clear_binds()
    end
end)

-- Auto-cleanup if players unload or reload your addon
windower.register_event('unload', function()
    menu_focus.unfocus()
end)
```

Now, players can create an in-game macro `/console youraddon focus` to open your menu, navigate it using their keyboard/controller, select an item, and automatically return to standard gameplay controls!

---

## 2. Case Study 1: Checklist HUDs (e.g., XIchecklist)

### The Problem
Checklist HUDs display long text blocks of completed/uncompleted quests. Because they do not have clickable buttons, they rely entirely on the **mouse scroll wheel** to scroll down the list. Gamepad-only players have no way to view items pushed off the screen.

### The Integration
To add gamepad scrolling, we bind the arrow keys to adjust the HUD's active selection variables directly:

```lua
-- Inside your HUD drawing/scrolling script (e.g. util/ui.lua)
local menu_focus = require('menu_focus')

-- 1. Tell menu_focus how many items exist
menu_focus.set_items(my_checklist_items)

-- 2. Hook focus callbacks to your list's scroll variables
menu_focus.init({
    on_select = function(item, index)
        -- Checklist items aren't clickable, so select just exits focus mode
        menu_focus.unfocus()
    end,
    on_focus_change = function(focused, index)
        if focused then
            -- Change checklist selected row index to match focus index
            selected = index
            clamp_scroll(#my_checklist_items) -- Scroll HUD window
        else
            selected = nil -- Remove selection cursor
        end
        draw() -- Redraw HUD
    end
})
```

By hooking this up, the player can focus the HUD, scroll through all elements using their gamepad D-pad, and press Escape to resume character movement.

---

## 3. Case Study 2: Graphical Clickable UIs (e.g., Chronicle)

### The Problem
Graphical UIs use clickable buttons and grid layout cards (like a quest log page). They register mouse hover and click events. Players without a mouse cannot hover or click the cards.

### The Integration
Instead of rewriting the GUI layouts, we map our 1D list index into 2D grid coordinates, and trigger a **mock click event** on the widget when Confirm is pressed:

```lua
-- Inside your visual widgets manager (e.g. ui/widgets.lua)
local menu_focus = require('menu_focus')

-- 1. Initialize with your active GUI card buttons
local visible_cards = get_active_panel_cards() -- Table of active image widgets
menu_focus.set_items(visible_cards)

-- 2. Map Confirm to trigger the widget's click handler
menu_focus.init({
    on_select = function(card_widget, index)
        -- Retrieve the widget's existing mouse-click function
        local click_callback = card_widget.on_click
        if click_callback then
            click_callback() -- Simulate a real mouse click!
        end
    end,
    on_focus_change = function(focused, index)
        -- Show focus by drawing a colored highlight border around the active card
        for idx, card in ipairs(visible_cards) do
            if focused and idx == index then
                card:set_border_color(0, 255, 255) -- Cyan selection border
            else
                card:set_border_color(0, 0, 0)     -- Clear border
            end
        end
    end
})
```

Using this click-simulation technique, developers can add full gamepad support to complex mouse interfaces in under 20 lines of code, leaving their existing GUI code completely untouched.

---

## 4. API Quick Reference

| Function | Description |
|---|---|
| `menu_focus.init(config)` | Sets up callbacks (`on_select`, `on_focus_change`) and keybinds. |
| `menu_focus.set_items(list)` | Sets the list array. Call this whenever your UI data list changes. |
| `menu_focus.focus()` | Starts focus mode. Binds all navigation keys to your addon. |
| `menu_focus.unfocus()` | Ends focus mode. Gracefully schedules unbinding of all keys. |
| `menu_focus.toggle()` | Switches focus mode between active and inactive. |
| `menu_focus.next()` | Cycles selection cursor forward by 1. |
| `menu_focus.prev()` | Cycles selection cursor backward by 1. |
| `menu_focus.select()` | Triggers the `on_select` callback for the highlighted item. |
| `menu_focus.num_select(num)` | Jump-selects the item at index `num` (1-9) immediately. |
