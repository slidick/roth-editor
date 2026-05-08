extends Control

signal jump_to_index_pressed(index: int)

var directional_data: Dictionary = {}
var raw_palette: PackedByteArray = []
var das: Dictionary = {}

@onready var node_mapping: Dictionary = {
	%BackTextureContainer: "dir_1_fat_idx",
	%BackRightTextureContainer: "dir_2_fat_idx",
	%RightTextureContainer: "dir_3_fat_idx",
	%FrontRightTextureContainer: "dir_4_fat_idx",
	%FrontTextureContainer: "dir_5_fat_idx",
	%FrontLeftTextureContainer: "dir_6_fat_idx",
	%LeftTextureContainer: "dir_7_fat_idx",
	%BackLeftTextureContainer: "dir_8_fat_idx",
}


func load_directional_data(p_directional_data: Dictionary, is_fat_3: bool, p_das: Dictionary) -> void:
	directional_data = p_directional_data
	das = p_das
	if das.raw_palette.is_empty():
		raw_palette = Das.DEFAULT_RAW_PALETTE
	else:
		raw_palette = das.raw_palette
	if is_fat_3:
		%ObjectCollision.show()
		%CollisionHeightSpinBox.set_value_no_signal(directional_data.object_collision.raw_data & 65535)
		%CollisionHeightSpinBox.get_line_edit().text = "%d" % int(directional_data.object_collision.raw_data & 65535)
		%CollisionRadiusSpinBox.set_value_no_signal((directional_data.object_collision.raw_data & 4294901760) >> 16)
		%CollisionRadiusSpinBox.get_line_edit().text = "%d" % (int(directional_data.object_collision.raw_data & 4294901760) >> 16)
	else:
		%ObjectCollision.hide()
	
	%NameEdit.text = directional_data.filename.name
	%DescriptionEdit.text = directional_data.filename.desc
	
	load_mapping_data()


func load_mapping_data() -> void:
	var mapping: Dictionary = directional_data.directional_mapping
	
	%BackIndexSpinBox.max_value = len(das.fat_1) + len(das.fat_2) + len(das.fat_3) + len(das.fat_4) - 1
	%BackRightIndexSpinBox.max_value = len(das.fat_1) + len(das.fat_2) + len(das.fat_3) + len(das.fat_4) - 1
	%RightIndexSpinBox.max_value = len(das.fat_1) + len(das.fat_2) + len(das.fat_3) + len(das.fat_4) - 1
	%FrontRightIndexSpinBox.max_value = len(das.fat_1) + len(das.fat_2) + len(das.fat_3) + len(das.fat_4) - 1
	%FrontIndexSpinBox.max_value = len(das.fat_1) + len(das.fat_2) + len(das.fat_3) + len(das.fat_4) - 1
	%FrontLeftIndexSpinBox.max_value = len(das.fat_1) + len(das.fat_2) + len(das.fat_3) + len(das.fat_4) - 1
	%LeftIndexSpinBox.max_value = len(das.fat_1) + len(das.fat_2) + len(das.fat_3) + len(das.fat_4) - 1
	%BackLeftIndexSpinBox.max_value = len(das.fat_1) + len(das.fat_2) + len(das.fat_3) + len(das.fat_4) - 1
	
	if das.das_info.is_ademo:
		%BackIndexSpinBox.min_value = -1
		%BackRightIndexSpinBox.min_value = -1
		%RightIndexSpinBox.min_value = -1
		%FrontRightIndexSpinBox.min_value = -1
		%FrontIndexSpinBox.min_value = -1
		%FrontLeftIndexSpinBox.min_value = -1
		%LeftIndexSpinBox.min_value = -1
		%BackLeftIndexSpinBox.min_value = -1
		
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
		%BackIndexSpinBox.min_value = 0
		%BackRightIndexSpinBox.min_value = 0
		%RightIndexSpinBox.min_value = 0
		%FrontRightIndexSpinBox.min_value = 0
		%FrontIndexSpinBox.min_value = 0
		%FrontLeftIndexSpinBox.min_value = 0
		%LeftIndexSpinBox.min_value = 0
		%BackLeftIndexSpinBox.min_value = 0
		
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
	var mapping: Dictionary = directional_data.directional_mapping
	
	for texture_container: RothTextureContainer in node_mapping:
		var fat_4_index: int = (mapping[node_mapping[texture_container]] & 0x7FFF) - (len(das.fat_1) + len(das.fat_2) + len(das.fat_3))
		var fat_3_index: int = (mapping[node_mapping[texture_container]] & 0x7FFF) - (len(das.fat_1) + len(das.fat_2))
		var fat_2_index: int = (mapping[node_mapping[texture_container]] & 0x7FFF) - (len(das.fat_1))
		var fat_1_index: int = (mapping[node_mapping[texture_container]] & 0x7FFF)
		if das.das_info.is_ademo:
			fat_4_index -= 4608
			fat_3_index -= 4608
			fat_2_index -= 4608
			fat_1_index -= 4608
		if mapping[node_mapping[texture_container]] & 0x7FFF >= 0:
			if fat_4_index >= 0:
				texture_container.load_data(das.fat_4[fat_4_index], raw_palette)
			elif fat_3_index >= 0:
				texture_container.load_data(das.fat_3[fat_3_index], raw_palette)
			elif fat_2_index >= 0:
				texture_container.load_data(das.fat_2[fat_2_index], raw_palette)
			elif fat_1_index >= 0:
				texture_container.load_data(das.fat_1[fat_1_index], raw_palette)
			else:
				texture_container.clear()
		else:
			texture_container.clear()
		if (mapping[node_mapping[texture_container]] & 0x8000):
			texture_container.mirror = true
		else:
			texture_container.mirror = false


