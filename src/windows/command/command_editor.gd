extends Control

signal command_editor_loading_finished

const COMMAND_NODE = preload("uid://bg2itg1120pon")
const VERTICAL_SPACING: int = 540
const HORIZONTAL_SPACING: int = 420

var map: Map
var command_section: Dictionary = {}
var command_nodes: Array = []
var add_at_position := Vector2.ZERO
var previous_search: String
var search_count: int = 0
var graph_edit: GraphEdit
var _is_loading: bool = false
var copy_commands: Array = []
var apply_offset := Vector2.ZERO

# Threaded loading of the command editor would be ideal so the program wouldn't become unresponsive
# while loading. However unfortunately, it ends up taking significantly longer to load on a thread.
# It's unclear if this is a problem with Godot or my usage of threads.
# In my testing of STUDY1 which has maybe the largest command section,
# the unthreaded load takes about 6.5 seconds, while the threaded load takes a whopping 50 seconds,
# the last 4.5 seconds of which still make the program unresponsive. For these reasons I'll stick
# with the unthreaded loading for now.
func load_command_editor_threaded(p_map: Map) -> void:
	if _is_loading:
		return
	_is_loading = true
	%ProgressBar.show()
	%ProgressBar.value = 0.0
	%MapLabel.text = p_map.map_info.name
	map = p_map
	if not map.name_changed.is_connected(_on_map_name_changed):
		map.name_changed.connect(_on_map_name_changed)
	if command_section != p_map.commands_section:
		command_section = p_map.commands_section
		if graph_edit:
			graph_edit.queue_free()
			await graph_edit.tree_exited
		var thread := Thread.new()
		var _err: Error = thread.start(init_graph_edit)
		await command_editor_loading_finished
		if graph_edit and not graph_edit.is_inside_tree():
			%Graph.add_child(graph_edit)
		thread.wait_to_finish()
	_is_loading = false
	%ProgressBar.hide()


func load_command_editor(p_map: Map, p_reset_camera: bool = true) -> void:
	%MapLabel.text = p_map.map_info.name
	%CloseButton.show()
	map = p_map
	var default_zoom: float = 0.5
	apply_offset = Vector2(-5, -5)
	if not map.name_changed.is_connected(_on_map_name_changed):
		map.name_changed.connect(_on_map_name_changed)
	if not is_same(command_section, p_map.commands_section):
		command_section = p_map.commands_section
		if graph_edit:
			if not p_reset_camera:
				default_zoom = graph_edit.zoom
				apply_offset = graph_edit.scroll_offset
			graph_edit.queue_free()
			await graph_edit.tree_exited
		init_graph_edit()
		
		# There's a severe issue with applying scroll offsets. The graph_edit needs to be visible for
		# a couple frames before it will correctly apply. This is my hacky work-around
		graph_edit.visibility_changed.connect(func () -> void:
			if graph_edit.is_visible_in_tree():
				if not apply_offset.is_zero_approx():
					await get_tree().process_frame
					graph_edit.scroll_offset = apply_offset
					apply_offset = Vector2.ZERO
		)
		
		if graph_edit and not graph_edit.is_inside_tree():
			%Graph.add_child.call_deferred(graph_edit)
			# BUGFIX: The next three lines work around a graphical bug related to the connection lines
			await graph_edit.ready
			graph_edit.zoom = default_zoom
			graph_edit.scroll_offset = apply_offset


func _loading_update(percentage: float) -> void:
	%ProgressBar.value = percentage * 100


func _on_map_name_changed(new_map_name: String) -> void:
	%MapLabel.text = new_map_name


func close(p_map_name: String) -> void:
	if map:
		if p_map_name == map.map_info.name:
			if graph_edit:
				graph_edit.queue_free()
				graph_edit = null
			command_section = {}
			_is_loading = false
			%MapLabel.text = "No Commands Loaded"
			if map.name_changed.is_connected(_on_map_name_changed):
				map.name_changed.disconnect(_on_map_name_changed)
			map = null
			%CloseButton.hide()


