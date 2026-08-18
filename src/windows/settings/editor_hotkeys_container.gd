extends MarginContainer

const ACTIONS: Dictionary = {
	"Global": {
		"ui_up": "UI Up",
		"ui_down": "UI Down",
		"ui_left": "UI Left",
		"ui_right": "UI Right",
		"toggle_fullscreen": "Toggle Fullscreen",
		"take_screenshot": "Take Screenshot",
		"test_map": "Run Map",
		"toggle_console": "Toggle Dev Console",
	},
	"Both Editors": {
		"delete_selected": "Delete Selected",
		"merge_sectors": "Merge Sectors",
		"hide_selected_sectors": "Hide Selected Sectors",
		"show_hidden_sectors": "Show Hidden Sectors",
		"hide_non_selected_sectors": "Hide Non-Selected Sectors",
	},
	"3D Editor": {
		"camera_forward": "Camera Forward",
		"camera_backward": "Camera Backward",
		"camera_left": "Camera Left",
		"camera_right": "Camera Right",
		"camera_up": "Camera Up",
		"camera_down": "Camera Down",
		"camera_boost": "Camera Boost",
		
		"select_face": "Select Sector/Face/etc",
		"select_additional_face": "Select Additional Sector/Face/etc",
		"deselect_additional_face": "Deselect Single Sector/Face/etc",
		"toggle_selection_highlight": "Toggle Selection Highlight",
		"open_3d_context_menu": "Open 3D Context Menu",
		
		"copy_texture": "Copy Texture/Properties",
		"paste_texture": "Paste Texture/Properties",
		"paste_options_dialog": "Open Paste Options Dialog",
		
		"raise_floor_ceiling": "Raise Floor/Ceiling Height",
		"lower_floor_ceiling": "Lower Floor/Ceiling Height",
		"move_object_to_ceiling": "Move Object To Ceiling",
		"move_object_to_floor": "Move Object To Floor",
		
		"toggle_mouse_capture": "Toggle Mouse Capture",
		"toggle_debug_collision": "Toggle Debug Collision",
		"toggle_mouse_picking": "Toggle Mouse Picking",
		"toggle_pointer_arrow": "Toggle Point To Selection Arrow",
	},
	"2D Editor": {
		"map_2d_zoom_in": "Map2D - Zoom In",
		"map_2d_zoom_out": "Map2D - Zoom Out",
		"next_sector_hover": "Next Overlapping Sector",
		"unmerge_vertices": "Unmerge Vertices",
		"copy_sectors": "Copy Sectors",
		"cut_sectors": "Cut Sectors",
		"start_paste_sectors": "Paste Sectors",
		"cancel_paste_sectors": "Cancel Paste Sectors",
		"complete_paste_sectors": "Complete Paste Sectors",
		"pin_paste": "Pin Paste Preview",
		"reset_paste_position": "Reset Paste Position",
	},
}

var KEY_REBINDS_FILEPATH: String = OS.get_user_data_dir().path_join("key_rebinds.tres")
const PLUS_ICON: Texture2D = preload("uid://b2ukr0mbf0vh")
const X_ICON: Texture2D = preload("uid://dar12qhmtpxnt")
const EDIT_ICON: Texture2D = preload("uid://c5klcdsorrg58")
const REVERT_ICON: Texture2D = preload("uid://cjvbuqfblt3nj")

@export var event_window: BaseWindow

var key_rebinds: KeyRebinds
var _default_controls: Dictionary[String, Array] = {}
var allow_input: bool = false
var current_event: InputEvent = null

func _ready() -> void:
	assert(event_window)
	
	# Gather list of all used actions
	var action_names: Array = []
	for category: String in ACTIONS:
		for action: String in ACTIONS[category]:
			action_names.append(action)
	
	# Get defaults for those actions
	for action: String in InputMap.get_actions():
		if action not in action_names:
			continue
		_default_controls[action] = InputMap.action_get_events(action)
	
	# Load custom keybinds
	if ResourceLoader.exists(KEY_REBINDS_FILEPATH):
		key_rebinds = ResourceLoader.load(KEY_REBINDS_FILEPATH, "KeyRebinds")
	else:
		key_rebinds = KeyRebinds.new()
	
	# Assign custom keybinds to actions
	for action: String in key_rebinds.key_rebinds:
		if action in action_names:
			InputMap.action_erase_events(action)
			for event: InputEvent in key_rebinds.key_rebinds[action]:
				InputMap.action_add_event(action, event)
	
	# Setup tree
	%Tree.set_column_title(0, "Name")
	%Tree.set_column_title(1, "Binding")
	setup_tree()


