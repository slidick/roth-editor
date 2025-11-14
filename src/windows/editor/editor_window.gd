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
var copied_object_data: Array
var copied_sfx_data: Array
var first_load: bool = false
var undo_stacks: Dictionary = {}
var undo_positions: Dictionary = {}
var undo_lists: Dictionary = {}
var hovered_sector: Variant = null
var hovered_face: Variant = null
var selected_faces: Array = []
var selected_sectors: Array = []
var selected_objects: Array = []
var selected_sfx: Array = []

func _ready() -> void:
	super._ready()
	Roth.map_loading_finished.connect(_on_map_loaded)
	Roth.map_loading_completely_finished.connect(_on_map_completely_loaded)
	Roth.close_map.connect(close_map)
	Roth.editor_action.connect(add_to_undo_redo)
	tree_root = %MapsTree.create_item()
	%MapsTree.set_column_title(0, "Maps")
	%MapContainer.hide()
	%EditorHeader.hide()
	
	%EditFaceTimer.wait_time = Roth.SEQUENTIAL_UNDO_TIMEOUT
	%EditSectorTimer.wait_time = Roth.SEQUENTIAL_UNDO_TIMEOUT
	%EditObjectTimer.wait_time = Roth.SEQUENTIAL_UNDO_TIMEOUT
	%EditSFXTimer.wait_time = Roth.SEQUENTIAL_UNDO_TIMEOUT


func _input(event: InputEvent) -> void:
	if %Camera3D.has_focus:
	
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventMouse and %Camera3D.has_focus == true:
			%SubViewport.push_input(event)
			get_viewport().set_input_as_handled()
		
		if event.is_action_pressed("move_object_to_ceiling"):
			var map_infos: Array = []
			for object: ObjectRoth in selected_objects:
				object.data.posZ = object.sector.get_ref().data.ceilingHeight
				redraw(selected_objects)
				%EditObjectContainer.update_selections()
				if object.map_info not in map_infos:
					map_infos.append(object.map_info)
			for map_info: Dictionary in map_infos:
				Roth.editor_action.emit(map_info, "Snap to Ceiling")
		if event.is_action_pressed("move_object_to_floor"):
			var map_infos: Array = []
			for object: ObjectRoth in selected_objects:
				object.data.posZ = object.sector.get_ref().data.floorHeight
				redraw(selected_objects)
				%EditObjectContainer.update_selections()
				if object.map_info not in map_infos:
					map_infos.append(object.map_info)
			for map_info: Dictionary in map_infos:
				Roth.editor_action.emit(map_info, "Snap to Floor")
		if event.is_action_pressed("open_3d_context_menu"):
			var viewport := %Map3D.get_viewport()
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
			var space_state: PhysicsDirectSpaceState3D = %Map3D.get_world_3d().direct_space_state
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
		
		if Input.is_action_just_pressed("paste_options_dialog"):
			%PasteOptions.toggle(true)
	
	if %Map3D.has_focus or %Map2D.has_focus:
		if event.is_action_pressed("delete_selected"):
			if len(selected_faces) == 1 and selected_faces[0].sister:
				delete_selected_face()
			elif selected_faces.is_empty() and not selected_sectors.is_empty():
				delete_selected_sector()
		if event.is_action_pressed("merge_sectors"):
			if len(selected_sectors) > 1 and len(selected_faces) == 0:
				merge_selected_sectors()
		if event.is_action_pressed("hide_selected_sectors", false, true):
			hide_selected_sectors()
		if event.is_action_pressed("hide_non_selected_sectors", false, true):
			hide_non_selected_sectors()
		if event.is_action_pressed("show_hidden_sectors"):
			show_hidden_sectors()


func _on_paste_options_button_pressed() -> void:
	%PasteOptions.toggle(true)


#region Map / Viewports

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


