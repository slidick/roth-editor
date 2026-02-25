extends MarginContainer

var last_selection_length: int = 0


func clear(p_force_timeout: bool = true) -> void:
	if p_force_timeout and not %EditFaceTimer.is_stopped():
		%EditFaceTimer.stop()
		%EditFaceTimer.timeout.emit()
	%FaceIndexLabel.text = ""
	%TopTextureOption.clear()
	%MidTextureOption.clear()
	%BottomTextureOption.clear()
	%XShiftEdit.get_line_edit().clear()
	%YShiftEdit.get_line_edit().clear()
	
	%TransparencyCheckBox.set_pressed_no_signal(false)
	%FlipXCheckBox.set_pressed_no_signal(false)
	%ImageFitCheckBox.set_pressed_no_signal(false)
	%FixedSizeTransparencyCheckBox.set_pressed_no_signal(false)
	%NoReflectCheckBox.set_pressed_no_signal(false)
	%HalfPixelCheckBox.set_pressed_no_signal(false)
	%EdgeMapCheckBox.set_pressed_no_signal(false)
	%DrawFromBottomCheckBox.set_pressed_no_signal(false)
	%"Unk0x00+TypeEdit".get_line_edit().clear()
	%StopWalkCheckBox.set_pressed_no_signal(false)
	%StopAlenCheckBox.set_pressed_no_signal(false)
	%Flag3CheckBox.set_pressed_no_signal(false)
	%RoomBlkCheckBox.set_pressed_no_signal(false)
	%Flag5CheckBox.set_pressed_no_signal(false)
	%Flag6CheckBox.set_pressed_no_signal(false)
	%Flag7CheckBox.set_pressed_no_signal(false)
	%Flag8CheckBox.set_pressed_no_signal(false)
	%TransparencyCheckBox.indeterminate = false
	%FlipXCheckBox.indeterminate = false
	%ImageFitCheckBox.indeterminate = false
	%FixedSizeTransparencyCheckBox.indeterminate = false
	%NoReflectCheckBox.indeterminate = false
	%HalfPixelCheckBox.indeterminate = false
	%EdgeMapCheckBox.indeterminate = false
	%DrawFromBottomCheckBox.indeterminate = false
	%StopWalkCheckBox.indeterminate = false
	%StopAlenCheckBox.indeterminate = false
	%Flag3CheckBox.indeterminate = false
	%RoomBlkCheckBox.indeterminate = false
	%Flag5CheckBox.indeterminate = false
	%Flag6CheckBox.indeterminate = false
	%Flag7CheckBox.indeterminate = false
	%Flag8CheckBox.indeterminate = false
	
	%SelectSisterButton.hide()
	%SisterEdit.text = ""
	%SelectSectorButton.show()
	%EditFaceContainer.hide()
	last_selection_length = 0


