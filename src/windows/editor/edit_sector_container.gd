extends MarginContainer

var current_sector: Sector


func _reset_edit_sector() -> void:
	%SectorIndexLabel.text = ""
	%SelectFacesPopupMenu.clear()
	%RoofHeightEdit.get_line_edit().clear()
	%RoofScaleOption.select(1)
	%FloorHeightEdit.get_line_edit().clear()
	%FloorScaleOption.select(1)
	%GlowEdit.get_line_edit().clear()
	%FloorTriggerIDEdit.get_line_edit().clear()
	%CandleCheckBox.set_pressed_no_signal(false)
	%Unk0x04Edit.get_line_edit().clear()
	%LightningCheckBox.set_pressed_no_signal(false)
	%TextureHeightOverrideEdit.get_line_edit().clear()
	%RoofTextureOption.clear()
	%RoofOffsetXEdit.get_line_edit().clear()
	%RoofOffsetYEdit.get_line_edit().clear()
	%FloorTextureOption.clear()
	%FloorOffsetXEdit.get_line_edit().clear()
	%FloorOffsetYEdit.get_line_edit().clear()
	%RoofFlipXCheckBox.set_pressed_no_signal(false)
	%RoofFlipYCheckBox.set_pressed_no_signal(false)
	%FloorFlipXCheckBox.set_pressed_no_signal(false)
	%FloorFlipYCheckBox.set_pressed_no_signal(false)
	%EditSectorContainer.show()
	
	%PlatformCheckButton.set_pressed_no_signal(false)
	%PlatformFloorHeightEdit.get_line_edit().clear()
	%PlatformFloorScaleOption.select(1)
	%PlatformRoofHeightEdit.get_line_edit().clear()
	%PlatformRoofScaleOption.select(1)
	%PlatformRoofTextureOption.clear()
	%PlatformRoofOffsetXEdit.get_line_edit().clear()
	%PlatformRoofOffsetYEdit.get_line_edit().clear()
	%PlatformFloorTextureOption.clear()
	%PlatformFloorOffsetXEdit.get_line_edit().clear()
	%PlatformFloorOffsetYEdit.get_line_edit().clear()


