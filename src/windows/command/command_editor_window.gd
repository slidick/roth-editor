extends BaseWindow

const COMMAND_NODE = preload("uid://bg2itg1120pon")
const VERTICAL_SPACING: int = 546
const HORIZONTAL_SPACING: int = 400

var map: Map
var command_section := {}
var selected_arg: TreeItem
var row_value: int = 0
var add_at_position := Vector2.ZERO

func _ready() -> void:
	super._ready()
	%ArgsTree.create_item()


func _fade_out() -> void:
	super._fade_out()
	clear_entry()


func clear_entry() -> void:
	%CommandBaseEdit.editable = false
	%CommandModifierEdit.editable = false
	%CommandNextCommandIndexEdit.editable = false
	%AddArgButton.disabled = true
	%CommandIndexEdit.text = ""
	%CommandBaseEdit.text = ""
	%CommandModifierEdit.text = ""
	%CommandNextCommandIndexEdit.text = ""
	%ArgsLabel.text = ""
	for child: TreeItem in %ArgsTree.get_root().get_children():
		%ArgsTree.get_root().remove_child(child)
		child.free()


func edit_data(p_map: Map) -> void:
	var p_command_section: Dictionary = p_map.commands_section
	map = p_map
	if command_section != p_command_section:
		command_section = p_command_section.duplicate(true)
		%EntryCommandIndices.clear()
		for child: Node in %GraphEdit.get_children():
			if child.name == "_connection_layer":
				continue
			child.queue_free()
		var command_nodes := {}
		for i in range(len(command_section.entryCommandIndexes)):
			%EntryCommandIndices.add_item("%d" % command_section.entryCommandIndexes[i])
			%EntryCommandIndices.set_item_metadata(i, command_section.entryCommandIndexes[i])
			
			var command_node: CommandNode = COMMAND_NODE.instantiate()
			command_node.initialize(command_section.entryCommandIndexes[i], command_section.allCommands[command_section.entryCommandIndexes[i]-1])
			command_node.set_slot(0, false, 0, Color.BLACK, true, 0, Color.WHITE)
			
			if "node_data" in command_section.allCommands[command_section.entryCommandIndexes[i]-1]:
				command_node.position_offset.x = command_section.allCommands[command_section.entryCommandIndexes[i]-1].node_data.x
				command_node.position_offset.y = command_section.allCommands[command_section.entryCommandIndexes[i]-1].node_data.y
			else:
				command_node.position_offset.y = VERTICAL_SPACING * i
			row_value = i + 1
			%GraphEdit.add_child(command_node)
			command_node.title = "Entry Command"
			command_nodes[command_section.entryCommandIndexes[i]] = command_node
			
			var next_command_index: int = command_section.allCommands[command_section.entryCommandIndexes[i]-1].nextCommandIndex
			var graph_node_prev: StringName = command_node.name
			var j: int = 1
			while next_command_index != 0:
				var command_node_2: CommandNode
				if next_command_index in command_nodes:
					command_node_2 = command_nodes[next_command_index]
				else:
					command_node_2 = COMMAND_NODE.instantiate()
					command_node_2.initialize(next_command_index, command_section.allCommands[next_command_index-1])
					if "node_data" in command_section.allCommands[next_command_index-1]:
						command_node_2.position_offset.x = command_section.allCommands[next_command_index-1].node_data.x
						command_node_2.position_offset.y = command_section.allCommands[next_command_index-1].node_data.y
					else:
						command_node_2.position_offset.y = VERTICAL_SPACING * i
						command_node_2.position_offset.x = j * HORIZONTAL_SPACING
					%GraphEdit.add_child(command_node_2)
				j += 1
				command_nodes[next_command_index] = command_node_2
				next_command_index = command_section.allCommands[next_command_index-1].nextCommandIndex
				
				%GraphEdit.connect_node(graph_node_prev, 0, command_node_2.name, 0)
				
				graph_node_prev = command_node_2.name
				
		
		var k: int = 0
		var repeat := []
		for i in range(len(command_section.allCommands)):
			if i + 1 not in command_nodes:
				var command_node: CommandNode = COMMAND_NODE.instantiate()
				command_node.initialize(i+1, command_section.allCommands[i])
				command_node.set_slot(0, false, 0, Color.BLACK, true, 0, Color.WHITE)
				
				if "node_data" in command_section.allCommands[i]:
					command_node.position_offset.x = command_section.allCommands[i].node_data.x
					command_node.position_offset.y = command_section.allCommands[i].node_data.y
				else:
					command_node.position_offset.y = VERTICAL_SPACING * k
					k += 1
					command_node.position_offset.x = -600
				%GraphEdit.add_child(command_node)
				command_node.title = "Orphan Command"
				command_nodes[i+1] = command_node
				repeat.append(command_node)
		
		
		for command_node: CommandNode in repeat:
			if command_node.data.nextCommandIndex != 0:
				%GraphEdit.connect_node(command_node.name, 0, command_nodes[command_node.data.nextCommandIndex].name, 0)
				if command_nodes[command_node.data.nextCommandIndex].title == "Orphan Command":
					command_nodes[command_node.data.nextCommandIndex].title = "Command"
		#%GraphEdit.arrange_nodes()
		
		%AllCommandIndices.clear()
		for i in range(len(command_section.allCommands)):
			%AllCommandIndices.add_item("%d" % (i+1))
			%AllCommandIndices.set_item_metadata(i, command_nodes[i+1])
			command_nodes[i+1].refresh.connect(_on_refresh)
			command_nodes[i+1].add_to_entry_list.connect(_on_add_to_entry_list)
			command_nodes[i+1].remove_from_entry_list.connect(_on_remove_from_entry_list)
			command_nodes[i+1].delete_command.connect(_on_delete_command)
		
	
	toggle(true)


