extends Control

signal done(from_page: String)
signal key_registered


const basic_controls: Array = [
	"move_forward",
	"move_backward",
	"strafe_left",
	"strafe_right",
	"turn_left",
	"turn_right",
	"look_up",
	"look_down",
	"tilt_up",
	"tilt_down",
	"jump",
	"crouch",
	"attack",
	"inventory",
	"toggle_run",
	"hold_run",
	"unarmed",
	"quickslot_1",
	"quickslot_2",
	"quickslot_3",
	"quickslot_4",
	"quickslot_5",
]

const advanced_controls: Array = [
	"quicksave",
	"quickload",
	"escape",
	"enter",
	"hide_weapon",
	"toggle_subtitles",
	"toggle_adventure_mode",
	"main_menu",
	"reload_after_death",
	"increase_gamma",
	"decrease_gamma",
	"increase_viewport",
	"decrease_viewport",
	"redraw_screen",
	"toggle_textures",
	"toggle_mouse_buttons",
	"display_version",
	"map_warp",
	"map_overlay",
]

const dosbox_controls: Array = [
	"toggle_fullscreen",
	"capture_mouse",
	"cycles_up",
	"cycles_down",
	#"debugger",
	"fast_forward",
]

const DEFAULT_CONTROLS_PRESET: Dictionary = {
	"move_forward": ["%d" % SDL.SDLK_w],
	"move_backward": ["%d" % SDL.SDLK_s],
	"strafe_left": ["%d" % SDL.SDLK_a],
	"strafe_right": ["%d" % SDL.SDLK_d],
	"turn_left": ["%d" % SDL.SDLK_q],
	"turn_right": ["%d" % SDL.SDLK_e],
	"look_up": ["%d" % SDL.SDLK_r],
	"look_down": ["%d" % SDL.SDLK_f],
	"tilt_up": ["%d" % SDL.SDLK_t],
	"tilt_down": ["%d" % SDL.SDLK_g],
	"jump": ["%d" % SDL.SDLK_SPACE],
	"crouch": ["%d" % SDL.SDLK_c],
	"attack": ["%d" % SDL.SDLK_LCTRL],
	"inventory": ["%d" % SDL.SDLK_TAB, "%d" % SDL.SDLK_i],
	"toggle_run": ["%d" % SDL.SDLK_BACKQUOTE],
	
	"unarmed": ["%d" % SDL.SDLK_1],
	"quickslot_1": ["%d" % SDL.SDLK_2],
	"quickslot_2": ["%d" % SDL.SDLK_3],
	"quickslot_3": ["%d" % SDL.SDLK_4],
	"quickslot_4": ["%d" % SDL.SDLK_5],
	"quickslot_5": ["%d" % SDL.SDLK_6],
	"quicksave": ["%d" % SDL.SDLK_F9],
	"quickload": ["%d" % SDL.SDLK_F10],
	"hide_weapon": ["%d" % SDL.SDLK_F1],
	"toggle_subtitles": ["%d" % SDL.SDLK_F2],
	"toggle_adventure_mode": ["%d" % SDL.SDLK_F3],
	"toggle_mouse_buttons": ["%d" % SDL.SDLK_F5],
	"display_version": ["%d" % SDL.SDLK_F8],
	"increase_gamma": ["%d" % SDL.SDLK_PERIOD],
	"decrease_gamma": ["%d" % SDL.SDLK_COMMA],
	"increase_viewport": ["%d" % SDL.SDLK_EQUALS],
	"decrease_viewport": ["%d" % SDL.SDLK_MINUS],
	"enter": ["%d" % SDL.SDLK_RETURN, "%d" % SDL.SDLK_KP_ENTER],
	"escape": ["%d" % SDL.SDLK_ESCAPE],
	"main_menu": ["%d" % SDL.SDLK_m],
	"toggle_textures": ["%d" % SDL.SDLK_BACKSLASH],
	"redraw_screen": ["%d" % SDL.SDLK_SLASH],
	"reload_after_death": ["%d" % SDL.SDLK_SPACE],
	"hold_run": ["%d" % SDL.SDLK_LSHIFT],
	"map_warp": ["%d" % SDL.SDLK_SEMICOLON],
	"map_overlay": ["%d" % SDL.SDLK_l],
	
	"toggle_fullscreen": ["%d" % SDL.SDLK_F11],
	"capture_mouse": ["%d" % SDL.SDLK_F12],
	"cycles_up": ["%d" % SDL.SDLK_RIGHTBRACKET],
	"cycles_down": ["%d" % SDL.SDLK_LEFTBRACKET],
	"debugger": ["%d" % SDL.SDLK_PAUSE],
	"fast_forward": [],
}

