extends Control

signal jump_to_collision_pressed
signal jump_to_filename_pressed(filename: Dictionary)

var animation_image: Dictionary = {}
var raw_palette: PackedByteArray
var right_clicked_frame: int = -1
var copied_frame_data: PackedByteArray = []


func load_animation_data(p_animation_image: Dictionary, p_raw_palette: Array = [], is_fat_3: bool = false) -> void:
	animation_image = p_animation_image
	if p_raw_palette.is_empty():
		raw_palette = Das.DEFAULT_RAW_PALETTE
	else:
		raw_palette = p_raw_palette
	if is_fat_3:
		%JumpToObjectCollisionButton.show()
	else:
		%JumpToObjectCollisionButton.hide()
	
	%Flags1Edit.text = str(animation_image.flags_1)
	%Flags2Edit.text = str(animation_image.flags_2)
	%ModifierEdit.text = str(animation_image.data.modifier)
	%ImageTypeEdit.text = str(animation_image.data.image_type)
	
	%Unk0x0EEdit.text = str(animation_image.data.unk_0x0E)
	
	%AnimationSpeedSpinBox.set_value_no_signal(animation_image.data.first_image_offset)
	%AnimationSpeedSpinBox.get_line_edit().text = str(animation_image.data.first_image_offset)
	%FramesSpinBox.get_line_edit().text = str(len(animation_image.data.animation_2))
	%FramesSpinBox.set_value_no_signal(len(animation_image.data.animation_2))
	if "filename" in animation_image:
		%NameEdit.text = animation_image.filename.name
		%DescriptionEdit.text = animation_image.filename.desc
		%JumpToFilenameButton.show()
		%AddFilenameButton.hide()
	else:
		%NameEdit.text = "No Name Set"
		%DescriptionEdit.text = ""
		%JumpToFilenameButton.hide()
		%AddFilenameButton.show()
	
	update_flags_1_checkboxes()
	update_flags_2_checkboxes()
	update_modifier_checkboxes()
	update_image_type_checkboxes()
	
	update_texture()
	
	if "shift_data" in animation_image.data:
		%ShiftDataContainer.show()
		%ShiftXSpinBox.set_value_no_signal(animation_image.data.shift_data[0])
		%ShiftYSpinBox.set_value_no_signal(animation_image.data.shift_data[1])
	else:
		%ShiftDataContainer.hide()


