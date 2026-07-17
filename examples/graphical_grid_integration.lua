-- =========================================================================================
-- graphical_grid_integration.lua
-- Example: Integrating MenuFocus with Graphical Card Grids (e.g., Chronicle)
-- =========================================================================================
-- In this model, the UI displays clickable card buttons. Selecting an item
-- triggers a simulated click event on the target widget.
--
-- CRITICAL LESSON: Ensure your widget toolkit stores position coordinates (x, y)
-- directly on the Lua objects themselves (e.g., self._x, self._y) rather than
-- just passing them to underlying C++ objects. Otherwise, navigation coordinates
-- will return nil and throw indexing errors.
-- =========================================================================================

local menu_focus = require('menu_focus')

-- Mock graphical widget classes
local Widget = {}
Widget.__index = Widget

function Widget.new(name, x, y, click_cb)
    local self = setmetatable({}, Widget)
    self.name = name
    -- CRITICAL: Store positions locally on the Lua object
    self._x = x
    self._y = y
    self.on_click = click_cb
    self.border_color = {0, 0, 0}
    return self
end

function Widget:set_border_color(r, g, b)
    self.border_color = {r, g, b}
end

-- Create sample clickable card buttons in a 2D layout grid
local card_widgets = {
    Widget.new("Card A", 100, 100, function() print("Card A clicked!") end),
    Widget.new("Card B", 300, 100, function() print("Card B clicked!") end),
    Widget.new("Card C", 100, 250, function() print("Card C clicked!") end),
    Widget.new("Card D", 300, 250, function() print("Card D clicked!") end),
}

-- =========================================================================================
-- MenuFocus Integration
-- =========================================================================================

menu_focus.init({
    -- Select triggers the widget's existing mouse callback
    on_select = function(widget, index)
        if widget.on_click then
            widget.on_click()
        end
        menu_focus.unfocus()
    end,

    -- Highlight cursor moves by drawing a border around the active widget
    on_focus_change = function(focused, index)
        for idx, widget in ipairs(card_widgets) do
            -- Safety check: verify coordinates exist before performing navigation operations
            if widget._x and widget._y then
                if focused and idx == index then
                    widget:set_border_color(0, 255, 255) -- Active Cyan Highlight
                    print(string.format("Highlighting %s at grid position (%d, %d)", widget.name, widget._x, widget._y))
                else
                    widget:set_border_color(0, 0, 0)     -- Clear Highlight
                end
            end
        end
    end
})

-- Load active buttons into focus helper
menu_focus.set_items(card_widgets)

-- To start navigating, call:
-- menu_focus.focus()
