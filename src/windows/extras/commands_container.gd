extends MarginContainer

var dbase100: Dictionary = {}


func _ready() -> void:
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
	
	dbase100 = DBase100.parse()
	if not dbase100.is_empty():
		# Actions/Commands
		for i in range(len(dbase100.actions)):
			var action: Dictionary = dbase100.actions[i]
			if action.commands.is_empty():
				continue
			var idx: int = %CommandList.add_item("%d" % (i+1))
			%CommandList.set_item_metadata(idx, action)


func _on_command_list_item_selected(index: int) -> void:
	var action: Dictionary = %CommandList.get_item_metadata(index)
	
	for tree_item: TreeItem in %CommandTree.get_root().get_children():
		tree_item.free()
	for node: Node in %CommandPanel.get_children():
		node.queue_free()
	
	for command: Dictionary in action.commands:
		var tree_item: TreeItem = %CommandTree.get_root().create_child()
		tree_item.set_text(0, "%d" % command.opcode)
		tree_item.set_metadata(0, command)
		tree_item.set_text(1, "%d" % command.args)


func _on_command_tree_item_selected() -> void:
	for node: Node in %CommandPanel.get_children():
		node.queue_free()
	
	var vbox := VBoxContainer.new()
	%CommandPanel.add_child(vbox)
	
	var tree_item: TreeItem = %CommandTree.get_selected()
	var opcode: Dictionary = tree_item.get_metadata(0)
	match opcode.opcode:
		5:
			var label := Label.new()
			var subtitle := DBase400.get_at_offset(opcode.args)
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
				var entry: Dictionary = DBase500.get_entry_at_offset(subtitle.dbase500_offset)
				if entry.is_empty():
					return
				Roth.play_audio_buffer(entry.data, entry.sampleRate)
			)
			vbox.add_child(button)
		7:
			var label := Label.new()
			var cutscene: Dictionary = dbase100.cutscenes[opcode.args-1]
			label.text = "%s" % cutscene.text_entry.string
			label.autowrap_mode = TextServer.AUTOWRAP_WORD
			vbox.add_child(label)
			
			vbox.add_child(HSeparator.new())
			
			var rich_text := RichTextLabel.new()
			rich_text.bbcode_enabled = true
			rich_text.selection_enabled = true
			rich_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
			vbox.add_child(rich_text)
			
			if "subtitles" in cutscene and "entries" in cutscene.subtitles:
				var palette: Array = Das.get_default_palette()
				for subtitle_line: Dictionary in cutscene.subtitles.entries:
					if subtitle_line.string.is_empty():
						continue
					var color: String = Color(palette[subtitle_line.font_color][0], palette[subtitle_line.font_color][1], palette[subtitle_line.font_color][2]).to_html()
					rich_text.append_text("- [color=%s]%s[/color]\n" % [color, subtitle_line.string])
		8:
			var label := Label.new()
			label.text = "%s" % DBase400.get_at_offset(opcode.args).string
			vbox.add_child(label)

var previous_search: String
var search_count: int = 0

func _on_command_search_edit_text_submitted(new_text: String) -> void:
	
	if new_text.is_empty():
		return
	
	if new_text == previous_search:
		search_count += 1
	else:
		search_count = 0
	previous_search = new_text
	var search_amount: int = search_count
	
	var search_type: int = -1
	match %CommandSearchOption.selected:
		0:
			search_type = 4
		1:
			search_type = 132
		2:
			search_type = 1
		3:
			search_type = 129
		4:
			search_type = 13
		5:
			search_type = 141
		6:
			search_type = 54
	#print(search_type)
	for i in range(len(dbase100.actions)):
		var action: Dictionary = dbase100.actions[i]
		if action.offset == 0 or action.length == 0:
			continue
		for opcode: Dictionary in action.opcodes:
			if opcode.opcode == search_type and opcode.args == new_text.to_int():
				
				if search_amount == 0:
				
					for j in range(%CommandList.item_count):
						if %CommandList.get_item_text(j) == str(i+1):
							%CommandList.select(j)
							%CommandList.ensure_current_is_visible()
							_on_command_list_item_selected(j)
							var tree_item: TreeItem = %CommandTree.get_root().get_first_child()
							
							while tree_item:
								if tree_item.get_text(0) == str(opcode.opcode) and tree_item.get_text(1) == str(opcode.args):
									%CommandTree.set_selected(tree_item, 0)
									break
								tree_item = tree_item.get_next()
							break
					return
				else:
					search_amount -= 1
	
	if search_count > 0:
		search_count = 0
		previous_search = ""
		_on_command_search_edit_text_submitted(new_text)
