extends Control

signal jump_to_index_pressed(index: int)

var monster_data: Dictionary = {}
var raw_palette: PackedByteArray = []
var das: Dictionary = {}


func load_monster_data(p_monster_data: Dictionary, p_das: Dictionary) -> void:
	monster_data = p_monster_data
	das = p_das
	if das.raw_palette.is_empty():
		raw_palette = Das.DEFAULT_RAW_PALETTE
	else:
		raw_palette = das.raw_palette
	
	%CollisionHeightSpinBox.set_value_no_signal(monster_data.object_collision.raw_data & 65535)
	%CollisionHeightSpinBox.get_line_edit().text = "%d" % int(monster_data.object_collision.raw_data & 65535)
	%CollisionRadiusSpinBox.set_value_no_signal((monster_data.object_collision.raw_data & 4294901760) >> 16)
	%CollisionRadiusSpinBox.get_line_edit().text = "%d" % (int(monster_data.object_collision.raw_data & 4294901760) >> 16)
	
	%NameEdit.text = monster_data.filename.name
	%DescriptionEdit.text = monster_data.filename.desc
	
	load_textures()


func load_textures() -> void:
	for node: Node in %Container.get_children():
		node.queue_free()
	for type: String in ["walking", "flying", "attack1", "attack2", "on_damage"]:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 20)
		
		var section_vbox := VBoxContainer.new()
		var section_label := Label.new()
		section_label.text = type.to_pascal_case()
		section_vbox.add_child(section_label)
		section_vbox.add_child(hbox)
		
		for direction: String in ["front", "front_left", "left", "back_left", "back", "back_right", "right", "front_right"]:
			var vbox: VBoxContainer = create_vbox(direction, type+"_"+direction)
			hbox.add_child(vbox)
		
		%Container.add_child(section_vbox)
		%Container.add_child(HSeparator.new())
	
	var hbox_2 := HBoxContainer.new()
	hbox_2.add_theme_constant_override("separation", 20)
	
	var section_vbox_2 := VBoxContainer.new()
	var section_label_2 := Label.new()
	section_label_2.text = "Other"
	section_vbox_2.add_child(section_label_2)
	section_vbox_2.add_child(hbox_2)
	%Container.add_child(section_vbox_2)
	
	for key: String in ["dying_normal", "dead_normal", "dying_crit", "dead_crit", "spawn"]:
		var vbox: VBoxContainer = create_vbox(key, key)
		hbox_2.add_child(vbox)
	for i in range(3):
		hbox_2.add_spacer(false)


func create_vbox(key_label: String, full_key: String) -> VBoxContainer:
	var mapping: Dictionary = monster_data.monster_mapping
	var label := Label.new()
	label.text = key_label.to_pascal_case()
	
	var texture_container := RothTextureContainer.new()
	texture_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var reload_texture: Callable = func () -> void:
		var fat_4_index: int = (mapping[full_key] & 0x7FFF) - (len(das.fat_1) + len(das.fat_2) + len(das.fat_3)) - 4608
		var fat_3_index: int = (mapping[full_key] & 0x7FFF) - (len(das.fat_1) + len(das.fat_2)) - 4608
		if fat_4_index >= 0:
			texture_container.load_data(das.fat_4[fat_4_index], raw_palette)
		elif fat_3_index >= 0:
			texture_container.load_data(das.fat_3[fat_3_index], raw_palette)
		else:
			texture_container.clear()
		if mapping[full_key] & 0x8000:
			texture_container.mirror = true
		else:
			texture_container.mirror = false
	reload_texture.call_deferred()
	
	var checkbox := CheckBox.new()
	checkbox.text = "Mirror"
	checkbox.button_pressed = mapping[full_key] & 0x8000
	checkbox.toggled.connect(func (toggled_on: bool) -> void:
		if toggled_on:
			mapping[full_key] |= 0x8000
		else:
			mapping[full_key] &= ~0x8000
		reload_texture.call()
	)
	
	var spinbox := SpinBox.new()
	spinbox.min_value = -1
	spinbox.max_value = len(das.fat_1) + len(das.fat_2) + len(das.fat_3) + len(das.fat_4) - 1
	spinbox.rounded = true
	spinbox.value = (mapping[full_key] & 0x7FFF) - 4608
	spinbox.get_line_edit().text = str((mapping[full_key] & 0x7FFF) - 4608)
	spinbox.value_changed.connect(func (value: float) -> void:
		if int(value) == -1:
			mapping[full_key] = 0
		else:
			mapping[full_key] = (int(value) + 4608) | (0x8000 if checkbox.button_pressed else 0)
		reload_texture.call()
	)
	
	var button := Button.new()
	button.text = "Jump to"
	button.pressed.connect(func () -> void:
		jump_to_index_pressed.emit((mapping[full_key] & 0x7FFF) - 4608)
	)
	
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(label)
	vbox.add_child(texture_container)
	vbox.add_child(spinbox)
	vbox.add_child(checkbox)
	vbox.add_child(button)
	return vbox


func _on_name_edit_text_changed(new_text: String) -> void:
	monster_data.filename.name = new_text


func _on_description_edit_text_changed(new_text: String) -> void:
	monster_data.filename.desc = new_text


func _on_collision_height_spin_box_value_changed(value: float) -> void:
	monster_data.object_collision.raw_data = int(%CollisionHeightSpinBox.value) + (int(%CollisionRadiusSpinBox.value) << 16)


func _on_collision_radius_spin_box_value_changed(value: float) -> void:
	monster_data.object_collision.raw_data = int(%CollisionHeightSpinBox.value) + (int(%CollisionRadiusSpinBox.value) << 16)
