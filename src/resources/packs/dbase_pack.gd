class_name DBasePack
extends Object

static var dbase_packs: Array = []


static func init_vanilla(p_installation: ROTHInstallation) -> void:
	var vanilla_dbase: Dictionary = {
			"name": p_installation.name,
			"vanilla": p_installation,
			"dbase100_filepath": p_installation.dbase100,
			"dbase200_filepath": p_installation.dbase200,
			"dbase300_filepath": p_installation.dbase300,
			"dbase400_filepath": p_installation.dbase400,
			"dbase500_filepath": p_installation.dbase500,
	}
	var dbase_100 := FileAccess.open(vanilla_dbase.dbase100_filepath, FileAccess.READ)
	vanilla_dbase.merge(Parser.parse_section(dbase_100, DBase100.DBASE100_HEADER))
	vanilla_dbase.erase("signature")
	vanilla_dbase.erase("unk_dword_02")
	vanilla_dbase.erase("unk_dword_11")
	dbase_100.close()
	dbase_packs.append(vanilla_dbase)


static func init_custom(p_directory: String) -> void:
	for dir in DirAccess.get_directories_at(p_directory):
		var dbase_info := {
			"name": dir,
			"dbase100_filepath": p_directory.path_join(dir).path_join("DBASE100.DAT"),
			"dbase200_filepath": p_directory.path_join(dir).path_join("DBASE200.DAT"),
			"dbase300_filepath": p_directory.path_join(dir).path_join("DBASE300.DAT"),
			"dbase400_filepath": p_directory.path_join(dir).path_join("DBASE400.DAT"),
			"dbase500_filepath": p_directory.path_join(dir).path_join("DBASE500.DAT"),
		}
		var dbase_100 := FileAccess.open(dbase_info.dbase100_filepath, FileAccess.READ)
		dbase_info.merge(Parser.parse_section(dbase_100, DBase100.DBASE100_HEADER))
		dbase_info.erase("signature")
		dbase_info.erase("unk_dword_02")
		dbase_info.erase("unk_dword_11")
		dbase_100.close()
		dbase_packs.append(dbase_info)


static func check_name(p_name: String) -> String:
	var error := ""
	if p_name.to_lower() in dbase_packs.map(func (d: Dictionary) -> String: return d.name.to_lower()):
		error = "Name already in use."
	if not p_name.is_valid_filename():
		error = "Can't contain the following: : / \\ ? * \" | % < >"
	return error


