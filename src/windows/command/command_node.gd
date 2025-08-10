extends GraphNode
class_name CommandNode

signal refresh
signal add_to_entry_list(index: int)
signal remove_from_entry_list(index: int)
signal delete_command(index: int)


const command_list: Array = [
	{"command_base": 1, "number_of_args": 0, "can_be_entry_command": false, "arg1_is_flags": true, "name": ""},
	{"command_base": 2, "number_of_args": 5, "can_be_entry_command": true, "arg1_is_flags": true, "name": ""},
	{"command_base": 3, "number_of_args": 8, "can_be_entry_command": true, "arg1_is_flags": true, "name": ""},
	{"command_base": 7, "number_of_args": 7, "can_be_entry_command": false, "arg1_is_flags": true, "name": "Change Floor/Ceiling Height"},
	{"command_base": 8, "number_of_args": 3, "can_be_entry_command": true, "arg1_is_flags": true, "name": "Left-Click Object", "flag_1": "No Switch", "flag_2": "Remove After", "flag_5": "Only Once", "arg_1": "Flags", "arg_2": "Object ID"},
	{"command_base": 9, "number_of_args": 6, "can_be_entry_command": false, "arg1_is_flags": true, "name": ""},
	{"command_base": 10, "number_of_args": 5, "can_be_entry_command": false, "arg1_is_flags": true, "name": ""},
	{"command_base": 12, "number_of_args": 8, "can_be_entry_command": false, "arg1_is_flags": true, "name": ""},
	{"command_base": 13, "number_of_args": 4, "can_be_entry_command": false, "arg1_is_flags": true, "name": ""},
	{"command_base": 14, "number_of_args": 3, "can_be_entry_command": false, "arg1_is_flags": true, "name": ""},
	{"command_base": 15, "number_of_args": 3, "can_be_entry_command": false, "arg1_is_flags": true, "name": ""},
	{"command_base": 16, "number_of_args": 2, "can_be_entry_command": false, "arg1_is_flags": true, "name": "Activate SFX Node"},
	{"command_base": 17, "number_of_args": 3, "can_be_entry_command": false, "arg1_is_flags": true, "name": ""},
	{"command_base": 18, "number_of_args": 1, "can_be_entry_command": false, "arg1_is_flags": true, "name": "Timer"},
	{"command_base": 19, "number_of_args": 3, "can_be_entry_command": true, "arg1_is_flags": true, "name": "Sector Trigger", "flag_5": "Only Once", "flag_9": "In Air"},
	{"command_base": 21, "number_of_args": 4, "can_be_entry_command": false, "arg1_is_flags": true, "name": ""},
	{"command_base": 22, "number_of_args": 2, "can_be_entry_command": false, "arg1_is_flags": true, "name": "Spawn Item"},
	{"command_base": 23, "number_of_args": 2, "can_be_entry_command": false, "arg1_is_flags": true, "name": ""},
	{"command_base": 24, "number_of_args": 7, "can_be_entry_command": true, "arg1_is_flags": true, "name": "Left-Click Face"},
	{"command_base": 25, "number_of_args": 7, "can_be_entry_command": true, "arg1_is_flags": true, "name": "Left-Click Floor"},
	{"command_base": 26, "number_of_args": 3, "can_be_entry_command": true, "arg1_is_flags": true, "name": ""},
	{"command_base": 27, "number_of_args": 3, "can_be_entry_command": true, "arg1_is_flags": true, "name": ""},
	{"command_base": 28, "number_of_args": 3, "can_be_entry_command": false, "arg1_is_flags": true, "name": ""},
	{"command_base": 29, "number_of_args": 2, "can_be_entry_command": false, "arg1_is_flags": true, "name": ""},
	{"command_base": 30, "number_of_args": 3, "can_be_entry_command": false, "arg1_is_flags": true, "name": ""},
	{"command_base": 31, "number_of_args": 6, "can_be_entry_command": false, "arg1_is_flags": true, "name": ""},
	{"command_base": 32, "number_of_args": 3, "can_be_entry_command": false, "arg1_is_flags": true, "name": ""},
	{"command_base": 34, "number_of_args": 6, "can_be_entry_command": false, "arg1_is_flags": true, "name": ""},
	{"command_base": 35, "number_of_args": 7, "can_be_entry_command": false, "arg1_is_flags": true, "name": ""},
	{"command_base": 36, "number_of_args": 3, "can_be_entry_command": false, "arg1_is_flags": true, "name": ""},
	{"command_base": 37, "number_of_args": 4, "can_be_entry_command": true, "arg1_is_flags": true, "name": ""},
	{"command_base": 38, "number_of_args": 2, "can_be_entry_command": false, "arg1_is_flags": true, "name": "Set/Unset Flag"},
	{"command_base": 39, "number_of_args": 2, "can_be_entry_command": false, "arg1_is_flags": true, "name": "Item Check"},
	{"command_base": 40, "number_of_args": 2, "can_be_entry_command": false, "arg1_is_flags": true, "name": "If not flag -> continue"},
	{"command_base": 41, "number_of_args": 2, "can_be_entry_command": false, "arg1_is_flags": true, "name": "Give Item"},
	{"command_base": 42, "number_of_args": 2, "can_be_entry_command": false, "arg1_is_flags": true, "name": "Remove Item?"},
	{"command_base": 43, "number_of_args": 2, "can_be_entry_command": false, "arg1_is_flags": true, "name": "DBase100 Command", "flag_5": "Only Once"},
	{"command_base": 45, "number_of_args": 2, "can_be_entry_command": false, "arg1_is_flags": true, "name": ""},
	{"command_base": 46, "number_of_args": 2, "can_be_entry_command": false, "arg1_is_flags": true, "name": ""},
	{"command_base": 47, "number_of_args": 6, "can_be_entry_command": false, "arg1_is_flags": true, "name": "Open Door"},
	{"command_base": 48, "number_of_args": 3, "can_be_entry_command": true, "arg1_is_flags": true, "name": "Right-click Object"},
	{"command_base": 49, "number_of_args": 7, "can_be_entry_command": true, "arg1_is_flags": true, "name": "Right-click Floor"},
	{"command_base": 50, "number_of_args": 7, "can_be_entry_command": true, "arg1_is_flags": true, "name": "Right-click Face", "flag_1": "Enabled"},
	{"command_base": 51, "number_of_args": 3, "can_be_entry_command": false, "arg1_is_flags": true, "name": "Apply Damage"},
	{"command_base": 52, "number_of_args": 3, "can_be_entry_command": false, "arg1_is_flags": true, "name": ""},
	{"command_base": 53, "number_of_args": 4, "can_be_entry_command": false, "arg1_is_flags": true, "name": ""},
	{"command_base": 54, "number_of_args": 2, "can_be_entry_command": false, "arg1_is_flags": true, "name": "DBase100 Command; Only if next command fails?"},
	{"command_base": 55, "number_of_args": 3, "can_be_entry_command": true, "arg1_is_flags": true, "name": ""},
	{"command_base": 56, "number_of_args": 2, "can_be_entry_command": false, "arg1_is_flags": true, "name": "Different Command Check"},
	{"command_base": 57, "number_of_args": 3, "can_be_entry_command": true, "arg1_is_flags": true, "name": ""},
	{"command_base": 58, "number_of_args": 1, "can_be_entry_command": false, "arg1_is_flags": true, "name": ""},
	{"command_base": 59, "number_of_args": 6, "can_be_entry_command": false, "arg1_is_flags": true, "name": "Map Transition / Warp", "flag_5": "Only Once"},
	{"command_base": 60, "number_of_args": 5, "can_be_entry_command": false, "arg1_is_flags": true, "name": "Spawn Entity"},
	{"command_base": 61, "number_of_args": 2, "can_be_entry_command": false, "arg1_is_flags": true, "name": ""},
	{"command_base": 62, "number_of_args": 0, "can_be_entry_command": false, "arg1_is_flags": true, "name": ""},
	{"command_base": 63, "number_of_args": 1, "can_be_entry_command": false, "arg1_is_flags": false, "name": "Player Rotation"},
	{"command_base": 64, "number_of_args": 1, "can_be_entry_command": false, "arg1_is_flags": true, "name": ""},
	{"command_base": 65, "number_of_args": 1, "can_be_entry_command": false, "arg1_is_flags": true, "name": ""},
	{"command_base": 66, "number_of_args": 1, "can_be_entry_command": false, "arg1_is_flags": true, "name": ""},
]