func setup_tree() -> void:
	%Tree.clear()
	var root: TreeItem = %Tree.create_item()
	for category: String in ACTIONS:
		var cat_tree: TreeItem = root.create_child()
		cat_tree.set_text(0, category)
		cat_tree.set_custom_bg_color(0, Color(0.3,0.3,0.3,0.3))
		cat_tree.set_custom_bg_color(1, Color(0.3,0.3,0.3,0.3))
		for action: String in ACTIONS[category]:
			if not %FilterNameEdit.text.is_empty() and ACTIONS[category][action].to_lower().find(%FilterNameEdit.text.to_lower()) == -1:
				continue
			if current_event:
				var found: bool = false
				for event: InputEvent in InputMap.action_get_events(action):
					if current_event.is_match(event):
						found = true
				if not found:
					continue
			var tree_item: TreeItem = cat_tree.create_child()
			tree_item.set_custom_bg_color(0, Color(0.3,0.3,0.3,0.1))
			tree_item.set_custom_bg_color(1, Color(0.3,0.3,0.3,0.1))
			tree_item.set_text(0, ACTIONS[category][action])
			tree_item.set_metadata(0, action)
			var j: int = 0
			for event: InputEvent in InputMap.action_get_events(action):
				var sub_tree_item: TreeItem = tree_item.create_child()
				if j == 0:
					sub_tree_item.set_text(0, "Primary")
					j += 1
				sub_tree_item.set_metadata(0, action)
				sub_tree_item.set_text(1, event.as_text())
				sub_tree_item.set_metadata(1, event)
				sub_tree_item.add_button(1, EDIT_ICON, 0)
				sub_tree_item.add_button(1, X_ICON, 1)
			if len(InputMap.action_get_events(action)) > 0:
				tree_item.set_text(1, ", ".join(InputMap.action_get_events(action).map(func (e: InputEvent) -> String: return e.as_text())))
			else:
				tree_item.set_text(1, "None")
			if action in key_rebinds.key_rebinds:
				tree_item.add_button(1, REVERT_ICON, 4)
			tree_item.add_button(1, PLUS_ICON, 2)
			tree_item.add_button(1, X_ICON, 3)
			tree_item.collapsed = true
		if cat_tree.get_child_count() == 0:
			cat_tree.free()


func _on_tree_item_activated() -> void:
	var tree_item: TreeItem = %Tree.get_selected()
	if tree_item.get_parent().get_parent() == %Tree.get_root():
		if %Tree.get_selected_column() == 0:
			tree_item.collapsed = not tree_item.collapsed
		if %Tree.get_selected_column() == 1 and tree_item.get_child_count() > 1:
			tree_item.collapsed = false
		if %Tree.get_selected_column() == 1 and tree_item.get_child_count() == 1:
			tree_item.collapsed = false
			activate(tree_item.get_child(0))
	else:
		if %Tree.get_selected_column() == 1:
			activate(tree_item)


