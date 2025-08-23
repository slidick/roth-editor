extends GraphNode
class_name CommandNode

signal add_to_entry_list(index: int)
signal remove_from_entry_list(index: int)
signal delete_command(index: int)

# Modifier Notes:
# Modifiers seem to always do the same thing for each command type but not all command types support each modifier.
# Bit 1: Autorun
# Bit 2: Toggle Initial State
# Bit 3: Effect all connected sectors not separated by faces with RoomBlk flag set
# Bit 4: Start Disabled; Enable with CommandBase 23
# Bit 5: Unused
# Bit 6: Unused
# Bit 7: Unused
# Bit 8: ??? Set on almost every entry command and commands 56 and 64, doesn't seem to have an actual effect.
const command_list: Array = [
	{"command_base": 1, "number_of_args": 0, "can_be_entry_command": false, "name": "Empty (No SFX)"},
	{"command_base": 2, "number_of_args": 5, "can_be_entry_command": true, "name": "Light Switch", "flag_2": "Remove After Use", "flag_6": "Start Off", "arg_1": "Flags", "arg_2": "Object ID", "arg_3": "Sector ID", "arg_5": "SFX Index"},
	{"command_base": 3, "number_of_args": 8, "can_be_entry_command": true, "name": "Modify Sector", "flag_2": "Texture Height Override", "arg_1": "Flags/Speed", "arg_2": "Sector ID", "arg_5": "Auto Revert Timeout"},
	{"command_base": 7, "number_of_args": 7, "can_be_entry_command": false, "name": "Change Floor/Ceiling Height", "flag_1": "Ceiling", "arg_1": "Flags/Speed", "arg_2": "Sector ID", "arg_3": "Starting Height", "arg_4": "Ending Height", "arg_5": "Autoclose Timeout"},
	{"command_base": 8, "number_of_args": 3, "can_be_entry_command": true, "name": "Left-Click Object", "flag_1": "No Switch", "flag_2": "Remove After", "flag_5": "Only Once", "arg_1": "Flags", "arg_2": "Object ID", "arg_3": "SFX Index"},
	{"command_base": 9, "number_of_args": 6, "can_be_entry_command": false, "name": "Move Sector", "flag_1": "Floor Texture Moves", "flag_2": "Ceiling Texture Moves", "flag_3": "Platform Floor Texture Moves", "flag_4": "Platform Ceiling Texture Moves", "flag_6": "Auto Repeat", "flag_7": "Move Along X-Axis", "arg_1": "Flags/Speed", "arg_2": "Sector ID", "arg_5": "Auto Revert Timeout"},
	{"command_base": 10, "number_of_args": 5, "can_be_entry_command": false, "name": "Change Floor Texture", "flag_3": "Disabled", "flag_9": "Scale A", "flag_10": "Scale B", "arg_1": "Flags", "arg_2": "Sector ID", "arg_3": "Texture Index", "arg_4": "X/Y Shift", "arg_5": "Auto Revert Timeout"},
	{"command_base": 12, "number_of_args": 8, "can_be_entry_command": false, "name": "Change Face Texture Advanced", "flag_4": "All Texture Maps With ID", "flag_9": "Transparency", "flag_10": "X-Flip", "flag_11": "Image Fit", "flag_12": "Fixed Size Transparency", "flag_13": "No Reflect", "flag_14": "Half Pixel", "flag_15": "Edge Map", "flag_16": "Draw From Bottom", "arg_1": "Flags", "arg_2": "Face ID", "arg_3": "Mid-Texture Index", "arg_4": "X/Y Shift", "arg_5": "Auto Revert Timeout", "arg_6": "Upper-Texture Index", "arg_7": "Bottom-Texture Index"},
	{"command_base": 13, "number_of_args": 4, "can_be_entry_command": false, "name": "Change Object Texture", "arg_1": "Flags", "arg_2": "Object ID", "arg_3": "Auto Revert Timeout", "arg_4": "Object Texture Index"},
	{"command_base": 14, "number_of_args": 3, "can_be_entry_command": false, "name": "Scroll Sector Texture", "flag_1": "Floor", "flag_2": "Ceiling", "flag_3": "Platform Floor", "flag_4": "Platform Ceiling", "arg_1": "Flags/X-Speed", "arg_2": "Sector ID/Y-Speed"},
	{"command_base": 15, "number_of_args": 3, "can_be_entry_command": false, "name": "Scroll Face Texture", "arg_1": "Flags/X-Speed", "arg_2": "Sector ID/Y-Speed"},
	{"command_base": 16, "number_of_args": 2, "can_be_entry_command": false, "name": "Activate SFX Node", "arg_1": "Flags", "arg_2": "SFX Node ID"},
	{"command_base": 17, "number_of_args": 3, "can_be_entry_command": false, "name": "Flash Lights", "arg_1": "Flags", "arg_2": "Sector ID"},
	{"command_base": 18, "number_of_args": 1, "can_be_entry_command": false, "name": "Delay Timer", "arg_1": "Length"},
	{"command_base": 19, "number_of_args": 3, "can_be_entry_command": true, "name": "Enter Sector", "flag_5": "Only Once", "flag_6": "Continuously", "flag_9": "In Air", "arg_1": "Flags", "arg_2": "Sector ID", "arg_3": "SFX Index"},
	{"command_base": 21, "number_of_args": 4, "can_be_entry_command": false, "name": "Count", "arg_1": "Flags"},
	{"command_base": 22, "number_of_args": 2, "can_be_entry_command": false, "name": "Spawn Object Simple", "arg_1": "Flags", "arg_2": "Object ID"},
	{"command_base": 23, "number_of_args": 2, "can_be_entry_command": false, "name": "Toggle Command", "flag_2": "Enable", "flag_3": "Disable", "flag_6": "More Than Once", "arg_1": "Flags", "arg_2": "Command Index"},
	{"command_base": 24, "number_of_args": 7, "can_be_entry_command": true, "name": "Left-Click Face", "flag_1": "Mid-Face", "flag_2": "Lower-Face", "flag_3": "Upper-Face", "flag_5": "Only Once", "arg_1": "Flags", "arg_2": "Face ID", "arg_3": "SFX Index", "arg_4": "Start X", "arg_5": "End X", "arg_6": "Start Y", "arg_7": "End Y"},
	{"command_base": 25, "number_of_args": 7, "can_be_entry_command": true, "name": "Left-Click Floor", "flag_1": "Disabled", "flag_5": "Only Once", "arg_1": "Flags", "arg_2": "Sector ID", "arg_3": "SFX Index", "arg_4": "Start X", "arg_5": "End X", "arg_6": "Start Y", "arg_7": "End Y"},
	{"command_base": 26, "number_of_args": 3, "can_be_entry_command": true, "name": "Attack Face", "arg_1": "Flags", "arg_2": "Face ID"},
	{"command_base": 27, "number_of_args": 3, "can_be_entry_command": true, "name": "Kill Enemy", "arg_1": "Flags", "arg_2": "Object ID"},
	{"command_base": 28, "number_of_args": 3, "can_be_entry_command": false, "name": "Cycle Texture", "arg_1": "Flags", "arg_2": "Sector ID", "arg_3": "Change To 1 Texture After This Sector ID's Texture"},
	{"command_base": 29, "number_of_args": 2, "can_be_entry_command": false, "name": "Change Lighting", "arg_1": "Flags", "arg_2": "Sector ID"},
	{"command_base": 30, "number_of_args": 3, "can_be_entry_command": false, "name": "Modify Count", "flag_2": "Add", "flag_6": "Subtract", "arg_1": "Flags", "arg_2": "Command Index of Count Command", "arg_3": "Amount"},
	{"command_base": 31, "number_of_args": 6, "can_be_entry_command": false, "name": "Texture Change Count", "arg_1": "Flags", "arg_5": "Face ID", "arg_6": "Starting Texture"},
	{"command_base": 32, "number_of_args": 3, "can_be_entry_command": false, "name": "Cycle Object Texture", "arg_1": "Flags", "arg_2": "Object ID", "arg_3": "Change To 1 Texture After This Object ID's Texture"},
	{"command_base": 34, "number_of_args": 6, "can_be_entry_command": false, "name": "Count (Additional Arg)", "arg_1": "Flags"},
	{"command_base": 35, "number_of_args": 7, "can_be_entry_command": false, "name": "Change Object Height", "flag_3": "Slow-Mo", "arg_1": "Flags/Speed", "arg_2": "Object ID", "arg_3": "Starting Height", "arg_4": "Ending Height", "arg_5": "Auto Revert Timeout"},
	{"command_base": 36, "number_of_args": 3, "can_be_entry_command": false, "name": "Rotate Object", "flag_1": "Counter-Clockwise", "arg_1": "Flags", "arg_2": "Object ID"},
	{"command_base": 37, "number_of_args": 4, "can_be_entry_command": true, "name": "Texture Animation Ends", "arg_1": "Flags", "arg_2": "Texture Index", "arg_3": "Ending Frame?"},
	{"command_base": 38, "number_of_args": 2, "can_be_entry_command": false, "name": "Set/Unset Flag", "flag_1": "Unset", "arg_1": "Flags", "arg_2": "Value"},
	{"command_base": 39, "number_of_args": 2, "can_be_entry_command": false, "name": "If Not Item", "flag_1": "If Item", "flag_2": "In Hand", "flag_3": "If Ever Had Item", "flag_4": "Disable?", "flag_5": "Only Once", "flag_6": "No Auto Equip", "arg_1": "Flags", "arg_2": "Item ID"},
	{"command_base": 40, "number_of_args": 2, "can_be_entry_command": false, "name": "If Not Flag", "flag_1": "If Flag", "arg_1": "Flags", "arg_2": "Value"},
	{"command_base": 41, "number_of_args": 2, "can_be_entry_command": false, "name": "Give Item", "arg_1": "Flags", "arg_2": "Item ID"},
	{"command_base": 42, "number_of_args": 2, "can_be_entry_command": false, "name": "Remove Item", "flag_5": "Only Once", "arg_1": "Flags", "arg_2": "Item ID"},
	{"command_base": 43, "number_of_args": 2, "can_be_entry_command": false, "name": "DBase100 Command", "flag_5": "Only Once", "arg_1": "Flags", "arg_2": "Global Command"},
	{"command_base": 45, "number_of_args": 2, "can_be_entry_command": false, "name": "Particle Effect", "arg_1": "Flags/Particles", "arg_2": "Object Texture Index"},
	{"command_base": 46, "number_of_args": 2, "can_be_entry_command": false, "name": "Smash Face Texture", "flag_6": "Allow Toggle", "arg_1": "Flags", "arg_2": "Face ID"},
	{"command_base": 47, "number_of_args": 6, "can_be_entry_command": false, "name": "Open Door", "arg_1": "Flags", "arg_2": "Face ID", "arg_3": "Autoclose Timeout", "arg_4": "Opening SFX", "arg_5": "Closing SFX", "arg_6": "Closed SFX"},
	{"command_base": 48, "number_of_args": 3, "can_be_entry_command": true, "name": "Right-click Object", "arg_1": "Flags", "arg_2": "Object ID", "arg_3": "Global Command"},
	{"command_base": 49, "number_of_args": 7, "can_be_entry_command": true, "name": "Right-click Sector", "flag_1": "Floor", "flag_2": "Ceiling", "flag_3": "Platform Floor", "flag_4": "All Walls", "arg_1": "Flags", "arg_2": "Sector ID", "arg_3": "DBase100 Command", "arg_4": "Start X", "arg_5": "End X", "arg_6": "Start Y", "arg_7": "End Y"},
	{"command_base": 50, "number_of_args": 7, "can_be_entry_command": true, "name": "Right-click Face", "flag_1": "Mid-Face", "flag_2": "Lower-Face", "flag_3": "Upper-Face", "flag_5": "Only Once", "arg_1": "Flags", "arg_2": "Face ID", "arg_3": "DBase100 Command", "arg_4": "Start X", "arg_5": "End X", "arg_6": "Start Y", "arg_7": "End Y"},
	{"command_base": 51, "number_of_args": 3, "can_be_entry_command": false, "name": "Apply Damage", "arg_1": "Flags/Damage", "arg_3": "Range"},
	{"command_base": 52, "number_of_args": 3, "can_be_entry_command": false, "name": "Change Face Texture Simple", "arg_1": "Flags", "arg_2": "Face ID", "arg_3": "Mid-Texture Index"},
	{"command_base": 53, "number_of_args": 4, "can_be_entry_command": false, "name": "Face Emits Damage", "arg_1": "Flags/Damage", "arg_2": "Face ID", "arg_3": "Range"},
	{"command_base": 54, "number_of_args": 2, "can_be_entry_command": false, "name": "DBase100 Command If Next Fails", "arg_1": "Flags", "arg_2": "Global Command"},
	{"command_base": 55, "number_of_args": 3, "can_be_entry_command": true, "name": "Change Texture If Command Chain True", "flag_1": "Objects", "arg_1": "Flags", "arg_2": "Object Texture Index To Change", "arg_3": "Object Texture Index To Change To"},
	{"command_base": 56, "number_of_args": 2, "can_be_entry_command": false, "name": "Jump If Next Fails", "arg_1": "Flags", "arg_2": "Command Index"},
	{"command_base": 57, "number_of_args": 3, "can_be_entry_command": true, "name": "Touch Object", "arg_1": "Flags", "arg_2": "Object ID", "arg_3": "SFX Index"},
	{"command_base": 58, "number_of_args": 1, "can_be_entry_command": false, "name": "Change Object ID", "arg_1": "New ID"},
	{"command_base": 59, "number_of_args": 6, "can_be_entry_command": false, "name": "Map Transition / Warp", "flag_5": "Only Once", "arg_1": "Flags", "arg_2": "Sector ID", "arg_3": "Map Name", "arg_4": "\"", "arg_5": "\"", "arg_6": "\""},
	{"command_base": 60, "number_of_args": 5, "can_be_entry_command": false, "name": "Spawn Object Advanced", "arg_1": "Flags", "arg_2": "Object ID", "arg_3": "Item ID", "arg_4": "Change Object ID", "arg_5": "SFX Index"},
	{"command_base": 61, "number_of_args": 2, "can_be_entry_command": false, "name": "Autorun Timer", "arg_1": "Timer"},
	{"command_base": 62, "number_of_args": 0, "can_be_entry_command": false, "name": "Empty (Allow SFX)"},
	{"command_base": 63, "number_of_args": 1, "can_be_entry_command": false, "name": "Player Rotation", "arg_1": "Flags/Rotation"},
	{"command_base": 64, "number_of_args": 1, "can_be_entry_command": false, "name": "Run Map Command", "arg_1": "Command Index"},
	{"command_base": 65, "number_of_args": 1, "can_be_entry_command": false, "name": "Slow Player Speed", "arg_1": "Flags/Speed Reduction"},
	{"command_base": 66, "number_of_args": 1, "can_be_entry_command": false, "name": "Take Inventory", "flag_1": "Give Back", "arg_1": "Flags"},
]