var current_command: Dictionary

var index: int = 0 :
	get():
		return index
	set(new_value):
		index = new_value
		%CommandIndexEdit.text = "%d" % index
var data: Dictionary = {}
var selected_arg: TreeItem
var command_base: int :
	get():
		return data.commandBase
	set(new_value):
		data.commandBase = new_value
		#%CommandBaseEdit.text = "%d" % data.commandBase
		for i in range(%CommandBaseOption.item_count):
			if data.commandBase == %CommandBaseOption.get_item_metadata(i).command_base:
				%CommandBaseOption.select(i)
				current_command = %CommandBaseOption.get_item_metadata(i)
		
		update_command_base()


var command_modifier: int :
	get():
		return data.commandModifier
	set(new_value):
		data.commandModifier = new_value
		%CommandModifierEdit.text = "%d" % data.commandModifier

var next_command_index: int :
	get():
		return data.nextCommandIndex
	set(new_value):
		for conn: Dictionary in get_parent().connections:
			if conn.from_node == self.name and conn.from_port == 0:
				get_parent().disconnect_node(conn.from_node, conn.from_port, conn.to_node, conn.to_port)
		data.nextCommandIndex = new_value
		%CommandNextCommandIndexEdit.text = "%d" % data.nextCommandIndex
		if data.nextCommandIndex != 0:
			for command_node: Node in get_parent().get_children():
				if command_node is CommandNode:
					if command_node.index == data.nextCommandIndex:
						get_parent().connect_node(self.name, 0, command_node.name, 0)
		refresh.emit()