func _on_tree_button_clicked(tree_item: TreeItem, _column: int, id: int, _mouse_button_index: int) -> void:
	var action: String = tree_item.get_metadata(0)
	match id:
		0:
			activate(tree_item)
		1:
			var event_data: Array = get_event_from_tree_item(tree_item)
			InputMap.action_erase_event(action, event_data[2][event_data[1]])
			event_data[2].pop_at(event_data[1])
			key_rebinds.key_rebinds[action] = event_data[2]
			save()
			if len(InputMap.action_get_events(action)) > 0:
				tree_item.get_parent().set_text(1, ", ".join(InputMap.action_get_events(action).map(func (e: InputEvent) -> String: return e.as_text())))
			else:
				tree_item.get_parent().set_text(1, "None")
			tree_item.get_parent().clear_buttons()
			tree_item.get_parent().add_button(1, REVERT_ICON, 4)
			tree_item.get_parent().add_button(1, PLUS_ICON, 2)
			tree_item.get_parent().add_button(1, X_ICON, 3)
			if tree_item.get_index() == 0 and tree_item.get_parent().get_child_count() > 1:
				tree_item.get_next().set_text(0, "Primary")
			tree_item.free()
		2:
			var new_event: InputEvent = await event_window.get_event(get_event_from_tree_item(tree_item, true))
			if new_event:
				var sub_item: TreeItem = tree_item.create_child()
				sub_item.set_metadata(0, action)
				sub_item.set_text(1, new_event.as_text())
				sub_item.set_metadata(1, new_event)
				if sub_item.get_index() == 0:
					sub_item.set_text(0, "Primary")
				sub_item.add_button(1, EDIT_ICON, 0)
				sub_item.add_button(1, X_ICON, 1)
				InputMap.action_add_event(action, new_event)
				tree_item.set_text(1, ", ".join(InputMap.action_get_events(action).map(func (e: InputEvent) -> String: return e.as_text())))
				key_rebinds.key_rebinds[action] = InputMap.action_get_events(action)
				save()
		3:
			for child: TreeItem in tree_item.get_children():
				child.free()
			InputMap.action_erase_events(action)
			key_rebinds.key_rebinds[action] = []
			tree_item.set_text(1, "None")
			save()
			tree_item.clear_buttons()
			tree_item.add_button(1, REVERT_ICON, 4)
			tree_item.add_button(1, PLUS_ICON, 2)
			tree_item.add_button(1, X_ICON, 3)
		4:
			InputMap.action_erase_events(action)
			key_rebinds.key_rebinds.erase(action)
			save()
			for child: TreeItem in tree_item.get_children():
				child.free()
			var j: int = 0
			for event: InputEvent in _default_controls[action]:
				InputMap.action_add_event(action, event)
				var sub_tree_item: TreeItem = tree_item.create_child()
				if j == 0:
					sub_tree_item.set_text(0, "Primary")
					j += 1
				sub_tree_item.set_metadata(0, action)
				sub_tree_item.set_text(1, event.as_text())
				sub_tree_item.set_metadata(1, event)
				sub_tree_item.add_button(1, EDIT_ICON, 0)
				sub_tree_item.add_button(1, X_ICON, 1)
			tree_item.set_text(1, ", ".join(InputMap.action_get_events(action).map(func (e: InputEvent) -> String: return e.as_text())))
			tree_item.clear_buttons()
			tree_item.add_button(1, PLUS_ICON, 2)
			tree_item.add_button(1, X_ICON, 3)


func get_event_from_tree_item(tree_item: TreeItem, is_parent: bool = false) -> Array:
	var action: String = tree_item.get_metadata(0)
	var selected_event: int = tree_item.get_index()
	var events: Array = []
	if is_parent:
		tree_item = tree_item.get_first_child()
		selected_event = -1
	else:
		tree_item = tree_item.get_parent().get_first_child()
	while tree_item:
		events.append(tree_item.get_metadata(1))
		tree_item = tree_item.get_next()
	return [action, selected_event, events]


func activate(tree_item: TreeItem) -> void:
	var event_data: Array = get_event_from_tree_item(tree_item)
	var new_event: InputEvent = await event_window.get_event(event_data)
	if new_event:
		event_data[2][event_data[1]] = new_event
		tree_item.set_metadata(1, new_event)
		tree_item.set_text(1, new_event.as_text())
		key_rebinds.key_rebinds[event_data[0]] = event_data[2]
		var parent_item: TreeItem = tree_item.get_parent()
		parent_item.clear_buttons()
		parent_item.add_button(1, REVERT_ICON, 4)
		parent_item.add_button(1, PLUS_ICON, 2)
		parent_item.add_button(1, X_ICON, 3)
		parent_item.set_text(1, ", ".join(event_data[2].map(func (e: InputEvent) -> String: return e.as_text())))
		save()
		
		InputMap.action_erase_events(event_data[0])
		for event: InputEvent in event_data[2]:
			InputMap.action_add_event(event_data[0], event)


func save() -> void:
	ResourceSaver.save(key_rebinds, KEY_REBINDS_FILEPATH)


func _on_filter_name_edit_text_changed(_new_text: String) -> void:
	setup_tree()


func _on_filter_event_edit_gui_input(event: InputEvent) -> void:
	if not allow_input:
		return
	if event is InputEventKey or event is InputEventMouseButton:
		if event.pressed:
			if "position" in event and event.position.x > %FilterEventEdit.size.x - 25:
				return
			current_event = event
			%FilterEventEdit.text = current_event.as_text()
			setup_tree()


func _on_filter_event_edit_editing_toggled(toggled_on: bool) -> void:
	if toggled_on:
		await get_tree().process_frame
		allow_input = true
		%FilterEventEdit.placeholder_text = "Listening for Input"
	else:
		allow_input = false
		%FilterEventEdit.placeholder_text = "Filter by Event"


func _on_filter_event_edit_text_changed(new_text: String) -> void:
	if new_text.is_empty():
		%FilterEventEdit.clear()
		current_event = null
		setup_tree()
	else:
		%FilterEventEdit.text = current_event.as_text()


func _on_clear_button_pressed() -> void:
	%FilterNameEdit.clear()
	%FilterEventEdit.clear()
	current_event = null
	setup_tree()
