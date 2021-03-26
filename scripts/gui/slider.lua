local config = require("scripts.config")

local slider = {}

function slider:update(action, action_id)
    if action_id == config.mouse_click and action.pressed and gui.pick_node(self.node, action.x, action.y) then
        self.is_draging = true
        self.drag_start_x = action.x
    elseif action.released and self.is_draging then
        self.is_draging = false
        self.current_x = -self.position.x
    end

    if self.is_draging == true then
        self.position.x = ((self.current_x + self.drag_start_x) - action.x) * -1

        if self.position.x > self.slider_width then
            self.position.x = self.slider_width
        elseif self.position.x < 0 then
            self.position.x = 0
        end

        self.value = ((self.position.x / self.slider_width) * self.range) + self.min

        self.callback(self.value)
        gui.set_position(self.node, self.position)
        self.slider_field_node_size.x = self.position.x
        gui.set_size(self.slider_field_node, self.slider_field_node_size)
    end
end

---@param _initial_value integer
---@param _node_name string
---@param _min integer
---@param _max integer
---@param _callback function
function slider.new(_initial_value, _node_name, _min, _max, _callback)
    local dragger = gui.get_node(_node_name .. "/button")
    local dragger_pos = gui.get_position(dragger)
    local dragger_size = gui.get_size(dragger)
    local slider_field = gui.get_node(_node_name .. "/box")
    local slider_field_size = gui.get_size(slider_field)

    local slider_width = gui.get_size(gui.get_node(_node_name .. "/slider")).x

    local slider_range = _max - _min
    local value = _initial_value - _min
    local init_x = ((slider_width - dragger_size.x) / slider_range) * value

    dragger_pos.x = init_x
    gui.set_position(dragger, dragger_pos)
    slider_field_size.x = init_x
    gui.set_size(slider_field, slider_field_size)
    _callback(_initial_value)
    local state = {
        min = _min,
        max = _max,
        is_draging = false,
        drag_start_x = dragger_pos.x,
        current_x = -dragger_pos.x,
        node = dragger,
        position = dragger_pos,
        slider_width = slider_width - dragger_size.x,
        value = _initial_value,
        range = slider_range,
        callback = _callback,
        slider_field_node = slider_field,
        slider_field_node_size = slider_field_size
    }
    return setmetatable(state, {__index = slider})
end

return slider
