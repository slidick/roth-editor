extends Control

signal jump_to_collision_pressed
signal jump_to_filename_pressed(filename: Dictionary)
signal jump_to_index_pressed(index: int)
signal directional_object_added

var directional_data: Dictionary = {}
var raw_palette: PackedByteArray = []
var directional_mappings: Array = []
var das: Dictionary = {}

func load_directional_data(p_directional_data: Dictionary, p_directional_mappings: Array, is_fat_3: bool, p_das: Dictionary) -> void:
	directional_data = p_directional_data
	directional_mappings = p_directional_mappings
	das = p_das
	if das.raw_palette.is_empty():
		raw_palette = Das.DEFAULT_RAW_PALETTE
	else:
		raw_palette = das.raw_palette
	if is_fat_3:
		%JumpToObjectCollisionButton.show()
		%ObjectCollision.show()
		%CollisionHeightSpinBox.set_value_no_signal(directional_data.object_collision.raw_data & 65535)
		%CollisionHeightSpinBox.get_line_edit().text = "%d" % int(directional_data.object_collision.raw_data & 65535)
		%CollisionRadiusSpinBox.set_value_no_signal((directional_data.object_collision.raw_data & 4294901760) >> 16)
		%CollisionRadiusSpinBox.get_line_edit().text = "%d" % (int(directional_data.object_collision.raw_data & 4294901760) >> 16)
	else:
		%JumpToObjectCollisionButton.hide()
		%ObjectCollision.hide()
	
	%Flags1Edit.text = str(directional_data.flags_1)
	%Flags2SpinBox.set_value_no_signal(directional_data.flags_2)
	%Flags2SpinBox.max_value = len(directional_mappings) - 1
	if "filename" in directional_data:
		%NameEdit.text = directional_data.filename.name
		%DescriptionEdit.text = directional_data.filename.desc
		%JumpToFilenameButton.show()
		%AddFilenameButton.hide()
	else:
		%NameEdit.text = "No Name Set"
		%DescriptionEdit.text = ""
		%JumpToFilenameButton.hide()
		%AddFilenameButton.show()
	
	update_flags_1_checkboxes()
	load_mapping_data()