func close_map(map_info: Dictionary) -> void:
	for tree_item: TreeItem in %MapsTree.get_root().get_children():
		if tree_item.get_parent() == tree_root and tree_item.get_metadata(0).ref.map_info == map_info:
			tree_item.get_metadata(0).queue_free()
			Roth.loaded_maps.erase(tree_item.get_metadata(0).map_info.name)
			for child_item: TreeItem in tree_item.get_children():
				child_item.free()
			%Map2D.close_map(tree_item.get_metadata(0).map_info)
			selected_faces.clear()
			selected_sectors.clear()
			hovered_face = null
			hovered_sector = null
			%"Command Editor".close(tree_item.get_metadata(0).map_info.name)
			Roth.reload_map_info(tree_item.get_metadata(0).map_info)
			close_undo_redo(tree_item.get_metadata(0).map_info)
			tree_item.free()


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
	for sfx: SFX in map.sound_effects:
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
	
	add_to_undo_redo(map_info, "Map Opened")


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
	%Map3D.has_focus = true
	%ViewportBorder.self_modulate.a = 1.0


func _on_sub_viewport_container_focus_exited() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		return
	%Camera3D.has_focus = false
	%Map3D.has_focus = false
	%ViewportBorder.self_modulate.a = 0.0


func _on_sub_viewport_container_mouse_entered() -> void:
	%SubViewportContainer.grab_focus()


func _on_sub_viewport_container_mouse_exited() -> void:
	%SubViewportContainer.release_focus()


func _on_sub_viewport_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		%SubViewportContainer.grab_focus()


func _on_sub_viewport_container_2d_mouse_entered() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		return
	%Map2D.has_focus = true
	%ViewportBorder2.self_modulate.a = 1.0
	%SubViewportContainer2D.grab_focus()
	if Input.get_mouse_button_mask() & MOUSE_BUTTON_MASK_LEFT == 0:
		%SubViewportContainer2D.grab_click_focus()


func _on_sub_viewport_container_2d_mouse_exited() -> void:
	%Map2D.has_focus = false
	%ViewportBorder2.self_modulate.a = 0.0
	if hovered_sector:
		hovered_sector = null
		%Map2D.queue_redraw()
	if hovered_face:
		hovered_face = null
		%Map2D.queue_redraw()


func _on_tab_bar_tab_changed(tab: int) -> void:
	%EditorTab.current_tab = tab
	match tab:
		0:
			%MapPanelContainer.show()
			%InspectorSidePanel.show()
		1:
			%MapPanelContainer.hide()
			%InspectorSidePanel.hide()

#endregion

#region MapTree

func _on_maps_tree_button_clicked(item: TreeItem, _column: int, id: int, _mouse_button_index: int) -> void:
	if item.get_metadata(0).visible:
		item.set_button(0, id, EYE_CLOSED_ICON)
		item.get_metadata(0).process_mode = PROCESS_MODE_DISABLED
	else:
		item.set_button(0, id, EYE_ICON)
		item.get_metadata(0).process_mode = PROCESS_MODE_INHERIT
	item.get_metadata(0).visible = not item.get_metadata(0).visible


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
			var old_map_name: String = selected[0].get_metadata(0).map_info.name
			var map: Map = Roth.get_map(selected[0].get_metadata(0).map_info)
			Roth.loaded_maps.erase(map.map_info.name)
			Roth.maps.erase(map.map_info)
			Roth.maps.append(map.map_info.duplicate())
			map.map_info.name = new_map_name
			map.map_info.filepath = Roth.ROTH_CUSTOM_MAP_DIRECTORY.path_join(new_map_name + ".RAW")
			map.map_info.erase("filepath_json")
			map.map_info.erase("vanilla")
			Roth.loaded_maps[map.map_info.name] = map
			Roth.save_map(map)
			selected[0].set_text(0, new_map_name)
			map.name_changed.emit(new_map_name)
			
			#Roth.load_roth_settings()
			Roth.settings_loaded.emit()
			rename_undo_redo(old_map_name, new_map_name)
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
			if await Dialog.confirm("Close map%s?\n %s" % ["s" if len(selected) > 1 else "", ", ".join(selected.map(func (item: TreeItem) -> String: return item.get_metadata(0).map_info.name))], "Confirm Close", false):
				for item: TreeItem in selected:
					close_map(item.get_metadata(0).map_info)
					#item.get_metadata(0).queue_free()
					#Roth.loaded_maps.erase(item.get_metadata(0).map_info.name)
					#for child_item: TreeItem in item.get_children():
						#child_item.free()
					#%Map2D.close_map(item.get_metadata(0).map_info)
					#%"Command Editor".close(item.get_metadata(0).map_info.name)
					#Roth.reload_map_info(item.get_metadata(0).map_info)
					#item.free()

