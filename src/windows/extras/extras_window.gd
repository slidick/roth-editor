extends BaseWindow


signal gdv_parsing_done(gdv: Dictionary)


var accumulated_time: float = 0.0
var dbase100: Dictionary = {}
var animation: Array
var animation_position: int = 0
var animation_rect: TextureRect
var current_video: Dictionary = {}
var current_frame: int = 0
var dragging_slider: bool = false


func _ready() -> void:
	super._ready()
	Roth.settings_loaded.connect(_on_settings_loaded)
	%CommandTree.create_item()
	%CommandTree.set_column_title(0, "Command")
	%CommandTree.set_column_title(1, "Value")
	Roth.gdv_loading_updated.connect(_on_gdv_loading_updated)


func _process(delta: float) -> void:
	if %VideoTimer.is_stopped() or %VideoTimer.paused or "header" not in current_video:
		return
	accumulated_time += delta
	while accumulated_time >= (1.0 / current_video.header.framerate):
		accumulated_time -= (1.0 / current_video.header.framerate)
		_on_video_timer_timeout()


func _on_settings_loaded() -> void:
	# DBase100
	# Actions/Commands Clear
	%CommandList.clear()
	for tree_item: TreeItem in %CommandTree.get_root().get_children():
		tree_item.free()
	for node: Node in %CommandPanel.get_children():
		node.queue_free()
	
	# Cutscenes Clear
	%CutsceneList.clear()
	for node: Node in %CutscenePanel.get_children():
		node.queue_free()
	%VideoControlsContainer.hide()
	
	# Interface Clear
	%InterfaceList.clear()
	
	# Inventory Clear
	%InventoryList.clear()
	for node: Node in %InventoryPanel.get_children():
		node.queue_free()
	
	# DBase100 Parse
	dbase100 = DBase100.parse()
	if not dbase100.is_empty():
		# Actions/Commands
		#var command_counts := {}
		for i in range(len(dbase100.actions)):
			var action: Dictionary = dbase100.actions[i]
			if action.offset == 0:
				continue
			if action.length == 0:
				continue
			var idx: int = %CommandList.add_item("%d" % (i+1))
			%CommandList.set_item_metadata(idx, action)
			#if "unk_word_00" in action and action.unk_word_00 != 768:
				#print(action)
			#if "length" in action and action.length == 0:
				#print(action)
			#print(action)
			#for opcode: Dictionary in action.opcodes:
				#if opcode.command not in command_counts:
					#command_counts[opcode.command] = 1
				#else:
					#command_counts[opcode.command] += 1
				#if opcode.command == 35:
					#print(i+1)
		#print(JSON.stringify(command_counts, '\t', true))
		
		# Cutscenes
		for i in range(len(dbase100.cutscenes)):
			var cutscene: Dictionary = dbase100.cutscenes[i]
			if cutscene.name == "":
				continue
			var idx: int = %CutsceneList.add_item("%d: %s" % [(i+1), cutscene.name])
			%CutsceneList.set_item_metadata(idx, cutscene)
		
		
		# Interfaces
		for i in range(len(dbase100.interfaces)):
			var interface: Dictionary = dbase100.interfaces[i]
			%InterfaceList.add_item("%d: %s" % [(i+1), interface.subtitle.string])
		
		
		# Inventory
		for i in range(len(dbase100.inventory)):
			var inventory_item: Dictionary = dbase100.inventory[i]
			var idx: int = %InventoryList.add_item("%d: %s" % [(i+1), inventory_item.subtitle.string])
			%InventoryList.set_item_metadata(idx, inventory_item)
		
	
	# DBASE200
	# DBase200 Clear
	%DBase200List.clear()
	for node: Node in %DBase200Panel.get_children():
		node.queue_free()
	%AnimationTimer.stop()
	
	# DBase200 Parse
	var dbase200_offsets: Array = DBase200.get_animation_offsets()
	if not dbase200_offsets.is_empty():
		# DBase200 Init
		for i in range(len(dbase200_offsets)):
			var offset: int = dbase200_offsets[i]
			var idx: int = %DBase200List.add_item("%d" % (i+1))
			%DBase200List.set_item_metadata(idx, offset)
	
	
	# IconsAll
	# IconsAll Clear
	%IconList.clear()
	
	# IconsAll Parse
	var icons_offsets: Array = IconsAll.get_icon_offsets()
	if not icons_offsets.is_empty():
		# IconsAll Init
		for i in range(len(icons_offsets)):
			var offset: int = icons_offsets[i]
			var idx: int = %IconList.add_item("%d"  % (i+1))
			var icon_image: Image = IconsAll.get_at_offset(offset)
			%IconList.set_item_icon(idx, ImageTexture.create_from_image(icon_image))
	
	# FXSCRIPT.SFX
	# Clear
	%SFXList.clear()
	
	var sfx_entries: Array = FXScript.get_sfx_entries()
	if not sfx_entries.is_empty():
		for i in range(len(sfx_entries)):
			var entry: Dictionary = sfx_entries[i]
			var idx: int = %SFXList.add_item("%d: %s - %s" % [(i+1), entry.name, entry.desc])
			%SFXList.set_item_metadata(idx, entry)
	
	# BACKDROP.RAW
	%BackdropRect.texture = null
	var backdrop_image: Image = Backdrop.parse()
	if backdrop_image:
		%BackdropRect.texture = ImageTexture.create_from_image(backdrop_image)


