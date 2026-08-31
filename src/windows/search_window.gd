extends BaseWindow

signal search_result_activated(search_result: Dictionary)

const FIELDS: Array = [
	"SectorData",
	"ceilingHeight",
	"floorHeight",
	"unk0x04",
	"ceilingTextureIndex",
	"floorTextureIndex",
	"sectorFlags",
	"lighting",
	"textureMapOverride",
	"facesCount",
	"firstFaceIndex",
	"ceilingTextureShiftX",
	"ceilingTextureShiftY",
	"floorTextureShiftX",
	"floorTextureShiftY",
	"sectorID",
	"additionalSectorFlags",
	"FaceData",
	"vertexIndex01",
	"vertexIndex02",
	"textureMappingIndex",
	"sectorIndex",
	"sisterFaceIndex",
	"faceFlags",
	"TextureMappingData",
	"unk0x00",
	"type",
	"midTextureIndex",
	"upperTextureIndex",
	"lowerTextureIndex",
	"textureFlags",
	"shiftTextureX",
	"shiftTextureY",
	"faceID",
	"ObjectData",
	"posX",
	"posY",
	"textureIndex",
	"textureSource",
	"rotation",
	"flags_obj",
	"lighting_obj",
	"renderType",
	"posZ",
	"unk0x0C_obj",
	"objectID",
	"SFXData",
	"posX_snd",
	"posY_snd",
	"sfxIndex",
	"sfxID",
	"flags_snd",
	"zoneIndex_snd",
	"audibleRadius",
	"loopDelay",
	"volume_snd",
	"unk0x11_snd",
	"CommandData",
	"commandBase",
	"commandModifier",
]


func _ready() -> void:
	super._ready()
	Roth.settings_updated.connect(_on_settings_updated)
	for field: String in FIELDS:
		if field.ends_with("Data"):
			%FieldsOption.add_separator(field.replace("Data", ""))
		else:
			%FieldsOption.add_item(field)


func _on_settings_updated() -> void:
	%MapsOption.clear()
	var index: int = 0
	%MapsOption.add_item("All Maps")
	%MapsOption.set_item_metadata(index, {"name": "All Maps"})
	for map_pack: Dictionary in MapPack.map_packs:
		for map: Map in map_pack.maps:
	#for map: Map in Roth.maps:
			index += 1
			%MapsOption.add_item(map.map_info.name)
			%MapsOption.set_item_metadata(index, map)


