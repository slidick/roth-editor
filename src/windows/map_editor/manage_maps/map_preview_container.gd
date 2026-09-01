extends VBoxContainer



func clear() -> void:
	%Map.clear()
	%Sectors.text = ""
	%Faces.text = ""
	%Vertices.text = ""
	%Objects.text = ""
	%MapName.text = ""
	%DASFile.text = ""
	%Commands.text = ""
	%UUID.text = ""
	%ChangeDASButton.hide()
	%UUID.hide()
	%UUIDLabel.hide()
	%Modified.hide()
	%ModifiedLabel.hide()


func setup(map: Map, is_restore: bool = false) -> void:
	var map_preview: Dictionary = map.get_map_preview()
	if map_preview.is_empty():
		return
	%Map.setup(map_preview.faces)
	
	%Sectors.text = "%d" % map_preview.sector_count
	%Faces.text = "%d" % len(map_preview.faces)
	%Vertices.text = "%d" % map_preview.vertices_count
	%Objects.text = "%d" % map_preview.objects_count
	%MapName.text = "%s" % map.map_info.name
	%DASFile.text = "%s" % map.map_info.das_info.name
	%Commands.text = "%d" % map_preview.commands_count
	if "uuid" in map.map_info:
		%UUID.text = "%s" % map.map_info.uuid
		%UUID.tooltip_text = "%s" % map.map_info.uuid
		%UUID.show()
		%UUIDLabel.show()
	else:
		%UUID.hide()
		%UUIDLabel.hide()
	
	if "modified_time" in map.map_info:
		%Modified.text = Time.get_datetime_string_from_unix_time(map.map_info.modified_time + Time.get_time_zone_from_system().bias*60, true)+" "+Time.get_time_zone_from_system().name
		%Modified.show()
		%ModifiedLabel.show()
	else:
		%Modified.hide()
		%ModifiedLabel.hide()
	
	if "vanilla" in map.map_info:
		%ChangeDASButton.hide()
	else:
		%ChangeDASButton.show()
	
	if is_restore:
		%ChangeDASButton.hide()


func _on_change_das_button_pressed() -> void:
	owner._on_change_das_button_pressed()

func set_das_name(new_name: String) -> void:
	%DASFile.text = new_name