func load_mapping_data() -> void:
	if directional_data.flags_2+1 > len(directional_mappings):
		while directional_data.flags_2+1 > len(directional_mappings):
			_on_add_directional_button_pressed()
		return
	
	var mapping: Dictionary = directional_mappings[directional_data.flags_2]
	
	if das.das_info.is_ademo:
		%BackIndexSpinBox.set_value_no_signal((mapping.dir_1_fat_idx & 0x7FFF) - 4608)
		%BackRightIndexSpinBox.set_value_no_signal((mapping.dir_2_fat_idx & 0x7FFF) - 4608)
		%RightIndexSpinBox.set_value_no_signal((mapping.dir_3_fat_idx & 0x7FFF) - 4608)
		%FrontRightIndexSpinBox.set_value_no_signal((mapping.dir_4_fat_idx & 0x7FFF) - 4608)
		%FrontIndexSpinBox.set_value_no_signal((mapping.dir_5_fat_idx & 0x7FFF) - 4608)
		%FrontLeftIndexSpinBox.set_value_no_signal((mapping.dir_6_fat_idx & 0x7FFF) - 4608)
		%LeftIndexSpinBox.set_value_no_signal((mapping.dir_7_fat_idx & 0x7FFF) - 4608)
		%BackLeftIndexSpinBox.set_value_no_signal((mapping.dir_8_fat_idx & 0x7FFF) - 4608)
		%BackIndexSpinBox.get_line_edit().text = str((mapping.dir_1_fat_idx & 0x7FFF) - 4608)
		%BackRightIndexSpinBox.get_line_edit().text = str((mapping.dir_2_fat_idx & 0x7FFF) - 4608)
		%RightIndexSpinBox.get_line_edit().text = str((mapping.dir_3_fat_idx & 0x7FFF) - 4608)
		%FrontRightIndexSpinBox.get_line_edit().text = str((mapping.dir_4_fat_idx & 0x7FFF) - 4608)
		%FrontIndexSpinBox.get_line_edit().text = str((mapping.dir_5_fat_idx & 0x7FFF) - 4608)
		%FrontLeftIndexSpinBox.get_line_edit().text = str((mapping.dir_6_fat_idx & 0x7FFF) - 4608)
		%LeftIndexSpinBox.get_line_edit().text = str((mapping.dir_7_fat_idx & 0x7FFF) - 4608)
		%BackLeftIndexSpinBox.get_line_edit().text = str((mapping.dir_8_fat_idx & 0x7FFF) - 4608)
	
	else:
		%BackIndexSpinBox.set_value_no_signal((mapping.dir_1_fat_idx & 0x7FFF))
		%BackRightIndexSpinBox.set_value_no_signal((mapping.dir_2_fat_idx & 0x7FFF))
		%RightIndexSpinBox.set_value_no_signal((mapping.dir_3_fat_idx & 0x7FFF))
		%FrontRightIndexSpinBox.set_value_no_signal((mapping.dir_4_fat_idx & 0x7FFF))
		%FrontIndexSpinBox.set_value_no_signal((mapping.dir_5_fat_idx & 0x7FFF))
		%FrontLeftIndexSpinBox.set_value_no_signal((mapping.dir_6_fat_idx & 0x7FFF))
		%LeftIndexSpinBox.set_value_no_signal((mapping.dir_7_fat_idx & 0x7FFF))
		%BackLeftIndexSpinBox.set_value_no_signal((mapping.dir_8_fat_idx & 0x7FFF))
		%BackIndexSpinBox.get_line_edit().text = str(mapping.dir_1_fat_idx & 0x7FFF)
		%BackRightIndexSpinBox.get_line_edit().text = str(mapping.dir_2_fat_idx & 0x7FFF)
		%RightIndexSpinBox.get_line_edit().text = str(mapping.dir_3_fat_idx & 0x7FFF)
		%FrontRightIndexSpinBox.get_line_edit().text = str(mapping.dir_4_fat_idx & 0x7FFF)
		%FrontIndexSpinBox.get_line_edit().text = str(mapping.dir_5_fat_idx & 0x7FFF)
		%FrontLeftIndexSpinBox.get_line_edit().text = str(mapping.dir_6_fat_idx & 0x7FFF)
		%LeftIndexSpinBox.get_line_edit().text = str(mapping.dir_7_fat_idx & 0x7FFF)
		%BackLeftIndexSpinBox.get_line_edit().text = str(mapping.dir_8_fat_idx & 0x7FFF)
	
	
	%BackIndexSpinBox.min_value = len(das.fat_1) + len(das.fat_2) + len(das.fat_3)
	%BackIndexSpinBox.max_value = len(das.fat_1) + len(das.fat_2) + len(das.fat_3) + len(das.fat_4) - 1
	%BackRightIndexSpinBox.min_value = len(das.fat_1) + len(das.fat_2) + len(das.fat_3)
	%BackRightIndexSpinBox.max_value = len(das.fat_1) + len(das.fat_2) + len(das.fat_3) + len(das.fat_4) - 1
	%RightIndexSpinBox.min_value = len(das.fat_1) + len(das.fat_2) + len(das.fat_3)
	%RightIndexSpinBox.max_value = len(das.fat_1) + len(das.fat_2) + len(das.fat_3) + len(das.fat_4) - 1
	%FrontRightIndexSpinBox.min_value = len(das.fat_1) + len(das.fat_2) + len(das.fat_3)
	%FrontRightIndexSpinBox.max_value = len(das.fat_1) + len(das.fat_2) + len(das.fat_3) + len(das.fat_4) - 1
	%FrontIndexSpinBox.min_value = len(das.fat_1) + len(das.fat_2) + len(das.fat_3)
	%FrontIndexSpinBox.max_value = len(das.fat_1) + len(das.fat_2) + len(das.fat_3) + len(das.fat_4) - 1
	%FrontLeftIndexSpinBox.min_value = len(das.fat_1) + len(das.fat_2) + len(das.fat_3)
	%FrontLeftIndexSpinBox.max_value = len(das.fat_1) + len(das.fat_2) + len(das.fat_3) + len(das.fat_4) - 1
	%LeftIndexSpinBox.min_value = len(das.fat_1) + len(das.fat_2) + len(das.fat_3)
	%LeftIndexSpinBox.max_value = len(das.fat_1) + len(das.fat_2) + len(das.fat_3) + len(das.fat_4) - 1
	%BackLeftIndexSpinBox.min_value = len(das.fat_1) + len(das.fat_2) + len(das.fat_3)
	%BackLeftIndexSpinBox.max_value = len(das.fat_1) + len(das.fat_2) + len(das.fat_3) + len(das.fat_4) - 1
	
	
	%BackMirroredCheckBox.button_pressed = mapping.dir_1_fat_idx & 0x8000
	%BackRightMirroredCheckBox.button_pressed = mapping.dir_2_fat_idx & 0x8000
	%RightMirroredCheckBox.button_pressed = mapping.dir_3_fat_idx & 0x8000
	%FrontRightMirroredCheckBox.button_pressed = mapping.dir_4_fat_idx & 0x8000
	%FrontMirroredCheckBox.button_pressed = mapping.dir_5_fat_idx & 0x8000
	%FrontLeftMirroredCheckBox.button_pressed = mapping.dir_6_fat_idx & 0x8000
	%LeftMirroredCheckBox.button_pressed = mapping.dir_7_fat_idx & 0x8000
	%BackLeftMirroredCheckBox.button_pressed = mapping.dir_8_fat_idx & 0x8000
	
	update_textures()


