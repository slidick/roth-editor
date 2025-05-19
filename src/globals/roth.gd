extends Node

signal settings_loaded
signal map_loading_started(map_info: String)
signal map_loading_updated(status: String, progress: float)
signal map_loading_finished(map_info: Dictionary)
signal map_loading_completely_finished
@warning_ignore("unused_signal")
signal das_loading_started
signal das_loading_updated(progress: float, das_file: String)
signal das_loading_finished(das: Dictionary)


const SCALE_3D_WORLD: float = 100.0
const SCALE_2D_WORLD: float = 10.0
var ROTH_CUSTOM_MAP_DIRECTORY: String = OS.get_user_data_dir().path_join("maps")


var res: Dictionary = {}
var maps: Array = []
var das_files: Array = []
var directory: String = ""
var loaded_maps: Dictionary = {}
var loaded_das: Dictionary = {}
var loading_das: Dictionary = {}

var audio_player: RothAudioPlayer

## Initialization
func _ready() -> void:
	audio_player = RothAudioPlayer.new()
	add_child(audio_player)
	
	if not DirAccess.dir_exists_absolute(ROTH_CUSTOM_MAP_DIRECTORY):
		DirAccess.make_dir_recursive_absolute(ROTH_CUSTOM_MAP_DIRECTORY)
	Settings.update_settings("locations", {"custom.res": ROTH_CUSTOM_MAP_DIRECTORY.path_join("custom.res")})
	
	das_loading_updated.connect(_on_das_loading_updated)
	Settings.settings_updated.connect(_on_settings_updated)
	
	# Wait for the scene to be ready so other nodes have time to connect to this nodes settings_loaded signal
	await get_tree().get_root().ready
	load_roth_settings()


func _on_das_loading_updated(progress: float, das_file: String) -> void:
	map_loading_updated.emit("Loading textures: %s" % das_file, progress)


func _on_settings_updated(key: String) -> void:
	if key == "locations":
		load_roth_settings()


## Loads roth.res location using Settings autoload. [br]
## Reads roth.res to get list of maps and associated das files.
func load_roth_settings() -> void:
	var locations: Variant = Settings.settings.get("locations")
	maps.clear()
	das_files.clear()
	if locations and locations.get("roth.res"):
		directory = locations.get("roth.res").get_base_dir()
		var file := FileAccess.open(locations.get("roth.res"), FileAccess.READ)
		# Parse the roth.res file
		while file.get_position() < file.get_length():
			var line: String = file.get_line().replace("\\", "/").replace("\"", "")
			if line.contains("="):
				var line_split: Array = line.split("=")
				if line_split[0] == "das2":
					line_split[1] += ".das"
					das_files.append(line_split[1].to_upper())
				res[line_split[0]] = line_split[1].to_upper()
				
			elif line.contains("maps"):
				continue
			elif line.contains("}"):
				continue
			elif line.contains(" "):
				var line_split: Array = line.split(" ")
				maps.append({
					"name": line_split[0].get_file().get_basename().to_upper(),
					"raw": (line_split[0]+".raw").to_upper(),
					"das": (line_split[1]+".das").to_upper(),
					"custom": false,
				})
			else:
				res[line] = true
		file.close()
		
		for das: String in maps.map(func (map: Dictionary) -> String: return map.das ):
			if das not in das_files:
				das_files.append(das)
		
		das_files.sort()
	
	if locations and locations.get("custom.res"):
		if not FileAccess.file_exists(locations.get("custom.res")):
			var file_custom := FileAccess.open(locations.get("custom.res"), FileAccess.WRITE)
			file_custom.close()
		var file := FileAccess.open(locations.get("custom.res"), FileAccess.READ)
		while file.get_position() < file.get_length():
			var line: String = file.get_line()
			var line_split: Array = line.split(" ")
			maps.append({
				"name": line_split[0].get_file().get_basename().to_upper(),
				"raw": (line_split[0]+".raw").to_upper(),
				"das": (line_split[1]+".das").to_upper(),
				"custom": true,
			})
	settings_loaded.emit()


