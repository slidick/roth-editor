extends Control

var dbase_data: Dictionary
var copy_command: Dictionary = {}


func _ready() -> void:
	%Tree.create_item()
	%Tree.set_column_title(0, "opcode")
	%Tree.set_column_title(1, "args")
	%Tree.set_column_expand(0, false)
	%Tree.set_column_custom_minimum_width(0, 150)


func reset() -> void:
	dbase_data = {}
	%ActionList.clear()
	%ActionList.get_v_scroll_bar().value = 0
	for tree_item: TreeItem in %Tree.get_root().get_children():
		tree_item.free()
	
	%AddOpcodeButton.disabled = true


func load_dbase(p_dbase_data: Dictionary) -> void:
	reset()
	dbase_data = p_dbase_data
	
	for i in len(dbase_data["dbase100"].actions):
		%ActionList.add_item("%d" % (i+1))
		%ActionList.set_item_metadata(i, dbase_data["dbase100"].actions[i])


func _add_action(p_action: Dictionary = {}) -> void:
	var action: Dictionary = {"commands": []}
	if not p_action.is_empty():
		action = p_action
	var idx: int = %ActionList.add_item(str(%ActionList.item_count+1))
	%ActionList.set_item_metadata(idx, action)
	%ActionList.select(idx)
	_on_action_list_item_selected(idx)
	%ActionList.ensure_current_is_visible()
	dbase_data["dbase100"].actions.append(action)


func _add_command(p_command: Dictionary = {}) -> void:
	var command := {"opcode": 0, "args": 0}
	if not p_command.is_empty():
		command = p_command
	var item: TreeItem = %Tree.get_root().create_child()
	item.set_text(0, str(command.opcode))
	item.set_text(1, str(command.args))
	item.set_metadata(0, command)
	_update_current_action()


func update_integer_preference() -> void:
	if %ActionList.get_selected_items().is_empty():
		return
	for tree_item: TreeItem in %Tree.get_root().get_children():
		var command: Dictionary = tree_item.get_metadata(0)
		if owner.get_hex_preference():
			tree_item.set_text(0, "0x%02X" % command.opcode)
		else:
			tree_item.set_text(0, "%d" % command.opcode)


func _update_current_action() -> void:
	var action: Dictionary = %ActionList.get_item_metadata(%ActionList.get_selected_items()[0])
	var new_commands := []
	for tree_item: TreeItem in %Tree.get_root().get_children():
		var command: Dictionary = tree_item.get_metadata(0)
		if tree_item.get_text(0).is_valid_hex_number(true):
			command.opcode = tree_item.get_text(0).hex_to_int()
		elif tree_item.get_text(0).is_valid_int():
			command.opcode = tree_item.get_text(0).to_int()
		else:
			command.opcode = 0
		
		if owner.get_hex_preference():
			tree_item.set_text(0, "0x%02X" % command.opcode)
		else:
			tree_item.set_text(0, "%d" % command.opcode)
		
		if (command.opcode == 5
				or command.opcode == 8
				or command.opcode == 15
				or command.opcode == 16
		):
			command.args = 0
			if "text_entry" in command and "string" in command.text_entry:
				tree_item.set_text(1, command.text_entry.string)
			else:
				tree_item.set_text(1, "(Empty)")
				command.text_entry = {}
		else:
			if tree_item.get_text(1).is_valid_hex_number(true):
				command.args = tree_item.get_text(1).hex_to_int()
			elif tree_item.get_text(1).is_valid_int():
				command.args = tree_item.get_text(1).to_int()
			else:
				command.args = 0
			tree_item.set_text(1, "%d" % command.args)
			command.erase("text_entry")
		new_commands.append(command)
		
	action.commands = new_commands


func _on_action_list_item_selected(index: int) -> void:
	for tree_item: TreeItem in %Tree.get_root().get_children():
		tree_item.free()
	%AddOpcodeButton.disabled = false
	var action: Dictionary = %ActionList.get_item_metadata(index)
	for command: Dictionary in action.commands:
		_add_tree_item(command)
		

func _add_tree_item(p_command: Dictionary) -> void:
	var tree_item: TreeItem = %Tree.get_root().create_child()
	if owner.get_hex_preference():
		tree_item.set_text(0, "0x%02X" % p_command.opcode)
	else:
		tree_item.set_text(0, "%d" % p_command.opcode)
	tree_item.set_autowrap_mode(1, TextServer.AUTOWRAP_WORD_SMART)
	tree_item.set_metadata(0, p_command)
	if "text_entry" in p_command:
		if "string" in p_command.text_entry:
			tree_item.set_text(1, p_command.text_entry.string)
		else:
			tree_item.set_text(1, "(Empty)")
	else:
		tree_item.set_text(1, "%d" % p_command.args)
	# Needed to update cell spacing after auto-wrap
	await get_tree().process_frame
	%Tree.queue_redraw()


