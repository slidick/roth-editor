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


func cancel() -> void:
	_hide()


func open() -> void:
	var maps: Array = get_selected_maps()
	if maps.is_empty():
		return
	Roth.load_maps(maps)


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
	%MapTree.clear()
	%MapTree.create_item()
	for map_info:Dictionary in Roth.maps:
		if map_info.custom:
			var tree_item: TreeItem = %MapTree.get_root().create_child()
			tree_item.set_text(0, map_info.name)
			tree_item.set_metadata(0, map_info)
	for map_info:Dictionary in Roth.maps:
		if not map_info.custom:
			var tree_item: TreeItem = %MapTree.get_root().create_child()
			tree_item.set_text(0, map_info.name)
			tree_item.set_metadata(0, map_info)


func _on_cancel_button_pressed() -> void:
	cancel()


func _on_open_button_pressed() -> void:
	open()
	cancel()


func _on_map_tree_cell_selected() -> void:
	var map_info: Dictionary = %MapTree.get_selected().get_metadata(0)
	var map: Map = Roth.get_map(map_info)
	%Map.setup(map.sectors)
	%Sectors.text = "%s" % len(map.sectors)
	%Faces.text = "%s" % len(map.faces)
	%Vertices.text = "%s" % map.vertices_count
	%Objects.text = "%s" % len(map.objects)
	%MapName.text = "%s" % map_info.name
	%DASFile.text = "%s" % map_info.das


func _on_map_tree_item_activated() -> void:
	Roth.load_maps([%MapTree.get_selected().get_metadata(0)])
	cancel()


func _on_map_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			var maps: Array = []
			var maps_string: String = ""
			var tree_item: TreeItem = %MapTree.get_next_selected(null)
			while tree_item:
				var map_info: Variant = tree_item.get_metadata(0)
				if map_info and map_info.custom:
					maps.append(map_info)
					maps_string += "%s\n" % map_info.name
				tree_item = %MapTree.get_next_selected(tree_item)
			
			if await Dialog.confirm("Are you sure you wish to delete the following maps?\n%s" % maps_string, "Confirm Deletion", false):
				Roth.delete_maps(maps)
				clear()


func _on_map_tree_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			var tree_item: TreeItem = %MapTree.get_item_at_position(mouse_position)
			if tree_item.get_metadata(0):
				if tree_item.get_metadata(0).custom:
					%MapPopupMenu.set_item_disabled(0, false)
				else:
					%MapPopupMenu.set_item_disabled(0, true)
				%MapPopupMenu.popup(Rect2i(int(mouse_position.x + %MapTree.global_position.x), int(mouse_position.y + %MapTree.global_position.y), 0, 0))


func _on_run_button_pressed() -> void:
	var maps := get_selected_maps()
	if len(maps) != 1:
		Dialog.information("Select a single map to run.", "Error", true, Vector2(400, 150), "Okay")
		return
	Roth.run_map(maps[0])