func load_edit_sector(p_sector: Sector) -> void:
	_reset_edit_sector()
	current_sector = p_sector
	%SectorIndexLabel.text = "Sector: %d" % current_sector.index
	var i: int = 0
	for face_ref: WeakRef in current_sector.faces:
		var face: Face = face_ref.get_ref()
		%SelectFacesPopupMenu.add_item("%d" % face.index)
		%SelectFacesPopupMenu.set_item_metadata(i, face.node)
		i += 1
	%RoofHeightEdit.get_line_edit().text = "%d" % current_sector.data.ceilingHeight
	%RoofHeightEdit.set_value_no_signal(current_sector.data.ceilingHeight)
	var roof_a: int = current_sector.data.textureFit & Sector.CEILING_A > 0
	var roof_b: int = current_sector.data.textureFit & Sector.CEILING_B > 0
	if roof_a == 0 and roof_b == 0:
		%RoofScaleOption.select(0)
	elif roof_a == 1 and roof_b == 0:
		%RoofScaleOption.select(1)
	elif roof_a == 0 and roof_b == 1:
		%RoofScaleOption.select(2)
	elif roof_a == 1 and roof_b == 1:
		%RoofScaleOption.select(3)
	
	%FloorHeightEdit.get_line_edit().text = "%d" % current_sector.data.floorHeight
	%FloorHeightEdit.set_value_no_signal(current_sector.data.floorHeight)
	var floor_a: int = current_sector.data.textureFit & Sector.FLOOR_A > 0
	var floor_b: int = current_sector.data.textureFit & Sector.FLOOR_B > 0
	if floor_a == 0 and floor_b == 0:
		%FloorScaleOption.select(0)
	elif floor_a == 1 and floor_b == 0:
		%FloorScaleOption.select(1)
	elif floor_a == 0 and floor_b == 1:
		%FloorScaleOption.select(2)
	elif floor_a == 1 and floor_b == 1:
		%FloorScaleOption.select(3)
	
	%GlowEdit.get_line_edit().text = "%d" % current_sector.data.lighting
	%GlowEdit.set_value_no_signal(current_sector.data.lighting)
	
	%FloorTriggerIDEdit.get_line_edit().text = "%d" % current_sector.data.floorTriggerID
	%FloorTriggerIDEdit.set_value_no_signal(current_sector.data.floorTriggerID)
	
	if current_sector.data.textureFit & Sector.CANDLE > 0:
		%CandleCheckBox.set_pressed_no_signal(true)
	
	%Unk0x04Edit.get_line_edit().text = "%d" % current_sector.data.unk0x04
	%Unk0x04Edit.set_value_no_signal(current_sector.data.unk0x04)
	
	if current_sector.data.textureFit & Sector.LIGHTNING > 0:
		%LightningCheckBox.set_pressed_no_signal(true)
	
	%TextureHeightOverrideEdit.get_line_edit().text = "%d" % current_sector.data.textureMapOverride
	%TextureHeightOverrideEdit.set_value_no_signal(current_sector.data.textureMapOverride)
	
	%RoofOffsetXEdit.get_line_edit().text = "%d" % current_sector.data.ceilingTextureShiftX
	%RoofOffsetXEdit.set_value_no_signal(current_sector.data.ceilingTextureShiftX)
	%RoofOffsetYEdit.get_line_edit().text = "%d" % current_sector.data.ceilingTextureShiftY
	%RoofOffsetYEdit.set_value_no_signal(current_sector.data.ceilingTextureShiftY)
	%FloorOffsetXEdit.get_line_edit().text = "%d" % current_sector.data.floorTextureShiftX
	%FloorOffsetXEdit.set_value_no_signal(current_sector.data.floorTextureShiftX)
	%FloorOffsetYEdit.get_line_edit().text = "%d" % current_sector.data.floorTextureShiftY
	%FloorOffsetYEdit.set_value_no_signal(current_sector.data.floorTextureShiftY)
	
	if current_sector.data.unk0x16 & Sector.CEILING_FLIP_X > 0:
		%RoofFlipXCheckBox.set_pressed_no_signal(true)
	if current_sector.data.unk0x16 & Sector.CEILING_FLIP_Y > 0:
		%RoofFlipYCheckBox.set_pressed_no_signal(true)
	if current_sector.data.unk0x16 & Sector.FLOOR_FLIP_X > 0:
		%FloorFlipXCheckBox.set_pressed_no_signal(true)
	if current_sector.data.unk0x16 & Sector.FLOOR_FLIP_Y > 0:
		%FloorFlipYCheckBox.set_pressed_no_signal(true)
	
	
	var das := await Roth.get_das(current_sector.map_info.das)
	if current_sector.data.ceilingTextureIndex in das.mapping:
		%RoofTextureOption.add_item( "%s:%s" % [das.mapping[current_sector.data.ceilingTextureIndex].index, das.mapping[current_sector.data.ceilingTextureIndex].name] )
	else:
		%RoofTextureOption.add_item( "%d" % current_sector.data.ceilingTextureIndex )
	if current_sector.data.floorTextureIndex in das.mapping:
		%FloorTextureOption.add_item( "%s:%s" % [das.mapping[current_sector.data.floorTextureIndex].index, das.mapping[current_sector.data.floorTextureIndex].name] )
	else:
		%FloorTextureOption.add_item( "%d" % current_sector.data.floorTextureIndex )
	
	%RoofTextureOption.add_item("--------")
	%RoofTextureOption.add_item("Sky")
	%RoofTextureOption.add_item("Select Texture")
	%RoofTextureOption.add_item("Select Palette")
	%FloorTextureOption.add_item("--------")
	%FloorTextureOption.add_item("Sky")
	%FloorTextureOption.add_item("Select Texture")
	%FloorTextureOption.add_item("Select Palette")
	
	
	if current_sector.platform:
		%PlatformCheckButton.set_pressed_no_signal(true)
		%PlatformContainer.show()
	
		%PlatformFloorHeightEdit.get_line_edit().text = "%d" % current_sector.platform.floorHeight
		%PlatformFloorHeightEdit.set_value_no_signal(current_sector.platform.floorHeight)
		
		%PlatformRoofHeightEdit.get_line_edit().text = "%d" % current_sector.platform.ceilingHeight
		%PlatformRoofHeightEdit.set_value_no_signal(current_sector.platform.ceilingHeight)
		
		var platform_floor_a: int = current_sector.platform.floorTextureScale & Sector.FLOOR_A > 0
		var platform_floor_b: int = current_sector.platform.floorTextureScale & Sector.FLOOR_B > 0
		if platform_floor_a == 0 and platform_floor_b == 0:
			%PlatformFloorScaleOption.select(0)
		elif platform_floor_a == 1 and platform_floor_b == 0:
			%PlatformFloorScaleOption.select(1)
		elif platform_floor_a == 0 and platform_floor_b == 1:
			%PlatformFloorScaleOption.select(2)
		elif platform_floor_a == 1 and platform_floor_b == 1:
			%PlatformFloorScaleOption.select(3)
		
		var platform_ceiling_a: int = current_sector.platform.floorTextureScale & Sector.CEILING_A > 0
		var platform_ceiling_b: int = current_sector.platform.floorTextureScale & Sector.CEILING_B > 0
		if platform_ceiling_a == 0 and platform_ceiling_b == 0:
			%PlatformRoofScaleOption.select(0)
		elif platform_ceiling_a == 1 and platform_ceiling_b == 0:
			%PlatformRoofScaleOption.select(1)
		elif platform_ceiling_a == 0 and platform_ceiling_b == 1:
			%PlatformRoofScaleOption.select(2)
		elif platform_ceiling_a == 1 and platform_ceiling_b == 1:
			%PlatformRoofScaleOption.select(3)
		
		
		%PlatformRoofOffsetXEdit.get_line_edit().text = "%d" % current_sector.platform.ceilingTextureShiftX
		%PlatformRoofOffsetXEdit.set_value_no_signal(current_sector.platform.ceilingTextureShiftX)
		%PlatformRoofOffsetYEdit.get_line_edit().text = "%d" % current_sector.platform.ceilingTextureShiftY
		%PlatformRoofOffsetYEdit.set_value_no_signal(current_sector.platform.ceilingTextureShiftY)
		
		%PlatformFloorOffsetXEdit.get_line_edit().text = "%d" % current_sector.platform.floorTextureShiftX
		%PlatformFloorOffsetXEdit.set_value_no_signal(current_sector.platform.floorTextureShiftX)
		%PlatformFloorOffsetYEdit.get_line_edit().text = "%d" % current_sector.platform.floorTextureShiftY
		%PlatformFloorOffsetYEdit.set_value_no_signal(current_sector.platform.floorTextureShiftY)
		
		if current_sector.platform.ceilingTextureIndex in das.mapping:
			%PlatformRoofTextureOption.add_item( "%s:%s" % [das.mapping[current_sector.platform.ceilingTextureIndex].index, das.mapping[current_sector.platform.ceilingTextureIndex].name] )
		else:
			%PlatformRoofTextureOption.add_item( "%d" % current_sector.platform.ceilingTextureIndex )
		if current_sector.platform.floorTextureIndex in das.mapping:
			%PlatformFloorTextureOption.add_item( "%s:%s" % [das.mapping[current_sector.platform.floorTextureIndex].index, das.mapping[current_sector.platform.floorTextureIndex].name] )
		else:
			%PlatformFloorTextureOption.add_item( "%d" % current_sector.platform.floorTextureIndex )
		
		%PlatformRoofTextureOption.add_item("--------")
		%PlatformRoofTextureOption.add_item("Sky")
		%PlatformRoofTextureOption.add_item("Select Texture")
		%PlatformRoofTextureOption.add_item("Select Palette")
		%PlatformFloorTextureOption.add_item("--------")
		%PlatformFloorTextureOption.add_item("Sky")
		%PlatformFloorTextureOption.add_item("Select Texture")
		%PlatformFloorTextureOption.add_item("Select Palette")
		
		
	else:
		%PlatformCheckButton.set_pressed_no_signal(false)
		%PlatformContainer.hide()


