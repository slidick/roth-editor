extends MarginContainer

var current_face: Face


func _reset_edit_face() -> void:
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
	%Unk0x00Edit.get_line_edit().clear()
	%TypeEdit.get_line_edit().clear()
	%"Unk0x00+TypeEdit".get_line_edit().clear()
	%StopWalkCheckBox.set_pressed_no_signal(false)
	%StopAlenCheckBox.set_pressed_no_signal(false)
	%Flag3CheckBox.set_pressed_no_signal(false)
	%RoomBlkCheckBox.set_pressed_no_signal(false)
	%Flag5CheckBox.set_pressed_no_signal(false)
	%Flag6CheckBox.set_pressed_no_signal(false)
	%Flag7CheckBox.set_pressed_no_signal(false)
	%Flag8CheckBox.set_pressed_no_signal(false)
	%SelectSisterButton.hide()
	%SisterEdit.text = ""
	#%EditSisterContainer.hide()
	%EditFaceContainer.show()


func load_edit_face(p_face: Face) -> void:
	_reset_edit_face()
	current_face = p_face
	%FaceIndexLabel.text = "Face: %d" % current_face.index
	if current_face.texture_data.unk0x08 & (1 << 0) > 0:
		%TransparencyCheckBox.set_pressed_no_signal(true)
	if current_face.texture_data.unk0x08 & (1 << 1) > 0:
		%FlipXCheckBox.set_pressed_no_signal(true)
	if current_face.texture_data.unk0x08 & (1 << 2) > 0:
		%ImageFitCheckBox.set_pressed_no_signal(true)
	if current_face.texture_data.unk0x08 & (1 << 3) > 0:
		%FixedSizeTransparencyCheckBox.set_pressed_no_signal(true)
	if current_face.texture_data.unk0x08 & (1 << 4) > 0:
		%NoReflectCheckBox.set_pressed_no_signal(true)
	if current_face.texture_data.unk0x08 & (1 << 5) > 0:
		%HalfPixelCheckBox.set_pressed_no_signal(true)
	if current_face.texture_data.unk0x08 & (1 << 6) > 0:
		%EdgeMapCheckBox.set_pressed_no_signal(true)
	if current_face.texture_data.unk0x08 & (1 << 7) > 0:
		%DrawFromBottomCheckBox.set_pressed_no_signal(true)
	
	if current_face.data.addCollision & (1 << 0) > 0:
		%StopWalkCheckBox.set_pressed_no_signal(true)
	if current_face.data.addCollision & (1 << 1) > 0:
		%StopAlenCheckBox.set_pressed_no_signal(true)
	if current_face.data.addCollision & (1 << 2) > 0:
		%Flag3CheckBox.set_pressed_no_signal(true)
	if current_face.data.addCollision & (1 << 3) > 0:
		%RoomBlkCheckBox.set_pressed_no_signal(true)
	if current_face.data.addCollision & (1 << 4) > 0:
		%Flag5CheckBox.set_pressed_no_signal(true)
	if current_face.data.addCollision & (1 << 5) > 0:
		%Flag6CheckBox.set_pressed_no_signal(true)
	if current_face.data.addCollision & (1 << 6) > 0:
		%Flag7CheckBox.set_pressed_no_signal(true)
	if current_face.data.addCollision & (1 << 7) > 0:
		%Flag8CheckBox.set_pressed_no_signal(true)
	
	
	%Unk0x00Edit.set_value_no_signal(current_face.texture_data.unk0x00)
	%Unk0x00Edit.get_line_edit().text = "%d" % current_face.texture_data.unk0x00
	%TypeEdit.set_value_no_signal(current_face.texture_data.type)
	%TypeEdit.get_line_edit().text = "%d" % current_face.texture_data.type
	%"Unk0x00+TypeEdit".set_value_no_signal(current_face.texture_data.unk0x00 + ((current_face.texture_data.type & ~(1<<7))<<8))
	%"Unk0x00+TypeEdit".get_line_edit().text = "%d" % (current_face.texture_data.unk0x00 + ((current_face.texture_data.type & ~(1<<7))<<8))
	
	if "additionalMetadata" in current_face.texture_data and current_face.texture_data.type & 128 > 0:
		%XShiftEdit.set_value_no_signal(current_face.texture_data.additionalMetadata.shiftTextureX)
		%XShiftEdit.get_line_edit().text = "%d" % current_face.texture_data.additionalMetadata.shiftTextureX
		%YShiftEdit.set_value_no_signal(current_face.texture_data.additionalMetadata.shiftTextureY)
		%YShiftEdit.get_line_edit().text = "%d" % current_face.texture_data.additionalMetadata.shiftTextureY
		%"0x0CEdit".text = str(current_face.texture_data.additionalMetadata.unk0x0C)
		%AdditionalCheckButton.set_pressed_no_signal(true)
		%XShiftEdit.editable = true
		%YShiftEdit.editable = true
		%"0x0CEdit".editable = true
	else:
		%XShiftEdit.set_value_no_signal(0)
		%XShiftEdit.get_line_edit().text = "0"
		%YShiftEdit.set_value_no_signal(0)
		%YShiftEdit.get_line_edit().text = "0"
		%"0x0CEdit".text = str(0)
		%AdditionalCheckButton.set_pressed_no_signal(false)
		%XShiftEdit.editable = false
		%YShiftEdit.editable = false
		%"0x0CEdit".editable = false
		
	var das := await Roth.get_das(current_face.map_info.das)
	if current_face.texture_data.upperTextureIndex in das.mapping:
		%TopTextureOption.add_item( "%s:%s" % [das.mapping[current_face.texture_data.upperTextureIndex].index, das.mapping[current_face.texture_data.upperTextureIndex].name] )
	elif current_face.texture_data.upperTextureIndex == 65535:
		pass
	else:
		%TopTextureOption.add_item( "%d" % current_face.texture_data.upperTextureIndex )
	if current_face.texture_data.midTextureIndex in das.mapping:
		%MidTextureOption.add_item( "%s:%s" % [das.mapping[current_face.texture_data.midTextureIndex].index, das.mapping[current_face.texture_data.midTextureIndex].name] )
	elif current_face.texture_data.midTextureIndex == 65535:
		pass
	else:
		%MidTextureOption.add_item( "%d" % current_face.texture_data.midTextureIndex )
	if current_face.texture_data.lowerTextureIndex in das.mapping:
		%BottomTextureOption.add_item( "%s:%s" % [das.mapping[current_face.texture_data.lowerTextureIndex].index, das.mapping[current_face.texture_data.lowerTextureIndex].name] )
	elif current_face.texture_data.lowerTextureIndex == 65535:
		pass
	else:
		%BottomTextureOption.add_item( "%d" % current_face.texture_data.lowerTextureIndex )
	
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
	
	if current_face.sister:
		%SelectSisterButton.show()
		%SisterEdit.text = "%d" % current_face.sister.get_ref().index
		#%EditSisterContainer.show()


