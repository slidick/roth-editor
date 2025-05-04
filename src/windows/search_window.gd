extends BaseWindow

signal search_result_activated(search_result: Dictionary)

const FIELDS: Array = [
	"SectorData",
	"ceilingHeight",
	"floorHeight",
	"unk0x04",
	"ceilingTextureIndex",
	"floorTextureIndex",
	"textureFit",
	"lighting",
	"textureMapOverride",
	"facesCount",
	"firstFaceIndex",
	"ceilingTextureShiftX",
	"ceilingTextureShiftY",
	"floorTextureShiftX",
	"floorTextureShiftY",
	"floorTriggerID",
	"unk0x16",
	"FaceData",
	"vertexIndex01",
	"vertexIndex02",
	"textureMappingIndex",
	"sectorIndex",
	"sisterFaceIndex",
	"addCollision",
	"TextureMappingData",
	"unk0x00",
	"type",
	"midTextureIndex",
	"upperTextureIndex",
	"lowerTextureIndex",
	"unk0x08",
	"shiftTextureX",
	"shiftTextureY",
	"unk0x0C",
	"ObjectData",
	"posX",
	"posY",
	"textureIndex",
	"textureSource",
	"rotation",
	"unk0x07",
	"lighting_obj",
	"renderType",
	"posZ",
	"unk0x0C_obj",
	"unk0x0E_obj",
	"SFXData",
	"unk0x00_snd",
	"unk0x02_snd",
	"unk0x04_snd",
	"unk0x06_snd",
	"unk0x08_snd",
	"unk0x10_snd",
	"unk0x0A_snd",
	"unk0x0C_snd",
	"unk0x0E_snd",
]


func _ready() -> void:
	super._ready()
	Roth.settings_loaded.connect(_on_settings_loaded)
	for field: String in FIELDS:
		if field.ends_with("Data"):
			%FieldsOption.add_separator(field.replace("Data", ""))
		else:
			%FieldsOption.add_item(field)


func _on_settings_loaded() -> void:
	%MapsOption.clear()
	var index: int = 0
	%MapsOption.add_item("All Maps")
	%MapsOption.set_item_metadata(index, {"name": "All Maps"})
	for map_info: Dictionary in Roth.maps:
		index += 1
		%MapsOption.add_item(map_info.name)
		%MapsOption.set_item_metadata(index, map_info)


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
	
	var search_map: Dictionary = %MapsOption.get_selected_metadata()
	var sectors := []
	var faces := []
	var objects := []
	var sfx := []
	if search_map.name == "All Maps":
		for map_info:Dictionary in Roth.maps:
			sectors.append_array(Roth.get_map(map_info).sectors)
			faces.append_array(Roth.get_map(map_info).faces)
			objects.append_array(Roth.get_map(map_info).objects)
			sfx.append_array(Roth.get_map(map_info).sound_effects)
			
	else:
		sectors = Roth.get_map(search_map).sectors
		faces = Roth.get_map(search_map).faces
		objects = Roth.get_map(search_map).objects
		sfx = Roth.get_map(search_map).sound_effects
		
	
	var search_field: String = %FieldsOption.text
	var operator: String = %OperatorOption.text
	
	
	var results := []
	
	if (
			search_field == "ceilingHeight"
			or search_field == "floorHeight"
			or search_field == "unk0x04"
			or search_field == "ceilingTextureIndex"
			or search_field == "floorTextureIndex"
			or search_field == "textureFit"
			or search_field == "lighting"
			or search_field == "textureMapOverride"
			or search_field == "facesCount"
			or search_field == "firstFaceIndex"
			or search_field == "ceilingTextureShiftX"
			or search_field == "ceilingTextureShiftY"
			or search_field == "floorTextureShiftX"
			or search_field == "floorTextureShiftY"
			or search_field == "floorTriggerID"
			or search_field == "unk0x16"
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
			or search_field == "addCollision"
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
			or search_field == "unk0x08"
			or search_field == "shiftTextureX"
			or search_field == "shiftTextureY"
			or search_field == "unk0x0C"
			
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
			or search_field == "unk0x07"
			or search_field == "lighting_obj"
			or search_field == "renderType"
			or search_field == "posZ"
			or search_field == "unk0x0C_obj"
			or search_field == "unk0x0E_obj"
			
	):
		search_field = search_field.trim_suffix("_obj")
		for object: ObjectRoth in objects:
			if compare(int(object.data[search_field]), search_value, operator):
				results.append({"type": "Object", "value": object})
	
	elif (
			search_field == "unk0x00_snd"
			or search_field == "unk0x02_snd"
			or search_field == "unk0x04_snd"
			or search_field == "unk0x06_snd"
			or search_field == "unk0x08_snd"
			or search_field == "unk0x10_snd"
			or search_field == "unk0x0A_snd"
			or search_field == "unk0x0C_snd"
			or search_field == "unk0x0E_snd"
	):
		search_field = search_field.trim_suffix("_snd")
		for sound: Section7_1 in sfx:
			if compare(int(sound.data[search_field]), search_value, operator):
				results.append({"type": "SFX", "value": sound})
	
	
	if results:
		%ResultsList.grab_focus()
		for result: Dictionary in results:
			var index: int  = %ResultsList.add_item("%s -- %s: %s" % [result.value.map_info.name, result.type, result.value.index])
			%ResultsList.set_item_metadata(index, {"map_info": result.value.map_info, "type": result.type, "index": result.value.index})
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