const ORIGINAL_CONTROLS_PRESET: Dictionary = {
	"move_forward": ["%d" % SDL.SDLK_UP],
	"move_backward": ["%d" % SDL.SDLK_DOWN],
	"strafe_left": ["%d" % SDL.SDLK_COMMA],
	"strafe_right": ["%d" % SDL.SDLK_PERIOD],
	"turn_left": ["%d" % SDL.SDLK_LEFT],
	"turn_right": ["%d" % SDL.SDLK_RIGHT],
	"look_up": ["%d" % SDL.SDLK_PAGEUP],
	"look_down": ["%d" % SDL.SDLK_PAGEDOWN],
	"tilt_up": ["%d" % SDL.SDLK_HOME],
	"tilt_down": ["%d" % SDL.SDLK_END],
	"jump": ["%d" % SDL.SDLK_a],
	"crouch": ["%d" % SDL.SDLK_z],
	"attack": ["%d" % SDL.SDLK_LCTRL],
	"inventory": ["%d" % SDL.SDLK_i],
	"toggle_run": ["%d" % SDL.SDLK_CAPSLOCK, "%d" % SDL.SDLK_BACKQUOTE],
	
	"unarmed": ["%d" % SDL.SDLK_1],
	"quickslot_1": ["%d" % SDL.SDLK_2],
	"quickslot_2": ["%d" % SDL.SDLK_3],
	"quickslot_3": ["%d" % SDL.SDLK_4],
	"quickslot_4": ["%d" % SDL.SDLK_5],
	"quickslot_5": ["%d" % SDL.SDLK_6],
	"quicksave": ["%d" % SDL.SDLK_F9],
	"quickload": ["%d" % SDL.SDLK_F10],
	"hide_weapon": ["%d" % SDL.SDLK_F1],
	"toggle_subtitles": ["%d" % SDL.SDLK_F2],
	"toggle_adventure_mode": ["%d" % SDL.SDLK_F3],
	"toggle_mouse_buttons": ["%d" % SDL.SDLK_F5],
	"display_version": ["%d" % SDL.SDLK_F8],
	"increase_gamma": ["%d" % SDL.SDLK_c],
	"decrease_gamma": ["%d" % SDL.SDLK_v],
	"increase_viewport": ["%d" % SDL.SDLK_EQUALS],
	"decrease_viewport": ["%d" % SDL.SDLK_MINUS],
	"enter": ["%d" % SDL.SDLK_RETURN, "%d" % SDL.SDLK_KP_ENTER],
	"escape": ["%d" % SDL.SDLK_ESCAPE],
	"main_menu": ["%d" % SDL.SDLK_d],
	"toggle_textures": ["%d" % SDL.SDLK_m],
	"redraw_screen": ["%d" % SDL.SDLK_t],
	"reload_after_death": ["%d" % SDL.SDLK_SPACE],
	"hold_run": ["%d" % SDL.SDLK_LSHIFT],
	"map_warp": ["%d" % SDL.SDLK_w],
	"map_overlay": ["%d" % SDL.SDLK_l],
	
	"toggle_fullscreen": ["%d" % SDL.SDLK_F11],
	"capture_mouse": ["%d" % SDL.SDLK_F12],
	"cycles_up": ["%d" % SDL.SDLK_RIGHTBRACKET],
	"cycles_down": ["%d" % SDL.SDLK_LEFTBRACKET],
	"debugger": ["%d" % SDL.SDLK_PAUSE],
	"fast_forward": [],
}

