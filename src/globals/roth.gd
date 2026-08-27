extends Node

signal settings_updated
signal das_loading_started(info: String)
signal map_loading_finished(map: Map)
signal map_loading_completely_finished
@warning_ignore("unused_signal")
signal das_loading_updated(progress: float, das_info: Dictionary)
@warning_ignore("unused_signal")
signal das_loading_finished(das: Dictionary)
@warning_ignore("unused_signal")
signal das_parse_finished(das: Dictionary)
@warning_ignore("unused_signal")
signal das_compile_finished(das: Dictionary)
@warning_ignore("unused_signal")
signal gdv_loading_updated(progress: float)
@warning_ignore("unused_signal")
signal close_map(map: Map)
@warning_ignore("unused_signal")
signal editor_action(p_map: Map, p_name: String)
@warning_ignore("unused_signal")
signal edit_texture(p_das_info: Dictionary, p_index: int)

const SCALE_3D_WORLD: float = 100.0
const SCALE_2D_WORLD: float = 10.0
var ROTH_CUSTOM_MAP_DIRECTORY: String = OS.get_user_data_dir().path_join("maps")
var ROTH_CUSTOM_MAP_PACKS_DIRECTORY: String = OS.get_user_data_dir().path_join("map_packs")
var ROTH_CUSTOM_DBASE_DIRECTORY: String = OS.get_user_data_dir().path_join("dbase")
var ROTH_CUSTOM_SFX_DIRECTORY: String = OS.get_user_data_dir().path_join("sfx")
var ROTH_CUSTOM_DAS_DIRECTORY: String = OS.get_user_data_dir().path_join("das")
var ROTH_CUSTOM_DAS2_DIRECTORY: String = OS.get_user_data_dir().path_join("das2")
var ROTH_CUSTOM_INSTALLS_DIRECTORY: String = OS.get_user_data_dir().path_join("installs")
var ROTH_CUSTOM_BACKDROPS_DIRECTORY: String = OS.get_user_data_dir().path_join("backdrops")
var ROTH_CUSTOM_ICONS_DIRECTORY: String = OS.get_user_data_dir().path_join("icons")
var ROTH_TEMP_DIRECTORY: String = OS.get_user_data_dir().path_join("temp")

const SEQUENTIAL_UNDO_TIMEOUT: float = 1.5
const DRAGGING_THRESHOLD: float = 2.0

const HIGHLIGHT_MATERIAL: StandardMaterial3D = preload("uid://b3vv75mwnat5k")
const SELECTED_MATERIAL: StandardMaterial3D = preload("uid://bcwfrjbr5vhmi")
const HIGHLIGHT_FIXED_Y_MATERIAL: StandardMaterial3D = preload("uid://dhsattf813kya")
const SELECTED_FIXED_Y_MATERIAL: StandardMaterial3D = preload("uid://b5iarhl24whsd")

const DEFAULT_TEXTURE_PRESETS: Dictionary = {
	"DEMO": {
		"STUDY": { "ceiling": 201, "floor": 59, "wall": 35 },
		"HALLWAY": { "ceiling": 201, "floor": 58, "wall": 8 },
		"MAUSOLEUM": { "ceiling": 766, "floor": 761, "wall": 763 },
	},
	"DEMO1": {
		"CHURCH": { "ceiling": 153, "floor": 168, "wall": 154},
		"GARDEN": { "ceiling": 1, "floor": 9, "wall": 26},
		"TOWER": { "ceiling": 541, "floor": 535, "wall": 861},
	},
	"DEMO2": {
		"TEMPLE": { "ceiling": 5, "floor": 7, "wall": 4},
		"LAVA": { "ceiling": 33, "floor": 30, "wall": 32},
		"HALLWAY": { "ceiling": 115, "floor": 116, "wall": 118},
	},
	"DEMO3": {
		"ALIEN": { "ceiling": 179, "floor": 179, "wall": 180 },
		"CAVERN": { "ceiling": 50, "floor": 118, "wall": 89 },
		"RITUAL": { "ceiling": 625, "floor": 610, "wall": 605 },
	},
	"DEMO4": {
		"MAUSOLEUM": { "ceiling": 2778, "floor": 2751, "wall": 2787 },
		"EXTERIOR": { "ceiling": 0, "floor": 331, "wall": 2201 },
		"TOMB": { "ceiling": 2025, "floor": 2031, "wall": 2235 },
	}
}