func update_selections(p_force_timeout: bool = true) -> void:
	clear(p_force_timeout)
	if len(owner.selected_faces) == 0:
		return
	
	%EditFaceContainer.show()
	last_selection_length = len(owner.selected_faces)
	
	var face: Face = owner.selected_faces[0]
	
	if len(owner.selected_faces) == 1:
		%FaceIndexLabel.text = "Face: %d" % face.index
		%SelectSectorButton.show()
		%EditSisterContainer.show()
		if face.sister:
			%SelectSisterButton.show()
			%SisterEdit.text = "%d" % face.sister.get_ref().index
		
	elif len(owner.selected_faces) > 1:
		%FaceIndexLabel.text = "Face: %d Selected" % len(owner.selected_faces)
		%SelectSectorButton.hide()
		%EditSisterContainer.hide()
		%SelectSisterButton.hide()
	
	
	if face.texture_data.unk0x08 & (1 << 0) > 0:
		%TransparencyCheckBox.set_pressed_no_signal(true)
	if face.texture_data.unk0x08 & (1 << 1) > 0:
		%FlipXCheckBox.set_pressed_no_signal(true)
	if face.texture_data.unk0x08 & (1 << 2) > 0:
		%ImageFitCheckBox.set_pressed_no_signal(true)
	if face.texture_data.unk0x08 & (1 << 3) > 0:
		%FixedSizeTransparencyCheckBox.set_pressed_no_signal(true)
	if face.texture_data.unk0x08 & (1 << 4) > 0:
		%NoReflectCheckBox.set_pressed_no_signal(true)
	if face.texture_data.unk0x08 & (1 << 5) > 0:
		%HalfPixelCheckBox.set_pressed_no_signal(true)
	if face.texture_data.unk0x08 & (1 << 6) > 0:
		%EdgeMapCheckBox.set_pressed_no_signal(true)
	if face.texture_data.unk0x08 & (1 << 7) > 0:
		%DrawFromBottomCheckBox.set_pressed_no_signal(true)
	
	if face.data.addCollision & (1 << 0) > 0:
		%StopWalkCheckBox.set_pressed_no_signal(true)
	if face.data.addCollision & (1 << 1) > 0:
		%StopAlenCheckBox.set_pressed_no_signal(true)
	if face.data.addCollision & (1 << 2) > 0:
		%Flag3CheckBox.set_pressed_no_signal(true)
	if face.data.addCollision & (1 << 3) > 0:
		%RoomBlkCheckBox.set_pressed_no_signal(true)
	if face.data.addCollision & (1 << 4) > 0:
		%Flag5CheckBox.set_pressed_no_signal(true)
	if face.data.addCollision & (1 << 5) > 0:
		%Flag6CheckBox.set_pressed_no_signal(true)
	if face.data.addCollision & (1 << 6) > 0:
		%Flag7CheckBox.set_pressed_no_signal(true)
	if face.data.addCollision & (1 << 7) > 0:
		%Flag8CheckBox.set_pressed_no_signal(true)
	
	
	%"Unk0x00+TypeEdit".set_value_no_signal(face.texture_data.unk0x00 + ((face.texture_data.type & ~(1<<7))<<8))
	%"Unk0x00+TypeEdit".get_line_edit().text = "%d" % (face.texture_data.unk0x00 + ((face.texture_data.type & ~(1<<7))<<8))
	
	if "additionalMetadata" in face.texture_data and face.texture_data.type & 128 > 0:
		%XShiftEdit.set_value_no_signal(face.texture_data.additionalMetadata.shiftTextureX)
		%XShiftEdit.get_line_edit().text = "%d" % face.texture_data.additionalMetadata.shiftTextureX
		%YShiftEdit.set_value_no_signal(face.texture_data.additionalMetadata.shiftTextureY)
		%YShiftEdit.get_line_edit().text = "%d" % face.texture_data.additionalMetadata.shiftTextureY
		%"0x0CEdit".text = str(face.texture_data.additionalMetadata.unk0x0C)
		%AdditionalCheckButton.set_pressed_no_signal(true)
		%XShiftEdit.editable = true
		%YShiftEdit.editable = true
		%"0x0CEdit".editable = true
	else:
		%XShiftEdit.get_line_edit().clear()
		%YShiftEdit.get_line_edit().clear()
		%"0x0CEdit".text = ""
		%AdditionalCheckButton.set_pressed_no_signal(false)
		%XShiftEdit.editable = false
		%YShiftEdit.editable = false
		%"0x0CEdit".editable = false
	
	
	%TopTextureOption.clear()
	%MidTextureOption.clear()
	%BottomTextureOption.clear()
	var das := await Roth.get_das(face.map_info.das)
	if face.texture_data.upperTextureIndex in das.mapping:
		%TopTextureOption.add_item( "%s:%s" % [das.mapping[face.texture_data.upperTextureIndex].index, das.mapping[face.texture_data.upperTextureIndex].name] )
	elif face.texture_data.upperTextureIndex == 65535:
		pass
	else:
		%TopTextureOption.add_item( "%d" % face.texture_data.upperTextureIndex )
	if face.texture_data.midTextureIndex in das.mapping:
		%MidTextureOption.add_item( "%s:%s" % [das.mapping[face.texture_data.midTextureIndex].index, das.mapping[face.texture_data.midTextureIndex].name] )
	elif face.texture_data.midTextureIndex == 65535:
		pass
	else:
		%MidTextureOption.add_item( "%d" % face.texture_data.midTextureIndex )
	if face.texture_data.lowerTextureIndex in das.mapping:
		%BottomTextureOption.add_item( "%s:%s" % [das.mapping[face.texture_data.lowerTextureIndex].index, das.mapping[face.texture_data.lowerTextureIndex].name] )
	elif face.texture_data.lowerTextureIndex == 65535:
		pass
	else:
		%BottomTextureOption.add_item( "%d" % face.texture_data.lowerTextureIndex )
	
	
	
	
	for each_face: Face in owner.selected_faces:
		if each_face.texture_data.unk0x08 & (1 << 0) > 0 != (face.texture_data.unk0x08 & (1 << 0) > 0):
			%TransparencyCheckBox.indeterminate = true
		if each_face.texture_data.unk0x08 & (1 << 1) > 0 != (face.texture_data.unk0x08 & (1 << 1) > 0):
			%FlipXCheckBox.indeterminate = true
		if each_face.texture_data.unk0x08 & (1 << 2) > 0 != (face.texture_data.unk0x08 & (1 << 2) > 0):
			%ImageFitCheckBox.indeterminate = true
		if each_face.texture_data.unk0x08 & (1 << 3) > 0 != (face.texture_data.unk0x08 & (1 << 3) > 0):
			%FixedSizeTransparencyCheckBox.indeterminate = true
		if each_face.texture_data.unk0x08 & (1 << 4) > 0 != (face.texture_data.unk0x08 & (1 << 4) > 0):
			%NoReflectCheckBox.indeterminate = true
		if each_face.texture_data.unk0x08 & (1 << 5) > 0 != (face.texture_data.unk0x08 & (1 << 5) > 0):
			%HalfPixelCheckBox.indeterminate = true
		if each_face.texture_data.unk0x08 & (1 << 6) > 0 != (face.texture_data.unk0x08 & (1 << 6) > 0):
			%EdgeMapCheckBox.indeterminate = true
		if each_face.texture_data.unk0x08 & (1 << 7) > 0 != (face.texture_data.unk0x08 & (1 << 7) > 0):
			%DrawFromBottomCheckBox.indeterminate = true
		if each_face.data.addCollision & (1 << 0) > 0 != (face.data.addCollision & (1 << 0) > 0):
			%StopWalkCheckBox.indeterminate = true
		if each_face.data.addCollision & (1 << 1) > 0 != (face.data.addCollision & (1 << 1) > 0):
			%StopAlenCheckBox.indeterminate = true
		if each_face.data.addCollision & (1 << 2) > 0 != (face.data.addCollision & (1 << 2) > 0):
			%Flag3CheckBox.indeterminate = true
		if each_face.data.addCollision & (1 << 3) > 0 != (face.data.addCollision & (1 << 3) > 0):
			%RoomBlkCheckBox.indeterminate = true
		if each_face.data.addCollision & (1 << 4) > 0 != (face.data.addCollision & (1 << 4) > 0):
			%Flag5CheckBox.indeterminate = true
		if each_face.data.addCollision & (1 << 5) > 0 != (face.data.addCollision & (1 << 5) > 0):
			%Flag6CheckBox.indeterminate = true
		if each_face.data.addCollision & (1 << 6) > 0 != (face.data.addCollision & (1 << 6) > 0):
			%Flag7CheckBox.indeterminate = true
		if each_face.data.addCollision & (1 << 7) > 0 != (face.data.addCollision & (1 << 7) > 0):
			%Flag8CheckBox.indeterminate = true
			
		if (each_face.texture_data.unk0x00 + ((face.texture_data.type & ~(1<<7))<<8)) != (face.texture_data.unk0x00 + ((face.texture_data.type & ~(1<<7))<<8)):
			%"Unk0x00+TypeEdit".get_line_edit().clear.call_deferred()
		if each_face.texture_data.upperTextureIndex != face.texture_data.upperTextureIndex:
			%TopTextureOption.clear()
		if each_face.texture_data.midTextureIndex != face.texture_data.midTextureIndex:
			%MidTextureOption.clear()
		if each_face.texture_data.lowerTextureIndex != face.texture_data.lowerTextureIndex:
			%BottomTextureOption.clear()
		
		if not "additionalMetadata" in each_face.texture_data or each_face.texture_data.type & 128 == 0:
			%XShiftEdit.get_line_edit().clear.call_deferred()
			%YShiftEdit.get_line_edit().clear.call_deferred()
			%"0x0CEdit".text = ""
			%XShiftEdit.editable = false
			%YShiftEdit.editable = false
			%"0x0CEdit".editable = false
			%AdditionalCheckButton.set_pressed_no_signal(false)
		elif "additionalMetadata" in face.texture_data:
			if each_face.texture_data.additionalMetadata.shiftTextureX != face.texture_data.additionalMetadata.shiftTextureX:
				%XShiftEdit.get_line_edit().clear.call_deferred()
			if each_face.texture_data.additionalMetadata.shiftTextureY != face.texture_data.additionalMetadata.shiftTextureY:
				%YShiftEdit.get_line_edit().clear.call_deferred()
			if each_face.texture_data.additionalMetadata.unk0x0C != face.texture_data.additionalMetadata.unk0x0C:
				%"0x0CEdit".text = ""
	
	%TopTextureOption.add_item("--------")
	%TopTextureOption.add_item("Sky")
	%TopTextureOption.add_item("Select Texture")
	%TopTextureOption.add_item("Select Palette")
	%MidTextureOption.add_item("--------")
	%MidTextureOption.add_item("Sky")
	%MidTextureOption.add_item("Select Texture")
	%MidTextureOption.add_item("Select Palette")
	%BottomTextureOption.add_item("--------")
	%BottomTextureOption.add_item("Sky")
	%BottomTextureOption.add_item("Select Texture")
	%BottomTextureOption.add_item("Select Palette")


