extends Object
class_name Map

signal name_changed(new_name: String)

var metadata := {
	"initPosX": 0,
	"initPosZ": 0,
	"initPosY": 0,
	"rotation": 0,
	"moveSpeed": 5,
	"playerHeight": 72,
	"maxClimb": 32,
	"minFit": 48,
	"unk0x10": 2,
	"candleGlow": 8,
	"lightAmbience": 0,
	"unk0x16": 0,
	"skyTexture": 0,
	"unk0x1A": 0,
}

var sectors := []
var faces := []
var objects := []
var sound_effects := []
var sfx_zones := []
var vertices_count: int = 0
var map_info := {}
var commands_section := {
	"header": {
		"signature": "3u",
		"unk0x02": 0
	},
	"entryCommandIndexes": [],
	"allCommands": []
}
var node: MapNode3D
var editor_metadata := {}
var das: Dictionary
var is_loaded: bool = false
var preview_map: Map = null
var editable_map: Map = null


static func load_from_bytes(p_map_info: Dictionary, p_bytes: PackedByteArray) -> Map:
	var map_json: Dictionary = Raw.parse_bytes(p_bytes, "normality" in p_map_info)
	if map_json.is_empty():
		return
	var loaded_map := Map.new(p_map_info)
	loaded_map.load_json(map_json)
	loaded_map.is_loaded = true
	return loaded_map


static func get_triggering_ids(command_section: Dictionary, command_index: int) -> Array:
	var triggering_ids: Array = []
	for entry_command: int in command_section.entryCommandIndexes:
		var command: Dictionary = command_section.allCommands[entry_command-1]
		var next_command_index: int = command.nextCommandIndex
		
		while next_command_index != 0:
			var next_command: Dictionary = command_section.allCommands[next_command_index-1]
			if next_command.index == command_index:
				if len(command.args) > 1:
					triggering_ids.append(command.args[1])
			next_command_index = next_command.nextCommandIndex
	
	return triggering_ids


static func check_map_name(title: String, map_pack: Dictionary) -> String:
	var error := ""
	if len(title) > 8:
		error = "Please limit to 8 characters"
	if title.find(" ") > 0:
		error = "No spaces"
	if title.to_upper() in map_pack.maps.map(func (m: Map) -> String: return m.map_info.name):
		error = "Name in use"
	if len(title) == 0:
		error = "Name is empty"
	return error


func _init(p_map_info: Dictionary) -> void:
	map_info = p_map_info


func load_map() -> void:
	if not is_loaded:
		var map_json: Dictionary = Raw.parse_file(map_info.filepath, "normality" in map_info)
		if map_json.is_empty():
			return
		load_json(map_json)
		is_loaded = true


func load_json(map_json: Dictionary) -> void:
	for i in range(len(map_json.sectorsSection.sectors)):
		sectors.append( Sector.new( 
				map_json.sectorsSection.sectors[i],
				self,
				map_json.midPlatformsSection.platforms if "midPlatformsSection" in map_json else [],
			)
		)
		for object_data: Dictionary in sectors[i].data.objectInformation:
			objects.append( ObjectRoth.new(
					object_data,
					self,
					sectors[i]
				)
			)
	
	for i in range(len(map_json.facesSection.faces)):
		faces.append( Face.new(
				map_json.facesSection.faces[i],
				self,
				map_json.verticesSection.vertices,
				sectors,
				map_json.faceTextureMappingSection.mappings,
			)
		)
	
	for face: Face in faces:
		face.update_sister_face(faces)
	
	for sector: Sector in sectors:
		sector.update_faces(faces)
	
	for i in range(len(map_json.section7.unkArray01)):
		sound_effects.append(SFX.new(map_json.section7.unkArray01[i], self))
	
	if "unkArray02" in map_json.section7:
		sfx_zones = map_json.section7.unkArray02
	
	metadata = map_json.mapMetadataSection
	vertices_count = len(map_json.verticesSection.vertices)
	
	if "commandsSection" in map_json:
		commands_section = map_json.commandsSection
		
		for i in range(len(commands_section.allCommands)):
			commands_section.allCommands[i]["map"] = self
			commands_section.allCommands[i]["index"] = i+1
	
	if "vanilla" in map_info and map_info.name == "RAQUIA2":
		for sector: Sector in sectors:
			for face_ref: WeakRef in sector.faces:
				var face: Face = face_ref.get_ref()
				if face.v1.y > 20000:
					face.v1.y -= 65536
				if face.v2.y > 20000:
					face.v2.y -= 65536
			sector._update_vertices()