func update_textures() -> void:
	var mapping: Dictionary = directional_mappings[directional_data.flags_2]
	
	var fat_4_index: int = (mapping.dir_1_fat_idx & 0x7FFF) - (len(das.fat_1) + len(das.fat_2) + len(das.fat_3))
	if das.das_info.is_ademo:
		fat_4_index -= 4608
	
	if len(das.fat_4) == 0:
		owner.owner.add_fat_4_entry()
	
	%BackTextureContainer.load_data(das.fat_4[fat_4_index], raw_palette)
	if (mapping.dir_1_fat_idx & 0x8000):
		%BackTextureContainer.mirror = true
	else:
		%BackTextureContainer.mirror = false
	
	fat_4_index = (mapping.dir_2_fat_idx & 0x7FFF) - (len(das.fat_1) + len(das.fat_2) + len(das.fat_3))
	if das.das_info.is_ademo:
		fat_4_index -= 4608
	%BackRightTextureContainer.load_data(das.fat_4[fat_4_index], raw_palette)
	if (mapping.dir_2_fat_idx & 0x8000):
		%BackRightTextureContainer.mirror = true
	else:
		%BackRightTextureContainer.mirror = false
	
	fat_4_index = (mapping.dir_3_fat_idx & 0x7FFF) - (len(das.fat_1) + len(das.fat_2) + len(das.fat_3))
	if das.das_info.is_ademo:
		fat_4_index -= 4608
	%RightTextureContainer.load_data(das.fat_4[fat_4_index], raw_palette)
	if (mapping.dir_3_fat_idx & 0x8000):
		%RightTextureContainer.mirror = true
	else:
		%RightTextureContainer.mirror = false
	
	fat_4_index = (mapping.dir_4_fat_idx & 0x7FFF) - (len(das.fat_1) + len(das.fat_2) + len(das.fat_3))
	if das.das_info.is_ademo:
		fat_4_index -= 4608
	%FrontRightTextureContainer.load_data(das.fat_4[fat_4_index], raw_palette)
	if (mapping.dir_4_fat_idx & 0x8000):
		%FrontRightTextureContainer.mirror = true
	else:
		%FrontRightTextureContainer.mirror = false
	
	fat_4_index = (mapping.dir_5_fat_idx & 0x7FFF) - (len(das.fat_1) + len(das.fat_2) + len(das.fat_3))
	if das.das_info.is_ademo:
		fat_4_index -= 4608
	%FrontTextureContainer.load_data(das.fat_4[fat_4_index], raw_palette)
	if (mapping.dir_5_fat_idx & 0x8000):
		%FrontTextureContainer.mirror = true
	else:
		%FrontTextureContainer.mirror = false
	
	fat_4_index = (mapping.dir_6_fat_idx & 0x7FFF) - (len(das.fat_1) + len(das.fat_2) + len(das.fat_3))
	if das.das_info.is_ademo:
		fat_4_index -= 4608
	%FrontLeftTextureContainer.load_data(das.fat_4[fat_4_index], raw_palette)
	if (mapping.dir_6_fat_idx & 0x8000):
		%FrontLeftTextureContainer.mirror = true
	else:
		%FrontLeftTextureContainer.mirror = false
	
	fat_4_index = (mapping.dir_7_fat_idx & 0x7FFF) - (len(das.fat_1) + len(das.fat_2) + len(das.fat_3))
	if das.das_info.is_ademo:
		fat_4_index -= 4608
	%LeftTextureContainer.load_data(das.fat_4[fat_4_index], raw_palette)
	if (mapping.dir_7_fat_idx & 0x8000):
		%LeftTextureContainer.mirror = true
	else:
		%LeftTextureContainer.mirror = false
	
	fat_4_index = (mapping.dir_8_fat_idx & 0x7FFF) - (len(das.fat_1) + len(das.fat_2) + len(das.fat_3))
	if das.das_info.is_ademo:
		fat_4_index -= 4608
	%BackLeftTextureContainer.load_data(das.fat_4[fat_4_index], raw_palette)
	if (mapping.dir_8_fat_idx & 0x8000):
		%BackLeftTextureContainer.mirror = true
	else:
		%BackLeftTextureContainer.mirror = false


