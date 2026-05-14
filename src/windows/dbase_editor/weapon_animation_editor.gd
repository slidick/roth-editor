extends BaseWindow

signal done(data: Dictionary)

var command: Dictionary = {}
var data: Dictionary = {}


func edit(p_command: Dictionary) -> void:
	command = p_command
	reset()
	toggle(true)


func reset() -> void:
	data = command.data.duplicate(true)
	redraw_textures()


func redraw_textures() -> void:
	%SizeLabel.text = "%d x %d" % [data.animation_2[0].buffer_width, data.animation_2[0].buffer_height]
	%FramesSpinBox.set_value_no_signal(len(data.animation_2))
	%FramesSpinBox.get_line_edit().text = str(len(data.animation_2))
	%RothTexture.load_data({"data": data}, Das.DEFAULT_RAW_PALETTE, true)
	
	for child: Node in %ImagesContainer.get_children():
		child.queue_free()
	
	for i in range(len(data.animation_2)):
		var frame: Dictionary = data.animation_2[i]
		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var texture_container := RothTextureContainer.new()
		texture_container.custom_minimum_size.x = 120
		texture_container.enabled = false
		texture_container.texture_expand_mode = TextureRect.EXPAND_FIT_HEIGHT
		texture_container.load_data.call_deferred({"data": frame}, Das.DEFAULT_RAW_PALETTE, true)
		texture_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		vbox.add_child(texture_container)
		
		
		var vbox2 := VBoxContainer.new()
		vbox2.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(vbox2)
		
		var label := Label.new()
		label.text = "Type"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox2.add_child(label)
		
		var spinbox := SpinBox.new()
		spinbox.value = frame.image_type
		spinbox.value_changed.connect(func (value: float) -> void:
			frame.image_type = int(value)
		)
		vbox2.add_child(spinbox)
		
		var button := Button.new()
		button.text = "Edit"
		button.custom_minimum_size.x = 80
		button.pressed.connect(func() -> void:
			var new_frame: Dictionary = await %ImageEditor.edit_image(frame, Das.DEFAULT_RAW_PALETTE, true)
			if not new_frame.is_empty():
				data.animation_2[i].raw_image = new_frame.raw_image
				data.animation_2[i].encoded_image = RLE.encode_row_rle_image(new_frame)
				data.animation_2[i].width = new_frame.width
				data.animation_2[i].height = new_frame.height
				redraw_textures()
		)
		vbox2.add_child(button)
		
		%ImagesContainer.add_child(vbox)
	



func _on_cancel_button_pressed() -> void:
	done.emit()
	toggle(false)


func _on_save_button_pressed() -> void:
	command.data = data
	done.emit()
	toggle(false)


func _on_edit_offsets_button_pressed() -> void:
	var new_data: Dictionary = await %EditAlignments.edit_alignments({"data": data}, Das.DEFAULT_RAW_PALETTE, false, true)
	if new_data.is_empty():
		return
	data = new_data.data
	redraw_textures()


func _on_reset_button_pressed() -> void:
	reset()


func _on_frames_spin_box_value_changed(value: float) -> void:
	if value < len(data.animation_2):
		while value != len(data.animation_2):
			data.animation_2.pop_back()
		redraw_textures()
	elif value > len(data.animation_2):
		while value != len(data.animation_2):
			var raw_image := PackedByteArray()
			raw_image.resize(16 * 16)
			var frame_data: Dictionary = {
				image_type = 30,
				buffer_width = data.animation_2[0].buffer_width,
				buffer_height = data.animation_2[0].buffer_height,
				x_offset = 0,
				width = 16,
				y_offset = 0,
				height = 16,
				raw_image = raw_image,
				
			}
			frame_data["encoded_image"] = RLE.encode_row_rle_image(frame_data)
			data.animation_2.append(frame_data)
		redraw_textures()
