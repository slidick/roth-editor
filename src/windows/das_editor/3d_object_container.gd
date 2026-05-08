extends Control

var das: Dictionary
var object_data: Dictionary = {}
var raw_palette: PackedByteArray = []


func load_3d_object_data(p_object_data: Dictionary, p_raw_palette: Array) -> void:
	object_data = p_object_data
	if p_raw_palette.is_empty():
		raw_palette = Das.DEFAULT_RAW_PALETTE
	else:
		raw_palette = p_raw_palette
	
	%CollisionUnk0x00SpinBox.set_value_no_signal(int(object_data.object_collision.raw_data & 255))
	%CollisionUnk0x00SpinBox.get_line_edit().text = "%d" % int(object_data.object_collision.raw_data & 255)
	%CollisionHeightSpinBox.set_value_no_signal(int(object_data.object_collision.raw_data & 65280) >> 8)
	%CollisionHeightSpinBox.get_line_edit().text = "%d" % (int(object_data.object_collision.raw_data & 65280) >> 8)
	%CollisionWidthPerpendicularSpinBox.set_value_no_signal(int(object_data.object_collision.raw_data & 16711680) >> 16)
	%CollisionWidthPerpendicularSpinBox.get_line_edit().text = "%d" % (int(object_data.object_collision.raw_data & 16711680) >> 16)
	%CollisionWidthParallelSpinBox.set_value_no_signal(int(object_data.object_collision.raw_data & 4278190080) >> 24)
	%CollisionWidthParallelSpinBox.get_line_edit().text = "%d" % (int(object_data.object_collision.raw_data & 4278190080) >> 24)
	
	%Flags1Edit.text = str(object_data.flags_1)
	%Flags2Edit.text = str(object_data.flags_2)
	%ModifierEdit.text = str(object_data.data.modifier)
	%ImageTypeEdit.text = str(object_data.data.image_type)
	%NameEdit.text = object_data.filename.name
	%DescriptionEdit.text = object_data.filename.desc
	
	update_flags_1_checkboxes()
	update_flags_2_checkboxes()
	update_modifier_checkboxes()
	update_image_type_checkboxes()
	
	%Unk0x06SpinBox.set_value_no_signal(object_data.data.unk_0x06)
	%Unk0x06SpinBox.get_line_edit().text = str(object_data.data.unk_0x06)
	%Unk0x08SpinBox.set_value_no_signal(object_data.data.unk_0x08)
	%Unk0x08SpinBox.get_line_edit().text = str(object_data.data.unk_0x08)
	%Unk0x0ASpinBox.set_value_no_signal(object_data.data.unk_0x0A)
	%Unk0x0ASpinBox.get_line_edit().text = str(object_data.data.unk_0x0A)
	%Unk0x10SpinBox.set_value_no_signal(object_data.data.unk_0x10)
	%Unk0x10SpinBox.get_line_edit().text = str(object_data.data.unk_0x10)
	%MaxBoundXSpinBox.set_value_no_signal(object_data.data.max_bound_x)
	%MaxBoundXSpinBox.get_line_edit().text = str(object_data.data.max_bound_x)
	%MaxBoundYSpinBox.set_value_no_signal(object_data.data.max_bound_y)
	%MaxBoundYSpinBox.get_line_edit().text = str(object_data.data.max_bound_y)
	%MaxBoundZSpinBox.set_value_no_signal(object_data.data.max_bound_z)
	%MaxBoundZSpinBox.get_line_edit().text = str(object_data.data.max_bound_z)
	%FacesSignatureEdit.text = object_data.data.faces_header.sig
	
	reload_data()


