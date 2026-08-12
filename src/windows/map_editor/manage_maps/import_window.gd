extends BaseWindow

@export var manage_maps_window: BaseWindow = null

var import_data: Dictionary = {}


func clear() -> void:
	%NameEdit.text = ""
	%NameWarningLabel.text = ""
	%VersionEdit.text = ""
	%TitleEdit.text = ""
	%ReleaseEdit.text = ""
	%DescriptionEdit.text = ""
	%StoryEdit.text = ""
	%DBaseEdit.text = ""
	%DBaseWarningLabel.text = ""
	%DAS2Edit.text = ""
	%DAS2WarningLabel.text = ""
	%SFXEdit.text = ""
	%SFXWarningLabel.text = ""
	%BackdropEdit.text = ""
	%BackdropWarningLabel.text = ""
	%IconEdit.text = ""
	%IconWarningLabel.text = ""
	%MapList.clear()
	import_data.clear()
	%ImportButton.disabled = true


func import_map() -> void:
	%FileDialog.popup_file_dialog()


func _on_file_dialog_file_selected(filepath: String) -> void:
	var reader := ZIPReader.new()
	var err := reader.open(filepath)
	if err != OK:
		Dialog.information("Can't read file", "Error", false, Vector2(400,150))
		return
	if not reader.file_exists("info.json"):
		Dialog.information("Not a valid map pack file.", "Error", false, Vector2(400,150))
		return
	import_data = JSON.parse_string(reader.read_file("info.json").get_string_from_utf8())
	reader.close()
	
	%NameEdit.text = import_data.name
	%TitleEdit.text = import_data.title
	%DescriptionEdit.text = import_data.description
	%StoryEdit.text = import_data.story
	%ReleaseEdit.text = import_data.release
	%VersionEdit.text = import_data.version
	
	%DBaseEdit.text = import_data.dbase_name
	%DAS2Edit.text = import_data.das2_name
	%SFXEdit.text = import_data.sfx_name
	%BackdropEdit.text = import_data.backdrop_name
	%IconEdit.text = import_data.icon_name
	
	if "dbase_vanilla" in import_data:
		%DBaseEdit.editable = false
	else:
		%DBaseEdit.editable = true
	if "das2_vanilla" in import_data:
		%DAS2Edit.editable = false
	else:
		%DAS2Edit.editable = true
	if "sfx_vanilla" in import_data:
		%SFXEdit.editable = false
	else:
		%SFXEdit.editable = true
	if "backdrop_vanilla" in import_data:
		%BackdropEdit.editable = false
	else:
		%BackdropEdit.editable = true
	if "icon_vanilla" in import_data:
		%IconEdit.editable = false
	else:
		%IconEdit.editable = true
	
	for map_import_info: Dictionary in import_data.maps:
		if "vanilla" in map_import_info:
			continue
		%MapList.add_item("%s (%s)" % [map_import_info.name, map_import_info.das_name])
	
	check_for_allow_import()
	
	toggle(true)


func check_for_allow_import() -> void:
	var import_disabled: bool = false
	
	var err: String = MapPack.check_name(%NameEdit.text)
	if not err.is_empty() and "vanilla" not in import_data:
		#import_disabled = true
		%NameWarningLabel.text = err
	else:
		%NameWarningLabel.text = ""
	
	err = DBasePack.check_name(%DBaseEdit.text)
	if not err.is_empty() and "dbase_vanilla" not in import_data:
		#import_disabled = true
		%DBaseWarningLabel.text = err
	else:
		%DBaseWarningLabel.text = ""
	
	err = DASPack.check_name(%DAS2Edit.text)
	if not err.is_empty() and "das2_vanilla" not in import_data:
		#import_disabled = true
		%DAS2WarningLabel.text = err
	else:
		%DAS2WarningLabel.text = ""
	
	err = SFXPack.check_name(%SFXEdit.text)
	if not err.is_empty() and "sfx_vanilla" not in import_data:
		#import_disabled = true
		%SFXWarningLabel.text = err
	else:
		%SFXWarningLabel.text = ""
	
	err = BackdropPack.check_name(%BackdropEdit.text)
	if not err.is_empty() and "backdrop_vanilla" not in import_data:
		#import_disabled = true
		%BackdropWarningLabel.text = err
	else:
		%BackdropWarningLabel.text = ""
	
	err = IconPack.check_name(%IconEdit.text)
	if not err.is_empty() and "icon_vanilla" not in import_data:
		#import_disabled = true
		%IconWarningLabel.text = err
	else:
		%IconWarningLabel.text = ""
	
	
	%ImportButton.disabled = import_disabled


func _on_cancel_button_pressed() -> void:
	await _fade_out()
	clear()


