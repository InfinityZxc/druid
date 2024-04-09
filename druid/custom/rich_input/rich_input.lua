-- Copyright (c) 2022 Maksim Tuprikov <insality@gmail.com>. This code is licensed under MIT license

--- Druid Rich Input custom component.
-- It's wrapper on Input component with cursor and placeholder text
-- @module RichInput
-- @within Input
-- @alias druid.rich_input

--- The component druid instance
-- @tfield DruidInstance druid @{DruidInstance}

--- Root node
-- @tfield node root

--- On input field text change callback(self, input_text)
-- @tfield Input input @{Input}

--- On input field text change to empty string callback(self, input_text)
-- @tfield node cursor

--- On input field text change to max length string callback(self, input_text)
-- @tfield druid.text placeholder @{Text}

---

local component = require("druid.component")
local helper = require("druid.helper")
local const  = require("druid.const")
local utf8_lua = require("druid.system.utf8")
local utf8 = utf8 or utf8_lua

local RichInput = component.create("druid.rich_input")

local SCHEME = {
	ROOT = "root",
	BUTTON = "button",
	PLACEHOLDER = "placeholder_text",
	INPUT = "input_text",
	CURSOR = "cursor_node",
	CURSOR_TEXT = "cursor_text",
}


local function animate_cursor(self)
	gui.cancel_animation(self.cursor_text, "color.w")
	gui.set_alpha(self.cursor_text, 1)
	gui.animate(self.cursor_text, "color.w", 0, gui.EASING_INSINE, 0.8, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
end


local function set_selection_width(self, selection_width)
	gui.set_visible(self.cursor, selection_width > 0)

	local width = selection_width / self.input.text.scale.x
	local height = gui.get_size(self.cursor).y
	gui.set_size(self.cursor, vmath.vector3(width, height, 0))
end


local function update_text(self)
	local left_text_part = utf8.sub(self.input:get_text(), 0, self.input.start_index)
	local selected_text_part = utf8.sub(self.input:get_text(), self.input.start_index + 1, self.input.end_index)

	local left_part_width = self.input.text:get_text_size(left_text_part)
	local selected_part_width = self.input.text:get_text_size(selected_text_part)

	local text_width = self.input.total_width

	local pivot_text = gui.get_pivot(self.input.text.node)
	local pivot_offset = helper.get_pivot_offset(pivot_text)

	self.cursor_position.x = self.text_position.x - text_width * (0.5 - pivot_offset.x) + left_part_width
	gui.set_position(self.cursor, self.cursor_position)
	gui.set_scale(self.cursor, self.input.text.scale)

	set_selection_width(self, selected_part_width)
end


local function on_select(self)
	gui.set_enabled(self.cursor, true)
	gui.set_enabled(self.placeholder.node, false)
	animate_cursor(self)
end


local function on_unselect(self)
	gui.cancel_animation(self.cursor, gui.PROP_COLOR)
	gui.set_enabled(self.cursor, false)
	gui.set_enabled(self.placeholder.node, true and #self.input:get_text() == 0)
end


--- Update selection
local function update_selection(self, start_index, end_index)
	update_text(self)
end


local function on_touch_start_callback(self, touch)
end


local function on_drag_callback(self)
end


--- The @{RichInput} constructor
-- @tparam RichInput self @{RichInput}
-- @tparam string template The template string name
-- @tparam table nodes Nodes table from gui.clone_tree
function RichInput.init(self, template, nodes)
	self:set_template(template)
	self:set_nodes(nodes)
	self.druid = self:get_druid()
	self.root = self:get_node(SCHEME.ROOT)

	---@type druid.input
	self.input = self.druid:new_input(self:get_node(SCHEME.BUTTON), self:get_node(SCHEME.INPUT))
	self.cursor = self:get_node(SCHEME.CURSOR)
	self.cursor_position = gui.get_position(self.cursor)
	self.cursor_text = self:get_node(SCHEME.CURSOR_TEXT)
	self.drag = self.druid:new_drag(self.root, on_drag_callback)
	self.drag.on_touch_start:subscribe(on_touch_start_callback)
	self.drag:set_input_priority(const.PRIORITY_INPUT_MAX + 1)

	self.input:set_text("")
	self.placeholder = self.druid:new_text(self:get_node(SCHEME.PLACEHOLDER))
	self.text_position = gui.get_position(self.input.text.node)

	self.input.on_input_text:subscribe(update_text)
	self.input.on_input_select:subscribe(on_select)
	self.input.on_input_unselect:subscribe(on_unselect)
	self.input.on_select_cursor_change:subscribe(update_selection)

	on_unselect(self)
	update_text(self, "")
end


--- Component style params.
-- You can override this component styles params in druid styles table
-- or create your own style
-- @table style
function RichInput.on_style_change(self, style)
	self.style = {}
end



--- Set placeholder text
-- @tparam RichInput self @{RichInput}
-- @tparam string placeholder_text The placeholder text
function RichInput.set_placeholder(self, placeholder_text)
	self.placeholder:set_to(placeholder_text)
	return self
end


--- Select input field
-- @tparam RichInput self @{RichInput}
function RichInput.select(self)
	self.input:select()
end


--- Set input field text
-- @tparam RichInput self @{RichInput}
-- @tparam string text The input text
function RichInput.set_text(self, text)
	self.input:set_text(text)
	gui.set_enabled(self.placeholder.node, true and #self.input:get_text() == 0)

	return self
end


function RichInput.set_font(self, font)
	gui.set_font(self.input.text.node, font)
	gui.set_font(self.placeholder.node, font)

	return self
end


--- Set input field text
-- @tparam RichInput self @{RichInput}
function RichInput.get_text(self)
	return self.input:get_text()
end


--- Set allowed charaters for input field.
-- See: https://defold.com/ref/stable/string/
-- ex: [%a%d] for alpha and numeric
-- @tparam RichInput self @{RichInput}
-- @tparam string characters Regulax exp. for validate user input
-- @treturn druid.input Current input instance
function RichInput.set_allowed_characters(self, characters)
	self.input:set_allowed_characters(characters)

	return self
end


return RichInput
