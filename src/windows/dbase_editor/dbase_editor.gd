extends BaseWindow

var right_click_index: int = -1
var dbase_data: Dictionary = {}
var original_dbase_data: Dictionary = {}
var save_tween: Tween
var previous_tab: int = 0
var audio_changed: bool = false

func _ready() -> void:
	super._ready()
	%ActivateButton.disabled = true
	%EditButton.disabled = true
	Roth.settings_loaded.connect(_on_settings_loaded)
	%ListControl.show()
	%EditControl.hide()
	window_title = "Manage DBASE Packs"
	%SuccessLabel.modulate.a = 0.0


func _on_settings_loaded() -> void:
	if not Roth.install_directory.is_empty():
		%NewButton.disabled = false
	%DBaseList.clear()
	for dbase_info: Dictionary in Roth.dbase_packs:
		var idx: int = %DBaseList.add_item(dbase_info.name+" (Active)" if dbase_info.active else dbase_info.name)
		%DBaseList.set_item_metadata(idx, dbase_info)
		if dbase_info.active:
			%DBaseList.select(idx)
			_on_d_base_list_item_selected(idx)


func _on_d_base_list_item_selected(index: int) -> void:
	var dbase_info: Dictionary = %DBaseList.get_item_metadata(index)
	if dbase_info.active:
		%ActivateButton.disabled = true
	else:
		%ActivateButton.disabled = false
	if "vanilla" in dbase_info:
		%EditButton.disabled = true
	else:
		%EditButton.disabled = false
	
	%DBaseNameLabel.text = dbase_info.name
	%InventoryCountLabel.text = str(dbase_info.inventory_count)
	%ActionCountLabel.text = str(dbase_info.action_count)
	%CutsceneCountLabel.text = str(dbase_info.cutscene_count)
	%InterfaceCountLabel.text = str(dbase_info.interface_count)
	%FilesizeLabel.text = str(dbase_info.filesize)
	%DuplicateButton.disabled = false


func _on_d_base_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			if "vanilla" in %DBaseList.get_item_metadata(index):
				%DBasePopupMenu.set_item_disabled(0, true)
				%DBasePopupMenu.set_item_disabled(1, true)
			else:
				%DBasePopupMenu.set_item_disabled(0, false)
				%DBasePopupMenu.set_item_disabled(1, false)
			right_click_index = index
			%DBasePopupMenu.popup(Rect2i(%DBaseList.global_position.x+at_position.x, %DBaseList.global_position.y+at_position.y, 0, 0))


func _on_d_base_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			var dbase_info: Dictionary = %DBaseList.get_item_metadata(right_click_index)
			var err: String = "init"
			var results: Array = [false, ""]
			while not err.is_empty():
				results = await Dialog.input("New Name", "Renaming DBase: %s" % dbase_info.name, results[1], err if err != "init" else "", false, Vector2(400,150))
				if not results[0]:
					return
				err = Roth.check_dbase_pack_name(results[1])
			Roth.rename_dbase_pack(dbase_info, results[1])
		1:
			var dbase_info: Dictionary = %DBaseList.get_item_metadata(right_click_index)
			if not await Dialog.confirm("Are you sure?", "Deleting DBase: %s" % dbase_info.name, false, Vector2(400,150)):
				return
			Roth.delete_dbase_pack(dbase_info)
		2:
			duplicate_dbase(right_click_index)


func duplicate_dbase(index: int) -> void:
	var dbase_info: Dictionary = %DBaseList.get_item_metadata(index)
	var err: String = "init"
	var results: Array = [false, ""]
	while not err.is_empty():
		results = await Dialog.input("New Name", "Duplicating DBase: %s" % dbase_info.name, results[1], err if err != "init" else "", false, Vector2(400,150))
		if not results[0]:
			return
		err = Roth.check_dbase_pack_name(results[1])
	Roth.duplicate_dbase_pack(dbase_info, results[1])
	%DBaseList.select(%DBaseList.item_count - 1)
	%ActivateButton.disabled = false
	%EditButton.disabled = false


func _on_d_base_list_item_activated(_index: int) -> void:
	activate()


func _on_activate_button_pressed() -> void:
	activate()


func activate() -> void:
	var new_index: int = %DBaseList.get_selected_items()[0]
	for i in range(%DBaseList.item_count):
		var dbase_info: Dictionary = %DBaseList.get_item_metadata(i)
		if i == new_index:
			dbase_info.active = true
			%DBaseList.set_item_text(i, dbase_info.name+" (Active)")
			Settings.update_settings("options", {"active_dbase": dbase_info.name})
		else:
			dbase_info.active = false
			%DBaseList.set_item_text(i, dbase_info.name)
	%ActivateButton.disabled = true