func _on_action_list_item_clicked(_index: int, at_position: Vector2, mouse_button_index: int) -> void:
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			%ActionListPopupMenu.popup(Rect2(%ActionList.global_position.x+at_position.x, %ActionList.global_position.y+at_position.y, 0, 0))


func _on_action_list_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			var action_to_duplicate: Dictionary = %ActionList.get_item_metadata(%ActionList.get_selected_items()[0])
			var new_action: Dictionary = action_to_duplicate.duplicate(true)
			for i in range(len(new_action.commands)):
				var command: Dictionary = new_action.commands[i]
				if "text_entry" in command:
					command.text_entry = action_to_duplicate.commands[i].text_entry
			_add_action(new_action)
		1:
			if not await Dialog.confirm("Clear Command Contents\nAre you sure?", "Confirm?", false, Vector2(400, 150)):
				return
			var action: Dictionary = %ActionList.get_item_metadata(%ActionList.get_selected_items()[0])
			action.commands = []
			_on_action_list_item_selected(%ActionList.get_selected_items()[0])
		2:
			if not await Dialog.confirm("This will alter array order!\nReferences to command will not be updated!\nConfirm delete?", "Warning!", false, Vector2(400,200)):
				return
			var selected_index: int = %ActionList.get_selected_items()[0]
			dbase_data["dbase100"].actions.pop_at(selected_index)
			%ActionList.remove_item(selected_index)
			for i in range(selected_index, %ActionList.item_count):
				%ActionList.set_item_text(i, str(i+1))
			for tree_item: TreeItem in %Tree.get_root().get_children():
				tree_item.free()


func _on_add_action_button_pressed() -> void:
	_add_action()


func _on_tree_item_moved() -> void:
	_update_current_action()


func _on_tree_item_edited() -> void:
	_update_current_action()


func _on_empty_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			_add_command()
		1:
			var command: Dictionary = copy_command.duplicate()
			if "text_entry" in copy_command:
				command.text_entry = copy_command.text_entry
			_add_command(command)


func _on_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			var item: TreeItem = %Tree.get_selected()
			copy_command = item.get_metadata(0).duplicate()
			if "text_entry" in copy_command:
				copy_command.text_entry = item.get_metadata(0).text_entry
		1:
			var item: TreeItem = %Tree.get_selected()
			%Tree.get_root().remove_child(item)
			item.free()
			_update_current_action()


func _on_tree_empty_clicked(click_position: Vector2, mouse_button_index: int) -> void:
	if %ActionList.get_selected_items().is_empty():
		return
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			if copy_command.is_empty():
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
	var tree_item: TreeItem = %Tree.get_selected()
	tree_item.set_editable(0, true)
	if (tree_item.get_text(0) != "5"
			and tree_item.get_text(0) != "8"
			and tree_item.get_text(0) != "15"
			and tree_item.get_text(0) != "16"
	):
		tree_item.set_editable(1, true)
	await get_tree().create_timer(0.5).timeout
	if tree_item:
		tree_item.set_editable(0, false)
		tree_item.set_editable(1, false)


func _on_add_opcode_button_pressed() -> void:
	_add_command()


func jump_to_reference(reference: Dictionary) -> void:
	%ActionList.select(reference.index-1)
	%ActionList.ensure_current_is_visible()
	_on_action_list_item_selected(reference.index-1)
	
	if "sub_index" in reference:
		%Tree.get_root().get_child(reference.sub_index).select(0)
		%Tree.scroll_to_item(%Tree.get_selected())


func _on_tree_item_activated() -> void:
	var tree_item: TreeItem = %Tree.get_selected()
	
	if (tree_item.get_text(0) != "5"
			and tree_item.get_text(0) != "8"
			and tree_item.get_text(0) != "15"
			and tree_item.get_text(0) != "16"
	):
		return
	
	var command: Dictionary = tree_item.get_metadata(0)
	if "text_entry" not in command:
		command.text_entry = {}
	await owner.edit_item_with_text_entry(command)
	if "string" in command.text_entry:
		tree_item.set_text(1, command.text_entry.string)
	else:
		tree_item.set_text(1, "(Empty)")