@onready var arg_nodes: Array = [
	%Arg1Range,
	%Arg2Range,
	%Arg3Range,
	%Arg4Range,
	%Arg5Range,
	%Arg6Range,
	%Arg7Range,
	%Arg8Range,
]

var current_command: Dictionary

var index: int = 0 :
	get():
		return index
	set(new_value):
		index = new_value
		%CommandIndexEdit.text = "%d" % index
var data: Dictionary = {}
var selected_arg: TreeItem
var command_base: int :
	get():
		return data.commandBase
	set(new_value):
		data.commandBase = new_value
		for i in range(%CommandBaseOption.item_count):
			if data.commandBase == %CommandBaseOption.get_item_metadata(i).command_base:
				%CommandBaseOption.select(i)
				current_command = %CommandBaseOption.get_item_metadata(i)
		update_command_base()
var next_command_index: int :
	get():
		return data.nextCommandIndex
	set(new_value):
		for conn: Dictionary in get_parent().connections:
			if conn.from_node == self.name and conn.from_port == 0:
				get_parent().disconnect_node(conn.from_node, conn.from_port, conn.to_node, conn.to_port)
		data.nextCommandIndex = new_value
		%CommandNextCommandIndexEdit.text = "%d" % data.nextCommandIndex
		if data.nextCommandIndex != 0:
			for command_node: Node in get_parent().get_children():
				if command_node is CommandNode:
					if command_node.index == data.nextCommandIndex:
						get_parent().connect_node(self.name, 0, command_node.name, 0)