func update_texture() -> void:
	%AnimationTextureRect.set_data(animation_image.data, raw_palette, animation_image.data.shift_data if "shift_data" in animation_image.data else [])
	update_dimension()
	
	for child: Node in %ImagesContainer.get_children():
		child.queue_free()
	
	var is_transparent: bool = animation_image.data.image_type & Das.IMAGE_TYPE.TRANSPARENT > 0 or animation_image.data.image_type & Das.IMAGE_TYPE.PALETTE_ZERO_OPAQUE == 0
	var is_fully_transparent: bool = animation_image.data.image_type & Das.IMAGE_TYPE.TRANSPARENT > 0
	for i in range(len(animation_image.data.animation_2)):
		var vbox := VBoxContainer.new()
		
		var sub_image: Dictionary = animation_image.data.animation_2[i]
		
		var raw_img: PackedByteArray = sub_image.raw_image
		var image: Image = Image.create_from_data(sub_image.width, sub_image.height, false, Image.FORMAT_RGBA8 if is_transparent else Image.FORMAT_RGB8, Utility.convert_palette_image(raw_palette, raw_img, is_transparent, is_fully_transparent))
		var image_texture := ImageTexture.create_from_image(image)
		
		var texture_rect := TextureRect.new()
		texture_rect.texture = image_texture
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if %RotatedCheckButton.button_pressed:
			texture_rect.expand_mode = TextureRect.EXPAND_FIT_HEIGHT
		else:
			texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		
		texture_rect.gui_input.connect( func (event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
				right_clicked_frame = vbox.get_index()
				if copied_frame_data.is_empty():
					%PopupMenu.set_item_disabled(1, true)
				else:
					%PopupMenu.set_item_disabled(1, false)
				if %RotatedCheckButton.button_pressed:
					%PopupMenu.popup(Rect2(texture_rect.global_position.x + event.position.y, texture_rect.global_position.y + event.position.x, 10, 10))
				else:
					%PopupMenu.popup(Rect2(texture_rect.global_position.x + event.position.x, texture_rect.global_position.y + event.position.y, 0, 0))
		)
		
		var rotation_container := RotationContainer.new()
		rotation_container.add_child(texture_rect)
		rotation_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		rotation_container.enabled = %RotatedCheckButton.button_pressed
		vbox.add_child(rotation_container)
		
		var dimension_label := Label.new()
		dimension_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if %RotatedCheckButton.button_pressed:
			dimension_label.text = "%s x %s" % [sub_image.height, sub_image.width]
		else:
			dimension_label.text = "%s x %s" % [sub_image.width, sub_image.height]
		vbox.add_child(dimension_label)
		
		var edit_button := Button.new()
		edit_button.text = "Edit"
		edit_button.custom_minimum_size.x = 100
		edit_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		edit_button.pressed.connect(func () -> void:
			var data := {
				"raw_image": raw_img,
				"image_type": animation_image.data.image_type,
				"width": sub_image.width,
				"height": sub_image.height,
			}
			var new_texture: Dictionary = await owner.owner.edit_image(data, raw_palette)
			if not new_texture.is_empty():
				animation_image.data.animation_2[i].raw_image = new_texture.raw_image
				animation_image.data.animation_2[i].width = new_texture.width
				animation_image.data.animation_2[i].height = new_texture.height
				update_texture()
		)
		vbox.add_child(edit_button)
		
		
		
		
		var spin1 := SpinBox.new()
		spin1.max_value = 65535
		spin1.value = sub_image.num_images
		
		var spin2 := SpinBox.new()
		spin2.max_value = 65535
		spin2.value = sub_image.current_image_idx
		
		var spin3 := SpinBox.new()
		spin3.max_value = 65535
		spin3.value = sub_image.current_image_size
		
		
		vbox.add_child(spin1)
		vbox.add_child(spin2)
		vbox.add_child(spin3)
		
		
		
		
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		%ImagesContainer.add_child(vbox)


func update_dimension() -> void:
	if %RotatedCheckButton.button_pressed:
		%DimensionLabel.text = "%s x %s" % [animation_image.data.height, animation_image.data.width]
	else:
		%DimensionLabel.text = "%s x %s" % [animation_image.data.width, animation_image.data.height]
	
	# Wait for queue_free of previous selection to run
	await get_tree().process_frame
	
	for i in range(%ImagesContainer.get_child_count()):
		var sub_image_container: VBoxContainer = %ImagesContainer.get_child(i)
		if %RotatedCheckButton.button_pressed:
			sub_image_container.get_child(1).text = "%s x %s" % [animation_image.data.animation_2[i].height, animation_image.data.animation_2[i].width]
		else:
			sub_image_container.get_child(1).text = "%s x %s" % [animation_image.data.animation_2[i].width, animation_image.data.animation_2[i].height]


func update_flags_1_checkboxes() -> void:
	%Flags1CheckBox1.button_pressed = (animation_image.flags_1 & (1<<0)) > 0
	%Flags1CheckBox2.button_pressed = (animation_image.flags_1 & (1<<1)) > 0
	%Flags1CheckBox3.button_pressed = (animation_image.flags_1 & (1<<2)) > 0
	%Flags1CheckBox4.button_pressed = (animation_image.flags_1 & (1<<3)) > 0
	%Flags1CheckBox5.button_pressed = (animation_image.flags_1 & (1<<4)) > 0
	%Flags1CheckBox6.button_pressed = (animation_image.flags_1 & (1<<5)) > 0
	%Flags1CheckBox7.button_pressed = (animation_image.flags_1 & (1<<6)) > 0
	%Flags1CheckBox8.button_pressed = (animation_image.flags_1 & (1<<7)) > 0


func update_flags_1_from_checkboxes() -> void:
	var new_value: int = 0
	if %Flags1CheckBox1.button_pressed:
		new_value |= (1<<0)
	if %Flags1CheckBox2.button_pressed:
		new_value |= (1<<1)
	if %Flags1CheckBox3.button_pressed:
		new_value |= (1<<2)
	if %Flags1CheckBox4.button_pressed:
		new_value |= (1<<3)
	if %Flags1CheckBox5.button_pressed:
		new_value |= (1<<4)
	if %Flags1CheckBox6.button_pressed:
		new_value |= (1<<5)
	if %Flags1CheckBox7.button_pressed:
		new_value |= (1<<6)
	if %Flags1CheckBox8.button_pressed:
		new_value |= (1<<7)
	animation_image.flags_1 = new_value
	%Flags1Edit.text = str(new_value)


func update_flags_2_checkboxes() -> void:
	%Flags2CheckBox1.button_pressed = (animation_image.flags_2 & (1<<0)) > 0
	%Flags2CheckBox2.button_pressed = (animation_image.flags_2 & (1<<1)) > 0
	%Flags2CheckBox3.button_pressed = (animation_image.flags_2 & (1<<2)) > 0
	%Flags2CheckBox4.button_pressed = (animation_image.flags_2 & (1<<3)) > 0
	%Flags2CheckBox5.button_pressed = (animation_image.flags_2 & (1<<4)) > 0
	%Flags2CheckBox6.button_pressed = (animation_image.flags_2 & (1<<5)) > 0
	%Flags2CheckBox7.button_pressed = (animation_image.flags_2 & (1<<6)) > 0
	%Flags2CheckBox8.button_pressed = (animation_image.flags_2 & (1<<7)) > 0


func update_flags_2_from_checkboxes() -> void:
	var new_value: int = 0
	if %Flags2CheckBox1.button_pressed:
		new_value |= (1<<0)
	if %Flags2CheckBox2.button_pressed:
		new_value |= (1<<1)
	if %Flags2CheckBox3.button_pressed:
		new_value |= (1<<2)
	if %Flags2CheckBox4.button_pressed:
		new_value |= (1<<3)
	if %Flags2CheckBox5.button_pressed:
		new_value |= (1<<4)
	if %Flags2CheckBox6.button_pressed:
		new_value |= (1<<5)
	if %Flags2CheckBox7.button_pressed:
		new_value |= (1<<6)
	if %Flags2CheckBox8.button_pressed:
		new_value |= (1<<7)
	animation_image.flags_2 = new_value
	%Flags2Edit.text = str(new_value)


func update_modifier_checkboxes() -> void:
	%ModifierCheckBox1.button_pressed = (animation_image.data.modifier & (1<<0)) > 0
	%ModifierCheckBox2.button_pressed = (animation_image.data.modifier & (1<<1)) > 0
	%ModifierCheckBox3.button_pressed = (animation_image.data.modifier & (1<<2)) > 0
	%ModifierCheckBox4.button_pressed = (animation_image.data.modifier & (1<<3)) > 0
	%ModifierCheckBox5.button_pressed = (animation_image.data.modifier & (1<<4)) > 0
	%ModifierCheckBox6.button_pressed = (animation_image.data.modifier & (1<<5)) > 0
	%ModifierCheckBox7.button_pressed = (animation_image.data.modifier & (1<<6)) > 0
	%ModifierCheckBox8.button_pressed = (animation_image.data.modifier & (1<<7)) > 0


func update_modifier_from_checkboxes() -> void:
	var new_value: int = 0
	if %ModifierCheckBox1.button_pressed:
		new_value |= (1<<0)
	if %ModifierCheckBox2.button_pressed:
		new_value |= (1<<1)
	if %ModifierCheckBox3.button_pressed:
		new_value |= (1<<2)
	if %ModifierCheckBox4.button_pressed:
		new_value |= (1<<3)
	if %ModifierCheckBox5.button_pressed:
		new_value |= (1<<4)
	if %ModifierCheckBox6.button_pressed:
		new_value |= (1<<5)
	if %ModifierCheckBox7.button_pressed:
		new_value |= (1<<6)
	if %ModifierCheckBox8.button_pressed:
		new_value |= (1<<7)
	animation_image.data.modifier = new_value
	%ModifierEdit.text = str(new_value)


func update_image_type_checkboxes() -> void:
	%ImageTypeCheckBox1.button_pressed = (animation_image.data.image_type & (1<<0)) > 0
	%ImageTypeCheckBox2.button_pressed = (animation_image.data.image_type & (1<<1)) > 0
	%ImageTypeCheckBox3.button_pressed = (animation_image.data.image_type & (1<<2)) > 0
	%ImageTypeCheckBox4.button_pressed = (animation_image.data.image_type & (1<<3)) > 0
	%ImageTypeCheckBox5.button_pressed = (animation_image.data.image_type & (1<<4)) > 0
	%ImageTypeCheckBox6.button_pressed = (animation_image.data.image_type & (1<<5)) > 0
	%ImageTypeCheckBox7.button_pressed = (animation_image.data.image_type & (1<<6)) > 0
	%ImageTypeCheckBox8.button_pressed = (animation_image.data.image_type & (1<<7)) > 0


func update_image_type_from_checkboxes() -> void:
	var new_value: int = 0
	if %ImageTypeCheckBox1.button_pressed:
		new_value |= (1<<0)
	if %ImageTypeCheckBox2.button_pressed:
		new_value |= (1<<1)
	if %ImageTypeCheckBox3.button_pressed:
		new_value |= (1<<2)
	if %ImageTypeCheckBox4.button_pressed:
		new_value |= (1<<3)
	if %ImageTypeCheckBox5.button_pressed:
		new_value |= (1<<4)
	if %ImageTypeCheckBox6.button_pressed:
		new_value |= (1<<5)
	if %ImageTypeCheckBox7.button_pressed:
		new_value |= (1<<6)
	if %ImageTypeCheckBox8.button_pressed:
		new_value |= (1<<7)
	animation_image.data.image_type = new_value
	%ImageTypeEdit.text = str(new_value)



func _on_name_edit_text_changed(new_text: String) -> void:
	animation_image.filename.name = new_text


func _on_description_edit_text_changed(new_text: String) -> void:
	animation_image.filename.desc = new_text


func _on_jump_to_filename_button_pressed() -> void:
	jump_to_filename_pressed.emit(animation_image.filename)


func _on_add_filename_button_pressed() -> void:
	if owner.name == "Fat1" or owner.name == "Fat2":
		animation_image["filename"] = owner.owner._on_add_filename_pressed(1, animation_image.index)
	else:
		animation_image["filename"] = owner.owner._on_add_filename_pressed(2, animation_image.index)
	%NameEdit.text = "%s (%s)" % [animation_image.filename.name, animation_image.filename.desc]


func _on_jump_to_object_collision_button_pressed() -> void:
	jump_to_collision_pressed.emit()


func _on_flags_1_edit_text_changed(new_text: String) -> void:
	animation_image.flags_1 = int(new_text)
	update_flags_1_checkboxes()


func _on_flags_2_edit_text_changed(new_text: String) -> void:
	animation_image.flags_2 = int(new_text)
	update_flags_2_checkboxes()


func _on_modifier_edit_text_changed(new_text: String) -> void:
	animation_image.data.modifier = int(new_text)
	update_modifier_checkboxes()


func _on_image_type_edit_text_changed(new_text: String) -> void:
	animation_image.data.image_type = int(new_text)
	update_image_type_checkboxes()
	#update_texture()


func _on_flags_1_check_box_pressed() -> void:
	update_flags_1_from_checkboxes()


func _on_flags_2_check_box_pressed() -> void:
	update_flags_2_from_checkboxes()


func _on_modifier_check_box_pressed() -> void:
	update_modifier_from_checkboxes()


func _on_image_type_check_box_pressed() -> void:
	update_image_type_from_checkboxes()
	#update_texture()


func _on_rotated_check_button_toggled(toggled_on: bool) -> void:
	%RotationContainer.enabled = toggled_on
	for vbox: VBoxContainer in %ImagesContainer.get_children():
		var rotation_container: RotationContainer = vbox.get_child(0)
		rotation_container.enabled = toggled_on
		if toggled_on:
			rotation_container.get_child(0).expand_mode = TextureRect.EXPAND_FIT_HEIGHT
		else:
			rotation_container.get_child(0).expand_mode = TextureRect.EXPAND_FIT_WIDTH
	update_dimension()


func _on_frames_spin_box_value_changed(value: float) -> void:
	if value < len(animation_image.data.animation_2):
		while value != len(animation_image.data.animation_2):
			animation_image.data.animation_2.pop_back()
		update_texture()
	elif value > len(animation_image.data.animation_2):
		while value != len(animation_image.data.animation_2):
			var raw_image := PackedByteArray()
			raw_image.resize(16 * 16)
			var frame_data: Dictionary = {
				x_offset = 0,
				width = 16,
				y_offset = 0,
				height = 16,
				raw_image = raw_image
			}
			animation_image.data.animation_2.append(frame_data)
		update_texture()


func _on_unk_0x_0e_edit_text_changed(new_text: String) -> void:
	animation_image.data.unk_0x0E = int(new_text)


func _on_animation_speed_spin_box_value_changed(value: float) -> void:
	animation_image.data.first_image_offset = int(value)
	%AnimationTextureRect.speed = value


func _on_as_images_check_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		%AnimationContainer.hide()
		%AsImagesContainer.show()
	else:
		%AnimationContainer.show()
		%AsImagesContainer.hide()


func _on_shift_x_spin_box_value_changed(value: float) -> void:
	animation_image.data.shift_data[0] = int(value)
	update_texture()


func _on_shift_y_spin_box_value_changed(value: float) -> void:
	animation_image.data.shift_data[1] = int(value)
	update_texture()


func _on_show_shift_check_button_pressed() -> void:
	update_texture()


func _on_edit_alignment_button_pressed() -> void:
	var new_data: Dictionary = await owner.owner.edit_animation_2_alignments(animation_image, raw_palette)
	if not new_data.is_empty():
		animation_image.data.width = new_data.data.width
		animation_image.data.height = new_data.data.height
		animation_image.data.animation_2 = new_data.data.animation_2
		update_texture()