func _on_edit_button_pressed() -> void:
	if Roth.install_directory.is_empty():
		return
	var dbase_info: Dictionary = %DBaseList.get_item_metadata(%DBaseList.get_selected_items()[0])
	if "vanilla" in dbase_info:
		return
	var directory: String = Roth.ROTH_CUSTOM_DBASE_DIRECTORY.path_join(dbase_info.name)
	var results := DBase100.parse_files_at_directory(directory)
	
	if results.is_empty():
		return
	dbase_data["dbase_info"] = dbase_info
	dbase_data["dbase100"] = results
	
	original_dbase_data = dbase_data.duplicate(true)
	audio_changed = false
	window_title = "Editing DBASE - %s" % dbase_data["dbase_info"].name
	
	%DBase100Header.load_dbase(dbase_data)
	%Cutscenes.load_dbase(dbase_data)
	%Interface.load_dbase(dbase_data)
	%Inventory.load_dbase(dbase_data)
	%Actions.load_dbase(dbase_data)
	%Text.load_dbase(dbase_data)
	
	%ListControl.hide()
	%EditControl.show()
	
	%DBase100ContentsList.select(0)
	_on_d_base_100_contents_list_item_selected(0)


func _on_cancel_button_pressed() -> void:
	if original_dbase_data != dbase_data:
		if not await Dialog.confirm("There are unsaved changes!\nAre you sure?", "Changes will be lost!", false, Vector2(400,200)):
			return
	dbase_data = {}
	original_dbase_data = {}
	%ListControl.show()
	%EditControl.hide()
	window_title = "Manage DBASE Files"
	
	%DBase100Header.reset()
	%Cutscenes.reset()
	%Interface.reset()
	%Inventory.reset()
	%Actions.reset()
	%Text.reset()


func _on_save_button_pressed() -> void:
	if audio_changed:
		var data3 := DBase500.compile(dbase_data["dbase100"])
		var file3 := FileAccess.open(Roth.ROTH_CUSTOM_DBASE_DIRECTORY.path_join(dbase_data["dbase_info"].name).path_join("DBASE500.DAT"), FileAccess.WRITE)
		file3.store_buffer(data3)
		file3.close()
	
	var data := DBase400.compile(dbase_data["dbase100"])
	
	var file := FileAccess.open(Roth.ROTH_CUSTOM_DBASE_DIRECTORY.path_join(dbase_data["dbase_info"].name).path_join("DBASE400.DAT"), FileAccess.WRITE)
	file.store_buffer(data)
	file.close()
	
	var data2 := DBase100.compile(dbase_data["dbase100"])
	
	var file2 := FileAccess.open(Roth.ROTH_CUSTOM_DBASE_DIRECTORY.path_join(dbase_data["dbase_info"].name).path_join("DBASE100.DAT"), FileAccess.WRITE)
	file2.store_buffer(data2)
	file2.close()
	
	# Update metadata
	var dbase_info: Dictionary = dbase_data["dbase_info"]
	dbase_info.inventory_count = len(dbase_data["dbase100"].inventory)
	dbase_info.action_count = len(dbase_data["dbase100"].actions)
	dbase_info.cutscene_count = len(dbase_data["dbase100"].cutscenes)
	dbase_info.interface_count = len(dbase_data["dbase100"].interfaces)
	dbase_info.filesize = len(data2)
	%DBaseNameLabel.text = dbase_info.name
	%InventoryCountLabel.text = str(dbase_info.inventory_count)
	%ActionCountLabel.text = str(dbase_info.action_count)
	%CutsceneCountLabel.text = str(dbase_info.cutscene_count)
	%InterfaceCountLabel.text = str(dbase_info.interface_count)
	%FilesizeLabel.text = str(dbase_info.filesize)
	
	
	original_dbase_data = dbase_data.duplicate(true)
	audio_changed = false
	
	if save_tween:
		save_tween.kill()
	%SuccessLabel.modulate.a = 1.0
	save_tween = get_tree().create_tween()
	save_tween.tween_property(%SuccessLabel, "modulate:a", 1.0, 0.5)
	save_tween.tween_property(%SuccessLabel, "modulate:a", 0.0, 2.0)


func _on_d_base_100_contents_list_item_selected(index: int) -> void:
	%TabContainer.current_tab = index


func edit_text_entry(text_entry: Dictionary) -> void:
	var references: Array = get_text_entry_references(text_entry)
	await %EditTextEntry.edit_text_entry(text_entry, references)
	refresh_text_2(text_entry)