func init_graph_edit() -> void:
	# Setup a new GraphEdit
	graph_edit = GraphEdit.new()
	graph_edit.connection_request.connect(_on_graph_edit_connection_request)
	graph_edit.disconnection_request.connect(_on_graph_edit_disconnection_request)
	graph_edit.end_node_move.connect(_on_graph_edit_end_node_move)
	graph_edit.popup_request.connect(_on_graph_edit_popup_request)
	graph_edit.scroll_offset = Vector2(-5, -5)
	graph_edit.right_disconnects = true
	#graph_edit.zoom = 0.5
	graph_edit.zoom = 1
	graph_edit.zoom_min = 0.01
	graph_edit.show_menu = false
	#graph_edit.show_grid = false
	
	# Initialize variables
	command_nodes = []
	var command_nodes_mapping := {}
	var referenced_commands := []
	var autorun_commands := []
	var row_value: int = 0
	var loading_count: float = 0.0
	
	# Commands that don't need entry
	# -- These with autorun modifier 1 --
	# Change Floor/Ceiling Height: 7
	# Move Sector: 9
	# Scroll Sector: 14
	# Scroll Face: 15
	# Flash Lights: 17
	# Face Emits Damage: 53
	# Autorun Timer: 61
	# -- And the following --
	# False Jump to commands, linked from Command: 56 arg2
	# Run Commands, linked from Command: 64 arg1
	# And I suppose the enable Commands from command: 23 arg2
	
	
	
	# Initialize entry command chains
	for i in range(len(command_section.entryCommandIndexes)):
		
		# Skip any command that has already been initialized
		if command_section.entryCommandIndexes[i] in command_nodes_mapping:
			continue
		
		# Initialize command node and add to mapping
		command_nodes_mapping[command_section.entryCommandIndexes[i]] = initialize_command_node(command_section.entryCommandIndexes[i], command_section.allCommands[command_section.entryCommandIndexes[i]-1], Vector2(0, VERTICAL_SPACING * row_value))
		
		# Update loading progress bar
		loading_count += 1
		_loading_update.call_deferred(loading_count / len(command_section.allCommands))
		
		# Initialize loop variables
		var next_command_index: int = command_section.allCommands[command_section.entryCommandIndexes[i]-1].nextCommandIndex
		var graph_node_prev: StringName = command_nodes_mapping[command_section.entryCommandIndexes[i]].name
		var j: int = 1
		
		# Cycle through the rest of the command chain
		while next_command_index != 0:
			if next_command_index not in command_nodes_mapping:
				# Initialize and add to mapping
				command_nodes_mapping[next_command_index] = initialize_command_node(next_command_index, command_section.allCommands[next_command_index-1], Vector2(HORIZONTAL_SPACING * j, VERTICAL_SPACING * row_value))
				
				# Update progress bar
				loading_count += 1
				_loading_update.call_deferred(loading_count / len(command_section.allCommands))
				
				# Keep track of the referenced commands for the types (23, 51, 56, 64[arg1])
				if (command_section.allCommands[next_command_index-1].commandBase == 23
					or command_section.allCommands[next_command_index-1].commandBase == 56
				):
					if command_section.allCommands[next_command_index-1].args[1] not in referenced_commands:
						referenced_commands.append(command_section.allCommands[next_command_index-1].args[1])
				if command_section.allCommands[next_command_index-1].commandBase == 64:
					if command_section.allCommands[next_command_index-1].args[0] not in referenced_commands:
						referenced_commands.append(command_section.allCommands[next_command_index-1].args[0])
			
			# Connect previous node to this node
			graph_edit.connect_node(graph_node_prev, 0, command_nodes_mapping[next_command_index].name, 0)
			
			# Update loop variables
			graph_node_prev = command_nodes_mapping[next_command_index].name
			next_command_index = command_section.allCommands[next_command_index-1].nextCommandIndex
			j += 1
		
		# New row
		row_value += 1
	
	
	# Autorun commands
	
	# This additional loop looks for any autorun command
	# Known types 7, 9, 14, 15, 17, and 53
	# Potentially any that have autorun modifier bit set
	# Also 61 which is autorun even without autorun bit set
	for i in range(len(command_section.allCommands)):
		if (i+1 not in command_nodes_mapping
			and i+1 not in autorun_commands
		):
			if ((command_section.allCommands[i].commandModifier & 1) > 0
				or command_section.allCommands[i].commandBase == 61
			):
				autorun_commands.append(i+1)
	
	# Initialize autorun command chains
	row_value = -1
	for command_index: int in autorun_commands:
		
		# Skip any command that has already been initialized
		if command_index in command_nodes_mapping:
			continue
		
		# Initialize and add to mapping
		command_nodes_mapping[command_index] = initialize_command_node(command_index, command_section.allCommands[command_index-1], Vector2(0, VERTICAL_SPACING * row_value))
		
		# Update loading progress bar
		loading_count += 1
		_loading_update.call_deferred(loading_count / len(command_section.allCommands))
		
		# Initialize loop variables
		var next_command_index: int = command_section.allCommands[command_index-1].nextCommandIndex
		var graph_node_prev: StringName = command_nodes_mapping[command_index].name
		var j: int = 1
		
		# Cycle through the rest of the command chain
		while next_command_index != 0:
			if not next_command_index in command_nodes_mapping:
				# Initialize and add to mapping
				command_nodes_mapping[next_command_index] = initialize_command_node(next_command_index, command_section.allCommands[next_command_index-1], Vector2(HORIZONTAL_SPACING * j, VERTICAL_SPACING * row_value))
				
				# Update progress bar
				loading_count += 1
				_loading_update.call_deferred(loading_count / len(command_section.allCommands))
			
				# Keep track of the referenced commands for the types (23, 51, 56, 64[arg1])
				if (command_section.allCommands[next_command_index-1].commandBase == 23
					or command_section.allCommands[next_command_index-1].commandBase == 56
				):
					if command_section.allCommands[next_command_index-1].args[1] not in referenced_commands:
						referenced_commands.append(command_section.allCommands[next_command_index-1].args[1])
				if command_section.allCommands[next_command_index-1].commandBase == 64:
					if command_section.allCommands[next_command_index-1].args[0] not in referenced_commands:
						referenced_commands.append(command_section.allCommands[next_command_index-1].args[0])
			
			# Connect previous node to this node
			graph_edit.connect_node(graph_node_prev, 0, command_nodes_mapping[next_command_index].name, 0)
			
			# Update loop variables
			graph_node_prev = command_nodes_mapping[next_command_index].name
			next_command_index = command_section.allCommands[next_command_index-1].nextCommandIndex
			j += 1
		
		# New row
		row_value += -1
	
	
	# Initialize referenced commands chains
	row_value = 0
	for command_index: int in referenced_commands:
		
		# Skip any command that has already been initialized
		if command_index in command_nodes_mapping:
			continue
		
		# Initialize and add to mapping
		command_nodes_mapping[command_index] = initialize_command_node(command_index, command_section.allCommands[command_index-1], Vector2(HORIZONTAL_SPACING * 10, VERTICAL_SPACING * row_value))
		
		# Update loading progress bar
		loading_count += 1
		_loading_update.call_deferred(loading_count / len(command_section.allCommands))
		
		# Initialize loop variables
		var next_command_index: int = command_section.allCommands[command_index-1].nextCommandIndex
		var graph_node_prev: StringName = command_nodes_mapping[command_index].name
		var j: int = 1
		
		# Cycle through the rest of the command chain
		while next_command_index != 0:
			if next_command_index not in command_nodes_mapping:
				# Initialize and add to mapping
				command_nodes_mapping[next_command_index] = initialize_command_node(next_command_index, command_section.allCommands[next_command_index-1], Vector2((HORIZONTAL_SPACING * 10) + (HORIZONTAL_SPACING * j), VERTICAL_SPACING * row_value))
				
				# Update progress bar
				loading_count += 1
				_loading_update.call_deferred(loading_count / len(command_section.allCommands))
				
				# TODO: What about references from referenced commands?
			
			# Connect previous node to this node
			graph_edit.connect_node(graph_node_prev, 0, command_nodes_mapping[next_command_index].name, 0)
			
			# Update loop variables
			graph_node_prev = command_nodes_mapping[next_command_index].name
			next_command_index = command_section.allCommands[next_command_index-1].nextCommandIndex
			j += 1
		
		# New row
		row_value += 1
	
	
	# Final loop looking for any leftovers
	row_value = 0
	var repeat := []
	for i in range(len(command_section.allCommands)):
		if i + 1 not in command_nodes_mapping:
			# Initialize and add to mapping
			command_nodes_mapping[i+1] = initialize_command_node(i+1, command_section.allCommands[i], Vector2(HORIZONTAL_SPACING * -5, VERTICAL_SPACING * row_value))
			
			# Update progress bar
			loading_count += 1
			_loading_update.call_deferred(loading_count / len(command_section.allCommands))
			
			# Append to repeat array
			repeat.append(command_nodes_mapping[i+1])
			
			# New row
			row_value += 1
	
	# A final-final loop through the leftovers to make any connections
	for command_node: CommandNode in repeat:
		if command_node.data.nextCommandIndex != 0:
			graph_edit.connect_node(command_node.name, 0, command_nodes_mapping[command_node.data.nextCommandIndex].name, 0)
	
	
	# Sort the node mapping and convert to array
	command_nodes_mapping.sort()
	for key: int in command_nodes_mapping:
		command_nodes.append(command_nodes_mapping[key])
	
	# Finished initializing graph edit
	command_editor_loading_finished.emit.call_deferred()