func update_flags_1_checkboxes() -> void:
	%Flags1CheckBox1.button_pressed = (directional_data.flags_1 & (1<<0)) > 0
	%Flags1CheckBox2.button_pressed = (directional_data.flags_1 & (1<<1)) > 0
	%Flags1CheckBox3.button_pressed = (directional_data.flags_1 & (1<<2)) > 0
	%Flags1CheckBox4.button_pressed = (directional_data.flags_1 & (1<<3)) > 0
	%Flags1CheckBox5.button_pressed = (directional_data.flags_1 & (1<<4)) > 0
	%Flags1CheckBox6.button_pressed = (directional_data.flags_1 & (1<<5)) > 0
	%Flags1CheckBox7.button_pressed = (directional_data.flags_1 & (1<<6)) > 0
	%Flags1CheckBox8.button_pressed = (directional_data.flags_1 & (1<<7)) > 0


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
	directional_data.flags_1 = new_value
	%Flags1Edit.text = str(new_value)


func _on_name_edit_text_changed(new_text: String) -> void:
	directional_data.filename.name = new_text


func _on_description_edit_text_changed(new_text: String) -> void:
	directional_data.filename.desc = new_text


func _on_jump_to_filename_button_pressed() -> void:
	jump_to_filename_pressed.emit(directional_data.filename)


func _on_add_filename_button_pressed() -> void:
	if owner.name == "Fat1" or owner.name == "Fat2":
		directional_data["filename"] = owner.owner._on_add_filename_pressed(1, directional_data.index)
	else:
		directional_data["filename"] = owner.owner._on_add_filename_pressed(2, directional_data.index)
	%NameEdit.text = "%s (%s)" % [directional_data.filename.name, directional_data.filename.desc]


func _on_jump_to_object_collision_button_pressed() -> void:
	jump_to_collision_pressed.emit()


