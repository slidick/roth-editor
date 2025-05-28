extends BaseWindow

const EYE_ICON: Texture2D = preload("uid://crb7de5pvofid")
const EYE_CLOSED_ICON: Texture2D = preload("uid://d8l1uefa8sbq")
enum MapMenu {
	Save,
	SaveAs,
	Sep1,
	EditMetadata,
	EditArray02,
	EditCommands,
	Sep2,
	EditMode,
	Sep3,
	Close,
}


var tree_root: TreeItem


func _ready() -> void:
	super._ready()
	Roth.map_loading_finished.connect(_on_map_loaded)
	Roth.map_loading_completely_finished.connect(_on_map_completely_loaded)
	tree_root = %MapsTree.create_item()
	%MapsTree.set_column_title(0, "Maps")
	%MapContainer.hide()


func test_map(full: bool) -> void:
	var map: Map = %Map2D.map
	if not map:
		return
	
	var player_position: Vector3 = %Camera3D.global_position
	player_position.y -= 1.2
	player_position *= Roth.SCALE_3D_WORLD
	var player_rotation: int = Roth.degrees_to_rotation(%Camera3D.global_rotation_degrees.y)
	var buffer: PackedByteArray = await map.compile(player_position, player_rotation)
	if buffer.is_empty():
		return
	Roth.test_run_map(buffer, map.map_info, full)


func _input(event: InputEvent) -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventMouse and %Camera3D.has_focus == true:
		%SubViewport.push_input(event)
		get_viewport().set_input_as_handled()


func load_map(map_info: Dictionary) -> void:
	for i in range(tree_root.get_child_count()):
		if map_info.name == tree_root.get_child(i).get_text(0):
			Console.print("Map loaded already")
			return
	
	var sectors_node := Node3D.new()
	sectors_node.name = "Sectors"
	for sector: Sector in Roth.get_map(map_info).sectors:
		var mesh := await sector.initialize_mesh()
		sectors_node.add_child(mesh)
	
	var faces_node := Node3D.new()
	faces_node.name = "Faces"
	for face: Face in Roth.get_map(map_info).faces:
		var mesh := await face.initialize_mesh()
		faces_node.add_child(mesh)
	
	var objects_node := Node3D.new()
	objects_node.name = "Objects"
	for object: ObjectRoth in Roth.get_map(map_info).objects:
		var mesh := object.initialize_mesh()
		objects_node.add_child(mesh)
	
	var sfx_node := Node3D.new()
	sfx_node.name = "SFX"
	for sfx: Section7_1 in Roth.get_map(map_info).sound_effects:
		var mesh := sfx.initialize_mesh()
		sfx_node.add_child(mesh)
	
	
	%Map2D.setup(Roth.get_map(map_info))
	
	var map_node := Map.MapNode3D.new()
	map_node.ref = Roth.get_map(map_info)
	map_node.map_info = map_info
	map_node.add_child(sectors_node)
	map_node.add_child(faces_node)
	map_node.add_child(objects_node)
	map_node.add_child(sfx_node)
	map_node.name = map_info.name
	map_node.visible = false
	map_node.process_mode = PROCESS_MODE_DISABLED
	%Maps.add_child(map_node)
	Roth.get_map(map_info).node = map_node
	
	var tree_child: TreeItem = tree_root.create_child()
	tree_child.set_text(0, map_info.name)
	tree_child.set_metadata(0, map_node)
	tree_child.add_button(0, EYE_CLOSED_ICON)
	
	var objects_child: TreeItem = tree_child.create_child()
	objects_child.set_text(0, "Objects")
	objects_child.set_metadata(0, objects_node)
	objects_child.add_button(0, EYE_ICON)
	
	var sfx_child: TreeItem = tree_child.create_child()
	sfx_child.set_text(0, "SFX")
	sfx_child.set_metadata(0, sfx_node)
	sfx_child.add_button(0, EYE_ICON)
	
	%NoMapLoaded.hide()
	%MapContainer.show()
	
	if tree_root.get_child_count() == 1:
		var starting_position := Vector3(
			-Roth.get_map(map_info).metadata["initPosX"],
			Roth.get_map(map_info).metadata["initPosZ"],
			Roth.get_map(map_info).metadata["initPosY"],
			
		)
		%Camera3D.global_position = starting_position / Roth.SCALE_3D_WORLD
		%Camera3D.global_position.y += 1.2
		%Camera3D.rotation_degrees = Vector3(
			0,
			Roth.rotation_to_degrees(Roth.get_map(map_info).metadata["rotation"]),
			0,
		)


func _on_map_loaded(map_info: Dictionary) -> void:
	load_map(map_info)