func _on_bottom_texture_option_item_selected(index: int) -> void:
	if index == %BottomTextureOption.item_count - 1:
		var das: Dictionary = await Roth.get_das(current_face.map_info.das)
		%Palette.show_palette(das.palette)
		%BottomTextureOption.select(0)
		var palette_index: int = await %Palette.color_selected
		if palette_index < 0:
			return
		current_face.texture_data.lowerTextureIndex = palette_index + 32768
		load_edit_face(current_face)
		%Picker.redraw_selected_node()
	elif index == %BottomTextureOption.item_count - 2:
		var das: Dictionary = await Roth.get_das(current_face.map_info.das)
		%Texture.show_texture(das)
		%BottomTextureOption.select(0)
		var texture_index: int = await %Texture.texture_selected
		if texture_index < 0:
			return
		current_face.texture_data.lowerTextureIndex = texture_index
		load_edit_face(current_face)
		%Picker.redraw_selected_node()
	elif index == %BottomTextureOption.item_count - 3:
		current_face.texture_data.lowerTextureIndex = Roth.get_map(current_face.map_info).metadata.skyTexture
		load_edit_face(current_face)
		%Picker.redraw_selected_node()
	elif index == %BottomTextureOption.item_count - 4:
		%BottomTextureOption.select(0)


