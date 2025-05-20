extends BaseWindow


func _ready() -> void:
	super._ready()
	Roth.settings_loaded.connect(_on_settings_loaded)


func _hide() -> void:
	super._hide()
	%MapNameEdit.text = ""
	%DasOption.select(-1)
	%CreateButton.disabled = true


func _on_settings_loaded() -> void:
	%DasOption.clear()
	for das: String in Roth.das_files:
		if das.ends_with("ADEMO.DAS"):
			continue
		%DasOption.add_item(das)


func _on_cancel_button_pressed() -> void:
	_hide()


func _on_create_button_pressed() -> void:
	create()


func create() -> void:
	if %MapNameEdit.text.to_upper() in Roth.maps.map(func (map: Dictionary) -> String: return map.name):
		await Dialog.information("Map name already in use.", "Name Conflict", false, Vector2(500,200))
		return
	var create_info := {
		"name": %MapNameEdit.text.to_upper(),
		"das": %DasOption.text.to_upper(),
		"raw": %MapNameEdit.text.to_upper() + ".RAW",
		"custom": true
	}
	Roth.create_new_map(create_info)
	_hide()


func _on_das_option_item_selected(_index: int) -> void:
	if not %MapNameEdit.text.is_empty():
		%CreateButton.disabled = false


func _on_map_name_edit_text_changed(new_text: String) -> void:
	if %DasOption.selected != -1 and not new_text.is_empty():
		%CreateButton.disabled = false
	else:
		%CreateButton.disabled = true


func _on_map_name_edit_text_submitted(_new_text: String) -> void:
	create()