func _on_map_completely_loaded() -> void:
	if not visible:
		_show()
	%Maps.get_child(%Maps.get_child_count() - 1).visible = true
	tree_root.get_child(%Maps.get_child_count() - 1).set_button(0, 0, EYE_ICON)
	%Maps.get_child(%Maps.get_child_count() - 1).process_mode = PROCESS_MODE_INHERIT


func _on_sub_viewport_container_focus_entered() -> void:
	%Camera3D.has_focus = true
	%Picker.has_focus = true
	%ViewportBorder.self_modulate.a = 1.0


func _on_sub_viewport_container_focus_exited() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		return
	%Camera3D.has_focus = false
	%Picker.has_focus = false
	%ViewportBorder.self_modulate.a = 0.0


func _on_maps_tree_button_clicked(item: TreeItem, _column: int, id: int, _mouse_button_index: int) -> void:
	if item.get_metadata(0).visible:
		item.set_button(0, id, EYE_CLOSED_ICON)
		item.get_metadata(0).process_mode = PROCESS_MODE_DISABLED
	else:
		item.set_button(0, id, EYE_ICON)
		item.get_metadata(0).process_mode = PROCESS_MODE_INHERIT
	item.get_metadata(0).visible = not item.get_metadata(0).visible


func _on_sub_viewport_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		%SubViewportContainer.grab_focus()


func _on_maps_tree_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	var tree_item: TreeItem = %MapsTree.get_item_at_position(mouse_position)
	if mouse_button_index == MOUSE_BUTTON_RIGHT and tree_item.get_parent() == tree_root:
		if tree_item.get_metadata(0).map_info.custom:
			%MapsTreeMenu.set_item_disabled(MapMenu.Save, false)
		else:
			%MapsTreeMenu.set_item_disabled(MapMenu.Save, true)
		%MapsTreeMenu.popup(Rect2i(int(%MapsTree.global_position.x+mouse_position.x), int(%MapsTree.global_position.y+mouse_position.y), 0, 0))


func _on_maps_tree_menu_index_pressed(index: int) -> void:
	var selected: Array = []
	var tree_item: TreeItem = %MapsTree.get_next_selected(null)
	while tree_item:
		if tree_item.get_parent() == tree_root:
			selected.append(tree_item)
		tree_item = %MapsTree.get_next_selected(tree_item)
	match index:
		MapMenu.Save:
			if len(selected) != 1:
				await Dialog.information("Please select only one map to save.", "Info", false, Vector2(400,150))
				return
			if selected[0].get_metadata(0).map_info.custom:
				Console.print("Saving file: %s" % selected[0].get_metadata(0).map_info.name)
				var map: Map = Roth.get_map(selected[0].get_metadata(0).map_info)
				var buffer: PackedByteArray = await map.compile()
				Roth.save_custom(buffer, map.map_info)
		MapMenu.SaveAs:
			if len(selected) != 1:
				await Dialog.information("Please select only one map to save as.", "Info", false, Vector2(400,150))
				return
			var results: Array = await Dialog.input("New Map Name:", "Save As", "", "", false)
			if not results[0]:
				return
			
			var error: String = ""
			if len(results[1]) > 8:
				error = "Please limit to 8 characters"
			if results[1].contains(" "):
				error = "No spaces"
			if results[1] in Roth.maps.map(func (m: Dictionary) -> String: return m.name):
				error = "Name in use."
			
			while not error.is_empty():
				results = await Dialog.input("New Map Name:", "Save As", results[1], error, false)
				if not results[0]:
					return
				error = ""
				if len(results[1]) > 8:
					error = "Please limit to 8 characters"
				if results[1].find(" ") > 0:
					error = "No spaces"
				if results[1] in Roth.maps.map(func (m: Dictionary) -> String: return m.name):
					error = "Name in use."
			
			Console.print("Saving file as: %s" % results[1].to_upper())
			
			var map: Map = Roth.get_map(selected[0].get_metadata(0).map_info)
			var buffer: PackedByteArray = await map.compile()
			Roth.loaded_maps.erase(map.map_info.name)
			map.map_info.name = results[1].to_upper()
			map.map_info.raw = results[1].to_upper() + ".RAW"
			map.map_info.custom = true
			Roth.save_custom(buffer, map.map_info, true)
			Roth.loaded_maps[map.map_info.name] = map
			selected[0].set_text(0, results[1])
			Roth.load_roth_settings()
		MapMenu.EditMetadata:
			if len(selected) != 1:
				await Dialog.information("Please select only one map to edit.", "Info", false, Vector2(400,150))
				return
			var results: Array = await %Metadata.show_metadata(selected[0].get_metadata(0).ref.metadata)
			if results[0] == false:
				return
			selected[0].get_metadata(0).ref.metadata = results[1]
		MapMenu.EditArray02:
			if len(selected) != 1:
				await Dialog.information("Please select only one map to edit.", "Info", false, Vector2(400,150))
				return
			var results: Array = await %Array02.edit_data(selected[0].get_metadata(0).ref.section7_2)
			if results[0] == false:
				return
			selected[0].get_metadata(0).ref.section7_2 = results[1]
		MapMenu.EditCommands:
			if len(selected) != 1:
				await Dialog.information("Please select only one map to edit.", "Info", false, Vector2(400,150))
				return
			%CommandEditor.edit_data(selected[0].get_metadata(0).ref)
		MapMenu.EditMode:
			if len(selected) != 1:
				await Dialog.information("Please select only one map to edit.", "Info", false, Vector2(400,150))
				return
			%Map2D.setup(Roth.get_map(selected[0].get_metadata(0).ref.map_info))
		MapMenu.Close:
			for item: TreeItem in selected:
				if await Dialog.confirm("Close map?\n %s" % item.get_metadata(0).map_info.name, "Confirm Close", false):
					item.get_metadata(0).queue_free()
					Roth.loaded_maps.erase(item.get_metadata(0).map_info.name)
					for child_item: TreeItem in item.get_children():
						child_item.free()
					%Map2D.close_map(item.get_metadata(0).map_info)
					item.free()


