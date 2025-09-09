extends Control

var dbase_data: Dictionary = {}
var copy_trigger: Dictionary = {}
var copy_opcode: Dictionary = {}


func _ready() -> void:
	%Tree.set_column_title(0, "opcode")
	%Tree.set_column_title(1, "value")
	%Tree.create_item()
	
	%TriggerTree.set_column_title(0, "Trigger")
	%TriggerTree.create_item()


func _reset() -> void:
	%InventoryList.clear()
	%InventoryList.get_v_scroll_bar().value = 0
	_reset_item()

func _reset_item() -> void:
	for tree_item: TreeItem in %TriggerTree.get_root().get_children():
		tree_item.free()
	for tree_item: TreeItem in %Tree.get_root().get_children():
		tree_item.free()
	%ObjectTextureIndexEdit.text = ""
	%CloseUpTypeEdit.text = ""
	%ItemTypeEdit.text = ""
	%CloseUpImageOffsetEdit.text = ""
	%InventoryImageOffsetEdit.text = ""
	%NameOffsetEdit.text = ""
	
	%ObjectTextureIndexEdit.editable = false
	%CloseUpTypeEdit.editable = false
	%ItemTypeEdit.editable = false
	%CloseUpImageOffsetEdit.editable = false
	%InventoryImageOffsetEdit.editable = false
	%NameOffsetEdit.editable = false
	%AddTriggerButton.disabled = true
	%AddOpcodeButton.disabled = true


func load_dbase(p_dbase_data: Dictionary) -> void:
	dbase_data = p_dbase_data
	_reset()
	
	for i in range(len(dbase_data["dbase100"].inventory)):
		var inventory_item: Dictionary = dbase_data["dbase100"].inventory[i]
		var idx: int = %InventoryList.add_item("%d: %s" % [(i+1), inventory_item.subtitle.string])
		%InventoryList.set_item_metadata(idx, inventory_item)


func _add_inventory_item(p_inventory_item: Dictionary = {}) -> void:
	var inventory_item: Dictionary = {
		"closeup_image": 0,
		"closeup_type": 0,
		"commands_section": [],
		"inventory_image": 0,
		"item_type": 0,
		"object_texture_index": 0,
		"offset_dbase400": 0,
		"subtitle": {
			"string": ""
		}
	}
	if not p_inventory_item.is_empty():
		inventory_item = p_inventory_item
	var idx: int = %InventoryList.add_item("%d: %s" % [(%InventoryList.item_count+1), inventory_item.subtitle.string])
	%InventoryList.set_item_metadata(idx, inventory_item)
	%InventoryList.select(idx)
	_on_inventory_list_item_selected(idx)
	%InventoryList.ensure_current_is_visible()
	dbase_data["dbase100"].inventory.append(inventory_item)


func _add_trigger(p_command: Dictionary = {}) -> void:
	var command: Dictionary = {"trigger": 0, "commands": []}
	if not p_command.is_empty():
		command = p_command
	var tree_item: TreeItem = %TriggerTree.get_root().create_child()
	tree_item.set_text(0, str(command.trigger))
	tree_item.set_metadata(0, command)
	_update_triggers()


func _update_triggers() -> void:
	var inventory_item: Dictionary = %InventoryList.get_item_metadata(%InventoryList.get_selected_items()[0])
	var commands := []
	for tree_item: TreeItem in %TriggerTree.get_root().get_children():
		var command: Dictionary = tree_item.get_metadata(0)
		command.trigger = int(tree_item.get_text(0))
		commands.append(command)
	inventory_item.commands_section = commands


func _add_opcode(p_opcode: Dictionary = {}) -> void:
	var opcode: Dictionary = {"command": "0", "arg": "0"}
	if not p_opcode.is_empty():
		opcode = p_opcode
	var item: TreeItem = %Tree.get_root().create_child()
	item.set_text(0, opcode.command)
	item.set_editable(0, true)
	item.set_text(1, opcode.arg)
	item.set_editable(1, true)
	_update_opcodes()