func load_das() -> void:
	das = await Das.get_das(map_info.das_info)


func unload(unload_all: bool = true) -> void:
	free.call_deferred()
	if preview_map and unload_all:
		preview_map.editable_map = null


func delete_map(p_delete_backups: bool = false) -> void:
	if FileAccess.file_exists(map_info.filepath):
		DirAccess.remove_absolute(map_info.filepath)
	if FileAccess.file_exists(map_info.filepath_json):
		DirAccess.remove_absolute(map_info.filepath_json)
	if p_delete_backups:
		var count: int = 1
		while FileAccess.file_exists(map_info.filepath + ".%d" % count):
			DirAccess.remove_absolute(map_info.filepath + ".%d" % count)
			count += 1
		count = 1
		while FileAccess.file_exists(map_info.filepath_json + ".%d" % count):
			DirAccess.remove_absolute(map_info.filepath_json + ".%d" % count)
			count += 1
	#Roth.maps.erase(self)
	map_info.map_pack.maps.erase(self)
	MapPack.save(map_info.map_pack)
	unload()


func rename_map(new_map_name: String) -> void:
	if map_info.name == new_map_name:
		return
	Console.print("Renaming map from %s to %s" % [map_info.name, new_map_name])
	var old_map_info: Dictionary = map_info.duplicate()
	
	map_info.name = new_map_name
	map_info.erase("filepath")
	map_info.erase("filepath_json")
	
	save_map()
	
	if FileAccess.file_exists(map_info.filepath) and map_info.filepath != old_map_info.filepath:
		if FileAccess.file_exists(old_map_info.filepath):
			DirAccess.remove_absolute(old_map_info.filepath)
		if FileAccess.file_exists(old_map_info.filepath_json):
			DirAccess.remove_absolute(old_map_info.filepath_json)
		var count: int = 1
		while FileAccess.file_exists(old_map_info.filepath + ".%d" % count):
			DirAccess.rename_absolute(old_map_info.filepath + ".%d" % count, map_info.filepath + ".%d" % count)
			count += 1
		count = 1
		while FileAccess.file_exists(old_map_info.filepath_json + ".%d" % count):
			DirAccess.rename_absolute(old_map_info.filepath_json + ".%d" % count, map_info.filepath_json + ".%d" % count)
			count += 1
	
	name_changed.emit(new_map_name)


func duplicate_map(new_map_name: String, map_pack: Dictionary) -> Map:
	var new_map: Map = Map.new(map_info.duplicate())
	new_map.map_info.name = new_map_name
	new_map.map_info.map_pack = map_pack
	new_map.map_info.erase("filepath")
	new_map.map_info.erase("filepath_json")
	new_map.map_info.erase("vanilla")
	new_map.map_info.erase("uuid")
	new_map.save_metadata()
	#Roth.maps.append(new_map)
	map_pack.maps.append(new_map)
	MapPack.save(map_pack)
	DirAccess.copy_absolute(map_info.filepath, new_map.map_info.filepath)
	return new_map


func create_editable_map(temp: bool = false) -> Map:
	var map := Map.new(map_info.duplicate())
	if not temp:
		map.preview_map = self
		editable_map = map
	return map


func close_map(unload_map: bool = false) -> void:
	metadata = {
		"initPosX": 0,
		"initPosZ": 0,
		"initPosY": 0,
		"rotation": 0,
		"moveSpeed": 5,
		"playerHeight": 72,
		"maxClimb": 32,
		"minFit": 48,
		"unk0x10": 2,
		"candleGlow": 8,
		"lightAmbience": 0,
		"unk0x16": 0,
		"skyTexture": 0,
		"unk0x1A": 0,
	}
	
	sectors = []
	faces = []
	objects = []
	sound_effects = []
	sfx_zones = []
	vertices_count = 0
	#map_info = {}
	commands_section = {
		"header": {
			"signature": "3u",
			"unk0x02": 0
		},
		"entryCommandIndexes": [],
		"allCommands": []
	}
	if node:
		node.queue_free()
	node = null
	editor_metadata = {}
	das = {}
	is_loaded = false
	if unload_map:
		unload()
	else:
		_reload_map_info()