func initialize_command_node(p_index: int, p_command_data: Dictionary, p_position: Vector2) -> CommandNode:
	# Init command node
	var command_node: CommandNode = COMMAND_NODE.instantiate()
	command_node.initialize(p_index, p_command_data)
	
	# Load position data
	#if "node_data" in p_command_data:
	if "command_positions" in map.map_info and str(p_index) in map.map_info.command_positions:
		command_node.position_offset.x = map.map_info.command_positions[str(p_index)].x
		command_node.position_offset.y = map.map_info.command_positions[str(p_index)].y
	else:
		command_node.position_offset = p_position
	
	# Setup signals
	command_node.add_to_entry_list.connect(_on_add_to_entry_list)
	command_node.remove_from_entry_list.connect(_on_remove_from_entry_list)
	command_node.delete_command.connect(_on_delete_command)
	command_node.copy_command.connect(_on_copy_command)
	
	# Add to graph
	graph_edit.add_child(command_node)
	
	# Return Node
	return command_node


func save_positions() -> void:
	var positions: Dictionary = {}
	for command_node: Control in graph_edit.get_children():
		if command_node.name == "_connection_layer":
			continue
		#command_node.save_position()
		positions[str(command_node.index)] = {
			"x": command_node.position_offset.x,
			"y": command_node.position_offset.y,
		}
	
	map.map_info["command_positions"] = positions