func _on_roof_height_edit_value_changed(value: float) -> void:
	current_sector.data.ceilingHeight = value
	var caret: int = %RoofHeightEdit.get_line_edit().caret_column
	await %Picker.redraw_selected_node()
	%RoofHeightEdit.get_line_edit().grab_focus()
	await get_tree().process_frame
	%RoofHeightEdit.get_line_edit().caret_column = caret


func _on_floor_height_edit_value_changed(value: float) -> void:
	current_sector.data.floorHeight = value
	var caret: int = %FloorHeightEdit.get_line_edit().caret_column
	await %Picker.redraw_selected_node()
	%FloorHeightEdit.get_line_edit().grab_focus()
	await get_tree().process_frame
	%FloorHeightEdit.get_line_edit().caret_column = caret


func _on_glow_edit_value_changed(value: float) -> void:
	current_sector.data.lighting = value


func _on_floor_trigger_id_edit_value_changed(value: float) -> void:
	current_sector.data.floorTriggerID = value


func _on_candle_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		current_sector.data.textureFit |= (Sector.CANDLE)
	else:
		current_sector.data.textureFit &= ~(Sector.CANDLE)


func _on_unk_0x_04_edit_value_changed(value: float) -> void:
	current_sector.data.unk0x04 = value


func _on_lightning_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		current_sector.data.textureFit |= (Sector.LIGHTNING)
	else:
		current_sector.data.textureFit &= ~(Sector.LIGHTNING)


