extends MarginContainer

enum {
	SELECT_DASH,
	SELECT_SKY,
	SELECT_TEXTURE,
	SELECT_PALETTE,
	EDIT_TEXTURE,
}

var last_selection_length: int = 0


func clear(p_force_timeout: bool = true) -> void:
	if p_force_timeout and not %EditSectorTimer.is_stopped():
		%EditSectorTimer.stop()
		%EditSectorTimer.timeout.emit()
	%SectorIndexLabel.text = ""
	%SelectFacesPopupMenu.clear()
	%RoofHeightEdit.get_line_edit().clear()
	%RoofScaleOption.select(1)
	%FloorHeightEdit.get_line_edit().clear()
	%FloorScaleOption.select(1)
	%GlowEdit.get_line_edit().clear()
	%FloorTriggerIDEdit.get_line_edit().clear()
	%CandleCheckBox.set_pressed_no_signal(false)
	%CandleCheckBox.indeterminate = false
	%LightningCheckBox.set_pressed_no_signal(false)
	%LightningCheckBox.indeterminate = false
	%TextureHeightOverrideEdit.get_line_edit().clear()
	%RoofTextureOption.clear()
	%RoofOffsetXEdit.get_line_edit().clear()
	%RoofOffsetYEdit.get_line_edit().clear()
	%FloorTextureOption.clear()
	%FloorOffsetXEdit.get_line_edit().clear()
	%FloorOffsetYEdit.get_line_edit().clear()
	%RoofFlipXCheckBox.set_pressed_no_signal(false)
	%RoofFlipXCheckBox.indeterminate = false
	%RoofFlipYCheckBox.set_pressed_no_signal(false)
	%RoofFlipYCheckBox.indeterminate = false
	%FloorFlipXCheckBox.set_pressed_no_signal(false)
	%FloorFlipXCheckBox.indeterminate = false
	%FloorFlipYCheckBox.set_pressed_no_signal(false)
	%FloorFlipYCheckBox.indeterminate = false
	
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
	%SelectFacesButton.show()
	%EditSectorContainer.hide()
	#%RelativeAmountControls.hide()
	#%RelativeRoofControls.hide()
	#%RelativeFloorControls.hide()
	last_selection_length = 0
	# Custom arrow steps on spinboxs are broken
	#%FloorHeightEdit.custom_arrow_step = %RelativeAmountBox.value
	#%RoofHeightEdit.custom_arrow_step = %RelativeAmountBox.value