func _on_bottom_texture_option_item_selected(index: int) -> void:
	if index == %BottomTextureOption.item_count - 1:
		var das: Dictionary = await Roth.get_das(owner.selected_faces[0].map_info.das)
		%Palette.show_palette(das.palette)
		%BottomTextureOption.select(0)
		var palette_index: int = await %Palette.color_selected
		if palette_index < 0:
			return
		for face: Face in owner.selected_faces:
			face.texture_data.lowerTextureIndex = palette_index + 32768
		update_selections(false)
		owner.redraw(owner.selected_faces)
		%EditFaceTimer.start()
	elif index == %BottomTextureOption.item_count - 2:
		var das: Dictionary = await Roth.get_das(owner.selected_faces[0].map_info.das)
		%Texture.show_texture(das)
		%BottomTextureOption.select(0)
		var texture_index: int = await %Texture.texture_selected
		if texture_index < 0:
			return
		for face: Face in owner.selected_faces:
			face.texture_data.lowerTextureIndex = texture_index
		update_selections(false)
		owner.redraw(owner.selected_faces)
		%EditFaceTimer.start()
	elif index == %BottomTextureOption.item_count - 3:
		for face: Face in owner.selected_faces:
			face.texture_data.lowerTextureIndex = Roth.get_map(face.map_info).metadata.skyTexture
		update_selections(false)
		owner.redraw(owner.selected_faces)
		%EditFaceTimer.start()
	elif index == %BottomTextureOption.item_count - 4:
		%BottomTextureOption.select(0)