func _on_texture_height_override_edit_value_changed(value: float) -> void:
	current_sector.data.textureMapOverride = value
	var caret: int = %TextureHeightOverrideEdit.get_line_edit().caret_column
	await %Picker.redraw_selected_node()
	%TextureHeightOverrideEdit.get_line_edit().grab_focus()
	await get_tree().process_frame
	%TextureHeightOverrideEdit.get_line_edit().caret_column = caret


func _on_roof_offset_x_edit_value_changed(value: float) -> void:
	current_sector.data.ceilingTextureShiftX = value
	var caret: int = %RoofOffsetXEdit.get_line_edit().caret_column
	await %Picker.redraw_selected_node()
	%RoofOffsetXEdit.get_line_edit().grab_focus()
	await get_tree().process_frame
	%RoofOffsetXEdit.get_line_edit().caret_column = caret


func _on_roof_offset_y_edit_value_changed(value: float) -> void:
	current_sector.data.ceilingTextureShiftY = value
	var caret: int = %RoofOffsetYEdit.get_line_edit().caret_column
	await %Picker.redraw_selected_node()
	%RoofOffsetYEdit.get_line_edit().grab_focus()
	await get_tree().process_frame
	%RoofOffsetYEdit.get_line_edit().caret_column = caret


func _on_floor_offset_x_edit_value_changed(value: float) -> void:
	current_sector.data.floorTextureShiftX = value
	var caret: int = %FloorOffsetXEdit.get_line_edit().caret_column
	await %Picker.redraw_selected_node()
	%FloorOffsetXEdit.get_line_edit().grab_focus()
	await get_tree().process_frame
	%FloorOffsetXEdit.get_line_edit().caret_column = caret


func _on_floor_offset_y_edit_value_changed(value: float) -> void:
	current_sector.data.floorTextureShiftY = value
	var caret: int = %FloorOffsetYEdit.get_line_edit().caret_column
	await %Picker.redraw_selected_node()
	%FloorOffsetYEdit.get_line_edit().grab_focus()
	await get_tree().process_frame
	%FloorOffsetYEdit.get_line_edit().caret_column = caret