## Does an initial partial load of a map. [br]
## Once loaded, maps are not unloaded.
func get_map(map_info: Dictionary) -> Map:
	# Check if map is already loaded
	if map_info.name in loaded_maps:
		return loaded_maps[map_info.name]
	
	var map := Map.new(map_info)
	loaded_maps[map_info.name] = map
	return map


## Loads an array of maps textures using the das file then signals viewer window
func load_maps(maps_array: Array) -> void:
	for map_info: Dictionary in maps_array:
		map_loading_started.emit(map_info.name)
		await get_das(map_info.das)
		map_loading_finished.emit(map_info)
	map_loading_completely_finished.emit()


## Return or load the requested das_file. [br]
## Das files stay loaded after initial load.
func get_das(das_file: String) -> Dictionary:
	if das_file in loaded_das:
		return loaded_das[das_file]
	elif das_file in loading_das:
		return await das_loading_finished
	else:
		loading_das[das_file] = true
		loaded_das[das_file] = await Das.load_das(das_file)
		loading_das.erase(das_file)
		return loaded_das[das_file]


func get_index_from_das(index:int, das_file: String) -> Dictionary:
	if das_file in loaded_das:
		if index in loaded_das[das_file]:
			return loaded_das[das_file][index]
	return Das._get_index_from_das(index, das_file)


func save_custom(map_raw: PackedByteArray, map_name: String, map_das: String, add_to_custom: bool = false) -> void:
	var raw_filepath := ROTH_CUSTOM_MAP_DIRECTORY.path_join(map_name.to_upper() + ".RAW")
	var file := FileAccess.open(raw_filepath, FileAccess.WRITE)
	file.store_buffer(map_raw)
	file.close()
	
	if add_to_custom:
		var file_custom_res := FileAccess.open(Settings.settings.locations.get("custom.res"), FileAccess.READ_WRITE)
		file_custom_res.seek(file_custom_res.get_length())
		file_custom_res.store_string("%s %s\n" % [map_name.to_lower(), map_das.get_basename().to_lower()])