func _on_mid_texture_option_item_selected(index: int) -> void:
	if index == %MidTextureOption.item_count - 1:
		var das: Dictionary = await Roth.get_das(owner.selected_faces[0].map_info.das)
		%Palette.show_palette(das.palette)
		%MidTextureOption.select(0)
		var palette_index: int = await %Palette.color_selected
		if palette_index < 0:
			return
		for face: Face in owner.selected_faces:
			face.texture_data.midTextureIndex = palette_index + 32768
		update_selections(false)
		owner.redraw(owner.selected_faces)
		%EditFaceTimer.start()
	elif index == %MidTextureOption.item_count - 2:
		var das: Dictionary = await Roth.get_das(owner.selected_faces[0].map_info.das)
		%Texture.show_texture(das, false, owner.selected_faces[0].texture_data.midTextureIndex)
		%MidTextureOption.select(0)
		var texture_index: int = await %Texture.texture_selected
		if texture_index < 0:
			return
		for face: Face in owner.selected_faces:
			face.texture_data.midTextureIndex = texture_index
		update_selections(false)
		owner.redraw(owner.selected_faces)
		%EditFaceTimer.start()
	elif index == %MidTextureOption.item_count - 3:
		for face: Face in owner.selected_faces:
			face.texture_data.midTextureIndex = Roth.get_map(face.map_info).metadata.skyTexture
		update_selections(false)
		owner.redraw(owner.selected_faces)
		%EditFaceTimer.start()
	elif index == %MidTextureOption.item_count - 4:
		%MidTextureOption.select(0)


