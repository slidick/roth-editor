extends Control

signal jump_to_collision_pressed
signal jump_to_filename_pressed(filename: Dictionary)

var pack_data: Dictionary = {}
var raw_palette: PackedByteArray = []
var right_clicked_frame: int = -1
var copied_image_data: Dictionary = {}

func load_pack_data(p_pack_data: Dictionary, p_raw_palette: Array = [], is_fat_3: bool = false) -> void:
	pack_data = p_pack_data
	if p_raw_palette.is_empty():
		raw_palette = Das.DEFAULT_RAW_PALETTE
	else:
		raw_palette = p_raw_palette
	if is_fat_3:
		%JumpToObjectCollisionButton.show()
	else:
		%JumpToObjectCollisionButton.hide()
	
	%Flags1Edit.text = str(pack_data.flags_1)
	%Flags2Edit.text = str(pack_data.flags_2)
	%ModifierEdit.text = str(pack_data.data.modifier)
	%ImageTypeEdit.text = str(pack_data.data.image_type)
	if "filename" in pack_data:
		%NameEdit.text = "%s (%s)" % [pack_data.filename.name, pack_data.filename.desc]
		%JumpToFilenameButton.show()
		%AddFilenameButton.hide()
	else:
		%NameEdit.text = "No Name Set"
		%JumpToFilenameButton.hide()
		%AddFilenameButton.show()
	
	%ImageCountSpinBox.set_value_no_signal(len(pack_data.data.image_pack))
	%PackTypeSpinBox.set_value_no_signal(pack_data.data.pack_type)
	%PackTypeSpinBox.get_line_edit().text = str(pack_data.data.pack_type)
	%"3DObjectTypeCheckBox".button_pressed = pack_data.data.pack_type & 64 > 0
	%DirectionalTypeCheckBox.button_pressed = pack_data.data.pack_type & 128 > 0
	if pack_data.data.pack_type & 128 > 0:
		%DirectionalContainer.show()
	else:
		%DirectionalContainer.hide()
	
	update_max_image_count()
	load_directions()
	
	update_flags_1_checkboxes()
	update_flags_2_checkboxes()
	update_modifier_checkboxes()
	update_image_type_checkboxes()
	
	update_dimensions()
	redraw_textures()


