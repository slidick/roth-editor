extends BaseWindow


func _ready() -> void:
	super._ready()
	Roth.settings_loaded.connect(_on_settings_loaded)
	%MapTree.set_column_title(0, "Maps")
	%MapTree.create_item()


func _show() -> void:
	super._show()
	%MapTree.grab_focus()
	%MapTree.get_root().select(0)


func _hide() -> void:
	super._hide()
	clear()


func clear() -> void:
	%MapTree.deselect_all()
	%Map.clear()
	%Sectors.text = ""
	%Faces.text = ""
	%Vertices.text = ""
	%Objects.text = ""
	%MapName.text = ""
	%DASFile.text = ""
	%Commands.text = ""
	%ExportButton.disabled = true
	%RunButton.disabled = true
	%OpenButton.disabled = true
	%ChangeDASButton.hide()


func cancel() -> void:
	_hide()


func open() -> void:
	var maps: Array = get_selected_maps()
	if maps.is_empty():
		return
	for map: Map in maps:
		if "invalid" in map.map_info.das_info:
			Dialog.information("Map has invalid das file!", "Error", false, Vector2(300,150))
			return
	Roth.load_maps(maps)
	_hide()


func get_selected_maps() -> Array:
	var maps: Array = []
	var tree_item: TreeItem = %MapTree.get_next_selected(null)
	while tree_item:
		var map_info: Variant = tree_item.get_metadata(0)
		if map_info:
			maps.append(map_info)
		tree_item = %MapTree.get_next_selected(tree_item)
	return maps


func _on_settings_loaded() -> void:
	clear()
	%MapTree.clear()
	%MapTree.create_item()
	for map: Map in Roth.maps:
		if "vanilla" not in map.map_info:
			var tree_item: TreeItem = %MapTree.get_root().create_child()
			tree_item.set_text(0, map.map_info.name)
			tree_item.set_metadata(0, map)
	for map: Map in Roth.maps:
		if "vanilla" in map.map_info:
			var tree_item: TreeItem = %MapTree.get_root().create_child()
			tree_item.set_text(0, map.map_info.name)
			tree_item.set_metadata(0, map)
	if not Roth.install_directory.is_empty():
		%NewMapButton.disabled = false
		%ImportButton.disabled = false


func _on_cancel_button_pressed() -> void:
	cancel()


func _on_open_button_pressed() -> void:
	open()


func _on_map_tree_cell_selected() -> void:
	var map: Map = %MapTree.get_selected().get_metadata(0)
	map.load_map()
	%Map.setup(map.sectors)
	%Sectors.text = "%s" % len(map.sectors)
	%Faces.text = "%s" % len(map.faces)
	%Vertices.text = "%s" % map.vertices_count
	%Objects.text = "%s" % len(map.objects)
	%MapName.text = "%s" % map.map_info.name
	%DASFile.text = "%s" % map.map_info.das_info.name
	%Commands.text = "%s" % len(map.commands_section.allCommands)
	if "invalid" in map.map_info.das_info:
		%ExportButton.disabled = true
		%RunButton.disabled = true
		%OpenButton.disabled = true
	else:
		%ExportButton.disabled = false
		%RunButton.disabled = false
		%OpenButton.disabled = false
	if "vanilla" in map.map_info:
		%ChangeDASButton.hide()
	else:
		%ChangeDASButton.show()


func _on_map_tree_item_activated() -> void:
	open()


func _on_map_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			var maps: Array = []
			var tree_item: TreeItem = %MapTree.get_next_selected(null)
			var map: Map
			while tree_item:
				map = tree_item.get_metadata(0)
				if map and "vanilla" not in map.map_info:
					maps.append(tree_item)
				tree_item = %MapTree.get_next_selected(tree_item)
			if len(maps) > 1:
				await Dialog.information("Please select only one map to rename.", "Info", false, Vector2(400,150))
				return
			
			tree_item = maps[0]
			map = maps[0].get_metadata(0)
			
			var new_map_name := await Roth.query_for_map_name("Rename %s" % map.map_info.name)
			if new_map_name.is_empty() or new_map_name == map.map_info.name:
				return
			map.rename_map(new_map_name)
			tree_item.set_text(0, new_map_name)
			
		1:
			var maps: Array = []
			var maps_string: String = ""
			var tree_item: TreeItem = %MapTree.get_next_selected(null)
			while tree_item:
				var map: Map = tree_item.get_metadata(0)
				if map and "vanilla" not in map.map_info:
					maps.append(map)
					maps_string += "%s\n" % map.map_info.name
				tree_item = %MapTree.get_next_selected(tree_item)
			var results: Array = await Dialog.confirm_additional("Are you sure you wish to delete the following maps?\n%s" % maps_string.trim_suffix("\n"), "Confirm Deletion", "Delete backup saves (CANNOT BE UNDONE)", false)
			if results[0]:
				for map: Map in maps:
					map.delete_map(results[1])
				_on_settings_loaded()
		2:
			var maps: Array = get_selected_maps()
			if len(maps) > 1:
				await Dialog.information("Only duplicate one at a time", "Info", false, Vector2(200,150))
				return
			var map: Map = maps[0]
			var new_map_name := await Roth.query_for_map_name("Duplicate %s" % map.map_info.name)
			if new_map_name.is_empty():
				return
			map.duplicate_map(new_map_name)
			_on_settings_loaded()


func _on_map_tree_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			var tree_item: TreeItem = %MapTree.get_item_at_position(mouse_position)
			if tree_item.get_metadata(0):
				if "vanilla" not in tree_item.get_metadata(0).map_info:
					%MapPopupMenu.set_item_disabled(0, false)
					%MapPopupMenu.set_item_disabled(1, false)
				else:
					%MapPopupMenu.set_item_disabled(0, true)
					%MapPopupMenu.set_item_disabled(1, true)
				%MapPopupMenu.popup(Rect2i(int(mouse_position.x + %MapTree.global_position.x), int(mouse_position.y + %MapTree.global_position.y), 0, 0))


func _on_run_button_pressed() -> void:
	var maps: Array = []
	if %MapTree.get_selected().get_metadata(0):
		maps.append(%MapTree.get_selected().get_metadata(0))
	var tree_item: TreeItem = %MapTree.get_next_selected(null)
	while tree_item:
		var map: Variant = tree_item.get_metadata(0)
		if map and map not in maps:
			maps.append(map)
		tree_item = %MapTree.get_next_selected(tree_item)
	if len(maps) == 0:
		return
	Roth.test_run_maps(maps)


func _on_new_map_button_pressed() -> void:
	%NewMap.toggle()


func _on_new_map_map_created(map: Map) -> void:
	_on_settings_loaded()
	%MapTree.deselect_all()
	for tree_item: TreeItem in %MapTree.get_root().get_children():
		if tree_item.get_metadata(0) == map:
			tree_item.select(0)
			_on_map_tree_cell_selected()


func _on_export_button_pressed() -> void:
	var maps := get_selected_maps()
	if maps.is_empty():
		return
	%Export.export_maps(maps)


func _on_import_button_pressed() -> void:
	%Import.import_map()


func _on_change_das_button_pressed() -> void:
	var map: Map = %MapTree.get_selected().get_metadata(0)
	var new_das: Dictionary = await %ChangeDAS.change_das(map.map_info.das_info)
	if new_das.is_empty():
		return
	map.map_info.das_info = new_das
	map.save_metadata()
	%DASFile.text = new_das.name
	%ExportButton.disabled = false
	%RunButton.disabled = false
	%OpenButton.disabled = false
