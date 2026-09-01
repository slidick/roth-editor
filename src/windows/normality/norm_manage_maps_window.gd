extends BaseWindow


func _ready() -> void:
	super._ready()
	Normality.settings_updated.connect(_on_settings_updated)
	Roth.map_closed.connect(_on_map_closed)
	%ExportButton.disabled = true
	%NewMapButton.disabled = true
	%RunButton.disabled = true
	%EditMapPackButton.disabled = true
	%ReorderMapsCheckBox.disabled = true


func _on_settings_updated() -> void:
	var selected_map_pack: Dictionary = get_selected_map_pack()
	var selected_maps: Array = get_selected_maps()
	clear()
	%MapPackList.clear()
	%MapTree.clear()
	for map_pack: Dictionary in NormPack.map_packs:
		if "vanilla" in map_pack:
			var idx: int = %MapPackList.add_item(map_pack.name)
			%MapPackList.set_item_metadata(idx, map_pack)
	for map_pack: Dictionary in NormPack.map_packs:
		if "vanilla" not in map_pack and "unassigned" not in map_pack:
			var idx: int = %MapPackList.add_item(map_pack.name)
			%MapPackList.set_item_metadata(idx, map_pack)
	for map_pack: Dictionary in NormPack.map_packs:
		if "unassigned" in map_pack:
			var idx: int = %MapPackList.add_item(map_pack.name)
			%MapPackList.set_item_metadata(idx, map_pack)
	if not selected_map_pack.is_empty():
		select_map_pack(selected_map_pack)
	elif %MapPackList.item_count > 0:
		%MapPackList.select(0)
		_on_map_pack_list_item_selected(0)
	if not selected_maps.is_empty():
		select_maps(selected_maps)


func clear() -> void:
	%MapTree.deselect_all()
	%MapPreview.clear()
	%OpenButton.disabled = true


func open() -> void:
	var maps: Array = get_selected_maps()
	if maps.is_empty():
		return
	for map: Map in maps:
		if "invalid" in map.map_info.das_info:
			Dialog.information("Map has invalid das file!", "Error", false, Vector2(300,150))
			return
	Normality.load_maps(maps)
	_hide()


func get_selected_map_pack() -> Dictionary:
	if len(%MapPackList.get_selected_items()) > 0:
		return %MapPackList.get_item_metadata(%MapPackList.get_selected_items()[0])
	return {}


func get_selected_maps() -> Array:
	var maps: Array = []
	var tree_item: TreeItem = %MapTree.get_next_selected(null)
	while tree_item:
		var map_info: Variant = tree_item.get_metadata(0)
		if map_info:
			maps.append(map_info)
		tree_item = %MapTree.get_next_selected(tree_item)
	return maps


func _on_map_pack_list_item_selected(index: int) -> void:
	clear()
	var map_pack: Dictionary = %MapPackList.get_item_metadata(index)
	%MapTree.clear()
	%MapTree.create_item()
	
	var maps: Array = map_pack.maps
	
	if "unassigned" in map_pack:
		maps.sort_custom(func (m1: Map, m2: Map) -> bool: return m1.map_info.name < m2.map_info.name)
	
	for map: Map in maps:
		var tree_item: TreeItem = %MapTree.get_root().create_child()
		tree_item.set_text(0, map.map_info.name)
		tree_item.set_metadata(0, map)
	
	if Normality.current_installation:
		%NewMapButton.disabled = false
		%ExportButton.disabled = false
		%RunButton.disabled = false
		%EditMapPackButton.disabled = false
	
	if "vanilla" in map_pack or "unassigned" in map_pack:
		%ReorderMapsCheckBox.disabled = true
		%ReorderMapsCheckBox.button_pressed = false
	else:
		%ReorderMapsCheckBox.disabled = false
		%ReorderMapsCheckBox.button_pressed = false
	#%DBaseLabel.text = map_pack.dbase_info.name
	#%DAS2Label.text = map_pack.das2_info.name
	#%SFXLabel.text = map_pack.sfx_info.name
	#%BackdropLabel.text = map_pack.backdrop_info.name
	#%IconsLabel.text = map_pack.icon_info.name


func _on_open_button_pressed() -> void:
	open()


