extends BaseWindow

const COMMAND_NODE = preload("uid://bg2itg1120pon")
const VERTICAL_SPACING: int = 546
const HORIZONTAL_SPACING: int = 400

var map: Map
var command_section: Dictionary = {}
var command_nodes: Array = []
var row_value: int = 0
var add_at_position := Vector2.ZERO
var previous_search: String
var search_count: int = 0


func edit_data(p_map: Map) -> void:
	var p_command_section: Dictionary = p_map.commands_section
	map = p_map
	if command_section != p_command_section:
		command_section = p_command_section.duplicate(true)
		
		for child: Node in %GraphEdit.get_children():
			if child.name == "_connection_layer":
				continue
			child.queue_free()
		
		command_nodes = []
		var command_nodes_mapping := {}
		var jump_to_commands := []
		var autorun_commands := []
		
		for i in range(len(command_section.entryCommandIndexes)):
			var command_node: CommandNode = COMMAND_NODE.instantiate()
			command_node.initialize(command_section.entryCommandIndexes[i], command_section.allCommands[command_section.entryCommandIndexes[i]-1])
			
			if "node_data" in command_section.allCommands[command_section.entryCommandIndexes[i]-1]:
				command_node.position_offset.x = command_section.allCommands[command_section.entryCommandIndexes[i]-1].node_data.x
				command_node.position_offset.y = command_section.allCommands[command_section.entryCommandIndexes[i]-1].node_data.y
			else:
				command_node.position_offset.y = VERTICAL_SPACING * i
			
			row_value = i + 1
			%GraphEdit.add_child(command_node)
			command_node.title = "Entry Command"
			command_node.add_to_entry_list.connect(_on_add_to_entry_list)
			command_node.remove_from_entry_list.connect(_on_remove_from_entry_list)
			command_node.delete_command.connect(_on_delete_command)
			command_nodes_mapping[command_section.entryCommandIndexes[i]] = command_node
			
			var next_command_index: int = command_section.allCommands[command_section.entryCommandIndexes[i]-1].nextCommandIndex
			var graph_node_prev: StringName = command_node.name
			var j: int = 1
			while next_command_index != 0:
				var command_node_2: CommandNode
				if next_command_index in command_nodes_mapping:
					command_node_2 = command_nodes_mapping[next_command_index]
				else:
					command_node_2 = COMMAND_NODE.instantiate()
					command_node_2.add_to_entry_list.connect(_on_add_to_entry_list)
					command_node_2.remove_from_entry_list.connect(_on_remove_from_entry_list)
					command_node_2.delete_command.connect(_on_delete_command)
					command_node_2.initialize(next_command_index, command_section.allCommands[next_command_index-1])
					if "node_data" in command_section.allCommands[next_command_index-1]:
						command_node_2.position_offset.x = command_section.allCommands[next_command_index-1].node_data.x
						command_node_2.position_offset.y = command_section.allCommands[next_command_index-1].node_data.y
					else:
						command_node_2.position_offset.y = VERTICAL_SPACING * i
						command_node_2.position_offset.x = j * HORIZONTAL_SPACING
					%GraphEdit.add_child(command_node_2)
					
					if command_section.allCommands[next_command_index-1].commandBase == 56:
						jump_to_commands.append(command_section.allCommands[next_command_index-1].args[1])
				
				j += 1
				command_nodes_mapping[next_command_index] = command_node_2
				next_command_index = command_section.allCommands[next_command_index-1].nextCommandIndex
				%GraphEdit.connect_node(graph_node_prev, 0, command_node_2.name, 0)
				graph_node_prev = command_node_2.name
		
		var k: int = 0
		for command_index: int in jump_to_commands:
			if command_index not in command_nodes_mapping:
				var command_node: CommandNode = COMMAND_NODE.instantiate()
				command_node.initialize(command_index, command_section.allCommands[command_index-1])
				command_node.add_to_entry_list.connect(_on_add_to_entry_list)
				command_node.remove_from_entry_list.connect(_on_remove_from_entry_list)
				command_node.delete_command.connect(_on_delete_command)
				if "node_data" in command_section.allCommands[command_index-1]:
					command_node.position_offset.x = command_section.allCommands[command_index-1].node_data.x
					command_node.position_offset.y = command_section.allCommands[command_index-1].node_data.y
				else:
					command_node.position_offset.y = VERTICAL_SPACING * k
					k += 1
					command_node.position_offset.x = HORIZONTAL_SPACING * 10
				%GraphEdit.add_child(command_node)
				command_node.title = "Jump Command"
				command_nodes_mapping[command_index] = command_node
				
				
				
				var next_command_index: int = command_section.allCommands[command_index-1].nextCommandIndex
				var graph_node_prev: StringName = command_node.name
				var j: int = 1
				while next_command_index != 0:
					var command_node_2: CommandNode
					if next_command_index in command_nodes_mapping:
						command_node_2 = command_nodes_mapping[next_command_index]
					else:
						command_node_2 = COMMAND_NODE.instantiate()
						command_node_2.add_to_entry_list.connect(_on_add_to_entry_list)
						command_node_2.remove_from_entry_list.connect(_on_remove_from_entry_list)
						command_node_2.delete_command.connect(_on_delete_command)
						command_node_2.initialize(next_command_index, command_section.allCommands[next_command_index-1])
						if "node_data" in command_section.allCommands[next_command_index-1]:
							command_node_2.position_offset.x = command_section.allCommands[next_command_index-1].node_data.x
							command_node_2.position_offset.y = command_section.allCommands[next_command_index-1].node_data.y
						else:
							command_node_2.position_offset.y = VERTICAL_SPACING * (k-1)
							command_node_2.position_offset.x = (j * HORIZONTAL_SPACING) + (HORIZONTAL_SPACING * 10)
						%GraphEdit.add_child(command_node_2)
						
						if command_section.allCommands[next_command_index-1].commandBase == 56:
							jump_to_commands.append(command_section.allCommands[next_command_index-1].args[1])
					
					j += 1
					command_nodes_mapping[next_command_index] = command_node_2
					next_command_index = command_section.allCommands[next_command_index-1].nextCommandIndex
					%GraphEdit.connect_node(graph_node_prev, 0, command_node_2.name, 0)
					graph_node_prev = command_node_2.name
				
				
			else:
				command_nodes_mapping[command_index].title = "Jump Command"
		
		
		
		for i in range(len(command_section.allCommands)):
			if command_section.allCommands[i].commandBase == 61:
				autorun_commands.append(i+1)
		
		k = -1
		for command_index: int in autorun_commands:
			if command_index not in command_nodes_mapping:
				var command_node: CommandNode = COMMAND_NODE.instantiate()
				command_node.initialize(command_index, command_section.allCommands[command_index-1])
				command_node.add_to_entry_list.connect(_on_add_to_entry_list)
				command_node.remove_from_entry_list.connect(_on_remove_from_entry_list)
				command_node.delete_command.connect(_on_delete_command)
				if "node_data" in command_section.allCommands[command_index-1]:
					command_node.position_offset.x = command_section.allCommands[command_index-1].node_data.x
					command_node.position_offset.y = command_section.allCommands[command_index-1].node_data.y
				else:
					command_node.position_offset.y = VERTICAL_SPACING * k
					k += -1
					command_node.position_offset.x = 0
				%GraphEdit.add_child(command_node)
				command_node.title = "Autorun Command"
				command_nodes_mapping[command_index] = command_node
				
				
				
				var next_command_index: int = command_section.allCommands[command_index-1].nextCommandIndex
				var graph_node_prev: StringName = command_node.name
				var j: int = 1
				while next_command_index != 0:
					var command_node_2: CommandNode
					if next_command_index in command_nodes_mapping:
						command_node_2 = command_nodes_mapping[next_command_index]
					else:
						command_node_2 = COMMAND_NODE.instantiate()
						command_node_2.add_to_entry_list.connect(_on_add_to_entry_list)
						command_node_2.remove_from_entry_list.connect(_on_remove_from_entry_list)
						command_node_2.delete_command.connect(_on_delete_command)
						command_node_2.initialize(next_command_index, command_section.allCommands[next_command_index-1])
						if "node_data" in command_section.allCommands[next_command_index-1]:
							command_node_2.position_offset.x = command_section.allCommands[next_command_index-1].node_data.x
							command_node_2.position_offset.y = command_section.allCommands[next_command_index-1].node_data.y
						else:
							command_node_2.position_offset.y = VERTICAL_SPACING * (k+1)
							command_node_2.position_offset.x = (j * HORIZONTAL_SPACING)
						%GraphEdit.add_child(command_node_2)
						
						if command_section.allCommands[next_command_index-1].commandBase == 56:
							jump_to_commands.append(command_section.allCommands[next_command_index-1].args[1])
					
					j += 1
					command_nodes_mapping[next_command_index] = command_node_2
					next_command_index = command_section.allCommands[next_command_index-1].nextCommandIndex
					%GraphEdit.connect_node(graph_node_prev, 0, command_node_2.name, 0)
					graph_node_prev = command_node_2.name
				
				
				
				
			else:
				command_nodes_mapping[command_index].title = "Autorun Command"
		
		
		k = 0
		var repeat := []
		for i in range(len(command_section.allCommands)):
			if i + 1 not in command_nodes_mapping:
				var command_node: CommandNode = COMMAND_NODE.instantiate()
				command_node.initialize(i+1, command_section.allCommands[i])
				command_node.add_to_entry_list.connect(_on_add_to_entry_list)
				command_node.remove_from_entry_list.connect(_on_remove_from_entry_list)
				command_node.delete_command.connect(_on_delete_command)
				if "node_data" in command_section.allCommands[i]:
					command_node.position_offset.x = command_section.allCommands[i].node_data.x
					command_node.position_offset.y = command_section.allCommands[i].node_data.y
				else:
					command_node.position_offset.y = VERTICAL_SPACING * k
					k += 1
					command_node.position_offset.x = -600
				%GraphEdit.add_child(command_node)
				command_node.title = "Orphan Command"
				command_nodes_mapping[i+1] = command_node
				repeat.append(command_node)
		
		
		for command_node: CommandNode in repeat:
			if command_node.data.nextCommandIndex != 0:
				%GraphEdit.connect_node(command_node.name, 0, command_nodes_mapping[command_node.data.nextCommandIndex].name, 0)
				if command_nodes_mapping[command_node.data.nextCommandIndex].title == "Orphan Command":
					command_nodes_mapping[command_node.data.nextCommandIndex].title = "Command"
		
		
		command_nodes_mapping.sort()
		for key: int in command_nodes_mapping:
			command_nodes.append(command_nodes_mapping[key])
	
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