func _reload_map_info() -> void:
	if "vanilla" in map_info:
		map_info.erase("command_positions")
	else:
		var file_string := FileAccess.get_file_as_string(map_info.filepath_json)
		if not file_string.is_empty():
			var file_json: Variant = JSON.parse_string(file_string)
			if file_json:
				file_json["filepath"] = map_info.filepath
				file_json["filepath_json"] = map_info.filepath_json
				for key: String in map_info:
					if key in file_json:
						map_info[key] = file_json[key]
					else:
						map_info.erase(key)
				for das_info: Dictionary in DASPack.das_packs:
					if das_info.name == file_json.das.get_basename().get_file():
						map_info.das_info = das_info


func save_map(directory: String = Roth.ROTH_CUSTOM_MAP_DIRECTORY, player_data: Dictionary = {}) -> void:
	_add_missing_map_info()
	
	var raw_map := compile(player_data)
	
	if directory == Roth.ROTH_CUSTOM_MAP_DIRECTORY:
		if FileAccess.file_exists(map_info.filepath):
			var count: int = 1
			while FileAccess.file_exists(map_info.filepath + ".%d" % count):
				count += 1
			count -= 1
			for i in range(count, 0, -1):
				DirAccess.rename_absolute(map_info.filepath + ".%d" % i, map_info.filepath + ".%d" % (i+1))
				DirAccess.rename_absolute(map_info.filepath_json + ".%d" % i, map_info.filepath_json + ".%d" % (i+1))
			
			DirAccess.rename_absolute(map_info.filepath, map_info.filepath + ".1")
			DirAccess.rename_absolute(map_info.filepath_json, map_info.filepath_json + ".1")
			
			count += 1
			while count > Settings.settings.get("options", {}).get("backup_saves", 5):
				DirAccess.remove_absolute(map_info.filepath + ".%d" % count)
				DirAccess.remove_absolute(map_info.filepath_json + ".%d" % count)
				count -= 1
				if count < 1:
					break
		
		var file := FileAccess.open(map_info.filepath, FileAccess.WRITE)
		file.store_buffer(raw_map)
		file.close()
		
		save_metadata()
		
		if preview_map:
			preview_map.close_map()
	
	else:
		var filepath: String = directory.path_join(map_info.name+".RAW")
		var file := FileAccess.open(filepath, FileAccess.WRITE)
		file.store_buffer(raw_map)
		file.close()


func _add_missing_map_info() -> void:
	if "vanilla" not in map_info:
		if "uuid" not in map_info:
			map_info["uuid"] = Utility.uuidv4()
			while FileAccess.file_exists(Roth.ROTH_CUSTOM_MAP_DIRECTORY.path_join(map_info.uuid + ".RAW")):
				map_info["uuid"] = Utility.uuidv4()
		
		if "filepath" not in map_info:
			map_info["filepath"] = Roth.ROTH_CUSTOM_MAP_DIRECTORY.path_join(map_info.uuid + ".RAW")
		
		if "filepath_json" not in map_info:
			map_info["filepath_json"] = Roth.ROTH_CUSTOM_MAP_DIRECTORY.path_join(map_info.uuid + ".json")


func save_metadata() -> void:
	
	_add_missing_map_info()
	
	var save_info: Dictionary = map_info.duplicate()
	save_info.erase("filepath")
	save_info.erase("filepath_json")
	save_info["das"] = save_info.das_info.name
	save_info.erase("das_info")
	save_info.erase("map_pack")
	save_info.erase("uuid")
	
	var json_file := FileAccess.open(map_info.filepath_json, FileAccess.WRITE)
	json_file.store_string(JSON.stringify(save_info, "\t"))
	json_file.close()


