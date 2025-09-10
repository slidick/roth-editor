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
var context_collision: Dictionary
var previous_search: String
var search_count: int = 0
var copied_object_data: ObjectRoth
var first_load: bool = false

func _ready() -> void:
	super._ready()
	Roth.map_loading_finished.connect(_on_map_loaded)
	Roth.map_loading_completely_finished.connect(_on_map_completely_loaded)
	Roth.close_map.connect(close_map)
	tree_root = %MapsTree.create_item()
	%MapsTree.set_column_title(0, "Maps")
	%MapContainer.hide()
	%EditorHeader.hide()


func test_map() -> void:
	var map: Map = %Map2D.map
	if not map:
		return
	
	var maps: Array = []
	maps.append(map)
	
	for tree_item: TreeItem in %MapsTree.get_root().get_children():
		if tree_item.get_metadata(0).ref not in maps:
			maps.append(tree_item.get_metadata(0).ref)
	
	
	var player_position: Vector3 = %Camera3D.global_position
	player_position.y -= 1.2
	player_position *= Roth.SCALE_3D_WORLD
	var player_rotation: int = Roth.degrees_to_rotation(%Camera3D.global_rotation_degrees.y)
	
	var player_data: Dictionary = {
		"position": player_position,
		"rotation": player_rotation,
	}
	
	Roth.test_run_maps(maps, player_data)


func _input(event: InputEvent) -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventMouse and %Camera3D.has_focus == true:
		%SubViewport.push_input(event)
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("move_object_to_ceiling"):
		if %EditObjectContainer.current_object:
			var height: int = %EditObjectContainer.current_object.sector.get_ref().data.ceilingHeight
			%EditObjectContainer.current_object.data.posZ = height
			%EditObjectContainer.current_object.initialize_mesh()
			await get_tree().process_frame
			%Picker.select(%EditObjectContainer.current_object.node)
	if event.is_action_pressed("move_object_to_floor"):
		if %EditObjectContainer.current_object:
			var height: int = %EditObjectContainer.current_object.sector.get_ref().data.floorHeight
			%EditObjectContainer.current_object.data.posZ = height
			%EditObjectContainer.current_object.initialize_mesh()
			await get_tree().process_frame
			%Picker.select(%EditObjectContainer.current_object.node)
	if event.is_action_pressed("open_3d_context_menu"):
		var viewport := %Picker.get_viewport()
		var mouse_position := viewport.get_mouse_position()
		var viewport_size: Vector2i = viewport.size
		if viewport.get("content_scale_size"):
			viewport_size = viewport.content_scale_size
		if ((mouse_position.x < 0 or
				mouse_position.y < 0 or
				mouse_position.x > viewport_size.x or
				mouse_position.y > viewport_size.y) and 
				Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
		):
			return
		var camera := viewport.get_camera_3d()
		var origin_position: Vector2 = mouse_position
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			origin_position = viewport_size / 2
		var origin := camera.project_ray_origin(origin_position)
		var direction := camera.project_ray_normal(origin_position)
		var ray_length := camera.far
		var end := origin + direction * ray_length
		var space_state: PhysicsDirectSpaceState3D = %Picker.get_world_3d().direct_space_state
		var query := PhysicsRayQueryParameters3D.create(origin, end)
		var result: Dictionary = space_state.intersect_ray(query)
		if result:
			if (result.collider.get_parent().ref is Face
				or result.collider.get_parent().ref is Sector
			):
				context_collision = result
				var pos: Vector2 = get_viewport().get_mouse_position()
				if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
					pos = %SubViewportContainer.global_position
					pos += %SubViewportContainer.size / 2
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
					get_viewport().warp_mouse(pos)
					
				%"3DContextMenu".popup(Rect2i(int(pos.x), int(pos.y), 0, 0))
			if result.collider.get_parent().ref is ObjectRoth:
				context_collision = result
				var pos: Vector2 = get_viewport().get_mouse_position()
				if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
					pos = %SubViewportContainer.global_position
					pos += %SubViewportContainer.size / 2
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
					get_viewport().warp_mouse(pos)
				%"3DObjectContextMenu".popup(Rect2i(int(pos.x), int(pos.y), 0, 0))