func _on_name_edit_text_changed(new_text: String) -> void:
	directional_data.filename.name = new_text


func _on_description_edit_text_changed(new_text: String) -> void:
	directional_data.filename.desc = new_text


func _on_collision_height_spin_box_value_changed(value: float) -> void:
	directional_data.object_collision.raw_data = int(%CollisionHeightSpinBox.value) + (int(%CollisionRadiusSpinBox.value) << 16)


func _on_collision_radius_spin_box_value_changed(value: float) -> void:
	directional_data.object_collision.raw_data = int(%CollisionHeightSpinBox.value) + (int(%CollisionRadiusSpinBox.value) << 16)


func _on_jump_to_front_button_pressed() -> void:
	var mapping: Dictionary = directional_data.directional_mapping
	if das.das_info.is_ademo:
		jump_to_index_pressed.emit((mapping.dir_5_fat_idx & 0x7FFF) - 4608)
	else:
		jump_to_index_pressed.emit(mapping.dir_5_fat_idx & 0x7FFF)


func _on_jump_to_front_left_button_pressed() -> void:
	var mapping: Dictionary = directional_data.directional_mapping
	if das.das_info.is_ademo:
		jump_to_index_pressed.emit((mapping.dir_6_fat_idx & 0x7FFF) - 4608)
	else:
		jump_to_index_pressed.emit(mapping.dir_6_fat_idx & 0x7FFF)


func _on_jump_to_left_button_pressed() -> void:
	var mapping: Dictionary = directional_data.directional_mapping
	if das.das_info.is_ademo:
		jump_to_index_pressed.emit((mapping.dir_7_fat_idx & 0x7FFF) - 4608)
	else:
		jump_to_index_pressed.emit(mapping.dir_7_fat_idx & 0x7FFF)


func _on_jump_to_back_left_button_pressed() -> void:
	var mapping: Dictionary = directional_data.directional_mapping
	if das.das_info.is_ademo:
		jump_to_index_pressed.emit((mapping.dir_8_fat_idx & 0x7FFF) - 4608)
	else:
		jump_to_index_pressed.emit(mapping.dir_8_fat_idx & 0x7FFF)


func _on_jump_to_back_button_pressed() -> void:
	var mapping: Dictionary = directional_data.directional_mapping
	if das.das_info.is_ademo:
		jump_to_index_pressed.emit((mapping.dir_1_fat_idx & 0x7FFF) - 4608)
	else:
		jump_to_index_pressed.emit(mapping.dir_1_fat_idx & 0x7FFF)