func redraw_textures() -> void:
	for child: Node in %ImagesContainer.get_children():
		child.queue_free()
	
	for i in range(len(pack_data.data.image_pack)):
		var image_data: Dictionary = pack_data.data.image_pack[i]
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 10)
		
		var label_1 := Label.new()
		label_1.text = "Modifier"
		label_1.custom_minimum_size.x = 110
		var line_edit_1 := LineEdit.new()
		line_edit_1.text = str(image_data.modifier)
		line_edit_1.text_changed.connect(func (new_text: String) -> void:
			pack_data.data.image_pack[i].modifier = int(new_text)
		)
		var hbox_1 := HBoxContainer.new()
		hbox_1.add_child(label_1)
		hbox_1.add_child(line_edit_1)
		vbox.add_child(hbox_1)
		
		var label_2 := Label.new()
		label_2.text = "Image Type"
		label_2.custom_minimum_size.x = 110
		var line_edit_2 := LineEdit.new()
		line_edit_2.text = str(image_data.image_type)
		line_edit_2.text_changed.connect(func (new_text: String) -> void:
			pack_data.data.image_pack[i].image_type = int(new_text)
		)
		var hbox_2 := HBoxContainer.new()
		hbox_2.add_child(label_2)
		hbox_2.add_child(line_edit_2)
		vbox.add_child(hbox_2)
		
		var checkbox := CheckBox.new()
		checkbox.text = "Flip"
		checkbox.button_pressed = pack_data.data.offsets_flipped[i]
		checkbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		checkbox.toggled.connect(func (toggled_on: bool) -> void:
			pack_data.data.offsets_flipped[i] = toggled_on
		)
		if pack_data.data.pack_type & 128 > 0:
			checkbox.hide()
		vbox.add_child(checkbox)
		
		var is_transparent: bool = image_data.image_type & Das.IMAGE_TYPE.TRANSPARENT > 0 or image_data.image_type & Das.IMAGE_TYPE.PALETTE_ZERO_OPAQUE == 0
		var is_fully_transparent: bool = image_data.image_type & Das.IMAGE_TYPE.TRANSPARENT > 0
		var image: Image = Image.create_from_data(image_data.width, image_data.height, false, Image.FORMAT_RGBA8 if is_transparent else Image.FORMAT_RGB8, Utility.convert_palette_image(raw_palette, image_data.raw_image, is_transparent, is_fully_transparent))
		var image_texture := ImageTexture.create_from_image(image)
		
		var texture_rect := TextureRect.new()
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		texture_rect.texture = image_texture
		texture_rect.gui_input.connect( func (event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
				right_clicked_frame = int(vbox.get_index() / 2.0)
				if copied_image_data.is_empty():
					%PopupMenu.set_item_disabled(1, true)
				else:
					%PopupMenu.set_item_disabled(1, false)
				if %RotatedCheckButton.button_pressed:
					%PopupMenu.popup(Rect2(texture_rect.global_position.x + event.position.y, texture_rect.global_position.y + event.position.x, 10, 10))
				else:
					%PopupMenu.popup(Rect2(texture_rect.global_position.x + event.position.x, texture_rect.global_position.y + event.position.y, 0, 0))
		)
		
		var rotation_container := RotationContainer.new()
		rotation_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rotation_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		rotation_container.add_child(texture_rect)
		vbox.add_child(rotation_container)
		
		rotation_container.enabled = %RotatedCheckButton.button_pressed
		
		var label_3 := Label.new()
		label_3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if %RotatedCheckButton.button_pressed:
			label_3.text = "%dx%d" % [image_data.height, image_data.width]
		else:
			label_3.text = "%dx%d" % [image_data.width, image_data.height]
		vbox.add_child(label_3)
		
		var edit_button := Button.new()
		edit_button.text = "Edit"
		edit_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		edit_button.custom_minimum_size.x = 100
		edit_button.pressed.connect(func () -> void:
			var new_texture: Dictionary = await owner.owner.edit_image(pack_data.data.image_pack[i], raw_palette)
			if not new_texture.is_empty():
				pack_data.data.image_pack[i] = new_texture
				var updated_image: Image = Image.create_from_data(new_texture.width, new_texture.height, false, Image.FORMAT_RGBA8 if is_transparent else Image.FORMAT_RGB8, Utility.convert_palette_image(raw_palette, new_texture.raw_image, is_transparent, is_fully_transparent))
				var updated_image_texture := ImageTexture.create_from_image(updated_image)
				texture_rect.texture = updated_image_texture
				calculate_new_max_dimensions()
				if %RotatedCheckButton.button_pressed:
					label_3.text = "%dx%d" % [new_texture.height, new_texture.width]
				else:
					label_3.text = "%dx%d" % [new_texture.width, new_texture.height]
				update_dimensions()
		)
		vbox.add_child(edit_button)
		
		%ImagesContainer.add_child(vbox)
		%ImagesContainer.add_child(VSeparator.new())


func load_directions() -> void:
	if len(pack_data.data.offsets_index) > 0:
		%BackSpinBox.set_value_no_signal(pack_data.data.offsets_index[0])
		%BackFlipCheckBox.button_pressed = pack_data.data.offsets_flipped[0]
	if len(pack_data.data.offsets_index) > 1:
		%BackRightSpinBox.set_value_no_signal(pack_data.data.offsets_index[1])
		%BackRightFlipCheckBox.button_pressed = pack_data.data.offsets_flipped[1]
	if len(pack_data.data.offsets_index) > 2:
		%RightSpinBox.set_value_no_signal(pack_data.data.offsets_index[2])
		%RightFlipCheckBox.button_pressed = pack_data.data.offsets_flipped[2]
	if len(pack_data.data.offsets_index) > 3:
		%FrontRightSpinBox.set_value_no_signal(pack_data.data.offsets_index[3])
		%FrontRightFlipCheckBox.button_pressed = pack_data.data.offsets_flipped[3]
	if len(pack_data.data.offsets_index) > 4:
		%FrontSpinBox.set_value_no_signal(pack_data.data.offsets_index[4])
		%FrontFlipCheckBox.button_pressed = pack_data.data.offsets_flipped[4]
	if len(pack_data.data.offsets_index) > 5:
		%FrontLeftSpinBox.set_value_no_signal(pack_data.data.offsets_index[5])
		%FrontLeftFlipCheckBox.button_pressed = pack_data.data.offsets_flipped[5]
	if len(pack_data.data.offsets_index) > 6:
		%LeftSpinBox.set_value_no_signal(pack_data.data.offsets_index[6])
		%LeftFlipCheckBox.button_pressed = pack_data.data.offsets_flipped[6]
	if len(pack_data.data.offsets_index) > 7:
		%BackLeftSpinBox.set_value_no_signal(pack_data.data.offsets_index[7])
		%BackLeftFlipCheckBox.button_pressed = pack_data.data.offsets_flipped[7]


func update_max_image_count() -> void:
	%FrontSpinBox.max_value = len(pack_data.data.image_pack) - 1
	%FrontLeftSpinBox.max_value = len(pack_data.data.image_pack) - 1
	%LeftSpinBox.max_value = len(pack_data.data.image_pack) - 1
	%BackLeftSpinBox.max_value = len(pack_data.data.image_pack) - 1
	%BackSpinBox.max_value = len(pack_data.data.image_pack) - 1
	%BackRightSpinBox.max_value = len(pack_data.data.image_pack) - 1
	%RightSpinBox.max_value = len(pack_data.data.image_pack) - 1
	%FrontRightSpinBox.max_value = len(pack_data.data.image_pack) - 1


func calculate_new_max_dimensions() -> void:
	var width: int = 0
	var height: int = 0
	for image_data: Dictionary in pack_data.data.image_pack:
		width = max(width, image_data.width)
		height = max(height, image_data.height)
	pack_data.data.width = width
	pack_data.data.height = height
	update_dimensions()


func update_flags_1_checkboxes() -> void:
	%Flags1CheckBox1.button_pressed = (pack_data.flags_1 & (1<<0)) > 0
	%Flags1CheckBox2.button_pressed = (pack_data.flags_1 & (1<<1)) > 0
	%Flags1CheckBox3.button_pressed = (pack_data.flags_1 & (1<<2)) > 0
	%Flags1CheckBox4.button_pressed = (pack_data.flags_1 & (1<<3)) > 0
	%Flags1CheckBox5.button_pressed = (pack_data.flags_1 & (1<<4)) > 0
	%Flags1CheckBox6.button_pressed = (pack_data.flags_1 & (1<<5)) > 0
	%Flags1CheckBox7.button_pressed = (pack_data.flags_1 & (1<<6)) > 0
	%Flags1CheckBox8.button_pressed = (pack_data.flags_1 & (1<<7)) > 0


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
	pack_data.flags_1 = new_value
	%Flags1Edit.text = str(new_value)


func update_flags_2_checkboxes() -> void:
	%Flags2CheckBox1.button_pressed = (pack_data.flags_2 & (1<<0)) > 0
	%Flags2CheckBox2.button_pressed = (pack_data.flags_2 & (1<<1)) > 0
	%Flags2CheckBox3.button_pressed = (pack_data.flags_2 & (1<<2)) > 0
	%Flags2CheckBox4.button_pressed = (pack_data.flags_2 & (1<<3)) > 0
	%Flags2CheckBox5.button_pressed = (pack_data.flags_2 & (1<<4)) > 0
	%Flags2CheckBox6.button_pressed = (pack_data.flags_2 & (1<<5)) > 0
	%Flags2CheckBox7.button_pressed = (pack_data.flags_2 & (1<<6)) > 0
	%Flags2CheckBox8.button_pressed = (pack_data.flags_2 & (1<<7)) > 0


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
	pack_data.flags_2 = new_value
	%Flags2Edit.text = str(new_value)


func update_modifier_checkboxes() -> void:
	%ModifierCheckBox1.button_pressed = (pack_data.data.modifier & (1<<0)) > 0
	%ModifierCheckBox2.button_pressed = (pack_data.data.modifier & (1<<1)) > 0
	%ModifierCheckBox3.button_pressed = (pack_data.data.modifier & (1<<2)) > 0
	%ModifierCheckBox4.button_pressed = (pack_data.data.modifier & (1<<3)) > 0
	%ModifierCheckBox5.button_pressed = (pack_data.data.modifier & (1<<4)) > 0
	%ModifierCheckBox6.button_pressed = (pack_data.data.modifier & (1<<5)) > 0
	%ModifierCheckBox7.button_pressed = (pack_data.data.modifier & (1<<6)) > 0
	%ModifierCheckBox8.button_pressed = (pack_data.data.modifier & (1<<7)) > 0


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
	pack_data.data.modifier = new_value
	%ModifierEdit.text = str(new_value)


func update_image_type_checkboxes() -> void:
	%ImageTypeCheckBox1.button_pressed = (pack_data.data.image_type & (1<<0)) > 0
	%ImageTypeCheckBox2.button_pressed = (pack_data.data.image_type & (1<<1)) > 0
	%ImageTypeCheckBox3.button_pressed = (pack_data.data.image_type & (1<<2)) > 0
	%ImageTypeCheckBox4.button_pressed = (pack_data.data.image_type & (1<<3)) > 0
	%ImageTypeCheckBox5.button_pressed = (pack_data.data.image_type & (1<<4)) > 0
	%ImageTypeCheckBox6.button_pressed = (pack_data.data.image_type & (1<<5)) > 0
	%ImageTypeCheckBox7.button_pressed = (pack_data.data.image_type & (1<<6)) > 0
	%ImageTypeCheckBox8.button_pressed = (pack_data.data.image_type & (1<<7)) > 0


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
	pack_data.data.image_type = new_value
	%ImageTypeEdit.text = str(new_value)


func update_dimensions() -> void:
	if %RotatedCheckButton.button_pressed:
		%DimensionLabel.text = "%s x %s" % [pack_data.data.height, pack_data.data.width]
	else:
		%DimensionLabel.text = "%s x %s" % [pack_data.data.width, pack_data.data.height]


func _on_jump_to_filename_button_pressed() -> void:
	jump_to_filename_pressed.emit(pack_data.filename)


func _on_add_filename_button_pressed() -> void:
	if owner.name == "Fat1" or owner.name == "Fat2":
		pack_data["filename"] = owner.owner._on_add_filename_pressed(1, pack_data.index)
	else:
		pack_data["filename"] = owner.owner._on_add_filename_pressed(2, pack_data.index)
	%NameEdit.text = "%s (%s)" % [pack_data.filename.name, pack_data.filename.desc]


func _on_jump_to_object_collision_button_pressed() -> void:
	jump_to_collision_pressed.emit()


func _on_flags_1_edit_text_changed(new_text: String) -> void:
	pack_data.flags_1 = int(new_text)
	update_flags_1_checkboxes()


func _on_flags_2_edit_text_changed(new_text: String) -> void:
	pack_data.flags_2 = int(new_text)
	update_flags_2_checkboxes()


func _on_modifier_edit_text_changed(new_text: String) -> void:
	pack_data.data.modifier = int(new_text)
	update_modifier_checkboxes()


func _on_image_type_edit_text_changed(new_text: String) -> void:
	pack_data.data.image_type = int(new_text)
	update_image_type_checkboxes()


func _on_flags_1_check_box_pressed() -> void:
	update_flags_1_from_checkboxes()


func _on_flags_2_check_box_pressed() -> void:
	update_flags_2_from_checkboxes()


func _on_modifier_check_box_pressed() -> void:
	update_modifier_from_checkboxes()


func _on_image_type_check_box_pressed() -> void:
	update_image_type_from_checkboxes()


func _on_rotated_check_button_toggled(toggled_on: bool) -> void:
	update_dimensions()
	var sub_image_index: int = 0
	for control: Control in %ImagesContainer.get_children():
		if control is VBoxContainer:
			control.get_child(3).enabled = toggled_on
			if toggled_on:
				control.get_child(4).text = "%dx%d" % [pack_data.data.image_pack[sub_image_index].height, pack_data.data.image_pack[sub_image_index].width]
			else:
				control.get_child(4).text = "%dx%d" % [pack_data.data.image_pack[sub_image_index].width, pack_data.data.image_pack[sub_image_index].height]
			sub_image_index += 1


func _on_pack_type_spin_box_value_changed(value: float) -> void:
	pack_data.data.pack_type = int(value)


func _on_3d_object_type_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		%PackTypeSpinBox.value = 64


func _on_directional_type_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		%PackTypeSpinBox.value = 128
		%DirectionalContainer.show()
		while len(pack_data.data.offsets_index) < 8:
			pack_data.data.offsets_index.append(0)
		while len(pack_data.data.offsets_flipped) < 8:
			pack_data.data.offsets_flipped.append(false)
		load_directions()
		for control: Control in %ImagesContainer.get_children():
			if control is VBoxContainer:
				control.get_child(2).hide()
	else:
		%DirectionalContainer.hide()
		for control: Control in %ImagesContainer.get_children():
			if control is VBoxContainer:
				control.get_child(2).show()


func _on_front_flip_check_box_toggled(toggled_on: bool) -> void:
	pack_data.data.offsets_flipped[4] = toggled_on


func _on_front_left_flip_check_box_toggled(toggled_on: bool) -> void:
	pack_data.data.offsets_flipped[5] = toggled_on


func _on_left_flip_check_box_toggled(toggled_on: bool) -> void:
	pack_data.data.offsets_flipped[6] = toggled_on


func _on_back_left_flip_check_box_toggled(toggled_on: bool) -> void:
	pack_data.data.offsets_flipped[7] = toggled_on


func _on_back_flip_check_box_toggled(toggled_on: bool) -> void:
	pack_data.data.offsets_flipped[0] = toggled_on


func _on_back_right_flip_check_box_toggled(toggled_on: bool) -> void:
	pack_data.data.offsets_flipped[1] = toggled_on


func _on_right_flip_check_box_toggled(toggled_on: bool) -> void:
	pack_data.data.offsets_flipped[2] = toggled_on


func _on_front_right_flip_check_box_toggled(toggled_on: bool) -> void:
	pack_data.data.offsets_flipped[3] = toggled_on


func _on_front_spin_box_value_changed(value: float) -> void:
	if len(pack_data.data.offsets_index) > 4:
		pack_data.data.offsets_index[4] = int(value)


func _on_front_left_spin_box_value_changed(value: float) -> void:
	if len(pack_data.data.offsets_index) > 5:
		pack_data.data.offsets_index[5] = int(value)


func _on_left_spin_box_value_changed(value: float) -> void:
	if len(pack_data.data.offsets_index) > 6:
		pack_data.data.offsets_index[6] = int(value)


func _on_back_left_spin_box_value_changed(value: float) -> void:
	if len(pack_data.data.offsets_index) > 7:
		pack_data.data.offsets_index[7] = int(value)


func _on_back_spin_box_value_changed(value: float) -> void:
	if len(pack_data.data.offsets_index) > 0:
		pack_data.data.offsets_index[0] = int(value)


func _on_back_right_spin_box_value_changed(value: float) -> void:
	if len(pack_data.data.offsets_index) > 1:
		pack_data.data.offsets_index[1] = int(value)


func _on_right_spin_box_value_changed(value: float) -> void:
	if len(pack_data.data.offsets_index) > 2:
		pack_data.data.offsets_index[2] = int(value)


func _on_front_right_spin_box_value_changed(value: float) -> void:
	if len(pack_data.data.offsets_index) > 3:
		pack_data.data.offsets_index[3] = int(value)


func _on_image_count_spin_box_value_changed(value: float) -> void:
	if len(pack_data.data.image_pack) > value:
		while len(pack_data.data.image_pack) > value:
			pack_data.data.image_pack.pop_back()
		redraw_textures()
		update_max_image_count()
	elif len(pack_data.data.image_pack) < value:
		while len(pack_data.data.image_pack) < value:
			var raw_image := PackedByteArray()
			raw_image.resize(16*16)
			var new_data := {
				"modifier": 0,
				"image_type": 0,
				"width": 16,
				"height": 16,
				"raw_image": raw_image
			}
			pack_data.data.image_pack.append(new_data)
		while len(pack_data.data.offsets_flipped) < value:
			pack_data.data.offsets_flipped.append(false)
		redraw_textures()
		update_max_image_count()


func _on_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			copied_image_data = pack_data.data.image_pack[right_clicked_frame].duplicate()
		1:
			pack_data.data.image_pack[right_clicked_frame] = copied_image_data.duplicate()
			redraw_textures()
		2:
			if await Dialog.confirm("Are you sure?", "Delete Frame", false, Vector2(400,150)):
				pack_data.data.image_pack.pop_at(right_clicked_frame)
				%ImagesContainer.get_child(right_clicked_frame*2).queue_free()
				%ImagesContainer.get_child(right_clicked_frame*2+1).queue_free()
				%ImageCountSpinBox.set_value_no_signal(len(pack_data.data.image_pack))