func _on_cancel_button_pressed() -> void:
	toggle(false)


func _on_save_button_pressed() -> void:
	save_positions()
	map.commands_section = command_section.duplicate(true)


func save_positions() -> void:
	for command_node: Control in %GraphEdit.get_children():
		if command_node.name == "_connection_layer":
			continue
		command_node.save_position()


func _on_refresh() -> void:
	if not %AllCommandIndices.get_selected_items():
		return
	var command_node: CommandNode = %AllCommandIndices.get_item_metadata(%AllCommandIndices.get_selected_items()[0])
	%CommandIndexEdit.text = "%d" % command_node.index
	%CommandBaseEdit.text = "%d" % command_node.command_base
	%CommandModifierEdit.text = "%d" % command_node.command_modifier
	%CommandNextCommandIndexEdit.text = "%d" % command_node.next_command_index
	%ArgsLabel.text = ""
	for tree_item: TreeItem in %ArgsTree.get_root().get_children():
		tree_item.free()
	var i: int = 0
	for value: int in command_node.args:
		var tree_item: TreeItem = %ArgsTree.get_root().create_child()
		tree_item.set_text(0, "%d" % value)
		tree_item.set_editable(0, true)
		if i >= 2:
			%ArgsLabel.text += String.chr((value) & 0xFF)
			%ArgsLabel.text += String.chr((value >> 8) & 0xFF)
		i += 1


func _on_entry_command_indices_item_selected(index: int) -> void:
	var metadata: int = %EntryCommandIndices.get_item_metadata(index)
	%AllCommandIndices.select(metadata-1)
	_on_all_command_indices_item_selected(metadata-1)
	%AllCommandIndices.ensure_current_is_visible()


func _on_all_command_indices_item_selected(index: int) -> void:
	switch_to_command(index)
	ensure_visible(%AllCommandIndices.get_item_metadata(index))


func switch_to_command(index: int) -> void:
	var metadata: CommandNode = %AllCommandIndices.get_item_metadata(index)
	
	%CommandIndexEdit.text = "%d" % (index + 1)
	%CommandBaseEdit.text = "%d" % metadata.command_base
	%CommandBaseEdit.editable = true
	%CommandModifierEdit.text = "%d" % metadata.command_modifier
	%CommandModifierEdit.editable = true
	%CommandNextCommandIndexEdit.text = "%d" % metadata.next_command_index
	%CommandNextCommandIndexEdit.editable = true
	%AddArgButton.disabled = false
	for child: TreeItem in %ArgsTree.get_root().get_children():
		%ArgsTree.get_root().remove_child(child)
		child.free()
	%ArgsLabel.text = ""
	var i: int = 0
	for value: int in metadata.args:
		var tree_item: TreeItem = %ArgsTree.get_root().create_child()
		tree_item.set_text(0, "%d" % value)
		tree_item.set_editable(0, true)
		if i >= 2:
			%ArgsLabel.text += String.chr((value) & 0xFF)
			%ArgsLabel.text += String.chr((value >> 8) & 0xFF)
		i += 1
	
	update_command_base()