const SLIDICKS_CONTROLS_PRESET: Dictionary = {
	"move_forward": ["%d" % SDL.SDLK_w],
	"move_backward": ["%d" % SDL.SDLK_s],
	"strafe_left": ["%d" % SDL.SDLK_a],
	"strafe_right": ["%d" % SDL.SDLK_d],
	"turn_left": ["%d" % SDL.SDLK_LSHIFT],
	"turn_right": ["%d" % SDL.SDLK_SPACE],
	"look_up": ["%d" % SDL.SDLK_r],
	"look_down": ["%d" % SDL.SDLK_v],
	"tilt_up": ["%d" % SDL.SDLK_t],
	"tilt_down": ["%d" % SDL.SDLK_f],
	"jump": ["%d" % SDL.SDLK_LALT],
	"crouch": ["%d" % SDL.SDLK_x],
	"attack": ["%d" % SDL.SDLK_LCTRL],
	"inventory": ["%d" % SDL.SDLK_TAB],
	"toggle_run": ["%d" % SDL.SDLK_BACKQUOTE],
	
	"unarmed": ["%d" % SDL.SDLK_1],
	"quickslot_1": ["%d" % SDL.SDLK_2],
	"quickslot_2": ["%d" % SDL.SDLK_3],
	"quickslot_3": ["%d" % SDL.SDLK_4],
	"quickslot_4": ["%d" % SDL.SDLK_5],
	"quickslot_5": ["%d" % SDL.SDLK_6],
	"quicksave": ["%d" % SDL.SDLK_HOME],
	"quickload": ["%d" % SDL.SDLK_INSERT],
	"hide_weapon": ["%d" % SDL.SDLK_F1],
	"toggle_subtitles": ["%d" % SDL.SDLK_F2],
	"toggle_adventure_mode": ["%d" % SDL.SDLK_F3],
	"toggle_mouse_buttons": ["%d" % SDL.SDLK_F5],
	"display_version": ["%d" % SDL.SDLK_F8],
	"increase_gamma": ["%d" % SDL.SDLK_PERIOD],
	"decrease_gamma": ["%d" % SDL.SDLK_COMMA],
	"increase_viewport": ["%d" % SDL.SDLK_EQUALS],
	"decrease_viewport": ["%d" % SDL.SDLK_MINUS],
	"enter": ["%d" % SDL.SDLK_RETURN, "%d" % SDL.SDLK_KP_ENTER, "%d" % SDL.SDLK_e, "%d" % SDL.SDLK_PAGEDOWN],
	"escape": ["%d" % SDL.SDLK_ESCAPE, "%d" % SDL.SDLK_q],
	"main_menu": ["%d" % SDL.SDLK_g],
	"toggle_textures": ["%d" % SDL.SDLK_m],
	"redraw_screen": ["%d" % SDL.SDLK_y],
	"reload_after_death": ["%d" % SDL.SDLK_c],
	"hold_run": ["%d" % SDL.SDLK_LSHIFT],
	"map_warp": ["%d" % SDL.SDLK_SEMICOLON],
	"map_overlay": ["%d" % SDL.SDLK_l],
	
	"toggle_fullscreen": ["%d" % SDL.SDLK_F11],
	"capture_mouse": ["%d" % SDL.SDLK_F12],
	"cycles_up": ["%d" % SDL.SDLK_RIGHTBRACKET],
	"cycles_down": ["%d" % SDL.SDLK_LEFTBRACKET],
	"debugger": ["%d" % SDL.SDLK_PAUSE],
	"fast_forward": ["%d" % SDL.SDLK_p],
}

const INCLUDED_PRESETS: Dictionary = {
	"Modern": DEFAULT_CONTROLS_PRESET,
	"Original": ORIGINAL_CONTROLS_PRESET,
	"Slidick's": SLIDICKS_CONTROLS_PRESET,
}