static func create(p_name: String) -> void:
	var dbase := {
		"actions": [],
		"cutscenes": [],
		"header": {
			"unk_dword_02": 433,
			"unk_dword_11": 2
		},
		"interfaces": [
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Subtitle\'s ON." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Subtitle\'s OFF." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Run mode ON." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Run mode OFF." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "I cannot use that." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Out of power." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "No ammo." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Mouse Buttons A-B." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Mouse Buttons B-A." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "New game" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Options" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Quit Game" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "OK SAVE!" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "OK LOAD!" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Load a game" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Save a game" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Restore last save game" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "CANCEL" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Volume settings" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Subtitle settings" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "DONE" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Saving ..." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Loading ..." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Master volume" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Sound effects" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Music" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Speech" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Movies" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Speech subtitles on" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Speech subtitles off" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Speech Audio on" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Speech Audio off" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Movie subtitles on" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Movie subtitles off" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Movie audio on" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Movie audio off" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Input name" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Select file to load" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Select file to save" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "OK to replace" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Using %s with %s." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "I cannot use %s with %s." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "I cannot use %s." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Quit to DOS" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Screen settings" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Using %s." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Mouse Speed" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Settings" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Input Settings" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Not available" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Empty slot" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "No name" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Scanning VESA, please wait..." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "OK to start a new game." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Reload game to take effect." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "VGA 320x200" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Mode-X 320x200" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Mode-X 320x400" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "VESA 320x200" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "VESA 320x400" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "VESA 640x400" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "VESA 640x480" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Options menu" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Insert Original ROTH Boot-CD" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Continue" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Insert ROTH \'Boot-CD\'" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Insert ROTH \'CD - two\'" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Insert ROTH \'CD - three\'" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Insert ROTH \'CD - four\'" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Read error found" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Retry" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Abort video" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Movie clips" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Playback menu" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Screen size" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Play the game" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Replay Intro" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Cancel, and don\'t ask again" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Intro" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Making of" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Credits" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "--RotH--^^keys:-^^F1 - Show/Hide weapon^^F2 - Subtitles On/Off^^F5 - Switch Mouse buttons^^F6 - Cycle through screen modes^^CapsLock - RunMode On/Off^^i - Inventory On/Off^^c,v - Adjust gamma^^1-6 - Select weapons^^F10/F9 - Load/Save game 0" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Quit Realms" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Select difficulty level" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Easy" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Normal" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Hard" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Define movment keys" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Walk forward" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Turn left" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Turn right" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Walk backward" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Walk left" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Walk right" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Fire" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Key already used by the game" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Press new key" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Very hard" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "<VGA 320x200>" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "<Mode-X 320x200>" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "<Mode-X 320x400>" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "<VESA 320x200>" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "<VESA 320x400>" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "<VESA 640x400>" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "<VESA 640x480>" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Jump" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Crawl" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Gamma" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Gamma setting" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Arcade level" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Adventure level" } },
		],
		"inventory": [],
		"subtitle_entrys": [],
	}

	var directory: String = Roth.ROTH_CUSTOM_DBASE_DIRECTORY.path_join(p_name)
	DirAccess.make_dir_recursive_absolute(directory)
	
	var dbase100_filepath := directory.path_join("DBASE100.DAT")
	var dbase200_filepath := directory.path_join("DBASE200.DAT")
	var dbase300_filepath := directory.path_join("DBASE300.DAT")
	var dbase400_filepath := directory.path_join("DBASE400.DAT")
	var dbase500_filepath := directory.path_join("DBASE500.DAT")
	
	var data5: = DBase500.compile(dbase)
	var file5 := FileAccess.open(dbase500_filepath, FileAccess.WRITE)
	file5.store_buffer(data5)
	file5.close()
	
	var data4 := DBase400.compile(dbase)
	var file4 := FileAccess.open(dbase400_filepath, FileAccess.WRITE)
	file4.store_buffer(data4)
	file4.close()
	
	var data3 := DBase300.compile(dbase)
	var file3 := FileAccess.open(dbase300_filepath, FileAccess.WRITE)
	file3.store_buffer(data3)
	file3.close()
	
	var data2 := DBase200.compile(dbase)
	var file2 := FileAccess.open(dbase200_filepath, FileAccess.WRITE)
	file2.store_buffer(data2)
	file2.close()
	
	var data1 := DBase100.compile(dbase)
	var file1 := FileAccess.open(dbase100_filepath, FileAccess.WRITE)
	file1.store_buffer(data1)
	file1.close()
	
	var dbase_info := {
		"name": p_name,
		"inventory_count": len(dbase.inventory),
		"action_count": len(dbase.actions),
		"cutscene_count": len(dbase.cutscenes),
		"interface_count": len(dbase.interfaces),
		"filesize": len(data2),
	}
	dbase_packs.append(dbase_info)
	Roth.settings_updated.emit()


static func duplicate_pack(p_dbase_info: Dictionary, p_new_name: String) -> void:
	var dbase_info := p_dbase_info.duplicate()
	dbase_info.name = p_new_name
	dbase_info.erase("vanilla")
	var new_dir: String = Roth.ROTH_CUSTOM_DBASE_DIRECTORY.path_join(p_new_name)
	dbase_info["dbase100_filepath"] = new_dir.path_join("DBASE100.DAT")
	dbase_info["dbase200_filepath"] = new_dir.path_join("DBASE200.DAT")
	dbase_info["dbase300_filepath"] = new_dir.path_join("DBASE300.DAT")
	dbase_info["dbase400_filepath"] = new_dir.path_join("DBASE400.DAT")
	dbase_info["dbase500_filepath"] = new_dir.path_join("DBASE500.DAT")
	DirAccess.make_dir_recursive_absolute(new_dir)
	
	for key: String in ["dbase100_filepath", "dbase200_filepath", "dbase300_filepath", "dbase400_filepath", "dbase500_filepath"]:
		if FileAccess.file_exists(p_dbase_info[key]):
			DirAccess.copy_absolute(p_dbase_info[key], dbase_info[key])
	
	dbase_packs.append(dbase_info)
	Roth.settings_updated.emit()


