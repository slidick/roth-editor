extends Node

signal settings_updated

var installations: Array = []
var current_installation: NormalityInstallation = null


func _ready() -> void:
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


func test_run_maps(_map_pack: Dictionary, _starting_map: Map = null, _player_data: Dictionary = {}) -> void:
	pass