func _on_mid_texture_option_item_selected(index: int) -> void:
	if index == %MidTextureOption.item_count - 1:
		var das: Dictionary = await Roth.get_das(current_face.map_info.das)
		%Palette.show_palette(das.palette)
		%MidTextureOption.select(0)
		var palette_index: int = await %Palette.color_selected
		if palette_index < 0:
			return
		current_face.texture_data.midTextureIndex = palette_index + 32768
		load_edit_face(current_face)
		%Picker.redraw_selected_node()
	elif index == %MidTextureOption.item_count - 2:
		var das: Dictionary = await Roth.get_das(current_face.map_info.das)
		%Texture.show_texture(das)
		%MidTextureOption.select(0)
		var texture_index: int = await %Texture.texture_selected
		if texture_index < 0:
			return
		current_face.texture_data.midTextureIndex = texture_index
		load_edit_face(current_face)
		%Picker.redraw_selected_node()
	elif index == %MidTextureOption.item_count - 3:
		current_face.texture_data.midTextureIndex = Roth.get_map(current_face.map_info).metadata.skyTexture
		load_edit_face(current_face)
		%Picker.redraw_selected_node()
	elif index == %MidTextureOption.item_count - 4:
		%MidTextureOption.select(0)


func _on_top_texture_option_item_selected(index: int) -> void:
	if index == %TopTextureOption.item_count - 1:
		var das: Dictionary = await Roth.get_das(current_face.map_info.das)
		%Palette.show_palette(das.palette)
		%TopTextureOption.select(0)
		var palette_index: int = await %Palette.color_selected
		if palette_index < 0:
			return
		current_face.texture_data.upperTextureIndex = palette_index + 32768
		load_edit_face(current_face)
		%Picker.redraw_selected_node()
	elif index == %TopTextureOption.item_count - 2:
		var das: Dictionary = await Roth.get_das(current_face.map_info.das)
		%Texture.show_texture(das)
		%TopTextureOption.select(0)
		var texture_index: int = await %Texture.texture_selected
		if texture_index < 0:
			return
		current_face.texture_data.upperTextureIndex = texture_index
		load_edit_face(current_face)
		%Picker.redraw_selected_node()
	elif index == %TopTextureOption.item_count - 3:
		current_face.texture_data.upperTextureIndex = Roth.get_map(current_face.map_info).metadata.skyTexture
		load_edit_face(current_face)
		%Picker.redraw_selected_node()
	elif index == %TopTextureOption.item_count - 4:
		%TopTextureOption.select(0)


func _on_transparency_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		current_face.texture_data.unk0x08 |= (1 << 0)
	else:
		current_face.texture_data.unk0x08 &= ~(1 << 0)
	%Picker.redraw_selected_node()


func _on_flip_x_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		current_face.texture_data.unk0x08 |= (1 << 1)
	else:
		current_face.texture_data.unk0x08 &= ~(1 << 1)
	%Picker.redraw_selected_node()


func _on_image_fit_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		current_face.texture_data.unk0x08 |= (1 << 2)
	else:
		current_face.texture_data.unk0x08 &= ~(1 << 2)
	%Picker.redraw_selected_node()


func _on_fixed_size_transparency_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		current_face.texture_data.unk0x08 |= (1 << 3)
	else:
		current_face.texture_data.unk0x08 &= ~(1 << 3)
	%Picker.redraw_selected_node()


func _on_no_reflect_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		current_face.texture_data.unk0x08 |= (1 << 4)
	else:
		current_face.texture_data.unk0x08 &= ~(1 << 4)
	%Picker.redraw_selected_node()


func _on_half_pixel_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		current_face.texture_data.unk0x08 |= (1 << 5)
	else:
		current_face.texture_data.unk0x08 &= ~(1 << 5)
	%Picker.redraw_selected_node()


func _on_edge_map_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		current_face.texture_data.unk0x08 |= (1 << 6)
	else:
		current_face.texture_data.unk0x08 &= ~(1 << 6)
	%Picker.redraw_selected_node()


func _on_draw_from_bottom_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		current_face.texture_data.unk0x08 |= (1 << 7)
	else:
		current_face.texture_data.unk0x08 &= ~(1 << 7)
	%Picker.redraw_selected_node()


func _on_stop_walk_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		current_face.data.addCollision |= (1 << 0)
	else:
		current_face.data.addCollision &= ~(1 << 0)


func _on_stop_alen_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		current_face.data.addCollision |= (1 << 1)
	else:
		current_face.data.addCollision &= ~(1 << 1)


func _on_flag_3_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		current_face.data.addCollision |= (1 << 2)
	else:
		current_face.data.addCollision &= ~(1 << 2)


