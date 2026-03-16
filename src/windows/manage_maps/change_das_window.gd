extends BaseWindow

signal done(new_das_info: Dictionary)


func _ready() -> void:
	super._ready()
	Roth.settings_loaded.connect(_on_settings_loaded)


func _on_settings_loaded() -> void:
	%DASOptions.clear()
	for das_info: Dictionary in Roth.das_packs:
		if das_info.name.to_upper().contains("ADEMO"):
			continue
		%DASOptions.add_item(das_info.name)
		%DASOptions.set_item_metadata(%DASOptions.item_count-1, das_info)


func change_das(current_das_info: Dictionary) -> Dictionary:
	%DASOptions.select(0)
	for i in range(%DASOptions.item_count):
		if %DASOptions.get_item_metadata(i) == current_das_info:
			%DASOptions.select(i)
	toggle(true)
	var new_das_info: Dictionary = await done
	toggle(false)
	return new_das_info


func _on_cancel_button_pressed() -> void:
	done.emit({})


func _on_change_button_pressed() -> void:
	done.emit(%DASOptions.get_selected_metadata())
