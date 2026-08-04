extends BaseWindow


func _ready() -> void:
	super._ready()
	_on_settings_list_item_selected(0)
	var roth_installations: Array = Settings.settings.get("roth_installations", [])
	for directory: String in roth_installations:
		var idx: int = %InstallationsList.add_item(directory)
		%InstallationsList.set_item_metadata(idx, directory)
	if %InstallationsList.item_count == 0:
		var idx: int = %InstallationsList.add_item("No installations configured.")
		%InstallationsList.set_item_disabled(idx, true)
	else:
		%InstallationsList.select(0)
		_on_installations_list_item_selected(0)


func _on_settings_list_item_selected(index: int) -> void:
	%TabContainer.current_tab = index


func _on_installations_list_item_selected(index: int) -> void:
	var installation := ROTHInstallation.new(%InstallationsList.get_item_metadata(index))
	%LanguageLabel.text = installation.language
	%ExeVersionLabel.text = installation.roth_exe_version


func _on_installations_list_item_clicked(_index: int, at_position: Vector2, mouse_button_index: int) -> void:
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			%InstallationsMenu.popup(Rect2(%InstallationsList.global_position+at_position, Vector2.ZERO))


func _on_installations_menu_index_pressed(index: int) -> void:
	match index:
		0:
			var directory: String = %InstallationsList.get_item_metadata(%InstallationsList.get_selected_items()[0])
			print("Remove install: %s" % directory)
			var roth_installations: Array = Settings.settings.get("roth_installations", [])
			roth_installations.erase(directory)
			Settings.update_settings("roth_installations", roth_installations)
			%InstallationsList.remove_item(%InstallationsList.get_selected_items()[0])
			if %InstallationsList.item_count == 0:
				var idx: int = %InstallationsList.add_item("No installations configured.")
				%InstallationsList.set_item_disabled(idx, true)


func _on_add_installation_button_pressed() -> void:
	%InstallationFileDialog.popup_file_dialog()


func _on_installation_file_dialog_dir_selected(dir: String) -> void:
	%InstallationFileDialog.current_dir = %InstallationFileDialog.current_path
	var installation := ROTHInstallation.new(dir)
	if not installation.is_valid():
		await Dialog.information("Not a valid ROTH installation", "Error", false, Vector2(350,150), "Close", HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER)
		return
	
	var roth_installations: Array = Settings.settings.get("roth_installations", [])
	if dir in roth_installations:
		await Dialog.information("Installation already added", "Error", false, Vector2(350,150), "Close", HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER)
		return
	if roth_installations.size() == 0:
		%InstallationsList.clear()
	roth_installations.append(dir)
	Settings.update_settings("roth_installations", roth_installations)
	var idx: int = %InstallationsList.add_item(dir)
	%InstallationsList.set_item_metadata(idx, dir)
	%InstallationsList.select(idx)
	_on_installations_list_item_selected(idx)
