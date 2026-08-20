extends Node

signal settings_updated

const NORMALITY_CUSTOM_MAP_DIRECTORY: String = "user://normality/maps"
const NORMALITY_CUSTOM_MAP_PACKS_DIRECTORY: String = "user://normality/map_packs"
var NORMALITY_TEMP_DIRECTORY: String = OS.get_user_data_dir().path_join("normality/temp")
var NORMALITY_CUSTOM_INSTALLS_DIRECTORY: String = OS.get_user_data_dir().path_join("normality/installs")

var installations: Array = []
var current_installation: NormalityInstallation = null


func _ready() -> void:
	if not DirAccess.dir_exists_absolute(NORMALITY_CUSTOM_MAP_DIRECTORY):
		DirAccess.make_dir_recursive_absolute(NORMALITY_CUSTOM_MAP_DIRECTORY)
	if not DirAccess.dir_exists_absolute(NORMALITY_CUSTOM_MAP_PACKS_DIRECTORY):
		DirAccess.make_dir_recursive_absolute(NORMALITY_CUSTOM_MAP_PACKS_DIRECTORY)
	
	var normality_installations: Array = Settings.settings.get("normality_installations", [])
	for installation_directory: String in normality_installations:
		installations.append(NormalityInstallation.new(installation_directory))
	
	var options: Dictionary = Settings.settings.get("normality_options", {})
	var current_install: int = options.get("current_install", 0)
	if current_install >= len(installations) or current_install < 0:
		current_install = 0
	if current_install < len(installations):
		current_installation = installations[current_install]
		for installation: NormalityInstallation in installations:
			NormPack.init_vanilla(installation)
	
	NormPack.init_custom(NORMALITY_CUSTOM_MAP_DIRECTORY, NORMALITY_CUSTOM_MAP_PACKS_DIRECTORY)
	
	await get_tree().get_root().ready
	settings_updated.emit()


func add_installation(directory: String) -> void:
	var installation := NormalityInstallation.new(directory)
	installations.append(installation)
	Settings.update_settings("normality_installations", installations.map(func (i: NormalityInstallation) -> String: return i.directory))
	NormPack.init_vanilla(installation)
	if current_installation == null:
		current_installation = installation
	settings_updated.emit()


func set_current_installation(installation: NormalityInstallation) -> void:
	current_installation = installation
	Settings.update_settings("normality_options", { "current_install": installations.find(installation) })
	settings_updated.emit()


func remove_installation(installation: NormalityInstallation) -> void:
	# Remove map pack and unload maps
	for i in range(len(NormPack.map_packs)):
		var map_pack: Dictionary = NormPack.map_packs[i]
		if "vanilla" in map_pack and map_pack.vanilla == installation:
			NormPack.map_packs.pop_at(i)
			for j in range(len(map_pack.maps)-1,-1,-1):
				var map: Map = map_pack.maps[j]
				if map.editable_map:
					map.editable_map.unload()
				map.unload()
			break
	
	# Remove installation
	installations.erase(installation)
	Settings.update_settings("normality_installations", installations.map(func (i: NormalityInstallation) -> String: return i.directory))
	if installation == current_installation:
		current_installation = null
	
	settings_updated.emit()


func load_maps(maps_array: Array) -> void:
	var start_time: int = Time.get_ticks_msec()
	#var unique_map_packs: Array = []
	#for map: Map in maps_array:
		#if map.map_info.map_pack not in unique_map_packs:
			#unique_map_packs.append(map.map_info.map_pack)
	#for map_pack: Dictionary in unique_map_packs:
		#Das.get_index_from_das(0, map_pack.das2_info, 293)
	for map: Map in maps_array:
		var loaded_map: Map = map.create_editable_map()
		loaded_map.load_map()
		Roth.das_loading_started.emit(map.map_info.name)
		await loaded_map.load_das()
		Roth.map_loading_finished.emit(loaded_map)
	Roth.map_loading_completely_finished.emit()
	print("Maps loaded in: %.2fs" % ((Time.get_ticks_msec()-start_time)/1000.0))