func _on_jump_to_back_right_button_pressed() -> void:
	var mapping: Dictionary = directional_data.directional_mapping
	if das.das_info.is_ademo:
		jump_to_index_pressed.emit((mapping.dir_2_fat_idx & 0x7FFF) - 4608)
	else:
		jump_to_index_pressed.emit(mapping.dir_2_fat_idx & 0x7FFF)


func _on_jump_to_right_button_pressed() -> void:
	var mapping: Dictionary = directional_data.directional_mapping
	if das.das_info.is_ademo:
		jump_to_index_pressed.emit((mapping.dir_3_fat_idx & 0x7FFF) - 4608)
	else:
		jump_to_index_pressed.emit(mapping.dir_3_fat_idx & 0x7FFF)


func _on_jump_to_front_right_button_pressed() -> void:
	var mapping: Dictionary = directional_data.directional_mapping
	if das.das_info.is_ademo:
		jump_to_index_pressed.emit((mapping.dir_4_fat_idx & 0x7FFF) - 4608)
	else:
		jump_to_index_pressed.emit(mapping.dir_4_fat_idx & 0x7FFF)


func _on_front_index_spin_box_value_changed(value: float) -> void:
	var mapping: Dictionary = directional_data.directional_mapping
	if int(value) == -1:
		mapping.dir_5_fat_idx = 0
	elif das.das_info.is_ademo:
		mapping.dir_5_fat_idx = (int(value) + 4608) | (0x8000 if %FrontMirroredCheckBox.button_pressed else 0)
	else:
		mapping.dir_5_fat_idx = int(value) | (0x8000 if %FrontMirroredCheckBox.button_pressed else 0)
	update_textures()


func _on_front_left_index_spin_box_value_changed(value: float) -> void:
	var mapping: Dictionary = directional_data.directional_mapping
	if int(value) == -1:
		mapping.dir_6_fat_idx = 0
	elif das.das_info.is_ademo:
		mapping.dir_6_fat_idx = (int(value) + 4608) | (0x8000 if %FrontLeftMirroredCheckBox.button_pressed else 0)
	else:
		mapping.dir_6_fat_idx = int(value) | (0x8000 if %FrontLeftMirroredCheckBox.button_pressed else 0)
	update_textures()


func _on_left_index_spin_box_value_changed(value: float) -> void:
	var mapping: Dictionary = directional_data.directional_mapping
	if int(value) == -1:
		mapping.dir_7_fat_idx = 0
	elif das.das_info.is_ademo:
		mapping.dir_7_fat_idx = (int(value) + 4608) | (0x8000 if %LeftMirroredCheckBox.button_pressed else 0)
	else:
		mapping.dir_7_fat_idx = int(value) | (0x8000 if %LeftMirroredCheckBox.button_pressed else 0)
	update_textures()


func _on_back_left_index_spin_box_value_changed(value: float) -> void:
	var mapping: Dictionary = directional_data.directional_mapping
	if int(value) == -1:
		mapping.dir_8_fat_idx = 0
	elif das.das_info.is_ademo:
		mapping.dir_8_fat_idx = (int(value) + 4608) | (0x8000 if %BackLeftMirroredCheckBox.button_pressed else 0)
	else:
		mapping.dir_8_fat_idx = int(value) | (0x8000 if %BackLeftMirroredCheckBox.button_pressed else 0)
	update_textures()


func _on_back_index_spin_box_value_changed(value: float) -> void:
	var mapping: Dictionary = directional_data.directional_mapping
	if int(value) == -1:
		mapping.dir_1_fat_idx = 0
	elif das.das_info.is_ademo:
		mapping.dir_1_fat_idx = (int(value) + 4608) | (0x8000 if %BackMirroredCheckBox.button_pressed else 0)
	else:
		mapping.dir_1_fat_idx = int(value) | (0x8000 if %BackMirroredCheckBox.button_pressed else 0)
	update_textures()