func update_selections(p_force_timeout: bool = true) -> void:
	clear(p_force_timeout)
	if len(owner.selected_sectors) == 0 or (len(owner.selected_sectors) == 1 and len(owner.selected_faces) > 0):
		return
	
	%EditSectorContainer.show()
	last_selection_length = len(owner.selected_sectors)
	var sector: Sector = owner.selected_sectors[0]
	
	if len(owner.selected_sectors) == 1:
		%SectorIndexLabel.text = "Sector: %d" % sector.index
		for i in range(len(sector.faces)):
			var face: Face = sector.faces[i].get_ref()
			%SelectFacesPopupMenu.add_item("%d" % face.index)
			%SelectFacesPopupMenu.set_item_metadata(i, face)
		%SelectFacesButton.show()
		#%RelativeAmountControls.hide()
		#%RelativeRoofControls.hide()
		#%RelativeFloorControls.hide()
	elif len(owner.selected_sectors) > 1:
		%SectorIndexLabel.text = "Sector: %d Selected" % len(owner.selected_sectors)
		%SelectFacesButton.hide()
		%RelativeAmountControls.show()
		%RelativeRoofControls.show()
		%RelativeFloorControls.show()
	
	
	%RoofHeightEdit.get_line_edit().text = "%d" % sector.data.ceilingHeight
	%RoofHeightEdit.set_value_no_signal(sector.data.ceilingHeight)
	var roof_a: int = sector.data.textureFit & Sector.CEILING_A > 0
	var roof_b: int = sector.data.textureFit & Sector.CEILING_B > 0
	if roof_a == 0 and roof_b == 0:
		%RoofScaleOption.select(0)
	elif roof_a == 1 and roof_b == 0:
		%RoofScaleOption.select(1)
	elif roof_a == 0 and roof_b == 1:
		%RoofScaleOption.select(2)
	elif roof_a == 1 and roof_b == 1:
		%RoofScaleOption.select(3)
	
	%FloorHeightEdit.get_line_edit().text = "%d" % sector.data.floorHeight
	%FloorHeightEdit.set_value_no_signal(sector.data.floorHeight)
	var floor_a: int = sector.data.textureFit & Sector.FLOOR_A > 0
	var floor_b: int = sector.data.textureFit & Sector.FLOOR_B > 0
	if floor_a == 0 and floor_b == 0:
		%FloorScaleOption.select(0)
	elif floor_a == 1 and floor_b == 0:
		%FloorScaleOption.select(1)
	elif floor_a == 0 and floor_b == 1:
		%FloorScaleOption.select(2)
	elif floor_a == 1 and floor_b == 1:
		%FloorScaleOption.select(3)
	
	%GlowEdit.get_line_edit().text = "%d" % sector.data.lighting
	%GlowEdit.set_value_no_signal(sector.data.lighting)
	
	%FloorTriggerIDEdit.get_line_edit().text = "%d" % sector.data.floorTriggerID
	%FloorTriggerIDEdit.set_value_no_signal(sector.data.floorTriggerID)
	
	if sector.data.textureFit & Sector.CANDLE > 0:
		%CandleCheckBox.set_pressed_no_signal(true)
	
	if sector.data.textureFit & Sector.LIGHTNING > 0:
		%LightningCheckBox.set_pressed_no_signal(true)
	
	%TextureHeightOverrideEdit.get_line_edit().text = "%d" % sector.data.textureMapOverride
	%TextureHeightOverrideEdit.set_value_no_signal(sector.data.textureMapOverride)
	
	%RoofOffsetXEdit.get_line_edit().text = "%d" % sector.data.ceilingTextureShiftX
	%RoofOffsetXEdit.set_value_no_signal(sector.data.ceilingTextureShiftX)
	%RoofOffsetYEdit.get_line_edit().text = "%d" % sector.data.ceilingTextureShiftY
	%RoofOffsetYEdit.set_value_no_signal(sector.data.ceilingTextureShiftY)
	%FloorOffsetXEdit.get_line_edit().text = "%d" % sector.data.floorTextureShiftX
	%FloorOffsetXEdit.set_value_no_signal(sector.data.floorTextureShiftX)
	%FloorOffsetYEdit.get_line_edit().text = "%d" % sector.data.floorTextureShiftY
	%FloorOffsetYEdit.set_value_no_signal(sector.data.floorTextureShiftY)
	
	if sector.data.unk0x16 & Sector.CEILING_FLIP_X > 0:
		%RoofFlipXCheckBox.set_pressed_no_signal(true)
	if sector.data.unk0x16 & Sector.CEILING_FLIP_Y > 0:
		%RoofFlipYCheckBox.set_pressed_no_signal(true)
	if sector.data.unk0x16 & Sector.FLOOR_FLIP_X > 0:
		%FloorFlipXCheckBox.set_pressed_no_signal(true)
	if sector.data.unk0x16 & Sector.FLOOR_FLIP_Y > 0:
		%FloorFlipYCheckBox.set_pressed_no_signal(true)
	
	%RoofTextureOption.clear()
	%FloorTextureOption.clear()
	%PlatformRoofTextureOption.clear()
	%PlatformFloorTextureOption.clear()
	
	var das := sector.map.das
	if sector.data.ceilingTextureIndex in das.mapping:
		%RoofTextureOption.add_item( "%s:%s" % [das.mapping[sector.data.ceilingTextureIndex].index, das.mapping[sector.data.ceilingTextureIndex].name] )
	else:
		%RoofTextureOption.add_item( "%d" % sector.data.ceilingTextureIndex )
	if sector.data.floorTextureIndex in das.mapping:
		%FloorTextureOption.add_item( "%s:%s" % [das.mapping[sector.data.floorTextureIndex].index, das.mapping[sector.data.floorTextureIndex].name] )
	else:
		%FloorTextureOption.add_item( "%d" % sector.data.floorTextureIndex )
	
	
	if sector.platform:
		%PlatformCheckButton.set_pressed_no_signal(true)
		%PlatformContainer.show()
	
		%PlatformFloorHeightEdit.get_line_edit().text = "%d" % sector.platform.floorHeight
		%PlatformFloorHeightEdit.set_value_no_signal(sector.platform.floorHeight)
		
		%PlatformRoofHeightEdit.get_line_edit().text = "%d" % sector.platform.ceilingHeight
		%PlatformRoofHeightEdit.set_value_no_signal(sector.platform.ceilingHeight)
		
		var platform_floor_a: int = sector.platform.floorTextureScale & Sector.FLOOR_A > 0
		var platform_floor_b: int = sector.platform.floorTextureScale & Sector.FLOOR_B > 0
		if platform_floor_a == 0 and platform_floor_b == 0:
			%PlatformFloorScaleOption.select(0)
		elif platform_floor_a == 1 and platform_floor_b == 0:
			%PlatformFloorScaleOption.select(1)
		elif platform_floor_a == 0 and platform_floor_b == 1:
			%PlatformFloorScaleOption.select(2)
		elif platform_floor_a == 1 and platform_floor_b == 1:
			%PlatformFloorScaleOption.select(3)
		
		var platform_ceiling_a: int = sector.platform.floorTextureScale & Sector.CEILING_A > 0
		var platform_ceiling_b: int = sector.platform.floorTextureScale & Sector.CEILING_B > 0
		if platform_ceiling_a == 0 and platform_ceiling_b == 0:
			%PlatformRoofScaleOption.select(0)
		elif platform_ceiling_a == 1 and platform_ceiling_b == 0:
			%PlatformRoofScaleOption.select(1)
		elif platform_ceiling_a == 0 and platform_ceiling_b == 1:
			%PlatformRoofScaleOption.select(2)
		elif platform_ceiling_a == 1 and platform_ceiling_b == 1:
			%PlatformRoofScaleOption.select(3)
		
		%PlatformRoofOffsetXEdit.get_line_edit().text = "%d" % sector.platform.ceilingTextureShiftX
		%PlatformRoofOffsetXEdit.set_value_no_signal(sector.platform.ceilingTextureShiftX)
		%PlatformRoofOffsetYEdit.get_line_edit().text = "%d" % sector.platform.ceilingTextureShiftY
		%PlatformRoofOffsetYEdit.set_value_no_signal(sector.platform.ceilingTextureShiftY)
		
		%PlatformFloorOffsetXEdit.get_line_edit().text = "%d" % sector.platform.floorTextureShiftX
		%PlatformFloorOffsetXEdit.set_value_no_signal(sector.platform.floorTextureShiftX)
		%PlatformFloorOffsetYEdit.get_line_edit().text = "%d" % sector.platform.floorTextureShiftY
		%PlatformFloorOffsetYEdit.set_value_no_signal(sector.platform.floorTextureShiftY)
		
		if sector.platform.ceilingTextureIndex in das.mapping:
			%PlatformRoofTextureOption.add_item( "%s:%s" % [das.mapping[sector.platform.ceilingTextureIndex].index, das.mapping[sector.platform.ceilingTextureIndex].name] )
		else:
			%PlatformRoofTextureOption.add_item( "%d" % sector.platform.ceilingTextureIndex )
		if sector.platform.floorTextureIndex in das.mapping:
			%PlatformFloorTextureOption.add_item( "%s:%s" % [das.mapping[sector.platform.floorTextureIndex].index, das.mapping[sector.platform.floorTextureIndex].name] )
		else:
			%PlatformFloorTextureOption.add_item( "%d" % sector.platform.floorTextureIndex )
		
	else:
		%PlatformCheckButton.set_pressed_no_signal(false)
		%PlatformContainer.hide()
	
	
	for each_sector: Sector in owner.selected_sectors:
		if each_sector.data.ceilingHeight != sector.data.ceilingHeight:
			%RoofHeightEdit.get_line_edit().clear.call_deferred()
		var each_roof_a: int = (each_sector.data.textureFit & Sector.CEILING_A > 0)
		var each_roof_b: int = (each_sector.data.textureFit & Sector.CEILING_B > 0)
		if  roof_a != each_roof_a or roof_b != each_roof_b:
			%RoofScaleOption.select(-1)
		
		if each_sector.data.floorHeight != sector.data.floorHeight:
			%FloorHeightEdit.get_line_edit().clear.call_deferred()
		var each_floor_a: int = (each_sector.data.textureFit & Sector.FLOOR_A > 0)
		var each_floor_b: int = (each_sector.data.textureFit & Sector.FLOOR_B > 0)
		if  floor_a != each_floor_a or floor_b != each_floor_b:
			%FloorScaleOption.select(-1)
		
		if each_sector.data.lighting != sector.data.lighting:
			%GlowEdit.get_line_edit().clear.call_deferred()
		if each_sector.data.floorTriggerID != sector.data.floorTriggerID:
			%FloorTriggerIDEdit.get_line_edit().clear.call_deferred()
		if ((each_sector.data.textureFit & Sector.CANDLE) > 0) != ((sector.data.textureFit & Sector.CANDLE) > 0):
			%CandleCheckBox.indeterminate = true
		if ((each_sector.data.textureFit & Sector.LIGHTNING) > 0) != ((sector.data.textureFit & Sector.LIGHTNING) > 0):
			%LightningCheckBox.indeterminate = true
		if each_sector.data.textureMapOverride != sector.data.textureMapOverride:
			%TextureHeightOverrideEdit.get_line_edit().clear.call_deferred()
		if each_sector.data.ceilingTextureShiftX != sector.data.ceilingTextureShiftX:
			%RoofOffsetXEdit.get_line_edit().clear.call_deferred()
		if each_sector.data.ceilingTextureShiftY != sector.data.ceilingTextureShiftY:
			%RoofOffsetYEdit.get_line_edit().clear.call_deferred()
		if each_sector.data.floorTextureShiftX != sector.data.floorTextureShiftX:
			%FloorOffsetXEdit.get_line_edit().clear.call_deferred()
		if each_sector.data.floorTextureShiftY != sector.data.floorTextureShiftY:
			%FloorOffsetYEdit.get_line_edit().clear.call_deferred()
		if ((each_sector.data.unk0x16 & Sector.CEILING_FLIP_X) > 0) != ((sector.data.unk0x16 & Sector.CEILING_FLIP_X) > 0):
			%RoofFlipXCheckBox.indeterminate = true
		if ((each_sector.data.unk0x16 & Sector.CEILING_FLIP_Y) > 0) != ((sector.data.unk0x16 & Sector.CEILING_FLIP_Y) > 0):
			%RoofFlipYCheckBox.indeterminate = true
		if ((each_sector.data.unk0x16 & Sector.FLOOR_FLIP_X) > 0) != ((sector.data.unk0x16 & Sector.FLOOR_FLIP_X) > 0):
			%FloorFlipXCheckBox.indeterminate = true
		if ((each_sector.data.unk0x16 & Sector.FLOOR_FLIP_Y) > 0) != ((sector.data.unk0x16 & Sector.FLOOR_FLIP_Y) > 0):
			%FloorFlipYCheckBox.indeterminate = true
		
		if each_sector.data.ceilingTextureIndex != sector.data.ceilingTextureIndex:
			%RoofTextureOption.clear()
		if each_sector.data.floorTextureIndex != sector.data.floorTextureIndex:
			%FloorTextureOption.clear()
		
		if each_sector.platform.is_empty():
			%PlatformCheckButton.set_pressed_no_signal(false)
			%PlatformContainer.hide()
		elif sector.platform:
			if each_sector.platform.ceilingHeight != sector.platform.ceilingHeight:
				%PlatformRoofHeightEdit.get_line_edit().clear.call_deferred()
			var platform_ceiling_a: int = sector.platform.floorTextureScale & Sector.CEILING_A > 0
			var platform_ceiling_b: int = sector.platform.floorTextureScale & Sector.CEILING_B > 0
			var each_platform_ceiling_a: int = each_sector.platform.floorTextureScale & Sector.CEILING_A > 0
			var each_platform_ceiling_b: int = each_sector.platform.floorTextureScale & Sector.CEILING_B > 0
			if  platform_ceiling_a != each_platform_ceiling_a or platform_ceiling_b != each_platform_ceiling_b:
				%PlatformRoofScaleOption.select(-1)
			
			if each_sector.platform.floorHeight != sector.platform.floorHeight:
				%PlatformFloorHeightEdit.get_line_edit().clear.call_deferred()
			var platform_floor_a: int = sector.platform.floorTextureScale & Sector.FLOOR_A > 0
			var platform_floor_b: int = sector.platform.floorTextureScale & Sector.FLOOR_B > 0
			var each_platform_floor_a: int = each_sector.platform.floorTextureScale & Sector.FLOOR_A > 0
			var each_platform_floor_b: int = each_sector.platform.floorTextureScale & Sector.FLOOR_B > 0
			if  platform_floor_a != each_platform_floor_a or platform_floor_b != each_platform_floor_b:
				%PlatformFloorScaleOption.select(-1)
			
			if each_sector.platform.ceilingTextureIndex != sector.platform.ceilingTextureIndex:
				%PlatformRoofTextureOption.clear()
			if each_sector.platform.floorTextureIndex != sector.platform.floorTextureIndex:
				%PlatformFloorTextureOption.clear()
			
			if each_sector.platform.ceilingTextureShiftX != sector.platform.ceilingTextureShiftX:
				%PlatformRoofOffsetXEdit.get_line_edit().clear.call_deferred()
			if each_sector.platform.ceilingTextureShiftY != sector.platform.ceilingTextureShiftY:
				%PlatformRoofOffsetYEdit.get_line_edit().clear.call_deferred()
			if each_sector.platform.floorTextureShiftX != sector.platform.floorTextureShiftX:
				%PlatformFloorOffsetXEdit.get_line_edit().clear.call_deferred()
			if each_sector.platform.floorTextureShiftY != sector.platform.floorTextureShiftY:
				%PlatformFloorOffsetYEdit.get_line_edit().clear.call_deferred()
	
	%RoofTextureOption.add_item("--------", SELECT_DASH)
	%RoofTextureOption.add_item("Sky", SELECT_SKY)
	%RoofTextureOption.add_item("Select Texture", SELECT_TEXTURE)
	%RoofTextureOption.add_item("Select Palette", SELECT_PALETTE)
	%FloorTextureOption.add_item("--------", SELECT_DASH)
	%FloorTextureOption.add_item("Sky", SELECT_SKY)
	%FloorTextureOption.add_item("Select Texture", SELECT_TEXTURE)
	%FloorTextureOption.add_item("Select Palette", SELECT_PALETTE)
	
	%PlatformRoofTextureOption.add_item("--------", SELECT_DASH)
	%PlatformRoofTextureOption.add_item("Sky", SELECT_SKY)
	%PlatformRoofTextureOption.add_item("Select Texture", SELECT_TEXTURE)
	%PlatformRoofTextureOption.add_item("Select Palette", SELECT_PALETTE)
	%PlatformFloorTextureOption.add_item("--------", SELECT_DASH)
	%PlatformFloorTextureOption.add_item("Sky", SELECT_SKY)
	%PlatformFloorTextureOption.add_item("Select Texture", SELECT_TEXTURE)
	%PlatformFloorTextureOption.add_item("Select Palette", SELECT_PALETTE)
	if "vanilla" not in sector.map.map_info.das_info:
		%RoofTextureOption.add_item("Edit Texture", EDIT_TEXTURE)
		%FloorTextureOption.add_item("Edit Texture", EDIT_TEXTURE)
		%PlatformRoofTextureOption.add_item("Edit Texture", EDIT_TEXTURE)
		%PlatformFloorTextureOption.add_item("Edit Texture", EDIT_TEXTURE)


