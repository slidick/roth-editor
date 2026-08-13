extends MarginContainer

func _ready() -> void:
	Normality.settings_updated.connect(_on_settings_updated)


func _on_settings_updated() -> void:
	%InstallationsList.clear()
	for installation: NormalityInstallation in Normality.installations:
		var idx: int = %InstallationsList.add_item(installation.directory + "* (Active)" if installation == Normality.current_installation else installation.directory)
		%InstallationsList.set_item_metadata(idx, installation)
		if installation == Normality.current_installation:
			%InstallationsList.select(idx)
			_on_installations_list_item_selected(idx)
	
	if %InstallationsList.item_count == 0:
		var idx: int = %InstallationsList.add_item("No installations configured.")
		%InstallationsList.set_item_disabled(idx, true)


func _on_installations_list_item_selected(_index: int) -> void:
	pass # Replace with function body.


func _on_installations_list_item_activated(index: int) -> void:
	var installation: NormalityInstallation = %InstallationsList.get_item_metadata(index)
	Normality.set_current_installation(installation)


func _on_installations_list_item_clicked(_index: int, at_position: Vector2, mouse_button_index: int) -> void:
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			%InstallationsMenu.popup(Rect2(%InstallationsList.global_position+at_position, Vector2.ZERO))


func _on_installations_menu_index_pressed(index: int) -> void:
	match index:
		0:
			var installation: NormalityInstallation = %InstallationsList.get_item_metadata(%InstallationsList.get_selected_items()[0])
			Normality.remove_installation(installation)
			if not Normality.current_installation:
				if %InstallationsList.item_count > 0:
					%InstallationsList.select(0)
					_on_installations_list_item_activated(0)


func _on_add_installation_button_pressed() -> void:
	%InstallationsFileDialog.popup_file_dialog()


func _on_installations_file_dialog_dir_selected(dir: String) -> void:
	var norm_installation := NormalityInstallation.new(dir)
	if not norm_installation.is_valid():
		await Dialog.information("Not a valid Normality installation", "Error", false, Vector2(350,150), "Close", HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER)
		return
	
	if dir in Normality.installations.map(func (i: NormalityInstallation) -> String: return i.directory):
		await Dialog.information("Installation already added", "Error", false, Vector2(350,150), "Close", HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER)
		return
	
	Normality.add_installation(dir)