func ensure_visible(command_node: GraphNode) -> void:
	graph_edit.scroll_offset = command_node.position_offset * graph_edit.zoom
	graph_edit.scroll_offset.x -= (graph_edit.size.x / 2) - (command_node.size.x / 2) * graph_edit.zoom
	graph_edit.scroll_offset.y -= (graph_edit.size.y / 2) - (command_node.size.y / 2) * graph_edit.zoom
	graph_edit.set_selected(command_node)


func _on_graph_edit_connection_request(from_node: StringName, from_port: int, to_node: StringName, _to_port: int) -> void:
	# Only allow one connection out
	for conn: Dictionary in graph_edit.connections:
		if conn.from_node == from_node and conn.from_port == from_port:
			return
	
	graph_edit.get_node(str(from_node)).next_command_index = graph_edit.get_node(str(to_node)).index
	
	#if graph_edit.get_node(str(to_node)).title == "Orphan Command":
		#graph_edit.get_node(str(to_node)).title = "Command"


func _on_graph_edit_disconnection_request(from_node: StringName, _from_port: int, _to_node: StringName, _to_port: int) -> void:
	graph_edit.get_node(str(from_node)).next_command_index = 0
	
	#var another_connection: bool = false
	#for conn: Dictionary in graph_edit.connections:
		#if conn.to_node == to_node:
			#another_connection = true
	#
	#if (not another_connection and
			#graph_edit.get_node(str(to_node)).title == "Command"
	#):
		#graph_edit.get_node(str(to_node)).title = "Orphan Command"


