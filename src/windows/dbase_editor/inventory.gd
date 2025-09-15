extends Control

var dbase_data: Dictionary = {}
var copy_action: Dictionary = {}
var copy_command: Dictionary = {}


func _ready() -> void:
	%Tree.set_column_title(0, "opcode")
	%Tree.set_column_expand(0, false)
	%Tree.set_column_custom_minimum_width(0, 100)
	%Tree.set_column_title(1, "value")
	%Tree.create_item()
	
	%TriggerTree.set_column_title(0, "Trigger")
	%TriggerTree.create_item()


func reset() -> void:
	dbase_data = {}
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
	%NameEdit.text = ""
	
	%ObjectTextureIndexEdit.editable = false
	%CloseUpTypeEdit.editable = false
	%ItemTypeEdit.editable = false
	%CloseUpImageOffsetEdit.editable = false
	%InventoryImageOffsetEdit.editable = false
	%AddTriggerButton.disabled = true
	%AddOpcodeButton.disabled = true
	%ChangeNameButton.disabled = true
	
	%ObjectTextureRect.texture = null
	%InventoryTextureRect.texture = null
	%AnimatedSprite2D.sprite_frames = null
	%CloseUpTextureRect.texture = null
	
	%Flag1CheckButton.set_pressed_no_signal(false)
	%Flag2CheckButton.set_pressed_no_signal(false)
	%Flag3CheckButton.set_pressed_no_signal(false)
	%Flag4CheckButton.set_pressed_no_signal(false)
	%Flag5CheckButton.set_pressed_no_signal(false)
	%Flag6CheckButton.set_pressed_no_signal(false)
	%Flag7CheckButton.set_pressed_no_signal(false)
	%Flag8CheckButton.set_pressed_no_signal(false)
	%TypeFlag1CheckButton.set_pressed_no_signal(false)
	%TypeFlag2CheckButton.set_pressed_no_signal(false)
	%TypeFlag3CheckButton.set_pressed_no_signal(false)
	
	%Flag1CheckButton.disabled = true
	%Flag2CheckButton.disabled = true
	%Flag3CheckButton.disabled = true
	%Flag4CheckButton.disabled = true
	%Flag5CheckButton.disabled = true
	%Flag6CheckButton.disabled = true
	%Flag7CheckButton.disabled = true
	%Flag8CheckButton.disabled = true
	%TypeFlag1CheckButton.disabled = true
	%TypeFlag2CheckButton.disabled = true
	%TypeFlag3CheckButton.disabled = true
	%TypeOption.disabled = true


func load_dbase(p_dbase_data: Dictionary) -> void:
	reset()
	dbase_data = p_dbase_data
	
	for i in range(len(dbase_data["dbase100"].inventory)):
		var inventory_item: Dictionary = dbase_data["dbase100"].inventory[i]
		var idx: int = %InventoryList.add_item("%d: %s" % [(i+1), inventory_item.text_entry.string])
		%InventoryList.set_item_metadata(idx, inventory_item)


func _add_inventory_item(p_inventory_item: Dictionary = {}) -> void:
	var inventory_item: Dictionary = {
		"closeup_image": 0,
		"closeup_type": 0,
		"actions_section": [],
		"inventory_image": 0,
		"item_type": 0,
		"object_texture_index": 0,
		"offset_dbase400": 0,
		"text_entry": {},
	}
	if not p_inventory_item.is_empty():
		inventory_item = p_inventory_item
		
	var item_name: String = "(Empty)"
	if not inventory_item.text_entry.is_empty():
		item_name = inventory_item.text_entry.string
	var idx: int = %InventoryList.add_item("%d: %s" % [(%InventoryList.item_count+1), item_name])
	%InventoryList.set_item_metadata(idx, inventory_item)
	%InventoryList.select(idx)
	_on_inventory_list_item_selected(idx)
	%InventoryList.ensure_current_is_visible()
	dbase_data["dbase100"].inventory.append(inventory_item)


func _add_action(p_action: Dictionary = {}) -> void:
	var action: Dictionary = {"trigger": 0, "commands": []}
	if not p_action.is_empty():
		action = p_action
	
	var tree_item: TreeItem = %TriggerTree.get_root().create_child()
	tree_item.set_text(0, str(action.trigger))
	tree_item.set_metadata(0, action)
	tree_item.select(0)
	_update_actions()


func _update_actions() -> void:
	var inventory_item: Dictionary = %InventoryList.get_item_metadata(%InventoryList.get_selected_items()[0])
	var actions := []
	for tree_item: TreeItem in %TriggerTree.get_root().get_children():
		var action: Dictionary = tree_item.get_metadata(0)
		action.trigger = int(tree_item.get_text(0))
		actions.append(action)
	inventory_item.actions_section = actions