func load_map(map_info: Dictionary) -> void:
	for i in range(tree_root.get_child_count()):
		if map_info.name == tree_root.get_child(i).get_text(0):
			Console.print("Map loaded already")
			return
	
	var map: Map = Roth.get_map(map_info)
	if not map:
		return
	
	var sectors_node := Node3D.new()
	sectors_node.name = "Sectors"
	for sector: Sector in map.sectors:
		var mesh := await sector.initialize_mesh()
		sectors_node.add_child(mesh)
	
	var faces_node := Node3D.new()
	faces_node.name = "Faces"
	for face: Face in map.faces:
		var mesh := await face.initialize_mesh()
		faces_node.add_child(mesh)
	
	var objects_node := Node3D.new()
	objects_node.name = "Objects"
	for object: ObjectRoth in map.objects:
		var mesh := object.initialize_mesh()
		objects_node.add_child(mesh)
	
	var sfx_node := Node3D.new()
	sfx_node.name = "SFX"
	for sfx: Section7_1 in map.sound_effects:
		var mesh := sfx.initialize_mesh()
		sfx_node.add_child(mesh)
	
	
	%Map2D.setup(map)
	
	var map_node := Map.MapNode3D.new()
	map_node.ref = map
	map_node.map_info = map.map_info
	map_node.add_child(sectors_node)
	map_node.add_child(faces_node)
	map_node.add_child(objects_node)
	map_node.add_child(sfx_node)
	map_node.name = map_info.name
	map_node.visible = false
	map_node.process_mode = PROCESS_MODE_DISABLED
	%Maps.add_child(map_node)
	map.node = map_node
	
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
	%EditorHeader.show()
	
	
	if tree_root.get_child_count() == 1:
		first_load = true


func _on_map_loaded(map_info: Dictionary) -> void:
	load_map(map_info)


func _on_map_completely_loaded() -> void:
	if not visible:
		_show()
	%Maps.get_child(%Maps.get_child_count() - 1).visible = true
	tree_root.get_child(%Maps.get_child_count() - 1).set_button(0, 0, EYE_ICON)
	%Maps.get_child(%Maps.get_child_count() - 1).process_mode = PROCESS_MODE_INHERIT
	
	if first_load:
		first_load = false
		var starting_position := Vector3(
			-%Maps.get_child(%Maps.get_child_count() - 1).ref.metadata["initPosX"],
			%Maps.get_child(%Maps.get_child_count() - 1).ref.metadata["initPosZ"],
			%Maps.get_child(%Maps.get_child_count() - 1).ref.metadata["initPosY"],
			
		)
		%Camera3D.global_position = starting_position / Roth.SCALE_3D_WORLD
		%Camera3D.global_position.y += 1.2
		%Camera3D.rotation_degrees = Vector3(
			0,
			Roth.rotation_to_degrees(%Maps.get_child(%Maps.get_child_count() - 1).ref.metadata["rotation"]),
			0,
		)


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
		if not "vanilla" in tree_item.get_metadata(0).map_info:
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
			if "vanilla" not in selected[0].get_metadata(0).map_info:
				Console.print("Saving file: %s" % selected[0].get_metadata(0).map_info.name)
				var map: Map = Roth.get_map(selected[0].get_metadata(0).map_info)
				Roth.save_map(map)
		MapMenu.SaveAs:
			if len(selected) != 1:
				await Dialog.information("Please select only one map to save as.", "Info", false, Vector2(400,150))
				return
			
			var new_map_name: String = await Roth.query_for_map_name("Save As")
			if new_map_name.is_empty():
				return
			
			Console.print("Saving file as: %s" % new_map_name)
			
			var map: Map = Roth.get_map(selected[0].get_metadata(0).map_info)
			Roth.loaded_maps.erase(map.map_info.name)
			Roth.maps.erase(map.map_info)
			Roth.maps.append(map.map_info.duplicate())
			map.map_info.name = new_map_name
			map.map_info.filepath = Roth.ROTH_CUSTOM_MAP_DIRECTORY.path_join(new_map_name + ".RAW")
			map.map_info.erase("vanilla")
			Roth.save_map(map)
			Roth.loaded_maps[map.map_info.name] = map
			selected[0].set_text(0, new_map_name)
			map.name_changed.emit(new_map_name)
			#Roth.load_roth_settings()
			Roth.settings_loaded.emit()
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
			%"Command Editor".load_command_editor(selected[0].get_metadata(0).ref)
			%TabBar.current_tab = 1
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
					%"Command Editor".close(item.get_metadata(0).map_info.name)
					Roth.reload_map_info(item.get_metadata(0).map_info)
					item.free()


