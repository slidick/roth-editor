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
	%MapTree.deselect_all()
	%Map.clear()


func cancel() -> void:
	_hide()


func open() -> void:
	var maps: Array = []
	var tree_item: TreeItem = %MapTree.get_next_selected(null)
	while tree_item:
		var metadata: Variant = tree_item.get_metadata(0)
		if metadata:
			maps.append(tree_item.get_metadata(0))
		tree_item = %MapTree.get_next_selected(tree_item)
	if maps.is_empty():
		return
	print(maps)
	Roth.load_maps(maps)


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
