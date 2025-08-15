extends Control


func _ready() -> void:
	Roth.das_loading_started.connect(_on_das_loading_start)
	Roth.das_loading_updated.connect(_on_das_loading_update)
	Roth.das_loading_finished.connect(_on_das_loading_finished)
	Roth.settings_loaded.connect(_on_roth_settings_loaded)


func load_das(das_file: Variant) -> void:
	clear_das()
	var das: Dictionary
	if typeof(das_file) == TYPE_STRING:
		for i in range(%DASFiles.item_count):
			if %DASFiles.get_item_metadata(i) == das_file:
				%DASFiles.select(i)
		das = await Roth.get_das(das_file)
		if das.is_empty():
			return
	else:
		for i in range(%DASFiles.item_count):
			if %DASFiles.get_item_metadata(i).get_file().get_basename() == das_file.name:
				%DASFiles.select(i)
		das = das_file
	for key: String in das.header:
		var label := Label.new()
		label.text = "%s: %s" % [key, das.header[key]]
		%DasInfoContainer.add_child(label)
	for key: String in das.das_strings_header:
		var label := Label.new()
		label.text = "%s: %s" % [key, das.das_strings_header[key]]
		%DasInfoContainer.add_child(label)
	for error: String in das.loading_errors:
		%Errors.append_text("%s\n" % error)

	
	%TabContainer.set_tab_title(0, "Textures (%s)" % len(das.textures))
	for texture: Dictionary in das.textures:
		var index: int = %TextureList.add_item("%s: %s (%s) %sx%s" % [texture["index"], texture["name"], texture["desc"], texture["width"], texture["height"]])
		#if %TextureLayoutOption.text == "Grid View":
			#%TextureList.set_item_text(index, "%s:%s" % [texture["index"], texture["name"]])
		%TextureList.set_item_metadata(index, texture)
		if "image" in texture:
			var image_texture: ImageTexture = texture.image[0] if typeof(texture.image) == TYPE_ARRAY else texture.image
			%TextureList.set_item_icon(index, image_texture)
		else:
			%TextureList.set_item_icon(index, ImageTexture.create_from_image(Image.create_empty(1,1, false, Image.FORMAT_L8)))


func set_das_list(das_list: Array) -> void:
	%DASFiles.clear()
	var index := 0
	for das: String in das_list:
		%DASFiles.add_item(das)
		%DASFiles.set_item_metadata(index, das)
		index += 1
	%DASFiles.select(-1)


func clear_das() -> void:
	clear_texture()
	for child in %DasInfoContainer.get_children():
		child.queue_free()
	%TextureList.clear()
	%Errors.clear()


func clear_texture() -> void:
	for node in %TextureContainer.get_children():
		node.queue_free()
	for node in %DataContainer.get_children():
		node.queue_free()
	%AnimationTimer.stop()


func _on_roth_settings_loaded() -> void:
	Console.print("Settings Loaded")
	set_das_list(Roth.das_files)


func _on_das_files_item_selected(_index: int) -> void:
	load_das(%DASFiles.get_selected_metadata())


func _on_load_button_pressed() -> void:
	load_das(%DASFiles.get_selected_metadata())


func _on_texture_list_item_selected(index: int) -> void:
	var meta: Variant = %TextureList.get_item_metadata(index)
	if meta:
		if meta.has("animation"):
			show_texture_animation(meta.get("animation"))
		elif meta.has("image"):
			if meta.get("image") is Array:
				show_texture_array(meta.get("image"))
			else:
				show_texture(meta.get("image"))
		else:
			clear_texture()
			
		show_texture_data(meta)
	else:
		clear_texture()


func show_texture_data(data: Dictionary) -> void:
	for key: String in data:
		if key == "image" or key == "animation":
			continue
		var label := Label.new()
		label.text = "%s: %s" % [key, data[key]]
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		#label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		#label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		#label.custom_minimum_size.y = 32
		%DataContainer.add_child(label)


func show_texture(img: ImageTexture) -> void:
	clear_texture()
	var texture_rect := TextureRect.new()
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_rect.texture = img
	texture_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var label := Label.new()
	label.text = "Floor / Ceiling:"
	%TextureContainer.add_child(label)
	%TextureContainer.add_child(texture_rect)
	
	var rotation_container := RotationContainer.new()
	var texture_rect_wall := TextureRect.new()
	texture_rect_wall.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect_wall.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect_wall.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_rect_wall.texture = img
	rotation_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rotation_container.add_child(texture_rect_wall)
	
	label = Label.new()
	label.text = "Wall:"
	%TextureContainer.add_child(label)
	%TextureContainer.add_child(rotation_container)


func show_texture_array(array: Array) -> void:
	clear_texture()
	for img: ImageTexture in array:
		
		var texture_rect := TextureRect.new()
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		texture_rect.texture = img
		
		var rotation_container := RotationContainer.new()
		rotation_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		rotation_container.add_child(texture_rect)
		%TextureContainer.add_child(rotation_container)


func show_texture_animation(array: Array) -> void:
	clear_texture()
	var animation_rect := TextureRect.new()
	animation_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	animation_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	animation_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	var rotation_container := RotationContainer.new()
	rotation_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rotation_container.add_child(animation_rect)
	%TextureContainer.add_child(rotation_container)
	
	var animated_image := AnimatedSprite2D.new()
	animated_image.hide()
	var sprite_frames := SpriteFrames.new()
	animated_image.sprite_frames = sprite_frames
	sprite_frames.set_animation_speed("default", 12)
	for image: ImageTexture in array.slice(0,-1):
		sprite_frames.add_frame("default", image)
	animated_image.play("default")
	animated_image.frame_changed.connect(func () -> void: animation_rect.texture = sprite_frames.get_frame_texture("default", animated_image.frame))
	%TextureContainer.add_child(animated_image)
	animation_rect.texture = sprite_frames.get_frame_texture("default", 0)


func _on_das_loading_start() -> void:
	%ProgressBar.show()
	%ProgressBar.value = 0


func _on_das_loading_update(progress: float, _das_file: String) -> void:
	%ProgressBar.value = progress * 100


func _on_das_loading_finished(_das: Dictionary) -> void:
	if %DASFiles.selected == -1:
		load_das(_das)
	%ProgressBar.hide()


func _on_texture_layout_option_item_selected(index: int) -> void:
	match index:
		0:
			%TextureList.max_columns = 1
			%TextureList.icon_mode = ItemList.ICON_MODE_LEFT
			%TextureList.fixed_column_width = 0
			%TextureList.fixed_icon_size = Vector2(25,25)
			%TextureList.ensure_current_is_visible()
		1:
			%TextureList.max_columns = 0
			%TextureList.icon_mode = ItemList.ICON_MODE_TOP
			%TextureList.fixed_column_width = 100
			%TextureList.fixed_icon_size = Vector2(95, 95)
			%TextureList.ensure_current_is_visible()