#endregion

#region Search

func _on_search_text_submitted(search_text: String) -> void:
	if search_text.is_empty():
		%Map3D.deselect()
		return
	
	if search_text == previous_search:
		search_count += 1
	else:
		search_count = 0
	previous_search = search_text
	
	var type: String = %SearchOption.get_item_text(%SearchOption.selected)
	select_face(int(search_text), type, "", search_count)


func _on_search_result_activated(search_result: Dictionary) -> void:
	await Roth.load_maps([search_result.map_info])
	%Search.text = str(search_result.index)
	for i in range(%SearchOption.item_count):
		if %SearchOption.get_item_text(i) == search_result.type:
			%SearchOption.select(i)
	select_face(search_result.index, search_result.type, search_result.map_info.name)


func _on_search_option_item_selected(_index: int) -> void:
	search_count = 0
	previous_search = ""

#endregion

#region Objects

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
			%Map2D.add_object_to_2d_map(new_object)
			select_resource(new_object, true)
			Roth.editor_action.emit(new_object.map_info, "Add Object")
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
			var new_object := ObjectRoth.new_from_copied_object_3d(map_info, copied_object_data[0], pos, extra_info)
			if not new_object:
				return
			Roth.get_map(map_info).add_object(new_object)
			%Map2D.add_object_to_2d_map(new_object)
			select_resource(new_object, true)
			Roth.editor_action.emit(new_object.map_info, "Paste Object")


func _on_3d_object_context_menu_index_pressed(index: int) -> void:
	match index:
		0:
			var object: ObjectRoth = context_collision.collider.get_parent().ref
			copy_objects([object])
		1:
			var object: ObjectRoth = context_collision.collider.get_parent().ref
			object.delete()
			%Map3D.deselect()


func copy_objects(object_list: Array) -> void:
	copied_object_data.clear()
	for object: ObjectRoth in object_list:
		copied_object_data.append(object.duplicate())
	%"3DContextMenu".set_item_disabled(1, false)
	%ObjectContextPopupMenu.set_item_disabled(1, false)

func copy_sfx(sfx_list: Array) -> void:
	copied_sfx_data.clear()
	for sfx: SFX in sfx_list:
		copied_sfx_data.append(sfx.duplicate())
	%SFXContextPopupMenu.set_item_disabled(1, false)

#endregion

#region Undo/Redo

func add_to_undo_redo(p_map_info: Dictionary, p_name: String = "") -> void:
	if p_map_info.name not in undo_stacks:
		undo_stacks[p_map_info.name] = []
		undo_positions[p_map_info.name] = 0
		undo_lists[p_map_info.name] = ItemList.new()
		undo_lists[p_map_info.name].name = p_map_info.name
		%HistoryTabContainer.add_child(undo_lists[p_map_info.name])
		undo_lists[p_map_info.name].item_selected.connect(func (index: int) -> void:
			undo_positions[p_map_info.name] = len(undo_stacks[p_map_info.name]) - index
			var undo_state: Dictionary = undo_stacks[p_map_info.name][ undo_positions[p_map_info.name] - 1]
			var map: Map = Map.load_from_bytes(undo_state.map_info, undo_state.bytes)
			if not map:
				return
			replace_map(map)
		)
	
	if Settings.settings.get("options", {}).get("undo_history", 50) != 0:
	
		var action: Dictionary = {
			"name": p_name,
			"map_info": p_map_info,
			"bytes": Roth.get_map(p_map_info).compile(),
		}
		
		# Check if state is same as previous state
		if not undo_stacks[p_map_info.name].is_empty() and action.bytes == undo_stacks[p_map_info.name][-1].bytes:
			return
		
		while undo_positions[p_map_info.name] < len(undo_stacks[p_map_info.name]):
			undo_stacks[p_map_info.name].pop_back()
		
		undo_stacks[p_map_info.name].append(action)
		undo_positions[p_map_info.name] += 1
	
	while len(undo_stacks[p_map_info.name]) > Settings.settings.get("options", {}).get("undo_history", 50):
		undo_stacks[p_map_info.name].pop_front()
	
	undo_lists[p_map_info.name].clear()
	for i in range(len(undo_stacks[p_map_info.name])-1, -1, -1):
		undo_lists[p_map_info.name].add_item(undo_stacks[p_map_info.name][i].name)
	if undo_lists[p_map_info.name].item_count > 0:
		undo_lists[p_map_info.name].select(0)