func _on_command_list_item_selected(index: int) -> void:
	var action: Dictionary = %CommandList.get_item_metadata(index)
	
	for tree_item: TreeItem in %CommandTree.get_root().get_children():
		tree_item.free()
	for node: Node in %CommandPanel.get_children():
		node.queue_free()
	
	for opcode: Dictionary in action.opcodes:
		var tree_item: TreeItem = %CommandTree.get_root().create_child()
		tree_item.set_text(0, "%d" % opcode.command)
		tree_item.set_metadata(0, opcode)
		tree_item.set_text(1, "%d" % opcode.full_value)


func _on_command_tree_item_selected() -> void:
	for node: Node in %CommandPanel.get_children():
		node.queue_free()
	
	var vbox := VBoxContainer.new()
	%CommandPanel.add_child(vbox)
	
	var tree_item: TreeItem = %CommandTree.get_selected()
	var opcode: Dictionary = tree_item.get_metadata(0)
	match opcode.command:
		5:
			var label := Label.new()
			var subtitle := DBase400.get_at_offset(opcode.full_value)
			label.text = "%s" % subtitle.string
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			label.autowrap_mode = TextServer.AUTOWRAP_WORD
			var color: Array = Das.get_default_palette()[subtitle.font_color]
			label.add_theme_color_override("font_color", Color(color[0], color[1], color[2]))
			
			var scroll := ScrollContainer.new()
			scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
			scroll.add_child(label)
			vbox.add_child(scroll)
			
			var button := Button.new()
			button.text = "Play"
			button.pressed.connect(func () -> void:
				var entry: Dictionary = DBase500.get_entry_at_offset(subtitle.offset)
				if entry.is_empty():
					return
				Roth.play_audio_buffer(entry.data, entry.sampleRate)
			)
			vbox.add_child(button)
		7:
			var label := Label.new()
			var cutscene: Dictionary = dbase100.cutscenes[opcode.full_value-1]
			label.text = "%s" % cutscene.entry.string
			label.autowrap_mode = TextServer.AUTOWRAP_WORD
			vbox.add_child(label)
			
			vbox.add_child(HSeparator.new())
			
			var rich_text := RichTextLabel.new()
			rich_text.bbcode_enabled = true
			rich_text.selection_enabled = true
			rich_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
			vbox.add_child(rich_text)
			
			var palette: Array = Das.get_default_palette()
			for subtitle_line: Dictionary in cutscene.subtitles.entries:
				if subtitle_line.string.is_empty():
					continue
				var color: String = Color(palette[subtitle_line.font_color][0], palette[subtitle_line.font_color][1], palette[subtitle_line.font_color][2]).to_html()
				rich_text.append_text("- [color=%s]%s[/color]\n" % [color, subtitle_line.string])
		8:
			var label := Label.new()
			label.text = "%s" % DBase400.get_at_offset(opcode.full_value).string
			vbox.add_child(label)


