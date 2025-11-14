extends MarginContainer

var last_selection_length: int = -1


func clear() -> void:
	%ObjectIndexLabel.text = "Object:"
	%ObjectSectorIndexLabel.text = "Sector:"
	%ObjectXEdit.get_line_edit().clear()
	%ObjectYEdit.get_line_edit().clear()
	%ObjectZEdit.get_line_edit().clear()
	%ObjectRotationEdit.get_line_edit().clear()
	%ObjectTextureIndexEdit.get_line_edit().clear()
	%ObjectTextureSourceEdit.get_line_edit().clear()
	%ObjectLightingEdit.get_line_edit().clear()
	%ObjectUnk0x0CEdit.get_line_edit().clear()
	%ObjectUnk0x0EEdit.get_line_edit().clear()
	%TextureNameLabel.text = ""
	%TextureDescLabel.text = ""
	%ObjectTexture.texture = null
	%ObjectFlagButton1.set_pressed_no_signal(false)
	%ObjectFlagButton2.set_pressed_no_signal(false)
	%ObjectFlagButton3.set_pressed_no_signal(false)
	%ObjectFlagButton4.set_pressed_no_signal(false)
	%ObjectFlagButton5.set_pressed_no_signal(false)
	%ObjectFlagButton6.set_pressed_no_signal(false)
	%ObjectFlagButton7.set_pressed_no_signal(false)
	%ObjectFlagButton8.set_pressed_no_signal(false)
	%ObjectFlagButton1.indeterminate = false
	%ObjectFlagButton2.indeterminate = false
	%ObjectFlagButton3.indeterminate = false
	%ObjectFlagButton4.indeterminate = false
	%ObjectFlagButton5.indeterminate = false
	%ObjectFlagButton6.indeterminate = false
	%ObjectFlagButton7.indeterminate = false
	%ObjectFlagButton8.indeterminate = false
	%RenderDirectionalCheckBox.set_pressed_no_signal(true)
	%RenderBillboardCheckBox.set_pressed_no_signal(false)
	%RenderStyleLabel.text = "Render Style"
	%EditObjectContainer.hide()
	last_selection_length = 0


