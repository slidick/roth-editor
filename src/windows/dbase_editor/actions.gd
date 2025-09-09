extends Control

var dbase_data: Dictionary
var copy_opcode: Dictionary = {}


func _ready() -> void:
	%Tree.create_item()
	%Tree.set_column_title(0, "opcode")
	%Tree.set_column_title(1, "value")


func load_dbase(p_dbase_data: Dictionary) -> void:
	dbase_data = p_dbase_data
	
	%ActionList.clear()
	%ActionList.get_v_scroll_bar().value = 0
	for tree_item: TreeItem in %Tree.get_root().get_children():
		tree_item.free()
	
	%AddOpcodeButton.disabled = true
	
	for i in len(dbase_data["dbase100"].actions):
		%ActionList.add_item("%d" % i)
		%ActionList.set_item_metadata(i, dbase_data["dbase100"].actions[i])


func _add_command(p_command: Dictionary = {}) -> void:
	var command: Dictionary = {"opcodes": []}
	if not p_command.is_empty():
		command = p_command
	%ActionList.add_item(str(%ActionList.item_count))
	%ActionList.set_item_metadata(%ActionList.item_count-1, command)
	%ActionList.select(%ActionList.item_count-1)
	_on_action_list_item_selected(%ActionList.item_count-1)
	%ActionList.ensure_current_is_visible()
	dbase_data["dbase100"].actions.append(command)


func _add_opcode(p_opcode: Dictionary = {}) -> void:
	var opcode := {"opcode": "0", "arg": "0"}
	if not p_opcode.is_empty():
		opcode = p_opcode
	var item: TreeItem = %Tree.get_root().create_child()
	item.set_text(0, opcode.opcode)
	item.set_editable(0, true)
	item.set_text(1, opcode.arg)
	item.set_editable(1, true)
	_update_current_command()


func _update_current_command() -> void:
	var command: Dictionary = %ActionList.get_item_metadata(%ActionList.get_selected_items()[0])
	var new_opcodes := []
	for tree_item: TreeItem in %Tree.get_root().get_children():
		var action := {}
		action.command = int(tree_item.get_text(0))
		action.full_value = int(tree_item.get_text(1))
		new_opcodes.append(action)
	command.opcodes = new_opcodes


func _on_action_list_item_selected(index: int) -> void:
	for tree_item: TreeItem in %Tree.get_root().get_children():
		tree_item.free()
	%AddOpcodeButton.disabled = false
	var command_data: Dictionary = %ActionList.get_item_metadata(index)
	for opcode: Dictionary in command_data.opcodes:
		var tree_item: TreeItem = %Tree.get_root().create_child()
		tree_item.set_text(0, "%d" % opcode.command)
		tree_item.set_text(1, "%d" % opcode.full_value)


func _on_action_list_item_clicked(_index: int, at_position: Vector2, mouse_button_index: int) -> void:
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			%ActionListPopupMenu.popup(Rect2(%ActionList.global_position.x+at_position.x, %ActionList.global_position.y+at_position.y, 0, 0))


func _on_action_list_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			var new_command: Dictionary = %ActionList.get_item_metadata(%ActionList.get_selected_items()[0]).duplicate(true)
			_add_command(new_command)
		1:
			if not await Dialog.confirm("Clear Command Contents\nAre you sure?", "Confirm?", false, Vector2(400, 150)):
				return
			var command: Dictionary = %ActionList.get_item_metadata(%ActionList.get_selected_items()[0])
			command.opcodes = []
			_on_action_list_item_selected(%ActionList.get_selected_items()[0])
		2:
			if not await Dialog.confirm("This will alter array order!\nReferences to command will not be updated!\nConfirm Delete?", "Warning!", false, Vector2(400,200)):
				return
			var selected_index: int = %ActionList.get_selected_items()[0]
			dbase_data["dbase100"].actions.pop_at(selected_index)
			%ActionList.remove_item(selected_index)
			for i in range(selected_index, %ActionList.item_count):
				%ActionList.set_item_text(i, str(i))
			for tree_item: TreeItem in %Tree.get_root().get_children():
				tree_item.free()


func _on_add_action_button_pressed() -> void:
	_add_command()


func _on_tree_item_moved() -> void:
	_update_current_command()


func _on_tree_item_edited() -> void:
	_update_current_command()


func _on_empty_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			_add_opcode()
		1:
			_add_opcode(copy_opcode.duplicate())


func _on_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			var item: TreeItem = %Tree.get_selected()
			copy_opcode = {"opcode": item.get_text(0), "arg": item.get_text(1)}
		1:
			var item: TreeItem = %Tree.get_selected()
			%Tree.get_root().remove_child(item)
			item.free()
			_update_current_command()


func _on_tree_empty_clicked(click_position: Vector2, mouse_button_index: int) -> void:
	if %ActionList.get_selected_items().is_empty():
		return
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			if copy_opcode.is_empty():
				%EmptyPopupMenu.set_item_disabled(1, true)
			else:
				%EmptyPopupMenu.set_item_disabled(1, false)
			%EmptyPopupMenu.popup(Rect2i(int(%Tree.global_position.x+click_position.x), int(%Tree.global_position.y+click_position.y), 0, 0))
		MOUSE_BUTTON_LEFT:
			%Tree.deselect_all()
			%Tree.release_focus()


func _on_tree_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			%PopupMenu.popup(Rect2i(int(%Tree.global_position.x+mouse_position.x), int(%Tree.global_position.y+mouse_position.y), 0, 0))


func _on_tree_item_selected() -> void:
	# Work-around to simulate edit only on double click
	var tree_item: TreeItem = %Tree.get_selected()
	tree_item.set_editable(0, true)
	tree_item.set_editable(1, true)
	await get_tree().create_timer(0.5).timeout
	if tree_item:
		tree_item.set_editable(0, false)
		tree_item.set_editable(1, false)


func _on_add_opcode_button_pressed() -> void:
	_add_opcode()
