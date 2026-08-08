extends MarginContainer


func _ready() -> void:
	Roth.settings_updated.connect(_on_settings_updated)


func _on_settings_updated() -> void:
	clear_install_info()
	%InstallationsList.clear()
	var installations: Array = Roth.roth_installations
	for installation: ROTHInstallation in installations:
		var idx: int = %InstallationsList.add_item(installation.directory + "* (Active)" if installation == Roth.current_installation else installation.directory)
		%InstallationsList.set_item_metadata(idx, installation)
		if installation == Roth.current_installation:
			%InstallationsList.select(idx)
			_on_installations_list_item_selected(idx)
	
	if %InstallationsList.item_count == 0:
		var idx: int = %InstallationsList.add_item("No installations configured.")
		%InstallationsList.set_item_disabled(idx, true)


func clear_install_info() -> void:
	%LanguageLabel.text = ""
	%ExeVersionLabel.text = ""
	%IDLabel.text = ""


func _on_installations_list_item_selected(index: int) -> void:
	var installation: ROTHInstallation = %InstallationsList.get_item_metadata(index)
	%LanguageLabel.text = installation.language
	%ExeVersionLabel.text = installation.roth_exe_version
	%IDLabel.text = installation.id


func _on_installations_list_item_clicked(_index: int, at_position: Vector2, mouse_button_index: int) -> void:
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			%InstallationsMenu.popup(Rect2(%InstallationsList.global_position+at_position, Vector2.ZERO))


func _on_installations_menu_index_pressed(index: int) -> void:
	match index:
		0:
			var installation: ROTHInstallation = %InstallationsList.get_item_metadata(%InstallationsList.get_selected_items()[0])
			Roth.remove_installation(installation)
			if not Roth.current_installation:
				if %InstallationsList.item_count > 0:
					%InstallationsList.select(0)
					_on_installations_list_item_activated(0)


func _on_add_installation_button_pressed() -> void:
	%InstallationFileDialog.popup_file_dialog()


func _on_installation_file_dialog_dir_selected(dir: String) -> void:
	%InstallationFileDialog.current_dir = %InstallationFileDialog.current_path
	var installation := ROTHInstallation.new(dir)
	if not installation.is_valid():
		await Dialog.information("Not a valid ROTH installation", "Error", false, Vector2(350,150), "Close", HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER)
		return
	if dir in Roth.roth_installations.map(func (i: ROTHInstallation) -> String: return i.directory):
		await Dialog.information("Installation already added", "Error", false, Vector2(350,150), "Close", HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER)
		return
	if Roth.roth_installations.size() == 0:
		%InstallationsList.clear()
	Roth.add_installation(dir)


func _on_installations_list_item_activated(index: int) -> void:
	var installation: ROTHInstallation = %InstallationsList.get_item_metadata(index)
	Roth.set_current_installation(installation)
