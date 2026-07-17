# MenuFocus

A customizable, keyboard-driven command menu addon for **Final Fantasy XI Windower 4**. It also includes a drop-in library for developer use.

Repository: [https://github.com/State-Null/MenuFocus](https://github.com/State-Null/MenuFocus)

> [!NOTE]
> **Project Structure**:
> * **The Demo Addon (`MenuFocus.lua`)**: A working Windower 4 addon that showcases the menu system. You can download and run it immediately!
> * **The Library (`menu_focus.lua`)**: A clean drop-in module designed to be integrated directly into *existing* mouse-only or HUD-based addons.

---

## Table of Contents
1. [Quick Start: Run the Demo Addon](#quick-start-run-the-demo-addon)
2. [How to Customize the Menu Options](#how-to-customize-the-menu-options)
3. [Keyboard Controls](#keyboard-controls)
4. [Bridging to Gamepads](#bridging-to-gamepads)
5. [For Developers: Drop-in Library Integration](#for-developers-drop-in-library-integration)
6. [Key Features](#key-features)
7. [License](#license)

---

## Quick Start: Run the Demo Addon

`MenuFocus` works out of the box as a standalone addon. To try it:

1. **Install**: Download the files and place the `MenuFocus` folder in your Windower addons directory:
   `C:\Windower4\addons\MenuFocus\`
2. **Load**: Open FFXI and type `//lua load MenuFocus` in the chat window.
3. **Open Menu**: Type `//mf focus` in chat (or create an in-game macro `/console mf focus`) to display the menu.
4. **Test Navigation**:
   * Cycle options using `Tab` or your keyboard `Arrow Keys`.
   * Select an option using `Enter` or `Space`.
   * Close or go back using `Escape`.
   * *Note: The default menu options execute harmless `/echo` commands to show you how selections trigger actions in the chat box without needing active gameplay targets.*

---

## How to Customize the Menu Options

You can customize the menu labels and actions using any standard text editor (like **Notepad**) to execute your own spells, items, or macros.

### Step 1: Open the Menu File
Go to `C:\Windower4\addons\MenuFocus\` and open the `MenuFocus.lua` file using Notepad.

### Step 2: Locate the Menu Options
Scroll down to line 17. You will see this block of text:

```lua
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
```

### Step 3: Modify Names and Actions
Simply swap out the text inside the quotation marks with your own labels and FFXI slash commands.

> [!WARNING]
> **Editing Rules**:
> * **Preserve quotation marks**: Ensure all names and actions are enclosed in double quotes `""` or single quotes `''`.
> * **Preserve commas**: Make sure every menu line ends with a comma `,` (except the last item in a list block).
> * **Special Actions**:
>   * Use `action = "back"` to go back up one level in a submenu.
>   * Use `action = "close"` to close the menu.

#### Example: Adding a Weaponskill Option
To add a direct command to execute a Weaponskill, add a new line like this:
```lua
    { name = "Savage Blade", action = "/ws \"Savage Blade\" <t>" },
```

---

## Keyboard Controls

When focus mode is active, the following default keyboard controls are dynamically registered:

*   **`Tab` / `Down` / `Right`**: Cycle highlight cursor to the next item.
*   **`Shift + Tab` / `Up` / `Left`**: Cycle highlight cursor to the previous item.
*   **`Enter` / `Space` / `Numpad Enter`**: Confirm and trigger the selected action.
*   **`Escape`**: Cancel selection, go back in submenus, or close the menu.
*   **`1` through `9`**: Instant selection shortcut for the corresponding item.

---

## Bridging to Gamepads

`MenuFocus` is designed with a decoupled architecture. It does not handle controller hardware directly. Instead, it exposes simple Windower console commands (like `//mf menu_next` or `//mf menu_select`) that make it easy to bind controller buttons to these commands using any mapping software (such as **reWASD**, **JoyToKey**, **Xpadder**, **Steam Input**, or **AutoHotkey**).

*Refer to the `templates/` directory for details on setting up gamepad bridges.*

---

## For Developers: Drop-in Library Integration

If you are writing a custom addon and want to add keyboard/controller focus navigation to your HUD or GUI, you can drop `menu_focus.lua` into your project and use it as a library.

### 1. Drop in the Library
Place `menu_focus.lua` in your addon's directory.

### 2. Initialize in Your Addon
Load the module and set your callbacks:

```lua
local menu_focus = require('menu_focus')

menu_focus.init({
    on_select = function(item, index)
        -- Triggers when player selects an item
        windower.send_command('input ' .. item.action)
        menu_focus.unfocus()
    end,
    on_focus_change = function(focused, index)
        -- Optional: Redraw your HUD styling and highlight cursors
        update_my_ui(focused, index)
    end
})

menu_focus.set_items(my_menu_list)
```

### 3. Route Addon Commands
Forward Windower console commands to the library in your command event handler:

```lua
windower.register_event('addon command', function(cmd, ...)
    local args = {...}
    local cmd_lower = cmd and cmd:lower()
    
    if cmd_lower == 'focus' then
        menu_focus.focus()
    elseif cmd_lower == 'unfocus' or cmd_lower == 'close' then
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
```

*For more detailed blueprints and case studies (e.g. Checklist HUD scrolling and Graphical UI grid navigation), see [developer_guide.md](developer_guide.md).*

---

## Key Features

*   **Chat Box Safety (`%` modifier)**: Keyboard binds automatically suspend whenever the FFXI chat input box is open. Players can type spaces, use numbers, and tab-complete text normally without triggering menu navigation.
*   **Leak-Free Unbinding (0.15s Buffer)**: Implements delayed unbinding to swallow the key-release (key-up) event. This prevents the FFXI client from receiving trailing inputs that might accidentally open the chat input line (a common issue in Compact Keyboard mode).
*   **Direct Numeric Shortcuts (1-9)**: Dynamically binds the number keys matching the active menu count, letting players hit number keys for instant selections.
*   **Dynamic Submenus**: Native support for infinite nested menus using stack-based history navigation (using `Escape` or `Back` to traverse up).
*   **Conflict Arbitration**: A built-in arbitrator automatically releases focus binds from other active addons using this framework if a new one claims focus locally.
*   **Zero Dependencies**: Completely sandboxed and portable. Just drop `menu_focus.lua` into your addon folder and require it.

---

## License

This library is open-source and free to include in any FFXI Windower addon.
