extends BaseWindow

var fxscript: Dictionary = {}
var original_fxscript: Dictionary = {}
var save_tween: Tween

func _ready() -> void:
	super._ready()
	%ActivateButton.disabled = true
	%EditButton.disabled = true
	Roth.settings_loaded.connect(_on_settings_loaded)
	%ListContainer.show()
	%EditContainer.hide()
	window_title = "Manage SFX Packs"
	%SuccessLabel.modulate.a = 0.0


func _on_settings_loaded() -> void:
	if not Roth.install_directory.is_empty():
		%NewButton.disabled = false
	%SFXPackList.clear()
	for sfx_info: Dictionary in Roth.sfx_packs:
		var idx: int = %SFXPackList.add_item(sfx_info.name+" (Active)" if sfx_info.active else sfx_info.name)
		%SFXPackList.set_item_metadata(idx, sfx_info)
		if sfx_info.active:
			%SFXPackList.select(idx)
			_on_sfx_pack_list_item_selected(idx)


func _on_sfx_pack_list_item_selected(index: int) -> void:
	var sfx_info: Dictionary = %SFXPackList.get_item_metadata(index)
	if sfx_info.active:
		%ActivateButton.disabled = true
	else:
		%ActivateButton.disabled = false
	if "vanilla" in sfx_info:
		%EditButton.disabled = true
	else:
		%EditButton.disabled = false
	
	%SFXPackNameLabel.text = sfx_info.name
	%CountLabel.text = str(sfx_info.count)
	%FilesizeLabel.text = str(sfx_info.filesize)
	%DuplicateButton.disabled = false


func _on_sfx_pack_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			if "vanilla" in %SFXPackList.get_item_metadata(index):
				%SFXPackPopupMenu.set_item_disabled(0, true)
				%SFXPackPopupMenu.set_item_disabled(1, true)
			else:
				%SFXPackPopupMenu.set_item_disabled(0, false)
				%SFXPackPopupMenu.set_item_disabled(1, false)
			#right_click_index = index
			%SFXPackPopupMenu.popup(Rect2i(%SFXPackList.global_position.x+at_position.x, %SFXPackList.global_position.y+at_position.y, 0, 0))


func _on_sfx_pack_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			var sfx_info: Dictionary = %SFXPackList.get_item_metadata(%SFXPackList.get_selected_items()[0])
			var err: String = "init"
			var results: Array = [false, ""]
			while not err.is_empty():
				results = await Dialog.input("New Name", "Renaming SFX Pack: %s" % sfx_info.name, results[1], err if err != "init" else "", false, Vector2(400,150))
				if not results[0]:
					return
				err = Roth.check_sfx_pack_name(results[1])
			Roth.rename_sfx_pack(sfx_info, results[1])
		1:
			var sfx_info: Dictionary = %SFXPackList.get_item_metadata(%SFXPackList.get_selected_items()[0])
			if not await Dialog.confirm("Are you sure?", "Deleting SFX Pack: %s" % sfx_info.name, false, Vector2(400,150)):
				return
			Roth.delete_sfx_pack(sfx_info)
		2:
			duplicate_sfx_pack(%SFXPackList.get_selected_items()[0])


func _on_sfx_pack_list_item_activated(_index: int) -> void:
	activate()


func activate() -> void:
	var new_index: int = %SFXPackList.get_selected_items()[0]
	for i in range(%SFXPackList.item_count):
		var sfx_info: Dictionary = %SFXPackList.get_item_metadata(i)
		if i == new_index:
			sfx_info.active = true
			%SFXPackList.set_item_text(i, sfx_info.name+" (Active)")
			Settings.update_settings("options", {"active_sfx": sfx_info.name})
		else:
			sfx_info.active = false
			%SFXPackList.set_item_text(i, sfx_info.name)
	%ActivateButton.disabled = true


func duplicate_sfx_pack(index: int) -> void:
	var sfx_info: Dictionary = %SFXPackList.get_item_metadata(index)
	var err: String = "init"
	var results: Array = [false, ""]
	while not err.is_empty():
		results = await Dialog.input("New Name:", "Duplicating SFX Pack: %s" % sfx_info.name, results[1], err if err != "init" else "", false, Vector2(400,150))
		if not results[0]:
			return
		err = Roth.check_sfx_pack_name(results[1])
	Roth.duplicate_sfx_pack(sfx_info, results[1])
	%SFXPackList.select(%SFXPackList.item_count - 1)
	_on_sfx_pack_list_item_selected(%SFXPackList.item_count - 1)
	%ActivateButton.disabled = false
	%EditButton.disabled = false


func _on_new_button_pressed() -> void:
	var err: String = "init"
	var results: Array = [false, ""]
	while not err.is_empty():
		results = await Dialog.input("Name:", "New SFX Pack", results[1], err if err != "init" else "", false, Vector2(400,150))
		if not results[0]:
			return
		err = Roth.check_sfx_pack_name(results[1])
	Roth.create_sfx_pack(results[1])


func _on_duplicate_button_pressed() -> void:
	if len(%SFXPackList.get_selected_items()) > 0:
		duplicate_sfx_pack(%SFXPackList.get_selected_items()[0])


func _on_activate_button_pressed() -> void:
	activate()


func _on_edit_button_pressed() -> void:
	if Roth.install_directory.is_empty():
		return
	var sfx_info: Dictionary = %SFXPackList.get_item_metadata(%SFXPackList.get_selected_items()[0])
	if "vanilla" in sfx_info:
		return
	
	fxscript = FXScript.parse_sfx_info(sfx_info)
	if fxscript.is_empty():
		return
	
	original_fxscript = fxscript.duplicate(true)
	
	window_title = "Editing SFX - %s" % fxscript["sfx_info"].name
	
	%SoundEffects.load_fxscript(fxscript)
	
	%ListContainer.hide()
	%EditContainer.show()
	
	#%DBase100ContentsList.select(0)
	#_on_d_base_100_contents_list_item_selected(0)


func _on_cancel_button_pressed() -> void:
	if original_fxscript != fxscript:
		if not await Dialog.confirm("There are unsaved changes!\nAre you sure?", "Changes will be lost!", false, Vector2(400,200)):
			return
	fxscript = {}
	original_fxscript = {}
	%ListContainer.show()
	%EditContainer.hide()
	window_title = "Manage SFX Packs"
	%SoundEffects.reset()


func _on_save_button_pressed() -> void:
	if original_fxscript != fxscript:
		var data := FXScript.compile(fxscript)
		var file := FileAccess.open(fxscript.sfx_info.filepath, FileAccess.WRITE)
		file.store_buffer(data)
		file.close()
		
		# Update metadata
		var sfx_info: Dictionary = fxscript.sfx_info
		sfx_info.count = len(fxscript.entries)
		sfx_info.filesize = len(data)
		%SFXPackNameLabel.text = sfx_info.name
		%CountLabel.text = str(sfx_info.count)
		%FilesizeLabel.text = str(sfx_info.filesize)
		
		original_fxscript = fxscript.duplicate(true)
		
		if save_tween:
			save_tween.kill()
		%SuccessLabel.modulate.a = 1.0
		save_tween = get_tree().create_tween()
		save_tween.tween_property(%SuccessLabel, "modulate:a", 1.0, 0.5)
		save_tween.tween_property(%SuccessLabel, "modulate:a", 0.0, 2.0)


func select_sfx() -> Dictionary:
	return await %SFXSelector.select_sfx(fxscript)


func edit_audio(entry: Dictionary) -> Dictionary:
	return await %AudioClipEditor.edit_audio(entry)