func edit_item_with_text_entry(item: Dictionary) -> void:
	var references: Array = get_text_entry_references(item.text_entry)
	await %EditTextEntry.edit_item_with_text_entry(item, references)
	refresh_text(item.text_entry)


func get_text_entry_references(text_entry: Dictionary) -> Array:
	var references: Array = []
	
	for i in range(len(dbase_data["dbase100"].interfaces)):
		var interface: Dictionary = dbase_data["dbase100"].interfaces[i]
		if is_same(interface.text_entry, text_entry):
			references.append({"type": "interface", "index": i+1})
	
	for i in range(len(dbase_data["dbase100"].actions)):
		var action: Dictionary = dbase_data["dbase100"].actions[i]
		for j in range(len(action.commands)):
			var command: Dictionary = action.commands[j]
			if (command.opcode == 5
				or command.opcode == 8
				or command.opcode == 15
				or command.opcode == 16
			):
				if is_same(command.text_entry, text_entry):
					references.append({"type": "action", "index": i+1, "sub_index": j})
	
	for i in range(len(dbase_data["dbase100"].inventory)):
		var inventory_item: Dictionary = dbase_data["dbase100"].inventory[i]
		if is_same(inventory_item.text_entry, text_entry):
			references.append({"type": "inventory", "index": i+1})
		for j in range(len(inventory_item.actions_section)):
			var action: Dictionary = inventory_item.actions_section[j]
			for k in range(len(action.commands)):
				var command: Dictionary = action.commands[k]
				if (command.opcode == 5
					or command.opcode == 8
					or command.opcode == 15
					or command.opcode == 16
				):
					if is_same(command.text_entry, text_entry):
						references.append({"type": "inventory", "index": i+1, "sub_index": j, "sub_sub_index": k})
	return references


func refresh_text(text_entry: Dictionary) -> void:
	%Text.refresh_text(text_entry)


func refresh_text_2(text_entry: Dictionary) -> void:
	%Interface.refresh_text(text_entry)
	%Inventory.refresh_text(text_entry)
	#%Actions.refresh_text(text_entry)


func get_texture_color_with_color(font_color: int) -> GradientTexture2D:
		var palette := Das.get_default_palette()
		var gradient := Gradient.new()
		var color := Color(palette[font_color][0] / float(255), palette[font_color][1] / float(255), palette[font_color][2] / float(255))
		gradient.set_color(0, color)
		gradient.set_color(1, color)
		var texture_gradient := GradientTexture2D.new()
		texture_gradient.height = 24
		texture_gradient.width = 24
		texture_gradient.gradient = gradient
		return texture_gradient


func jump_to_reference(p_reference: Dictionary) -> void:
	if p_reference.type == "action":
		%TabContainer.current_tab = 4
		%DBase100ContentsList.select(4)
		%Actions.jump_to_reference(p_reference)
	elif p_reference.type == "inventory":
		%TabContainer.current_tab = 3
		%DBase100ContentsList.select(3)
		%Inventory.jump_to_reference(p_reference)
	elif p_reference.type == "interface":
		%TabContainer.current_tab = 2
		%DBase100ContentsList.select(2)
		%Interface.jump_to_reference(p_reference)


func _on_tab_container_tab_changed(tab: int) -> void:
	if previous_tab == 3:
		%Inventory._on_page_hidden()
	if tab == 3:
		%Inventory._on_page_shown()
	previous_tab = tab


func _on_duplicate_button_pressed() -> void:
	if len(%DBaseList.get_selected_items()) > 0:
		duplicate_dbase(%DBaseList.get_selected_items()[0])


func _on_new_button_pressed() -> void:
	var err: String = "init"
	var results: Array = [false, ""]
	while not err.is_empty():
		results = await Dialog.input("Name:", "New DBase Pack", results[1], err if err != "init" else "", false, Vector2(400,150))
		if not results[0]:
			return
		err = Roth.check_dbase_pack_name(results[1])
	Roth.create_dbase_pack(results[1])


func get_hex_preference() -> bool:
	if %IntegerOption.selected == 1:
		return true
	return false


func _on_integer_option_item_selected(_index: int) -> void:
	%Actions.update_integer_preference()
	%Inventory.update_integer_preference()


func ademo_object_selection() -> Dictionary:
	return await %ObjectSelection.ademo_object_selection()


func dbase200_object_selection() -> int:
	return await %ObjectSelection.dbase200_object_selection()


func dbase300_object_selection() -> int:
	return await %ObjectSelection.dbase300_object_selection()