func update_selections() -> void:
	clear()
	if len(owner.selected_objects) == 0:
		return
	
	%EditObjectContainer.show()
	last_selection_length = len(owner.selected_objects)
	var object: ObjectRoth = owner.selected_objects[0]
	
	if len(owner.selected_objects) == 1:
		%ObjectIndexLabel.text = "Object: %d" % object.index
		%ObjectSectorIndexLabel.show()
		%ObjectSectorIndexLabel.text = "Sector: %d" % object.sector.get_ref().index
	
	elif len(owner.selected_objects) > 1:
		%ObjectIndexLabel.text = "Object: %d Selected" % len(owner.selected_objects)
		%ObjectSectorIndexLabel.hide()
	
	
	%ObjectXEdit.get_line_edit().text = "%d" % object.data.posX
	%ObjectXEdit.set_value_no_signal(object.data.posX)
	%ObjectYEdit.get_line_edit().text = "%d" % object.data.posY
	%ObjectYEdit.set_value_no_signal(object.data.posY)
	%ObjectZEdit.get_line_edit().text = "%d" % object.data.posZ
	%ObjectZEdit.set_value_no_signal(object.data.posZ)
	%ObjectRotationEdit.get_line_edit().text = "%d" % object.data.rotation
	%ObjectRotationEdit.set_value_no_signal(object.data.rotation)
	%ObjectTextureIndexEdit.get_line_edit().text = "%d" % object.data.textureIndex
	%ObjectTextureIndexEdit.set_value_no_signal(object.data.textureIndex)
	%ObjectTextureSourceEdit.get_line_edit().text = "%d" % object.data.textureSource
	%ObjectTextureSourceEdit.set_value_no_signal(object.data.textureSource)
	%ObjectLightingEdit.get_line_edit().text = "%d" % object.data.lighting
	%ObjectLightingEdit.set_value_no_signal(object.data.lighting)
	%ObjectUnk0x0CEdit.get_line_edit().text = "%d" % object.data.unk0x0C
	%ObjectUnk0x0CEdit.set_value_no_signal(object.data.unk0x0C)
	%ObjectUnk0x0EEdit.get_line_edit().text = "%d" % object.data.unk0x0E
	%ObjectUnk0x0EEdit.set_value_no_signal(object.data.unk0x0E)
	%ObjectFlagButton1.set_pressed_no_signal((object.data.unk0x07 & (1<<0)) > 0)
	%ObjectFlagButton2.set_pressed_no_signal((object.data.unk0x07 & (1<<1)) > 0)
	%ObjectFlagButton3.set_pressed_no_signal((object.data.unk0x07 & (1<<2)) > 0)
	%ObjectFlagButton4.set_pressed_no_signal((object.data.unk0x07 & (1<<3)) > 0)
	%ObjectFlagButton5.set_pressed_no_signal((object.data.unk0x07 & (1<<4)) > 0)
	%ObjectFlagButton6.set_pressed_no_signal((object.data.unk0x07 & (1<<5)) > 0)
	%ObjectFlagButton7.set_pressed_no_signal((object.data.unk0x07 & (1<<6)) > 0)
	%ObjectFlagButton8.set_pressed_no_signal((object.data.unk0x07 & (1<<7)) > 0)
	
	if (object.data.renderType & (1<<7)) > 0:
		%RenderBillboardCheckBox.set_pressed_no_signal(false)
		%RenderDirectionalCheckBox.set_pressed_no_signal(true)
	else:
		%RenderBillboardCheckBox.set_pressed_no_signal(true)
		%RenderDirectionalCheckBox.set_pressed_no_signal(false)
	if (object.data.unk0x07 & (1<<0)) > 0:
		%RenderStyleLabel.text = "Collision Style"
	else:
		%RenderStyleLabel.text = "Render Style"
	
	update_texture(object)
	
	
	for each_object: ObjectRoth in owner.selected_objects:
		if each_object.data.posX != object.data.posX:
			%ObjectXEdit.get_line_edit().clear.call_deferred()
		if each_object.data.posY != object.data.posY:
			%ObjectYEdit.get_line_edit().clear.call_deferred()
		if each_object.data.posZ != object.data.posZ:
			%ObjectZEdit.get_line_edit().clear.call_deferred()
		if each_object.data.rotation != object.data.rotation:
			%ObjectRotationEdit.get_line_edit().clear.call_deferred()
		if each_object.data.textureIndex != object.data.textureIndex:
			%ObjectTextureIndexEdit.get_line_edit().clear.call_deferred()
			%TextureNameLabel.text = ""
			%TextureDescLabel.text = ""
			%ObjectTexture.texture = null
		if each_object.data.textureSource != object.data.textureSource:
			%ObjectTextureSourceEdit.get_line_edit().clear.call_deferred()
			%TextureNameLabel.text = ""
			%TextureDescLabel.text = ""
			%ObjectTexture.texture = null
		if each_object.data.lighting != object.data.lighting:
			%ObjectLightingEdit.get_line_edit().clear.call_deferred()
		if each_object.data.unk0x0C != object.data.unk0x0C:
			%ObjectUnk0x0CEdit.get_line_edit().clear.call_deferred()
		if each_object.data.unk0x0E != object.data.unk0x0E:
			%ObjectUnk0x0EEdit.get_line_edit().clear.call_deferred()
		if ((each_object.data.renderType & (1<<7)) > 0) != ((object.data.renderType & (1<<7)) > 0):
			%RenderBillboardCheckBox.set_pressed_no_signal(false)
			%RenderDirectionalCheckBox.set_pressed_no_signal(false)
		if ((each_object.data.unk0x07 & (1<<0)) > 0) != ((object.data.unk0x07 & (1<<0)) > 0):
			%ObjectFlagButton1.indeterminate = true
		if ((each_object.data.unk0x07 & (1<<1)) > 0) != ((object.data.unk0x07 & (1<<1)) > 0):
			%ObjectFlagButton2.indeterminate = true
		if ((each_object.data.unk0x07 & (1<<2)) > 0) != ((object.data.unk0x07 & (1<<2)) > 0):
			%ObjectFlagButton3.indeterminate = true
		if ((each_object.data.unk0x07 & (1<<3)) > 0) != ((object.data.unk0x07 & (1<<3)) > 0):
			%ObjectFlagButton4.indeterminate = true
		if ((each_object.data.unk0x07 & (1<<4)) > 0) != ((object.data.unk0x07 & (1<<4)) > 0):
			%ObjectFlagButton5.indeterminate = true
		if ((each_object.data.unk0x07 & (1<<5)) > 0) != ((object.data.unk0x07 & (1<<5)) > 0):
			%ObjectFlagButton6.indeterminate = true
		if ((each_object.data.unk0x07 & (1<<6)) > 0) != ((object.data.unk0x07 & (1<<6)) > 0):
			%ObjectFlagButton7.indeterminate = true
		if ((each_object.data.unk0x07 & (1<<7)) > 0) != ((object.data.unk0x07 & (1<<7)) > 0):
			%ObjectFlagButton8.indeterminate = true