func _on_top_texture_option_item_selected(index: int) -> void:
	if index == %TopTextureOption.item_count - 1:
		var das: Dictionary = await Roth.get_das(owner.selected_faces[0].map_info.das)
		%Palette.show_palette(das.palette)
		%TopTextureOption.select(0)
		var palette_index: int = await %Palette.color_selected
		if palette_index < 0:
			return
		for face: Face in owner.selected_faces:
			face.texture_data.upperTextureIndex = palette_index + 32768
		update_selections(false)
		owner.redraw(owner.selected_faces)
		%EditFaceTimer.start()
	elif index == %TopTextureOption.item_count - 2:
		var das: Dictionary = await Roth.get_das(owner.selected_faces[0].map_info.das)
		%Texture.show_texture(das)
		%TopTextureOption.select(0)
		var texture_index: int = await %Texture.texture_selected
		if texture_index < 0:
			return
		for face: Face in owner.selected_faces:
			face.texture_data.upperTextureIndex = texture_index
		update_selections(false)
		owner.redraw(owner.selected_faces)
		%EditFaceTimer.start()
	elif index == %TopTextureOption.item_count - 3:
		for face: Face in owner.selected_faces:
			face.texture_data.upperTextureIndex = Roth.get_map(face.map_info).metadata.skyTexture
		update_selections(false)
		owner.redraw(owner.selected_faces)
		%EditFaceTimer.start()
	elif index == %TopTextureOption.item_count - 4:
		%TopTextureOption.select(0)


func _on_transparency_check_box_toggled(toggled_on: bool) -> void:
	for face: Face in owner.selected_faces:
		if toggled_on:
			face.texture_data.unk0x08 |= (1 << 0)
		else:
			face.texture_data.unk0x08 &= ~(1 << 0)
	owner.redraw(owner.selected_faces)
	%EditFaceTimer.start()


func _on_flip_x_check_box_toggled(toggled_on: bool) -> void:
	for face: Face in owner.selected_faces:
		if toggled_on:
			face.texture_data.unk0x08 |= (1 << 1)
		else:
			face.texture_data.unk0x08 &= ~(1 << 1)
	owner.redraw(owner.selected_faces)
	%EditFaceTimer.start()


func _on_image_fit_check_box_toggled(toggled_on: bool) -> void:
	for face: Face in owner.selected_faces:
		if toggled_on:
			face.texture_data.unk0x08 |= (1 << 2)
		else:
			face.texture_data.unk0x08 &= ~(1 << 2)
	owner.redraw(owner.selected_faces)
	%EditFaceTimer.start()


func _on_fixed_size_transparency_check_box_toggled(toggled_on: bool) -> void:
	for face: Face in owner.selected_faces:
		if toggled_on:
			face.texture_data.unk0x08 |= (1 << 3)
		else:
			face.texture_data.unk0x08 &= ~(1 << 3)
	owner.redraw(owner.selected_faces)
	%EditFaceTimer.start()