var roth_installations: Array = []
var current_installation: ROTHInstallation
var dosbox_pid: int = -1
var halve_display_values: bool :
	get():
		return Settings.settings.get("options", {}).get("halve_display_values", true)


func _ready() -> void:
	# Create directories
	if not DirAccess.dir_exists_absolute(ROTH_CUSTOM_MAP_DIRECTORY):
		DirAccess.make_dir_recursive_absolute(ROTH_CUSTOM_MAP_DIRECTORY)
	if not DirAccess.dir_exists_absolute(ROTH_CUSTOM_MAP_PACKS_DIRECTORY):
		DirAccess.make_dir_recursive_absolute(ROTH_CUSTOM_MAP_PACKS_DIRECTORY)
	if not DirAccess.dir_exists_absolute(ROTH_CUSTOM_DBASE_DIRECTORY):
		DirAccess.make_dir_recursive_absolute(ROTH_CUSTOM_DBASE_DIRECTORY)
	if not DirAccess.dir_exists_absolute(ROTH_CUSTOM_SFX_DIRECTORY):
		DirAccess.make_dir_recursive_absolute(ROTH_CUSTOM_SFX_DIRECTORY)
	if not DirAccess.dir_exists_absolute(ROTH_CUSTOM_DAS_DIRECTORY):
		DirAccess.make_dir_recursive_absolute(ROTH_CUSTOM_DAS_DIRECTORY)
	if not DirAccess.dir_exists_absolute(ROTH_CUSTOM_DAS2_DIRECTORY):
		DirAccess.make_dir_recursive_absolute(ROTH_CUSTOM_DAS2_DIRECTORY)
	if not DirAccess.dir_exists_absolute(ROTH_CUSTOM_BACKDROPS_DIRECTORY):
		DirAccess.make_dir_recursive_absolute(ROTH_CUSTOM_BACKDROPS_DIRECTORY)
	if not DirAccess.dir_exists_absolute(ROTH_CUSTOM_ICONS_DIRECTORY):
		DirAccess.make_dir_recursive_absolute(ROTH_CUSTOM_ICONS_DIRECTORY)
	
	# Initialize default texture presets
	if Settings.settings.get("texture_presets", {}).is_empty():
		Settings.update_settings("texture_presets", DEFAULT_TEXTURE_PRESETS.duplicate(true))
	
	# Migrate settings
	migrate_to_uuid_map_filenames(false)
	migrate_install_directory(false)
	migrate_dosbox_settings(false)
	
	# Initialize installations
	var installations: Array = Settings.settings.get("roth_installations", [])
	for directory: String in installations:
		roth_installations.append(ROTHInstallation.new(directory))
	var current_install: int = Settings.settings.get("options", {}).get("current_install", 0)
	if current_install >= len(roth_installations) or current_install < 0:
		current_install = 0
	
	# Create sub packs (sfx,das2,dbase,backdrop,icon)
	if current_install < len(roth_installations):
		current_installation = roth_installations[current_install]
		for installation: ROTHInstallation in roth_installations:
			DASPack.init_vanilla_das2_pack(installation)
			DBasePack.init_vanilla(installation)
			SFXPack.init_vanilla(installation)
			BackdropPack.init_vanilla(installation)
			IconPack.init_vanilla(installation)
	DASPack.init_custom_das2_packs(ROTH_CUSTOM_DAS2_DIRECTORY)
	DBasePack.init_custom(ROTH_CUSTOM_DBASE_DIRECTORY)
	SFXPack.init_custom(ROTH_CUSTOM_SFX_DIRECTORY)
	BackdropPack.init_custom(ROTH_CUSTOM_BACKDROPS_DIRECTORY)
	IconPack.init_custom(ROTH_CUSTOM_ICONS_DIRECTORY)
	
	# Create das and map packs
	if current_install < len(roth_installations):
		for installation: ROTHInstallation in roth_installations:
			MapPack.init_vanilla(installation)
	DASPack.init_custom_das_packs(ROTH_CUSTOM_DAS_DIRECTORY)
	MapPack.init_custom(ROTH_CUSTOM_MAP_DIRECTORY, ROTH_CUSTOM_MAP_PACKS_DIRECTORY)
	
	# Wait for the scene to be ready so other nodes have time to connect to the settings_updated signal
	await get_tree().get_root().ready
	settings_updated.emit()


