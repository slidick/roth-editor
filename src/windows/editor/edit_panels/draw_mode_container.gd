extends MarginContainer

var current_das: String = ""

func _ready() -> void:
	Roth.settings_loaded.connect(_on_settings_loaded)
	%Map3D.properties_copied.connect(_on_properties_copied)


func _on_settings_loaded() -> void:
	pass


func enter_draw_mode(force_reload: bool = false) -> void:
	var texture_presets: Dictionary = Settings.settings.get("texture_presets", {})
	
	if current_das != %Map2D.map.map_info.das or force_reload:
		var current_preset: String = ""
		if force_reload:
			current_preset = %DrawModeTextureOptionButton.get_item_text(%DrawModeTextureOptionButton.get_item_index(%DrawModeTextureOptionButton.get_selected_id()))
		current_das = %Map2D.map.map_info.das
		%DrawModeTextureOptionButton.clear()
		for das: String in texture_presets:
			if %Map2D.map.map_info.das == das:
				for preset_name: String in texture_presets[das]:
					%DrawModeTextureOptionButton.add_item(preset_name)
					%DrawModeTextureOptionButton.set_item_metadata(%DrawModeTextureOptionButton.item_count-1, texture_presets[das][preset_name])
		%DrawModeTextureOptionButton.add_item("Copied Data")
		%DrawModeTextureOptionButton.add_item("Custom")
		
		if force_reload:
			for i in range(%DrawModeTextureOptionButton.item_count):
				if %DrawModeTextureOptionButton.get_item_text(i) == current_preset:
					%DrawModeTextureOptionButton.select(i)
					_on_draw_mode_texture_option_button_item_selected(i)
					break
		else:
			if %DrawModeTextureOptionButton.item_count > 0:
				_on_draw_mode_texture_option_button_item_selected(0)
	show()


func exit_draw_mode() -> void:
	hide()


func get_sector_options() -> Dictionary:
	var texture_fit: int = 0
	match %DrawModeRoofScaleOption.get_selected_id():
		0:
			texture_fit &= ~Sector.CEILING_A
			texture_fit &= ~Sector.CEILING_B
		1:
			texture_fit |= Sector.CEILING_A
			texture_fit &= ~Sector.CEILING_B
		2:
			texture_fit &= ~Sector.CEILING_A
			texture_fit |= Sector.CEILING_B
		3:
			texture_fit |= Sector.CEILING_A
			texture_fit |= Sector.CEILING_B

	match %DrawModeFloorScaleOption.get_selected_id():
		0:
			texture_fit &= ~Sector.FLOOR_A
			texture_fit &= ~Sector.FLOOR_B
		1:
			texture_fit |= Sector.FLOOR_A
			texture_fit &= ~Sector.FLOOR_B
		2:
			texture_fit &= ~Sector.FLOOR_A
			texture_fit |= Sector.FLOOR_B
		3:
			texture_fit |= Sector.FLOOR_A
			texture_fit |= Sector.FLOOR_B
	
	
	return {
		"ceiling": %DrawModeRoofOption.get_selected_metadata(),
		"floor": %DrawModeFloorOption.get_selected_metadata(),
		"wall": %DrawModeWallOption.get_selected_metadata(),
		"texture_fit": texture_fit,
		"ceiling_height": %DrawModeRoofHeightSpinBox.value,
		"floor_height": %DrawModeFloorHeightSpinBox.value,
	}


func _on_properties_copied() -> void:
	var index: int = %DrawModeTextureOptionButton.get_item_index(%DrawModeTextureOptionButton.get_selected_id())
	if index != %DrawModeTextureOptionButton.item_count-2:
		return
	_on_draw_mode_texture_option_button_item_selected(index)


func _on_draw_mode_texture_option_button_item_selected(index: int) -> void:
	var texture_data: Dictionary = {}
	%DrawModeRoofOption.disabled = true
	%DrawModeFloorOption.disabled = true
	%DrawModeWallOption.disabled = true
	%DrawModeEditTexturePresetsButton.text = "Edit"
	if index == %DrawModeTextureOptionButton.item_count-1:
		%DrawModeRoofOption.disabled = false
		%DrawModeFloorOption.disabled = false
		%DrawModeWallOption.disabled = false
		%DrawModeEditTexturePresetsButton.text = "Create"
		return
	elif index == %DrawModeTextureOptionButton.item_count-2:
		%DrawModeEditTexturePresetsButton.text = "Create"
		texture_data = {
			"ceiling": %Map3D.copied_sector_data.get("ceilingTextureIndex", 65535),
			"floor": %Map3D.copied_sector_data.get("floorTextureIndex", 65535),
			"wall": %Map3D.copied_face_texture_data.get("midTextureIndex", 65535),
		}
	else:
		texture_data = %DrawModeTextureOptionButton.get_selected_metadata()
	
	update_texture_options(texture_data)