func _on_roof_height_edit_value_changed(value: float) -> void:
	for sector: Sector in owner.selected_sectors:
		sector.data.ceilingHeight = value
	owner.redraw(owner.selected_sectors)
	%EditSectorTimer.start()


func _on_floor_height_edit_value_changed(value: float) -> void:
	for sector: Sector in owner.selected_sectors:
		sector.data.floorHeight = value
	owner.redraw(owner.selected_sectors)
	%EditSectorTimer.start()


func _on_glow_edit_value_changed(value: float) -> void:
	for sector: Sector in owner.selected_sectors:
		sector.data.lighting = value
	%EditSectorTimer.start()


func _on_floor_trigger_id_edit_value_changed(value: float) -> void:
	for sector: Sector in owner.selected_sectors:
		sector.data.floorTriggerID = value
	%EditSectorTimer.start()


func _on_candle_check_box_toggled(toggled_on: bool) -> void:
	for sector: Sector in owner.selected_sectors:
		if toggled_on:
			sector.data.textureFit |= (Sector.CANDLE)
		else:
			sector.data.textureFit &= ~(Sector.CANDLE)
	%EditSectorTimer.start()


func _on_lightning_check_box_toggled(toggled_on: bool) -> void:
	for sector: Sector in owner.selected_sectors:
		if toggled_on:
			sector.data.textureFit |= (Sector.LIGHTNING)
		else:
			sector.data.textureFit &= ~(Sector.LIGHTNING)
	%EditSectorTimer.start()