func _on_flags_1_edit_text_changed(new_text: String) -> void:
	directional_data.flags_1 = int(new_text)
	update_flags_1_checkboxes()


func _on_flags_2_spin_box_value_changed(value: float) -> void:
	directional_data.flags_2 = int(value)
	load_mapping_data()


func _on_flags_1_check_box_pressed() -> void:
	update_flags_1_from_checkboxes()


func _on_jump_to_front_button_pressed() -> void:
	var mapping: Dictionary = directional_mappings[directional_data.flags_2]
	if das.das_info.is_ademo:
		jump_to_index_pressed.emit((mapping.dir_5_fat_idx & 0x7FFF) - 4608)
	else:
		jump_to_index_pressed.emit(mapping.dir_5_fat_idx & 0x7FFF)


func _on_jump_to_front_left_button_pressed() -> void:
	var mapping: Dictionary = directional_mappings[directional_data.flags_2]
	if das.das_info.is_ademo:
		jump_to_index_pressed.emit((mapping.dir_6_fat_idx & 0x7FFF) - 4608)
	else:
		jump_to_index_pressed.emit(mapping.dir_6_fat_idx & 0x7FFF)


func _on_jump_to_left_button_pressed() -> void:
	var mapping: Dictionary = directional_mappings[directional_data.flags_2]
	if das.das_info.is_ademo:
		jump_to_index_pressed.emit((mapping.dir_7_fat_idx & 0x7FFF) - 4608)
	else:
		jump_to_index_pressed.emit(mapping.dir_7_fat_idx & 0x7FFF)


func _on_jump_to_back_left_button_pressed() -> void:
	var mapping: Dictionary = directional_mappings[directional_data.flags_2]
	if das.das_info.is_ademo:
		jump_to_index_pressed.emit((mapping.dir_8_fat_idx & 0x7FFF) - 4608)
	else:
		jump_to_index_pressed.emit(mapping.dir_8_fat_idx & 0x7FFF)


func _on_jump_to_back_button_pressed() -> void:
	var mapping: Dictionary = directional_mappings[directional_data.flags_2]
	if das.das_info.is_ademo:
		jump_to_index_pressed.emit((mapping.dir_1_fat_idx & 0x7FFF) - 4608)
	else:
		jump_to_index_pressed.emit(mapping.dir_1_fat_idx & 0x7FFF)


func _on_jump_to_back_right_button_pressed() -> void:
	var mapping: Dictionary = directional_mappings[directional_data.flags_2]
	if das.das_info.is_ademo:
		jump_to_index_pressed.emit((mapping.dir_2_fat_idx & 0x7FFF) - 4608)
	else:
		jump_to_index_pressed.emit(mapping.dir_2_fat_idx & 0x7FFF)


func _on_jump_to_right_button_pressed() -> void:
	var mapping: Dictionary = directional_mappings[directional_data.flags_2]
	if das.das_info.is_ademo:
		jump_to_index_pressed.emit((mapping.dir_3_fat_idx & 0x7FFF) - 4608)
	else:
		jump_to_index_pressed.emit(mapping.dir_3_fat_idx & 0x7FFF)


func _on_jump_to_front_right_button_pressed() -> void:
	var mapping: Dictionary = directional_mappings[directional_data.flags_2]
	if das.das_info.is_ademo:
		jump_to_index_pressed.emit((mapping.dir_4_fat_idx & 0x7FFF) - 4608)
	else:
		jump_to_index_pressed.emit(mapping.dir_4_fat_idx & 0x7FFF)


func _on_collision_height_spin_box_value_changed(value: float) -> void:
	directional_data.object_collision.raw_data = int(%CollisionHeightSpinBox.value) + (int(%CollisionRadiusSpinBox.value) << 16)


func _on_collision_radius_spin_box_value_changed(value: float) -> void:
	directional_data.object_collision.raw_data = int(%CollisionHeightSpinBox.value) + (int(%CollisionRadiusSpinBox.value) << 16)