func _on_map_tree_cell_selected() -> void:
	if not %MapTree.get_selected():
		return
	var map: Map = %MapTree.get_selected().get_metadata(0)
	%MapPreview.setup(map)
	if "invalid" in map.map_info.das_info:
		%RunButton.disabled = true
		%OpenButton.disabled = true
	else:
		%RunButton.disabled = false
		%OpenButton.disabled = false


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
				maps = maps.map(func (item: TreeItem) -> Map: return item.get_metadata(0))
				var results: Array = await %ModifyMap.modify_maps(maps, %ModifyMap.Modification.MOVE, true)
				if results[0]:
					select_maps(maps)
			else:
				tree_item = maps[0]
				map = maps[0].get_metadata(0)
				
				var results: Array = await %ModifyMap.modify_maps([map], %ModifyMap.Modification.RENAME, true)
				
				if results[1]:
					select_maps([map])
				elif results[0]:
					tree_item.set_text(0, results[2])
		
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
				tree_item = %MapTree.get_root().get_first_child()
				while tree_item:
					if tree_item.get_metadata(0) in maps:
						tree_item.free.call_deferred()
					tree_item = tree_item.get_next()
				clear()
		2:
			var maps: Array = get_selected_maps()
			if len(maps) > 1:
				var results: Array = await %ModifyMap.modify_maps(maps, %ModifyMap.Modification.DUPLICATE_MULTIPLE, true)
				if results[0]:
					select_maps(results[1])
			else:
				var map: Map = maps[0]
				var results: Array = await %ModifyMap.modify_maps([map], %ModifyMap.Modification.DUPLICATE, true)
				if results[0]:
					select_maps([results[1]])
		3:
			var maps: Array = get_selected_maps()
			if len(maps) == 1:
				var new_map: Map = await %PreviousVersions.previous_versions(maps[0])
				if new_map:
					var tree_item: TreeItem = %MapTree.get_next_selected(null)
					tree_item.set_metadata(0, new_map)
					_on_map_tree_cell_selected()


func _on_map_tree_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			var tree_item: TreeItem = %MapTree.get_item_at_position(mouse_position)
			if tree_item.get_metadata(0):
				if "vanilla" not in tree_item.get_metadata(0).map_info:
					%MapPopupMenu.set_item_disabled(0, false)
					%MapPopupMenu.set_item_disabled(1, false)
					if len(get_selected_maps()) > 1:
						%MapPopupMenu.set_item_disabled(3, true)
					else:
						%MapPopupMenu.set_item_disabled(3, false)
				else:
					%MapPopupMenu.set_item_disabled(0, true)
					%MapPopupMenu.set_item_disabled(1, true)
					%MapPopupMenu.set_item_disabled(3, true)
				if len(get_selected_maps()) > 1:
					%MapPopupMenu.set_item_text(0, "Move Maps")
					%MapPopupMenu.set_item_text(1, "Delete Maps")
					%MapPopupMenu.set_item_text(2, "Duplicate Maps")
				else:
					%MapPopupMenu.set_item_text(0, "Rename/Move Map")
					%MapPopupMenu.set_item_text(1, "Delete Map")
					%MapPopupMenu.set_item_text(2, "Duplicate Map")
				%MapPopupMenu.popup(Rect2i(int(mouse_position.x + %MapTree.global_position.x), int(mouse_position.y + %MapTree.global_position.y), 0, 0))


func _on_run_button_pressed() -> void:
	var map_pack: Dictionary = %MapPackList.get_item_metadata(%MapPackList.get_selected_items()[0])
	var tree_item: TreeItem = %MapTree.get_selected()
	Normality.test_run_maps(map_pack, tree_item.get_metadata(0) if tree_item else null)


func _on_new_map_button_pressed() -> void:
	var map: Map = await %NewMap.new_map(%MapPackList.get_item_metadata(%MapPackList.get_selected_items()[0]), NormPack.das_packs, NormPack.map_packs)
	if map:
		select_maps([map])


func select_map_pack(map_pack: Dictionary) -> void:
	for i in range(%MapPackList.item_count):
		if %MapPackList.get_item_metadata(i) == map_pack:
			%MapPackList.select(i)
			_on_map_pack_list_item_selected(i)


func select_maps(maps: Array) -> void:
	if len(maps) == 0:
		return
	var map: Map = maps[0]
	select_map_pack(map.map_info.map_pack)
	%MapTree.deselect_all()
	for tree_item: TreeItem in %MapTree.get_root().get_children():
		if tree_item.get_metadata(0) in maps:
			tree_item.select(0)
			_on_map_tree_cell_selected()


func _on_export_button_pressed() -> void:
	var map_pack: Dictionary = %MapPackList.get_item_metadata(%MapPackList.get_selected_items()[0])
	var changed: bool = await %MapPack.map_pack(%MapPack.Type.EXPORT, true, map_pack)
	if changed:
		%MapPackList.set_item_text(%MapPackList.get_selected_items()[0], map_pack.name)
		#%DBaseLabel.text = map_pack.dbase_info.name
		#%DAS2Label.text = map_pack.das2_info.name
		#%SFXLabel.text = map_pack.sfx_info.name
		#%BackdropLabel.text = map_pack.backdrop_info.name
		#%IconsLabel.text = map_pack.icon_info.name