func _update_opcodes() -> void:
	var command: Dictionary = %TriggerTree.get_selected().get_metadata(0)
	var new_opcodes := []
	for tree_item: TreeItem in %Tree.get_root().get_children():
		var action := {}
		action.opcode = int(tree_item.get_text(0))
		action.args = int(tree_item.get_text(1))
		new_opcodes.append(action)
	command.commands = new_opcodes


func _on_inventory_list_item_selected(index: int) -> void:
	var inventory_item: Dictionary = %InventoryList.get_item_metadata(index)
	%ObjectTextureIndexEdit.text = str(inventory_item.object_texture_index)
	%CloseUpTypeEdit.text = str(inventory_item.closeup_type)
	%ItemTypeEdit.text = str(inventory_item.item_type)
	%CloseUpImageOffsetEdit.text = str(inventory_item.closeup_image)
	%InventoryImageOffsetEdit.text = str(inventory_item.inventory_image)
	%NameOffsetEdit.text = str(inventory_item.offset_dbase400)
	%ObjectTextureIndexEdit.editable = true
	%CloseUpTypeEdit.editable = true
	%ItemTypeEdit.editable = true
	%CloseUpImageOffsetEdit.editable = true
	%InventoryImageOffsetEdit.editable = true
	%NameOffsetEdit.editable = true
	%AddTriggerButton.disabled = false
	%AddOpcodeButton.disabled = true
	
	
	for tree_item: TreeItem in %TriggerTree.get_root().get_children():
		tree_item.free()
	for tree_item: TreeItem in %Tree.get_root().get_children():
		tree_item.free()
	
	for trigger: Dictionary in inventory_item.commands_section:
		var tree_item: TreeItem = %TriggerTree.get_root().create_child()
		tree_item.set_text(0, str(trigger.trigger))
		tree_item.set_metadata(0, trigger)


func _on_inventory_list_item_clicked(_index: int, at_position: Vector2, mouse_button_index: int) -> void:
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			%InventoryListPopupMenu.popup(Rect2(%InventoryList.global_position.x+at_position.x, %InventoryList.global_position.y+at_position.y, 0, 0))


func _on_inventory_list_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			var inventory_item: Dictionary = %InventoryList.get_item_metadata(%InventoryList.get_selected_items()[0]).duplicate(true)
			_add_inventory_item(inventory_item)
		1:
			if not await Dialog.confirm("This will alter array order!\nReferences to item will not be updated!\nConfirm Delete?", "Warning!", false, Vector2(400,200)):
				return
			var selected_index: int = %InventoryList.get_selected_items()[0]
			dbase_data["dbase100"].inventory.pop_at(selected_index)
			%InventoryList.remove_item(selected_index)
			for i in range(selected_index, %InventoryList.item_count):
				%InventoryList.set_item_text(i, "%d: %s" % [(i+1), dbase_data["dbase100"].inventory[i].subtitle.string])
			_reset_item()


func _on_add_inventory_button_pressed() -> void:
	_add_inventory_item()


func _on_object_texture_index_edit_text_changed(new_text: String) -> void:
	var inventory_item: Dictionary = %InventoryList.get_item_metadata(%InventoryList.get_selected_items()[0])
	inventory_item.object_texture_index = int(new_text)


func _on_close_up_type_edit_text_changed(new_text: String) -> void:
	var inventory_item: Dictionary = %InventoryList.get_item_metadata(%InventoryList.get_selected_items()[0])
	inventory_item.closeup_type = int(new_text)


func _on_item_type_edit_text_changed(new_text: String) -> void:
	var inventory_item: Dictionary = %InventoryList.get_item_metadata(%InventoryList.get_selected_items()[0])
	inventory_item.item_type = int(new_text)


func _on_close_up_image_offset_edit_text_changed(new_text: String) -> void:
	var inventory_item: Dictionary = %InventoryList.get_item_metadata(%InventoryList.get_selected_items()[0])
	inventory_item.closeup_image = int(new_text)