var arg_1: int :
	get():
		return int(%Arg1Range.text)
	set(new_value):
		%Arg1Range.text = str(new_value)
		update_args_array()
var arg_2: int :
	get():
		return int(%Arg2Range.text)
	set(new_value):
		%Arg2Range.text = str(new_value)
		update_args_array()

func initialize(p_index: int, p_data: Dictionary) -> void:
	index = p_index
	data = p_data


func _ready() -> void:
	var style_box := StyleBoxFlat.new()
	style_box.bg_color = Color("#3399cc")
	var style_box_header := StyleBoxFlat.new()
	style_box_header.bg_color = Color("#8877ee")
	var style_box_header_selected := StyleBoxFlat.new()
	style_box_header_selected.bg_color = Color("#442277")
	
	title = "Command"
	add_theme_stylebox_override("panel", style_box)
	add_theme_stylebox_override("panel_selected", style_box)
	add_theme_stylebox_override("titlebar", style_box_header)
	add_theme_stylebox_override("titlebar_selected", style_box_header_selected)
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
	
	var idx: int = 0
	for command: Dictionary in command_list:
		%CommandBaseOption.add_item("%s%s: %s" % ["*" if command.can_be_entry_command else "", command.command_base, command.name])
		%CommandBaseOption.set_item_metadata(idx, command)
		if data.commandBase == command.command_base:
			%CommandBaseOption.select(idx)
			current_command = command
		idx += 1
	
	%CommandIndexEdit.text = "%d" % index
	%CommandModifierEdit.text = "%d" % data.commandModifier
	%CommandNextCommandIndexEdit.text = "%d" % data.nextCommandIndex
	%MapNameLabel.text = ""

	
	for node: LineEdit in arg_nodes:
		node.set_text(str(0))
		node.get_parent().hide()
	
	var i: int = 0
	for value: int in data.args:
		arg_nodes[i].get_parent().show()
		
		if i == 0 and "arg_1" in current_command and current_command.arg_1.begins_with("Flags/"):
			arg_nodes[i].set_text(str((value>>8)))
		else:
			arg_nodes[i].set_text(str((value)))
	
		if i >= 2:
			%MapNameLabel.text += String.chr((value) & 0xFF)
			%MapNameLabel.text += String.chr((value >> 8) & 0xFF)
		
		if i == 0:
			%FlagButton1.set_pressed_no_signal((value & (1 << 0)) > 0)
			%FlagButton2.set_pressed_no_signal((value & (1 << 1)) > 0)
			%FlagButton3.set_pressed_no_signal((value & (1 << 2)) > 0)
			%FlagButton4.set_pressed_no_signal((value & (1 << 3)) > 0)
			%FlagButton5.set_pressed_no_signal((value & (1 << 4)) > 0)
			%FlagButton6.set_pressed_no_signal((value & (1 << 5)) > 0)
			%FlagButton7.set_pressed_no_signal((value & (1 << 6)) > 0)
			%FlagButton8.set_pressed_no_signal((value & (1 << 7)) > 0)
			%FlagButton9.set_pressed_no_signal((value & (1 << 8)) > 0)
			%FlagButton10.set_pressed_no_signal((value & (1 << 9)) > 0)
			%FlagButton11.set_pressed_no_signal((value & (1 << 10)) > 0)
			%FlagButton12.set_pressed_no_signal((value & (1 << 11)) > 0)
			%FlagButton13.set_pressed_no_signal((value & (1 << 12)) > 0)
			%FlagButton14.set_pressed_no_signal((value & (1 << 13)) > 0)
			%FlagButton15.set_pressed_no_signal((value & (1 << 14)) > 0)
			%FlagButton16.set_pressed_no_signal((value & (1 << 15)) > 0)
		
		i += 1
	
	update_command_base()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if index in get_parent().owner.command_section.entryCommandIndexes:
			%CommandPopupMenu.set_item_disabled(0, true)
			%CommandPopupMenu.set_item_disabled(1, false)
		else:
			if current_command.can_be_entry_command:
				%CommandPopupMenu.set_item_disabled(0, false)
			else:
				%CommandPopupMenu.set_item_disabled(0, true)
			%CommandPopupMenu.set_item_disabled(1, true)
		%CommandPopupMenu.popup(Rect2i(int(event.global_position.x), int(event.global_position.y), 0, 0))
		get_viewport().set_input_as_handled()