func ensure_visible(command_node: GraphNode) -> void:
	%GraphEdit.scroll_offset = command_node.position_offset * %GraphEdit.zoom
	%GraphEdit.scroll_offset.x -= (%GraphEdit.size.x / 2) - (command_node.size.x / 2) * %GraphEdit.zoom
	%GraphEdit.scroll_offset.y -= (%GraphEdit.size.y / 2) - (command_node.size.y / 2) * %GraphEdit.zoom
	%GraphEdit.set_selected(command_node)


func _on_graph_edit_connection_request(from_node: StringName, from_port: int, to_node: StringName, _to_port: int) -> void:
	# Only allow one connection out
	for conn: Dictionary in %GraphEdit.connections:
		if conn.from_node == from_node and conn.from_port == from_port:
			return
	
	%GraphEdit.get_node(str(from_node)).next_command_index = %GraphEdit.get_node(str(to_node)).index
	
	if %GraphEdit.get_node(str(to_node)).title == "Orphan Command":
		%GraphEdit.get_node(str(to_node)).title = "Command"


func _on_graph_edit_disconnection_request(from_node: StringName, _from_port: int, to_node: StringName, _to_port: int) -> void:
	%GraphEdit.get_node(str(from_node)).next_command_index = 0
	
	var another_connection: bool = false
	for conn: Dictionary in %GraphEdit.connections:
		if conn.to_node == to_node:
			another_connection = true
	
	if (not another_connection and
			%GraphEdit.get_node(str(to_node)).title == "Command"
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
	
	var new_index: int = len(command_nodes) + 1
	
	var command_node: CommandNode = COMMAND_NODE.instantiate()
	command_node.initialize(new_index, new_command)
	if at_position:
		var pos:Vector2 = (at_position + %GraphEdit.scroll_offset) / %GraphEdit.zoom
		command_node.position_offset = pos
	else:
		command_node.position_offset.y = VERTICAL_SPACING * row_value
		row_value += 1
	%GraphEdit.add_child(command_node)
	command_node.title = "Orphan Command"
	command_node.add_to_entry_list.connect(_on_add_to_entry_list)
	command_node.remove_from_entry_list.connect(_on_remove_from_entry_list)
	command_node.delete_command.connect(_on_delete_command)
	
	command_section.allCommands.append(new_command)
	command_nodes.append(command_node)


func _on_add_to_entry_list(index: int) -> void:
	add_to_entry_list(index)


func add_to_entry_list(index: int) -> void:
	command_section.entryCommandIndexes.append(index)
	
	# Entry commands need to be sorted first by command base and then by index
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
	
	command_nodes[index-1].title = "Entry Command"


func _on_remove_from_entry_list(index: int) -> void:
	remove_from_entry_list(index)


func remove_from_entry_list(index: int) -> void:
	if not index in command_section.entryCommandIndexes:
		return
	command_section.entryCommandIndexes.erase(index)
	
	var has_to: bool = false
	for conn: Dictionary in %GraphEdit.connections:
		if conn.to_node == command_nodes[index-1].name:
			has_to = true
	
	if has_to == false:
		command_nodes[index-1].title = "Orphan Command"
	else:
		command_nodes[index-1].title = "Command"


func _on_delete_command(index: int) -> void:
	delete_command(index)


func delete_command(index: int) -> void:
	# Remove command
	remove_from_entry_list(index)
	command_section.allCommands.pop_at(index-1)
	
	# Check for a connection
	var has_connection: bool = false
	var to_node: StringName
	var from_node: StringName = command_nodes[index-1].name
	for conn: Dictionary in %GraphEdit.connections:
		if conn.from_node == from_node:
			has_connection = true
			to_node = conn.to_node
			break
	
	# Remove command node
	command_nodes[index-1].queue_free()
	command_nodes.pop_at(index-1)
	
	# Update later commands with new indexes
	for i in range(index-1, len(command_nodes)):
		command_nodes[i].index = i + 1
	
	# Update references to commands
	for command_node: CommandNode in command_nodes:
		# Update next_command_index
		if command_node.next_command_index == index:
			command_node.next_command_index = 0
		if command_node.next_command_index > index:
			command_node.next_command_index -= 1
		
		# Update arg1
		if command_node.command_base in [64]:
			if command_node.arg_1 == index:
				command_node.arg_1 = 0
			if command_node.arg_1 > index:
				command_node.arg_1 -= 1
		
		# Update arg2
		if command_node.command_base in [23, 30, 56]:
			if command_node.arg_2 == index:
				command_node.arg_2 = 0
			if command_node.arg_2 > index:
				command_node.arg_2 -= 1
	
	# Update entry commands with new indexes
	for i in range(len(command_section.entryCommandIndexes)):
		if command_section.entryCommandIndexes[i] > index:
			command_section.entryCommandIndexes[i] -= 1
	
	# Check if connected node has any other connections and change title accordingly
	if has_connection:
		var another_connection: bool = false
		for conn: Dictionary in %GraphEdit.connections:
			if conn.to_node == to_node and conn.from_node != from_node:
				another_connection = true
				break
		if (not another_connection and
				%GraphEdit.get_node(str(to_node)).title == "Command"
		):
			%GraphEdit.get_node(str(to_node)).title = "Orphan Command"


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
					ensure_visible(command_node)
					if search_amount == 0:
						return
					search_amount -= 1
			"LeftClick Face ID":
				if command_node.data.commandBase == 24 and len(command_node.data.args) >= 2 and command_node.data.args[1] == int(new_text):
					ensure_visible(command_node)
					if search_amount == 0:
						return
					search_amount -= 1
			"Object ID":
				if command_node.data.commandBase == 8 and len(command_node.data.args) >= 2 and command_node.data.args[1] == int(new_text):
					ensure_visible(command_node)
					if search_amount == 0:
						return
					search_amount -= 1
			"Arg01":
				if len(command_node.data.args) >= 1 and command_node.data.args[0] == int(new_text):
					ensure_visible(command_node)
					if search_amount == 0:
						return
					search_amount -= 1
			"Arg02":
				if len(command_node.data.args) >= 2 and command_node.data.args[1] == int(new_text):
					ensure_visible(command_node)
					if search_amount == 0:
						return
					search_amount -= 1
			"Arg03":
				if len(command_node.data.args) >= 3 and command_node.data.args[2] == int(new_text):
					ensure_visible(command_node)
					if search_amount == 0:
						return
					search_amount -= 1
			"Arg04":
				if len(command_node.data.args) >= 4 and command_node.data.args[3] == int(new_text):
					ensure_visible(command_node)
					if search_amount == 0:
						return
					search_amount -= 1
			"Arg05":
				if len(command_node.data.args) >= 5 and command_node.data.args[4] == int(new_text):
					ensure_visible(command_node)
					if search_amount == 0:
						return
					search_amount -= 1
			"Arg06":
				if len(command_node.data.args) >= 6 and command_node.data.args[5] == int(new_text):
					ensure_visible(command_node)
					if search_amount == 0:
						return
					search_amount -= 1
			"Arg07":
				if len(command_node.data.args) >= 7 and command_node.data.args[6] == int(new_text):
					ensure_visible(command_node)
					if search_amount == 0:
						return
					search_amount -= 1
			"Arg08":
				if len(command_node.data.args) >= 8 and command_node.data.args[7] == int(new_text):
					ensure_visible(command_node)
					if search_amount == 0:
						return
					search_amount -= 1
			"Command Base":
				if command_node.data.commandBase == int(new_text):
					ensure_visible(command_node)
					if search_amount == 0:
						return
					search_amount -= 1
			"Command Modifier":
				if command_node.data.commandModifier == int(new_text):
					ensure_visible(command_node)
					if search_amount == 0:
						return
					search_amount -= 1
			"Command Index":
				if command_node.index == int(new_text):
					if search_amount == 0:
						ensure_visible(command_node)
						return
					search_amount -= 1
	if search_count > 0:
		search_count = 0
		previous_search = ""
		_on_search_edit_text_submitted(new_text)


func _on_search_options_item_selected(_index: int) -> void:
	search_count = 0
	previous_search = ""