func _on_front_index_spin_box_value_changed(value: float) -> void:
	var mapping: Dictionary = directional_mappings[directional_data.flags_2]
	if das.das_info.is_ademo:
		mapping.dir_5_fat_idx = int(value) + 4608
	else:
		mapping.dir_5_fat_idx = int(value) | (0x8000 if %FrontMirroredCheckBox.button_pressed else 0)
	update_textures()


func _on_front_left_index_spin_box_value_changed(value: float) -> void:
	var mapping: Dictionary = directional_mappings[directional_data.flags_2]
	if das.das_info.is_ademo:
		mapping.dir_6_fat_idx = int(value) + 4608
	else:
		mapping.dir_6_fat_idx = int(value) | (0x8000 if %FrontLeftMirroredCheckBox.button_pressed else 0)
	update_textures()


func _on_left_index_spin_box_value_changed(value: float) -> void:
	var mapping: Dictionary = directional_mappings[directional_data.flags_2]
	if das.das_info.is_ademo:
		mapping.dir_7_fat_idx = int(value) + 4608
	else:
		mapping.dir_7_fat_idx = int(value) | (0x8000 if %LeftMirroredCheckBox.button_pressed else 0)
	update_textures()


func _on_back_left_index_spin_box_value_changed(value: float) -> void:
	var mapping: Dictionary = directional_mappings[directional_data.flags_2]
	if das.das_info.is_ademo:
		mapping.dir_8_fat_idx = int(value) + 4608
	else:
		mapping.dir_8_fat_idx = int(value) | (0x8000 if %BackLeftMirroredCheckBox.button_pressed else 0)
	update_textures()


func _on_back_index_spin_box_value_changed(value: float) -> void:
	var mapping: Dictionary = directional_mappings[directional_data.flags_2]
	if das.das_info.is_ademo:
		mapping.dir_1_fat_idx = int(value) + 4608
	else:
		mapping.dir_1_fat_idx = int(value) | (0x8000 if %BackMirroredCheckBox.button_pressed else 0)
	update_textures()


func _on_back_right_index_spin_box_value_changed(value: float) -> void:
	var mapping: Dictionary = directional_mappings[directional_data.flags_2]
	if das.das_info.is_ademo:
		mapping.dir_2_fat_idx = int(value) + 4608
	else:
		mapping.dir_2_fat_idx = int(value) | (0x8000 if %BackRightMirroredCheckBox.button_pressed else 0)
	update_textures()


func _on_right_index_spin_box_value_changed(value: float) -> void:
	var mapping: Dictionary = directional_mappings[directional_data.flags_2]
	if das.das_info.is_ademo:
		mapping.dir_3_fat_idx = int(value) + 4608
	else:
		mapping.dir_3_fat_idx = int(value) | (0x8000 if %RightMirroredCheckBox.button_pressed else 0)
	update_textures()


func _on_front_right_index_spin_box_value_changed(value: float) -> void:
	var mapping: Dictionary = directional_mappings[directional_data.flags_2]
	if das.das_info.is_ademo:
		mapping.dir_4_fat_idx = int(value) + 4608
	else:
		mapping.dir_4_fat_idx = int(value) | (0x8000 if %FrontRightMirroredCheckBox.button_pressed else 0)
	update_textures()


func _on_front_mirrored_check_box_toggled(toggled_on: bool) -> void:
	var mapping: Dictionary = directional_mappings[directional_data.flags_2]
	if toggled_on:
		mapping.dir_5_fat_idx |= 0x8000
	else:
		mapping.dir_5_fat_idx &= ~0x8000
	update_textures()


func _on_front_left_mirrored_check_box_toggled(toggled_on: bool) -> void:
	var mapping: Dictionary = directional_mappings[directional_data.flags_2]
	if toggled_on:
		mapping.dir_6_fat_idx |= 0x8000
	else:
		mapping.dir_6_fat_idx &= ~0x8000
	update_textures()