func _on_texture_height_override_edit_value_changed(value: float) -> void:
	for sector: Sector in owner.selected_sectors:
		sector.data.textureMapOverride = value
	owner.redraw(owner.selected_sectors)
	%EditSectorTimer.start()


func _on_roof_offset_x_edit_value_changed(value: float) -> void:
	for sector: Sector in owner.selected_sectors:
		sector.data.ceilingTextureShiftX = value
	owner.redraw(owner.selected_sectors)
	%EditSectorTimer.start()


func _on_roof_offset_y_edit_value_changed(value: float) -> void:
	for sector: Sector in owner.selected_sectors:
		sector.data.ceilingTextureShiftY = value
	owner.redraw(owner.selected_sectors)
	%EditSectorTimer.start()


func _on_floor_offset_x_edit_value_changed(value: float) -> void:
	for sector: Sector in owner.selected_sectors:
		sector.data.floorTextureShiftX = value
	owner.redraw(owner.selected_sectors)
	%EditSectorTimer.start()


func _on_floor_offset_y_edit_value_changed(value: float) -> void:
	for sector: Sector in owner.selected_sectors:
		sector.data.floorTextureShiftY = value
	owner.redraw(owner.selected_sectors)
	%EditSectorTimer.start()


func _on_roof_scale_option_item_selected(index: int) -> void:
	for sector: Sector in owner.selected_sectors:
		match index:
			0:
				sector.data.textureFit &= ~Sector.CEILING_A
				sector.data.textureFit &= ~Sector.CEILING_B
			1:
				sector.data.textureFit |= Sector.CEILING_A
				sector.data.textureFit &= ~Sector.CEILING_B
			2:
				sector.data.textureFit &= ~Sector.CEILING_A
				sector.data.textureFit |= Sector.CEILING_B
			3:
				sector.data.textureFit |= Sector.CEILING_A
				sector.data.textureFit |= Sector.CEILING_B
	owner.redraw(owner.selected_sectors)
	%EditSectorTimer.start()