func save_map_as(new_map_name: String, map_pack: Dictionary) -> void:
	map_info.name = new_map_name
	map_info.map_pack = map_pack
	map_info.erase("filepath")
	map_info.erase("filepath_json")
	map_info.erase("vanilla")
	map_info.erase("uuid")
	save_map()
	preview_map.editable_map = null
	preview_map = Map.new(map_info.duplicate())
	preview_map.editable_map = self
	#Roth.maps.append(preview_map)
	map_pack.maps.append(preview_map)
	MapPack.save(map_pack)
	name_changed.emit(new_map_name)


func delete_sector(sector_to_delete: Sector) -> void:
	if sector_to_delete.node:
		sector_to_delete.node.queue_free()
	sectors.erase(sector_to_delete)


func add_sector(vertices: Array, sector_data: Dictionary) -> Sector:
	var initial_data := {
		"ceilingHeight": sector_data.ceiling_height,
		"floorHeight": sector_data.floor_height,
		"unk0x04": 0,
		"ceilingTextureIndex": sector_data.ceiling,
		"floorTextureIndex": sector_data.floor,
		"textureFit": sector_data.texture_fit,
		"lighting": 128,
		"textureMapOverride": 0,
		"facesCount": len(vertices),
		"ceilingTextureShiftX": 0,
		"ceilingTextureShiftY": 0,
		"floorTextureShiftX": 0,
		"floorTextureShiftY": 0,
		"floorTriggerID": 0,
		"unk0x16": 0b00010100,
		"objectInformation": [],
	}
	
	var new_sector: Sector = Sector.new(initial_data, self)
	sectors.append(new_sector)
	
	for i in range(len(vertices)):
		var v1: Vector2 = vertices[i].snappedf(2.0)
		var v2: Vector2 = vertices[(i+1)%len(vertices)].snappedf(2.0)
		
		if sector_data.auto_split_walls:
			while (v2-v1).length() > sector_data.auto_split_walls_value:
				var v2a: Vector2 = v1 + (v2-v1).normalized() * sector_data.auto_split_walls_value
				var sub_face: Face = Face.create_new_face(self, new_sector, sector_data)
				sub_face.v1 = v1
				sub_face.v2 = v2a
				sub_face.update_horizontal_fit()
				new_sector.faces.append(weakref(sub_face))
				faces.append(sub_face)
				node.get_node("Faces").add_child(sub_face.initialize_mesh())
				v1 = v2a
		
		var face: Face = Face.create_new_face(self, new_sector, sector_data)
		face.v1 = v1
		face.v2 = v2
		face.update_horizontal_fit()
		new_sector.faces.append(weakref(face))
		faces.append(face)
		node.get_node("Faces").add_child(face.initialize_mesh())
	
	new_sector._update_vertices()
	node.get_node("Sectors").add_child(new_sector.initialize_mesh())
	
	return new_sector


func add_box_sector(starting_position: Vector2, ending_position: Vector2, sector_data: Dictionary) -> Sector:
	var v2 := Vector2.ZERO
	var v4 := Vector2.ZERO
	
	if ((starting_position.x > ending_position.x and starting_position.y > ending_position.y)
		or (starting_position.x < ending_position.x and starting_position.y < ending_position.y)
	):
		v2 = Vector2(ending_position.x, starting_position.y)
		v4 = Vector2(starting_position.x, ending_position.y)
	else:
		v4 = Vector2(ending_position.x, starting_position.y)
		v2 = Vector2(starting_position.x, ending_position.y)
	
	var vertices: Array = [
		starting_position,
		v2,
		ending_position,
		v4,
	]
	var new_sector: Sector = add_sector(vertices, sector_data)
	return new_sector


