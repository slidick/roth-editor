extends Control

signal jump_to_collision_pressed
signal jump_to_filename_pressed(filename: Dictionary)
var das: Variant
var SCRIPT: Script = preload("uid://daro30p1hipaw")

func reset() -> void:
	das = {}
	for child: Node in get_children():
		child.queue_free()


func load_das(p_das: Variant, p_key: Variant, p_raw_palette: Array = [], is_fat_3: bool = false) -> void:
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
		if key == "index" or key == "raw_animation" or key == "raw_animation_2":
			continue
		
		var hbox := HBoxContainer.new()
		
		var label := Label.new()
		label.text = key
		label.custom_minimum_size.x = 200
		hbox.add_child(label)
		
		match key:
			"shift_data":
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
			"raw_image":
				var palette: Array = []
				if p_raw_palette.is_empty():
					palette = Das.DEFAULT_RAW_PALETTE
				else:
					palette = p_raw_palette
				var is_transparent: bool = das[p_key].image_type & Das.IMAGE_TYPE.TRANSPARENT > 0 or das[p_key].image_type & Das.IMAGE_TYPE.PALETTE_ZERO_OPAQUE == 0
				var is_fully_transparent: bool = das[p_key].image_type & Das.IMAGE_TYPE.TRANSPARENT > 0
				var image: Image = Image.create_from_data(das[p_key].width, das[p_key].height, false, Image.FORMAT_RGBA8 if is_transparent else Image.FORMAT_RGB8, Utility.convert_palette_image(palette, das[p_key][key], is_transparent, is_fully_transparent))
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
				edit_button.pressed.connect(func () -> void:
					var new_texture: Dictionary = await owner.owner.edit_image(das[p_key], palette)
					if not new_texture.is_empty():
						var new_image: Image = Image.create_from_data(
							new_texture.width,
							new_texture.height,
							false,
							Image.FORMAT_RGBA8 if is_transparent else Image.FORMAT_RGB8,
							Utility.convert_palette_image(palette, new_texture.raw_image, is_transparent, is_fully_transparent)
						)
						texture_rect.texture = ImageTexture.create_from_image(new_image)
						das[p_key] = new_texture
						
				)
				hbox.add_child(rotation_container)
				hbox.add_child(edit_button)
				hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
			"animation":
				label.custom_minimum_size.y = 200
				label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				var palette: Array = []
				if p_raw_palette.is_empty():
					palette = Das.DEFAULT_RAW_PALETTE
				else:
					palette = p_raw_palette
				
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
				var is_transparent: bool = das[p_key].image_type_2 & Das.IMAGE_TYPE.TRANSPARENT > 0 or das[p_key].image_type_2 & Das.IMAGE_TYPE.PALETTE_ZERO_OPAQUE == 0
				var is_fully_transparent: bool = das[p_key].image_type_2 & Das.IMAGE_TYPE.TRANSPARENT > 0
				for raw_img: Array in das[p_key][key].slice(0,-1):
					var image: Image = Image.create_from_data(das[p_key].width, das[p_key].height, false, Image.FORMAT_RGBA8 if is_transparent else Image.FORMAT_RGB8, Utility.convert_palette_image(palette, raw_img, is_transparent, is_fully_transparent))
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
				if p_raw_palette.is_empty():
					palette = Das.DEFAULT_RAW_PALETTE
				else:
					palette = p_raw_palette
				
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
					var is_transparent: bool = sub_image_data.header.image_type & Das.IMAGE_TYPE.TRANSPARENT > 0 or sub_image_data.header.image_type & Das.IMAGE_TYPE.PALETTE_ZERO_OPAQUE == 0
					var is_fully_transparent: bool = sub_image_data.header.image_type & Das.IMAGE_TYPE.TRANSPARENT > 0
					var image: Image = Image.create_from_data(sub_image_data.header.width, sub_image_data.header.height, false, Image.FORMAT_RGBA8 if is_transparent else Image.FORMAT_RGB8, Utility.convert_palette_image(palette, sub_image_data.raw_image, is_transparent, is_fully_transparent))
					var image_texture := ImageTexture.create_from_image(image)
					sprite_frames.add_frame("default", image_texture)
				animated_image.play("default")
				animated_image.frame_changed.connect(func () -> void: animation_rect.texture = sprite_frames.get_frame_texture("default", animated_image.frame))
				animation_rect.texture = sprite_frames.get_frame_texture("default", 0)
				hbox.add_child(animated_image)
				hbox.add_child(animation_rect)
				hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
			"image_pack":
				var palette: Array = []
				if p_raw_palette.is_empty():
					palette = Das.DEFAULT_RAW_PALETTE
				else:
					palette = p_raw_palette
				
				var scroll2 := ScrollContainer.new()
				scroll2.size_flags_vertical = Control.SIZE_EXPAND_FILL
				scroll2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				scroll2.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
				hbox.add_child(scroll2)
				var hbox2 := HBoxContainer.new()
				hbox2.size_flags_vertical = Control.SIZE_EXPAND_FILL
				hbox2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				hbox2.add_theme_constant_override("separation", 20)
				scroll2.add_child(hbox2)
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
					var is_transparent: bool = sub_image_data.header.image_type & Das.IMAGE_TYPE.TRANSPARENT > 0 or sub_image_data.header.image_type & Das.IMAGE_TYPE.PALETTE_ZERO_OPAQUE == 0
					var is_fully_transparent: bool = sub_image_data.header.image_type & Das.IMAGE_TYPE.TRANSPARENT > 0
					var image: Image = Image.create_from_data(sub_image_data.header.width, sub_image_data.header.height, false, Image.FORMAT_RGBA8 if is_transparent else Image.FORMAT_RGB8, Utility.convert_palette_image(palette, sub_image_data.raw_image, is_transparent, is_fully_transparent))
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
			"vertices":
				var scroll_2 := ScrollContainer.new()
				scroll_2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				scroll_2.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
				hbox.add_child(scroll_2)
				#hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
				var hbox_3 := HBoxContainer.new()
				scroll_2.add_child(hbox_3)
				for i in range(len(das[p_key][key])):
					var vertex: Vector3 = das[p_key][key][i]
					var vbox2 := VBoxContainer.new()
					hbox_3.add_child(vbox2)
					hbox_3.add_theme_constant_override("separation", 20)
					var hbox2 := HBoxContainer.new()
					vbox2.add_child(hbox2)
					var label2 := Label.new()
					label2.text = "X:"
					label2.custom_minimum_size.x = 40
					hbox2.add_child(label2)
					var line_edit_x := LineEdit.new()
					line_edit_x.custom_minimum_size.x = 60
					line_edit_x.text = str(vertex.x)
					hbox2.add_child(line_edit_x)
					var hbox3 := HBoxContainer.new()
					vbox2.add_child(hbox3)
					var label3 := Label.new()
					label3.text = "Y:"
					label3.custom_minimum_size.x = 40
					hbox3.add_child(label3)
					var line_edit_y := LineEdit.new()
					line_edit_y.custom_minimum_size.x = 60
					line_edit_y.text = str(vertex.y)
					hbox3.add_child(line_edit_y)
					var hbox4 := HBoxContainer.new()
					vbox2.add_child(hbox4)
					var label4 := Label.new()
					label4.text = "Z:"
					label4.custom_minimum_size.x = 40
					hbox4.add_child(label4)
					var line_edit_z := LineEdit.new()
					line_edit_z.custom_minimum_size.x = 60
					line_edit_z.text = str(vertex.z)
					hbox4.add_child(line_edit_z)
					line_edit_x.text_changed.connect(func (_new_text: String) -> void:
						das[p_key][key][i] = Vector3i(int(line_edit_x.text), int(line_edit_y.text), int(line_edit_z.text))
					)
					line_edit_y.text_changed.connect(func (_new_text: String) -> void:
						das[p_key][key][i] = Vector3i(int(line_edit_x.text), int(line_edit_y.text), int(line_edit_z.text))
					)
					line_edit_z.text_changed.connect(func (_new_text: String) -> void:
						das[p_key][key][i] = Vector3i(int(line_edit_x.text), int(line_edit_y.text), int(line_edit_z.text))
					)
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
				margin_container.set_owner.call_deferred(owner)
				margin_container.call_deferred("load_das", das[p_key], key, p_raw_palette)
				margin_container.add_theme_constant_override("margin_right", 0)
				margin_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				hbox.add_child(margin_container)
				
				hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
			"filename":
				var line_edit := LineEdit.new()
				line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				line_edit.text = "%s: %s" % [das[p_key][key].name, das[p_key][key].desc]
				line_edit.editable = false
				hbox.add_child(line_edit)
				var button := Button.new()
				button.text = "Jump to Filename"
				button.pressed.connect(func() -> void:
					jump_to_filename_pressed.emit(das[p_key][key])
				)
				hbox.add_child(button)
			_:
				var line_edit := LineEdit.new()
				line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				line_edit.text = str(das[p_key][key])
				
				var editable_keys: Array = ["flags_1", "flags_2", "modifier", "image_type", "unk_0x06", "unk_0x07", "unk_0x08", "unk_0x0A", "unk_0x0E", "unk_0x10", "name", "desc", "modifier_2", "image_type_2", "max_bound_x", "max_bound_y", "max_bound_z", "pack_type"]
				editable_keys.append_array(Das.MONSTER_MAPPING_ENTRY.keys())
				if key in editable_keys:
					line_edit.text_changed.connect(func (new_text: String) -> void:
						if new_text.contains("["):
							das[p_key][key] = Array(new_text.trim_prefix("[").trim_suffix("]").split(", ")).map(func(string: String) -> int: return int(string))
						elif new_text.is_valid_int():
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
				
				
				if key == "offset" and is_fat_3:
					var button := Button.new()
					button.text = "Jump to Object Collision"
					button.pressed.connect(func() -> void:
						jump_to_collision_pressed.emit()
					)
					hbox.add_child(button)
				
		vbox.add_child(hbox)
	
	if "data" in das[p_key] and "filename" not in das[p_key]:
		var hbox := HBoxContainer.new()
		var label := Label.new()
		label.text = "filename"
		label.custom_minimum_size.x = 200
		hbox.add_child(label)
		var button := Button.new()
		button.text = "Add Filename"
		button.custom_minimum_size.x = 400
		button.pressed.connect(func () -> void:
			if owner.name == "Fat1" or owner.name == "Fat2":
				das[p_key]["filename"] = owner.owner._on_add_filename_pressed(1, das[p_key].index)
			else:
				das[p_key]["filename"] = owner.owner._on_add_filename_pressed(2, das[p_key].index)
			owner.select(p_key)
		)
		hbox.add_child(button)
		vbox.add_child(hbox)