func close_undo_redo(p_map_info: Dictionary) -> void:
	undo_stacks.erase(p_map_info.name)
	undo_positions.erase(p_map_info.name)
	if p_map_info.name in undo_lists:
		undo_lists[p_map_info.name].queue_free()
	undo_lists.erase(p_map_info.name)


func rename_undo_redo(p_old_map_name: String, p_new_map_name: String) -> void:
	undo_stacks[p_new_map_name] = undo_stacks[p_old_map_name]
	undo_positions[p_new_map_name] = undo_positions[p_old_map_name]
	undo_lists[p_new_map_name] = undo_lists[p_old_map_name]
	undo_lists[p_new_map_name].name = p_new_map_name
	undo_stacks.erase(p_old_map_name)
	undo_positions.erase(p_old_map_name)
	undo_lists.erase(p_old_map_name)


func replace_map(map: Map) -> void:
	for tree_item: TreeItem in %MapsTree.get_root().get_children():
		if tree_item.get_parent() == tree_root and tree_item.get_metadata(0).ref.map_info == map.map_info:
			
			Roth.loaded_maps[map.map_info.name] = map
			
			var old_map_node: Node3D = tree_item.get_metadata(0)
			
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
			for sfx: SFX in map.sound_effects:
				var mesh := sfx.initialize_mesh()
				sfx_node.add_child(mesh)
			
			
			
			var map_node := Map.MapNode3D.new()
			map_node.ref = map
			map_node.map_info = map.map_info
			map_node.add_child(sectors_node)
			map_node.add_child(faces_node)
			map_node.add_child(objects_node)
			map_node.add_child(sfx_node)
			map_node.name = map.map_info.name
			map_node.visible = old_map_node.visible
			map_node.process_mode = old_map_node.process_mode
			%Maps.add_child(map_node)
			map.node = map_node
			
			tree_item.set_metadata(0, map_node)
			
			tree_item.get_child(0).set_metadata(0, objects_node)
			tree_item.get_child(1).set_metadata(0, sfx_node)
			
			
			old_map_node.queue_free()
			
			if %Map2D.close_map(map.map_info, false):
				%Map2D.setup(map, false)

#endregion

#region Editor Functions

func select_face(index: int, type: String, p_map_name: String = "", count: int = 0, deselect_others: bool = true) -> void:
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
						select_resource(sector.ref, deselect_others)
						return
			"Sector ID":
				for sector: Node3D in map_node.get_node("Sectors").get_children():
					if index == sector.ref.data.floorTriggerID:
						if count == 0:
							select_resource(sector.ref, deselect_others)
							return
						count -= 1
			"Face":
				for face: Node3D in map_node.get_node("Faces").get_children():
					if index == face.ref.index:
						if face.get_child_count() > 0:
							select_resource(face.get_child(0).ref, deselect_others)
							return
			"Face ID":
				for face: Node3D in map_node.get_node("Faces").get_children():
					if ("additionalMetadata" in face.ref.texture_data
						and index == face.ref.texture_data.additionalMetadata.unk0x0C
					):
						if face.get_child_count() > 0:
							if count == 0:
								select_resource(face.get_child(0).ref, deselect_others)
								return
							count -= 1
			"Object":
				for object: Node3D in map_node.get_node("Objects").get_children():
					if index == object.ref.index:
						select_resource(object.ref, deselect_others)
			"Object ID":
				for object: Node3D in map_node.get_node("Objects").get_children():
					if index == object.ref.data.unk0x0E:
						if count == 0:
							select_resource(object.ref, deselect_others)
							return
						count -= 1
			"SFX":
				for sfx: Node3D in map_node.get_node("SFX").get_children():
					if index == sfx.ref.index:
						select_resource(sfx.ref, deselect_others)
			"SFX ID":
				for sfx: Node3D in map_node.get_node("SFX").get_children():
					if index == sfx.ref.data.unk0x06:
						if count == 0:
							select_resource(sfx.ref, deselect_others)
							return
						count -= 1
				
	if search_count > 0:
		search_count = 0
		previous_search = str(index)
		select_face(index, type, p_map_name, search_count)


