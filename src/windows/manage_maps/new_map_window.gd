extends BaseWindow

signal map_created(map_info: Dictionary)

func _ready() -> void:
	super._ready()
	Roth.settings_loaded.connect(_on_settings_loaded)


func toggle(_bool: Variant = null) -> void:
	super.toggle(_bool)
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
	toggle(false)


func _on_create_button_pressed() -> void:
	create()


func create() -> void:
	var map_name: String = %MapNameEdit.text.to_upper()
	var error := Roth.check_map_name(map_name)
	if not error.is_empty():
		await Dialog.information(error, "Name Error", false, Vector2(400,150))
		return
	var create_info := {
		"name": map_name,
		"das": %DasOption.text.to_upper(),
	}
	Roth.create_new_map(create_info)
	toggle(false)
	map_created.emit(create_info)


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
