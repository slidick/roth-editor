extends Control

signal jump_to_collision_pressed
signal jump_to_filename_pressed(filename: Dictionary)

var standard_image: Dictionary = {}
var raw_palette: PackedByteArray = []


func load_image_data(p_standard_image: Dictionary, p_raw_palette: Array = [], is_fat_3: bool = false) -> void:
	standard_image = p_standard_image
	if p_raw_palette.is_empty():
		raw_palette = Das.DEFAULT_RAW_PALETTE
	else:
		raw_palette = p_raw_palette
	if is_fat_3:
		%JumpToObjectCollisionButton.show()
	else:
		%JumpToObjectCollisionButton.hide()
	
	%Flags1Edit.text = str(standard_image.flags_1)
	%Flags2Edit.text = str(standard_image.flags_2)
	%ModifierEdit.text = str(standard_image.data.modifier)
	%ImageTypeEdit.text = str(standard_image.data.image_type)
	if "filename" in standard_image:
		%NameEdit.text = standard_image.filename.name
		%DescriptionEdit.text = standard_image.filename.desc
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
	
	# Texture
	update_texture()


func update_flags_1_checkboxes() -> void:
	%Flags1CheckBox1.button_pressed = (standard_image.flags_1 & (1<<0)) > 0
	%Flags1CheckBox2.button_pressed = (standard_image.flags_1 & (1<<1)) > 0
	%Flags1CheckBox3.button_pressed = (standard_image.flags_1 & (1<<2)) > 0
	%Flags1CheckBox4.button_pressed = (standard_image.flags_1 & (1<<3)) > 0
	%Flags1CheckBox5.button_pressed = (standard_image.flags_1 & (1<<4)) > 0
	%Flags1CheckBox6.button_pressed = (standard_image.flags_1 & (1<<5)) > 0
	%Flags1CheckBox7.button_pressed = (standard_image.flags_1 & (1<<6)) > 0
	%Flags1CheckBox8.button_pressed = (standard_image.flags_1 & (1<<7)) > 0


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
	standard_image.flags_1 = new_value
	%Flags1Edit.text = str(new_value)


func update_flags_2_checkboxes() -> void:
	%Flags2CheckBox1.button_pressed = (standard_image.flags_2 & (1<<0)) > 0
	%Flags2CheckBox2.button_pressed = (standard_image.flags_2 & (1<<1)) > 0
	%Flags2CheckBox3.button_pressed = (standard_image.flags_2 & (1<<2)) > 0
	%Flags2CheckBox4.button_pressed = (standard_image.flags_2 & (1<<3)) > 0
	%Flags2CheckBox5.button_pressed = (standard_image.flags_2 & (1<<4)) > 0
	%Flags2CheckBox6.button_pressed = (standard_image.flags_2 & (1<<5)) > 0
	%Flags2CheckBox7.button_pressed = (standard_image.flags_2 & (1<<6)) > 0
	%Flags2CheckBox8.button_pressed = (standard_image.flags_2 & (1<<7)) > 0


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
	standard_image.flags_2 = new_value
	%Flags2Edit.text = str(new_value)


func update_modifier_checkboxes() -> void:
	%ModifierCheckBox1.button_pressed = (standard_image.data.modifier & (1<<0)) > 0
	%ModifierCheckBox2.button_pressed = (standard_image.data.modifier & (1<<1)) > 0
	%ModifierCheckBox3.button_pressed = (standard_image.data.modifier & (1<<2)) > 0
	%ModifierCheckBox4.button_pressed = (standard_image.data.modifier & (1<<3)) > 0
	%ModifierCheckBox5.button_pressed = (standard_image.data.modifier & (1<<4)) > 0
	%ModifierCheckBox6.button_pressed = (standard_image.data.modifier & (1<<5)) > 0
	%ModifierCheckBox7.button_pressed = (standard_image.data.modifier & (1<<6)) > 0
	%ModifierCheckBox8.button_pressed = (standard_image.data.modifier & (1<<7)) > 0


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
	standard_image.data.modifier = new_value
	%ModifierEdit.text = str(new_value)


func update_image_type_checkboxes() -> void:
	%ImageTypeCheckBox1.button_pressed = (standard_image.data.image_type & (1<<0)) > 0
	%ImageTypeCheckBox2.button_pressed = (standard_image.data.image_type & (1<<1)) > 0
	%ImageTypeCheckBox3.button_pressed = (standard_image.data.image_type & (1<<2)) > 0
	%ImageTypeCheckBox4.button_pressed = (standard_image.data.image_type & (1<<3)) > 0
	%ImageTypeCheckBox5.button_pressed = (standard_image.data.image_type & (1<<4)) > 0
	%ImageTypeCheckBox6.button_pressed = (standard_image.data.image_type & (1<<5)) > 0
	%ImageTypeCheckBox7.button_pressed = (standard_image.data.image_type & (1<<6)) > 0
	%ImageTypeCheckBox8.button_pressed = (standard_image.data.image_type & (1<<7)) > 0


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
	standard_image.data.image_type = new_value
	%ImageTypeEdit.text = str(new_value)