func ensure_visible(command_node: GraphNode) -> void:
	%GraphEdit.scroll_offset = command_node.position_offset * %GraphEdit.zoom
	%GraphEdit.scroll_offset.x -= (%GraphEdit.size.x / 2) - (command_node.size.x / 2) * %GraphEdit.zoom
	%GraphEdit.scroll_offset.y -= (%GraphEdit.size.y / 2) - (command_node.size.y / 2) * %GraphEdit.zoom
	%GraphEdit.set_selected(command_node)


func _on_args_tree_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			selected_arg = %ArgsTree.get_item_at_position(mouse_position)
			%ArgsPopupMenu.popup(Rect2i(int(mouse_position.x + %ArgsTree.global_position.x), int(mouse_position.y + %ArgsTree.global_position.y), 0, 0))


func _on_args_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			%ArgsTree.get_root().remove_child(selected_arg)
			selected_arg.free()
			selected_arg = null
			update_args_array()


func _on_add_arg_button_pressed() -> void:
	var tree_item: TreeItem = %ArgsTree.get_root().create_child()
	tree_item.set_text(0, "0")
	tree_item.set_editable(0, true)
	%ArgsTree.scroll_to_item(tree_item)
	update_args_array()


func _on_command_base_edit_text_changed(new_text: String) -> void:
	%AllCommandIndices.get_item_metadata(%AllCommandIndices.get_selected_items()[0]).command_base = int(new_text)
	update_command_base()


func update_command_base() -> void:
	if %AllCommandIndices.get_item_metadata(%AllCommandIndices.get_selected_items()[0]).command_base == 59:
		%MapNameButton.show()
		%ArgsLabel.show()
	else:
		%MapNameButton.hide()
		%ArgsLabel.hide()


func _on_command_modifier_edit_text_changed(new_text: String) -> void:
	%AllCommandIndices.get_item_metadata(%AllCommandIndices.get_selected_items()[0]).command_modifier = int(new_text)


func _on_command_next_command_index_edit_text_changed(new_text: String) -> void:
	%AllCommandIndices.get_item_metadata(%AllCommandIndices.get_selected_items()[0]).next_command_index = int(new_text)


func _on_args_tree_item_edited() -> void:
	update_args_array()


func _on_args_tree_item_moved() -> void:
	update_args_array()


func update_args_array() -> void:
	var arg_array := []
	for tree_item: TreeItem in %ArgsTree.get_root().get_children():
		arg_array.append(int(tree_item.get_text(0)))
	%AllCommandIndices.get_item_metadata(%AllCommandIndices.get_selected_items()[0]).args = arg_array 
	%ArgsLabel.text = ""
	for value: int in arg_array.slice(2):
		%ArgsLabel.text += String.chr((value) & 0xFF)
		%ArgsLabel.text += String.chr((value >> 8) & 0xFF)


func _on_graph_edit_connection_request(from_node: StringName, from_port: int, to_node: StringName, _to_port: int) -> void:
	for conn: Dictionary in %GraphEdit.connections:
		if conn.from_node == from_node and conn.from_port == from_port:
			return
	#%GraphEdit.connect_node(from_node, from_port, to_node, to_port)
	%GraphEdit.get_node(str(from_node)).next_command_index = %GraphEdit.get_node(str(to_node)).index
	if %GraphEdit.get_node(str(to_node)).title == "Orphan Command":
		%GraphEdit.get_node(str(to_node)).title = "Command"


func _on_graph_edit_disconnection_request(from_node: StringName, _from_port: int, to_node: StringName, _to_port: int) -> void:
	#%GraphEdit.disconnect_node(from_node, from_port, to_node, to_port)
	%GraphEdit.get_node(str(from_node)).next_command_index = 0
	
	var another_connection: bool = false
	for conn: Dictionary in %GraphEdit.connections:
		if conn.to_node == to_node:
			another_connection = true
	
	if (not another_connection 
		and %GraphEdit.get_node(str(to_node)).title != "Entry Command"
	):
		%GraphEdit.get_node(str(to_node)).title = "Orphan Command"