func update_texture(object: ObjectRoth) -> void:
	var object_das: String = ""
	var object_index: int = -1
	if object.data.textureSource == 0:
		object_das = object.map_info.das
		object_index = object.data.textureIndex + 4096
	elif object.data.textureSource == 1:
		object_das = object.map_info.das
		object_index = object.data.textureIndex + 4096 + 256
	elif object.data.textureSource == 2:
		object_das = "M/ADEMO.DAS"
		object_index = object.data.textureIndex
	elif object.data.textureSource == 3:
		object_das = "M/ADEMO.DAS"
		object_index = object.data.textureIndex + 256
	else:
		%TextureNameLabel.text = "Invalid Source"
		%TextureDescLabel.text = ""
		%ObjectTexture.texture = null
		return
	var texture := Roth.get_index_from_das(object_index, object_das)
	if texture:
		%TextureNameLabel.text = texture.name
		%TextureDescLabel.text = texture.desc
		if "image" in texture:
			if typeof(texture.image) == TYPE_ARRAY:
				%ObjectTexture.texture = texture.image[0]
			else:
				%ObjectTexture.texture = texture.image
		else:
			%ObjectTexture.texture = null
	else:
		%TextureNameLabel.text = "Invalid Index/Source"
		%TextureDescLabel.text = ""
		%ObjectTexture.texture = null


func _on_object_x_edit_value_changed(value: float) -> void:
	for object: ObjectRoth in owner.selected_objects:
		object.data.posX = value
	owner.redraw(owner.selected_objects)
	%EditObjectTimer.start()


func _on_object_y_edit_value_changed(value: float) -> void:
	for object: ObjectRoth in owner.selected_objects:
		object.data.posY = value
	owner.redraw(owner.selected_objects)
	%EditObjectTimer.start()


func _on_object_z_edit_value_changed(value: float) -> void:
	for object: ObjectRoth in owner.selected_objects:
		object.data.posZ = value
	owner.redraw(owner.selected_objects)
	%EditObjectTimer.start()


func _on_object_rotation_edit_value_changed(value: float) -> void:
	for object: ObjectRoth in owner.selected_objects:
		object.data.rotation = value
	owner.redraw(owner.selected_objects)
	%EditObjectTimer.start()


func _on_object_texture_index_edit_value_changed(value: float) -> void:
	var i: int = 0
	for object: ObjectRoth in owner.selected_objects:
		object.data.textureIndex = value
		if i == 0:
			update_texture(object)
			i += 1
	owner.redraw(owner.selected_objects)
	%EditObjectTimer.start()


func _on_object_texture_source_edit_value_changed(value: float) -> void:
	var i: int = 0
	for object: ObjectRoth in owner.selected_objects:
		object.data.textureSource = value
		if i == 0:
			update_texture(object)
			i += 1
	owner.redraw(owner.selected_objects)
	%EditObjectTimer.start()


func _on_object_lighting_edit_value_changed(value: float) -> void:
	for object: ObjectRoth in owner.selected_objects:
		object.data.lighting = value
	%EditObjectTimer.start()


func _on_object_render_type_edit_value_changed(value: float) -> void:
	for object: ObjectRoth in owner.selected_objects:
		object.data.renderType = value
	%EditObjectTimer.start()


func _on_object_unk_0x_0c_edit_value_changed(value: float) -> void:
	for object: ObjectRoth in owner.selected_objects:
		object.data.unk0x0C = value
	%EditObjectTimer.start()


func _on_object_unk_0x_0e_edit_value_changed(value: float) -> void:
	for object: ObjectRoth in owner.selected_objects:
		object.data.unk0x0E = value
	%EditObjectTimer.start()


