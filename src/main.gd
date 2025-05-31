extends Control


enum Main {
	NewMap,
	OpenMap,
	Sep0,
	TestMapLimited,
	TestMapFull,
	Sep1,
	Settings,
	Sep2,
	Quit,
}

enum WindowID {
	Editor,
	Search,
	DAS,
	Sound,
	DBase100,
}

enum HelpID {
	Controls=0,
}


func _ready() -> void:
	get_tree().auto_accept_quit = false
	%Version.text = "v%s" % ProjectSettings.get_setting("application/config/version")
	var input := InputEventAction.new()
	input.action = "test_map"
	var shortcut := Shortcut.new()
	shortcut.events.append(input)
	%Main.set_item_shortcut(Main.TestMapLimited, shortcut, true)
	var input_2 := InputEventAction.new()
	input_2.action = "test_map_full"
	var shortcut_2 := Shortcut.new()
	shortcut_2.events.append(input_2)
	%Main.set_item_shortcut(Main.TestMapFull, shortcut_2, true)


func _process(_delta: float) -> void:
	$FPSLabel.text = "FPS: %s" % Engine.get_frames_per_second()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug_collision"):
		toggle_show_debug_collisions_hint()
	if event.is_action_pressed("toggle_fullscreen"):
		toggle_fullscreen()
	if event.is_action_pressed("take_screenshot"):
		take_screenshot()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if await Dialog.confirm("Are you sure?\nMake sure to save!", "Confirm Quit", false):
			Console.print("Quitting...")
			get_tree().quit()


func quit() -> void:
	get_tree().get_root().propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)


func toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func toggle_show_debug_collisions_hint() -> void:
	var _value: bool = not get_tree().debug_collisions_hint
	Console.print("Set show_debug_collisions_hint: %s" % _value)
	var tree: SceneTree = get_tree()
	# https://github.com/godotengine/godot-proposals/issues/2072
	
	# Traverse tree to call toggle collision visibility
	var node_stack: Array[Node] = [tree.get_root()]
	while not node_stack.is_empty():
		var node: Node = node_stack.pop_back()
		if is_instance_valid(node):
			if (
					node is CollisionShape2D
					or node is CollisionPolygon2D
					or node is CollisionObject2D
			):
				# queue_redraw on instances of
				node.queue_redraw()
			elif node is TileMap:
				# use visibility mode to force redraw
				node.collision_visibility_mode = TileMap.VISIBILITY_MODE_FORCE_HIDE
				node.collision_visibility_mode = TileMap.VISIBILITY_MODE_DEFAULT
			elif (
					node is RayCast3D
					or node is CollisionShape3D
					or node is CollisionPolygon3D
					or node is CollisionObject3D
					or node is GPUParticlesCollision3D
					or node is GPUParticlesCollisionBox3D
					or node is GPUParticlesCollisionHeightField3D
					or node is GPUParticlesCollisionSDF3D
					or node is GPUParticlesCollisionSphere3D
			):
				# remove and re-add the node to the tree to force a redraw
				# https://github.com/godotengine/godot/blob/26b1fd0d842fa3c2f090ead47e8ea7cd2d6515e1/scene/3d/collision_object_3d.cpp#L39
				var parent: Node = node.get_parent()
				if parent:
					if not node.can_process():
						tree.debug_collisions_hint = false
						parent.remove_child(node)
						parent.add_child(node)
					else:
						tree.debug_collisions_hint = _value
						parent.remove_child(node)
						parent.add_child(node)
			node_stack.append_array(node.get_children())
	tree.debug_collisions_hint = _value


func take_screenshot() -> void:
	if not DirAccess.dir_exists_absolute("user://screenshots"):
		DirAccess.make_dir_absolute("user://screenshots")
	var list: PackedStringArray = DirAccess.get_files_at("user://screenshots")
	var number: int = 0
	for file: String in list:
		var i: int = int(file.split("screen-")[1].split(".png")[0])
		if i > number:
			number = i
	number += 1
	get_viewport().get_texture().get_image().save_png("user://screenshots/screen-%03d.png" % number)


func _on_main_index_pressed(index: int) -> void:
	match index:
		Main.NewMap:
			%NewMap.toggle()
		Main.OpenMap:
			%OpenMap.toggle()
		Main.Settings:
			%Settings.toggle(true)
			#%SelectionInstallationFileDialog.popup_centered_ratio()
		Main.Quit:
			quit()
		Main.TestMapLimited:
			%Editor.test_map(false)
		Main.TestMapFull:
			%Editor.test_map(true)


func _on_windows_index_pressed(index: int) -> void:
	match index:
		WindowID.DAS:
			%DASViewer.toggle()
		WindowID.Editor:
			%Editor.toggle()
		WindowID.Search:
			%Search.toggle()
		WindowID.Sound:
			%SoundViewer.toggle()
		WindowID.DBase100:
			%DBase100.toggle()


func _on_help_index_pressed(index: int) -> void:
	match index:
		HelpID.Controls:
			%Controls.toggle()


func _on_das_window_window_shown(_bool: bool) -> void:
	%Windows.set_item_checked(WindowID.DAS, _bool)


func _on_view_3d_window_window_shown(_bool: bool) -> void:
	%Windows.set_item_checked(WindowID.Editor, _bool)


func _on_controls_window_shown(_bool: bool) -> void:
	%Help.set_item_checked(HelpID.Controls, _bool)


func _on_search_window_shown(_bool: bool) -> void:
	%Windows.set_item_checked(WindowID.Search, _bool)


func _on_sound_effects_window_shown(_bool: bool) -> void:
	%Windows.set_item_checked(WindowID.Sound, _bool)


func _on_d_base_100_window_shown(_bool: bool) -> void:
	%Windows.set_item_checked(WindowID.DBase100, _bool)
