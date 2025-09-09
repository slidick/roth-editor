extends BaseWindow

const DRAG_DROP_TREE_SCRIPT := preload("uid://bh8vniea2yee2")

var right_click_index: int = -1
var dbase_data: Dictionary = {}
var original_dbase_data: Dictionary = {}
var save_tween: Tween


func _ready() -> void:
	super._ready()
	%ActivateButton.disabled = true
	%EditButton.disabled = true
	Roth.settings_loaded.connect(_on_settings_loaded)
	%ListControl.show()
	%EditControl.hide()
	window_title = "Manage DBASE Files"
	%SuccessLabel.modulate.a = 0.0


func _on_settings_loaded() -> void:
	%DBaseList.clear()
	for dbase_info: Dictionary in Roth.dbase_packs:
		var idx: int = %DBaseList.add_item(dbase_info.name+" (Active)" if dbase_info.active else dbase_info.name)
		%DBaseList.set_item_metadata(idx, dbase_info)
		if dbase_info.active:
			%DBaseList.select(idx)
			%ActivateButton.disabled = true
			if "vanilla" not in dbase_info:
				%EditButton.disabled = false
			else:
				%EditButton.disabled = true


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
			var dbase_info: Dictionary = %DBaseList.get_item_metadata(right_click_index)
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
	var dbase_info: Dictionary = %DBaseList.get_item_metadata(%DBaseList.get_selected_items()[0])
	if "vanilla" in dbase_info:
		return
	var directory: String = Roth.ROTH_CUSTOM_DBASE_DIRECTORY.path_join(dbase_info.name)
	var results := DBase100.parse_files_at_directory(directory)
	
	if results.is_empty():
		return
	dbase_data["name"] = dbase_info.name
	dbase_data["dbase100"] = results[0]
	dbase_data["dbase400"] = results[1]
	
	dbase_data["dbase100"].filepath = Roth.ROTH_CUSTOM_DBASE_DIRECTORY.path_join(dbase_info.name).path_join("DBASE100.DAT")
	dbase_data["dbase400"].filepath = Roth.ROTH_CUSTOM_DBASE_DIRECTORY.path_join(dbase_info.name).path_join("DBASE400.DAT")
	
	original_dbase_data = dbase_data.duplicate(true)
	
	window_title = "Editing DBASE - %s" % dbase_data["name"]
	
	%DBase100Header.load_dbase(dbase_data)
	%Cutscenes.load_dbase(dbase_data)
	%Interface.load_dbase(dbase_data)
	%Inventory.load_dbase(dbase_data)
	%Actions.load_dbase(dbase_data)
	
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


func _on_save_button_pressed() -> void:
	var _data := DBase400.compile(dbase_data["dbase400"], dbase_data["dbase100"])
	
	#var file := FileAccess.open(Roth.ROTH_CUSTOM_DBASE_DIRECTORY.path_join(dbase_data["name"]).path_join("DBASE400.DAT"), FileAccess.WRITE)
	#file.store_buffer(data)
	#file.close()
	
	var data2 := DBase100.compile(dbase_data["dbase100"])
	
	var file2 := FileAccess.open(Roth.ROTH_CUSTOM_DBASE_DIRECTORY.path_join(dbase_data["name"]).path_join("DBASE100.DAT"), FileAccess.WRITE)
	file2.store_buffer(data2)
	file2.close()
	
	original_dbase_data = dbase_data.duplicate(true)
	
	if save_tween:
		save_tween.kill()
	%SuccessLabel.modulate.a = 1.0
	save_tween = get_tree().create_tween()
	save_tween.tween_property(%SuccessLabel, "modulate:a", 1.0, 0.5)
	save_tween.tween_property(%SuccessLabel, "modulate:a", 0.0, 2.0)
	
	#%ListControl.show()
	#%EditControl.hide()


func _on_d_base_100_contents_list_item_selected(index: int) -> void:
	%TabContainer.current_tab = index