## Takes a compiled map, saves it to a temporary file, and runs it.
func test_run_map(map_raw: PackedByteArray, map_info: Dictionary, with_objects: bool) -> void:
	if not FileAccess.file_exists(Settings.settings.locations.get("roth.res")):
		Console.print("Roth.res not selected.")
		return
	
	if not FileAccess.file_exists(Settings.settings.locations.get("dosbox")):
		Console.print("Dosbox executable not selected.")
		return
	
	
	var dosbox_bin: String = Settings.settings.locations.get("dosbox")
	var roth_directory: String = Settings.settings.locations.get("roth.res").get_base_dir().path_join("..")
	
	
	
	var dosbox_autoexec_filepath := OS.get_user_data_dir().path_join("dosbox_roth_auto.conf")
	var roth_res_test_filepath := ROTH_CUSTOM_MAP_DIRECTORY.path_join("test.res")
	
	var raw_filename := "TEST_MAP.RAW"
	var raw_filepath := ROTH_CUSTOM_MAP_DIRECTORY.path_join(raw_filename)
	var file := FileAccess.open(raw_filepath, FileAccess.WRITE)
	file.store_buffer(map_raw)
	file.close()
	
	var roth_res_test := """
	version="Roth Custom Maps"
	snd=data\\fxscript.sfx
	das2=m\\ademo

	maps {
	"""
	
	roth_res_test += "D:\\%s %s\n" % [raw_filename.get_basename(), map_info.das.replace("/", "\\").get_basename()]
	
	for custom_map_info:Dictionary in Roth.maps:
		if custom_map_info.custom:
			roth_res_test += "	D:\\%s %s\n" % [custom_map_info.raw.get_basename(), custom_map_info.das.replace("/", "\\").get_basename()]
	
	
	roth_res_test += """
	m\\study1 m\\demo
	m\\study2 m\\demo
	m\\study3 m\\demo
	m\\study4 m\\demo
	m\\abagate2 m\\demo3
	m\\optemp1 m\\demo
	m\\anubis m\\demo2
	m\\gnarl1 m\\demo2
	m\\mauso1ea m\\demo4
	m\\mauso1eb m\\demo4
	m\\mas3 m\\demo4
	m\\mas4 m\\demo4
	m\\mas6 m\\demo4
	m\\mas7 m\\demo4
	m\\aelf m\\demo4
	m\\caverns2 m\\demo4
	m\\caverns3 m\\demo4
	m\\grave m\\demo4
	m\\maze m\\demo4
	m\\dominion m\\demo3
	m\\salvat m\\demo3
	m\\dopple m\\demo3
	m\\soulst2 m\\demo1
	m\\soulst3 m\\demo1
	m\\tower1 m\\demo2
	m\\tgate1f m\\demo2
	m\\tgate1g m\\demo2
	m\\tgate1h m\\demo2
	m\\tgate1i m\\demo2
	m\\caverns m\\demo
	m\\temple1 m\\demo
	m\\raquia1 m\\demo1
	m\\raquia2 m\\demo1
	m\\raquia3 m\\demo1
	m\\raquia4 m\\demo1
	m\\raquia5 m\\demo1
	m\\church1 m\\demo1
	m\\vicar m\\demo1
	m\\aqua1 m\\demo1
	m\\aqua2 m\\demo1
	m\\lrinth m\\demo1
	m\\lrinth1 m\\demo1
	m\\elohim1 m\\demo1
	m\\vicar1 m\\demo1
	}
	"""
	
	var roth_res_test_file := FileAccess.open(roth_res_test_filepath, FileAccess.WRITE)
	roth_res_test_file.store_string(roth_res_test)
	roth_res_test_file.close()
	
	
	
	
	var autoexec := FileAccess.open(dosbox_autoexec_filepath, FileAccess.WRITE)
	autoexec.store_string("[autoexec]\n")
	autoexec.store_string("mount d \"%s\"\n" % ROTH_CUSTOM_MAP_DIRECTORY)
	autoexec.store_string("mount c \"%s\"\n" % roth_directory)
	autoexec.store_string("c:\n")
	autoexec.store_string("cd \\roth\n")
	if with_objects:
		autoexec.store_string("ROTH.EXE /G 03 @D:\\test.res\n")
	else:
		autoexec.store_string("ROTH.EXE /9 /G 03 FILE D:\\%s DAS %s SND DATA\\FXSCRIPT.SFX\n" % [raw_filename, map_info.das.replace("/", "\\")])
	autoexec.store_string("exit\n")
	autoexec.close()
	
	
	var dosbox_args := []
	if Settings.settings.locations.get("dosbox_config") and FileAccess.file_exists(Settings.settings.locations.get("dosbox_config")):
		dosbox_args.append_array([
			"-conf",
			Settings.settings.locations.get("dosbox_config")
		])
	
	dosbox_args.append_array([
		"-conf",
		dosbox_autoexec_filepath
	])
	
	#print("Executing: %s" % dosbox_bin)
	#print(dosbox_args)
	
	OS.execute(dosbox_bin, dosbox_args)


## Converts from game rotation to degrees
func rotation_to_degrees(rotation: float) -> int:
	return int(-180 + (90 * (rotation / 128)))


## Converts from degrees to game rotation
func degrees_to_rotation(degrees: float) -> int:
	return int(((degrees + 180) * 128) / 90)


func play_audio_buffer(buffer: PackedVector2Array) -> void:
	audio_player.play_buffer(buffer)

func stop_audio_buffer() -> void:
	audio_player.stop_buffer()