func _on_import_button_pressed() -> void:
	if MapPack.check_name(%NameEdit.text) == "Name already in use.":
		if not await Dialog.confirm("Overwrite map pack: %s\nMaps in current pack will be lost!" % %NameEdit.text, "Confirm Overwrite", false, Vector2(400,220)):
			return
	
	var reader := ZIPReader.new()
	var err := reader.open(%FileDialog.current_path)
	if err != OK:
		Dialog.information("Can't read file", "Error", false, Vector2(400,150))
		return
	
	import_data.name = %NameEdit.text
	import_data.title = %TitleEdit.text
	import_data.description = %DescriptionEdit.text
	import_data.story = %StoryEdit.text
	import_data.release = %ReleaseEdit.text
	import_data.version = %VersionEdit.text
	import_data.dbase_name = %DBaseEdit.text
	import_data.das2_name = %DAS2Edit.text
	import_data.sfx_name = %SFXEdit.text
	import_data.backdrop_name = %BackdropEdit.text
	import_data.icon_name = %IconEdit.text
	
	if "dbase_vanilla" not in import_data:
		var dbase_array: Array = []
		for filename: String in ["DBASE100.DAT", "DBASE200.DAT", "DBASE300.DAT", "DBASE400.DAT", "DBASE500.DAT"]:
			if not reader.file_exists(filename):
				Dialog.information("Missing expected file.", "Error", false, Vector2(400,150))
				return
			dbase_array.append(reader.read_file(filename))
		if DBasePack.check_name(import_data.dbase_name) == "Name already in use.":
			if await Dialog.confirm("Overwrite dbase: %s" % import_data.dbase_name, "Confirm Overwrite", false, Vector2(400,200)):
				DBasePack.import(import_data.dbase_name, dbase_array)
		else:
			DBasePack.import(import_data.dbase_name, dbase_array)
	
	if "das2_vanilla" not in import_data:
		if not reader.file_exists("DAS2.DAS"):
			Dialog.information("Missing expected file.", "Error", false, Vector2(400,150))
			return
		if DASPack.check_name(import_data.das2_name) == "Name already in use.":
			if await Dialog.confirm("Overwrite das2: %s" % import_data.das2_name, "Confirm Overwrite", false, Vector2(400,200)):
				DASPack.import_das2_pack(import_data.das2_name, reader.read_file("DAS2.DAS"))
		else:
			DASPack.import_das2_pack(import_data.das2_name, reader.read_file("DAS2.DAS"))
	
	if "sfx_vanilla" not in import_data:
		if not reader.file_exists("FXSCRIPT.SFX"):
			Dialog.information("Missing expected file.", "Error", false, Vector2(400,150))
			return
		if SFXPack.check_name(import_data.sfx_name) == "Name already in use.":
			if await Dialog.confirm("Overwrite sfx: %s" % import_data.sfx_name, "Confirm Overwrite", false, Vector2(400,200)):
				SFXPack.import(import_data.sfx_name, reader.read_file("FXSCRIPT.SFX"))
		else:
			SFXPack.import(import_data.sfx_name, reader.read_file("FXSCRIPT.SFX"))
	
	if "backdrop_vanilla" not in import_data:
		if not reader.file_exists("BACKDROP.RAW"):
			Dialog.information("Missing expected file.", "Error", false, Vector2(400,150))
			return
		if BackdropPack.check_name(import_data.backdrop_name) == "Name already in use.":
			if await Dialog.confirm("Overwrite backdrop: %s" % import_data.backdrop_name, "Confirm Overwrite", false, Vector2(400,200)):
				BackdropPack.import(import_data.backdrop_name, reader.read_file("BACKDROP.RAW"))
		else:
			BackdropPack.import(import_data.backdrop_name, reader.read_file("BACKDROP.RAW"))
	
	if "icon_vanilla" not in import_data:
		if not reader.file_exists("ICONS.ALL"):
			Dialog.information("Missing expected file.", "Error", false, Vector2(400,150))
			return
		if IconPack.check_name(import_data.icon_name) == "Name already in use.":
			if await Dialog.confirm("Overwrite icon: %s" % import_data.icon_name, "Confirm Overwrite", false, Vector2(400,200)):
				IconPack.import(import_data.icon_name, reader.read_file("ICONS.ALL"))
		else:
			IconPack.import(import_data.icon_name, reader.read_file("ICONS.ALL"))
	
	
	var unique_das: Array = []
	var map_data: Array = []
	for import_map_info: Dictionary in import_data.maps:
		if import_map_info.das_name not in unique_das and "das_vanilla" not in import_map_info:
			if not reader.file_exists("DAS/%s.DAS" % import_map_info.das_name):
				Dialog.information("Missing expected file.", "Error", false, Vector2(400,150))
				return
			DASPack.import_das_pack(import_map_info.das_name, reader.read_file("DAS/%s.DAS" % import_map_info.das_name))
		if "vanilla" not in import_map_info:
			if not reader.file_exists("MAPS/%s.RAW" % import_map_info.name):
				Dialog.information("Missing expected file.", "Error", false, Vector2(400,150))
				return
			map_data.append(reader.read_file("MAPS/%s.RAW" % import_map_info.name))
	
	var map_pack: Dictionary = MapPack.import(import_data, map_data)
	
	clear()
	toggle(false)
	Roth.settings_updated.emit()
	manage_maps_window.select_map_pack(map_pack)
	await Dialog.information("Successfully imported map pack!", "Import Successful", false, Vector2(400,170), "Close", HORIZONTAL_ALIGNMENT_CENTER)
