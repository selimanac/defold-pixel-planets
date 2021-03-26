local config = require("scripts.config")

local dropdown = {}

local dropdown_selector
local dropdown_container
local dropdown_current = 0
local selected_dropdown = 0
local dropdown_label
local color_black = vmath.vector4(0, 0, 0, 1)
local color_white = vmath.vector4(1, 1, 1, 1)

local function dropdown_field_toggle(item)
    local prev_field = config.planets[item].nodes["dropdown_field_template/planet_name"]
    gui.set_color(prev_field, color_black)
    prev_field = config.planets[item].nodes["dropdown_field_template/planet_name_txt"]
    gui.set_color(prev_field, color_white)
end

local function toggle_selected_field()
    if selected_dropdown ~= 0 and selected_dropdown ~= dropdown_current then
        dropdown_field_toggle(selected_dropdown)
    end
end

local function toggle_prev_field()
    if dropdown_current ~= 0 and dropdown_current ~= selected_dropdown then
        dropdown_field_toggle(dropdown_current)
    end
end

local function toggle_dropdown_field(nodes, index)
    -- unselect prev
    toggle_prev_field()

    -- turn selected
    gui.set_color(nodes["dropdown_field_template/planet_name"], color_white)
    gui.set_color(nodes["dropdown_field_template/planet_name_txt"], color_black)

    dropdown_current = index
end

local function toggle_dropdown()
    toggle_prev_field()
    local set = gui.is_enabled(dropdown_container) == false and true or false
    gui.set_enabled(dropdown_container, set)
    dropdown_current = 0
end

local function send_msg()
    msg.post(config.main_url, config.msg.load_planet, {id = selected_dropdown})
end

function dropdown.init(select)
    dropdown_selector = gui.get_node("planet_type")
    dropdown_container = gui.get_node("dropdown_container")
    dropdown_label = gui.get_node("planet_type_label")

    local dropdown_background = gui.get_node("dropdown_back")
    local dropdow_template = gui.get_node("dropdown_field_template/root")

    local field_position = vmath.vector3(0, -4, 0)
    local template_clone

    for index, value in ipairs(config.planets) do
        template_clone = gui.clone_tree(dropdow_template)
        value.nodes = template_clone

        gui.set_text(template_clone[hash("dropdown_field_template/planet_name_txt")], value.name)
        gui.set_position(template_clone[hash("dropdown_field_template/root")], field_position)

        field_position.y = field_position.y - 22
    end

    local dropdown_background_size = gui.get_size(dropdown_background)
    dropdown_background_size.y = field_position.y * -1

    gui.set_size(dropdown_background, dropdown_background_size)
    gui.delete_node(dropdow_template)
    gui.set_enabled(dropdown_container, false)

    selected_dropdown = select
    toggle_dropdown_field(config.planets[select].nodes, select)
    gui.set_text(dropdown_label, config.planets[select].name)
    send_msg()
end

function dropdown.update(action, action_id)
    if gui.is_enabled(dropdown_container) then
        for index, value in ipairs(config.planets) do
            if
                gui.pick_node(value.nodes["dropdown_field_template/planet_name"], action.x, action.y) and
                    index ~= dropdown_current
             then
                toggle_dropdown_field(value.nodes, index)
            elseif
                gui.pick_node(value.nodes["dropdown_field_template/planet_name"], action.x, action.y) and action.pressed
             then
                toggle_selected_field()

                selected_dropdown = dropdown_current
                gui.set_text(dropdown_label, value.name)

                dropdown_current = 0
                send_msg()
            end
        end
    end

    if action_id == config.mouse_click  and action.pressed and not gui.pick_node(dropdown_selector, action.x, action.y) then
        if gui.is_enabled(dropdown_container) then
            toggle_dropdown()
        end
    elseif gui.pick_node(dropdown_selector, action.x, action.y) and action.pressed then
        toggle_dropdown()
    end
end

return dropdown
