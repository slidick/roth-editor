extends BaseWindow


@onready var _things_to_save : Dictionary = {
	"locations": {
		"roth.res": {"node": %RothResEdit, "value": %RothResEdit.text},
		"dosbox": {"node": %DosboxEdit, "value": %DosboxEdit.text},
		"dosbox_config": {"node": %DosboxConfigEdit, "value": %DosboxConfigEdit.text},
	},
}
@onready var _default_roth_res_dialog_directory: String = %RothResFileDialog.current_dir
@onready var _default_dosbox_dialog_directory: String = %DosboxFileDialog.current_dir
@onready var _default_dosbox_config_dialog_directory: String = %DosboxConfigFileDialog.current_dir


func _ready() -> void:
	super._ready()
	if OS.get_name() == "Linux":
		%RothResFileDialog.root_subfolder = "/"
		%DosboxFileDialog.root_subfolder = "/"
		%DosboxConfigFileDialog.root_subfolder = "/"
	if OS.get_name() == "Windows":
		%DosboxFileDialog.filters.append("*.exe")
	_reset()


func _reset() -> void:
	for outer_key: String in _things_to_save:
		var settings: Variant = Settings.settings.get(outer_key)
		if settings:
			for key: String in settings as Dictionary:
				if key in _things_to_save[outer_key]:
					if _things_to_save[outer_key][key].node is LineEdit:
						_things_to_save[outer_key][key].node.text = settings[key]
					if _things_to_save[outer_key][key].node is CheckBox:
						_things_to_save[outer_key][key].node.button_pressed = settings[key]
					_things_to_save[outer_key][key].value = settings[key]
		else:
			var save_data: Dictionary = {}
			for key: String in _things_to_save[outer_key]:
				if _things_to_save[outer_key][key].node is LineEdit:
					_things_to_save[outer_key][key].node.text = _things_to_save[outer_key][key].value
				if _things_to_save[outer_key][key].node is CheckBox:
					_things_to_save[outer_key][key].node.button_pressed = _things_to_save[outer_key][key].value
				save_data[key] = _things_to_save[outer_key][key].value
			Settings.update_settings(outer_key, save_data)
	
	%ResetButton.disabled = true
	%SaveButton.disabled = true


func _save() -> void:
	for outer_key: String in _things_to_save:
		var save_data  : Dictionary = {}
		for key: String in _things_to_save[outer_key]:
			if _things_to_save[outer_key][key].node is LineEdit:
				_things_to_save[outer_key][key].value = _things_to_save[outer_key][key].node.text
			if _things_to_save[outer_key][key].node is CheckBox:
				_things_to_save[outer_key][key].value = _things_to_save[outer_key][key].node.button_pressed
			save_data[key] = _things_to_save[outer_key][key].value
		Settings.update_settings(outer_key, save_data)
	
	%ResetButton.disabled = true
	%SaveButton.disabled = true


func _changed(_value:String="") -> void:
	%ResetButton.disabled = false
	%SaveButton.disabled = false


func _on_roth_res_button_pressed() -> void:
	if %RothResEdit.text.is_empty():
		%RothResFileDialog.current_dir = _default_roth_res_dialog_directory
		%RothResFileDialog.deselect_all()
	else:
		%RothResFileDialog.current_path = %RothResEdit.text
		%RothResFileDialog.current_dir = %RothResEdit.text.get_base_dir()
	%RothResFileDialog.popup(Rect2i(get_viewport().content_scale_size.x / 2, get_viewport().content_scale_size.y / 2, 1000, 600))


func _on_dosbox_button_pressed() -> void:
	if %DosboxEdit.text.is_empty():
		%DosboxFileDialog.current_dir = _default_dosbox_dialog_directory
		%DosboxFileDialog.deselect_all()
	else:
		%DosboxFileDialog.current_path = %DosboxEdit.text
		%DosboxFileDialog.current_dir = %DosboxEdit.text.get_base_dir()
	%DosboxFileDialog.popup(Rect2i(get_viewport().content_scale_size.x / 2, get_viewport().content_scale_size.y / 2, 1000, 600))


func _on_dosbox_config_button_pressed() -> void:
	if %DosboxConfigEdit.text.is_empty():
		%DosboxConfigFileDialog.current_dir = _default_dosbox_config_dialog_directory
		%DosboxConfigFileDialog.deselect_all()
	else:
		%DosboxConfigFileDialog.current_path = %DosboxConfigEdit.text
		%DosboxConfigFileDialog.current_dir = %DosboxConfigEdit.text.get_base_dir()
	%DosboxConfigFileDialog.popup(Rect2i(get_viewport().content_scale_size.x / 2, get_viewport().content_scale_size.y / 2, 1000, 600))


func _on_roth_res_file_dialog_file_selected(path: String) -> void:
	if path != %RothResEdit.text:
		_changed()
		%RothResEdit.text = path
		
		if %DosboxEdit.text.is_empty():
			find_dosbox(path)
		if %DosboxConfigEdit.text.is_empty():
			find_dosbox_config(path)


func _on_dosbox_file_dialog_file_selected(path: String) -> void:
	if path != %DosboxEdit.text:
		_changed()
		%DosboxEdit.text = path


func _on_dosbox_config_file_dialog_file_selected(path: String) -> void:
	if path != %DosboxConfigEdit.text:
		_changed()
		%DosboxConfigEdit.text = path


func find_dosbox(path: String) -> void:
	if OS.get_name() == "Windows":
		var array: Array = path.get_base_dir().rsplit("/", true, 1)
		if FileAccess.file_exists(array[0].path_join("DOSBOX").path_join("DOSBox.EXE")):
			_on_dosbox_file_dialog_file_selected(array[0].path_join("DOSBOX").path_join("DOSBox.EXE"))
	else:
		if FileAccess.file_exists("/usr/bin/dosbox"):
			_on_dosbox_file_dialog_file_selected("/usr/bin/dosbox")


func find_dosbox_config(path: String) -> void:
	var array: Array
	array = path.get_base_dir().rsplit("/", true, 1)
	if FileAccess.file_exists(array[0].path_join("dosboxROTH.conf")):
		_on_dosbox_config_file_dialog_file_selected(array[0].path_join("dosboxROTH.conf"))