func _on_room_blk_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		current_face.data.addCollision |= (1 << 3)
	else:
		current_face.data.addCollision &= ~(1 << 3)


func _on_flag_5_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		current_face.data.addCollision |= (1 << 4)
	else:
		current_face.data.addCollision &= ~(1 << 4)


func _on_flag_6_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		current_face.data.addCollision |= (1 << 5)
	else:
		current_face.data.addCollision &= ~(1 << 5)


func _on_flag_7_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		current_face.data.addCollision |= (1 << 6)
	else:
		current_face.data.addCollision &= ~(1 << 6)


func _on_flag_8_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		current_face.data.addCollision |= (1 << 7)
	else:
		current_face.data.addCollision &= ~(1 << 7)


func _on_additional_check_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		if not "additionalMetadata" in current_face.texture_data:
			current_face.texture_data["additionalMetadata"] = {
				"shiftTextureX": 0,
				"shiftTextureY": 0,
				"unk0x0C": 0,
			}
		current_face.texture_data.type += 0x80
		%XShiftEdit.editable = true
		%YShiftEdit.editable = true
		%"0x0CEdit".editable = true
	else:
		current_face.texture_data.type -= 0x80
		%XShiftEdit.editable = false
		%YShiftEdit.editable = false
		%"0x0CEdit".editable = false
		current_face.texture_data.additionalMetadata.shiftTextureX = 0
		current_face.texture_data.additionalMetadata.shiftTextureY = 0
		current_face.texture_data.additionalMetadata.unk0x0C = 0
		%Picker.redraw_selected_node()


func _on_x_shift_edit_value_changed(value: float) -> void:
	current_face.texture_data.additionalMetadata.shiftTextureX = int(value)
	var caret: int = %XShiftEdit.get_line_edit().caret_column
	await %Picker.redraw_selected_node()
	%XShiftEdit.get_line_edit().grab_focus()
	await get_tree().process_frame
	%XShiftEdit.get_line_edit().caret_column = caret


func _on_y_shift_edit_value_changed(value: float) -> void:
	current_face.texture_data.additionalMetadata.shiftTextureY = int(value)
	var caret: int = %YShiftEdit.get_line_edit().caret_column
	await %Picker.redraw_selected_node()
	%YShiftEdit.get_line_edit().grab_focus()
	await get_tree().process_frame
	%YShiftEdit.get_line_edit().caret_column = caret


func _on_x_0c_edit_text_changed(new_text: String) -> void:
	current_face.texture_data.additionalMetadata.unk0x0C = int(new_text)


func _on_unk_0x_00_edit_value_changed(value: float) -> void:
	current_face.texture_data.unk0x00 = int(value)


func _on_type_edit_value_changed(value: float) -> void:
	current_face.texture_data.type = int(value)


func _on_unk_0x_00_type_edit_value_changed(value: float) -> void:
	current_face.texture_data.unk0x00 = int(value) & 255
	current_face.texture_data.type = (int(value) >> 8) | (current_face.texture_data.type & (1<<7))
	var caret: int = %"Unk0x00+TypeEdit".get_line_edit().caret_column
	await %Picker.redraw_selected_node()
	%"Unk0x00+TypeEdit".get_line_edit().grab_focus()
	await get_tree().process_frame
	%"Unk0x00+TypeEdit".get_line_edit().caret_column = caret


func _on_auto_button_pressed() -> void:
	_on_unk_0x_00_type_edit_value_changed(int(ceil(current_face.face_length)))


func _on_select_sister_button_pressed() -> void:
	if current_face and current_face.sister:
		%Picker.select(current_face.sister.get_ref().node, true)


func _on_select_sector_button_pressed() -> void:
	if current_face:
		%Picker.select(current_face.sector.node, true)


func _on_sister_edit_text_changed(new_text: String) -> void:
	var new_sister: Variant = owner.get_face(int(new_text), "Face", current_face.map_info)
	current_face.sister = weakref(new_sister)


func _on_flip_face_button_pressed() -> void:
	var v1:Vector2 = Vector2(current_face.v1)
	current_face.v1 = Vector2(current_face.v2)
	current_face.v2 = v1
	%Picker.redraw_selected_node()


func _on_face_debug_button_pressed() -> void:
	#print(current_face.texture_data)
	Das._get_index_from_das(current_face.texture_data.midTextureIndex, current_face.map_info.das)
