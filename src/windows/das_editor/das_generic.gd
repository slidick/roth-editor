extends Control

signal jump_to_pressed(index: int)

var das: Variant
var SCRIPT: Script = preload("uid://daro30p1hipaw")

func reset() -> void:
	das = {}
	for child: Node in get_children():
		child.queue_free()


func load_das(p_das: Variant, p_key: Variant, p_palette: Array = []) -> void:
	das = p_das
	if p_das is Dictionary and p_key not in p_das:
		return
	
	
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var scroll_container := ScrollContainer.new()
	scroll_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll_container.add_child(vbox)
	
	add_child(scroll_container)
	
	for key: String in das[p_key]:
		
		if key == "index" and "name" not in das[p_key]:
			continue
		if key == "raw_animation" or key == "raw_animation_2":
			continue
		var hbox := HBoxContainer.new()
		
		var label := Label.new()
		label.text = key
		label.custom_minimum_size.x = 200
		hbox.add_child(label)
		
		match key:
			"bonus":
				var line_edit_1 := LineEdit.new()
				line_edit_1.text = str(das[p_key][key][0])
				line_edit_1.text_changed.connect(func (new_text: String) -> void:
					das[p_key][key][0] = int(new_text)
				)
				hbox.add_child(line_edit_1)
				var line_edit_2 := LineEdit.new()
				line_edit_2.text = str(das[p_key][key][1])
				line_edit_2.text_changed.connect(func (new_text: String) -> void:
					das[p_key][key][1] = int(new_text)
				)
				hbox.add_child(line_edit_2)
			"raw":
				var palette: Array = []
				if p_palette.is_empty():
					palette = Das.DEFAULT_PALETTE
				else:
					palette = p_palette
				var texture_data: Array = []
				for pixel: int in das[p_key][key]:
					texture_data.append_array(palette[pixel])
					if palette[pixel] == [0,0,0] and pixel == 0:
						texture_data.append(0)
					else:
						texture_data.append(255)
				var image: Image = Image.create_from_data(das[p_key].width, das[p_key].height, false, Image.FORMAT_RGBA8, texture_data)
				var image_texture := ImageTexture.create_from_image(image)
				var texture_rect := TextureRect.new()
				texture_rect.texture = image_texture
				texture_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				var rotation_container := RotationContainer.new()
				rotation_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				rotation_container.add_child(texture_rect)
				var edit_button := Button.new()
				edit_button.text = "Edit"
				edit_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				hbox.add_child(rotation_container)
				hbox.add_child(edit_button)
				hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
			"animation":
				label.custom_minimum_size.y = 200
				label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				var palette: Array = []
				if p_palette.is_empty():
					palette = Das.DEFAULT_PALETTE
				else:
					palette = p_palette
				
				var animation_rect := TextureRect.new()
				#animation_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				animation_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				animation_rect.expand_mode = TextureRect.EXPAND_FIT_HEIGHT
				animation_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				var animated_image := AnimatedSprite2D.new()
				animated_image.hide()
				var sprite_frames := SpriteFrames.new()
				animated_image.sprite_frames = sprite_frames
				sprite_frames.set_animation_speed("default", 12)
				for raw_img: Array in das[p_key][key].slice(0,-1):
					var texture_data: Array = []
					for pixel: int in raw_img:
						texture_data.append_array(palette[pixel])
						if palette[pixel] == [0,0,0] and pixel == 0:
							texture_data.append(0)
						else:
							texture_data.append(255)
					var image: Image = Image.create_from_data(das[p_key].width, das[p_key].height, false, Image.FORMAT_RGBA8, texture_data)
					var image_texture := ImageTexture.create_from_image(image)
					sprite_frames.add_frame("default", image_texture)
				animated_image.play("default")
				animated_image.frame_changed.connect(func () -> void: animation_rect.texture = sprite_frames.get_frame_texture("default", animated_image.frame))
				animation_rect.texture = sprite_frames.get_frame_texture("default", 0)
				hbox.add_child(animated_image)
				var rotation_container := RotationContainer.new()
				#rotation_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				rotation_container.add_child(animation_rect)
				hbox.add_child(rotation_container)
				hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
			"animation_2":
				label.custom_minimum_size.y = 200
				label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				var palette: Array = []
				if p_palette.is_empty():
					palette = Das.DEFAULT_PALETTE
				else:
					palette = p_palette
				
				var animation_rect := TextureRect.new()
				#animation_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				animation_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				animation_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
				animation_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				var animated_image := AnimatedSprite2D.new()
				animated_image.hide()
				var sprite_frames := SpriteFrames.new()
				animated_image.sprite_frames = sprite_frames
				sprite_frames.set_animation_speed("default", 12)
				var hbox2 := HBoxContainer.new()
				vbox.add_child(hbox2)
				for sub_image_data: Dictionary in das[p_key][key].slice(0,-1):
					
					var vbox2 := VBoxContainer.new()
					hbox2.add_child(vbox2)
					for key2: String in sub_image_data.header:
						var label2 := Label.new()
						label2.text = key2
						label2.custom_minimum_size.x = 150
						var line_edit2 := LineEdit.new()
						line_edit2.text = str(sub_image_data.header[key2])
						line_edit2.text_changed.connect(func (new_text: String) -> void:
							sub_image_data.header[key2] = int(new_text)
						)
						var hbox3 := HBoxContainer.new()
						hbox3.add_child(label2)
						hbox3.add_child(line_edit2)
						vbox2.add_child(hbox3)
					
					var texture_data: Array = []
					for pixel: int in sub_image_data.raw_image:
						texture_data.append_array(palette[pixel])
						if palette[pixel] == [0,0,0] and pixel == 0:
							texture_data.append(0)
						else:
							texture_data.append(255)
					var image: Image = Image.create_from_data(sub_image_data.header.width, sub_image_data.header.height, false, Image.FORMAT_RGBA8, texture_data)
					var image_texture := ImageTexture.create_from_image(image)
					sprite_frames.add_frame("default", image_texture)
				animated_image.play("default")
				animated_image.frame_changed.connect(func () -> void: animation_rect.texture = sprite_frames.get_frame_texture("default", animated_image.frame))
				animation_rect.texture = sprite_frames.get_frame_texture("default", 0)
				hbox.add_child(animated_image)
				hbox.add_child(animation_rect)
				hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
			"directional":
				var palette: Array = []
				if p_palette.is_empty():
					palette = Das.DEFAULT_PALETTE
				else:
					palette = p_palette
				
				
				var hbox2 := HBoxContainer.new()
				hbox.add_child(hbox2)
				for sub_image_data: Dictionary in das[p_key][key]:
					var vbox2 := VBoxContainer.new()
					hbox2.add_child(vbox2)
					for key2: String in sub_image_data.header:
						var label2 := Label.new()
						label2.text = key2
						label2.custom_minimum_size.x = 150
						var line_edit2 := LineEdit.new()
						line_edit2.text = str(sub_image_data.header[key2])
						if key2 in ["flags_1", "flags_2", "modifier", "image_type", "unk_0x06"]:
							line_edit2.text_changed.connect(func (new_text: String) -> void:
								sub_image_data.header[key2] = int(new_text)
							)
						else:
							line_edit2.editable = false
						var hbox3 := HBoxContainer.new()
						hbox3.add_child(label2)
						hbox3.add_child(line_edit2)
						vbox2.add_child(hbox3)
					
					var texture_data: Array = []
					for pixel: int in sub_image_data.raw_image:
						texture_data.append_array(palette[pixel])
						if palette[pixel] == [0,0,0] and pixel == 0:
							texture_data.append(0)
						else:
							texture_data.append(255)
					var image: Image = Image.create_from_data(sub_image_data.header.width, sub_image_data.header.height, false, Image.FORMAT_RGBA8, texture_data)
					var image_texture := ImageTexture.create_from_image(image)
					
					var texture_rect := TextureRect.new()
					texture_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					texture_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
					texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
					texture_rect.texture = image_texture
					texture_rect.custom_minimum_size.y = 100
					hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
					vbox2.add_child(texture_rect)
			"object_images":
				var palette: Array = []
				if p_palette.is_empty():
					palette = Das.DEFAULT_PALETTE
				else:
					palette = p_palette
				
				
				var hbox2 := HBoxContainer.new()
				hbox.add_child(hbox2)
				for sub_image_data: Dictionary in das[p_key][key]:
					var vbox2 := VBoxContainer.new()
					hbox2.add_child(vbox2)
					for key2: String in sub_image_data.header:
						var label2 := Label.new()
						label2.text = key2
						label2.custom_minimum_size.x = 150
						var line_edit2 := LineEdit.new()
						line_edit2.text = str(sub_image_data.header[key2])
						line_edit2.text_changed.connect(func (new_text: String) -> void:
							sub_image_data.header[key2] = int(new_text)
						)
						var hbox3 := HBoxContainer.new()
						hbox3.add_child(label2)
						hbox3.add_child(line_edit2)
						vbox2.add_child(hbox3)
					
					var texture_data: Array = []
					for pixel: int in sub_image_data.raw_image:
						texture_data.append_array(palette[pixel])
						if palette[pixel] == [0,0,0] and pixel == 0:
							texture_data.append(0)
						else:
							texture_data.append(255)
					var image: Image = Image.create_from_data(sub_image_data.header.width, sub_image_data.header.height, false, Image.FORMAT_RGBA8, texture_data)
					var image_texture := ImageTexture.create_from_image(image)
					
					var texture_rect := TextureRect.new()
					texture_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					texture_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
					texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
					texture_rect.texture = image_texture
					texture_rect.custom_minimum_size.y = 100
					hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
					vbox2.add_child(texture_rect)
			"faces":
				var scroll_2 := ScrollContainer.new()
				scroll_2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				scroll_2.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
				hbox.add_child(scroll_2)
				hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
				var hbox_3 := HBoxContainer.new()
				scroll_2.add_child(hbox_3)
				for face: Dictionary in das[p_key][key]:
					var vbox2 := VBoxContainer.new()
					hbox_3.add_child(vbox2)
					hbox_3.add_theme_constant_override("separation", 20)
					for key2: String in face:
						var hbox2 := HBoxContainer.new()
						vbox2.add_child(hbox2)
						
						var label2 := Label.new()
						label2.text = key2
						label2.tooltip_text = key2
						label2.mouse_filter = Control.MOUSE_FILTER_PASS
						label2.custom_minimum_size.x = 120
						label2.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS_FORCE
						
						var line_edit_2 := LineEdit.new()
						line_edit_2.custom_minimum_size.x = 150
						line_edit_2.text = str(face[key2])
						if key2 in ["size", "edge_count"]:
							line_edit_2.editable = false
						else:
							line_edit_2.text_changed.connect(func(new_text: String) -> void:
								if new_text.contains("["):
									face[key2] = Array(new_text.trim_prefix("[").trim_suffix("]").split(", ")).map(func(string: String) -> int: return int(string))
								else:
									face[key2] = int(new_text)
							)
						
						hbox2.add_child(label2)
						hbox2.add_child(line_edit_2)
			"data":
				var margin_container := MarginContainer.new()
				margin_container.add_theme_constant_override("margin_left", 10)
				margin_container.add_theme_constant_override("margin_top", 10)
				margin_container.add_theme_constant_override("margin_right", 10)
				margin_container.add_theme_constant_override("margin_bottom", 10)
				margin_container.set_script(SCRIPT)
				margin_container.call("load_das", das[p_key], key, p_palette)
				margin_container.add_theme_constant_override("margin_right", 0)
				margin_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				hbox.add_child(margin_container)
				hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
			"index":
				var line_edit := LineEdit.new()
				line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				line_edit.text = str(das[p_key][key])
				if das[p_key][key] is Array or das[p_key][key] is PackedByteArray:
					line_edit.editable = false
				line_edit.text_changed.connect(func (new_text: String) -> void:
					das[p_key][key] = int(new_text)
				)
				hbox.add_child(line_edit)
				var button := Button.new()
				button.text = "Jump to"
				button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				button.pressed.connect(func() -> void: jump_to_pressed.emit(das[p_key][key]))
				hbox.add_child(button)
			_:
				var line_edit := LineEdit.new()
				line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				line_edit.text = str(das[p_key][key])
				
				if key in ["flags_1", "flags_2", "modifier", "image_type", "unk_0x06", "unk_0x08", "unk_0x0A", "unk_0x10", "name", "desc", "modifier_2", "image_type_2"]:
					line_edit.text_changed.connect(func (new_text: String) -> void:
						if new_text.is_valid_int():
							das[p_key][key] = int(new_text)
						else:
							das[p_key][key] = new_text
						
						for i in range(line_edit.get_index()+1, line_edit.get_parent().get_child_count()):
							line_edit.get_parent().get_child(i).button_pressed = false
							line_edit.get_parent().get_child(i).button_pressed = das[p_key][key] & (1<<(i-(line_edit.get_index()+1)))
					)
				else:
					line_edit.editable = false
				
				hbox.add_child(line_edit)
				
				
				
				if key in ["flags_1", "flags_2", "modifier", "image_type", "modifier_2", "image_type_2"]:
					for i in range(8):
						var checkbox := CheckBox.new()
						checkbox.text = "Flag%d" % (i+1)
						checkbox.button_pressed = das[p_key][key] & (1<<i)
						checkbox.pressed.connect(func () -> void:
							var new_value: int = 0
							for j in range(8):
								if checkbox.get_parent().get_child(2+j).button_pressed:
									new_value |= (1<<j)
							var line_edit_2 := checkbox.get_parent().get_child(1)
							line_edit_2.text = str(new_value)
							das[p_key][key] = int(new_value)
						)
						
						hbox.add_child(checkbox)
				
				
				
		vbox.add_child(hbox)