func update_texture_options(texture_data: Dictionary) -> void:
	var das := await Roth.get_das(%Map2D.map.map_info.das)
	%DrawModeRoofOption.clear()
	if texture_data.ceiling in das.mapping:
		%DrawModeRoofOption.add_item( "%s:%s" % [das.mapping[texture_data.ceiling].index, das.mapping[texture_data.ceiling].name] )
		%DrawModeRoofOption.set_item_metadata(%DrawModeRoofOption.item_count-1, das.mapping[texture_data.ceiling].index)
	else:
		%DrawModeRoofOption.add_item( "%d" % texture_data.ceiling )
		%DrawModeRoofOption.set_item_metadata(%DrawModeRoofOption.item_count-1, texture_data.ceiling)
	%DrawModeRoofOption.add_item("Sky")
	%DrawModeRoofOption.add_item("Select Texture")
	%DrawModeRoofOption.add_item("Select Palette")
	%DrawModeFloorOption.clear()
	if texture_data.floor in das.mapping:
		%DrawModeFloorOption.add_item( "%s:%s" % [das.mapping[texture_data.floor].index, das.mapping[texture_data.floor].name] )
		%DrawModeFloorOption.set_item_metadata(%DrawModeFloorOption.item_count-1, das.mapping[texture_data.floor].index)
	else:
		%DrawModeFloorOption.add_item("%s" % texture_data.floor)
		%DrawModeFloorOption.set_item_metadata(%DrawModeFloorOption.item_count-1, texture_data.floor)
	%DrawModeFloorOption.add_item("Sky")
	%DrawModeFloorOption.add_item("Select Texture")
	%DrawModeFloorOption.add_item("Select Palette")
	%DrawModeWallOption.clear()
	if texture_data.wall in das.mapping:
		%DrawModeWallOption.add_item( "%s:%s" % [das.mapping[texture_data.wall].index, das.mapping[texture_data.wall].name] )
		%DrawModeWallOption.set_item_metadata(%DrawModeWallOption.item_count-1, das.mapping[texture_data.wall].index)
	else:
		%DrawModeWallOption.add_item("%s" % texture_data.wall)
		%DrawModeWallOption.set_item_metadata(%DrawModeWallOption.item_count-1, texture_data.wall)
	%DrawModeWallOption.add_item("Sky")
	%DrawModeWallOption.add_item("Select Texture")
	%DrawModeWallOption.add_item("Select Palette")


func _on_draw_mode_adjust_ceiling_height_button_pressed() -> void:
	var das := await Roth.get_das(%Map2D.map.map_info.das)
	var index: int = %DrawModeWallOption.get_selected_metadata()
	%DrawModeRoofHeightSpinBox.set_value_no_signal(%DrawModeFloorHeightSpinBox.value + (das.mapping[index].width * 2))


func _on_draw_mode_edit_texture_presets_button_pressed() -> void:
	var selected_preset: String = %DrawModeTextureOptionButton.get_item_text(%DrawModeTextureOptionButton.get_item_index(%DrawModeTextureOptionButton.get_selected_id()))
	
	var texture_data: Dictionary = {}
	if selected_preset == "Copied Data":
		texture_data = {
			"ceiling": %Map3D.copied_sector_data.get("ceilingTextureIndex", 65535),
			"floor": %Map3D.copied_sector_data.get("floorTextureIndex", 65535),
			"wall": %Map3D.copied_face_texture_data.get("midTextureIndex", 65535),
		}
	elif selected_preset == "Custom":
		texture_data = {
			"ceiling": %DrawModeRoofOption.get_selected_metadata(),
			"floor": %DrawModeFloorOption.get_selected_metadata(),
			"wall": %DrawModeWallOption.get_selected_metadata(),
		}
	var selected_key: Variant = await %TexturePresets.edit_presets(%Map2D.map.map_info.das, selected_preset, texture_data)
	enter_draw_mode(true)
	if selected_key is int:
		return
	if selected_key.is_empty():
		%DrawModeTextureOptionButton.select(0)
		_on_draw_mode_texture_option_button_item_selected(0)
	else:
		for i in range(%DrawModeTextureOptionButton.item_count):
			if %DrawModeTextureOptionButton.get_item_text(i) == selected_key:
				%DrawModeTextureOptionButton.select(i)
				_on_draw_mode_texture_option_button_item_selected(i)