func reload_data() -> void:
	for child: Node in %VertexContainer.get_children():
		child.queue_free()
	
	for i in range(len(object_data.data.vertices)):
		var vertex: Vector3 = object_data.data.vertices[i]
		var label := Label.new()
		label.text = str(i)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var spinbox_x := SpinBox.new()
		spinbox_x.min_value = -32768
		spinbox_x.max_value = 32767
		spinbox_x.value = vertex.x
		var spinbox_y := SpinBox.new()
		spinbox_y.min_value = -32768
		spinbox_y.max_value = 32767
		spinbox_y.value = vertex.y
		var spinbox_z := SpinBox.new()
		spinbox_z.min_value = -32768
		spinbox_z.max_value = 32767
		spinbox_z.value = vertex.z
		spinbox_x.value_changed.connect(func (value: float) -> void:
			object_data.data.vertices[i] = Vector3(spinbox_x.value, spinbox_y.value, spinbox_z.value)
		)
		spinbox_y.value_changed.connect(func (value: float) -> void:
			object_data.data.vertices[i] = Vector3(spinbox_x.value, spinbox_y.value, spinbox_z.value)
		)
		spinbox_z.value_changed.connect(func (value: float) -> void:
			object_data.data.vertices[i] = Vector3(spinbox_x.value, spinbox_y.value, spinbox_z.value)
		)
		
		var vbox := VBoxContainer.new()
		vbox.add_child(label)
		vbox.add_child(spinbox_x)
		vbox.add_child(spinbox_y)
		vbox.add_child(spinbox_z)
		vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		%VertexContainer.add_child(vbox)
	
	
	for child: Node in %FaceContainer.get_children():
		child.queue_free()
	
	for i in range(len(object_data.data.faces)):
		var vbox := VBoxContainer.new()
		vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		%FaceContainer.add_child(vbox)
		
		var label := Label.new()
		label.text = str(i)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(label)
		
		var face: Dictionary = object_data.data.faces[i]
		for key: String in face:
			var label2 := Label.new()
			label2.text = key
			label2.custom_minimum_size.x = 120
			label2.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			
			var line_edit := LineEdit.new()
			line_edit.text = str(face[key])
			line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line_edit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			line_edit.custom_minimum_size.x = 200
			line_edit.text_changed.connect(func (new_text: String) -> void:
				if new_text.contains("["):
					face[key] = Array(new_text.trim_prefix("[").trim_suffix("]").split(", ")).map(func(string: String) -> int: return int(string))
				else:
					face[key] = int(new_text)
			)
			
			var hbox := HBoxContainer.new()
			hbox.add_child(label2)
			hbox.add_child(line_edit)
			
			vbox.add_child(hbox)


func update_flags_1_checkboxes() -> void:
	%Flags1CheckBox1.button_pressed = (object_data.flags_1 & (1<<0)) > 0
	%Flags1CheckBox2.button_pressed = (object_data.flags_1 & (1<<1)) > 0
	%Flags1CheckBox3.button_pressed = (object_data.flags_1 & (1<<2)) > 0
	%Flags1CheckBox4.button_pressed = (object_data.flags_1 & (1<<3)) > 0
	%Flags1CheckBox5.button_pressed = (object_data.flags_1 & (1<<4)) > 0
	%Flags1CheckBox6.button_pressed = (object_data.flags_1 & (1<<5)) > 0
	%Flags1CheckBox7.button_pressed = (object_data.flags_1 & (1<<6)) > 0
	%Flags1CheckBox8.button_pressed = (object_data.flags_1 & (1<<7)) > 0


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
	object_data.flags_1 = new_value
	%Flags1Edit.text = str(new_value)


func update_flags_2_checkboxes() -> void:
	%Flags2CheckBox1.button_pressed = (object_data.flags_2 & (1<<0)) > 0
	%Flags2CheckBox2.button_pressed = (object_data.flags_2 & (1<<1)) > 0
	%Flags2CheckBox3.button_pressed = (object_data.flags_2 & (1<<2)) > 0
	%Flags2CheckBox4.button_pressed = (object_data.flags_2 & (1<<3)) > 0
	%Flags2CheckBox5.button_pressed = (object_data.flags_2 & (1<<4)) > 0
	%Flags2CheckBox6.button_pressed = (object_data.flags_2 & (1<<5)) > 0
	%Flags2CheckBox7.button_pressed = (object_data.flags_2 & (1<<6)) > 0
	%Flags2CheckBox8.button_pressed = (object_data.flags_2 & (1<<7)) > 0


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
	object_data.flags_2 = new_value
	%Flags2Edit.text = str(new_value)


func update_modifier_checkboxes() -> void:
	%ModifierCheckBox1.button_pressed = (object_data.data.modifier & (1<<0)) > 0
	%ModifierCheckBox2.button_pressed = (object_data.data.modifier & (1<<1)) > 0
	%ModifierCheckBox3.button_pressed = (object_data.data.modifier & (1<<2)) > 0
	%ModifierCheckBox4.button_pressed = (object_data.data.modifier & (1<<3)) > 0
	%ModifierCheckBox5.button_pressed = (object_data.data.modifier & (1<<4)) > 0
	%ModifierCheckBox6.button_pressed = (object_data.data.modifier & (1<<5)) > 0
	%ModifierCheckBox7.button_pressed = (object_data.data.modifier & (1<<6)) > 0
	%ModifierCheckBox8.button_pressed = (object_data.data.modifier & (1<<7)) > 0


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
	object_data.data.modifier = new_value
	%ModifierEdit.text = str(new_value)