func _on_add_command_button_pressed() -> void:
	add_command()


func add_command(at_position: Variant = null) -> void:
	var new_command := {
		"commandBase": 1,
		"commandModifier": 0,
		"nextCommandIndex": 0,
		"args": [0],
	}
	
	var new_index: int = %AllCommandIndices.item_count + 1
	
	var command_node: CommandNode = COMMAND_NODE.instantiate()
	command_node.initialize(new_index, new_command)
	command_node.set_slot(0, false, 0, Color.BLACK, true, 0, Color.WHITE)
	if at_position:
		var pos:Vector2 = (at_position + %GraphEdit.scroll_offset) / %GraphEdit.zoom
		command_node.position_offset = pos
	else:
		command_node.position_offset.y = VERTICAL_SPACING * row_value
	row_value += 1
	%GraphEdit.add_child(command_node)
	command_node.title = "Orphan Command"
	command_node.refresh.connect(_on_refresh)
	command_node.add_to_entry_list.connect(_on_add_to_entry_list)
	command_node.remove_from_entry_list.connect(_on_remove_from_entry_list)
	command_node.delete_command.connect(_on_delete_command)
	command_section.allCommands.append(new_command)
	var _index: int = %AllCommandIndices.add_item("%d" % new_index)
	%AllCommandIndices.set_item_metadata(_index, command_node)
	%AllCommandIndices.select(_index)
	%AllCommandIndices.ensure_current_is_visible()
	switch_to_command(_index)


func _on_all_command_indices_item_clicked(_index: int, at_position: Vector2, mouse_button_index: int) -> void:
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			if %AllCommandIndices.get_item_metadata(%AllCommandIndices.get_selected_items()[0]).index in command_section.entryCommandIndexes:
				%AllCommandPopupMenu.set_item_disabled(0, true)
			else:
				%AllCommandPopupMenu.set_item_disabled(0, false)
			%AllCommandPopupMenu.popup(Rect2i(int(at_position.x + %AllCommandIndices.global_position.x), int(at_position.y + %AllCommandIndices.global_position.y), 0, 0))


func _on_all_command_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			var selected_index: int = %AllCommandIndices.get_item_metadata(%AllCommandIndices.get_selected_items()[0]).index
			add_to_entry_list(selected_index)
		1:
			var selected_index: int = %AllCommandIndices.get_item_metadata(%AllCommandIndices.get_selected_items()[0]).index
			delete_command(selected_index)


func _on_add_to_entry_list(index: int) -> void:
	add_to_entry_list(index)


func add_to_entry_list(index: int) -> void:
	command_section.entryCommandIndexes.append(index)
	#command_section.entryCommandIndexes.sort()
	command_section.entryCommandIndexes.sort_custom(func (i1: int, i2: int) -> bool: return command_section.allCommands[i1-1].commandBase < command_section.allCommands[i2-1].commandBase)
	
	var new_entry_indexes_mapping: Dictionary = {}
	for entry_command_index: int in command_section.entryCommandIndexes:
		var command_base: int = command_section.allCommands[entry_command_index-1].commandBase
		if command_base not in new_entry_indexes_mapping:
			new_entry_indexes_mapping[command_base] = [entry_command_index]
		else:
			new_entry_indexes_mapping[command_base].append(entry_command_index)
	
	var new_entry_indexes: Array = []
	for command_base: int in new_entry_indexes_mapping:
		new_entry_indexes_mapping[command_base].sort()
		new_entry_indexes.append_array(new_entry_indexes_mapping[command_base])
	command_section.entryCommandIndexes = new_entry_indexes
	
	var selected_index: int = 0
	%EntryCommandIndices.clear()
	for i in range(len(command_section.entryCommandIndexes)):
		%EntryCommandIndices.add_item("%d" % command_section.entryCommandIndexes[i])
		%EntryCommandIndices.set_item_metadata(i, command_section.entryCommandIndexes[i])
		if command_section.entryCommandIndexes[i] == index:
			selected_index = i
	%EntryCommandIndices.select(selected_index)
	
	%AllCommandIndices.select(index-1)
	%AllCommandIndices.ensure_current_is_visible()
	switch_to_command(index-1)
	%EntryCommandIndices.ensure_current_is_visible()
	%AllCommandIndices.get_item_metadata(index-1).title = "Entry Command"