var _current_key: String = ""
var _adding: bool = false
var _previous_selected: int = -1


func _ready() -> void:
	%"Basic Controls".show()
	
	var custom_keymap: Dictionary = Settings.settings.get("dosbox_keymap", {})
	%SaveButton.hide()
	%SaveAsButton.hide()
	%DeleteButton.hide()
	
	var preset_selected: bool = false
	%PresetOption.clear()
	for key: String in INCLUDED_PRESETS:
		%PresetOption.add_item(key)
		%PresetOption.set_item_metadata(%PresetOption.item_count-1, INCLUDED_PRESETS[key])
		if key == Settings.settings.get("dosbox_settings", {}).get("keymap_preset", "") and compare_keymaps(custom_keymap, INCLUDED_PRESETS[key]):
			%PresetOption.select(%PresetOption.item_count-1)
			_on_preset_option_item_selected(%PresetOption.item_count-1)
			preset_selected = true
	
	var custom_presets: Dictionary = Settings.settings.get("dosbox_custom_keymap_presets", {})
	for key: String in custom_presets:
		%PresetOption.add_item(key)
		%PresetOption.set_item_metadata(%PresetOption.item_count-1, custom_presets[key])
		if key == Settings.settings.get("dosbox_settings", {}).get("keymap_preset", "") and compare_keymaps(custom_keymap, custom_presets[key]):
			%PresetOption.select(%PresetOption.item_count-1)
			_on_preset_option_item_selected(%PresetOption.item_count-1)
			preset_selected = true
	
	if not preset_selected:
		if custom_keymap.is_empty():
			%PresetOption.select(0)
			_on_preset_option_item_selected(0)
		else:
			%PresetOption.add_item("Custom")
			%PresetOption.select(%PresetOption.item_count-1)
			_previous_selected = %PresetOption.item_count-1
			load_controls(custom_keymap)
			%SaveAsButton.show()


func _on_preset_option_item_selected(index: int) -> void:
	if _previous_selected >= 0 and (%PresetOption.get_item_text(_previous_selected) == "Custom" or %PresetOption.get_item_text(_previous_selected).ends_with("*")):
		if not await Dialog.confirm("Changes not saved. Continue?", "Confirm?", false):
			%PresetOption.select(_previous_selected)
			return
	
	var controls: Dictionary = %PresetOption.get_item_metadata(index)
	Settings.update_settings("dosbox_keymap", controls)
	Settings.update_settings("dosbox_settings", { "keymap_preset": %PresetOption.get_item_text(index) })
	load_controls(controls)
	if _previous_selected >= 0:
		%PresetOption.set_item_text(_previous_selected, %PresetOption.get_item_text(_previous_selected).trim_suffix("*"))
	if %PresetOption.get_item_text(%PresetOption.item_count-1) == "Custom":
		%PresetOption.remove_item(%PresetOption.item_count-1)
	_previous_selected = index
	if %PresetOption.get_item_text(index) in Settings.settings.get("dosbox_custom_keymap_presets", {}):
		%SaveAsButton.show()
		%SaveButton.show()
		%DeleteButton.show()
	else:
		%SaveAsButton.hide()
		%SaveButton.hide()
		%DeleteButton.hide()


func alter_custom_preset() -> void:
	if %PresetOption.get_item_text(%PresetOption.selected) == "Custom":
		pass
	elif %PresetOption.get_item_text(%PresetOption.selected) in INCLUDED_PRESETS:
		%PresetOption.add_item("Custom")
		%PresetOption.select(%PresetOption.item_count-1)
		_previous_selected = %PresetOption.selected
		%SaveAsButton.show()
		%SaveButton.hide()
		%DeleteButton.hide()
	else:
		%PresetOption.set_item_text(%PresetOption.selected, %PresetOption.get_item_text(%PresetOption.selected).trim_suffix("*")+"*")


func compare_keymaps(keymap_a: Dictionary, keymap_b: Dictionary) -> bool:
	for key: String in keymap_a:
		if key not in keymap_b or keymap_a[key] != keymap_b[key]:
			return false
	#for key: String in keymap_b:
		#if key not in keymap_a or keymap_a[key] != keymap_b[key]:
			#return false
	return true