func _on_floor_scale_option_item_selected(index: int) -> void:
	for sector: Sector in owner.selected_sectors:
		match index:
			0:
				sector.data.textureFit &= ~Sector.FLOOR_A
				sector.data.textureFit &= ~Sector.FLOOR_B
			1:
				sector.data.textureFit |= Sector.FLOOR_A
				sector.data.textureFit &= ~Sector.FLOOR_B
			2:
				sector.data.textureFit &= ~Sector.FLOOR_A
				sector.data.textureFit |= Sector.FLOOR_B
			3:
				sector.data.textureFit |= Sector.FLOOR_A
				sector.data.textureFit |= Sector.FLOOR_B
	owner.redraw(owner.selected_sectors)
	%EditSectorTimer.start()


func _on_roof_texture_option_item_selected(index: int) -> void:
	var id: int = %RoofTextureOption.get_item_id(index)
	match id:
		SELECT_PALETTE:
			var das: Dictionary = owner.selected_sectors[0].map.das
			%Palette.show_palette(das.palette)
			%RoofTextureOption.select(0)
			var palette_index: int = await %Palette.color_selected
			if palette_index < 0:
				return
			for sector: Sector in owner.selected_sectors:
				sector.data.ceilingTextureIndex = palette_index + 65280
			update_selections(false)
			owner.redraw(owner.selected_sectors)
			%EditSectorTimer.start()
		SELECT_TEXTURE:
			var das: Dictionary = owner.selected_sectors[0].map.das
			%Texture.show_texture(das, true, owner.selected_sectors[0].data.ceilingTextureIndex)
			%RoofTextureOption.select(0)
			var texture_index: int = await %Texture.texture_selected
			if texture_index < 0:
				return
			for sector: Sector in owner.selected_sectors:
				sector.data.ceilingTextureIndex = texture_index
			update_selections(false)
			owner.redraw(owner.selected_sectors)
			%EditSectorTimer.start()
		SELECT_SKY:
			var das: Dictionary = owner.selected_sectors[0].map.das
			for sector: Sector in owner.selected_sectors:
				sector.data.ceilingTextureIndex = das.textures[0].index
			update_selections(false)
			owner.redraw(owner.selected_sectors)
			%EditSectorTimer.start()
		SELECT_DASH:
			%RoofTextureOption.select(0)
		EDIT_TEXTURE:
			var sector: Sector = owner.selected_sectors[0]
			var das: Dictionary = sector.map.das
			%RoofTextureOption.select(0)
			Roth.edit_texture.emit(das.das_info, sector.data.ceilingTextureIndex)