func _on_cutscene_list_item_selected(index: int) -> void:
	for node: Node in %CutscenePanel.get_children():
		node.queue_free()
	
	%VideoControlsContainer.show()
	
	var cutscene: Dictionary = %CutsceneList.get_item_metadata(index)
	
	var vbox := VBoxContainer.new()
	%CutscenePanel.add_child(vbox)
	
	var label := Label.new()
	label.text = "%s" % cutscene.entry.string
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(label)
	vbox.add_child(HSeparator.new())
	
	if "subtitles" in cutscene:
		var rich_text := RichTextLabel.new()
		rich_text.bbcode_enabled = true
		rich_text.selection_enabled = true
		rich_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(rich_text)
		
		var palette: Array = Das.get_default_palette()
		for subtitle_line: Dictionary in cutscene.subtitles.entries:
			if subtitle_line.string.is_empty():
				continue
			var color: String = Color(palette[subtitle_line.font_color][0], palette[subtitle_line.font_color][1], palette[subtitle_line.font_color][2]).to_html()
			rich_text.append_text("- [color=%s]%s[/color]\n" % [color, subtitle_line.string])


func _on_cutscene_list_item_activated(_index: int) -> void:
	%VideoTimer.stop()
	play_video()


func _on_play_video_button_pressed() -> void:
	play_video()


func _on_pause_video_button_pressed() -> void:
	pause_video()


func _on_stop_video_button_pressed() -> void:
	stop_video()


func play_video() -> void:
	if not %VideoTimer.is_stopped():
		pause_video()
		return
	stop_video()
	var cutscene: Dictionary = %CutsceneList.get_item_metadata(%CutsceneList.get_selected_items()[0])
	var gdv: Dictionary
	if current_video.is_empty() or (current_video and current_video.name != cutscene.name):
		await get_tree().process_frame
		await get_tree().process_frame
		var thread := Thread.new()
		%VideoLoadingBar.show()
		%VideoLoadingBar.value = 0
		thread.start(parse_thread.bind(cutscene.name))
		gdv = await gdv_parsing_done
		%VideoLoadingBar.hide()
		thread.wait_to_finish()
	else:
		gdv = current_video
	if not gdv.is_empty() and "header" in gdv:
		Roth.play_audio_buffer(gdv.audio, gdv.header.playback_frequency)
		current_video = gdv
		current_frame = 0
		%VideoTitleLabel.text = "%s" % gdv.name
		%VideoRect.texture = ImageTexture.create_from_image(current_video.video[current_frame])
		%VideoTimer.paused = false
		%VideoTimer.start()
		%VideoSlider.max_value = len(current_video.video) - 1
		%VideoTimeLabel.text = "%s/%s" % [_seconds_to_time(0), _seconds_to_time(int(float(len(current_video.video)/current_video.header.framerate)))]


func parse_thread(gdv_name: String) -> void:
	#var gdv: Dictionary = GDV.get_video(gdv_name)
	var gdv_filepath: String =  Roth.directory.path_join("..").path_join("DATA").path_join("GDV").path_join("%s.GDV" % gdv_name)
	var gdv: Dictionary = RothExt.get_video_by_path(gdv_filepath, func (percent: float) -> void: Roth.gdv_loading_updated.emit(percent))
	gdv_parsing_done.emit.call_deferred(gdv)


func _on_gdv_loading_updated(progress: float) -> void:
	%VideoLoadingBar.value = progress * 100