func add_command(at_position: Vector2, p_command: Dictionary = {}) -> CommandNode:
	var new_index: int = len(command_nodes) + 1
	
	var new_command := {
		"commandBase": 1,
		"commandModifier": 0,
		"nextCommandIndex": 0,
		"args": [0],
		"map_info": map.map_info,
		"index": new_index,
	}
	
	if not p_command.is_empty():
		new_command = p_command
		new_command["map_info"] = map.map_info
		new_command["index"] = new_index
	
	var command_node: CommandNode = COMMAND_NODE.instantiate()
	command_node.initialize(new_index, new_command)
	
	#var pos:Vector2 = (at_position + graph_edit.scroll_offset) / graph_edit.zoom
	command_node.position_offset = at_position
	
	graph_edit.add_child(command_node)
	#command_node.title = "Orphan Command"
	command_node.add_to_entry_list.connect(_on_add_to_entry_list)
	command_node.remove_from_entry_list.connect(_on_remove_from_entry_list)
	command_node.delete_command.connect(_on_delete_command)
	command_node.copy_command.connect(_on_copy_command)
	
	command_section.allCommands.append(new_command)
	command_nodes.append(command_node)
	
	save_positions()
	
	return command_node


func paste_commands(p_starting_position: Vector2) -> void:
	for child: Node in graph_edit.get_children():
		if child.name == "_connection_layer":
			continue
		child.selected = false
	
	var added_nodes: Array = []
	for command: Dictionary in copy_commands:
		added_nodes.append(add_command(p_starting_position+command.position, command.duplicate(true)))
	for command_node: CommandNode in added_nodes:
		if command_node.data.copy_next_command_index >= 0:
			command_node.next_command_index = command_node.data.copy_next_command_index + added_nodes[0].index
		command_node.selected = true
		if command_node.data.add_to_entry:
			add_to_entry_list(command_node.index)
			command_node.update_command_base()


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
	
	#command_nodes[index-1].title = "Entry Command"


func _on_remove_from_entry_list(index: int) -> void:
	remove_from_entry_list(index)


func remove_from_entry_list(index: int) -> void:
	if not index in command_section.entryCommandIndexes:
		return
	command_section.entryCommandIndexes.erase(index)
	
	#var has_to: bool = false
	#for conn: Dictionary in graph_edit.connections:
		#if conn.to_node == command_nodes[index-1].name:
			#has_to = true
	#
	#if has_to == false:
		#command_nodes[index-1].title = "Orphan Command"
	#else:
		#command_nodes[index-1].title = "Command"


func _on_copy_command(index: int) -> void:
	copy_commands = []
	var origin := Vector2.ZERO
	for child: Node in graph_edit.get_children():
		if child.name == "_connection_layer":
			continue
		if child.selected:
			var copy_data: Dictionary = child.data.duplicate(true)
			copy_data.erase("map_info")
			copy_data.position = child.position_offset
			copy_commands.append(copy_data)
			if copy_data.index == index:
				origin = copy_data.position
			if copy_data.index in command_section.entryCommandIndexes:
				copy_data.add_to_entry = true
			else:
				copy_data.add_to_entry = false
	
	for command: Dictionary in copy_commands:
		command.copy_next_command_index = copy_commands.map(func(c: Dictionary) -> int: return c.index).find(command.nextCommandIndex)
		if command.copy_next_command_index == -1:
			command.nextCommandIndex = 0
		command.position -= origin
	
	#print(JSON.stringify(copy_commands, '\t'))


func _on_delete_command(index: int) -> void:
	var to_delete: Array = []
	for child: Node in graph_edit.get_children():
		if child.name == "_connection_layer":
			continue
		if child.selected:
			to_delete.append(child)
	
	if not await Dialog.confirm("Delete %d commands?" % len(to_delete), "Confirm Deletion?", false, Vector2(400,150)):
		return
	
	for child: Node in to_delete:
		delete_command(child.index)
	#delete_command(index)