func update_texture() -> void:
	var is_transparent: bool = standard_image.data.image_type & Das.IMAGE_TYPE.TRANSPARENT > 0 or standard_image.data.image_type & Das.IMAGE_TYPE.PALETTE_ZERO_OPAQUE == 0
	var is_fully_transparent: bool = standard_image.data.image_type & Das.IMAGE_TYPE.TRANSPARENT > 0
	var image: Image = Image.create_from_data(standard_image.data.width, standard_image.data.height, false, Image.FORMAT_RGBA8 if is_transparent else Image.FORMAT_RGB8, Utility.convert_palette_image(raw_palette, standard_image.data.raw_image, is_transparent, is_fully_transparent))
	var image_texture := ImageTexture.create_from_image(image)
	%TextureRect.texture = image_texture
	update_dimension()


func update_dimension() -> void:
	if %RotatedCheckButton.button_pressed:
		%DimensionLabel.text = "%s x %s" % [standard_image.data.height, standard_image.data.width]
	else:
		%DimensionLabel.text = "%s x %s" % [standard_image.data.width, standard_image.data.height]


func _on_edit_image_button_pressed() -> void:
	var new_texture: Dictionary = await owner.owner.edit_image(standard_image.data, raw_palette)
	if not new_texture.is_empty():
		standard_image.data = new_texture
		update_texture()


func _on_name_edit_text_changed(new_text: String) -> void:
	standard_image.filename.name = new_text


func _on_description_edit_text_changed(new_text: String) -> void:
	standard_image.filename.desc = new_text


func _on_jump_to_filename_button_pressed() -> void:
	jump_to_filename_pressed.emit(standard_image.filename)


func _on_add_filename_button_pressed() -> void:
	if owner.name == "Fat1" or owner.name == "Fat2":
		standard_image["filename"] = owner.owner._on_add_filename_pressed(1, standard_image.index)
	else:
		standard_image["filename"] = owner.owner._on_add_filename_pressed(2, standard_image.index)
	%NameEdit.text = "%s (%s)" % [standard_image.filename.name, standard_image.filename.desc]


func _on_jump_to_object_collision_button_pressed() -> void:
	jump_to_collision_pressed.emit()


func _on_flags_1_edit_text_changed(new_text: String) -> void:
	standard_image.flags_1 = int(new_text)
	update_flags_1_checkboxes()


func _on_flags_2_edit_text_changed(new_text: String) -> void:
	standard_image.flags_2 = int(new_text)
	update_flags_2_checkboxes()


func _on_modifier_edit_text_changed(new_text: String) -> void:
	standard_image.data.modifier = int(new_text)
	update_modifier_checkboxes()


func _on_image_type_edit_text_changed(new_text: String) -> void:
	standard_image.data.image_type = int(new_text)
	update_image_type_checkboxes()
	update_texture()


func _on_flags_1_check_box_pressed() -> void:
	update_flags_1_from_checkboxes()


func _on_flags_2_check_box_pressed() -> void:
	update_flags_2_from_checkboxes()


func _on_modifier_check_box_pressed() -> void:
	update_modifier_from_checkboxes()


func _on_image_type_check_box_pressed() -> void:
	update_image_type_from_checkboxes()
	update_texture()


func _on_rotated_check_button_toggled(toggled_on: bool) -> void:
	%RotationContainer.enabled = toggled_on
	update_dimension()


func _on_texture_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		%PopupMenu.popup(Rect2(event.global_position.x, event.global_position.y, 0, 0))


func _on_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			if %RotatedCheckButton.button_pressed:
				standard_image.data.raw_image = Utility.rotate_raw_image_counter_clockwise(standard_image.data.raw_image, standard_image.data.width, standard_image.data.height)
			else:
				standard_image.data.raw_image = Utility.rotate_raw_image_clockwise(standard_image.data.raw_image, standard_image.data.width, standard_image.data.height)
			var new_height: int = standard_image.data.width
			standard_image.data.width = standard_image.data.height
			standard_image.data.height = new_height
			update_texture()
		1:
			if %RotatedCheckButton.button_pressed:
				standard_image.data.raw_image = Utility.rotate_raw_image_clockwise(standard_image.data.raw_image, standard_image.data.width, standard_image.data.height)
			else:
				standard_image.data.raw_image = Utility.rotate_raw_image_counter_clockwise(standard_image.data.raw_image, standard_image.data.width, standard_image.data.height)
			var new_height: int = standard_image.data.width
			standard_image.data.width = standard_image.data.height
			standard_image.data.height = new_height
			update_texture()
		2:
			if %RotatedCheckButton.button_pressed:
				standard_image.data.raw_image = Utility.flip_raw_image_vertical(standard_image.data.raw_image, standard_image.data.width, standard_image.data.height)
			else:
				standard_image.data.raw_image = Utility.flip_raw_image_horizontal(standard_image.data.raw_image, standard_image.data.width, standard_image.data.height)
			update_texture()
		3:
			if %RotatedCheckButton.button_pressed:
				standard_image.data.raw_image = Utility.flip_raw_image_horizontal(standard_image.data.raw_image, standard_image.data.width, standard_image.data.height)
			else:
				standard_image.data.raw_image = Utility.flip_raw_image_vertical(standard_image.data.raw_image, standard_image.data.width, standard_image.data.height)
			update_texture()