func _on_no_reflect_check_box_toggled(toggled_on: bool) -> void:
	for face: Face in owner.selected_faces:
		if toggled_on:
			face.texture_data.unk0x08 |= (1 << 4)
		else:
			face.texture_data.unk0x08 &= ~(1 << 4)
	owner.redraw(owner.selected_faces)
	%EditFaceTimer.start()


func _on_half_pixel_check_box_toggled(toggled_on: bool) -> void:
	for face: Face in owner.selected_faces:
		if toggled_on:
			face.texture_data.unk0x08 |= (1 << 5)
		else:
			face.texture_data.unk0x08 &= ~(1 << 5)
	owner.redraw(owner.selected_faces)
	%EditFaceTimer.start()


func _on_edge_map_check_box_toggled(toggled_on: bool) -> void:
	for face: Face in owner.selected_faces:
		if toggled_on:
			face.texture_data.unk0x08 |= (1 << 6)
		else:
			face.texture_data.unk0x08 &= ~(1 << 6)
	owner.redraw(owner.selected_faces)
	%EditFaceTimer.start()


func _on_draw_from_bottom_check_box_toggled(toggled_on: bool) -> void:
	for face: Face in owner.selected_faces:
		if toggled_on:
			face.texture_data.unk0x08 |= (1 << 7)
		else:
			face.texture_data.unk0x08 &= ~(1 << 7)
	owner.redraw(owner.selected_faces)
	%EditFaceTimer.start()


func _on_stop_walk_check_box_toggled(toggled_on: bool) -> void:
	for face: Face in owner.selected_faces:
		if toggled_on:
			face.data.addCollision |= (1 << 0)
		else:
			face.data.addCollision &= ~(1 << 0)
	%EditFaceTimer.start()


func _on_stop_alen_check_box_toggled(toggled_on: bool) -> void:
	for face: Face in owner.selected_faces:
		if toggled_on:
			face.data.addCollision |= (1 << 1)
		else:
			face.data.addCollision &= ~(1 << 1)
	%EditFaceTimer.start()


func _on_flag_3_check_box_toggled(toggled_on: bool) -> void:
	for face: Face in owner.selected_faces:
		if toggled_on:
			face.data.addCollision |= (1 << 2)
		else:
			face.data.addCollision &= ~(1 << 2)
	%EditFaceTimer.start()


func _on_room_blk_check_box_toggled(toggled_on: bool) -> void:
	for face: Face in owner.selected_faces:
		if toggled_on:
			face.data.addCollision |= (1 << 3)
		else:
			face.data.addCollision &= ~(1 << 3)
	%EditFaceTimer.start()


func _on_flag_5_check_box_toggled(toggled_on: bool) -> void:
	for face: Face in owner.selected_faces:
		if toggled_on:
			face.data.addCollision |= (1 << 4)
		else:
			face.data.addCollision &= ~(1 << 4)
	%EditFaceTimer.start()


func _on_flag_6_check_box_toggled(toggled_on: bool) -> void:
	for face: Face in owner.selected_faces:
		if toggled_on:
			face.data.addCollision |= (1 << 5)
		else:
			face.data.addCollision &= ~(1 << 5)
	%EditFaceTimer.start()


func _on_flag_7_check_box_toggled(toggled_on: bool) -> void:
	for face: Face in owner.selected_faces:
		if toggled_on:
			face.data.addCollision |= (1 << 6)
		else:
			face.data.addCollision &= ~(1 << 6)
	%EditFaceTimer.start()


func _on_flag_8_check_box_toggled(toggled_on: bool) -> void:
	for face: Face in owner.selected_faces:
		if toggled_on:
			face.data.addCollision |= (1 << 7)
		else:
			face.data.addCollision &= ~(1 << 7)
	%EditFaceTimer.start()