func migrate_to_uuid_map_filenames(dryrun: bool = true) -> void:
	for file: String in DirAccess.get_files_at(ROTH_CUSTOM_MAP_DIRECTORY):
		if file.get_extension() != "json":
			continue
		if file.get_basename().get_file().length() > 8:
			continue
		var filepath_json: String = ROTH_CUSTOM_MAP_DIRECTORY.path_join(file)
		var filepath: String = filepath_json.trim_suffix("json") + "RAW"
		var new_filepath_json: String = ROTH_CUSTOM_MAP_DIRECTORY.path_join(Utility.uuidv4()) + ".json"
		var new_filepath: String = new_filepath_json.trim_suffix("json") + "RAW"
		
		var uuid_collisions: int = 0
		while FileAccess.file_exists(new_filepath_json):
			if uuid_collisions == 10:
				assert(false, "Inconceivable number of uuid collisions")
				return
			uuid_collisions += 1
			new_filepath_json = ROTH_CUSTOM_MAP_DIRECTORY.path_join(Utility.uuidv4())
			new_filepath = new_filepath_json.trim_suffix("json") + "RAW"
		
		if dryrun:
			print("rename_absolute(%s, %s)" % [filepath_json, new_filepath_json])
			print("rename_absolute(%s, %s)" % [filepath, new_filepath])
		else:
			DirAccess.rename_absolute(filepath_json, new_filepath_json)
			if FileAccess.file_exists(filepath):
				DirAccess.rename_absolute(filepath, new_filepath)
		
		var count: int = 1
		while FileAccess.file_exists(filepath + ".%d" % count):
			if dryrun:
				print("rename_absolute(%s.%d, %s.%d)" % [filepath, count, new_filepath, count])
			else:
				DirAccess.rename_absolute(filepath + ".%d" % count, new_filepath + ".%d" % count)
			count += 1
		count = 1
		while FileAccess.file_exists(filepath_json + ".%d" % count):
			if dryrun:
				print("rename_absolute(%s.%d, %s.%d)" % [filepath_json, count, new_filepath_json, count])
			else:
				DirAccess.rename_absolute(filepath_json + ".%d" % count, new_filepath_json + ".%d" % count)
			count += 1


func migrate_install_directory(dryrun: bool = true) -> void:
	var locations: Dictionary = Settings.settings.get("locations", {})
	var roth_res: Variant = locations.get("roth.res")
	if roth_res:
		print("Erasing settings.json: locations/roth.res")
		if not dryrun:
			Settings.settings.locations.erase("roth.res")
			Settings._save_settings()
	else:
		return
	
	var directory: String = "/".join(roth_res.get_base_dir().split("/").slice(0, -1))
	
	var installation := ROTHInstallation.new(directory)
	if installation.is_valid():
		print("Migrating settings: %s" % directory)
		var installations: Array = Settings.settings.get("roth_installations", [])
		if directory in installations:
			return
		if not dryrun:
			installations.append(directory)
			Settings.update_settings("roth_installations", installations)


func migrate_dosbox_settings(dryrun: bool = true) -> void:
	var dosbox: String = Settings.settings.get("locations", {}).get("dosbox", "")
	var dosbox_config: String = Settings.settings.get("locations", {}).get("dosbox_config", "")
	if not dosbox.is_empty():
		print("Migrating dosbox executable setting")
		if not dryrun:
			Settings.update_settings("dosbox_settings", { "dosbox_executable": dosbox })
	if not dosbox_config.is_empty():
		print("Migrating dosbox config setting")
		if not dryrun:
			Settings.update_settings("dosbox_settings", { "dosbox_config": dosbox_config })
	if Settings.settings.get("locations"):
		print("Removing old locations setting")
		if not dryrun:
			Settings.settings.erase("locations")
			Settings._save_settings()


