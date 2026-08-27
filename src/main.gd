extends Control


enum Main {
	ManageMaps,
	ManageDBase,
	ManageSFX,
	ManageDAS,
	BackdropEditor,
	IconsEditor,
	Sep0,
	SaveEditor,
	Sep1,
	Normality,
	Sep2,
	Quit,
}

enum Options {
	ConcaveSectors,
	SFXZone3D,
	SFXZones2D,
	MousePoint,
	ShowSky,
	Sep0,
	Settings
}

enum WindowID {
	Editor,
	Extras,
}

enum HelpID {
	Controls=0,
}

enum Shortcuts {
	Run,
}


func _ready() -> void:
	get_tree().auto_accept_quit = false
	%Version.text = "v%s" % ProjectSettings.get_setting("application/config/version")
	var input := InputEventAction.new()
	input.action = "test_map"
	var shortcut := Shortcut.new()
	shortcut.events.append(input)
	%Shortcuts.set_item_shortcut(Shortcuts.Run, shortcut, true)
	%Options.set_item_checked(Options.ConcaveSectors, Settings.settings.get("options", {}).get("highlight_concave_sectors", false))
	%Options.set_item_checked(Options.SFXZone3D, Settings.settings.get("options", {}).get("show_3d_sfx_zone", true))
	%Options.set_item_checked(Options.SFXZones2D, Settings.settings.get("options", {}).get("always_show_sfx_zones", false))
	%Options.set_item_checked(Options.MousePoint, Settings.settings.get("options", {}).get("show_mouse_point", false))
	%Options.set_item_checked(Options.ShowSky, Settings.settings.get("options", {}).get("show_sky", true))


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
		var quit_string: String = "Are you sure?"
		var nothing_to_save: bool = true
		
		var map_editor: Node = find_child("Editor")
		if map_editor:
			var map_names: Array = map_editor.get_modified_map_names()
			if len(map_names) > 0:
				quit_string += "\nThe following maps are unsaved:"
				for map_name: String in map_names:
					quit_string += "\n" + map_name
				nothing_to_save = false
		
		var dbase_editor: Node = find_child("ManageDbase")
		if dbase_editor:
			var dbase_name: String = dbase_editor.get_modified_dbase_name()
			if not dbase_name.is_empty():
				quit_string += "\nThe following dbase pack is unsaved:\n%s" % dbase_name
				nothing_to_save = false
		
		var sfx_editor: Node = find_child("ManageSFX")
		if sfx_editor:
			var sfx_name: String = sfx_editor.get_modified_sfx_name()
			if not sfx_name.is_empty():
				quit_string += "\nThe following sfx pack is unsaved:\n%s" % sfx_name
				nothing_to_save = false
		
		var das_editor: Node = find_child("ManageDAS")
		if das_editor:
			var das_name: String = das_editor.get_modified_das_name()
			if not das_name.is_empty():
				quit_string += "\nThe following das pack is unsaved:\n%s" % das_name
				nothing_to_save = false
		
		var icons_editor: Node = find_child("IconsEditor")
		if icons_editor:
			var icon_name: String = icons_editor.get_modified_icon_name()
			if not icon_name.is_empty():
				quit_string += "\nThe following icon pack is unsaved:\n%s" % icon_name
				nothing_to_save = false
		
		if Settings.settings.get("options", {}).get("always_warn_on_exit", true):
			nothing_to_save = false
		
		if nothing_to_save or await Dialog.confirm(quit_string, "Confirm Quit", false):
			Utility.deinit_shader()
			Console.print("Quitting...")
			for map_pack: Dictionary in MapPack.map_packs:
				for map: Map in map_pack.maps:
					if map.editable_map:
						map.editable_map.unload()
					map.unload()
			for map_pack: Dictionary in NormPack.map_packs:
				for map: Map in map_pack.maps:
					if map.editable_map:
						map.editable_map.unload()
					map.unload()
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
		Main.ManageMaps:
			%ManageMaps.toggle(true)
		Main.ManageDBase:
			%ManageDbase.toggle(true)
		Main.ManageSFX:
			%ManageSFX.toggle(true)
		Main.ManageDAS:
			%ManageDAS.toggle(true)
		Main.BackdropEditor:
			%BackdropEditor.toggle(true)
		Main.IconsEditor:
			%IconsEditor.toggle(true)
		Main.SaveEditor:
			%SaveEditor.toggle(true)
		Main.Normality:
			%NormalityMaps.toggle(true)
		Main.Quit:
			quit()


func _on_options_index_pressed(index: int) -> void:
	match index:
		Options.ConcaveSectors:
			var checked: bool = not %Options.is_item_checked(Options.ConcaveSectors)
			Settings.update_settings("options", {"highlight_concave_sectors": checked })
			%Options.set_item_checked(Options.ConcaveSectors, checked)
			var map_2d: Node = find_child("Map2D", true, false)
			if map_2d:
				map_2d.queue_redraw()
		Options.SFXZone3D:
			var checked: bool = not %Options.is_item_checked(Options.SFXZone3D)
			Settings.update_settings("options", {"show_3d_sfx_zone": checked })
			%Options.set_item_checked(Options.SFXZone3D, checked)
			var map_3d: Node = find_child("Map3D", true, false)
			if map_3d:
				map_3d.update_selections()
		Options.SFXZones2D:
			var checked: bool = not %Options.is_item_checked(Options.SFXZones2D)
			Settings.update_settings("options", {"always_show_sfx_zones": checked })
			%Options.set_item_checked(Options.SFXZones2D, checked)
			var map_2d: Node = find_child("Map2D", true, false)
			if map_2d:
				map_2d.redraw_sfx()
		Options.MousePoint:
			var checked: bool = not %Options.is_item_checked(Options.MousePoint)
			Settings.update_settings("options", {"show_mouse_point": checked })
			%Options.set_item_checked(Options.MousePoint, checked)
		Options.ShowSky:
			var checked: bool = not %Options.is_item_checked(Options.ShowSky)
			Settings.update_settings("options", {"show_sky": checked})
			%Options.set_item_checked(Options.ShowSky, checked)
			var editor: Node = find_child("Editor", true, false)
			if editor:
				editor.reload_skybox()
		Options.Settings:
			%Settings.toggle(true)


func _on_windows_index_pressed(index: int) -> void:
	match index:
		WindowID.Editor:
			%Editor.toggle()
		WindowID.Extras:
			%Extras.toggle()


func _on_shortcuts_menu_index_pressed(index: int) -> void:
	match index:
		Shortcuts.Run:
			%Editor.test_map()


func _on_help_index_pressed(index: int) -> void:
	match index:
		HelpID.Controls:
			%Controls.toggle()


func _on_view_3d_window_window_shown(_bool: bool) -> void:
	%Windows.set_item_checked(WindowID.Editor, _bool)


func _on_controls_window_shown(_bool: bool) -> void:
	%Help.set_item_checked(HelpID.Controls, _bool)


func _on_extras_window_shown(_bool: bool) -> void:
	%Windows.set_item_checked(WindowID.Extras, _bool)