func _on_back_right_index_spin_box_value_changed(value: float) -> void:
	var mapping: Dictionary = directional_data.directional_mapping
	if int(value) == -1:
		mapping.dir_2_fat_idx = 0
	elif das.das_info.is_ademo:
		mapping.dir_2_fat_idx = (int(value) + 4608) | (0x8000 if %BackRightMirroredCheckBox.button_pressed else 0)
	else:
		mapping.dir_2_fat_idx = int(value) | (0x8000 if %BackRightMirroredCheckBox.button_pressed else 0)
	update_textures()


func _on_right_index_spin_box_value_changed(value: float) -> void:
	var mapping: Dictionary = directional_data.directional_mapping
	if int(value) == -1:
		mapping.dir_3_fat_idx = 0
	elif das.das_info.is_ademo:
		mapping.dir_3_fat_idx = (int(value) + 4608) | (0x8000 if %RightMirroredCheckBox.button_pressed else 0)
	else:
		mapping.dir_3_fat_idx = int(value) | (0x8000 if %RightMirroredCheckBox.button_pressed else 0)
	update_textures()


func _on_front_right_index_spin_box_value_changed(value: float) -> void:
	var mapping: Dictionary = directional_data.directional_mapping
	if int(value) == -1:
		mapping.dir_4_fat_idx = 0
	elif das.das_info.is_ademo:
		mapping.dir_4_fat_idx = (int(value) + 4608) | (0x8000 if %FrontRightMirroredCheckBox.button_pressed else 0)
	else:
		mapping.dir_4_fat_idx = int(value) | (0x8000 if %FrontRightMirroredCheckBox.button_pressed else 0)
	update_textures()


func _on_front_mirrored_check_box_toggled(toggled_on: bool) -> void:
	var mapping: Dictionary = directional_data.directional_mapping
	if toggled_on:
		mapping.dir_5_fat_idx |= 0x8000
	else:
		mapping.dir_5_fat_idx &= ~0x8000
	update_textures()


func _on_front_left_mirrored_check_box_toggled(toggled_on: bool) -> void:
	var mapping: Dictionary = directional_data.directional_mapping
	if toggled_on:
		mapping.dir_6_fat_idx |= 0x8000
	else:
		mapping.dir_6_fat_idx &= ~0x8000
	update_textures()


func _on_left_mirrored_check_box_toggled(toggled_on: bool) -> void:
	var mapping: Dictionary = directional_data.directional_mapping
	if toggled_on:
		mapping.dir_7_fat_idx |= 0x8000
	else:
		mapping.dir_7_fat_idx &= ~0x8000
	update_textures()


func _on_back_left_mirrored_check_box_toggled(toggled_on: bool) -> void:
	var mapping: Dictionary = directional_data.directional_mapping
	if toggled_on:
		mapping.dir_8_fat_idx |= 0x8000
	else:
		mapping.dir_8_fat_idx &= ~0x8000
	update_textures()


func _on_back_mirrored_check_box_toggled(toggled_on: bool) -> void:
	var mapping: Dictionary = directional_data.directional_mapping
	if toggled_on:
		mapping.dir_1_fat_idx |= 0x8000
	else:
		mapping.dir_1_fat_idx &= ~0x8000
	update_textures()


func _on_back_right_mirrored_check_box_toggled(toggled_on: bool) -> void:
	var mapping: Dictionary = directional_data.directional_mapping
	if toggled_on:
		mapping.dir_2_fat_idx |= 0x8000
	else:
		mapping.dir_2_fat_idx &= ~0x8000
	update_textures()


func _on_right_mirrored_check_box_toggled(toggled_on: bool) -> void:
	var mapping: Dictionary = directional_data.directional_mapping
	if toggled_on:
		mapping.dir_3_fat_idx |= 0x8000
	else:
		mapping.dir_3_fat_idx &= ~0x8000
	update_textures()


func _on_front_right_mirrored_check_box_toggled(toggled_on: bool) -> void:
	var mapping: Dictionary = directional_data.directional_mapping
	if toggled_on:
		mapping.dir_4_fat_idx |= 0x8000
	else:
		mapping.dir_4_fat_idx &= ~0x8000
	update_textures()