func delete_command(index: int) -> void:
	# Remove command
	remove_from_entry_list(index)
	command_section.allCommands.pop_at(index-1)
	
	# Check for a connection
	#var has_connection: bool = false
	#var to_node: StringName
	#var from_node: StringName = command_nodes[index-1].name
	#for conn: Dictionary in graph_edit.connections:
		#if conn.from_node == from_node:
			#has_connection = true
			#to_node = conn.to_node
			#break
	
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
	#if has_connection:
		#var another_connection: bool = false
		#for conn: Dictionary in graph_edit.connections:
			#if conn.to_node == to_node and conn.from_node != from_node:
				#another_connection = true
				#break
		#if (not another_connection and
				#graph_edit.get_node(str(to_node)).title == "Command"
		#):
			#graph_edit.get_node(str(to_node)).title = "Orphan Command"
	
	# Force minimap refresh
	await get_tree().process_frame
	graph_edit.minimap_enabled = false
	graph_edit.minimap_enabled = true
	save_positions()


func _on_graph_edit_popup_request(at_position: Vector2) -> void:
	if copy_commands.is_empty():
		%GraphPopupMenu.set_item_disabled(1, true)
	else:
		%GraphPopupMenu.set_item_disabled(1, false)
	add_at_position = (at_position + graph_edit.scroll_offset) / graph_edit.zoom
	%GraphPopupMenu.popup(Rect2i(int(at_position.x + graph_edit.global_position.x), int(at_position.y + graph_edit.global_position.y), 0, 0))


func _on_graph_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			add_command(add_at_position)
		1:
			paste_commands(add_at_position)