func _add_command(p_command: Dictionary = {}) -> void:
	var command: Dictionary = {"opcode": 0, "args": 0}
	if not p_command.is_empty():
		command = p_command
	var item: TreeItem = %Tree.get_root().create_child()
	item.set_text(0, str(command.opcode))
	item.set_text(1, str(command.args))
	item.set_autowrap_mode(1, TextServer.AUTOWRAP_WORD_SMART)
	item.set_metadata(0, command)
	await get_tree().process_frame
	%Tree.queue_redraw()
	_update_commands()


func _update_commands() -> void:
	var action: Dictionary = %TriggerTree.get_selected().get_metadata(0)
	var commands := []
	for tree_item: TreeItem in %Tree.get_root().get_children():
		var command: Dictionary = tree_item.get_metadata(0)
		command.opcode = int(tree_item.get_text(0))
		if (	command.opcode == 5
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
			if not tree_item.get_text(1).is_valid_int():
				tree_item.set_text(1, "0")
			command.args = int(tree_item.get_text(1))
			command.erase("text_entry")
		commands.append(command)
	action.commands = commands


func _on_inventory_list_item_selected(index: int) -> void:
	_reset_item()
	var inventory_item: Dictionary = %InventoryList.get_item_metadata(index)
	%ObjectTextureIndexEdit.text = str(inventory_item.object_texture_index)
	%CloseUpTypeEdit.text = str(inventory_item.closeup_type)
	%Flag1CheckButton.set_pressed_no_signal((inventory_item.closeup_type & (1 << 0)) > 0)
	%Flag2CheckButton.set_pressed_no_signal((inventory_item.closeup_type & (1 << 1)) > 0)
	%Flag3CheckButton.set_pressed_no_signal((inventory_item.closeup_type & (1 << 2)) > 0)
	%Flag4CheckButton.set_pressed_no_signal((inventory_item.closeup_type & (1 << 3)) > 0)
	%Flag5CheckButton.set_pressed_no_signal((inventory_item.closeup_type & (1 << 4)) > 0)
	%Flag6CheckButton.set_pressed_no_signal((inventory_item.closeup_type & (1 << 5)) > 0)
	%Flag7CheckButton.set_pressed_no_signal((inventory_item.closeup_type & (1 << 6)) > 0)
	%Flag8CheckButton.set_pressed_no_signal((inventory_item.closeup_type & (1 << 7)) > 0)
	%ItemTypeEdit.text = str(inventory_item.item_type)
	%CloseUpImageOffsetEdit.text = str(inventory_item.closeup_image)
	%InventoryImageOffsetEdit.text = str(inventory_item.inventory_image)
	%NameEdit.text = str(inventory_item.text_entry.string if "string" in inventory_item.text_entry else "(Empty)")
	%ObjectTextureIndexEdit.editable = true
	#%CloseUpTypeEdit.editable = true
	#%ItemTypeEdit.editable = true
	%CloseUpImageOffsetEdit.editable = true
	%InventoryImageOffsetEdit.editable = true
	%ChangeNameButton.disabled = false
	%AddTriggerButton.disabled = false
	%AddOpcodeButton.disabled = true
	%Flag1CheckButton.disabled = false
	%Flag2CheckButton.disabled = false
	%Flag3CheckButton.disabled = false
	%Flag4CheckButton.disabled = false
	%Flag5CheckButton.disabled = false
	%Flag6CheckButton.disabled = false
	%Flag7CheckButton.disabled = false
	%Flag8CheckButton.disabled = false
	%TypeFlag1CheckButton.disabled = false
	%TypeFlag2CheckButton.disabled = false
	%TypeFlag3CheckButton.disabled = false
	%TypeOption.disabled = false
	
	if (inventory_item.item_type & 0b111) == 0:
		%TypeOption.select(0)
	elif (inventory_item.item_type & 0b111) == 1:
		%TypeOption.select(1)
	elif (inventory_item.item_type & 0b111) == 2:
		%TypeOption.select(4)
	elif (inventory_item.item_type & 0b111) == 3:
		%TypeOption.select(2)
	elif (inventory_item.item_type & 0b111) == 3:
		%TypeOption.select(3)
	
	
	%TypeFlag1CheckButton.set_pressed_no_signal((inventory_item.item_type & (1 << 4)) > 0)
	%TypeFlag2CheckButton.set_pressed_no_signal((inventory_item.item_type & (1 << 5)) > 0)
	%TypeFlag3CheckButton.set_pressed_no_signal((inventory_item.item_type & (1 << 6)) > 0)
	
	
	if inventory_item["object_texture_index"] >= 512:
		var image: Dictionary = Roth.get_index_from_das(inventory_item["object_texture_index"]-512, "M/ADEMO.DAS")
		if "image" in image:
			%ObjectTextureRect.texture = image.image[0] if typeof(image.image) == TYPE_ARRAY else image.image
	if "inventory_image" in inventory_item and inventory_item["inventory_image"] != 0:
		var image: Image = DBase200.get_at_offset(inventory_item["inventory_image"]*8)
		if image:
			%InventoryTextureRect.texture = ImageTexture.create_from_image(image)
	if "closeup_image" in inventory_item and inventory_item["closeup_image"] != 0:
		var video: Variant = DBase300.get_at_offset(inventory_item["closeup_image"]*8)
		if video:
			var sprite_frames := SpriteFrames.new()
			%AnimatedSprite2D.sprite_frames = sprite_frames
			sprite_frames.set_animation_speed("default", 12)
			for image: Image in video.video:
				sprite_frames.add_frame("default", ImageTexture.create_from_image(image))
			if inventory_item.closeup_type & 1 > 0:
				sprite_frames.set_animation_loop("default", false)
			%AnimatedSprite2D.play("default")
	
	
	for tree_item: TreeItem in %TriggerTree.get_root().get_children():
		tree_item.free()
	for tree_item: TreeItem in %Tree.get_root().get_children():
		tree_item.free()
	
	for trigger: Dictionary in inventory_item.actions_section:
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
			var inventory_item_to_duplicate: Dictionary = %InventoryList.get_item_metadata(%InventoryList.get_selected_items()[0])
			var inventory_item: Dictionary = inventory_item_to_duplicate.duplicate(true)
			for i in range(len(inventory_item.actions_section)):
				var action: Dictionary = inventory_item.actions_section[i]
				for j in range(len(action.commands)):
					var command: Dictionary = action.commands[j]
					if "text_entry" in command:
						command.text_entry = inventory_item_to_duplicate.actions_section[i].commands[j].text_entry
			_add_inventory_item(inventory_item)
		1:
			if not await Dialog.confirm("This will alter array order!\nReferences to item will not be updated!\nConfirm delete?", "Warning!", false, Vector2(400,200)):
				return
			var selected_index: int = %InventoryList.get_selected_items()[0]
			dbase_data["dbase100"].inventory.pop_at(selected_index)
			%InventoryList.remove_item(selected_index)
			for i in range(selected_index, %InventoryList.item_count):
				%InventoryList.set_item_text(i, "%d: %s" % [(i+1), dbase_data["dbase100"].inventory[i].text_entry.string if "string" in dbase_data["dbase100"].inventory[i].text_entry else "(Empty)"])
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
	%Tree.scroll_to_item(%Tree.get_root())
	var selected_item: TreeItem = %TriggerTree.get_selected()
	for command: Dictionary in selected_item.get_metadata(0).commands:
		var tree_item: TreeItem = %Tree.get_root().create_child()
		tree_item.set_text(0, "%d" % command.opcode)
		tree_item.set_autowrap_mode(1, TextServer.AUTOWRAP_WORD_SMART)
		if "text_entry" in command:
			if "string" in command.text_entry:
				tree_item.set_text(1, command.text_entry.string)
			else:
				tree_item.set_text(1, "(Empty)")
		else:
			tree_item.set_text(1, "%d" % command.args)
		
		tree_item.set_metadata(0, command)
	
	# Needed to update cell spacing after auto-wrap
	await get_tree().process_frame
	%Tree.queue_redraw()
	
	# Work-around to simulate edit only on double click
	selected_item.set_editable(0, true)
	await get_tree().create_timer(0.5).timeout
	if selected_item:
		selected_item.set_editable(0, false)


func _on_add_trigger_button_pressed() -> void:
	_add_action()


func _on_trigger_tree_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			%TriggerPopupMenu.popup(Rect2(%TriggerTree.global_position.x+mouse_position.x, %TriggerTree.global_position.y+mouse_position.y, 0, 0))


func _on_trigger_tree_empty_clicked(click_position: Vector2, mouse_button_index: int) -> void:
	if %InventoryList.get_selected_items().is_empty():
		return
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			if copy_action.is_empty():
				%TriggerEmptyPopupMenu.set_item_disabled(1, true)
			else:
				%TriggerEmptyPopupMenu.set_item_disabled(1, false)
			%TriggerEmptyPopupMenu.popup(Rect2(%TriggerTree.global_position.x+click_position.x, %TriggerTree.global_position.y+click_position.y, 0, 0))


func _on_trigger_tree_item_edited() -> void:
	_update_actions()


func _on_trigger_tree_item_moved() -> void:
	_update_actions()


func _on_trigger_empty_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			_add_action()
		1:
			var action: Dictionary = copy_action.duplicate(true)
			for i in range(len(action.commands)):
				var command: Dictionary = action.commands[i]
				if "text_entry" in command:
					command.text_entry = copy_action.commands[i].text_entry
			_add_action(action)


func _on_trigger_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			var action_to_copy: Dictionary = %TriggerTree.get_selected().get_metadata(0)
			copy_action = action_to_copy.duplicate(true)
			for i in range(len(copy_action.commands)):
				var command: Dictionary = copy_action.commands[i]
				if "text_entry" in command:
					command.text_entry = action_to_copy.commands[i].text_entry
		1:
			var item: TreeItem = %TriggerTree.get_selected()
			%TriggerTree.get_root().remove_child(item)
			item.free()
			_update_actions()
			for tree_item: TreeItem in %Tree.get_root().get_children():
				tree_item.free()


func _on_tree_item_edited() -> void:
	_update_commands()


func _on_tree_item_moved() -> void:
	_update_commands()


func _on_tree_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			%PopupMenu.popup(Rect2(%Tree.global_position.x+mouse_position.x, %Tree.global_position.y+mouse_position.y, 0, 0))


func _on_tree_empty_clicked(click_position: Vector2, mouse_button_index: int) -> void:
	if not %TriggerTree.get_selected():
		return
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			if copy_command.is_empty():
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
			copy_command = item.get_metadata(0).duplicate()
			if "text_entry" in copy_command:
				copy_command.text_entry = item.get_metadata(0).text_entry
		1:
			var item: TreeItem = %Tree.get_selected()
			%Tree.get_root().remove_child(item)
			item.free()
			_update_commands()


func _on_empty_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			_add_command()
		1:
			var command: Dictionary = copy_command.duplicate()
			if "text_entry" in copy_command:
				command.text_entry = copy_command.text_entry
			_add_command(command)


func _on_tree_item_selected() -> void:
	# Work-around to simulate edit only on double click
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


func _on_tree_item_activated() -> void:
	var tree_item: TreeItem = %Tree.get_selected()
	
	if (tree_item.get_text(0) != "5"
		and tree_item.get_text(0) != "8"
		and tree_item.get_text(0) != "15"
		and tree_item.get_text(0) != "16"
	):
		return
	
	var command: Dictionary = tree_item.get_metadata(0)
	await owner.edit_item_with_text_entry(command)
	if "string" in command.text_entry:
		tree_item.set_text(1, command.text_entry.string)
	else:
		tree_item.set_text(1, "(Empty)")


func refresh_text(text_entry: Dictionary) -> void:
	for tree_item: TreeItem in %Tree.get_root().get_children():
		var command: Dictionary = tree_item.get_metadata(0)
		if "text_entry" in command and is_same(command.text_entry, text_entry):
			if "string" in text_entry:
				tree_item.set_text(1, text_entry.string)
			else:
				tree_item.set_text(1, "(Empty)")
	if %InventoryList.get_selected_items().is_empty():
		return
	if is_same(%InventoryList.get_item_metadata(%InventoryList.get_selected_items()[0]).text_entry, text_entry):
		%NameEdit.text = text_entry.string
		%InventoryList.set_item_text(%InventoryList.get_selected_items()[0], "%d: %s" % [%InventoryList.get_selected_items()[0]+1, text_entry.string])

func jump_to_reference(p_reference: Dictionary) -> void:
	%InventoryList.select(p_reference.index-1)
	%InventoryList.ensure_current_is_visible()
	_on_inventory_list_item_selected(p_reference.index-1)
	if "sub_index" in p_reference:
		%TriggerTree.get_root().get_child(p_reference.sub_index).select(0)
		_on_trigger_tree_item_selected()
		%TriggerTree.scroll_to_item(%TriggerTree.get_selected())
	if "sub_sub_index" in p_reference:
		%Tree.get_root().get_child(p_reference.sub_sub_index).select(1)
		%Tree.scroll_to_item(%Tree.get_selected())


func _on_animated_sprite_2d_frame_changed() -> void:
	%CloseUpTextureRect.texture = %AnimatedSprite2D.sprite_frames.get_frame_texture("default", %AnimatedSprite2D.frame)


func _on_page_shown() -> void:
	if (%AnimatedSprite2D.sprite_frames
			and "default" in %AnimatedSprite2D.sprite_frames.get_animation_names()
	):
		%AnimatedSprite2D.play()


func _on_page_hidden() -> void:
	%AnimatedSprite2D.pause()


func _on_change_name_button_pressed() -> void:
	var command: Dictionary = %InventoryList.get_item_metadata(%InventoryList.get_selected_items()[0])
	await owner.edit_item_with_text_entry(command)
	if "string" in command.text_entry:
		%NameEdit.text = command.text_entry.string
		%InventoryList.set_item_text(%InventoryList.get_selected_items()[0], "%d: %s" % [%InventoryList.get_selected_items()[0]+1, command.text_entry.string])
	else:
		%NameEdit.text = "(Empty)"
		%InventoryList.set_item_text(%InventoryList.get_selected_items()[0], "%d: (Empty)" % (%InventoryList.get_selected_items()[0]+1))


func _on_close_up_image_offset_edit_text_submitted(_new_text: String) -> void:
	var inventory_item: Dictionary = %InventoryList.get_item_metadata(%InventoryList.get_selected_items()[0])
	var video: Variant = DBase300.get_at_offset(inventory_item["closeup_image"]*8)
	if video:
		var sprite_frames := SpriteFrames.new()
		%AnimatedSprite2D.sprite_frames = sprite_frames
		sprite_frames.set_animation_speed("default", 12)
		for image: Image in video.video:
			sprite_frames.add_frame("default", ImageTexture.create_from_image(image))
		if inventory_item.closeup_type & 1 > 0:
			sprite_frames.set_animation_loop("default", false)
		%AnimatedSprite2D.play("default")
	else:
		%AnimatedSprite2D.sprite_frames = null
		%CloseUpTextureRect.texture = null
	


func _on_inventory_image_offset_edit_text_submitted(_new_text: String) -> void:
	var inventory_item: Dictionary = %InventoryList.get_item_metadata(%InventoryList.get_selected_items()[0])
	var image: Image = DBase200.get_at_offset(inventory_item["inventory_image"]*8)
	if image:
		%InventoryTextureRect.texture = ImageTexture.create_from_image(image)
	else:
		%InventoryTextureRect.texture = null


func _on_object_texture_index_edit_text_submitted(_new_text: String) -> void:
	var inventory_item: Dictionary = %InventoryList.get_item_metadata(%InventoryList.get_selected_items()[0])
	if inventory_item["object_texture_index"] >= 512:
		var image: Dictionary = Roth.get_index_from_das(inventory_item["object_texture_index"]-512, "M/ADEMO.DAS")
		if "image" in image:
			%ObjectTextureRect.texture = image.image[0] if typeof(image.image) == TYPE_ARRAY else image.image
		else:
			%ObjectTextureRect.texture = null
	else:
		%ObjectTextureRect.texture = null


func _on_flag_check_button_toggled(toggled_on: bool, shift: int) -> void:
	var inventory_item: Dictionary = %InventoryList.get_item_metadata(%InventoryList.get_selected_items()[0])
	if toggled_on:
		inventory_item.closeup_type |= (1 << shift)
		%CloseUpTypeEdit.text = str(inventory_item.closeup_type)
	else:
		inventory_item.closeup_type &= ~(1 << shift)
		%CloseUpTypeEdit.text = str(inventory_item.closeup_type)


func _on_type_option_item_selected(index: int) -> void:
	var inventory_item: Dictionary = %InventoryList.get_item_metadata(%InventoryList.get_selected_items()[0])
	inventory_item.item_type &= 0b11111000
	match index:
		0:
			pass
		1:
			inventory_item.item_type |= 1
		2:
			inventory_item.item_type |= 3
		3:
			inventory_item.item_type |= 4
		4:
			inventory_item.item_type |= 2
	%ItemTypeEdit.text = str(inventory_item.item_type)


func _on_type_flag_check_button_toggled(toggled_on: bool, shift: int) -> void:
	var inventory_item: Dictionary = %InventoryList.get_item_metadata(%InventoryList.get_selected_items()[0])
	if toggled_on:
		inventory_item.item_type |= (1 << shift)
		%ItemTypeEdit.text = str(inventory_item.item_type)
	else:
		inventory_item.item_type &= ~(1 << shift)
		%ItemTypeEdit.text = str(inventory_item.item_type)


func _on_name_edit_gui_input(event: InputEvent) -> void:
	if %InventoryList.get_selected_items().is_empty():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		_on_change_name_button_pressed()
		get_viewport().set_input_as_handled()