func get_mapping_text(mapping_array: Array) -> String:
	var godot_key_string: String = ""
	for keycode: String in mapping_array:
		godot_key_string += ", " + SDL.sdl_to_godot_string(int(keycode))
	return godot_key_string.lstrip(", ")


func _on_back_button_pressed() -> void:
	%BackButton.disabled = true
	done.emit("Controls")
	await get_tree().create_timer(0.2).timeout
	%BackButton.disabled = false


func _on_button_pressed(key: String, adding: bool = false) -> void:
	alter_custom_preset()
	_current_key = key
	_adding = adding
	%KeyInputPanel.show()
	var node: Node = find_child(key)
	if node.get_child_count() > 0:
		node.get_child(0).show()
	%KeyEdit.grab_focus()
	%ChangingKeyLabel.text = key.to_pascal_case()


func _on_key_edit_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		#print("Command: %s, Godot: %s, SDL: %s" % [_current_key, event.keycode, SDL.godot_to_sdl(event)])
		%KeyInputPanel.hide()
		
		var key_string := OS.get_keycode_string(event.keycode)
		if event.location == KEY_LOCATION_LEFT:
			key_string = "Left" + key_string
		if event.location == KEY_LOCATION_RIGHT:
			key_string = "Right" + key_string
		get_viewport().set_input_as_handled()
		
		var code: int = SDL.godot_to_sdl(event)
		if code == -1:
			Dialog.information("Key mapping to sdl not found for keycode: %d" % event.keycode, "Error", false, Vector2(450, 160), "Close", HORIZONTAL_ALIGNMENT_CENTER)
		else:
		
			if _adding:
				var current_mapping: Variant = Settings.settings.get("dosbox_keymap").get(_current_key)
				if current_mapping and current_mapping is Array:
					current_mapping.append("%d" % code)
				else:
					current_mapping = ["%d" % code]
				Settings.update_settings("dosbox_keymap", {_current_key: current_mapping})
				var mapping_text: String = get_mapping_text(current_mapping)
				find_child(_current_key).text = mapping_text
			else:
				Settings.update_settings("dosbox_keymap", {_current_key: ["%d" % code]})
				find_child(_current_key).text = key_string
		
		if find_child(_current_key).get_child_count() > 0:
			find_child(_current_key).get_child(0).hide()
		
		key_registered.emit()


func _on_change_all_button_pressed() -> void:
	_adding = false
	alter_custom_preset()
	for node_name: String in basic_controls:
		_current_key = node_name
		%KeyInputPanel.show()
		%KeyEdit.grab_focus()
		%ChangingKeyLabel.text = node_name.to_pascal_case()
		var node: Node = find_child(node_name)
		if node.get_child_count() > 0:
			node.get_child(0).show()
		
		await key_registered


func _on_change_all_advanced_button_pressed() -> void:
	_adding = false
	alter_custom_preset()
	for node_name: String in advanced_controls:
		_current_key = node_name
		%KeyInputPanel.show()
		%KeyEdit.grab_focus()
		%ChangingKeyLabel.text = node_name.to_pascal_case()
		var node: Node = find_child(node_name)
		if node.get_child_count() > 0:
			node.get_child(0).show()
		
		await key_registered


func _on_change_all_dos_box_button_pressed() -> void:
	_adding = false
	alter_custom_preset()
	for node_name: String in dosbox_controls:
		_current_key = node_name
		%KeyInputPanel.show()
		%KeyEdit.grab_focus()
		%ChangingKeyLabel.text = node_name.to_pascal_case()
		var node: Node = find_child(node_name)
		if node.get_child_count() > 0:
			node.get_child(0).show()
		
		await key_registered


func _on_label_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_current_key = get_viewport().gui_get_hovered_control().name
		%PopupMenu.popup(Rect2i(int(event.global_position.x), int(event.global_position.y), 0, 0))