func select_resource(resource: RefCounted, deselect_others: bool = true) -> void:
	%EditFaceContainer.clear()
	%EditSectorContainer.clear()
	%EditObjectContainer.clear()
	%EditSFXContainer.clear()
	if not resource:
		selected_faces.clear()
		selected_sectors.clear()
		selected_objects.clear()
		selected_sfx.clear()
		for object_node: ObjectRoth.ObjectNode2D in %Objects.get_children():
			object_node.deselect()
		for sfx_node: SFX.SFXNode2D in %SFX.get_children():
			sfx_node.deselect()
		%Arrow3D.clear_target()
		%Map2D.update_selections()
		%Map3D.update_selections()
		return
	
	if resource is ObjectRoth:
		selected_faces.clear()
		selected_sectors.clear()
		selected_sfx.clear()
		if deselect_others:
			selected_objects.clear()
		if resource not in selected_objects:
			selected_objects.append(resource)
		%EditObjectContainer.update_selections()
	elif resource is SFX:
		
		selected_faces.clear()
		selected_sectors.clear()
		selected_objects.clear()
		if deselect_others:
			selected_sfx.clear()
		if resource not in selected_sfx:
			selected_sfx.append(resource)
		%EditSFXContainer.update_selections()
	elif resource is Face:
		selected_objects.clear()
		selected_sfx.clear()
		if deselect_others:
			selected_faces.clear()
			selected_sectors.clear()
			selected_faces.append(resource)
			selected_sectors.append(resource.sector)
		else:
			if resource not in selected_faces:
				selected_faces.append(resource)
			if len(selected_faces) > 1:
				selected_sectors.clear()
			elif len(selected_faces) == 1:
				selected_sectors.clear()
				selected_sectors.append(selected_faces[0].sector)
		%EditFaceContainer.update_selections()
	elif resource is Sector:
		selected_faces.clear()
		selected_objects.clear()
		selected_sfx.clear()
		hovered_face = null
		if deselect_others:
			selected_sectors.clear()
		if resource not in selected_sectors:
			selected_sectors.append(resource)
		%EditSectorContainer.update_selections()
	
	%Arrow3D.set_target(resource)
	%Map2D.update_selections()
	%Map3D.update_selections()
	


func deselect_resource(resource: RefCounted) -> void:
	if resource is Face:
		selected_faces.erase(resource)
		if len(selected_faces) == 1:
			selected_sectors.clear()
			selected_sectors.append(selected_faces[0].sector)
		elif len(selected_faces) == 0:
			selected_sectors.clear()
		%EditFaceContainer.update_selections()
	elif resource is Sector:
		selected_sectors.erase(resource)
		%EditSectorContainer.update_selections()
	elif resource is ObjectRoth:
		selected_objects.erase(resource)
		%EditObjectContainer.update_selections()
	elif resource is SFX:
		selected_sfx.erase(resource)
		%EditSFXContainer.update_selections()
	%Arrow3D.unset_target(resource)
	%Map2D.update_selections()
	%Map3D.update_selections()


func redraw(redraw_list: Array) -> void:
	for resource: Variant in redraw_list:
		resource.initialize_mesh()
		if resource is Sector:
			for face_ref: WeakRef in resource.faces:
				var face: Face = face_ref.get_ref()
				if face.sister:
					face.sister.get_ref().initialize_mesh()
				face.initialize_mesh()
	%Map2D.queue_redraw()
	%Map3D.update_selections()


func delete_selected_face() -> void:
	assert(len(selected_faces) == 1)
	assert(len(selected_sectors) == 1)
	await get_tree().process_frame # Fixes double input bug somehow caused from the confirmation dialog
	if await Dialog.confirm("Delete selected double-sided face?", "Confirm Deletion", false):
		Roth.get_map(selected_faces[0].map_info).merge_sectors(selected_faces[0])
		Roth.editor_action.emit(selected_faces[0].map_info, "Delete Double-Sided Face")
		hovered_face = null
		select_resource(selected_sectors[0])