var args: Array :
	get():
		return data.args
	set(new_value):
		for tree_item: TreeItem in %ArgsTree.get_root().get_children():
			tree_item.free()
		%ArgsLabel.text = ""
		var i: int = 0
		for value: int in new_value:
			var tree_item: TreeItem = %ArgsTree.get_root().create_child()
			tree_item.set_text(0, "%d" % value)
			tree_item.set_editable(0, true)
			if i >= 2:
				%ArgsLabel.text += String.chr((value) & 0xFF)
				%ArgsLabel.text += String.chr((value >> 8) & 0xFF)
			i += 1
		data.args = new_value 


func initialize(p_index: int, p_data: Dictionary) -> void:
	index = p_index
	data = p_data


func _ready() -> void:
	var style_box := StyleBoxFlat.new()
	style_box.bg_color = Color("#3399cc")
	var style_box_header := StyleBoxFlat.new()
	style_box_header.bg_color = Color("#8877ee")
	var style_box_header_selected := StyleBoxFlat.new()
	style_box_header_selected.bg_color = Color("#442277")
	
	title = "Command"
	add_theme_stylebox_override("panel", style_box)
	add_theme_stylebox_override("panel_selected", style_box)
	add_theme_stylebox_override("titlebar", style_box_header)
	add_theme_stylebox_override("titlebar_selected", style_box_header_selected)
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
	
	var idx: int = 0
	for command: Dictionary in command_list:
		%CommandBaseOption.add_item("%s%s: %s" % ["*" if command.can_be_entry_command else "", command.command_base, command.name])
		%CommandBaseOption.set_item_metadata(idx, command)
		idx += 1
	
	
	
	%CommandIndexEdit.text = "%d" % index
	command_base = data.commandBase
	%CommandModifierEdit.text = "%d" % data.commandModifier
	%CommandNextCommandIndexEdit.text = "%d" % data.nextCommandIndex
	%ArgsTree.create_item()
	for child: TreeItem in %ArgsTree.get_root().get_children():
		%ArgsTree.get_root().remove_child(child)
		child.free()
	%ArgsLabel.text = ""
	var i: int = 0
	for value: int in data.args:
		var tree_item: TreeItem = %ArgsTree.get_root().create_child()
		tree_item.set_text(0, "%d" % value)
		tree_item.set_editable(0, true)
		if i >= 2:
			%ArgsLabel.text += String.chr((value) & 0xFF)
			%ArgsLabel.text += String.chr((value >> 8) & 0xFF)
		i += 1
	update_command_base()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if index in get_parent().owner.command_section.entryCommandIndexes:
			%CommandPopupMenu.set_item_disabled(0, true)
			%CommandPopupMenu.set_item_disabled(1, false)
		else:
			if current_command.can_be_entry_command:
				%CommandPopupMenu.set_item_disabled(0, false)
			else:
				%CommandPopupMenu.set_item_disabled(0, true)
			%CommandPopupMenu.set_item_disabled(1, true)
		%CommandPopupMenu.popup(Rect2i(int(event.global_position.x), int(event.global_position.y), 0, 0))
		get_viewport().set_input_as_handled()