func search() -> void:
	%ResultsList.clear()
	
	var search_string: String = %SearchValue.text.to_lower()
	if search_string.begins_with("0b"):
		search_string = str(search_string.bin_to_int())
	if search_string.begins_with("0x"):
		search_string = str(search_string.hex_to_int())
	
	if not search_string.is_valid_int():
		%ResultsList.add_item("Search value must be an integer; decimal, hex, or binary.")
		return
	
	var search_value := int(search_string)
	
	
	var sectors := []
	var faces := []
	var objects := []
	var sfx := []
	var commands := []
	if %MapsOption.get_item_index(%MapsOption.get_selected_id()) == 0:
		for map_pack: Dictionary in MapPack.map_packs:
			for map: Map in map_pack.maps:
		#for map: Map in Roth.maps:
				map.load_map()
				sectors.append_array(map.sectors)
				faces.append_array(map.faces)
				objects.append_array(map.objects)
				sfx.append_array(map.sound_effects)
				commands.append_array(map.commands_section.allCommands)
	else:
		var map: Map = %MapsOption.get_selected_metadata()
		sectors = map.sectors
		faces = map.faces
		objects = map.objects
		sfx = map.sound_effects
		commands = map.commands_section.allCommands
		
	
	var search_field: String = %FieldsOption.text
	var operator: String = %OperatorOption.text
	
	
	var results := []
	
	if (
			search_field == "ceilingHeight"
			or search_field == "floorHeight"
			or search_field == "unk0x04"
			or search_field == "ceilingTextureIndex"
			or search_field == "floorTextureIndex"
			or search_field == "sectorFlags"
			or search_field == "lighting"
			or search_field == "textureMapOverride"
			or search_field == "facesCount"
			or search_field == "firstFaceIndex"
			or search_field == "ceilingTextureShiftX"
			or search_field == "ceilingTextureShiftY"
			or search_field == "floorTextureShiftX"
			or search_field == "floorTextureShiftY"
			or search_field == "sectorID"
			or search_field == "additionalSectorFlags"
	):
		for sector: Sector in sectors:
			if compare(int(sector.data[search_field]), search_value, operator):
				results.append({"type": "Sector", "value": sector})
	
	elif (
			search_field == "vertexIndex01"
			or search_field == "vertexIndex02"
			or search_field == "textureMappingIndex"
			or search_field == "sectorIndex"
			or search_field == "sisterFaceIndex"
			or search_field == "faceFlags"
	):
		for face: Face in faces:
			if compare(int(face.data[search_field]), search_value, operator):
				results.append({"type": "Face", "value": face})
	
	elif (
			search_field == "unk0x00"
			or search_field == "type"
			or search_field == "midTextureIndex"
			or search_field == "upperTextureIndex"
			or search_field == "lowerTextureIndex"
			or search_field == "textureFlags"
			or search_field == "shiftTextureX"
			or search_field == "shiftTextureY"
			or search_field == "faceID"
			
	):
		for face: Face in faces:
			if compare(int(face.texture_data[search_field]), search_value, operator):
				results.append({"type": "Face", "value": face})
	
	elif (
			search_field == "posX"
			or search_field == "posY"
			or search_field == "textureIndex"
			or search_field == "textureSource"
			or search_field == "rotation"
			or search_field == "flags_obj"
			or search_field == "lighting_obj"
			or search_field == "renderType"
			or search_field == "posZ"
			or search_field == "unk0x0C_obj"
			or search_field == "objectID"
			
	):
		search_field = search_field.trim_suffix("_obj")
		for object: ObjectRoth in objects:
			if compare(int(object.data[search_field]), search_value, operator):
				results.append({"type": "Object", "value": object})
	
	elif (
			search_field == "posX_snd"
			or search_field == "posY_snd"
			or search_field == "sfxIndex"
			or search_field == "sfxID"
			or search_field == "flags_snd"
			or search_field == "zoneIndex_snd"
			or search_field == "audibleRadius"
			or search_field == "loopDelay"
			or search_field == "volume_snd"
			or search_field == "unk0x11_snd"
	):
		search_field = search_field.trim_suffix("_snd")
		for sound: SFX in sfx:
			if compare(int(sound.data[search_field]), search_value, operator):
				results.append({"type": "SFX", "value": sound})
	elif (
			search_field == "commandBase"
			or search_field == "commandModifier"
	):
		for command: Dictionary in commands:
			if compare(int(command[search_field]), search_value, operator):
				results.append({"type": "Command", "value": command})
	
	
	if results:
		%ResultsList.grab_focus()
		for result: Dictionary in results:
			var index: int  = %ResultsList.add_item("%s -- %s: %s" % [result.value.map.map_info.name, result.type, result.value.index])
			%ResultsList.set_item_metadata(index, {"map": result.value.map, "type": result.type, "index": result.value.index})
	else:
		%ResultsList.add_item("No results.")
		# Quirk Fix: Needed to allow reediting of search value when pressing enter and no results.
		await get_tree().process_frame
		
		%SearchValue.edit()


func compare(first_term: int, second_term: int, operator: String) -> bool:
	match operator:
		"==":
			if first_term == second_term:
				return true
		"!=":
			if first_term != second_term:
				return true
		">":
			if first_term > second_term:
				return true
		">=":
			if first_term >= second_term:
				return true
		"<":
			if first_term < second_term:
				return true
		"<=":
			if first_term <= second_term:
				return true
		"&":
			if (int(first_term) & int(second_term)) > 0:
				return true
	
	return false


func _on_search_button_pressed() -> void:
	search()


func _on_search_value_text_submitted(_new_text: String) -> void:
	search()


func _on_results_list_item_activated(index: int) -> void:
	var metadata: Variant = %ResultsList.get_item_metadata(index)
	if metadata:
		search_result_activated.emit(metadata)
		_hide()