func save_position() -> void:
	data["node_data"] = Vector2(position_offset)


func _on_command_base_option_item_selected(idx: int) -> void:
	data.commandBase = %CommandBaseOption.get_item_metadata(idx).command_base
	current_command = %CommandBaseOption.get_item_metadata(idx)
	update_command_base()


func update_command_base() -> void:
	if index in get_parent().owner.command_section.entryCommandIndexes:
		%CommandBaseOption.disabled = true
	else:
		%CommandBaseOption.disabled = false
	
	if data.commandBase == 59:
		%MapNameButton.show()
		%MapNameLabel.show()
	else:
		%MapNameButton.hide()
		%MapNameLabel.hide()
	
	if "arg_1" in current_command and current_command.arg_1 == "Flags":
		%FlagsContainer.show()
		%FlagsContainer2.show()
		arg_nodes[0].editable = false
	elif "arg_1" in current_command and current_command.arg_1.begins_with("Flags"):
		%FlagsContainer.show()
		%FlagsContainer2.hide()
		arg_nodes[0].editable = true
	else:
		%FlagsContainer.hide()
		arg_nodes[0].editable = true
	
	
	for i in range(len(arg_nodes)):
		if i >= current_command.number_of_args:
			arg_nodes[i].get_parent().hide()
		else:
			arg_nodes[i].get_parent().show()
	
	update_args_array()
	
	%FlagButton1.text = current_command.flag_1 if "flag_1" in current_command else "Flag 1"
	%FlagButton2.text = current_command.flag_2 if "flag_2" in current_command else "Flag 2"
	%FlagButton3.text = current_command.flag_3 if "flag_3" in current_command else "Flag 3"
	%FlagButton4.text = current_command.flag_4 if "flag_4" in current_command else "Flag 4"
	%FlagButton5.text = current_command.flag_5 if "flag_5" in current_command else "Flag 5"
	%FlagButton6.text = current_command.flag_6 if "flag_6" in current_command else "Flag 6"
	%FlagButton7.text = current_command.flag_7 if "flag_7" in current_command else "Flag 7"
	%FlagButton8.text = current_command.flag_8 if "flag_8" in current_command else "Flag 8"
	%FlagButton9.text = current_command.flag_9 if "flag_9" in current_command else "Flag 9"
	%FlagButton10.text = current_command.flag_10 if "flag_10" in current_command else "Flag 10"
	%FlagButton11.text = current_command.flag_11 if "flag_11" in current_command else "Flag 11"
	%FlagButton12.text = current_command.flag_12 if "flag_12" in current_command else "Flag 12"
	%FlagButton13.text = current_command.flag_13 if "flag_13" in current_command else "Flag 13"
	%FlagButton14.text = current_command.flag_14 if "flag_14" in current_command else "Flag 14"
	%FlagButton15.text = current_command.flag_15 if "flag_15" in current_command else "Flag 15"
	%FlagButton16.text = current_command.flag_16 if "flag_16" in current_command else "Flag 16"
	
	%FlagButton1.tooltip_text = current_command.flag_1 if "flag_1" in current_command else "Flag 1"
	%FlagButton2.tooltip_text = current_command.flag_2 if "flag_2" in current_command else "Flag 2"
	%FlagButton3.tooltip_text = current_command.flag_3 if "flag_3" in current_command else "Flag 3"
	%FlagButton4.tooltip_text = current_command.flag_4 if "flag_4" in current_command else "Flag 4"
	%FlagButton5.tooltip_text = current_command.flag_5 if "flag_5" in current_command else "Flag 5"
	%FlagButton6.tooltip_text = current_command.flag_6 if "flag_6" in current_command else "Flag 6"
	%FlagButton7.tooltip_text = current_command.flag_7 if "flag_7" in current_command else "Flag 7"
	%FlagButton8.tooltip_text = current_command.flag_8 if "flag_8" in current_command else "Flag 8"
	%FlagButton9.tooltip_text = current_command.flag_9 if "flag_9" in current_command else "Flag 9"
	%FlagButton10.tooltip_text = current_command.flag_10 if "flag_10" in current_command else "Flag 10"
	%FlagButton11.tooltip_text = current_command.flag_11 if "flag_11" in current_command else "Flag 11"
	%FlagButton12.tooltip_text = current_command.flag_12 if "flag_12" in current_command else "Flag 12"
	%FlagButton13.tooltip_text = current_command.flag_13 if "flag_13" in current_command else "Flag 13"
	%FlagButton14.tooltip_text = current_command.flag_14 if "flag_14" in current_command else "Flag 14"
	%FlagButton15.tooltip_text = current_command.flag_15 if "flag_15" in current_command else "Flag 15"
	%FlagButton16.tooltip_text = current_command.flag_16 if "flag_16" in current_command else "Flag 16"
	
	if "arg_1" in current_command:
		if current_command.arg_1.begins_with("Flags/"):
			%Arg1Label.text = "%s:" % current_command.arg_1.get_slice("/", 1)
		else:
			%Arg1Label.text = "%s:" % current_command.arg_1
	else:
		%Arg1Label.text = "Arg 1:"
	%Arg2Label.text = ("%s:" % current_command.arg_2) if "arg_2" in current_command else "Arg 2:"
	%Arg3Label.text = ("%s:" % current_command.arg_3) if "arg_3" in current_command else "Arg 3:"
	%Arg4Label.text = ("%s:" % current_command.arg_4) if "arg_4" in current_command else "Arg 4:"
	%Arg5Label.text = ("%s:" % current_command.arg_5) if "arg_5" in current_command else "Arg 5:"
	%Arg6Label.text = ("%s:" % current_command.arg_6) if "arg_6" in current_command else "Arg 6:"
	%Arg7Label.text = ("%s:" % current_command.arg_7) if "arg_7" in current_command else "Arg 7:"
	%Arg8Label.text = ("%s:" % current_command.arg_8) if "arg_8" in current_command else "Arg 8:"
	
	%Arg1Label.tooltip_text = ("%s" % current_command.arg_1) if "arg_1" in current_command else "Arg 1"
	%Arg2Label.tooltip_text = ("%s" % current_command.arg_2) if "arg_2" in current_command else "Arg 2"
	%Arg3Label.tooltip_text = ("%s" % current_command.arg_3) if "arg_3" in current_command else "Arg 3"
	%Arg4Label.tooltip_text = ("%s" % current_command.arg_4) if "arg_4" in current_command else "Arg 4"
	%Arg5Label.tooltip_text = ("%s" % current_command.arg_5) if "arg_5" in current_command else "Arg 5"
	%Arg6Label.tooltip_text = ("%s" % current_command.arg_6) if "arg_6" in current_command else "Arg 6"
	%Arg7Label.tooltip_text = ("%s" % current_command.arg_7) if "arg_7" in current_command else "Arg 7"
	%Arg8Label.tooltip_text = ("%s" % current_command.arg_8) if "arg_8" in current_command else "Arg 8"
	