func _on_popup_menu_index_pressed(_index: int) -> void:
	Settings.settings.dosbox_keymap.erase(_current_key)
	Settings._save_settings()
	find_child(_current_key).text = ""


func reset_controls() -> Dictionary:
	Settings.update_settings("dosbox_keymap", DEFAULT_CONTROLS_PRESET)
	return DEFAULT_CONTROLS_PRESET


func load_controls(controls: Dictionary) -> void:
	for key: String in controls:
		var node: Label = find_child(key)
		if node:
			node.text = get_mapping_text(controls[key])


func _on_save_button_pressed() -> void:
	%PresetOption.set_item_text(%PresetOption.selected, %PresetOption.get_item_text(%PresetOption.selected).trim_suffix("*"))
	var preset_name: String = %PresetOption.get_item_text(%PresetOption.selected)
	var new_keymap: Dictionary = Settings.settings.get("dosbox_keymap", {})
	%PresetOption.set_item_metadata(%PresetOption.selected, new_keymap)
	Settings.update_settings("dosbox_custom_keymap_presets", { preset_name: new_keymap })


func _on_save_as_button_pressed(p_preset_name: String = "") -> void:
	var error: String = "init"
	var preset_name: String = p_preset_name
	while not error.is_empty():
		var results: Array = await Dialog.input("New preset name:", "Preset", preset_name, "" if error=="init" else error, false, Vector2(400,200))
		if results[0] == false:
			return
		preset_name = results[1]
		error = check_preset_name(preset_name)
	
	var new_keymap: Dictionary = Settings.settings.get("dosbox_keymap", {})
	if preset_name in Settings.settings.get("dosbox_custom_keymap_presets", {}):
		if not await Dialog.confirm("Preset exists. Overwrite?", "Confirm overwrite", false, Vector2(400,200)):
			_on_save_as_button_pressed(preset_name)
			return
		Settings.update_settings("dosbox_custom_keymap_presets", { preset_name: new_keymap })
		for i in range(%PresetOption.item_count):
			if %PresetOption.get_item_text(i) == preset_name:
				%PresetOption.select(i)
				%PresetOption.set_item_text(_previous_selected, %PresetOption.get_item_text(_previous_selected).trim_suffix("*"))
				_previous_selected = i
				%PresetOption.set_item_metadata(i, new_keymap)
	else:
		if %PresetOption.get_item_text(%PresetOption.selected) == "Custom":
			%PresetOption.set_item_text(%PresetOption.selected, preset_name)
			%PresetOption.set_item_metadata(%PresetOption.selected, new_keymap)
		else:
			%PresetOption.set_item_text(_previous_selected, %PresetOption.get_item_text(_previous_selected).trim_suffix("*"))
			%PresetOption.add_item(preset_name)
			%PresetOption.set_item_metadata(%PresetOption.item_count-1, new_keymap)
			%PresetOption.select(%PresetOption.item_count-1)
			_previous_selected = %PresetOption.item_count-1
	Settings.update_settings("dosbox_custom_keymap_presets", { preset_name: new_keymap })
	%SaveButton.show()
	%DeleteButton.show()


func check_preset_name(preset_name: String) -> String:
	if not preset_name.is_valid_filename():
		return "Can't start/end with space\nCan't contain characters :/\\?*\"|%<>"
	elif preset_name == "Custom":
		return "Can't be named Custom"
	elif preset_name in INCLUDED_PRESETS:
		return "Can't be named same as included presets"
	return ""


func _on_delete_button_pressed() -> void:
	if await Dialog.confirm("Delete preset?", "Confirm Delete", false, Vector2(400,200)):
		var preset_name: String = %PresetOption.get_item_text(%PresetOption.selected)
		Settings.settings.get("dosbox_custom_keymap_presets").erase(preset_name)
		Settings._save_settings()
		_previous_selected = %PresetOption.selected - 1
		%PresetOption.remove_item(%PresetOption.selected)
		%PresetOption.select(_previous_selected)
		_on_preset_option_item_selected(_previous_selected)