func pause_video() -> void:
	if %VideoTimer.paused:
		%VideoTimer.paused = false
		#Roth.unpause_audio()
		var percentage: float = float(current_frame)/len(current_video.video)
		var audio_frame: int = int(len(current_video.audio) * percentage)
		Roth.play_audio_buffer(current_video.audio.slice(int(audio_frame)), current_video.header.playback_frequency)
	else:
		Roth.stop_audio_buffer()
		#Roth.pause_audio()
		%VideoTimer.paused = true


func _on_video_timer_timeout() -> void:
	if current_frame+1 >= len(current_video.video)-1:
		stop_video()
		current_frame = len(current_video.video)-1
		%VideoSlider.value = current_frame
		%VideoRect.texture = ImageTexture.create_from_image(current_video.video[current_frame-1])
		%VideoTimeLabel.text = "%s/%s" % [_seconds_to_time(int(float(current_frame-1)/current_video.header.framerate)), _seconds_to_time(int(float(len(current_video.video)/current_video.header.framerate)))]
		return
	current_frame = (current_frame + 1) % (len(current_video.video) - 1)
	%VideoRect.texture = ImageTexture.create_from_image(current_video.video[current_frame])
	%VideoTimeLabel.text = "%s/%s" % [_seconds_to_time(int(float(current_frame)/current_video.header.framerate)), _seconds_to_time(int(float(len(current_video.video)/current_video.header.framerate)))]

	if not dragging_slider:
		%VideoSlider.value = current_frame


func _on_video_slider_drag_ended(value_changed: bool) -> void:
	dragging_slider = false
	%VideoDragLabel.text = ""
	if value_changed:
		current_frame = %VideoSlider.value - 1
		if current_frame < 0:
			current_frame = 0
		if not %VideoTimer.paused and not %VideoTimer.is_stopped():
			var percentage: float = float(current_frame)/len(current_video.video)
			var audio_frame: int = int(len(current_video.audio) * percentage)
			Roth.play_audio_buffer(current_video.audio.slice(int(audio_frame)), current_video.header.playback_frequency)
		_on_video_timer_timeout()


func _on_video_slider_drag_started() -> void:
	dragging_slider = true


func _on_video_slider_value_changed(value: float) -> void:
	if dragging_slider:
		%VideoDragLabel.text = "%s" % _seconds_to_time(int(float(value)/current_video.header.framerate))
		if %VideoTimer.paused or %VideoTimer.is_stopped():
			%VideoRect.texture = ImageTexture.create_from_image(current_video.video[value])


func stop_video() -> void:
	#print("STOP")
	#GDV.stop_loading()
	RothExt.stop_video_loading()
	Roth.stop_audio_buffer()
	#%VideoTimer.stop()
	if current_video:
		%VideoRect.texture = ImageTexture.create_from_image(current_video.video[0])
		%VideoTimeLabel.text = "00:00/%s" % [_seconds_to_time(int(float(len(current_video.video)/current_video.header.framerate)))]
	%VideoSlider.value = 0
	#%VideoSlider.max_value = 0
	%VideoTimer.paused = true
	current_frame = 0


func _seconds_to_time(total: int) -> String:
	var seconds: int = total % 60
	@warning_ignore("integer_division")
	var minutes: int = total / 60
	@warning_ignore("integer_division")
	var hours: int = minutes / 60
	if minutes >= 60:
		minutes = minutes % 60
	var result := "%02d:%02d:%02d" % [hours,minutes,seconds]
	if hours == 0:
		result = "%02d:%02d" % [minutes,seconds]
	return result