func _on_roof_scale_option_item_selected(index: int) -> void:
	match index:
		0:
			current_sector.data.textureFit &= ~Sector.CEILING_A
			current_sector.data.textureFit &= ~Sector.CEILING_B
		1:
			current_sector.data.textureFit |= Sector.CEILING_A
			current_sector.data.textureFit &= ~Sector.CEILING_B
		2:
			current_sector.data.textureFit &= ~Sector.CEILING_A
			current_sector.data.textureFit |= Sector.CEILING_B
		3:
			current_sector.data.textureFit |= Sector.CEILING_A
			current_sector.data.textureFit |= Sector.CEILING_B
	%Picker.redraw_selected_node()


func _on_floor_scale_option_item_selected(index: int) -> void:
	match index:
		0:
			current_sector.data.textureFit &= ~Sector.FLOOR_A
			current_sector.data.textureFit &= ~Sector.FLOOR_B
		1:
			current_sector.data.textureFit |= Sector.FLOOR_A
			current_sector.data.textureFit &= ~Sector.FLOOR_B
		2:
			current_sector.data.textureFit &= ~Sector.FLOOR_A
			current_sector.data.textureFit |= Sector.FLOOR_B
		3:
			current_sector.data.textureFit |= Sector.FLOOR_A
			current_sector.data.textureFit |= Sector.FLOOR_B
	%Picker.redraw_selected_node()


func _on_roof_texture_option_item_selected(index: int) -> void:
	if index == %RoofTextureOption.item_count - 1:
		var das: Dictionary = await Roth.get_das(current_sector.map_info.das)
		%Palette.show_palette(das.palette)
		%RoofTextureOption.select(0)
		var palette_index: int = await %Palette.color_selected
		if palette_index < 0:
			return
		current_sector.data.ceilingTextureIndex = palette_index + 65280
		load_edit_sector(current_sector)
		%Picker.redraw_selected_node()
	elif index == %RoofTextureOption.item_count - 2:
		var das: Dictionary = await Roth.get_das(current_sector.map_info.das)
		%Texture.show_texture(das, true)
		%RoofTextureOption.select(0)
		var texture_index: int = await %Texture.texture_selected
		if texture_index < 0:
			return
		current_sector.data.ceilingTextureIndex = texture_index
		load_edit_sector(current_sector)
		%Picker.redraw_selected_node()
	elif index == %RoofTextureOption.item_count - 3:
		current_sector.data.ceilingTextureIndex = Roth.get_map(current_sector.map_info).metadata.skyTexture
		load_edit_sector(current_sector)
		%Picker.redraw_selected_node()
	elif index == %RoofTextureOption.item_count - 4:
		%RoofTextureOption.select(0)


func _on_floor_texture_option_item_selected(index: int) -> void:
	if index == %FloorTextureOption.item_count - 1:
		var das: Dictionary = await Roth.get_das(current_sector.map_info.das)
		%Palette.show_palette(das.palette)
		%FloorTextureOption.select(0)
		var palette_index: int = await %Palette.color_selected
		if palette_index < 0:
			return
		current_sector.data.floorTextureIndex = palette_index + 65280
		load_edit_sector(current_sector)
		%Picker.redraw_selected_node()
	elif index == %FloorTextureOption.item_count - 2:
		var das: Dictionary = await Roth.get_das(current_sector.map_info.das)
		%Texture.show_texture(das, true)
		%FloorTextureOption.select(0)
		var texture_index: int = await %Texture.texture_selected
		if texture_index < 0:
			return
		current_sector.data.floorTextureIndex = texture_index
		load_edit_sector(current_sector)
		%Picker.redraw_selected_node()
	elif index == %FloorTextureOption.item_count - 3:
		current_sector.data.floorTextureIndex = Roth.get_map(current_sector.map_info).metadata.skyTexture
		load_edit_sector(current_sector)
		%Picker.redraw_selected_node()
	elif index == %FloorTextureOption.item_count - 4:
		%FloorTextureOption.select(0)


func _on_roof_flip_x_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		current_sector.data.unk0x16 |= (Sector.CEILING_FLIP_X)
	else:
		current_sector.data.unk0x16 &= ~(Sector.CEILING_FLIP_X)
	%Picker.redraw_selected_node()