func _on_remove_from_entry_list(index: int) -> void:
	remove_from_entry_list(index)


func remove_from_entry_list(index: int) -> void:
	if not index in command_section.entryCommandIndexes:
		return
	command_section.entryCommandIndexes.erase(index)
	
	var has_to: bool = false
	for conn: Dictionary in %GraphEdit.connections:
		if conn.to_node == %AllCommandIndices.get_item_metadata(index-1).name:
			has_to = true
	
	if has_to == false:
		%AllCommandIndices.get_item_metadata(index-1).title = "Orphan Command"
	else:
		%AllCommandIndices.get_item_metadata(index-1).title = "Command"
	
	reset_entry_list()


func reset_entry_list() -> void:
	%EntryCommandIndices.clear()
	for i in range(len(command_section.entryCommandIndexes)):
		%EntryCommandIndices.add_item("%d" % command_section.entryCommandIndexes[i])
		%EntryCommandIndices.set_item_metadata(i, command_section.entryCommandIndexes[i])


func _on_delete_command(index: int) -> void:
	delete_command(index)


func delete_command(index: int) -> void:
	#Console.print("Delete command: %d" % index)
	remove_from_entry_list(index)
	command_section.allCommands.pop_at(index-1)
	%AllCommandIndices.get_item_metadata(index-1).queue_free()
	%AllCommandIndices.remove_item(index-1)
	clear_entry()
	
	for conn:Dictionary in %GraphEdit.connections:
		if %GraphEdit.get_node(str(conn.from_node)).next_command_index >= index:
			%GraphEdit.disconnect_node(conn.from_node, conn.from_port, conn.to_node, conn.to_port)
	
	for i in range(index-1, %AllCommandIndices.item_count):
		%AllCommandIndices.set_item_text(i, "%d" % (i+1))
		%AllCommandIndices.get_item_metadata(i).index = i+1
	for i in range(%AllCommandIndices.item_count):
		if %AllCommandIndices.get_item_metadata(i).next_command_index == index:
			%AllCommandIndices.get_item_metadata(i).next_command_index = 0
		if %AllCommandIndices.get_item_metadata(i).next_command_index > index:
			%AllCommandIndices.get_item_metadata(i).next_command_index -= 1
	
	for i in range(len(command_section.entryCommandIndexes)):
		if command_section.entryCommandIndexes[i] > index:
			command_section.entryCommandIndexes[i] -= 1
	
	reset_entry_list()


func _on_graph_edit_popup_request(at_position: Vector2) -> void:
	add_at_position = at_position
	%GraphPopupMenu.popup(Rect2i(int(at_position.x + %GraphEdit.global_position.x), int(at_position.y + %GraphEdit.global_position.y), 0, 0))


func _on_graph_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			add_command(add_at_position)
		1:
			for child: Node in %GraphEdit.get_children():
				if child.name == "_connection_layer":
					continue
				if child.selected:
					delete_command(child.index)
					


func _on_entry_command_indices_item_clicked(_index: int, at_position: Vector2, mouse_button_index: int) -> void:
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			%EntryCommandPopupMenu.popup(Rect2i(int(at_position.x + %EntryCommandIndices.global_position.x), int(at_position.y + %EntryCommandIndices.global_position.y), 0, 0))


func _on_entry_command_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			var command_index: int = %EntryCommandIndices.get_item_metadata(%EntryCommandIndices.get_selected_items()[0])
			remove_from_entry_list(command_index)


func _on_map_name_button_pressed() -> void:
	var results: Array = await Dialog.input("Map Name:", "Enter Map Name", "", "", false)
	if not results[0]:
		return
	while len(%ArgsTree.get_root().get_children()) < 6:
		var tree_item: TreeItem = %ArgsTree.get_root().create_child()
		tree_item.set_text(0, "0")
		tree_item.set_editable(0, true)
	
	var value: int = 0
	if len(results[1]) > 0:
		value = results[1].unicode_at(0)
	if len(results[1]) > 1:
		value += (results[1].unicode_at(1) << 8)
	%ArgsTree.get_root().get_child(2).set_text(0, "%d" % value)
	
	value = 0
	if len(results[1]) > 2:
		value = results[1].unicode_at(2)
	if len(results[1]) > 3:
		value += (results[1].unicode_at(3) << 8)
	%ArgsTree.get_root().get_child(3).set_text(0, "%d" % value)
	
	value = 0
	if len(results[1]) > 4:
		value = results[1].unicode_at(4)
	if len(results[1]) > 5:
		value += (results[1].unicode_at(5) << 8)
	%ArgsTree.get_root().get_child(4).set_text(0, "%d" % value)
	
	value = 0
	if len(results[1]) > 6:
		value = results[1].unicode_at(6)
	if len(results[1]) > 7:
		value += (results[1].unicode_at(7) << 8)
	%ArgsTree.get_root().get_child(5).set_text(0, "%d" % value)
	
	update_args_array()