func _on_object_flag_button_1_toggled(toggled_on: bool) -> void:
	for object: ObjectRoth in owner.selected_objects:
		if toggled_on:
			object.data.unk0x07 |= (1 << 0)
			%RenderStyleLabel.text = "Collision Style"
		else:
			object.data.unk0x07 &= ~(1 << 0)
			%RenderStyleLabel.text = "Render Style"
	%EditObjectTimer.start()


func _on_object_flag_button_2_toggled(toggled_on: bool) -> void:
	for object: ObjectRoth in owner.selected_objects:
		if toggled_on:
			object.data.unk0x07 |= (1 << 1)
		else:
			object.data.unk0x07 &= ~(1 << 1)
	%EditObjectTimer.start()


func _on_object_flag_button_3_toggled(toggled_on: bool) -> void:
	for object: ObjectRoth in owner.selected_objects:
		if toggled_on:
			object.data.unk0x07 |= (1 << 2)
		else:
			object.data.unk0x07 &= ~(1 << 2)
	%EditObjectTimer.start()


func _on_object_flag_button_4_toggled(toggled_on: bool) -> void:
	for object: ObjectRoth in owner.selected_objects:
		if toggled_on:
			object.data.unk0x07 |= (1 << 3)
		else:
			object.data.unk0x07 &= ~(1 << 3)
	%EditObjectTimer.start()


func _on_object_flag_button_5_toggled(toggled_on: bool) -> void:
	for object: ObjectRoth in owner.selected_objects:
		if toggled_on:
			object.data.unk0x07 |= (1 << 4)
		else:
			object.data.unk0x07 &= ~(1 << 4)
	owner.redraw(owner.selected_objects)
	%EditObjectTimer.start()


func _on_object_flag_button_6_toggled(toggled_on: bool) -> void:
	for object: ObjectRoth in owner.selected_objects:
		if toggled_on:
			object.data.unk0x07 |= (1 << 5)
		else:
			object.data.unk0x07 &= ~(1 << 5)
	%EditObjectTimer.start()


func _on_object_flag_button_7_toggled(toggled_on: bool) -> void:
	for object: ObjectRoth in owner.selected_objects:
		if toggled_on:
			object.data.unk0x07 |= (1 << 6)
		else:
			object.data.unk0x07 &= ~(1 << 6)
	%EditObjectTimer.start()


func _on_object_flag_button_8_toggled(toggled_on: bool) -> void:
	for object: ObjectRoth in owner.selected_objects:
		if toggled_on:
			object.data.unk0x07 |= (1 << 7)
		else:
			object.data.unk0x07 &= ~(1 << 7)
	%EditObjectTimer.start()


func _on_render_directional_check_box_toggled(toggled_on: bool) -> void:
	if not toggled_on:
		return
	for object: ObjectRoth in owner.selected_objects:
		if toggled_on:
			object.data.renderType |= (1 << 7)
	owner.redraw(owner.selected_objects)
	%EditObjectTimer.start()


func _on_render_billboard_check_box_toggled(toggled_on: bool) -> void:
	if not toggled_on:
		return
	for object: ObjectRoth in owner.selected_objects:
		if toggled_on:
			object.data.renderType &= ~(1 << 7)
	owner.redraw(owner.selected_objects)
	%EditObjectTimer.start()


func _on_browse_objects_button_pressed() -> void:
	var new_object: Dictionary = await %ObjectSelection.wait_for_object_selection(owner.selected_objects[0].map_info.das)
	if new_object.is_empty():
		return
	var i: int = 0
	for object: ObjectRoth in owner.selected_objects:
		var source := 0
		var index := 0
		if new_object.das.get_file().get_basename() == "ADEMO":
			source = 2
			index = object.index
			if new_object.index >= 256:
				source = 3
				index -= 256
		else:
			source = 0
			index = new_object.index - 4096
			if new_object.index >= 4352:
				source = 1
				index -= 256
		object.data.textureIndex = index
		object.data.textureSource = source
		if i == 0:
			update_texture(object)
			i += 1
	owner.redraw(owner.selected_objects)
	%EditObjectTimer.start()


func _on_edit_object_timer_timeout() -> void:
	if last_selection_length == 1:
		Roth.editor_action.emit(owner.selected_objects[0].map_info, "Edit Object")
	elif last_selection_length > 1:
		Roth.editor_action.emit(owner.selected_objects[0].map_info, "Edit Objects")