func _on_additional_check_button_toggled(toggled_on: bool) -> void:
	for face: Face in owner.selected_faces:
		if toggled_on:
			if not "additionalMetadata" in face.texture_data:
				face.texture_data["additionalMetadata"] = {
					"shiftTextureX": 0,
					"shiftTextureY": 0,
					"unk0x0C": 0,
				}
			face.texture_data.type |= 0x80
			%XShiftEdit.editable = true
			%YShiftEdit.editable = true
			%"0x0CEdit".editable = true
		else:
			face.texture_data.type &= ~0x80
			%XShiftEdit.editable = false
			%YShiftEdit.editable = false
			%"0x0CEdit".editable = false
			#face.texture_data.additionalMetadata.shiftTextureX = 0
			#face.texture_data.additionalMetadata.shiftTextureY = 0
			#face.texture_data.additionalMetadata.unk0x0C = 0
	owner.redraw(owner.selected_faces)
	update_selections(false)
	%EditFaceTimer.start()


func _on_x_shift_edit_value_changed(value: float) -> void:
	for face: Face in owner.selected_faces:
		face.texture_data.additionalMetadata.shiftTextureX = int(value)
	owner.redraw(owner.selected_faces)
	%EditFaceTimer.start()


func _on_y_shift_edit_value_changed(value: float) -> void:
	for face: Face in owner.selected_faces:
		face.texture_data.additionalMetadata.shiftTextureY = int(value)
	owner.redraw(owner.selected_faces)
	%EditFaceTimer.start()


func _on_x_0c_edit_text_changed(new_text: String) -> void:
	for face: Face in owner.selected_faces:
		face.texture_data.additionalMetadata.unk0x0C = int(new_text)
	%EditFaceTimer.start()


func _on_unk_0x_00_type_edit_value_changed(value: float) -> void:
	for face: Face in owner.selected_faces:
		face.texture_data.unk0x00 = int(value) & 255
		face.texture_data.type = (int(value) >> 8) | (face.texture_data.type & (1<<7))
	owner.redraw(owner.selected_faces)
	%EditFaceTimer.start()


func _on_auto_button_pressed() -> void:
	for face: Face in owner.selected_faces:
		var value: int = int(ceil(face.face_length))
		face.texture_data.unk0x00 = int(value) & 255
		face.texture_data.type = (int(value) >> 8) | (face.texture_data.type & (1<<7))
		if len(owner.selected_faces) > 1:
			%"Unk0x00+TypeEdit".get_line_edit().clear()
		else:
			%"Unk0x00+TypeEdit".set_value_no_signal(face.texture_data.unk0x00 + ((face.texture_data.type & ~(1<<7))<<8))
			%"Unk0x00+TypeEdit".get_line_edit().text = "%d" % (face.texture_data.unk0x00 + ((face.texture_data.type & ~(1<<7))<<8))
		
	owner.redraw(owner.selected_faces)
	%EditFaceTimer.start()


func _on_select_sister_button_pressed() -> void:
	if owner.selected_faces[0] and owner.selected_faces[0].sister:
		owner.select_resource(owner.selected_faces[0].sister.get_ref())


func _on_select_sector_button_pressed() -> void:
	if owner.selected_faces[0]:
		owner.select_resource(owner.selected_faces[0].sector)


func _on_sister_edit_text_changed(new_text: String) -> void:
	for face: Face in owner.selected_faces:
		if new_text.is_empty():
			face.sister = null
			return
		var new_sister_index: int = int(new_text)
		if new_sister_index < 0 or new_sister_index >= len(Roth.get_map(face.map_info).faces):
			face.sister = null
			return
		var new_sister: Face = Roth.get_map(face.map_info).faces[new_sister_index]
		face.sister = weakref(new_sister)
	owner.redraw(owner.selected_faces)
	%EditFaceTimer.start()


func _on_flip_face_button_pressed() -> void:
	for face: Face in owner.selected_faces:
		var v1:Vector2 = Vector2(face.v1)
		face.v1 = Vector2(face.v2)
		face.v2 = v1
	owner.redraw(owner.selected_faces)
	%EditFaceTimer.start()


func _on_edit_face_timer_timeout() -> void:
	if last_selection_length == 1:
		Roth.editor_action.emit(owner.selected_faces[0].map_info, "Edit Face")
	elif last_selection_length > 1:
		Roth.editor_action.emit(owner.selected_faces[0].map_info, "Edit Faces")