var previous_search: String
var search_count: int = 0

func _on_search_edit_text_submitted(new_text: String) -> void:
	if new_text.is_empty():
		return
	if new_text == previous_search:
		search_count += 1
	else:
		search_count = 0
	previous_search = new_text
	var search_amount: int = search_count
	for command_node: Control in %GraphEdit.get_children():
		if command_node.name == "_connection_layer":
			continue
		match %SearchOptions.text:
			"Floor Sector ID":
				if command_node.data.commandBase == 19 and len(command_node.data.args) >= 2 and command_node.data.args[1] == int(new_text):
					search_select(command_node)
					if search_amount == 0:
						return
					search_amount -= 1
			"LeftClick Face ID":
				if command_node.data.commandBase == 24 and len(command_node.data.args) >= 2 and command_node.data.args[1] == int(new_text):
					search_select(command_node)
					if search_amount == 0:
						return
					search_amount -= 1
			"Object ID":
				if command_node.data.commandBase == 8 and len(command_node.data.args) >= 2 and command_node.data.args[1] == int(new_text):
					search_select(command_node)
					if search_amount == 0:
						return
					search_amount -= 1
			"Arg01":
				if len(command_node.data.args) >= 1 and command_node.data.args[0] == int(new_text):
					search_select(command_node)
					if search_amount == 0:
						return
					search_amount -= 1
			"Arg02":
				if len(command_node.data.args) >= 2 and command_node.data.args[1] == int(new_text):
					search_select(command_node)
					if search_amount == 0:
						return
					search_amount -= 1
			"Arg03":
				if len(command_node.data.args) >= 3 and command_node.data.args[2] == int(new_text):
					search_select(command_node)
					if search_amount == 0:
						return
					search_amount -= 1
			"Arg04":
				if len(command_node.data.args) >= 4 and command_node.data.args[3] == int(new_text):
					search_select(command_node)
					if search_amount == 0:
						return
					search_amount -= 1
			"Arg05":
				if len(command_node.data.args) >= 5 and command_node.data.args[4] == int(new_text):
					search_select(command_node)
					if search_amount == 0:
						return
					search_amount -= 1
			"Arg06":
				if len(command_node.data.args) >= 6 and command_node.data.args[5] == int(new_text):
					search_select(command_node)
					if search_amount == 0:
						return
					search_amount -= 1
			"Arg07":
				if len(command_node.data.args) >= 7 and command_node.data.args[6] == int(new_text):
					search_select(command_node)
					if search_amount == 0:
						return
					search_amount -= 1
			"Arg08":
				if len(command_node.data.args) >= 8 and command_node.data.args[7] == int(new_text):
					search_select(command_node)
					if search_amount == 0:
						return
					search_amount -= 1
			"Command Base":
				if command_node.data.commandBase == int(new_text):
					search_select(command_node)
					if search_amount == 0:
						return
					search_amount -= 1
			"Command Modifier":
				if command_node.data.commandModifier == int(new_text):
					search_select(command_node)
					if search_amount == 0:
						return
					search_amount -= 1
			"Command Index":
				if command_node.index == int(new_text):
					if search_amount == 0:
						search_select(command_node)
						return
					search_amount -= 1
	if search_count > 0:
		search_count = 0
		previous_search = ""
		_on_search_edit_text_submitted(new_text)

func search_select(command_node: CommandNode) -> void:
	ensure_visible(command_node)
	%AllCommandIndices.select(command_node.index-1)
	%AllCommandIndices.ensure_current_is_visible()
	_on_all_command_indices_item_selected(command_node.index-1)


func _on_search_options_item_selected(_index: int) -> void:
	search_count = 0
	previous_search = ""