func _on_import_button_pressed() -> void:
	%Import.import_map(true)


func _on_change_das_button_pressed() -> void:
	var map: Map = %MapTree.get_selected().get_metadata(0)
	var new_das: Dictionary = await %ChangeDAS.change_das(map.map_info.das_info, NormPack.das_packs)
	if new_das.is_empty():
		return
	map.map_info.das_info = new_das
	map.save_metadata()
	%MapPreview.set_das_name(new_das.name)
	%RunButton.disabled = false
	%OpenButton.disabled = false


func _on_edit_map_pack_button_pressed() -> void:
	var map_pack: Dictionary = %MapPackList.get_item_metadata(%MapPackList.get_selected_items()[0])
	var changed: bool = await %MapPack.map_pack(%MapPack.Type.EDIT, true, map_pack)
	if changed:
		%MapPackList.set_item_text(%MapPackList.get_selected_items()[0], map_pack.name)
		#%DBaseLabel.text = map_pack.dbase_info.name
		#%DAS2Label.text = map_pack.das2_info.name
		#%SFXLabel.text = map_pack.sfx_info.name
		#%BackdropLabel.text = map_pack.backdrop_info.name
		#%IconsLabel.text = map_pack.icon_info.name


func _on_new_map_pack_button_pressed() -> void:
	var map_pack: Dictionary = await %MapPack.map_pack(%MapPack.Type.CREATE, true)
	if map_pack:
		var idx: int = %MapPackList.add_item(map_pack.name)
		%MapPackList.set_item_metadata(idx, map_pack)
		%MapPackList.move_item(idx, idx-1)
		#%DBaseLabel.text = map_pack.dbase_info.name
		#%DAS2Label.text = map_pack.das2_info.name
		#%SFXLabel.text = map_pack.sfx_info.name
		#%BackdropLabel.text = map_pack.backdrop_info.name
		#%IconsLabel.text = map_pack.icon_info.name
		%MapPackList.select(idx-1)
		_on_map_pack_list_item_selected(idx-1)


func _on_reorder_maps_check_box_toggled(toggled_on: bool) -> void:
	%MapTree.reorder_enabled = toggled_on


func _on_map_tree_item_moved() -> void:
	var map_pack: Dictionary = %MapPackList.get_item_metadata(%MapPackList.get_selected_items()[0])
	var new_map_order: Array = []
	var tree_item: TreeItem = %MapTree.get_root().get_first_child()
	while tree_item:
		var map: Map = tree_item.get_metadata(0)
		new_map_order.append(map)
		tree_item = tree_item.get_next()
	map_pack.maps = new_map_order
	NormPack.save(map_pack)


func _on_map_pack_menu_index_pressed(index: int) -> void:
	match index:
		0:
			var map_pack: Dictionary = %MapPackList.get_item_metadata(%MapPackList.get_selected_items()[0])
			var results: Array = await Dialog.confirm_additional("Deleting map pack\n%s" % map_pack.name, "Confirm Delete", "Also delete maps and backups!")
			if results[0]:
				NormPack.delete(map_pack, results[1])
				for i in range(%MapPackList.item_count):
					if %MapPackList.get_item_metadata(i) == map_pack:
						%MapPackList.remove_item(i)
						break
				clear()
				%MapTree.clear()
				#%DBaseLabel.text = ""
				#%DAS2Label.text = ""
				#%SFXLabel.text = ""
				#%BackdropLabel.text = ""
				#%IconsLabel.text = ""
				%ExportButton.disabled = true
				%NewMapButton.disabled = true
				%RunButton.disabled = true
				%EditMapPackButton.disabled = true
				%ReorderMapsCheckBox.disabled = true


func _on_map_pack_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			var map_pack: Dictionary = %MapPackList.get_item_metadata(index)
			if "vanilla" in map_pack or "unassigned" in map_pack:
				%MapPackMenu.set_item_disabled(0, true)
			else:
				%MapPackMenu.set_item_disabled(0, false)
			%MapPackMenu.popup(Rect2(%MapPackList.global_position+at_position, Vector2.ZERO))


func _on_map_closed(_map: Map) -> void:
	_on_map_tree_cell_selected()


func _on_view_trash_button_pressed() -> void:
	%Trash.view_trash(Normality.NORMALITY_CUSTOM_MAP_DIRECTORY)