func _on_inventory_image_offset_edit_text_changed(new_text: String) -> void:
	var inventory_item: Dictionary = %InventoryList.get_item_metadata(%InventoryList.get_selected_items()[0])
	inventory_item.inventory_image = int(new_text)


func _on_name_offset_edit_text_changed(new_text: String) -> void:
	var inventory_item: Dictionary = %InventoryList.get_item_metadata(%InventoryList.get_selected_items()[0])
	inventory_item.offset_dbase400 = int(new_text)


func _on_trigger_tree_item_selected() -> void:
	%AddOpcodeButton.disabled = false
	for tree_item: TreeItem in %Tree.get_root().get_children():
		tree_item.free()
	var selected_item: TreeItem = %TriggerTree.get_selected()
	for command: Dictionary in selected_item.get_metadata(0).commands:
		var tree_item: TreeItem = %Tree.get_root().create_child()
		tree_item.set_text(0, "%d" % command.opcode)
		tree_item.set_text(1, "%d" % command.args)
	
	# Work-around to simulate edit only on double click
	selected_item.set_editable(0, true)
	await get_tree().create_timer(0.5).timeout
	if selected_item:
		selected_item.set_editable(0, false)


func _on_add_trigger_button_pressed() -> void:
	_add_trigger()


func _on_trigger_tree_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			%TriggerPopupMenu.popup(Rect2(%TriggerTree.global_position.x+mouse_position.x, %TriggerTree.global_position.y+mouse_position.y, 0, 0))


func _on_trigger_tree_empty_clicked(click_position: Vector2, mouse_button_index: int) -> void:
	if %InventoryList.get_selected_items().is_empty():
		return
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			if copy_trigger.is_empty():
				%TriggerEmptyPopupMenu.set_item_disabled(1, true)
			else:
				%TriggerEmptyPopupMenu.set_item_disabled(1, false)
			%TriggerEmptyPopupMenu.popup(Rect2(%TriggerTree.global_position.x+click_position.x, %TriggerTree.global_position.y+click_position.y, 0, 0))


func _on_trigger_tree_item_edited() -> void:
	_update_triggers()


func _on_trigger_tree_item_moved() -> void:
	_update_triggers()


func _on_trigger_empty_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			_add_trigger()
		1:
			_add_trigger(copy_trigger.duplicate(true))


func _on_trigger_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			copy_trigger = %TriggerTree.get_selected().get_metadata(0).duplicate(true)
		1:
			var item: TreeItem = %TriggerTree.get_selected()
			%TriggerTree.get_root().remove_child(item)
			item.free()
			_update_triggers()


func _on_tree_item_edited() -> void:
	_update_opcodes()


func _on_tree_item_moved() -> void:
	_update_opcodes()


func _on_tree_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			%PopupMenu.popup(Rect2(%Tree.global_position.x+mouse_position.x, %Tree.global_position.y+mouse_position.y, 0, 0))


func _on_tree_empty_clicked(click_position: Vector2, mouse_button_index: int) -> void:
	if not %TriggerTree.get_selected():
		return
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			if copy_opcode.is_empty():
				%EmptyPopupMenu.set_item_disabled(1, true)
			else:
				%EmptyPopupMenu.set_item_disabled(1, false)
			%EmptyPopupMenu.popup(Rect2(%Tree.global_position.x+click_position.x, %Tree.global_position.y+click_position.y, 0, 0))
		MOUSE_BUTTON_LEFT:
			%Tree.deselect_all()
			%Tree.release_focus()


func _on_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			var item: TreeItem = %Tree.get_selected()
			copy_opcode = {"command": item.get_text(0), "arg": item.get_text(1)}
		1:
			var item: TreeItem = %Tree.get_selected()
			%Tree.get_root().remove_child(item)
			item.free()
			_update_opcodes()


func _on_empty_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			_add_opcode()
		1:
			_add_opcode(copy_opcode.duplicate())


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