func _on_roof_flip_y_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		current_sector.data.unk0x16 |= (Sector.CEILING_FLIP_Y)
	else:
		current_sector.data.unk0x16 &= ~(Sector.CEILING_FLIP_Y)
	%Picker.redraw_selected_node()


func _on_floor_flip_x_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		current_sector.data.unk0x16 |= (Sector.FLOOR_FLIP_X)
	else:
		current_sector.data.unk0x16 &= ~(Sector.FLOOR_FLIP_X)
	%Picker.redraw_selected_node()


func _on_floor_flip_y_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		current_sector.data.unk0x16 |= (Sector.FLOOR_FLIP_Y)
	else:
		current_sector.data.unk0x16 &= ~(Sector.FLOOR_FLIP_Y)
	%Picker.redraw_selected_node()


func _on_platform_floor_height_edit_value_changed(value: float) -> void:
	current_sector.platform.floorHeight = value
	%Picker.redraw_selected_node(%PlatformFloorHeightEdit)


func _on_platform_floor_scale_option_item_selected(index: int) -> void:
	match index:
		0:
			current_sector.platform.floorTextureScale &= ~Sector.FLOOR_A
			current_sector.platform.floorTextureScale &= ~Sector.FLOOR_B
		1:
			current_sector.platform.floorTextureScale |= Sector.FLOOR_A
			current_sector.platform.floorTextureScale &= ~Sector.FLOOR_B
		2:
			current_sector.platform.floorTextureScale &= ~Sector.FLOOR_A
			current_sector.platform.floorTextureScale |= Sector.FLOOR_B
		3:
			current_sector.platform.floorTextureScale |= Sector.FLOOR_A
			current_sector.platform.floorTextureScale |= Sector.FLOOR_B
	%Picker.redraw_selected_node()


func _on_platform_roof_height_edit_value_changed(value: float) -> void:
	current_sector.platform.ceilingHeight = value
	%Picker.redraw_selected_node(%PlatformRoofHeightEdit)


func _on_platform_roof_scale_option_item_selected(index: int) -> void:
	match index:
		0:
			current_sector.platform.floorTextureScale &= ~Sector.CEILING_A
			current_sector.platform.floorTextureScale &= ~Sector.CEILING_B
		1:
			current_sector.platform.floorTextureScale |= Sector.CEILING_A
			current_sector.platform.floorTextureScale &= ~Sector.CEILING_B
		2:
			current_sector.platform.floorTextureScale &= ~Sector.CEILING_A
			current_sector.platform.floorTextureScale |= Sector.CEILING_B
		3:
			current_sector.platform.floorTextureScale |= Sector.CEILING_A
			current_sector.platform.floorTextureScale |= Sector.CEILING_B
	%Picker.redraw_selected_node()


func _on_platform_floor_texture_option_item_selected(index: int) -> void:
	if index == %PlatformFloorTextureOption.item_count - 1:
		var das: Dictionary = await Roth.get_das(current_sector.map_info.das)
		%Palette.show_palette(das.palette)
		var palette_index: int = await %Palette.color_selected
		if palette_index < 0:
			return
		current_sector.platform.floorTextureIndex = palette_index + 65280
		load_edit_sector(current_sector)
		%Picker.redraw_selected_node()
	elif index == %PlatformFloorTextureOption.item_count - 2:
		var das: Dictionary = await Roth.get_das(current_sector.map_info.das)
		%Texture.show_texture(das, true)
		var texture_index: int = await %Texture.texture_selected
		if texture_index < 0:
			return
		current_sector.platform.floorTextureIndex = texture_index
		load_edit_sector(current_sector)
		%Picker.redraw_selected_node()
	elif index == %PlatformFloorTextureOption.item_count - 3:
		current_sector.platform.floorTextureIndex = Roth.get_map(current_sector.map_info).metadata.skyTexture
		load_edit_sector(current_sector)
		%Picker.redraw_selected_node()
	elif index == %PlatformFloorTextureOption.item_count - 4:
		%PlatformFloorTextureOption.select(0)