static func delete(p_dbase_info: Dictionary) -> void:
	if DirAccess.dir_exists_absolute(Roth.ROTH_CUSTOM_DBASE_DIRECTORY.path_join(p_dbase_info.name)):
		Utility.remove_dir_recursive(Roth.ROTH_CUSTOM_DBASE_DIRECTORY.path_join(p_dbase_info.name))
	dbase_packs.erase(p_dbase_info)
	MapPack.update_subpack_deleted(p_dbase_info)
	Roth.settings_updated.emit()


static func rename(p_dbase_info: Dictionary, p_new_name: String) -> void:
	DirAccess.rename_absolute(
		Roth.ROTH_CUSTOM_DBASE_DIRECTORY.path_join(p_dbase_info.name),
		Roth.ROTH_CUSTOM_DBASE_DIRECTORY.path_join(p_new_name)
	)
	var new_dir: String = Roth.ROTH_CUSTOM_DBASE_DIRECTORY.path_join(p_new_name)
	p_dbase_info.name = p_new_name
	p_dbase_info.dbase100_filepath = new_dir.path_join("DBASE100.DAT")
	p_dbase_info.dbase200_filepath = new_dir.path_join("DBASE200.DAT")
	p_dbase_info.dbase300_filepath = new_dir.path_join("DBASE300.DAT")
	p_dbase_info.dbase400_filepath = new_dir.path_join("DBASE400.DAT")
	p_dbase_info.dbase500_filepath = new_dir.path_join("DBASE500.DAT")
	MapPack.update_subpack_name(p_dbase_info)
	Roth.settings_updated.emit()


static func import(p_name: String) -> void:
	var dbase_info := {
		"name": p_name,
	}
	var dbase_dir: String = Roth.ROTH_CUSTOM_DBASE_DIRECTORY.path_join(dbase_info.name)
	var dbase_100_filename := dbase_dir.path_join("DBASE100.DAT")
	var dbase_100 := FileAccess.open(dbase_100_filename, FileAccess.READ)
	dbase_info.merge(Parser.parse_section(dbase_100, DBase100.DBASE100_HEADER))
	dbase_info.erase("signature")
	dbase_info.erase("unk_dword_02")
	dbase_info.erase("unk_dword_11")
	dbase_100.close()
	
	dbase_packs.append(dbase_info)


static func get_first_vanilla() -> Dictionary:
	var vanilla_dbase_array: Array = dbase_packs.filter(func (a:Dictionary) -> bool: return true if "vanilla" in a else false)
	return vanilla_dbase_array[0] if len(vanilla_dbase_array) > 0 else {"name": "None", "invalid": true}


static func get_by_installation(p_installation: ROTHInstallation) -> Dictionary:
	var vanilla_dbase_array: Array = dbase_packs.filter(func (a:Dictionary) -> bool: return true if "vanilla" in a and a.vanilla == p_installation else false)
	return vanilla_dbase_array[0] if len(vanilla_dbase_array) > 0 else {"name": "None", "invalid": true}


static func get_by_name(p_name: String) -> Dictionary:
	var dbase_info: Dictionary = get_first_vanilla()
	for dbase_pack: Dictionary in dbase_packs:
		if dbase_pack.name == p_name:
			dbase_info = dbase_pack
	return dbase_info


static func get_by_name_then_installation(p_name: String, p_installation: ROTHInstallation) -> Dictionary:
	var dbase_info: Dictionary = get_by_installation(p_installation)
	for dbase_pack: Dictionary in dbase_packs:
		if dbase_pack.name == p_name:
			dbase_info = dbase_pack
	return dbase_info