func add_stairs(starting_position: Vector2, ending_position: Vector2, sector_data: Dictionary, stair_data: Dictionary) -> Array:
	var new_sectors: Array = []
	var size: Vector2i = (ending_position - starting_position).round()
	
	sector_data["lower_wall"] = sector_data.wall
	if stair_data.stepped_ceiling:
		sector_data["upper_wall"] = sector_data.wall
	
	for i in range(stair_data.steps):
		var start := Vector2.ZERO
		var end := Vector2.ZERO
		
		if stair_data.orientation == "horizontal":
			start = Vector2(starting_position.x + (size.x * (i) / stair_data.steps), starting_position.y)
			end = Vector2(starting_position.x + (size.x * (i+1) / stair_data.steps), starting_position.y+size.y)
		else:
			start = Vector2(starting_position.x, starting_position.y + (size.y * (i) / stair_data.steps))
			end = Vector2(starting_position.x + size.x, starting_position.y + (size.y * (i+1) / stair_data.steps))
		
		var sector: Sector = add_box_sector(start, end, sector_data)
		new_sectors.append(sector)
		
		sector_data.floor_height += stair_data.height
		if stair_data.stepped_ceiling:
			sector_data.ceiling_height += stair_data.height
	
	return new_sectors


func add_copied_sectors(sector_data: Array, original_data: Array) -> void:
	for i in range(len(sector_data)):
		var sector: Sector = sector_data[i]
		var new_faces: Array = []
		var sector_center := Vector2.ZERO
		var original_center := Vector2.ZERO
		var count: int = 0
		for j in range(len(sector.faces)):
			var face: Face = sector.faces[j]
			face.v1 = face.v1.snappedf(2)
			face.v2 = face.v2.snappedf(2)
			face.map = self
			faces.append(face)
			new_faces.append(weakref(face))
			node.get_node("Faces").add_child(face.initialize_mesh())
			sector_center += face.v1
			sector_center += face.v2
			original_center += original_data[i].faces[j].v1
			original_center += original_data[i].faces[j].v2
			count += 2
		sector_center /= count
		original_center /= count
		sector.faces = new_faces
		sector.map = self
		sector._update_vertices()
		var shift: Vector2 = original_center - sector_center
		sector.data.floorTextureShiftX = int((shift.x * sector.get_floor_scale() + sector.data.floorTextureShiftX)) & 0xFF
		sector.data.floorTextureShiftY = int((-shift.y * sector.get_floor_scale() + sector.data.floorTextureShiftY)) & 0xFF
		sector.data.ceilingTextureShiftX = int((shift.x * sector.get_ceiling_scale() + sector.data.ceilingTextureShiftX)) & 0xFF
		sector.data.ceilingTextureShiftY = int((-shift.y * sector.get_ceiling_scale()  + sector.data.ceilingTextureShiftY)) & 0xFF
		if sector.platform:
			sector.platform.floorTextureShiftX = int((shift.x * sector.get_floor_platform_scale() + sector.platform.floorTextureShiftX)) & 0xFF
			sector.platform.floorTextureShiftY = int((-shift.y * sector.get_floor_platform_scale() + sector.platform.floorTextureShiftY)) & 0xFF
			sector.platform.ceilingTextureShiftX = int((shift.x * sector.get_ceiling_platform_scale() + sector.platform.ceilingTextureShiftX)) & 0xFF
			sector.platform.ceilingTextureShiftY = int((-shift.y * sector.get_ceiling_platform_scale()  + sector.platform.ceilingTextureShiftY)) & 0xFF
		node.get_node("Sectors").add_child(sector.initialize_mesh())
		
		for object_data: Dictionary in sector.data.objectInformation:
			object_data.rotation = object_data.rotation & 0xFF
			var object_roth: ObjectRoth = ObjectRoth.new(object_data, self, sector)
			add_object(object_roth)
		
		sectors.append(sector)
	
	# Assign sisters
	for sector: Sector in sector_data:
		for face_ref: WeakRef in sector.faces:
			var face: Face = face_ref.get_ref()
			if face.has_copied_sister:
				for sector_sister: Sector in sector_data:
					for face_sister_ref: WeakRef in sector_sister.faces:
						var face_sister: Face = face_sister_ref.get_ref()
						if face.v2.is_equal_approx(face_sister.v1) and face.v1.is_equal_approx(face_sister.v2) and face != face_sister:
							face.sister = weakref(face_sister)
							face_sister.sister = weakref(face)
							face.initialize_mesh()
							face_sister.initialize_mesh()
	reorder_faces()


