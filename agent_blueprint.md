# MenuFocus Integration Blueprint (AI Agent Training Guide)

This blueprint contains the constraints, rules of thumb, and integration paradigms discovered through building and debugging focus navigation for Final Fantasy XI (Windower 4) addons. Load this when modifying existing addons to support keyboard/controller menus.

---

## Healthy Basics for Developers & AI Agents

Before modifying any code, review these essential safety standards:
1. **Chat Safety First**: Every custom keybind must be prefixed with `%` (e.g. `%space`) so they suspend automatically when the FFXI chat line is open. Never bind raw keys.
2. **Respect the Original UI**: Addons should remain visually unchanged when focus is inactive. Do not hide persistent HUD elements or add custom decorative borders unless focused.
3. **No Enter Traps**: Keyboard `Enter` leaks and opens the chat line in FFXI. Use `Space` or `Numpad Enter` as confirm keys.
4. **Collaborate on Complexity**: If the layout requires complex submenus, multi-column navigation, or major visual alterations, stop and ask the user for alignment before writing code.

---

## 1. Core Philosophy: Preserve the Original Addon

*   **No Unnecessary Redesigns**: Do not rewrite the host addon's visual drawing code. Keep the fonts, padding, backgrounds, and sizes exactly as they were.
*   **Persistent HUDs Remain Visible**: If the host addon displays active settings (e.g. roll readouts, quest checklists), the HUD **must stay on screen** when unfocused.
*   **Focus State Separation**: 
    *   *Unfocused*: Hide the selection arrow (`→`) and any key help text. The HUD should look 100% identical to the original addon layout.
    *   *Focused*: Draw the selection arrow (`→`) next to the current index, update the background if necessary to indicate active focus, and show help text.
*   **Prompt on Complexity / Major Interventions**: If the integration requires changes beyond simple toggles, simple checklists, or basic submenus (such as adding multiple pages, layout re-orientations, or complex state routing), you **must stop and prompt the user** for design feedback *before* writing or modifying any code. Do not execute major visual or structural revisions unilaterally.

---

## 2. Keybind Safety & Swallow Rules

*   **Chat Suspension (`%`)**: Always prefix bindings with `%` (e.g., `%space`, `%numpad0`). This suspends the binds when FFXI's chat box is open, preventing chat lockups.
*   **The Enter Key Leak**: 
    *   Standard keyboard `Enter` (`%enter`) is unblockable in Windower 4 and will force open the FFXI chat line. Do not use it as a default confirm key.
    *   **Space Bar (`%space`)** and **Numpad Enter (`%numpadenter`)** are blockable/swallowable and are the safe confirm keys.
*   **Numpad Movement Collision**: 
    *   Do not bind directional numpad keys (`8`, `2`, `4`, `6`) to menu navigation by default, as this steals character/camera movement from players.
    *   Instead, map **Numpad 0 (`%numpad0`)** to cycle options (secondary `Tab`), and let standard Arrow keys handle 2D moves.
*   **Unload Cleanup**: Addons must hook into Windower's `unload` event and call `menu_focus.unfocus()` to clear all key mappings. Failure to do so locks player keyboard controls when the addon is reloaded/unloaded.

---

## 3. The Three Integration Paradigms

### Pattern A: Checklist / Scrolling Lists (e.g. XIchecklist)
*   **Goal**: Navigate long readouts that exceed screen space.
*   **Approach**: Bind arrow keys to increment/decrement the list index. On focus change, set the list scroll offset variables to keep the selected item in view.

### Pattern B: Graphical Grid Widgets (e.g. Chronicle)
*   **Goal**: Mouse-only buttons need keyboard/controller activation.
*   **Approach**: Map the 1D menu index to 2D grid coordinates. On selection, execute the target card widget's mouse-click callback function (`widget.on_click()`) to simulate a real click.

### Pattern C: Simple Toggle Settings (e.g. AutoCOR)
*   **Goal**: On/Off toggles for combat settings.
*   **Approach**: Map the menu items directly to status rows. On selection, toggle the status boolean, print a confirmation to chat, and call `unfocus()` immediately.
*   *Layout*: Place the selection arrow (`→`) directly on the status line (e.g., `→ AutoCOR [Off]`).

---

## 4. Boilerplate Command Router

When implementing command routing, always include the new directional arrow commands:

```lua
windower.register_event('addon command', function(cmd, ...)
    local args = {...}
    local cmd_lower = cmd and cmd:lower()

    if cmd_lower == 'focus' or cmd_lower == 'open' then
        menu_focus.focus()
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
```