func _on_left_mirrored_check_box_toggled(toggled_on: bool) -> void:
	var mapping: Dictionary = directional_mappings[directional_data.flags_2]
	if toggled_on:
		mapping.dir_7_fat_idx |= 0x8000
	else:
		mapping.dir_7_fat_idx &= ~0x8000
	update_textures()


func _on_back_left_mirrored_check_box_toggled(toggled_on: bool) -> void:
	var mapping: Dictionary = directional_mappings[directional_data.flags_2]
	if toggled_on:
		mapping.dir_8_fat_idx |= 0x8000
	else:
		mapping.dir_8_fat_idx &= ~0x8000
	update_textures()


func _on_back_mirrored_check_box_toggled(toggled_on: bool) -> void:
	var mapping: Dictionary = directional_mappings[directional_data.flags_2]
	if toggled_on:
		mapping.dir_1_fat_idx |= 0x8000
	else:
		mapping.dir_1_fat_idx &= ~0x8000
	update_textures()


func _on_back_right_mirrored_check_box_toggled(toggled_on: bool) -> void:
	var mapping: Dictionary = directional_mappings[directional_data.flags_2]
	if toggled_on:
		mapping.dir_2_fat_idx |= 0x8000
	else:
		mapping.dir_2_fat_idx &= ~0x8000
	update_textures()


func _on_right_mirrored_check_box_toggled(toggled_on: bool) -> void:
	var mapping: Dictionary = directional_mappings[directional_data.flags_2]
	if toggled_on:
		mapping.dir_3_fat_idx |= 0x8000
	else:
		mapping.dir_3_fat_idx &= ~0x8000
	update_textures()


func _on_front_right_mirrored_check_box_toggled(toggled_on: bool) -> void:
	var mapping: Dictionary = directional_mappings[directional_data.flags_2]
	if toggled_on:
		mapping.dir_4_fat_idx |= 0x8000
	else:
		mapping.dir_4_fat_idx &= ~0x8000
	update_textures()


func _on_add_directional_button_pressed() -> void:
	%Flags2SpinBox.max_value = len(directional_mappings)
	directional_data.flags_2 = len(directional_mappings)
	%Flags2SpinBox.set_value_no_signal(directional_data.flags_2)
	var data: Dictionary = {
		"header": 32784,
		"dir_1_fat_idx": len(das.fat_1) + len(das.fat_2) + len(das.fat_3),
		"dir_2_fat_idx": len(das.fat_1) + len(das.fat_2) + len(das.fat_3),
		"dir_3_fat_idx": len(das.fat_1) + len(das.fat_2) + len(das.fat_3),
		"dir_4_fat_idx": len(das.fat_1) + len(das.fat_2) + len(das.fat_3),
		"dir_5_fat_idx": len(das.fat_1) + len(das.fat_2) + len(das.fat_3),
		"dir_6_fat_idx": len(das.fat_1) + len(das.fat_2) + len(das.fat_3),
		"dir_7_fat_idx": len(das.fat_1) + len(das.fat_2) + len(das.fat_3),
		"dir_8_fat_idx": len(das.fat_1) + len(das.fat_2) + len(das.fat_3),
	}
	if das.das_info.is_ademo:
		data.dir_1_fat_idx += 4608
		data.dir_2_fat_idx += 4608
		data.dir_3_fat_idx += 4608
		data.dir_4_fat_idx += 4608
		data.dir_5_fat_idx += 4608
		data.dir_6_fat_idx += 4608
		data.dir_7_fat_idx += 4608
		data.dir_8_fat_idx += 4608
	directional_mappings.append(data)
	load_mapping_data()
	directional_object_added.emit()


func _on_remove_directional_button_pressed() -> void:
	directional_mappings.pop_at(directional_data.flags_2)
	if directional_data.flags_2 >= len(directional_mappings):
		directional_data.flags_2 = max(len(directional_mappings) - 1, 0)
	%Flags2SpinBox.set_value_no_signal(directional_data.flags_2)
	%Flags2SpinBox.max_value = len(directional_mappings) - 1
	load_mapping_data()
	directional_object_added.emit()
