extends MarginContainer

var current_object: ObjectRoth
var object_das: String
var object_index: int

func _redraw_object(node: Variant = null) -> void:
	var caret: int = 0
	if node:
		caret = node.get_line_edit().caret_column
	current_object.initialize_mesh()
	await get_tree().process_frame
	%Picker.select(current_object.node)
	%Map2D.redraw_object(current_object)
	if node:
		node.get_line_edit().grab_focus()
		await get_tree().process_frame
		node.get_line_edit().caret_column = caret


func _reset_edit_object() -> void:
	%ObjectXEdit.get_line_edit().clear()
	%ObjectYEdit.get_line_edit().clear()
	%ObjectZEdit.get_line_edit().clear()
	%ObjectRotationEdit.get_line_edit().clear()
	%ObjectTextureIndexEdit.get_line_edit().clear()
	%ObjectTextureSourceEdit.get_line_edit().clear()
	%ObjectUnk0x07Edit.get_line_edit().clear()
	%ObjectLightingEdit.get_line_edit().clear()
	%ObjectRenderTypeEdit.get_line_edit().clear()
	%ObjectUnk0x0CEdit.get_line_edit().clear()
	%ObjectUnk0x0EEdit.get_line_edit().clear()
	%TextureNameLabel.text = ""
	%TextureDescLabel.text = ""
	%ObjectTexture.texture = null
	%EditObjectContainer.show()


func load_edit_object(object: ObjectRoth.ObjectMesh3D) -> void:
	_reset_edit_object()
	current_object = object.ref
	%ObjectIndexLabel.text = "Object: %d" % object.ref.index
	%ObjectXEdit.get_line_edit().text = "%d" % object.ref.data.posX
	%ObjectXEdit.set_value_no_signal(object.ref.data.posX)
	%ObjectYEdit.get_line_edit().text = "%d" % object.ref.data.posY
	%ObjectYEdit.set_value_no_signal(object.ref.data.posY)
	%ObjectZEdit.get_line_edit().text = "%d" % object.ref.data.posZ
	%ObjectZEdit.set_value_no_signal(object.ref.data.posZ)
	%ObjectRotationEdit.get_line_edit().text = "%d" % object.ref.data.rotation
	%ObjectRotationEdit.set_value_no_signal(object.ref.data.rotation)
	%ObjectTextureIndexEdit.get_line_edit().text = "%d" % object.ref.data.textureIndex
	%ObjectTextureIndexEdit.set_value_no_signal(object.ref.data.textureIndex)
	%ObjectTextureSourceEdit.get_line_edit().text = "%d" % object.ref.data.textureSource
	%ObjectTextureSourceEdit.set_value_no_signal(object.ref.data.textureSource)
	%ObjectUnk0x07Edit.get_line_edit().text = "%d" % object.ref.data.unk0x07
	%ObjectUnk0x07Edit.set_value_no_signal(object.ref.data.unk0x07)
	%ObjectLightingEdit.get_line_edit().text = "%d" % object.ref.data.lighting
	%ObjectLightingEdit.set_value_no_signal(object.ref.data.lighting)
	%ObjectRenderTypeEdit.get_line_edit().text = "%d" % object.ref.data.renderType
	%ObjectRenderTypeEdit.set_value_no_signal(object.ref.data.renderType)
	%ObjectUnk0x0CEdit.get_line_edit().text = "%d" % object.ref.data.unk0x0C
	%ObjectUnk0x0CEdit.set_value_no_signal(object.ref.data.unk0x0C)
	%ObjectUnk0x0EEdit.get_line_edit().text = "%d" % object.ref.data.unk0x0E
	%ObjectUnk0x0EEdit.set_value_no_signal(object.ref.data.unk0x0E)
	
	update_texture()


func update_texture() -> void:
	if current_object.data.textureSource == 0:
		object_das = current_object.map_info.das
		object_index = current_object.data.textureIndex + 4096
	elif current_object.data.textureSource == 1:
		object_das = current_object.map_info.das
		object_index = current_object.data.textureIndex + 4096 + 256
	elif current_object.data.textureSource == 2:
		object_das = "M/ADEMO.DAS"
		object_index = current_object.data.textureIndex
	elif current_object.data.textureSource == 3:
		object_das = "M/ADEMO.DAS"
		object_index = current_object.data.textureIndex + 256
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
	current_object.data.posX = value
	_redraw_object(%ObjectXEdit)


func _on_object_y_edit_value_changed(value: float) -> void:
	current_object.data.posY = value
	_redraw_object(%ObjectYEdit)


func _on_object_z_edit_value_changed(value: float) -> void:
	current_object.data.posZ = value
	_redraw_object(%ObjectZEdit)


func _on_object_rotation_edit_value_changed(value: float) -> void:
	current_object.data.rotation = value
	_redraw_object(%ObjectRotationEdit)


func _on_object_texture_index_edit_value_changed(value: float) -> void:
	current_object.data.textureIndex = value
	update_texture()


func _on_object_texture_source_edit_value_changed(value: float) -> void:
	current_object.data.textureSource = value
	update_texture()


func _on_object_unk_0x_07_edit_value_changed(value: float) -> void:
	current_object.data.unk0x07 = value


func _on_object_lighting_edit_value_changed(value: float) -> void:
	current_object.data.lighting = value


func _on_object_render_type_edit_value_changed(value: float) -> void:
	current_object.data.renderType = value


func _on_object_unk_0x_0c_edit_value_changed(value: float) -> void:
	current_object.data.unk0x0C = value


func _on_object_unk_0x_0e_edit_value_changed(value: float) -> void:
	current_object.data.unk0x0E = value