func save_position() -> void:
	data["node_data"] = Vector2(position_offset)


func _on_command_base_option_item_selected(idx: int) -> void:
	data.commandBase = %CommandBaseOption.get_item_metadata(idx).command_base
	current_command = %CommandBaseOption.get_item_metadata(idx)
	update_command_base()
	refresh.emit()


func update_command_base() -> void:
	if index in get_parent().owner.command_section.entryCommandIndexes:
		%CommandBaseOption.disabled = true
	else:
		%CommandBaseOption.disabled = false
	
	if data.commandBase == 59:
		%MapNameButton.show()
		%ArgsLabel.show()
	else:
		%MapNameButton.hide()
		%ArgsLabel.hide()
	
	if current_command.arg1_is_flags:
		%FlagsContainer.show()
	else:
		%FlagsContainer.hide()
	
	
	if not %ArgsTree.get_root():
		return
	
	# Store previous args
	var arg_array := []
	for tree_item: TreeItem in %ArgsTree.get_root().get_children():
		arg_array.append(int(tree_item.get_text(0)))
	
	# Clear args tree
	for tree_item: TreeItem in %ArgsTree.get_root().get_children():
		tree_item.free()
	
	
	# Setup args tree based on number of args and reenter previous values
	for i in range(current_command.number_of_args):
		var tree_item: TreeItem = %ArgsTree.get_root().create_child()
		tree_item.set_text(0, "%d" % (arg_array[i] if len(arg_array) > i else 0))
		if i == 0 and current_command.arg1_is_flags:
			tree_item.set_editable(0, false)
		else:
			tree_item.set_editable(0, true)
		%ArgsTree.scroll_to_item(tree_item)
	
	# Recollect values and save into data
	arg_array = []
	for tree_item: TreeItem in %ArgsTree.get_root().get_children():
		arg_array.append(int(tree_item.get_text(0)))
	data.args = arg_array
	
	# Update MapName label
	%ArgsLabel.text = ""
	for value: int in arg_array.slice(2):
		%ArgsLabel.text += String.chr((value) & 0xFF)
		%ArgsLabel.text += String.chr((value >> 8) & 0xFF)
	
	
	if current_command.arg1_is_flags and len(arg_array) > 0:
		%FlagButton1.button_pressed = (arg_array[0] & (1 << 0)) > 0
		%FlagButton2.button_pressed = (arg_array[0] & (1 << 1)) > 0
		%FlagButton3.button_pressed = (arg_array[0] & (1 << 2)) > 0
		%FlagButton4.button_pressed = (arg_array[0] & (1 << 3)) > 0
		%FlagButton5.button_pressed = (arg_array[0] & (1 << 4)) > 0
		%FlagButton6.button_pressed = (arg_array[0] & (1 << 5)) > 0
		%FlagButton7.button_pressed = (arg_array[0] & (1 << 6)) > 0
		%FlagButton8.button_pressed = (arg_array[0] & (1 << 7)) > 0
		%FlagButton9.button_pressed = (arg_array[0] & (1 << 8)) > 0
		%FlagButton10.button_pressed = (arg_array[0] & (1 << 9)) > 0
		%FlagButton11.button_pressed = (arg_array[0] & (1 << 10)) > 0
		%FlagButton12.button_pressed = (arg_array[0] & (1 << 11)) > 0
		%FlagButton13.button_pressed = (arg_array[0] & (1 << 12)) > 0
		%FlagButton14.button_pressed = (arg_array[0] & (1 << 13)) > 0
		%FlagButton15.button_pressed = (arg_array[0] & (1 << 14)) > 0
		%FlagButton16.button_pressed = (arg_array[0] & (1 << 15)) > 0
		
		
		%FlagButton1.text = current_command.flag_1 if "flag_1" in current_command else "Flag 1"
		%FlagButton2.text = current_command.flag_2 if "flag_2" in current_command else "Flag 2"
		%FlagButton3.text = current_command.flag_3 if "flag_3" in current_command else "Flag 3"
		%FlagButton4.text = current_command.flag_4 if "flag_4" in current_command else "Flag 4"
		%FlagButton5.text = current_command.flag_5 if "flag_5" in current_command else "Flag 5"
		%FlagButton6.text = current_command.flag_6 if "flag_6" in current_command else "Flag 6"
		%FlagButton7.text = current_command.flag_7 if "flag_7" in current_command else "Flag 7"
		%FlagButton8.text = current_command.flag_8 if "flag_8" in current_command else "Flag 8"
		%FlagButton9.text = current_command.flag_9 if "flag_9" in current_command else "Flag 9"
		%FlagButton10.text = current_command.flag_10 if "flag_10" in current_command else "Flag 10"
		%FlagButton11.text = current_command.flag_11 if "flag_11" in current_command else "Flag 11"
		%FlagButton12.text = current_command.flag_12 if "flag_12" in current_command else "Flag 12"
		%FlagButton13.text = current_command.flag_13 if "flag_13" in current_command else "Flag 13"
		%FlagButton14.text = current_command.flag_14 if "flag_14" in current_command else "Flag 14"
		%FlagButton15.text = current_command.flag_15 if "flag_15" in current_command else "Flag 15"
		%FlagButton16.text = current_command.flag_16 if "flag_16" in current_command else "Flag 16"
		
		%FlagButton1.tooltip_text = current_command.flag_1 if "flag_1" in current_command else "Flag 1"
		%FlagButton2.tooltip_text = current_command.flag_2 if "flag_2" in current_command else "Flag 2"
		%FlagButton3.tooltip_text = current_command.flag_3 if "flag_3" in current_command else "Flag 3"
		%FlagButton4.tooltip_text = current_command.flag_4 if "flag_4" in current_command else "Flag 4"
		%FlagButton5.tooltip_text = current_command.flag_5 if "flag_5" in current_command else "Flag 5"
		%FlagButton6.tooltip_text = current_command.flag_6 if "flag_6" in current_command else "Flag 6"
		%FlagButton7.tooltip_text = current_command.flag_7 if "flag_7" in current_command else "Flag 7"
		%FlagButton8.tooltip_text = current_command.flag_8 if "flag_8" in current_command else "Flag 8"
		%FlagButton9.tooltip_text = current_command.flag_9 if "flag_9" in current_command else "Flag 9"
		%FlagButton10.tooltip_text = current_command.flag_10 if "flag_10" in current_command else "Flag 10"
		%FlagButton11.tooltip_text = current_command.flag_11 if "flag_11" in current_command else "Flag 11"
		%FlagButton12.tooltip_text = current_command.flag_12 if "flag_12" in current_command else "Flag 12"
		%FlagButton13.tooltip_text = current_command.flag_13 if "flag_13" in current_command else "Flag 13"
		%FlagButton14.tooltip_text = current_command.flag_14 if "flag_14" in current_command else "Flag 14"
		%FlagButton15.tooltip_text = current_command.flag_15 if "flag_15" in current_command else "Flag 15"
		%FlagButton16.tooltip_text = current_command.flag_16 if "flag_16" in current_command else "Flag 16"
		
	
	refresh.emit()