func _on_floor_texture_option_item_selected(index: int) -> void:
	var id: int = %FloorTextureOption.get_item_id(index)
	match id:
		SELECT_PALETTE:
			var das: Dictionary = owner.selected_sectors[0].map.das
			%Palette.show_palette(das.palette)
			%FloorTextureOption.select(0)
			var palette_index: int = await %Palette.color_selected
			if palette_index < 0:
				return
			for sector: Sector in owner.selected_sectors:
				sector.data.floorTextureIndex = palette_index + 65280
			update_selections(false)
			owner.redraw(owner.selected_sectors)
			%EditSectorTimer.start()
		SELECT_TEXTURE:
			var das: Dictionary = owner.selected_sectors[0].map.das
			%Texture.show_texture(das, true, owner.selected_sectors[0].data.floorTextureIndex)
			%FloorTextureOption.select(0)
			var texture_index: int = await %Texture.texture_selected
			if texture_index < 0:
				return
			for sector: Sector in owner.selected_sectors:
				sector.data.floorTextureIndex = texture_index
			update_selections(false)
			owner.redraw(owner.selected_sectors)
			%EditSectorTimer.start()
		SELECT_SKY:
			var das: Dictionary = owner.selected_sectors[0].map.das
			for sector: Sector in owner.selected_sectors:
				sector.data.floorTextureIndex = das.textures[0].index
			update_selections(false)
			owner.redraw(owner.selected_sectors)
			%EditSectorTimer.start()
		SELECT_DASH:
			%FloorTextureOption.select(0)
		EDIT_TEXTURE:
			var sector: Sector = owner.selected_sectors[0]
			var das: Dictionary = sector.map.das
			%FloorTextureOption.select(0)
			Roth.edit_texture.emit(das.das_info, sector.data.floorTextureIndex)


func _on_roof_flip_x_check_box_toggled(toggled_on: bool) -> void:
	for sector: Sector in owner.selected_sectors:
		if toggled_on:
			sector.data.unk0x16 |= (Sector.CEILING_FLIP_X)
		else:
			sector.data.unk0x16 &= ~(Sector.CEILING_FLIP_X)
	owner.redraw(owner.selected_sectors)
	%EditSectorTimer.start()


func _on_roof_flip_y_check_box_toggled(toggled_on: bool) -> void:
	for sector: Sector in owner.selected_sectors:
		if toggled_on:
			sector.data.unk0x16 |= (Sector.CEILING_FLIP_Y)
		else:
			sector.data.unk0x16 &= ~(Sector.CEILING_FLIP_Y)
	owner.redraw(owner.selected_sectors)
	%EditSectorTimer.start()


func _on_floor_flip_x_check_box_toggled(toggled_on: bool) -> void:
	for sector: Sector in owner.selected_sectors:
		if toggled_on:
			sector.data.unk0x16 |= (Sector.FLOOR_FLIP_X)
		else:
			sector.data.unk0x16 &= ~(Sector.FLOOR_FLIP_X)
	owner.redraw(owner.selected_sectors)
	%EditSectorTimer.start()


func _on_floor_flip_y_check_box_toggled(toggled_on: bool) -> void:
	for sector: Sector in owner.selected_sectors:
		if toggled_on:
			sector.data.unk0x16 |= (Sector.FLOOR_FLIP_Y)
		else:
			sector.data.unk0x16 &= ~(Sector.FLOOR_FLIP_Y)
	owner.redraw(owner.selected_sectors)
	%EditSectorTimer.start()


func _on_platform_floor_height_edit_value_changed(value: float) -> void:
	for sector: Sector in owner.selected_sectors:
		sector.platform.floorHeight = value
	owner.redraw(owner.selected_sectors)
	%EditSectorTimer.start()