func split_sector(existing_sector: Sector, vertex_node_1: VertexNode, vertex_node_2: VertexNode) -> void:
	#Console.print("Splitting sector")
	
	var new_sector: Sector = existing_sector.duplicate()
	new_sector.data.objectInformation = []
	sectors.append(new_sector)
	
	var face_1: Face = Face.create_new_face(self, existing_sector)
	face_1.v1 = vertex_node_1.coordinate
	face_1.v2 = vertex_node_2.coordinate
	var face_2: Face = Face.create_new_face(self, new_sector)
	face_2.index += 1
	face_2.v1 = vertex_node_2.coordinate
	face_2.v2 = vertex_node_1.coordinate
	face_1.sister = weakref(face_2)
	face_2.sister = weakref(face_1)
	face_1.update_horizontal_fit()
	face_2.update_horizontal_fit()
	faces.append(face_1)
	faces.append(face_2)
	
	var existing_faces := existing_sector.faces.duplicate()
	var new_faces := []
	var split_index_1: int = -1
	var split_index_2: int = -1
	for i in range(len(existing_faces)):
		if existing_faces[i].get_ref().v1 == vertex_node_1.coordinate:
			split_index_1 = i
		if existing_faces[i].get_ref().v2 == vertex_node_2.coordinate:
			split_index_2 = i
	
	if split_index_2 > split_index_1:
		existing_sector.faces = existing_faces.slice(split_index_1, split_index_2+1)
		existing_sector.faces.append(weakref(face_2))
		new_faces.append_array(existing_faces.slice(split_index_2+1))
		new_faces.append_array(existing_faces.slice(0, split_index_1))
		new_faces.append(weakref(face_1))
	else:
		existing_sector.faces = existing_faces.slice(split_index_1)
		existing_sector.faces.append_array(existing_faces.slice(0, split_index_2+1))
		existing_sector.faces.append(weakref(face_2))
		new_faces.append_array(existing_faces.slice(split_index_2+1, split_index_1))
		new_faces.append(weakref(face_1))
	
	
	
	new_sector.faces = new_faces
	
	for face_ref: WeakRef in existing_sector.faces:
		face_ref.get_ref().sector = existing_sector
	for face_ref: WeakRef in new_sector.faces:
		face_ref.get_ref().sector = new_sector
	
	
	new_sector.reorder_faces()
	existing_sector.reorder_faces()
	existing_sector.initialize_mesh()
	node.get_node("Faces").add_child(face_1.initialize_mesh())
	node.get_node("Faces").add_child(face_2.initialize_mesh())
	node.get_node("Sectors").add_child(new_sector.initialize_mesh())
	
	for object: ObjectRoth in objects:
		if object.sector.get_ref() == existing_sector:
			if not existing_sector.is_object_inside(object):
				existing_sector.data.objectInformation.erase(object.data)
				new_sector.data.objectInformation.append(object.data)
				object.sector = weakref(new_sector)


func add_object(new_object: ObjectRoth) -> void:
	objects.append(new_object)
	var object_node_3d: Node3D = new_object.initialize_mesh()
	node.get_node("Objects").add_child(object_node_3d)


func add_sfx(new_object: SFX) -> void:
	sound_effects.append(new_object)
	var object_node_3d: Node3D = new_object.initialize_mesh()
	node.get_node("SFX").add_child(object_node_3d)


func get_sector_floor_height_from_vertex(vertex: Vector2) -> int:
	for sector: Sector in sectors:
		if Geometry2D.is_point_in_polygon(vertex, sector.vertices.slice(0,-1)):
			return sector.data.floorHeight
	return 0


func reorder_faces() -> void:
	var ordered_faces: Array = []
	for sector: Sector in sectors:
		for face_ref: WeakRef in sector.faces:
			var face: Face = face_ref.get_ref()
			ordered_faces.append(face)
	faces.clear()
	faces = ordered_faces


func get_sector_ceiling_height_from_vertex(vertex: Vector2) -> int:
	for sector: Sector in sectors:
		if Geometry2D.is_point_in_polygon(vertex, sector.vertices.slice(0,-1)):
			return sector.data.ceilingHeight
	return 0


