extends BaseWindow

var dbase100: Dictionary = {}
var animation: Array
var animation_position: int = 0
var animation_rect: TextureRect

func _ready() -> void:
	super._ready()
	Roth.settings_loaded.connect(_on_settings_loaded)
	%CommandTree.create_item()
	%CommandTree.set_column_title(0, "Command")
	%CommandTree.set_column_title(1, "Value")


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
	for node: Node in %IconPanel.get_children():
		node.queue_free()
		
	# IconsAll Parse
	var icons_offsets: Array = IconsAll.get_icon_offsets()
	if not icons_offsets.is_empty():
		# IconsAll Init
		for i in range(len(icons_offsets)):
			var offset: int = icons_offsets[i]
			var idx: int = %IconList.add_item("%d"  % (i+1))
			%IconList.set_item_metadata(idx, offset)
	
	# FXSCRIPT.SFX
	# Clear
	%SFXList.clear()
	
	var sfx_entries: Array = FXScript.get_sfx_entries()
	if not sfx_entries.is_empty():
		for i in range(len(sfx_entries)):
			var entry: Dictionary = sfx_entries[i]
			var idx: int = %SFXList.add_item("%d: %s - %s" % [(i+1), entry.name, entry.desc])
			%SFXList.set_item_metadata(idx, entry)


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
				var data: Array = DBase500.get_at_offset(subtitle.offset)
				if data.is_empty():
					return
				Roth.play_audio_buffer(data)
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


func _on_cutscene_list_item_selected(index: int) -> void:
	for node: Node in %CutscenePanel.get_children():
		node.queue_free()
	
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
	
	if "inventory_image" in inventory_item and inventory_item["inventory_image"] != 0:
		var image: Image = DBase200.get_at_offset(inventory_item["inventory_image"]*8+4)
		var texture_rect := TextureRect.new()
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		texture_rect.custom_minimum_size.y = 150
		#texture_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		texture_rect.texture = ImageTexture.create_from_image(image)
		vbox_main.add_child(texture_rect)
	
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


func _on_icon_list_item_selected(index: int) -> void:
	for node: Node in %IconPanel.get_children():
		node.queue_free()
	var image_offset: int = %IconList.get_item_metadata(index)
	var image: Image = IconsAll.get_at_offset(image_offset)
	var texture_rect := TextureRect.new()
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_rect.custom_minimum_size.y = 100
	texture_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	texture_rect.texture = ImageTexture.create_from_image(image)
	%IconPanel.add_child(texture_rect)


func _on_sfx_list_item_activated(index: int) -> void:
	var entry: Dictionary = %SFXList.get_item_metadata(index)
	var entry_data := FXScript.get_from_entry(entry)
	Roth.play_audio_entry(entry_data)