func _on_platform_floor_scale_option_item_selected(index: int) -> void:
	for sector: Sector in owner.selected_sectors:
		match index:
			0:
				sector.platform.floorTextureScale &= ~Sector.FLOOR_A
				sector.platform.floorTextureScale &= ~Sector.FLOOR_B
			1:
				sector.platform.floorTextureScale |= Sector.FLOOR_A
				sector.platform.floorTextureScale &= ~Sector.FLOOR_B
			2:
				sector.platform.floorTextureScale &= ~Sector.FLOOR_A
				sector.platform.floorTextureScale |= Sector.FLOOR_B
			3:
				sector.platform.floorTextureScale |= Sector.FLOOR_A
				sector.platform.floorTextureScale |= Sector.FLOOR_B
	owner.redraw(owner.selected_sectors)
	%EditSectorTimer.start()


func _on_platform_roof_height_edit_value_changed(value: float) -> void:
	for sector: Sector in owner.selected_sectors:
		sector.platform.ceilingHeight = value
	owner.redraw(owner.selected_sectors)
	%EditSectorTimer.start()


func _on_platform_roof_scale_option_item_selected(index: int) -> void:
	for sector: Sector in owner.selected_sectors:
		match index:
			0:
				sector.platform.floorTextureScale &= ~Sector.CEILING_A
				sector.platform.floorTextureScale &= ~Sector.CEILING_B
			1:
				sector.platform.floorTextureScale |= Sector.CEILING_A
				sector.platform.floorTextureScale &= ~Sector.CEILING_B
			2:
				sector.platform.floorTextureScale &= ~Sector.CEILING_A
				sector.platform.floorTextureScale |= Sector.CEILING_B
			3:
				sector.platform.floorTextureScale |= Sector.CEILING_A
				sector.platform.floorTextureScale |= Sector.CEILING_B
	owner.redraw(owner.selected_sectors)
	%EditSectorTimer.start()


func _on_platform_floor_texture_option_item_selected(index: int) -> void:
	var id: int = %PlatformFloorTextureOption.get_item_id(index)
	match id:
		SELECT_PALETTE:
			var das: Dictionary = owner.selected_sectors[0].map.das
			%Palette.show_palette(das.palette)
			%PlatformFloorTextureOption.select(0)
			var palette_index: int = await %Palette.color_selected
			if palette_index < 0:
				return
			for sector: Sector in owner.selected_sectors:
				sector.platform.floorTextureIndex = palette_index + 65280
			update_selections(false)
			owner.redraw(owner.selected_sectors)
			%EditSectorTimer.start()
		SELECT_TEXTURE:
			var das: Dictionary = owner.selected_sectors[0].map.das
			%Texture.show_texture(das, true, owner.selected_sectors[0].platform.floorTextureIndex)
			%PlatformFloorTextureOption.select(0)
			var texture_index: int = await %Texture.texture_selected
			if texture_index < 0:
				return
			for sector: Sector in owner.selected_sectors:
				sector.platform.floorTextureIndex = texture_index
			update_selections(false)
			owner.redraw(owner.selected_sectors)
			%EditSectorTimer.start()
		SELECT_SKY:
			var das: Dictionary = owner.selected_sectors[0].map.das
			for sector: Sector in owner.selected_sectors:
				sector.platform.floorTextureIndex = das.textures[0].index
			update_selections(false)
			owner.redraw(owner.selected_sectors)
			%EditSectorTimer.start()
		SELECT_DASH:
			%PlatformFloorTextureOption.select(0)
		EDIT_TEXTURE:
			var sector: Sector = owner.selected_sectors[0]
			var das: Dictionary = sector.map.das
			%PlatformFloorTextureOption.select(0)
			Roth.edit_texture.emit(das.das_info, sector.platform.floorTextureIndex)


func _on_platform_floor_offset_x_edit_value_changed(value: float) -> void:
	for sector: Sector in owner.selected_sectors:
		sector.platform.floorTextureShiftX = value
	owner.redraw(owner.selected_sectors)
	%EditSectorTimer.start()


func _on_platform_floor_offset_y_edit_value_changed(value: float) -> void:
	for sector: Sector in owner.selected_sectors:
		sector.platform.floorTextureShiftY = value
	owner.redraw(owner.selected_sectors)
	%EditSectorTimer.start()


