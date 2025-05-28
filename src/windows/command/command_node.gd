extends GraphNode
class_name CommandNode

signal refresh
signal add_to_entry_list(index: int)
signal remove_from_entry_list(index: int)
signal delete_command(index: int)

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
		%CommandBaseEdit.text = "%d" % data.commandBase
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


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if index in get_parent().owner.command_section.entryCommandIndexes:
			%CommandPopupMenu.set_item_disabled(0, true)
			%CommandPopupMenu.set_item_disabled(1, false)
		else:
			%CommandPopupMenu.set_item_disabled(0, false)
			%CommandPopupMenu.set_item_disabled(1, true)
		%CommandPopupMenu.popup(Rect2i(int(event.global_position.x), int(event.global_position.y), 0, 0))
		get_viewport().set_input_as_handled()


func save_position() -> void:
	data["node_data"] = Vector2(position_offset)


func _on_command_base_edit_text_changed(new_text: String) -> void:
	data.commandBase = int(new_text)
	update_command_base()
	refresh.emit()


func update_command_base() -> void:
	if data.commandBase == 59:
		%MapNameButton.show()
		%ArgsLabel.show()
	else:
		%MapNameButton.hide()
		%ArgsLabel.hide()


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

func _on_args_tree_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			selected_arg = %ArgsTree.get_item_at_position(mouse_position)
			%ArgsPopupMenu.popup(Rect2i(int(mouse_position.x + %ArgsTree.global_position.x), int(mouse_position.y + %ArgsTree.global_position.y), 0, 0))


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
		1:
			remove_from_entry_list.emit(index)
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
