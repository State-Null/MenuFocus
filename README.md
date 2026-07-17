# MenuFocus

A lightweight, self-contained drop-in Lua library for **Final Fantasy XI Windower 4** addons that adds native gamepad or keyboard only focus navigation to custom text HUDs and graphical UIs.

Many modern FFXI addons feature highly interactive menus that are **intended** for mouse input. However, in a classic tab-targeting MMO, forcing gamepad or keyboard-only players to click around a graphical overlay is clunky and breaks immersion. `MenuFocus` bridges this gap, allowing developers to easily make their UIs gamepad-accessible in minutes.

Repository: [https://github.com/State-Null/MenuFocus](https://github.com/State-Null/MenuFocus)

---

## Key Features

*   **Chat Box Safety (`%` modifier)**: Automatically suspends menu bindings whenever the player opens the chat input box, allowing them to type spaces and use autocomplete normally.
*   **Leak-Free Unbinding (0.15s Buffer)**: Implements delayed unbinding to swallow the key-release (key-up) event, preventing FFXI from receiving inputs that accidentally trigger the chat prompt (especially in Compact Keyboard mode).
*   **Direct Numeric Shortcuts (1-9)**: Dynamically binds the number keys matching the active menu item count, letting players hit number keys for instant selections.
*   **Dynamic Submenus**: Native support for infinite nested menus using stack-based history navigation (using `Escape` or `Back` to traverse up).
*   **Zero Dependencies**: Completely sandboxed and portable. Just drop `menu_focus.lua` into your addon folder and require it.

---

## How It Works: The CCI Pattern

`MenuFocus` uses a **Console Command Interface (CCI)** architecture. It does not couple controller-mapping configurations or external device inputs (like reWASD, Steam Input, or AHK scripts) directly inside the library. 

Instead, it exposes public console commands:
*   `//mf focus` (toggles focus mode)
*   `//mf menu_next` (cycles highlight forward)
*   `//mf menu_select` (executes selected action)
*   `//mf menu_close` (goes back or closes menu)

This allows gamepad players or bridging plugins (such as a bridging script for `xivcrossbar`) to drive addon navigation simply by routing key events to these console commands.

---

## Quick Start Integration

### 1. Drop in the Library
Place `menu_focus.lua` in your addon's directory.

### 2. Initialize in Your Addon
Load the module and set your menu items:

```lua
local menu_focus = require('menu_focus')

-- Define your menu items (supports submenus)
local menu_items = {
    { 
        name = "Travel Options...", 
        submenu = {
            { name = "Use Warp Ring", action = "/echo Using Warp Ring..." },
            { name = "Cast Warp",     action = "/echo Casting Warp..." },
            { name = "Back to Main",  action = "back" }
        }
    },
    { name = "Use Echo Drops", action = "/item \"Echo Drops\" <me>" },
    { name = "Exit Menu",      action = "close" }
}

-- Initialize navigation and selection callbacks
menu_focus.init({
    on_select = function(item, index)
        if item.action == "close" then
            menu_focus.unfocus()
        elseif item.action ~= "back" and not item.submenu then
            windower.send_command('input ' .. item.action)
            menu_focus.unfocus() -- Auto-close after action
        end
    end,
    on_focus_change = function(focused, index)
        -- Hook this callback to redraw your HUD styling and highlight cursors!
        update_my_ui(focused, index)
    end
})

menu_focus.set_items(menu_items)
```

### 3. Route Addon Commands
Register addon console commands to allow routing inputs:

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

-- Always unfocus on unload to clean up binds dynamically
windower.register_event('unload', function()
    menu_focus.unfocus()
end)
```

---

## License
This library is open-source and free to include in any FFXI Windower addon.