func _on_platform_roof_texture_option_item_selected(index: int) -> void:
	var id: int = %PlatformRoofTextureOption.get_item_id(index)
	match id:
		SELECT_PALETTE:
			var das: Dictionary = owner.selected_sectors[0].map.das
			%Palette.show_palette(das.palette)
			%PlatformRoofTextureOption.select(0)
			var palette_index: int = await %Palette.color_selected
			if palette_index < 0:
				return
			for sector: Sector in owner.selected_sectors:
				sector.platform.ceilingTextureIndex = palette_index + 65280
			update_selections(false)
			owner.redraw(owner.selected_sectors)
			%EditSectorTimer.start()
		SELECT_TEXTURE:
			var das: Dictionary = owner.selected_sectors[0].map.das
			%Texture.show_texture(das, true, owner.selected_sectors[0].platform.ceilingTextureIndex)
			%PlatformRoofTextureOption.select(0)
			var texture_index: int = await %Texture.texture_selected
			if texture_index < 0:
				return
			for sector: Sector in owner.selected_sectors:
				sector.platform.ceilingTextureIndex = texture_index
			update_selections(false)
			owner.redraw(owner.selected_sectors)
			%EditSectorTimer.start()
		SELECT_SKY:
			var das: Dictionary = owner.selected_sectors[0].map.das
			for sector: Sector in owner.selected_sectors:
				sector.platform.ceilingTextureIndex = das.textures[0].index
			update_selections(false)
			owner.redraw(owner.selected_sectors)
			%EditSectorTimer.start()
		SELECT_DASH:
			%PlatformRoofTextureOption.select(0)
		EDIT_TEXTURE:
			var sector: Sector = owner.selected_sectors[0]
			var das: Dictionary = sector.map.das
			%PlatformRoofTextureOption.select(0)
			Roth.edit_texture.emit(das.das_info, sector.platform.ceilingTextureIndex)


func _on_platform_roof_offset_x_edit_value_changed(value: float) -> void:
	for sector: Sector in owner.selected_sectors:
		sector.platform.ceilingTextureShiftX = value
	owner.redraw(owner.selected_sectors)
	%EditSectorTimer.start()


func _on_platform_roof_offset_y_edit_value_changed(value: float) -> void:
	for sector: Sector in owner.selected_sectors:
		sector.platform.ceilingTextureShiftY = value
	owner.redraw(owner.selected_sectors)
	%EditSectorTimer.start()


func _on_platform_check_button_toggled(toggled_on: bool) -> void:
	var das: Dictionary = owner.selected_sectors[0].map.das
	for sector: Sector in owner.selected_sectors:
		if toggled_on:
			sector.platform = {
				"ceilingTextureIndex": 2,
				"ceilingHeight": ((sector.data.ceilingHeight + sector.data.floorHeight) / 2) - 10,
				"ceilingTextureShiftX": 0,
				"ceilingTextureShiftY": 0,
				"floorTextureIndex": 2,
				"floorHeight": ((sector.data.ceilingHeight + sector.data.floorHeight) / 2) + 10,
				"floorTextureShiftX": 0,
				"floorTextureShiftY": 0,
				"floorTextureScale": Sector.FLOOR_A | Sector.CEILING_A,
				"padding": 0,
			}
			for face_ref: WeakRef in sector.faces:
				var face: Face = face_ref.get_ref()
				if face.sister:
					var sister: Face = face.sister.get_ref()
					if sister.texture_data.midTextureIndex == das.textures[0].index:
						sister.texture_data.midTextureIndex = 2
					var value := int(ceil(sister.face_length))
					sister.texture_data.unk0x00 = int(value) & 255
					sister.texture_data.type = (int(value) >> 8) | (sister.texture_data.type & (1<<7))
		else:
			sector.platform = {}
	update_selections(false)
	owner.redraw(owner.selected_sectors)
	%EditSectorTimer.start()


func _on_select_faces_button_pressed() -> void:
	%SelectFacesPopupMenu.popup(Rect2i(%SelectFacesButton.global_position.x, %SelectFacesButton.global_position.y+%SelectFacesButton.size.y, %SelectFacesButton.size.x, 0))


func _on_select_faces_popup_menu_index_pressed(index: int) -> void:
	var face: Face = %SelectFacesPopupMenu.get_item_metadata(index)
	owner.select_resource(face)


func _on_edit_sector_timer_timeout() -> void:
	if last_selection_length == 1:
		Roth.editor_action.emit(owner.selected_sectors[0].map, "Edit Sector")
	elif last_selection_length > 1:
		Roth.editor_action.emit(owner.selected_sectors[0].map, "Edit Sectors")


func _on_lower_roof_button_pressed() -> void:
	for sector: Sector in owner.selected_sectors:
		sector.data.ceilingHeight -= %RelativeAmountBox.value
	update_selections(false)
	owner.redraw(owner.selected_sectors)
	%EditSectorTimer.start()


func _on_raise_roof_button_pressed() -> void:
	for sector: Sector in owner.selected_sectors:
		sector.data.ceilingHeight += %RelativeAmountBox.value
	update_selections(false)
	owner.redraw(owner.selected_sectors)
	%EditSectorTimer.start()


func _on_lower_floor_button_pressed() -> void:
	for sector: Sector in owner.selected_sectors:
		sector.data.floorHeight -= %RelativeAmountBox.value
	update_selections(false)
	owner.redraw(owner.selected_sectors)
	%EditSectorTimer.start()


func _on_raise_floor_button_pressed() -> void:
	for sector: Sector in owner.selected_sectors:
		sector.data.floorHeight += %RelativeAmountBox.value
	update_selections(false)
	owner.redraw(owner.selected_sectors)
	%EditSectorTimer.start()


func _on_relative_amount_box_value_changed(_value: float) -> void:
	# Broken
	#%FloorHeightEdit.custom_arrow_step = value
	#%RoofHeightEdit.custom_arrow_step = value
	pass