func delete_selected_sector() -> void:
	await get_tree().process_frame # Fixes double input bug somehow caused from the confirmation dialog
	if await Dialog.confirm("Delete selected sector%s?" % ("s" if len(selected_sectors) > 1 else ""), "Confirm Deletion", false):
		var map_groups: Dictionary = {}
		for sector: Sector in selected_sectors:
			sector.delete_sector()
			if sector.map_info not in map_groups:
				map_groups[sector.map_info] = []
			map_groups[sector.map_info].append(sector)
		for map_info: Dictionary in map_groups:
			Roth.editor_action.emit(map_info, "Delete Sector%s" % ("s" if len(map_groups[map_info]) > 1 else ""))
		select_resource(null)

func merge_selected_sectors() -> void:
	var all_sector_faces: Array = []
	for sector: Sector in selected_sectors:
		for face_ref: WeakRef in sector.faces:
			var face: Face = face_ref.get_ref()
			all_sector_faces.append(face)
	var map_info: Dictionary = selected_sectors[0].map_info
	var found: bool = true
	while found:
		found = false
		for sector: Sector in selected_sectors:
			for face_ref: WeakRef in sector.faces:
				var face: Face = face_ref.get_ref()
				if face.sister:
					var face_sister: Face = face.sister.get_ref()
					if face_sister in all_sector_faces:
						selected_sectors.erase(face_sister.sector)
						Roth.get_map(face_sister.map_info).merge_sectors(face)
						found = true
						hovered_face = null
						hovered_sector = null
						%Map2D.update_selections()
						%Map3D.update_selections()
						break
			if found:
				break
	
	Roth.editor_action.emit(map_info, "Merge Multiple Sectors")


func hide_selected_sectors() -> void:
	var maps: Array = []
	for sector: Sector in selected_sectors:
		if sector.map_info not in maps:
			maps.append(sector.map_info)
		sector.hidden = true
		for face_ref: WeakRef in sector.faces:
			var face: Face = face_ref.get_ref()
			face.hidden = true
	for map_info: Dictionary in maps:
		for object: ObjectRoth in Roth.get_map(map_info).objects:
			if object.sector.get_ref().hidden:
				object.initialize_mesh()
	redraw(selected_sectors)
	selected_sectors.clear()
	hovered_sector = null
	if %ObjectCheckBox.button_pressed:
		%Map2D.show_objects()
	%Map2D.update_selections()
	%Map3D.update_selections()


func hide_non_selected_sectors() -> void:
	var maps: Array = []
	var hidden_sectors: Array = []
	for i in range(tree_root.get_child_count()):
		var map: Map = tree_root.get_child(i).get_metadata(0).ref
		maps.append(map)
		for sector: Sector in map.sectors:
			if sector not in selected_sectors:
				sector.hidden = true
				hidden_sectors.append(sector)
				for face_ref: WeakRef in sector.faces:
					var face: Face = face_ref.get_ref()
					face.hidden = true
	for map: Map in maps:
		for object: ObjectRoth in map.objects:
			if object.sector.get_ref().hidden:
				object.initialize_mesh()
	redraw(hidden_sectors)
	selected_sectors.clear()
	hovered_sector = null
	if %ObjectCheckBox.button_pressed:
		%Map2D.show_objects()
	%Map2D.update_selections()
	%Map3D.update_selections()


func show_hidden_sectors() -> void:
	var hidden_sectors: Array = []
	for i in range(tree_root.get_child_count()):
		var map: Map = tree_root.get_child(i).get_metadata(0).ref
		for object: ObjectRoth in map.objects:
			if object.sector.get_ref().hidden:
				object.sector.get_ref().hidden = false
				object.initialize_mesh()
				object.sector.get_ref().hidden = true
		for sector: Sector in map.sectors:
			if sector.hidden:
				hidden_sectors.append(sector)
				sector.hidden = false
				for face_ref: WeakRef in sector.faces:
					var face: Face = face_ref.get_ref()
					face.hidden = false
					#if face.sister:
						#face.sister.get_ref().hidden = false
	redraw(hidden_sectors)
	if %ObjectCheckBox.button_pressed:
		%Map2D.show_objects()
	#%Map2D.update_selections()
	#%Map3D.update_selections()

#endregion