func close_map(map_info: Dictionary) -> void:
	for tree_item: TreeItem in %MapsTree.get_root().get_children():
		if tree_item.get_parent() == tree_root and tree_item.get_metadata(0).ref.map_info == map_info:
			tree_item.get_metadata(0).queue_free()
			Roth.loaded_maps.erase(tree_item.get_metadata(0).map_info.name)
			for child_item: TreeItem in tree_item.get_children():
				child_item.free()
			%Map2D.close_map(tree_item.get_metadata(0).map_info)
			%"Command Editor".close(tree_item.get_metadata(0).map_info.name)
			Roth.reload_map_info(tree_item.get_metadata(0).map_info)
			tree_item.free()


func _on_search_text_submitted(search_text: String) -> void:
	if search_text.is_empty():
		%Picker.deselect()
		return
	
	if search_text == previous_search:
		search_count += 1
	else:
		search_count = 0
	previous_search = search_text
	
	var type: String = %SearchOption.get_item_text(%SearchOption.selected)
	select_face(int(search_text), type, "", search_count)


func _on_search_option_item_selected(_index: int) -> void:
	search_count = 0
	previous_search = ""


func select_face(index: int, type: String, p_map_name: String = "", count: int = 0) -> void:
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
						return
			"Sector ID":
				for sector: Node3D in map_node.get_node("Sectors").get_children():
					if index == sector.ref.data.floorTriggerID:
						if count == 0:
							%Picker.select(sector)
							return
						count -= 1
			"Face":
				for face: Node3D in map_node.get_node("Faces").get_children():
					if index == face.ref.index:
						if face.get_child_count() > 0:
							%Picker.select(face.get_child(0))
							return
			"Face ID":
				for face: Node3D in map_node.get_node("Faces").get_children():
					if ("additionalMetadata" in face.ref.texture_data
						and index == face.ref.texture_data.additionalMetadata.unk0x0C
					):
						if face.get_child_count() > 0:
							if count == 0:
								%Picker.select(face.get_child(0))
								return
							count -= 1
			"Object":
				for object: Node3D in map_node.get_node("Objects").get_children():
					if index == object.ref.index:
						%Picker.select(object)
			"Object ID":
				for object: Node3D in map_node.get_node("Objects").get_children():
					if index == object.ref.data.unk0x0E:
						if count == 0:
							%Picker.select(object)
							return
						count -= 1
			"SFX":
				for sfx: Node3D in map_node.get_node("SFX").get_children():
					if index == sfx.ref.index:
						%Picker.select(sfx)
			"SFX ID":
				for sfx: Node3D in map_node.get_node("SFX").get_children():
					if index == sfx.ref.data.unk0x06:
						if count == 0:
							%Picker.select(sfx)
							return
						count -= 1
				
	if search_count > 0:
		search_count = 0
		previous_search = str(index)
		select_face(index, type, p_map_name, search_count)