func add_installation(directory: String) -> void:
	var installation := ROTHInstallation.new(directory)
	roth_installations.append(installation)
	Settings.update_settings("roth_installations", roth_installations.map(func (i: ROTHInstallation) -> String: return i.directory))
	DASPack.init_vanilla_das2_pack(installation)
	DBasePack.init_vanilla(installation)
	SFXPack.init_vanilla(installation)
	BackdropPack.init_vanilla(installation)
	IconPack.init_vanilla(installation)
	MapPack.init_vanilla(installation)
	if current_installation == null:
		current_installation = installation
	var unassigned_map_pack: Dictionary = MapPack.get_unassigned_pack()
	if "invalid" in unassigned_map_pack.dbase_info:
		unassigned_map_pack.dbase_info = DBasePack.get_first_vanilla()
	if "invalid" in unassigned_map_pack.das2_info:
		unassigned_map_pack.das2_info = DASPack.get_first_vanilla_das2_pack()
	if "invalid" in unassigned_map_pack.sfx_info:
		unassigned_map_pack.sfx_info = SFXPack.get_first_vanilla()
	if "invalid" in unassigned_map_pack.backdrop_info:
		unassigned_map_pack.backdrop_info = BackdropPack.get_first_vanilla()
	if "invalid" in unassigned_map_pack.icon_info:
		unassigned_map_pack.icon_info = IconPack.get_first_vanilla()
	settings_updated.emit()


func remove_installation(installation: ROTHInstallation) -> void:
	# Remove map pack and unload maps
	for i in range(len(MapPack.map_packs)):
		var map_pack: Dictionary = MapPack.map_packs[i]
		if "vanilla" in map_pack and map_pack.vanilla == installation:
			MapPack.map_packs.pop_at(i)
			for j in range(len(map_pack.maps)-1,-1,-1):
				var map: Map = map_pack.maps[j]
				if map.editable_map:
					map.editable_map.unload()
				map.unload()
			break
	
	# Remove map pack options
	var options: Dictionary = Settings.settings.get("pack_options", {})
	options.erase("%s_das2" % installation.id)
	options.erase("%s_dbase" % installation.id)
	options.erase("%s_sfx" % installation.id)
	options.erase("%s_backdrop" % installation.id)
	options.erase("%s_icon" % installation.id)
	Settings.update_settings("pack_options", options, true)
	
	# Remove map's das packs
	for i in range(len(DASPack.das_packs)-1,-1,-1):
		var das_info: Dictionary = DASPack.das_packs[i]
		if "vanilla" in das_info and das_info.vanilla == installation:
			DASPack.das_packs.pop_at(i)
	
	# Remove das2 pack
	for i in range(len(DASPack.das2_packs)):
		var das_info: Dictionary = DASPack.das2_packs[i]
		if "vanilla" in das_info and das_info.vanilla == installation:
			DASPack.das2_packs.pop_at(i)
			MapPack.update_subpack_deleted(das_info)
			break
	
	# Remove sfx pack
	for i in range(len(SFXPack.sfx_packs)):
		var sfx_info: Dictionary = SFXPack.sfx_packs[i]
		if "vanilla" in sfx_info and sfx_info.vanilla == installation:
			SFXPack.sfx_packs.pop_at(i)
			MapPack.update_subpack_deleted(sfx_info)
			break
	
	# Remove dbase pack
	for i in range(len(DBasePack.dbase_packs)):
		var dbase_info: Dictionary = DBasePack.dbase_packs[i]
		if "vanilla" in dbase_info and dbase_info.vanilla == installation:
			DBasePack.dbase_packs.pop_at(i)
			MapPack.update_subpack_deleted(dbase_info)
			break
	
	# Remove backdrop pack
	for i in range(len(BackdropPack.backdrop_packs)):
		var backdrop_info: Dictionary = BackdropPack.backdrop_packs[i]
		if "vanilla" in backdrop_info and backdrop_info.vanilla == installation:
			BackdropPack.backdrop_packs.pop_at(i)
			MapPack.update_subpack_deleted(backdrop_info)
			break
	
	# Remove icon pack
	for i in range(len(IconPack.icon_packs)):
		var icon_info: Dictionary = IconPack.icon_packs[i]
		if "vanilla" in icon_info and icon_info.vanilla == installation:
			IconPack.icon_packs.pop_at(i)
			MapPack.update_subpack_deleted(icon_info)
			break
	
	# Remove runtime install
	if DirAccess.dir_exists_absolute(ROTH_CUSTOM_INSTALLS_DIRECTORY.path_join(installation.id)):
		Utility.remove_dir_recursive(ROTH_CUSTOM_INSTALLS_DIRECTORY.path_join(installation.id))
	
	# Remove installation
	roth_installations.erase(installation)
	Settings.update_settings("roth_installations", roth_installations.map(func (i: ROTHInstallation) -> String: return i.directory))
	if installation == current_installation:
		current_installation = null
	
	settings_updated.emit()