func test_run_maps(map_pack: Dictionary, starting_map: Map = null, player_data: Dictionary = {}) -> void:
# Check for valid install
	if not current_installation.is_valid():
		return
	
	
	# Delete and recreate temporary run directory
	Utility.remove_dir_recursive(NORMALITY_TEMP_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(NORMALITY_TEMP_DIRECTORY)
	
	
	# Check for proper dosbox configuration
	var dosbox_settings: Dictionary = Settings.settings.get("dosbox_settings", {})
	var dosbox_executable: String = ""
	var dosbox_config: String = ""
	if dosbox_settings.get("use_installs_dosbox", true):
		dosbox_executable = current_installation.dosbox_exe
	else:
		dosbox_executable = dosbox_settings.get("dosbox_executable", "")
	
	if dosbox_executable.is_empty() or not FileAccess.file_exists(dosbox_executable):
		Dialog.information("DOSBox executable not configured", "Error", false, Vector2(400,150))
		return
	
	if dosbox_settings.get("use_installs_dosbox_config", false):
		dosbox_config = current_installation.dosbox_config
	elif dosbox_settings.get("use_location_dosbox_config", false):
		dosbox_config = dosbox_settings.get("dosbox_config", "")
	elif dosbox_settings.get("use_internal_dosbox_config", true):
		dosbox_config = NORMALITY_TEMP_DIRECTORY.path_join("dosboxROTH.conf")
		#ROTHInstallation.write_dosbox_mapper_file(NORMALITY_TEMP_DIRECTORY.path_join("mapper.txt"), Settings.settings.get("dosbox_keymap", {}))
		ROTHInstallation.write_dosbox_config_file(dosbox_config, dosbox_settings)
	
	if dosbox_config.is_empty() or not FileAccess.file_exists(dosbox_config):
		Dialog.information("DOSBox config not configured", "Error", false, Vector2(400,150))
		return
	
	
	# Create custom install directory
	var norm_directory: String = NORMALITY_CUSTOM_INSTALLS_DIRECTORY.path_join(current_installation.id)
	var success: bool = current_installation.populate_custom_install(norm_directory)
	if not success:
		Dialog.information("NORM.EXE has unknown checksum:\n%s" % current_installation.roth_exe_md5_calculated, "Invalid installation", false, Vector2(450, 200), "Close", HORIZONTAL_ALIGNMENT_CENTER)
		return
	
	
	# Save the maps into temporary directory
	for i in range(len(map_pack.maps)):
		var map: Map = map_pack.maps[i]
		if map.editable_map:
			map.editable_map.save_map(NORMALITY_TEMP_DIRECTORY, player_data if map.editable_map == starting_map else {})
		else:
			if Settings.settings.get("options", {}).get("always_recompile_maps", false):
				var tmp_map: Map = map.create_editable_map(true)
				tmp_map.load_map()
				tmp_map.save_map(NORMALITY_TEMP_DIRECTORY, player_data if map == starting_map else {})
				tmp_map.unload()
			else:
				DirAccess.copy_absolute(map.map_info.filepath, NORMALITY_TEMP_DIRECTORY.path_join(map.map_info.name+".RAW"))
	
	
	# Copy map das files into temporary directory
	for map: Map in map_pack.maps:
		var dest_filepath: String = NORMALITY_TEMP_DIRECTORY.path_join(map.map_info.das_info.name+".MGL")
		if "filepath" in map.map_info.das_info:
			DirAccess.copy_absolute(map.map_info.das_info.filepath_mgl, dest_filepath)
	
	
	# Copy and Patch NORM.EXE with new map/das list
	DirAccess.copy_absolute(current_installation.normality_exe, norm_directory.path_join("NORM.EXE"))
	var file := FileAccess.open(norm_directory.path_join("NORM.EXE"), FileAccess.READ_WRITE)
	var i: int = 0
	
	if starting_map:
		file.seek(NormalityInstallation.DAS_OFFSETS[i])
		file.store_8(ord("m"))
		file.store_8(ord(":"))
		file.store_8(ord("\\"))
		for c: String in starting_map.map_info.das_info.name.to_lower():
			file.store_8(ord(c))
		file.store_8(0)
		while file.get_position() < NormalityInstallation.DAS_OFFSETS[i+1]:
			file.store_8(0)
		file.seek(NormalityInstallation.MAP_OFFSETS[i])
		file.store_8(ord("m"))
		file.store_8(ord(":"))
		file.store_8(ord("\\"))
		for c: String in starting_map.map_info.name.to_lower():
			file.store_8(ord(c))
		file.store_8(ord("."))
		file.store_8(ord("r"))
		file.store_8(ord("a"))
		file.store_8(ord("w"))
		file.store_8(0)
		while file.get_position() < NormalityInstallation.MAP_OFFSETS[i+1]:
			file.store_8(0)
		i += 1
	for map: Map in map_pack.maps:
		if map == starting_map.preview_map or starting_map == map:
			continue
		file.seek(NormalityInstallation.DAS_OFFSETS[i])
		file.store_8(ord("m"))
		file.store_8(ord(":"))
		file.store_8(ord("\\"))
		for c: String in map.map_info.das_info.name.to_lower():
			file.store_8(ord(c))
		file.store_8(0)
		while file.get_position() < NormalityInstallation.DAS_OFFSETS[i+1]:
			file.store_8(0)
		file.seek(NormalityInstallation.MAP_OFFSETS[i])
		file.store_8(ord("m"))
		file.store_8(ord(":"))
		file.store_8(ord("\\"))
		for c: String in map.map_info.name.to_lower():
			file.store_8(ord(c))
		file.store_8(ord("."))
		file.store_8(ord("r"))
		file.store_8(ord("a"))
		file.store_8(ord("w"))
		file.store_8(0)
		while file.get_position() < NormalityInstallation.MAP_OFFSETS[i+1]:
			file.store_8(0)
		i += 1
	while i < 30:
		file.seek(NormalityInstallation.DAS_OFFSETS[i])
		file.store_8(0)
		file.seek(NormalityInstallation.MAP_OFFSETS[i])
		file.store_8(0)
		i += 1
	file.close()
	
	NormalityInstallation.write_config_ini(norm_directory.path_join("CONFIG.INI"), Settings.settings.get("normality_options", {}).get("disable_cdrom", true))
	
	# Create the dosbox auto exec .conf file
	var dosbox_autoexec_filepath := NORMALITY_TEMP_DIRECTORY.path_join("dosbox_autoexec.conf")
	var autoexec := FileAccess.open(dosbox_autoexec_filepath, FileAccess.WRITE)
	autoexec.store_string("[autoexec]\n")
	autoexec.store_string("mount c \"%s\"\n" % norm_directory)
	autoexec.store_string("imgmount d \"%s\" -t iso -fs iso\n" % current_installation.normality_iso)
	autoexec.store_string("mount m \"%s\"\n" % NORMALITY_TEMP_DIRECTORY)
	autoexec.store_string("c:\n")
	autoexec.store_string("NORM.EXE /nointro\n")
	autoexec.store_string("exit\n")
	autoexec.close()
	
	
	# Assemble the dosbox command line arguments
	var dosbox_args := []
	dosbox_args.append_array([
		"-conf",
		dosbox_config
	])
	dosbox_args.append_array([
		"-conf",
		dosbox_autoexec_filepath
	])
	
	if OS.get_name() == "Linux" and dosbox_executable.get_extension().to_lower() == "exe" and dosbox_settings.get("linux_use_wine", false):
		dosbox_args.insert(0, dosbox_executable)
		dosbox_executable = "wine"
	
	
	# Run dosbox
	OS.execute(dosbox_executable, dosbox_args)
