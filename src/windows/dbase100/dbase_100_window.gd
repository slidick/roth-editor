extends BaseWindow

var dbase100: Dictionary = {}

func _ready() -> void:
	super._ready()
	Roth.settings_loaded.connect(_on_settings_loaded)
	%CommandTree.create_item()
	%CommandTree.set_column_title(0, "Command")
	%CommandTree.set_column_title(1, "Value")


func _on_settings_loaded() -> void:
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
	
	dbase100 = DBase100.parse()
	if dbase100.is_empty():
		return
	
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
	
	var vbox := VBoxContainer.new()
	var scroll := ScrollContainer.new()
	scroll.add_child(vbox)
	%InventoryPanel.add_child(scroll)
	
	var title := Label.new()
	title.text = "%s" % inventory_item.subtitle.string
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())
	
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
		#label2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(label2)
		
