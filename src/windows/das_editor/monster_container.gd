extends Control

signal jump_to_collision_pressed
signal jump_to_filename_pressed(filename: Dictionary)

var monster_data: Dictionary = {}
var raw_palette: PackedByteArray = []
var monster_mappings: Array = []


func load_monster_data(p_monster_data: Dictionary, p_monster_mappings: Array, p_raw_palette: Array = [], is_fat_3: bool = false) -> void:
	monster_data = p_monster_data
	monster_mappings = p_monster_mappings
	if p_raw_palette.is_empty():
		raw_palette = Das.DEFAULT_RAW_PALETTE
	else:
		raw_palette = p_raw_palette
	if is_fat_3:
		%JumpToObjectCollisionButton.show()
	else:
		%JumpToObjectCollisionButton.hide()
	
	%Flags1Edit.text = str(monster_data.flags_1)
	%Flags2SpinBox.set_value_no_signal(monster_data.flags_2)
	%Flags2SpinBox.max_value = len(monster_mappings) - 1
	if "filename" in monster_data:
		%NameEdit.text = monster_data.filename.name
		%DescriptionEdit.text = monster_data.filename.desc
		%JumpToFilenameButton.show()
		%AddFilenameButton.hide()
	else:
		%NameEdit.text = "No Name Set"
		%DescriptionEdit.text = ""
		%JumpToFilenameButton.hide()
		%AddFilenameButton.show()
	
	update_flags_1_checkboxes()


func update_flags_1_checkboxes() -> void:
	%Flags1CheckBox1.button_pressed = (monster_data.flags_1 & (1<<0)) > 0
	%Flags1CheckBox2.button_pressed = (monster_data.flags_1 & (1<<1)) > 0
	%Flags1CheckBox3.button_pressed = (monster_data.flags_1 & (1<<2)) > 0
	%Flags1CheckBox4.button_pressed = (monster_data.flags_1 & (1<<3)) > 0
	%Flags1CheckBox5.button_pressed = (monster_data.flags_1 & (1<<4)) > 0
	%Flags1CheckBox6.button_pressed = (monster_data.flags_1 & (1<<5)) > 0
	%Flags1CheckBox7.button_pressed = (monster_data.flags_1 & (1<<6)) > 0
	%Flags1CheckBox8.button_pressed = (monster_data.flags_1 & (1<<7)) > 0


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
	monster_data.flags_1 = new_value
	%Flags1Edit.text = str(new_value)


func _on_name_edit_text_changed(new_text: String) -> void:
	monster_data.filename.name = new_text


func _on_description_edit_text_changed(new_text: String) -> void:
	monster_data.filename.desc = new_text


func _on_jump_to_filename_button_pressed() -> void:
	jump_to_filename_pressed.emit(monster_data.filename)


func _on_add_filename_button_pressed() -> void:
	if owner.name == "Fat1" or owner.name == "Fat2":
		monster_data["filename"] = owner.owner._on_add_filename_pressed(1, monster_data.index)
	else:
		monster_data["filename"] = owner.owner._on_add_filename_pressed(2, monster_data.index)
	%NameEdit.text = "%s (%s)" % [monster_data.filename.name, monster_data.filename.desc]


func _on_jump_to_object_collision_button_pressed() -> void:
	jump_to_collision_pressed.emit()


func _on_flags_1_edit_text_changed(new_text: String) -> void:
	monster_data.flags_1 = int(new_text)
	update_flags_1_checkboxes()


func _on_flags_2_spin_box_value_changed(value: float) -> void:
	monster_data.flags_2 = int(value)


func _on_flags_1_check_box_pressed() -> void:
	update_flags_1_from_checkboxes()