func _on_command_modifier_edit_text_changed(new_text: String) -> void:
	data.commandModifier = int(new_text)


func update_args_array() -> void:
	var arg_array := []
	for i in range(len(arg_nodes)):
		var node: LineEdit = arg_nodes[i]
		if node.get_parent().visible:
			if i == 0 and "arg_1" in current_command and current_command.arg_1.begins_with("Flags/"):
				var first_half := gather_flags()
				var second_half := int(node.text) << 8
				arg_array.append(first_half+second_half)
			else:
				arg_array.append(int(node.text))
	#print(arg_array)
	data.args = arg_array
	%MapNameLabel.text = ""
	for value: int in arg_array.slice(2):
		%MapNameLabel.text += String.chr((value) & 0xFF)
		%MapNameLabel.text += String.chr((value >> 8) & 0xFF)


func _on_command_popup_menu_index_pressed(_index: int) -> void:
	match _index:
		0:
			add_to_entry_list.emit(index)
			update_command_base()
		1:
			remove_from_entry_list.emit(index)
			update_command_base()
		2:
			delete_command.emit(index)


func _on_map_name_button_pressed() -> void:
	var results: Array = await Dialog.input("Map Name:", "Enter Map Name", "", "", false)
	if not results[0]:
		return
	results[1] = results[1].to_upper()
	
	var value: int = 0
	if len(results[1]) > 0:
		value = results[1].unicode_at(0)
	if len(results[1]) > 1:
		value += (results[1].unicode_at(1) << 8)
	%Arg3Range.text = "%d" % value
	
	value = 0
	if len(results[1]) > 2:
		value = results[1].unicode_at(2)
	if len(results[1]) > 3:
		value += (results[1].unicode_at(3) << 8)
	%Arg4Range.text = "%d" % value
	
	value = 0
	if len(results[1]) > 4:
		value = results[1].unicode_at(4)
	if len(results[1]) > 5:
		value += (results[1].unicode_at(5) << 8)
	%Arg5Range.text = "%d" % value
	
	value = 0
	if len(results[1]) > 6:
		value = results[1].unicode_at(6)
	if len(results[1]) > 7:
		value += (results[1].unicode_at(7) << 8)
	%Arg6Range.text = "%d" % value
	
	update_args_array()


func _on_flag_button_toggled(toggled_on: bool, shift: int) -> void:
	if "arg_1" in current_command and current_command.arg_1.begins_with("Flags/"):
		update_args_array()
		return
	#var arg1 := int(%Arg1Range.text)
	if toggled_on:
		arg_1 |= (1 << shift)
	else:
		arg_1 &= ~(1 << shift)
	#%Arg1Range.set_text(str((arg1)))
	#update_args_array()


func _on_arg_text_changed(_new_text: String) -> void:
	update_args_array()


func gather_flags() -> int:
	return ((int(%FlagButton1.button_pressed) << 0) +
			(int(%FlagButton2.button_pressed) << 1) +
			(int(%FlagButton3.button_pressed) << 2) +
			(int(%FlagButton4.button_pressed) << 3) +
			(int(%FlagButton5.button_pressed) << 4) +
			(int(%FlagButton6.button_pressed) << 5) +
			(int(%FlagButton7.button_pressed) << 6) +
			(int(%FlagButton8.button_pressed) << 7)
	)