func _on_platform_floor_offset_x_edit_value_changed(value: float) -> void:
	current_sector.platform.floorTextureShiftX = value
	%Picker.redraw_selected_node(%PlatformFloorOffsetXEdit)


func _on_platform_floor_offset_y_edit_value_changed(value: float) -> void:
	current_sector.platform.floorTextureShiftY = value
	%Picker.redraw_selected_node(%PlatformFloorOffsetYEdit)


func _on_platform_roof_texture_option_item_selected(index: int) -> void:
	if index == %PlatformRoofTextureOption.item_count - 1:
		var das: Dictionary = await Roth.get_das(current_sector.map_info.das)
		%Palette.show_palette(das.palette)
		var palette_index: int = await %Palette.color_selected
		if palette_index < 0:
			return
		current_sector.platform.ceilingTextureIndex = palette_index + 65280
		load_edit_sector(current_sector)
		%Picker.redraw_selected_node()
	elif index == %PlatformRoofTextureOption.item_count - 2:
		var das: Dictionary = await Roth.get_das(current_sector.map_info.das)
		%Texture.show_texture(das, true)
		var texture_index: int = await %Texture.texture_selected
		if texture_index < 0:
			return
		current_sector.platform.ceilingTextureIndex = texture_index
		load_edit_sector(current_sector)
		%Picker.redraw_selected_node()
	elif index == %PlatformRoofTextureOption.item_count - 3:
		current_sector.platform.ceilingTextureIndex = Roth.get_map(current_sector.map_info).metadata.skyTexture
		load_edit_sector(current_sector)
		%Picker.redraw_selected_node()
	elif index == %PlatformRoofTextureOption.item_count - 4:
		%PlatformRoofTextureOption.select(0)


func _on_platform_roof_offset_x_edit_value_changed(value: float) -> void:
	current_sector.platform.ceilingTextureShiftX = value
	%Picker.redraw_selected_node(%PlatformRoofOffsetXEdit)


func _on_platform_roof_offset_y_edit_value_changed(value: float) -> void:
	current_sector.platform.ceilingTextureShiftY = value
	%Picker.redraw_selected_node(%PlatformRoofOffsetYEdit)


func _on_platform_check_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		current_sector.platform = {
			"ceilingTextureIndex": 2,
			"ceilingHeight": ((current_sector.data.ceilingHeight + current_sector.data.floorHeight) / 2) - 10,
			"ceilingTextureShiftX": 0,
			"ceilingTextureShiftY": 0,
			"floorTextureIndex": 2,
			"floorHeight": ((current_sector.data.ceilingHeight + current_sector.data.floorHeight) / 2) + 10,
			"floorTextureShiftX": 0,
			"floorTextureShiftY": 0,
			"floorTextureScale": Sector.FLOOR_A | Sector.CEILING_A,
			"padding": 0,
		}
		for face_ref: WeakRef in current_sector.faces:
			var face: Face = face_ref.get_ref()
			if face.sister:
				var sister: Face = face.sister.get_ref()
				if sister.texture_data.midTextureIndex == Roth.get_map(sister.map_info).metadata.skyTexture:
					sister.texture_data.midTextureIndex = 2
				var value := int(ceil(sister.face_length))
				sister.texture_data.unk0x00 = int(value) & 255
				sister.texture_data.type = (int(value) >> 8) | (sister.texture_data.type & (1<<7))
	else:
		current_sector.platform = {}
	load_edit_sector(current_sector)
	%Picker.redraw_selected_node(%PlatformRoofOffsetYEdit)


func _on_select_faces_button_pressed() -> void:
	%SelectFacesPopupMenu.popup(Rect2i(%SelectFacesButton.global_position.x, %SelectFacesButton.global_position.y+%SelectFacesButton.size.y, %SelectFacesButton.size.x, 0))


func _on_select_faces_popup_menu_index_pressed(index: int) -> void:
	var face_node: Node3D = %SelectFacesPopupMenu.get_item_metadata(index)
	%Picker.select(face_node, true)