func _on_search_text_submitted(search_text: String) -> void:
	if search_text.is_empty():
		%Picker.deselect()
		return
	
	var type: String = %SearchOption.get_item_text(%SearchOption.selected)
	select_face(int(search_text), type)


func select_face(index: int, type: String, p_map_name: String = "") -> void:
	var maps_available := []
	
	for i in range(tree_root.get_child_count()):
		if p_map_name.is_empty():
			if tree_root.get_child(i).get_metadata(0).visible:
				maps_available.append(tree_root.get_child(i).get_metadata(0))
		else:
			if tree_root.get_child(i).get_text(0) == p_map_name:
				maps_available.append(tree_root.get_child(i).get_metadata(0))
	
	for map_node: Node3D in maps_available:
		match type:
			"Sector":
				for sector: Node3D in map_node.get_node("Sectors").get_children():
					if index == sector.ref.index:
						%Picker.select(sector)
			"Sector ID":
				for sector: Node3D in map_node.get_node("Sectors").get_children():
					if index == sector.ref.data.floorTriggerID:
						%Picker.select(sector)
			"Face":
				for face: Node3D in map_node.get_node("Faces").get_children():
					if index == face.ref.index:
						if face.get_child_count() > 0:
							%Picker.select(face.get_child(0))
			"Face ID":
				for face: Node3D in map_node.get_node("Faces").get_children():
					if ("additionalMetadata" in face.ref.texture_data
						and index == face.ref.texture_data.additionalMetadata.unk0x0C
					):
						if face.get_child_count() > 0:
							%Picker.select(face.get_child(0))
			"Object":
				for object: Node3D in map_node.get_node("Objects").get_children():
					if index == object.ref.index:
						%Picker.select(object)
			"SFX":
				for sfx: Node3D in map_node.get_node("SFX").get_children():
					if index == sfx.ref.index:
						%Picker.select(sfx)

func get_face(index: int, type: String, map_info: Dictionary) -> Variant:
	var map_node: Node3D
	
	for i in range(tree_root.get_child_count()):
		if tree_root.get_child(i).get_text(0) == map_info.name:
			map_node = tree_root.get_child(i).get_metadata(0)
	
	if not map_node:
		return null
	
	match type:
		"Sector":
			for sector: Node3D in map_node.get_node("Sectors").get_children():
				if index == sector.ref.index:
					return sector.ref
		"Face":
			for face: Node3D in map_node.get_node("Faces").get_children():
				if index == face.ref.index:
					return face.ref
		"Object":
			for object: Node3D in map_node.get_node("Objects").get_children():
				if index == object.ref.index:
					return object.ref
		"SFX":
			for sfx: Node3D in map_node.get_node("SFX").get_children():
				if index == sfx.ref.index:
					return sfx.ref
	return null


func _on_search_result_activated(search_result: Dictionary) -> void:
	await Roth.load_maps([search_result.map_info])
	%Search.text = str(search_result.index)
	for i in range(%SearchOption.item_count):
		if %SearchOption.get_item_text(i) == search_result.type:
			%SearchOption.select(i)
	select_face(search_result.index, search_result.type, search_result.map_info.name)


func _on_sub_viewport_container_mouse_entered() -> void:
	%SubViewportContainer.grab_focus()


func _on_sub_viewport_container_mouse_exited() -> void:
	%SubViewportContainer.release_focus()