func _on_command_modifier_edit_text_changed(new_text: String) -> void:
	data.commandModifier = int(new_text)
	refresh.emit()


func _on_command_next_command_index_edit_text_changed(new_text: String) -> void:
	data.nextCommandIndex = int(new_text)
	refresh.emit()


func update_args_array() -> void:
	var arg_array := []
	for tree_item: TreeItem in %ArgsTree.get_root().get_children():
		arg_array.append(int(tree_item.get_text(0)))
	data.args = arg_array
	%ArgsLabel.text = ""
	for value: int in arg_array.slice(2):
		%ArgsLabel.text += String.chr((value) & 0xFF)
		%ArgsLabel.text += String.chr((value >> 8) & 0xFF)
	refresh.emit()


func _on_args_tree_item_edited() -> void:
	update_args_array()


func _on_args_tree_item_moved() -> void:
	update_args_array()


func _on_add_arg_button_pressed() -> void:
	var tree_item: TreeItem = %ArgsTree.get_root().create_child()
	tree_item.set_text(0, "0")
	tree_item.set_editable(0, true)
	%ArgsTree.scroll_to_item(tree_item)
	update_args_array()

func _on_args_tree_item_mouse_selected(_mouse_position: Vector2, _mouse_button_index: int) -> void:
	pass
	#match mouse_button_index:
		#MOUSE_BUTTON_RIGHT:
			#selected_arg = %ArgsTree.get_item_at_position(mouse_position)
			#%ArgsPopupMenu.popup(Rect2i(int(mouse_position.x + %ArgsTree.global_position.x), int(mouse_position.y + %ArgsTree.global_position.y), 0, 0))


