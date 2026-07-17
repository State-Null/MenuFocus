-- =========================================================================================
-- checklist_hud_integration.lua
-- Example: Integrating MenuFocus with a Checklist HUD (e.g., XIchecklist)
-- =========================================================================================
-- In this model, the HUD displays a long list of quests. Keyboard navigation
-- scrolls the list cursor, while selecting simply closes focus mode.
-- =========================================================================================

local menu_focus = require('menu_focus')

-- Simulated HUD checklist variables
local my_checklist = {
    { name = "Defeating the Shadow Lord", done = false },
    { name = "The Secret Weapon",         done = true },
    { name = "Rivalry",                  done = false },
    { name = "A Toy Store Quest",        done = true },
    { name = "The Cold Light of Day",    done = false }
}

local selected_row = nil -- Tracks currently highlighted index
local scroll_offset = 0  -- Tracks top visible row

-- Clamps scrolling so the highlighted cursor stays visible on screen
local function clamp_scroll(list_size)
    local max_visible = 3 -- Let's assume our HUD window displays 3 rows at a time
    if selected_row > scroll_offset + max_visible then
        scroll_offset = selected_row - max_visible
    elseif selected_row <= scroll_offset then
        scroll_offset = selected_row - 1
    end
end

-- Simulated HUD drawing routine
local function draw_hud()
    local text = "=== QUEST CHECKLIST (Focus Mode) ===\n"
    for i = 1, #my_checklist do
        local is_visible = i > scroll_offset and i <= scroll_offset + 3
        if is_visible then
            -- Highlight current selected row
            local cursor = (i == selected_row) and "→ " or "  "
            local status = my_checklist[i].done and "[X]" or "[ ]"
            text = text .. cursor .. status .. " " .. my_checklist[i].name .. "\n"
        end
    end
    print(text) -- In a real addon, you would update your Windower text object
end

-- =========================================================================================
-- MenuFocus Initialization
-- =========================================================================================

menu_focus.init({
    -- Selection exits focus mode (checks are passive toggles driven by mouse or other triggers)
    on_select = function(item, index)
        print("Closing focus on checklist item: " .. item.name)
        menu_focus.unfocus()
    end,
    
    -- Focus changes update selection highlights and scroll offsets
    on_focus_change = function(focused, index)
        if focused then
            selected_row = index
            clamp_scroll(#my_checklist)
        else
            selected_row = nil -- Clear visual highlight
        end
        draw_hud()
    end
})

-- Load active checklist items into the focus engine
menu_focus.set_items(my_checklist)

-- To start navigating, call:
-- menu_focus.focus()
