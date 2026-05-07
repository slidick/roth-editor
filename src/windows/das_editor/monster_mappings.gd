extends MarginContainer

signal jump_to_index_pressed(index: int)

var das: Dictionary = {}


func reset() -> void:
	das = {}
	%ItemList.clear()
	%Container.hide()


func load_das(p_das: Dictionary) -> void:
	das = p_das
	reload()


func reload() -> void:
	%ItemList.clear()
	%Container.hide()
	for i in range(len(das.monster_mappings)):
		var idx: int = %ItemList.add_item(str(i))
		%ItemList.set_item_metadata(idx, das.monster_mappings[i])


func _on_item_list_item_selected(index: int) -> void:
	for child: Node in %Container.get_children():
		child.queue_free()
	
	var mapping: Dictionary = %ItemList.get_item_metadata(index)
	
	var vbox := VBoxContainer.new()
	%Container.add_child(vbox)
	%Container.show()
	for key: String in mapping:
		var label := Label.new()
		label.text = key
		label.custom_minimum_size.x = 250
		
		var checkbox := CheckBox.new()
		checkbox.text = "Mirror"
		checkbox.button_pressed = mapping[key] & 0x8000
		checkbox.toggled.connect(func (toggled_on: bool) -> void:
			if toggled_on:
				mapping[key] |= 0x8000
			else:
				mapping[key] &= ~0x8000
		)
		
		var line_edit := LineEdit.new()
		line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if das.das_info.is_ademo:
			var idx: int = (mapping[key] & 0x7FFF)
			if idx != 0:
				idx -= 4608
			line_edit.text = str(idx)
		else:
			line_edit.text = str(mapping[key] & 0x7FFF)
		line_edit.text_changed.connect(func (new_text: String) -> void:
			if das.das_info.is_ademo:
				mapping[key] = (int(new_text) + 4608) | (0x8000 if checkbox.button_pressed else 0)
			else:
				mapping[key] = int(new_text) | (0x8000 if checkbox.button_pressed else 0)
		)
		
		var button := Button.new()
		button.text = "Jump to"
		button.pressed.connect(func () -> void:
			var idx: int = (mapping[key] & 0x7FFF)
			if das.das_info.is_ademo:
				if idx != 0:
					idx -= 4608
			jump_to_index_pressed.emit(idx)
		)
		
		var hbox := HBoxContainer.new()
		hbox.add_child(label)
		hbox.add_child(line_edit)
		hbox.add_child(checkbox)
		hbox.add_child(button)
		vbox.add_child(hbox)


func _on_add_button_pressed() -> void:
	var monster_mapping: Dictionary = {
		"unk_0x00": 0,
		"flying_back": 0,
		"flying_back_right": 0,
		"flying_right": 0,
		"flying_front_right": 0,
		"flying_front": 0,
		"flying_front_left": 0,
		"flying_left": 0,
		"flying_back_left": 0,
		"walking_back": 0,
		"walking_back_right": 0,
		"walking_right": 0,
		"walking_front_right": 0,
		"walking_front": 0,
		"walking_front_left": 0,
		"walking_left": 0,
		"walking_back_left": 0,
		"attack1_back": 0,
		"attack1_back_right": 0,
		"attack1_right": 0,
		"attack1_front_right": 0,
		"attack1_front": 0,
		"attack1_front_left": 0,
		"attack1_left": 0,
		"attack1_back_left": 0,
		"attack2_back": 0,
		"attack2_back_right": 0,
		"attack2_right": 0,
		"attack2_front_right": 0,
		"attack2_front": 0,
		"attack2_front_left": 0,
		"attack2_left": 0,
		"attack2_back_left": 0,
		"on_damage_back": 0,
		"on_damage_back_right": 0,
		"on_damage_right": 0,
		"on_damage_front_right": 0,
		"on_damage_front": 0,
		"on_damage_front_left": 0,
		"on_damage_left": 0,
		"on_damage_back_left": 0,
		"dying_normal": 0,
		"dead_normal": 0,
		"dying_crit": 0,
		"dead_crit": 0,
		"spawn": 0,
		"unk_0x5E": 0,
		"unk_0x60": 0,
		"unk_0x64": 0,
	}
	das.monster_mappings.append(monster_mapping)
	var idx: int = %ItemList.add_item(str(%ItemList.item_count))
	%ItemList.set_item_metadata(idx, monster_mapping)
	%ItemList.select(idx)
	%ItemList.ensure_current_is_visible()
	_on_item_list_item_selected(idx)