#func get_face(index: int, type: String, map_info: Dictionary) -> Variant:
	#var map_node: Node3D
	#
	#for i in range(tree_root.get_child_count()):
		#if tree_root.get_child(i).get_text(0) == map_info.name:
			#map_node = tree_root.get_child(i).get_metadata(0)
	#
	#if not map_node:
		#return null
	#
	#match type:
		#"Sector":
			#for sector: Node3D in map_node.get_node("Sectors").get_children():
				#if index == sector.ref.index:
					#return sector.ref
		#"Face":
			#for face: Node3D in map_node.get_node("Faces").get_children():
				#if index == face.ref.index:
					#return face.ref
		#"Object":
			#for object: Node3D in map_node.get_node("Objects").get_children():
				#if index == object.ref.index:
					#return object.ref
		#"SFX":
			#for sfx: Node3D in map_node.get_node("SFX").get_children():
				#if index == sfx.ref.index:
					#return sfx.ref
	#return null


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


func _on_3d_context_menu_index_pressed(index: int) -> void:
	match index:
		0:
			var map_info: Dictionary = context_collision.collider.get_parent().ref.map_info
			var extra_info: Dictionary = {
				"render_type": "billboard",
				"rotation": 0,
				"sector_index": -1,
			}
			var pos: Vector3 = context_collision.position * Roth.SCALE_3D_WORLD
			if context_collision.collider.get_parent().ref is Face:
				extra_info["render_type"] = "fixed"
				extra_info["sector_index"] = context_collision.collider.get_parent().ref.sector.index
				var angle: float = rad_to_deg(atan2(context_collision.normal.x, -context_collision.normal.z))
				if angle < 0:
					angle += 360
				extra_info["rotation"] = int((angle / 360) * 256)
				if not context_collision.collider.get_parent().ref.sister:
					pos += (context_collision.normal * 2)
			elif context_collision.collider.get_parent().ref is Sector:
				extra_info["sector_index"] = context_collision.collider.get_parent().ref.index
			
			var new_object := ObjectRoth.new_object_3d(map_info, pos, extra_info)
			if not new_object:
				return
			Roth.get_map(map_info).add_object(new_object)
			%Map2D.add_object_to_2d_map(new_object, false)
			%Picker.select(new_object.node)
		1:
			var map_info: Dictionary = context_collision.collider.get_parent().ref.map_info
			var extra_info: Dictionary = {
				"render_type": "billboard",
				"rotation": 0,
				"sector_index": -1,
			}
			var pos: Vector3 = context_collision.position * Roth.SCALE_3D_WORLD
			if context_collision.collider.get_parent().ref is Face:
				extra_info["render_type"] = "fixed"
				extra_info["sector_index"] = context_collision.collider.get_parent().ref.sector.index
				var angle: float = rad_to_deg(atan2(context_collision.normal.x, -context_collision.normal.z))
				if angle < 0:
					angle += 360
				extra_info["rotation"] = int((angle / 360) * 256)
				if not context_collision.collider.get_parent().ref.sister:
					pos += (context_collision.normal * 2)
			elif context_collision.collider.get_parent().ref is Sector:
				extra_info["sector_index"] = context_collision.collider.get_parent().ref.index
			var new_object := ObjectRoth.new_from_copied_object_3d(map_info, copied_object_data, pos, extra_info)
			if not new_object:
				return
			Roth.get_map(map_info).add_object(new_object)
			%Map2D.add_object_to_2d_map(new_object, true)
			%Picker.select(new_object.node)


func _on_tab_bar_tab_changed(tab: int) -> void:
	%EditorTab.current_tab = tab
	match tab:
		0:
			%MapPanelContainer.show()
			%EditInfoContainer.show()
		1:
			%MapPanelContainer.hide()
			%EditInfoContainer.hide()


func _on_3d_object_context_menu_index_pressed(index: int) -> void:
	match index:
		0:
			var object: ObjectRoth = context_collision.collider.get_parent().ref
			copy_object(object)
		1:
			var object: ObjectRoth = context_collision.collider.get_parent().ref
			object.delete()
			%Picker.deselect()


func copy_object(object: ObjectRoth) -> void:
	copied_object_data = object
	%"3DContextMenu".set_item_disabled(1, false)
	%ObjectContextPopupMenu.set_item_disabled(1, false)