func update_image_type_checkboxes() -> void:
	%ImageTypeCheckBox1.button_pressed = (object_data.data.image_type & (1<<0)) > 0
	%ImageTypeCheckBox2.button_pressed = (object_data.data.image_type & (1<<1)) > 0
	%ImageTypeCheckBox3.button_pressed = (object_data.data.image_type & (1<<2)) > 0
	%ImageTypeCheckBox4.button_pressed = (object_data.data.image_type & (1<<3)) > 0
	%ImageTypeCheckBox5.button_pressed = (object_data.data.image_type & (1<<4)) > 0
	%ImageTypeCheckBox6.button_pressed = (object_data.data.image_type & (1<<5)) > 0
	%ImageTypeCheckBox7.button_pressed = (object_data.data.image_type & (1<<6)) > 0
	%ImageTypeCheckBox8.button_pressed = (object_data.data.image_type & (1<<7)) > 0


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
	object_data.data.image_type = new_value
	%ImageTypeEdit.text = str(new_value)


func _on_name_edit_text_changed(new_text: String) -> void:
	object_data.filename.name = new_text


func _on_description_edit_text_changed(new_text: String) -> void:
	object_data.filename.desc = new_text


func _on_flags_1_edit_text_changed(new_text: String) -> void:
	object_data.flags_1 = int(new_text)
	update_flags_1_checkboxes()


func _on_flags_2_edit_text_changed(new_text: String) -> void:
	object_data.flags_2 = int(new_text)
	update_flags_2_checkboxes()


func _on_modifier_edit_text_changed(new_text: String) -> void:
	object_data.data.modifier = int(new_text)
	update_modifier_checkboxes()


func _on_image_type_edit_text_changed(new_text: String) -> void:
	object_data.data.image_type = int(new_text)
	update_image_type_checkboxes()


func _on_flags_1_check_box_pressed() -> void:
	update_flags_1_from_checkboxes()


func _on_flags_2_check_box_pressed() -> void:
	update_flags_2_from_checkboxes()


func _on_modifier_check_box_pressed() -> void:
	update_modifier_from_checkboxes()


func _on_image_type_check_box_pressed() -> void:
	update_image_type_from_checkboxes()


func _on_collision_unk_0x_00_spin_box_value_changed(value: float) -> void:
	object_data.object_collision.raw_data = int(%CollisionUnk0x00SpinBox.value) + (int(%CollisionHeightSpinBox.value) << 8) + (int(%CollisionWidthPerpendicularSpinBox.value) << 16) + (int(%CollisionWidthParallelSpinBox.value) << 24)


func _on_collision_height_spin_box_value_changed(value: float) -> void:
	object_data.object_collision.raw_data = int(%CollisionUnk0x00SpinBox.value) + (int(%CollisionHeightSpinBox.value) << 8) + (int(%CollisionWidthPerpendicularSpinBox.value) << 16) + (int(%CollisionWidthParallelSpinBox.value) << 24)


func _on_collision_width_perpendicular_spin_box_value_changed(value: float) -> void:
	object_data.object_collision.raw_data = int(%CollisionUnk0x00SpinBox.value) + (int(%CollisionHeightSpinBox.value) << 8) + (int(%CollisionWidthPerpendicularSpinBox.value) << 16) + (int(%CollisionWidthParallelSpinBox.value) << 24)


func _on_collision_width_parallel_spin_box_value_changed(value: float) -> void:
	object_data.object_collision.raw_data = int(%CollisionUnk0x00SpinBox.value) + (int(%CollisionHeightSpinBox.value) << 8) + (int(%CollisionWidthPerpendicularSpinBox.value) << 16) + (int(%CollisionWidthParallelSpinBox.value) << 24)


func _on_unk_0x_06_spin_box_value_changed(value: float) -> void:
	object_data.data.unk_0x06 = int(value)


func _on_unk_0x_08_spin_box_value_changed(value: float) -> void:
	object_data.data.unk_0x08 = int(value)


func _on_unk_0x_0a_spin_box_value_changed(value: float) -> void:
	object_data.data.unk_0x0A = int(value)


func _on_unk_0x_10_spin_box_value_changed(value: float) -> void:
	object_data.data.unk_0x10 = int(value)


func _on_max_bound_x_spin_box_value_changed(value: float) -> void:
	object_data.data.max_bound_x = int(value)


func _on_max_bound_y_spin_box_value_changed(value: float) -> void:
	object_data.data.max_bound_y = int(value)


func _on_max_bound_z_spin_box_value_changed(value: float) -> void:
	object_data.data.max_bound_z = int(value)


func _on_faces_signature_edit_text_changed(new_text: String) -> void:
	object_data.data.faces_header.sig = new_text