func _on_args_popup_menu_index_pressed(_index: int) -> void:
	match _index:
		0:
			%ArgsTree.get_root().remove_child(selected_arg)
			selected_arg.free()
			selected_arg = null
			update_args_array()


func _on_command_popup_menu_index_pressed(_index: int) -> void:
	match _index:
		0:
			add_to_entry_list.emit(index)
			update_command_base()
		1:
			remove_from_entry_list.emit(index)
			update_command_base()
		2:
			delete_command.emit(index)


func _on_map_name_button_pressed() -> void:
	var results: Array = await Dialog.input("Map Name:", "Enter Map Name", "", "", false)
	if not results[0]:
		return
	while len(%ArgsTree.get_root().get_children()) < 6:
		var tree_item: TreeItem = %ArgsTree.get_root().create_child()
		tree_item.set_text(0, "0")
		tree_item.set_editable(0, true)
	
	var value: int = 0
	if len(results[1]) > 0:
		value = results[1].unicode_at(0)
	if len(results[1]) > 1:
		value += (results[1].unicode_at(1) << 8)
	%ArgsTree.get_root().get_child(2).set_text(0, "%d" % value)
	
	value = 0
	if len(results[1]) > 2:
		value = results[1].unicode_at(2)
	if len(results[1]) > 3:
		value += (results[1].unicode_at(3) << 8)
	%ArgsTree.get_root().get_child(3).set_text(0, "%d" % value)
	
	value = 0
	if len(results[1]) > 4:
		value = results[1].unicode_at(4)
	if len(results[1]) > 5:
		value += (results[1].unicode_at(5) << 8)
	%ArgsTree.get_root().get_child(4).set_text(0, "%d" % value)
	
	value = 0
	if len(results[1]) > 6:
		value = results[1].unicode_at(6)
	if len(results[1]) > 7:
		value += (results[1].unicode_at(7) << 8)
	%ArgsTree.get_root().get_child(5).set_text(0, "%d" % value)
	
	update_args_array()


func _on_flag_button_toggled(toggled_on: bool, shift: int) -> void:
	var arg1 := int(%ArgsTree.get_root().get_first_child().get_text(0))
	if toggled_on:
		arg1 |= (1 << shift)
	else:
		arg1 &= ~(1 << shift)
	%ArgsTree.get_root().get_first_child().set_text(0, "%d" % arg1)
	update_args_array()