func _on_draw_mode_roof_option_item_selected(index: int) -> void:
	if index == %DrawModeRoofOption.item_count - 1:
		var das: Dictionary = await Roth.get_das(%Map2D.map.map_info.das)
		%Palette.show_palette(das.palette)
		var palette_index: int = await %Palette.color_selected
		%DrawModeRoofOption.select(0)
		if palette_index < 0:
			return
		update_texture_options({"ceiling": palette_index + 65280, "floor": %DrawModeFloorOption.get_item_metadata(0), "wall": %DrawModeWallOption.get_item_metadata(0)})
	elif index == %DrawModeRoofOption.item_count - 2:
		var das: Dictionary = await Roth.get_das(%Map2D.map.map_info.das)
		%Texture.show_texture(das, true)
		var texture_index: int = await %Texture.texture_selected
		%DrawModeRoofOption.select(0)
		if texture_index < 0:
			return
		update_texture_options({"ceiling": texture_index, "floor": %DrawModeFloorOption.get_item_metadata(0), "wall": %DrawModeWallOption.get_item_metadata(0)})
	elif index == %DrawModeRoofOption.item_count - 3:
		%DrawModeRoofOption.select(0)
		update_texture_options({"ceiling": %Map2D.map.metadata.skyTexture, "floor": %DrawModeFloorOption.get_item_metadata(0), "wall": %DrawModeWallOption.get_item_metadata(0)})


func _on_draw_mode_floor_option_item_selected(index: int) -> void:
	if index == %DrawModeFloorOption.item_count - 1:
		var das: Dictionary = await Roth.get_das(%Map2D.map.map_info.das)
		%Palette.show_palette(das.palette)
		var palette_index: int = await %Palette.color_selected
		%DrawModeFloorOption.select(0)
		if palette_index < 0:
			return
		update_texture_options({"floor": palette_index + 65280, "ceiling": %DrawModeRoofOption.get_item_metadata(0), "wall": %DrawModeWallOption.get_item_metadata(0)})
	elif index == %DrawModeFloorOption.item_count - 2:
		var das: Dictionary = await Roth.get_das(%Map2D.map.map_info.das)
		%Texture.show_texture(das, true)
		var texture_index: int = await %Texture.texture_selected
		%DrawModeFloorOption.select(0)
		if texture_index < 0:
			return
		update_texture_options({"floor": texture_index, "ceiling": %DrawModeRoofOption.get_item_metadata(0), "wall": %DrawModeWallOption.get_item_metadata(0)})
	elif index == %DrawModeFloorOption.item_count - 3:
		%DrawModeFloorOption.select(0)
		update_texture_options({"floor": %Map2D.map.metadata.skyTexture, "ceiling": %DrawModeRoofOption.get_item_metadata(0), "wall": %DrawModeWallOption.get_item_metadata(0)})


func _on_draw_mode_wall_option_item_selected(index: int) -> void:
	if index == %DrawModeWallOption.item_count - 1:
		var das: Dictionary = await Roth.get_das(%Map2D.map.map_info.das)
		%Palette.show_palette(das.palette)
		var palette_index: int = await %Palette.color_selected
		%DrawModeWallOption.select(0)
		if palette_index < 0:
			return
		update_texture_options({"wall": palette_index + 65280, "ceiling": %DrawModeRoofOption.get_item_metadata(0), "floor": %DrawModeFloorOption.get_item_metadata(0)})
	elif index == %DrawModeWallOption.item_count - 2:
		var das: Dictionary = await Roth.get_das(%Map2D.map.map_info.das)
		%Texture.show_texture(das, false)
		var texture_index: int = await %Texture.texture_selected
		%DrawModeWallOption.select(0)
		if texture_index < 0:
			return
		update_texture_options({"wall": texture_index, "ceiling": %DrawModeRoofOption.get_item_metadata(0), "floor": %DrawModeFloorOption.get_item_metadata(0)})
	elif index == %DrawModeWallOption.item_count - 3:
		%DrawModeWallOption.select(0)
		update_texture_options({"wall": %Map2D.map.metadata.skyTexture, "ceiling": %DrawModeRoofOption.get_item_metadata(0), "floor": %DrawModeFloorOption.get_item_metadata(0)})