func set_current_installation(installation: ROTHInstallation) -> void:
	current_installation = installation
	Settings.update_settings("options", { "current_install": roth_installations.find(installation) })
	settings_updated.emit()


func load_maps(maps_array: Array) -> void:
	var start_time: int = Time.get_ticks_msec()
	var unique_map_packs: Array = []
	for map: Map in maps_array:
		if map.map_info.map_pack not in unique_map_packs:
			unique_map_packs.append(map.map_info.map_pack)
	for map_pack: Dictionary in unique_map_packs:
		Das.get_index_from_das(0, map_pack.das2_info, 293)
	for map: Map in maps_array:
		var loaded_map: Map = map.create_editable_map()
		loaded_map.load_map()
		das_loading_started.emit(map.map_info.name)
		await loaded_map.load_das()
		map_loading_finished.emit(loaded_map)
	map_loading_completely_finished.emit()
	print("Maps loaded in: %.2fs" % ((Time.get_ticks_msec()-start_time)/1000.0))


func test_run_maps(map_pack: Dictionary, starting_map: Map = null, player_data: Dictionary = {}) -> void:
	# Check for valid install
	if not current_installation.is_valid():
		return
	
	
	# Delete and recreate temporary run directory
	Utility.remove_dir_recursive(ROTH_TEMP_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(ROTH_TEMP_DIRECTORY)
	
	
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
		dosbox_config = ROTH_TEMP_DIRECTORY.path_join("dosboxROTH.conf")
		ROTHInstallation.write_dosbox_mapper_file(ROTH_TEMP_DIRECTORY.path_join("mapper.txt"), Settings.settings.get("dosbox_keymap", {}))
		ROTHInstallation.write_dosbox_config_file(dosbox_config, dosbox_settings)
	
	if dosbox_config.is_empty() or not FileAccess.file_exists(dosbox_config):
		Dialog.information("DOSBox config not configured", "Error", false, Vector2(400,150))
		return
	
	
	# Create custom install directory
	var roth_directory: String = ROTH_CUSTOM_INSTALLS_DIRECTORY.path_join(current_installation.id)
	var success: bool = current_installation.populate_custom_install(roth_directory)
	if not success:
		Dialog.information("ROTH.EXE has unknown checksum:\n%s" % current_installation.roth_exe_md5_calculated, "Invalid installation", false, Vector2(450, 200), "Close", HORIZONTAL_ALIGNMENT_CENTER)
		return
	
	
	# Save the maps into temporary directory
	for i in range(len(map_pack.maps)):
		var map: Map = map_pack.maps[i]
		if map.editable_map:
			map.editable_map.save_map(ROTH_TEMP_DIRECTORY, player_data if map.editable_map == starting_map else {})
		else:
			if Settings.settings.get("options", {}).get("always_recompile_maps", false):
				var tmp_map: Map = map.create_editable_map(true)
				tmp_map.load_map()
				tmp_map.save_map(ROTH_TEMP_DIRECTORY, player_data if map == starting_map else {})
				tmp_map.unload()
			else:
				DirAccess.copy_absolute(map.map_info.filepath, ROTH_TEMP_DIRECTORY.path_join(map.map_info.name+".RAW"))
	
	
	# Copy sfx file into temporary directory
	DirAccess.copy_absolute(map_pack.sfx_info.filepath, ROTH_TEMP_DIRECTORY.path_join("FXSCRIPT.SFX"))
	
	
	# Copy das2 into temporary directory
	DirAccess.copy_absolute(map_pack.das2_info.filepath, ROTH_TEMP_DIRECTORY.path_join("DAS2.DAS"))
	
	
	# Create the .res file in the temporary directory with the specified maps
	var roth_res_test_filepath := ROTH_TEMP_DIRECTORY.path_join("test.res")
	var roth_res_test := """version="Roth Custom Maps"\nsnd=%s\ndas2=%s\n\nmaps {\n""" % ["D:\\fxscript", "D:\\das2"]
	if starting_map:
		roth_res_test += "D:\\%s D:\\%s\n" % [starting_map.map_info.name.get_file().get_basename(), starting_map.map_info.das_info.name.md5_text().to_upper().left(8)]
	for map: Map in map_pack.maps:
		if map != starting_map and map != starting_map.preview_map:
			roth_res_test += "D:\\%s D:\\%s\n" % [map.map_info.name.get_file().get_basename(), map.map_info.das_info.name.md5_text().to_upper().left(8)]
	roth_res_test += "}\n"
	
	
	# Write the .res file
	var roth_res_test_file := FileAccess.open(roth_res_test_filepath, FileAccess.WRITE)
	roth_res_test_file.store_string(roth_res_test)
	roth_res_test_file.close()
	
	
	# Copy map das files into temporary directory
	for map: Map in map_pack.maps:
		var dest_filepath: String = ROTH_TEMP_DIRECTORY.path_join(map.map_info.das_info.name.md5_text().to_upper().left(8)+".DAS")
		if "filepath" in map.map_info.das_info:
			DirAccess.copy_absolute(map.map_info.das_info.filepath, dest_filepath)
	
	
	# Copy dbase into temporary directory
	for filepath: String in [map_pack.dbase_info.dbase100_filepath, map_pack.dbase_info.dbase200_filepath, map_pack.dbase_info.dbase300_filepath, map_pack.dbase_info.dbase400_filepath, map_pack.dbase_info.dbase500_filepath]:
		#var dest_filepath: String = roth_directory.path_join(filepath.get_file())
		var dest_filepath: String = ROTH_TEMP_DIRECTORY.path_join(filepath.get_file().replace("DBASE", "DB"))
		DirAccess.copy_absolute(filepath, dest_filepath)
	
	# Copy backdrop into temporary directory
	DirAccess.copy_absolute(map_pack.backdrop_info.filepath, ROTH_TEMP_DIRECTORY.path_join("BACKDROP.RAW"))
	
	# Copy icons into temporary directory
	DirAccess.copy_absolute(map_pack.icon_info.filepath, ROTH_TEMP_DIRECTORY.path_join("ICONS.ALL"))
	
	
	# Create the dosbox auto exec .conf file
	var dosbox_autoexec_filepath := OS.get_user_data_dir().path_join("dosbox_roth_auto.conf")
	var autoexec := FileAccess.open(dosbox_autoexec_filepath, FileAccess.WRITE)
	autoexec.store_string("[autoexec]\n")
	autoexec.store_string("mount d \"%s\"\n" % ROTH_TEMP_DIRECTORY)
	autoexec.store_string("mount c \"%s\"\n" % roth_directory)
	autoexec.store_string("mount g \"%s\n" % current_installation.gdv_directory)
	autoexec.store_string("c:\n")
	# Only the older version allows command line arguments
	if current_installation.roth_exe_version == ROTHInstallation.OLD_EXE:
		# Increase starting gamma
		autoexec.store_string("ROTH.EXE /G 03 @D:\\test.res\n")
	else:
		# Newer version should save gamma anyway
		autoexec.store_string("ROTH.EXE @D:\\test.res\n")
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
	if dosbox_pid > -1 and OS.is_process_running(dosbox_pid):
		OS.kill(dosbox_pid)
	dosbox_pid = OS.create_process(dosbox_executable, dosbox_args)