func merge_sectors(double_sided_face: Face) -> void:
	if not double_sided_face.sister:
		#Console.print("Not a double sided face.")
		return
	#Console.print("Deleting double sided face and merging sectors.")
	
	
	var sector: Sector = double_sided_face.sector
	var sister_sector: Sector = double_sided_face.sister.get_ref().sector
	
	var new_faces := []
	for face_ref: WeakRef in sister_sector.faces:
		if face_ref.get_ref() == double_sided_face.sister.get_ref():
			face_ref.get_ref().delete()
		elif face_ref.get_ref().sister and face_ref.get_ref().sister.get_ref().sector == sector:
			face_ref.get_ref().delete()
		else:
			face_ref.get_ref().sector = sector
			new_faces.append(weakref(face_ref.get_ref()))
	
	for face_ref: WeakRef in sector.faces:
		if face_ref.get_ref() == double_sided_face:
			face_ref.get_ref().delete()
		elif face_ref.get_ref().sister and face_ref.get_ref().sister.get_ref().sector == null:
			face_ref.get_ref().delete()
		else:
			new_faces.append(weakref(face_ref.get_ref()))
	
	for object: ObjectRoth in objects:
		if object.sector.get_ref() == sister_sector:
				sister_sector.data.objectInformation.erase(object.data)
				sector.data.objectInformation.append(object.data)
				object.sector = weakref(sector)
	
	delete_sector(sister_sector)
	sector.faces = new_faces
	sector.reorder_faces()
	sector.initialize_mesh()
	for face_ref: WeakRef in sector.faces:
		var face: Face = face_ref.get_ref()
		if face.sister:
			face.sister.get_ref().initialize_mesh()
			face.sister.get_ref().update_horizontal_fit()
		face.initialize_mesh()
		face.update_horizontal_fit()


func find_concave_sectors() -> Array:
	var bad_sectors := []
	# Check for concave sectors.
	for sector: Sector in sectors:
		if not sector.is_convex():
			bad_sectors.append(sector)
	return bad_sectors


func get_texture_mappings_counts() -> Array:
	var command_52_face_ids := []
	for command: Dictionary in commands_section.allCommands:
		if command.commandBase in [46, 52]:
			if command.args[1] != 0:
				if command.args[1] not in command_52_face_ids:
					command_52_face_ids.append(command.args[1])
			else:
				var face_ids: Array = get_triggering_ids(commands_section, command.index)
				for face_id: int in face_ids:
					if face_id not in command_52_face_ids:
						command_52_face_ids.append(face_id)
	
	var texture_additional_count: int = 0
	var texture_mappings: Array = []
	for sector: Sector in sectors:
		for face_ref: WeakRef in sector.faces:
			var face: Face = face_ref.get_ref()
			if face.texture_data not in texture_mappings:
				texture_mappings.append(face.texture_data)
				if "additionalMetadata" in face.texture_data and face.texture_data.type & 128 > 0:
					texture_additional_count += 1
			else:
				# Map command 52 can't modify face flags if the texture mapping is assigned to more than one face
				var texture_mapping: Dictionary = texture_mappings[texture_mappings.find(face.texture_data)]
				if "additionalMetadata" in texture_mapping and face.texture_data.type & 128 > 0 and texture_mapping.additionalMetadata.unk0x0C in command_52_face_ids:
					texture_mappings.append(face.texture_data)
					texture_additional_count += 1
	return [len(texture_mappings), texture_additional_count]