func _on_inventory_list_item_selected(index: int) -> void:
	for node: Node in %InventoryPanel.get_children():
		node.queue_free()
	
	var inventory_item: Dictionary = %InventoryList.get_item_metadata(index)
	
	
	var title := Label.new()
	#title.size_flags_horizontal = Control.SIZE_SHRINK_CENTER & Control.SIZE_EXPAND
	title.text = "%s" % inventory_item.subtitle.string
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var vbox_main := VBoxContainer.new()
	vbox_main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_main.add_child(title)
	vbox_main.add_child(HSeparator.new())
	%InventoryPanel.add_child(vbox_main)
	
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)
	
	var image_hbox := HBoxContainer.new()
	vbox_main.add_child(image_hbox)
	
	if "inventory_image" in inventory_item and inventory_item["inventory_image"] != 0:
		var image: Image = DBase200.get_at_offset(inventory_item["inventory_image"]*8+4)
		var texture_rect := TextureRect.new()
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		texture_rect.custom_minimum_size.y = 150
		texture_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		texture_rect.texture = ImageTexture.create_from_image(image)
		image_hbox.add_child(texture_rect)
	if "closeup_image" in inventory_item and inventory_item["closeup_image"] != 0:
		var video: Dictionary = DBase300.get_at_offset(inventory_item["closeup_image"]*8)
		if video:
			
			var texture_rect := TextureRect.new()
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			texture_rect.custom_minimum_size.y = 150
			texture_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			#texture_rect.texture = ImageTexture.create_from_image(image)
			image_hbox.add_child(texture_rect)
			
			var animated_image := AnimatedSprite2D.new()
			animated_image.hide()
			var sprite_frames := SpriteFrames.new()
			animated_image.sprite_frames = sprite_frames
			sprite_frames.set_animation_speed("default", 12)
			for image: Image in video.video:
				sprite_frames.add_frame("default", ImageTexture.create_from_image(image))
			if inventory_item.closeup_type & 1 > 0:
				sprite_frames.set_animation_loop("default", false)
			animated_image.play("default")
			animated_image.frame_changed.connect(func () -> void: texture_rect.texture = sprite_frames.get_frame_texture("default", animated_image.frame))
			image_hbox.add_child(animated_image)
			
			
	
	vbox_main.add_child(scroll)
	
	for key: String in inventory_item:
		if key == "subtitle" or key == "offset_dbase400":
			continue
		
		var hbox := HBoxContainer.new()
		
		vbox.add_child(hbox)
		
		var label1 := Label.new()
		label1.text = "%s:" % key
		label1.custom_minimum_size.x = 200
		hbox.add_child(label1)
		
		var label2 := Label.new()
		label2.text = "%s" % [inventory_item[key]]
		#label2.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		label2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(label2)


func _on_d_base_200_list_item_selected(index: int) -> void:
	for node: Node in %DBase200Panel.get_children():
		node.queue_free()
	%AnimationTimer.stop()
	var image_offset: int = %DBase200List.get_item_metadata(index)
	var image: Variant = DBase200.get_at_offset(image_offset)
	match typeof(image):
		TYPE_ARRAY:
			animation_position = 0
			animation = image
			animation_rect = TextureRect.new()
			animation_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			animation_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			animation_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			animation_rect.custom_minimum_size.y = 100
			animation_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
			animation_rect.texture = ImageTexture.create_from_image(animation[animation_position])
			%DBase200Panel.add_child(animation_rect)
			%AnimationTimer.start()
		TYPE_OBJECT:
			var texture_rect := TextureRect.new()
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			texture_rect.custom_minimum_size.y = 100
			texture_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
			texture_rect.texture = ImageTexture.create_from_image(image)
			%DBase200Panel.add_child(texture_rect)


func _on_animation_timer_timeout() -> void:
	if len(animation) == 1:
		return
	animation_position = (animation_position + 1) % (len(animation) - 1)
	animation_rect.texture = ImageTexture.create_from_image(animation[animation_position])


func _on_tab_container_tab_changed(_tab: int) -> void:
	%AnimationTimer.stop()


func _on_sfx_list_item_activated(index: int) -> void:
	var entry: Dictionary = %SFXList.get_item_metadata(index)
	var entry_data := FXScript.get_from_entry(entry)
	Roth.play_audio_entry(entry_data)