func _on_search_edit_text_submitted(new_text: String) -> void:
	if new_text.is_empty():
		return
	if new_text == previous_search:
		search_count += 1
	else:
		search_count = 0
	previous_search = new_text
	var search_amount: int = search_count
	for command_node: Control in graph_edit.get_children():
		if command_node.name == "_connection_layer":
			continue
		match %SearchOptions.text:
			"Sector ID":
				if (
						(command_node.data.commandBase == 2 and command_node.data.args[2] == int(new_text))
						or (command_node.data.commandBase == 3 and command_node.data.args[1] == int(new_text))
						or (command_node.data.commandBase == 7 and command_node.data.args[1] == int(new_text))
						or (command_node.data.commandBase == 9 and command_node.data.args[1] == int(new_text))
						or (command_node.data.commandBase == 10 and command_node.data.args[1] == int(new_text))
						or (command_node.data.commandBase == 14 and (command_node.data.args[1]>>8) == int(new_text))
						or (command_node.data.commandBase == 17 and (command_node.data.args[1]) == int(new_text))
						or (command_node.data.commandBase == 19 and command_node.data.args[1] == int(new_text))
						or (command_node.data.commandBase == 25 and command_node.data.args[1] == int(new_text))
						or (command_node.data.commandBase == 28 and command_node.data.args[1] == int(new_text))
						or (command_node.data.commandBase == 29 and command_node.data.args[1] == int(new_text))
						or (command_node.data.commandBase == 49 and command_node.data.args[1] == int(new_text))
						or (command_node.data.commandBase == 59 and command_node.data.args[1] == int(new_text) and command_node.data.args[2] == 0 and command_node.data.args[3] == 0 and command_node.data.args[4] == 0 and command_node.data.args[5] == 0)
				):
					if search_amount == 0:
						ensure_visible(command_node)
						return
					search_amount -= 1
			"Face ID":
				if (
						command_node.data.commandBase == 12 and command_node.data.args[1] == int(new_text)
						or command_node.data.commandBase == 15 and (command_node.data.args[1]>>8) == int(new_text)
						or command_node.data.commandBase == 24 and command_node.data.args[1] == int(new_text)
						or command_node.data.commandBase == 26 and command_node.data.args[1] == int(new_text)
						or command_node.data.commandBase == 31 and command_node.data.args[4] == int(new_text)
						or command_node.data.commandBase == 46 and command_node.data.args[1] == int(new_text)
						or command_node.data.commandBase == 47 and command_node.data.args[1] == int(new_text)
						or command_node.data.commandBase == 50 and command_node.data.args[1] == int(new_text)
						or command_node.data.commandBase == 52 and command_node.data.args[1] == int(new_text)
						or command_node.data.commandBase == 53 and command_node.data.args[1] == int(new_text)
				):
					if search_amount == 0:
						ensure_visible(command_node)
						return
					search_amount -= 1
			"Object ID":
				if (
						command_node.data.commandBase == 2 and command_node.data.args[1] == int(new_text)
						or command_node.data.commandBase == 8 and command_node.data.args[1] == int(new_text)
						or command_node.data.commandBase == 13 and command_node.data.args[1] == int(new_text)
						or command_node.data.commandBase == 22 and command_node.data.args[1] == int(new_text)
						or command_node.data.commandBase == 27 and command_node.data.args[1] == int(new_text)
						or command_node.data.commandBase == 32 and command_node.data.args[1] == int(new_text)
						or command_node.data.commandBase == 32 and command_node.data.args[2] == int(new_text)
						or command_node.data.commandBase == 35 and command_node.data.args[1] == int(new_text)
						or command_node.data.commandBase == 36 and command_node.data.args[1] == int(new_text)
						or command_node.data.commandBase == 48 and command_node.data.args[1] == int(new_text)
						or command_node.data.commandBase == 57 and command_node.data.args[1] == int(new_text)
						or command_node.data.commandBase == 58 and command_node.data.args[0] == int(new_text)
						or command_node.data.commandBase == 60 and command_node.data.args[1] == int(new_text)
						or command_node.data.commandBase == 60 and command_node.data.args[3] == int(new_text)
				):
					if search_amount == 0:
						ensure_visible(command_node)
						return
					search_amount -= 1
			"Arg01":
				if len(command_node.data.args) >= 1 and command_node.data.args[0] == int(new_text):
					if search_amount == 0:
						ensure_visible(command_node)
						return
					search_amount -= 1
			"Arg02":
				if len(command_node.data.args) >= 2 and command_node.data.args[1] == int(new_text):
					if search_amount == 0:
						ensure_visible(command_node)
						return
					search_amount -= 1
			"Arg03":
				if len(command_node.data.args) >= 3 and command_node.data.args[2] == int(new_text):
					if search_amount == 0:
						ensure_visible(command_node)
						return
					search_amount -= 1
			"Arg04":
				if len(command_node.data.args) >= 4 and command_node.data.args[3] == int(new_text):
					if search_amount == 0:
						ensure_visible(command_node)
						return
					search_amount -= 1
			"Arg05":
				if len(command_node.data.args) >= 5 and command_node.data.args[4] == int(new_text):
					if search_amount == 0:
						ensure_visible(command_node)
						return
					search_amount -= 1
			"Arg06":
				if len(command_node.data.args) >= 6 and command_node.data.args[5] == int(new_text):
					if search_amount == 0:
						ensure_visible(command_node)
						return
					search_amount -= 1
			"Arg07":
				if len(command_node.data.args) >= 7 and command_node.data.args[6] == int(new_text):
					if search_amount == 0:
						ensure_visible(command_node)
						return
					search_amount -= 1
			"Arg08":
				if len(command_node.data.args) >= 8 and command_node.data.args[7] == int(new_text):
					if search_amount == 0:
						ensure_visible(command_node)
						return
					search_amount -= 1
			"Command Base":
				if command_node.data.commandBase == int(new_text):
					if search_amount == 0:
						ensure_visible(command_node)
						return
					search_amount -= 1
			"Command Modifier":
				if command_node.data.commandModifier == int(new_text):
					if search_amount == 0:
						ensure_visible(command_node)
						return
					search_amount -= 1
			"Command Index":
				if (
						command_node.index == int(new_text)
						or command_node.data.commandBase == 23 and command_node.data.args[1] == int(new_text)
						or command_node.data.commandBase == 30 and command_node.data.args[1] == int(new_text)
						or command_node.data.commandBase == 56 and command_node.data.args[1] == int(new_text)
						or command_node.data.commandBase == 64 and command_node.data.args[0] == int(new_text)
				):
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


func _on_graph_edit_end_node_move() -> void:
	save_positions()


func _on_close_button_pressed() -> void:
	if map:
		Roth.editor_action.emit(map.map_info, "Edit Commands")
		close(map.map_info.name)