func compile(player_data: Dictionary = {}) -> PackedByteArray:
	
	var json := {}
	json["mapMetadataSection"] = metadata.duplicate()
	json["sectorsSection"] = { "sectors": sectors.map(func (sector: Sector) -> Dictionary: return sector.data) }
	
	var compiled_faces := []
	for i in range(len(sectors)):
		var sector: Sector = sectors[i]
		sector.data["firstFaceIndex"] = len(compiled_faces)
		for face_ref: WeakRef in sector.faces:
			var face: Face = face_ref.get_ref()
			compiled_faces.append(face)
			
		sector.data["facesCount"] = len(sector.faces)
	
	var face_index: int = 0
	for face: Face in faces:
		face.compiled_index = face_index
		face_index += 1
		
	
	for i in range(len(sectors)):
		var sector: Sector = sectors[i]
		for face_ref: WeakRef in sector.faces:
			var face: Face = face_ref.get_ref()
			face.data["sectorIndex"] = i
			if face.sister:
				face.data["sisterFaceIndex"] = face.sister.get_ref().compiled_index
				assert(face.data["sisterFaceIndex"] != -1)
			else:
				face.data.erase("sisterFaceIndex")
	
	json["facesSection"] = { "faces": compiled_faces.map(func (face: Face) -> Dictionary: return face.data) }
	
	# Get a list of face ids used by map command 52
	var command_52_face_ids := []
	for command: Dictionary in commands_section.allCommands:
		if command.commandBase in [46, 52]:
			if command.args[1] != 0:
				if command.args[1] not in command_52_face_ids:
					command_52_face_ids.append(command.args[1])
			else:
				var face_ids: Array = get_triggering_ids(commands_section, command.index)
				for face_id: int in face_ids:
					if face_id not in command_52_face_ids:
						command_52_face_ids.append(face_id)
	
	var texture_mappings_map := {}
	var additional_texture_faces := []
	var texture_map_index: int = 0
	for face: Face in compiled_faces:
		if face.texture_data not in texture_mappings_map:
			texture_mappings_map[face.texture_data] = texture_map_index
			face.data["textureMappingIndex"] = texture_map_index
			texture_map_index += 1
		else:
			# Map command 52 can't modify face flags if the texture mapping is assigned to more than one face
			if "additionalMetadata" in face.texture_data and face.texture_data.additionalMetadata.unk0x0C in command_52_face_ids:
				additional_texture_faces.append(face)
			else:
				face.data["textureMappingIndex"] = texture_mappings_map[face.texture_data]
	
	var texture_mappings: Array = []
	for texture_map_data: Dictionary in texture_mappings_map:
		texture_mappings.append(texture_map_data)
	
	for face: Face in additional_texture_faces:
		texture_mappings.append(face.texture_data)
		face.data["textureMappingIndex"] = len(texture_mappings) - 1
	
	json["faceTextureMappingSection"] = { "mappings": texture_mappings }
	
	
	var platforms := []
	for sector: Sector in sectors:
		if sector.platform.is_empty():
			sector.data.erase("intermediateFloorIndex")
		else:
			platforms.append(sector.platform)
			sector.data["intermediateFloorIndex"] = len(platforms) - 1
	
	if not platforms.is_empty():
		json["midPlatformsSection"] = { "platforms": platforms }
	
	var vertices := {}
	var vertex_index: int = 0
	for face: Face in compiled_faces:
		var v1: Dictionary = {
			"x": -int(face.v1.x),
			"y": int(face.v1.y)
		}
		if v1 not in vertices:
			vertices[v1] = vertex_index
			face.data["vertexIndex01"] = vertex_index
			vertex_index += 1
		else:
			face.data["vertexIndex01"] = vertices[v1]
		var v2: Dictionary = {
			"x": -int(face.v2.x),
			"y": int(face.v2.y)
		}
		if v2 not in vertices:
			vertices[v2] = vertex_index
			face.data["vertexIndex02"] = vertex_index
			vertex_index += 1
		else:
			face.data["vertexIndex02"] = vertices[v2]
	
	var vertices_array: Array = []
	for vertex: Dictionary in vertices:
		vertices_array.append(vertex)
	json["verticesSection"] = { "vertices": vertices_array }
	
	json["commandsSection"] = commands_section
	json["section7"] = { "unkArray01": sound_effects.map(func (sfx: SFX) -> Dictionary: return sfx.data) }
	if sfx_zones:
		json["section7"]["unkArray02"] = sfx_zones
	
	
	if "position" in player_data:
		json["mapMetadataSection"]["initPosX"] = -player_data.position.x
		json["mapMetadataSection"]["initPosY"] = player_data.position.z
		json["mapMetadataSection"]["initPosZ"] = player_data.position.y
	if "rotation" in player_data:
		json["mapMetadataSection"]["rotation"] = player_data.rotation
	
	return Raw.compile(json)


class MapNode3D extends Node3D:
	var ref: Map
