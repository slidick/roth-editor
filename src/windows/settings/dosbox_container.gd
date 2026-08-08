extends MarginContainer

@export var settings_window: BaseWindow

@onready var _things_to_save : Dictionary = {
	"dosbox_settings": {
		"fullscreen": {"node": %FullscreenCheckButton, "value": %FullscreenCheckButton.button_pressed},
		"fulldouble": {"node": %FulldoubleCheckButton, "value": %FulldoubleCheckButton.button_pressed},
		"fullresolution": {"node": %FullResolutionOption, "value": %FullResolutionOption.text},
		"windowresolution": {"node": %WindowResolutionOption, "value": %WindowResolutionOption.text},
		"output": {"node": %OutputOption, "value": %OutputOption.text},
		"autolock": {"node": %AutolockCheckButton, "value": %AutolockCheckButton.button_pressed},
		"scaler": {"node": %ScalerOption, "value": %ScalerOption.text},
		"cycles": {"node": %CyclesOption, "value": %CyclesOption.text}
	},
}


func _ready() -> void:
	Roth.settings_updated.connect(_on_settings_updated)
	if OS.get_name() == "Windows":
		%DosboxExecutableFileDialog.filters.append("*.exe")


func _on_settings_updated() -> void:
	var dosbox_options: Dictionary = Settings.settings.get("dosbox_settings", {})
	%UseInstallDosboxCheckButton.set_pressed_no_signal(dosbox_options.get("use_installs_dosbox", %UseInstallDosboxCheckButton.button_pressed))
	%UseInstallDosboxConfigCheckBox.set_pressed_no_signal(dosbox_options.get("use_installs_dosbox_config", %UseInstallDosboxConfigCheckBox.button_pressed))
	%UseLocationDosboxConfigCheckBox.set_pressed_no_signal(dosbox_options.get("use_location_dosbox_config", %UseLocationDosboxConfigCheckBox.button_pressed))
	%UseInternalDosboxConfigCheckBox.set_pressed_no_signal(dosbox_options.get("use_internal_dosbox_config", %UseInternalDosboxConfigCheckBox.button_pressed))
	update_dosbox_executable()
	update_dosbox_config()


func update_dosbox_executable() -> void:
	%DosboxExecutableEdit.editable = not %UseInstallDosboxCheckButton.button_pressed
	%DosboxExecutableBrowseButton.disabled = %UseInstallDosboxCheckButton.button_pressed
	if %UseInstallDosboxCheckButton.button_pressed:
		%DosboxExecutableEdit.text = Roth.current_installation.dosbox_exe
	else:
		%DosboxExecutableEdit.text = Settings.settings.get("dosbox_settings", {}).get("dosbox_executable", "")


func update_dosbox_config() -> void:
	%DosboxConfigEdit.editable = %UseLocationDosboxConfigCheckBox.button_pressed
	%DosboxConfigBrowseButton.disabled = not %UseLocationDosboxConfigCheckBox.button_pressed
	if %UseInstallDosboxConfigCheckBox.button_pressed:
		%DosboxConfigEdit.text = Roth.current_installation.dosbox_config
		settings_window.find_child("SettingsList").set_item_disabled(2, true)
	elif %UseInternalDosboxConfigCheckBox.button_pressed:
		%DosboxConfigEdit.text = "[Internal]"
		settings_window.find_child("SettingsList").set_item_disabled(2, false)
	else:
		%DosboxConfigEdit.text = Settings.settings.get("dosbox_settings", {}).get("dosbox_config", "")
		settings_window.find_child("SettingsList").set_item_disabled(2, true)
		
	%DosboxSettingsContainer.visible = %UseInternalDosboxConfigCheckBox.button_pressed
	
	
	if Settings.settings.get("dosbox_settings", {}).get("cycles", "").is_empty():
		_save()
	
	for outer_key: String in _things_to_save:
		var settings: Variant = Settings.settings.get(outer_key)
		for key: String in settings as Dictionary:
			if key in _things_to_save[outer_key]:
				_handle_node_reset(_things_to_save[outer_key][key].node, settings[key])
				_things_to_save[outer_key][key].value = settings[key]


func _on_use_install_dosbox_check_button_toggled(toggled_on: bool) -> void:
	Settings.update_settings("dosbox_settings", { "use_installs_dosbox": toggled_on })
	update_dosbox_executable()


func _on_use_install_dosbox_config_check_box_toggled(toggled_on: bool) -> void:
	Settings.update_settings("dosbox_settings", { "use_installs_dosbox_config": toggled_on })
	update_dosbox_config()


func _on_use_location_dosbox_config_check_box_toggled(toggled_on: bool) -> void:
	Settings.update_settings("dosbox_settings", { "use_location_dosbox_config": toggled_on })
	update_dosbox_config()


func _on_use_internal_dosbox_config_check_box_toggled(toggled_on: bool) -> void:
	Settings.update_settings("dosbox_settings", { "use_internal_dosbox_config": toggled_on })
	update_dosbox_config()


func _save(_unused: Variant = null) -> void:
	for outer_key: String in _things_to_save:
		var save_data  : Dictionary = {}
		for key: String in _things_to_save[outer_key]:
			_handle_node_save(_things_to_save[outer_key][key])
			save_data[key] = _things_to_save[outer_key][key].value
		Settings.update_settings(outer_key, save_data)


func _handle_node_reset(node: Control, value: Variant) -> void:
	if node is LineEdit:
		node.text = value
	if (node is CheckBox or
			node is CheckButton):
		node.button_pressed = value
	if node is OptionButton:
		for i in range(node.item_count):
			if node.get_item_text(i).to_lower() == value.to_lower():
				node.selected = i


func _handle_node_save(node_data: Dictionary) -> void:
	if node_data.node is LineEdit:
		node_data.value = node_data.node.text
	if (node_data.node is CheckBox or
			node_data.node is CheckButton):
		node_data.value = node_data.node.button_pressed
	if node_data.node is OptionButton:
		node_data.value = node_data.node.text.to_lower()


func _on_dosbox_executable_browse_button_pressed() -> void:
	%DosboxExecutableFileDialog.popup_file_dialog()


func _on_dosbox_executable_file_dialog_file_selected(path: String) -> void:
	%DosboxExecutableEdit.text = path
	Settings.update_settings("dosbox_settings", { "dosbox_executable": %DosboxExecutableEdit.text })


func _on_dosbox_config_browse_button_pressed() -> void:
	%DosboxConfigFileDialog.popup_file_dialog()


func _on_dosbox_config_file_dialog_file_selected(path: String) -> void:
	%DosboxConfigEdit.text = path
	Settings.update_settings("dosbox_settings", { "dosbox_config": %DosboxConfigEdit.text })


func _on_dosbox_executable_edit_text_changed(_new_text: String) -> void:
	%DosboxExecutableTimer.start()


func _on_dosbox_executable_timer_timeout() -> void:
	Settings.update_settings("dosbox_settings", { "dosbox_executable": %DosboxExecutableEdit.text })


func _on_dosbox_config_edit_text_changed(_new_text: String) -> void:
	%DosboxConfigTimer.start()


func _on_dosbox_config_timer_timeout() -> void:
	Settings.update_settings("dosbox_settings", { "dosbox_config": %DosboxConfigEdit.text })
