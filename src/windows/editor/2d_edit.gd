extends Node2D


const COLOR_GRID := Color(0.498039, 1, 0.831373, 0.2)
const COLOR_AXIS := Color(1, 0.270588, 0, 0.2)
const COLOR_AXIS_EDGE := Color(0.52, 0.434, 0.179, 1.0)
const ZOOM_SPEED : float = 0.95
const MAX_ZOOM : int = 100
const MIN_ZOOM : float = 0.2


var line_width: float = 0.1
var map: Variant
var minimum_x: float = 0
var minimum_y: float = 0
var maximum_x: float = 0
var maximum_y: float = 0
var additional_zoom: float = 1
var prev_viewport_size := Vector2i.ZERO
var has_focus: bool = false
var mouse_drag_enabled: bool = false
var zooming: bool = false


var holding_left_mouse: bool = false
var holding_right_mouse: bool = false
var holding_shift: bool = false
var holding_ctrl: bool = false
var holding_alt: bool = false
var snap: float = 0.2
var timer: Timer
var start_box_draw: bool = false 
var start_box_position := Vector2.ZERO
var start_sector_split: bool = false
var start_sector_split_vertex: VertexNode
var last_allow_move: bool = false
var skip_sector_hover: int = 0
var skip_sector_hover_prev: int = 0
var start_box_select: bool = false
var start_box_deselect: bool = false
var start_box_select_position := Vector2.ZERO
var mouse_paste_position := Vector2.ZERO
var mouse_rotation_position := Vector2i.ZERO
var mouse_object_rotation_center := Vector2.ZERO
var context_menu_object: ObjectRoth
var context_menu_sfx: SFX
var grid_size := Vector2.ONE
var highlight_sectors: Array = []
var vertex_drag_amount := Vector2.ZERO
var concave_sectors: Array = []


func _ready() -> void:
	timer = Timer.new()
	timer.wait_time = 0.1
	timer.one_shot = true
	timer.timeout.connect(check_for_hover)
	add_child(timer)
	
	var data: Variant = Settings.cache.get("2d_edit")
	if data and typeof(data) == TYPE_DICTIONARY:
		if "grid_enabled" in data:
			%GridCheckBox.button_pressed = data.grid_enabled
		if "grid_size" in data:
			%GridEdit.value = data.grid_size
		if "snap_enabled" in data:
			%SnapCheckBox.button_pressed = data.snap_enabled
		if "snap_size" in data:
			%SnapEdit.value = data.snap_size
	
	if %SnapCheckBox.button_pressed:
		snap = %SnapEdit.value / Roth.SCALE_2D_WORLD
	
	grid_size = Vector2.ONE * %GridEdit.value / Roth.SCALE_2D_WORLD


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			var data := {
				"grid_enabled": %GridCheckBox.button_pressed,
				"grid_size": int(%GridEdit.value),
				"snap_enabled": %SnapCheckBox.button_pressed,
				"snap_size": int(%SnapEdit.value),
			}
			Settings.update_cache("2d_edit", data)


func _process(_delta: float) -> void:
	if not has_focus:
		return
	if holding_left_mouse or holding_right_mouse:
		timer.wait_time = 0.01
	else:
		timer.wait_time = 0.1
	var mouse_x: float = get_global_mouse_position().x + global_position.x
	var mouse_y: float = get_global_mouse_position().y + global_position.y
	%CoordinatesLabel.text = "(%d, %d)" % [mouse_x * Roth.SCALE_2D_WORLD, mouse_y * Roth.SCALE_2D_WORLD]

#region Input

func _input(event: InputEvent) -> void:
	if not map:
		return
	
	if event.is_action_pressed("map_2d_zoom_in"):
		additional_zoom /= ZOOM_SPEED
		additional_zoom = clamp(additional_zoom, MIN_ZOOM, MAX_ZOOM)
		zooming = true
		update_camera_zoom()
		var changed: bool = update_line_width(additional_zoom)
		if changed:
			queue_redraw()
	
	if event.is_action_pressed("map_2d_zoom_out"):
		additional_zoom *= ZOOM_SPEED
		additional_zoom = clamp(additional_zoom, MIN_ZOOM, MAX_ZOOM)
		zooming = true
		update_camera_zoom()
		update_line_width(additional_zoom)
		queue_redraw()
	
	if event.is_action_pressed("next_sector_hover"):
		skip_sector_hover += 1
		check_for_hover()
	
	if event.is_action_pressed("unmerge_vertices"):
		unmerge_vertices()
	
	if mouse_drag_enabled:
		if event is InputEventMouseMotion:
			%Camera2D.position.x -= event.relative.x / %Camera2D.zoom.x
			%Camera2D.position.y -= event.relative.y / %Camera2D.zoom.y
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		if event.pressed:
			mouse_drag_enabled = true
		else:
			mouse_drag_enabled = false
			queue_redraw()
	
	if start_box_draw:
		if event is InputEventMouseMotion:
			queue_redraw()
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			start_box_draw = false
			start_box_position = Vector2.ZERO
			queue_redraw()
	
	if start_box_select:
		if event is InputEventMouseMotion:
			queue_redraw()
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			start_box_select = false
			start_box_select_position = Vector2.ZERO
			start_box_deselect = false
			highlight_sectors.clear()
			queue_redraw()
	
	if start_sector_split:
		if event is InputEventMouseMotion:
			queue_redraw()
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			start_sector_split = false
			queue_redraw()
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			start_sector_split = false
			var nearest_vertex: VertexNode = find_nearest_vertex(get_global_mouse_position() + global_position)
			check_for_split(nearest_vertex)
			queue_redraw()
	
	if event is InputEventKey and event.keycode == KEY_SHIFT:
		if event.pressed:
			holding_shift = true
		else:
			holding_shift = false
	
	if event is InputEventKey and event.keycode == KEY_CTRL:
		if event.pressed:
			owner.hovered_sector = null
			owner.hovered_face = null
			holding_ctrl = true
			queue_redraw()
		else:
			holding_ctrl = false
			if not owner.paste_sectors_mode:
				check_for_hover()
			queue_redraw()
	
	if event is InputEventKey and event.keycode == KEY_ALT:
		if event.pressed:
			holding_alt = true
			queue_redraw()
			mouse_rotation_position = DisplayServer.mouse_get_position()
			if not owner.selected_objects.is_empty():
				mouse_object_rotation_center = Vector2.ZERO
				for object: ObjectRoth in owner.selected_objects:
					mouse_object_rotation_center += Vector2(-object.data.posX, object.data.posY)
				mouse_object_rotation_center /= len(owner.selected_objects)
		else:
			holding_alt = false
			%"2DManipLabel".text = ""
	
	handle_paste_sectors_mode_event(event)
	handle_sector_mode_event(event)
	handle_draw_mode_event(event)
	handle_object_mode_event(event)
	handle_vertex_mode_event(event)
	handle_sfx_mode_event(event)


func handle_paste_sectors_mode_event(event: InputEvent) -> void:
	if not owner.paste_sectors_mode or not %SectorCheckBox.button_pressed:
		return
	if event is InputEventKey and event.keycode == KEY_ALT:
		if event.pressed:
			for i in range(len(owner.current_pasted_sector_data)):
				for j in range(len(owner.current_pasted_sector_data[i].faces)):
					owner.original_pasted_sector_data[i].faces[j].v1 = owner.current_pasted_sector_data[i].faces[j].v1
					owner.original_pasted_sector_data[i].faces[j].v2 = owner.current_pasted_sector_data[i].faces[j].v2
				for j in range(len(owner.copied_sector_data[i].data.objectInformation)):
					owner.original_pasted_sector_data[i].data.objectInformation[j].posX = owner.current_pasted_sector_data[i].data.objectInformation[j].posX
					owner.original_pasted_sector_data[i].data.objectInformation[j].posY = owner.current_pasted_sector_data[i].data.objectInformation[j].posY
					owner.original_pasted_sector_data[i].data.objectInformation[j].rotation = owner.current_pasted_sector_data[i].data.objectInformation[j].rotation
	if event is InputEventMouseMotion and event.alt_pressed:
		var offset: Vector2 = (DisplayServer.mouse_get_position() - mouse_rotation_position)
		var rotation_deg: float = offset.x + offset.y
		var rotation_snap: float = 1.0
		if event.ctrl_pressed:
			rotation_snap = 15
		var rotation_amount := deg_to_rad(snapped(rotation_deg, rotation_snap))
		%"2DManipLabel".text = "Rotate: %d°" % snapped(rotation_deg, rotation_snap)
		var translation := Transform2D(rotation_amount, Vector2.ZERO)
		for i in range(len(owner.copied_sector_data)):
			for j in range(len(owner.copied_sector_data[i].faces)):
				owner.current_pasted_sector_data[i].faces[j].v1 = translation * (owner.original_pasted_sector_data[i].faces[j].v1 - owner.current_copied_sector_center) + owner.current_copied_sector_center
				owner.current_pasted_sector_data[i].faces[j].v2 = translation * (owner.original_pasted_sector_data[i].faces[j].v2 - owner.current_copied_sector_center) + owner.current_copied_sector_center
			for j in range(len(owner.copied_sector_data[i].data.objectInformation)):
				var point := Vector2(-owner.original_pasted_sector_data[i].data.objectInformation[j].posX, owner.original_pasted_sector_data[i].data.objectInformation[j].posY)
				point = translation * (point - owner.current_copied_sector_center) + owner.current_copied_sector_center
				owner.current_pasted_sector_data[i].data.objectInformation[j].posX = -point.x
				owner.current_pasted_sector_data[i].data.objectInformation[j].posY = point.y
				owner.current_pasted_sector_data[i].data.objectInformation[j].rotation = owner.original_pasted_sector_data[i].data.objectInformation[j].rotation+Roth.object_relative_degrees_to_rotation(snapped(rotation_deg, rotation_snap))
		queue_redraw()
		return
	if (event is InputEventMouseMotion or (holding_ctrl and not holding_alt)) and not owner.pin_paste:
		var mouse: Vector2 = ((get_global_mouse_position() + global_position).snappedf(snap) * Roth.SCALE_2D_WORLD)
		if holding_ctrl:
			if abs(mouse.x - owner.original_copied_sector_center.x) < abs(mouse.y - owner.original_copied_sector_center.y):
				mouse.x = owner.original_copied_sector_center.x
			else:
				mouse.y = owner.original_copied_sector_center.y
		var offset: Vector2 = mouse - owner.current_copied_sector_center
		
		for sector: Sector in owner.current_pasted_sector_data:
			for face: Face in sector.faces:
				face.v1 = (face.v1 + offset).snappedf(2)
				face.v2 = (face.v2 + offset).snappedf(2)
			for object_data: Dictionary in sector.data.objectInformation:
				object_data.posX = snappedf(object_data.posX - offset.x, 2)
				object_data.posY = snappedf(object_data.posY + offset.y, 2)
		owner.current_copied_sector_center = mouse
		queue_redraw()
	if owner.pin_paste and has_focus:
		if event.is_action_pressed("ui_up", true):
			for sector: Sector in owner.current_pasted_sector_data:
				for face: Face in sector.faces:
					face.v1.y -= 2
					face.v2.y -= 2
				for object_data: Dictionary in sector.data.objectInformation:
					object_data.posY -= 2
			queue_redraw()
			get_viewport().set_input_as_handled()
		if event.is_action_pressed("ui_down", true):
			for sector: Sector in owner.current_pasted_sector_data:
				for face: Face in sector.faces:
					face.v1.y += 2
					face.v2.y += 2
				for object_data: Dictionary in sector.data.objectInformation:
					object_data.posY += 2
			queue_redraw()
			get_viewport().set_input_as_handled()
		if event.is_action_pressed("ui_left", true):
			for sector: Sector in owner.current_pasted_sector_data:
				for face: Face in sector.faces:
					face.v1.x -= 2
					face.v2.x -= 2
				for object_data: Dictionary in sector.data.objectInformation:
					object_data.posX += 2
			queue_redraw()
			get_viewport().set_input_as_handled()
		if event.is_action_pressed("ui_right", true):
			for sector: Sector in owner.current_pasted_sector_data:
				for face: Face in sector.faces:
					face.v1.x += 2
					face.v2.x += 2
				for object_data: Dictionary in sector.data.objectInformation:
					object_data.posX -= 2
			queue_redraw()
			get_viewport().set_input_as_handled()


func handle_sector_mode_event(event: InputEvent) -> void:
	if not %SectorCheckBox.button_pressed or owner.paste_sectors_mode:
		return
	
	if event is InputEventMouseMotion and not mouse_drag_enabled:
		if timer.is_stopped():
			timer.start()
	
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if not event.pressed and start_box_select:
					var starting_position := start_box_select_position
					var ending_position := (get_global_mouse_position() + global_position)
					var v2 := Vector2(ending_position.x, starting_position.y)
					var v3 := Vector2(starting_position.x, ending_position.y)
					var sectors_in_selection: Array = []
					for sector: Sector in map.sectors:
						if Geometry2D.is_point_in_polygon(sector.get_center()/Roth.SCALE_2D_WORLD, [
							starting_position,
							v2,
							ending_position,
							v3
						]):
							sectors_in_selection.append(sector)
					if sectors_in_selection.is_empty():
						if not event.shift_pressed:
							owner.select_resource(null)
					else:
						if not event.shift_pressed:
							owner.select_resource(null)
						for sector: Sector in sectors_in_selection:
							owner.select_resource(sector, false)
					start_box_select = false
					highlight_sectors.clear()
					start_box_select_position = Vector2.ZERO
					queue_redraw()
				if event.ctrl_pressed:
					if event.pressed:
						start_box_select = true
						start_box_select_position = (get_global_mouse_position() + global_position)
					return
				if not event.shift_pressed:
					if event.pressed:
						holding_left_mouse = true
						skip_sector_hover = 0
						skip_sector_hover_prev = 0
						if owner.hovered_face and not owner.selected_faces.is_empty() and owner.hovered_face in owner.selected_faces:
							owner.select_resource(null)
						elif owner.hovered_face:
							owner.select_resource(owner.hovered_face)
						elif owner.hovered_sector and not owner.selected_sectors.is_empty() and owner.hovered_sector in owner.selected_sectors and owner.selected_faces.is_empty():
							owner.select_resource(null)
						elif owner.hovered_sector and len(owner.selected_faces) <= 1:
							owner.select_resource(owner.hovered_sector)
						elif not owner.hovered_sector:
							owner.select_resource(null)
					else:
						holding_left_mouse = false
				if event.shift_pressed:
					if event.pressed:
						holding_shift = true
						holding_left_mouse = true
						if owner.hovered_face and owner.hovered_face not in owner.selected_faces:
							owner.select_resource(owner.hovered_face, false)
						elif owner.hovered_face and owner.hovered_face in owner.selected_faces and len(owner.selected_faces) == 1:
							owner.deselect_resource(owner.hovered_face)
						elif owner.hovered_sector and len(owner.selected_faces) <= 1 and owner.hovered_sector not in owner.selected_sectors:
							owner.select_resource(owner.hovered_sector, false)
						elif owner.hovered_sector and owner.hovered_sector in owner.selected_sectors:
							#owner.deselect_resource(owner.hovered_sector)
							pass
					else:
						holding_shift = false
						holding_left_mouse = false
			MOUSE_BUTTON_RIGHT:
				if not event.pressed and start_box_deselect:
					var starting_position := start_box_select_position
					var ending_position := (get_global_mouse_position() + global_position)
					var v2 := Vector2(ending_position.x, starting_position.y)
					var v3 := Vector2(starting_position.x, ending_position.y)
					var sectors_in_selection: Array = []
					for sector: Sector in map.sectors:
						if Geometry2D.is_point_in_polygon(sector.get_center()/Roth.SCALE_2D_WORLD, [
							starting_position,
							v2,
							ending_position,
							v3
						]):
							sectors_in_selection.append(sector)
					for sector: Sector in sectors_in_selection:
						owner.deselect_resource(sector)
					start_box_select = false
					start_box_deselect = false
					highlight_sectors.clear()
					start_box_select_position = Vector2.ZERO
					queue_redraw()
				if event.ctrl_pressed:
					if event.pressed:
						start_box_select = true
						start_box_deselect = true
						start_box_select_position = (get_global_mouse_position() + global_position)
					return
				if event.pressed:
					if owner.hovered_sector and owner.hovered_sector in owner.selected_sectors and len(owner.selected_faces) != 1:
						owner.deselect_resource(owner.hovered_sector)
					elif owner.hovered_face and owner.hovered_face in owner.selected_faces:
						owner.deselect_resource(owner.hovered_face)
				if event.shift_pressed:
					if event.pressed:
						holding_shift = true
						holding_right_mouse = true
					else:
						holding_shift = false
						holding_right_mouse = false


func handle_draw_mode_event(event: InputEvent) -> void:
	if not %BoxCheckBox.button_pressed:
		return
	
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					start_box_draw = true
					start_box_position = (get_global_mouse_position() + global_position).snappedf(snap)
				else:
					if start_box_draw == false:
						return
					
					if (start_box_position.x == (get_global_mouse_position() + global_position).snappedf(snap).x or 
							start_box_position.y == (get_global_mouse_position() + global_position).snappedf(snap).y
					):
						start_box_draw = false
						start_box_position = Vector2.ZERO
						queue_redraw()
						return
					
					var new_sector: Sector = map.add_sector(start_box_position * Roth.SCALE_2D_WORLD, (get_global_mouse_position() + global_position).snappedf(snap) * Roth.SCALE_2D_WORLD)
					start_box_draw = false
					start_box_position = Vector2.ZERO
					queue_redraw()
					show_vertices(false)
					
					# Check for merges
					for sector: Sector in map.sectors:
						for face_ref: WeakRef in sector.faces:
							var face: Face = face_ref.get_ref()
							for new_face_ref: WeakRef in new_sector.faces:
								var new_face: Face = new_face_ref.get_ref()
								if face.sister and face.sister.get_ref() == new_face:
									pass
								elif new_face.v2 == face.v1 and new_face.v1 == face.v2:
									face.sister = weakref(new_face)
									new_face.sister = weakref(face)
									face.initialize_mesh()
									new_face.initialize_mesh()
									show_vertices(false)
									queue_redraw()
					
					Roth.editor_action.emit(map.map_info, "Draw Box Sector")


func handle_object_mode_event(event: InputEvent) -> void:
	if not %ObjectCheckBox.button_pressed:
		return
	
	if event is InputEventKey and event.keycode == KEY_ALT and not owner.selected_objects.is_empty():
		if event.pressed:
			for object: ObjectRoth in owner.selected_objects:
				object.data.original_rotation = object.data.rotation
				object.data.original_pos_x = object.data.posX
				object.data.original_pos_y = object.data.posY
		else:
			for object: ObjectRoth in owner.selected_objects:
				object.node_2d.update_position()
			%EditObjectContainer.update_selections()
			Roth.editor_action.emit(map.map_info, "Rotate Object%s" % ("s" if len(owner.selected_objects) > 1 else ""))
	if holding_alt and event is InputEventMouseMotion and not owner.selected_objects.is_empty():
		var offset: Vector2 = (DisplayServer.mouse_get_position() - mouse_rotation_position)
		var rotation_deg: float = offset.x + offset.y
		var rotation_snap: float = 1.0
		if event.ctrl_pressed:
			rotation_snap = 15
		%"2DManipLabel".text = "Rotate: %d°" % snapped(rotation_deg, rotation_snap)
		var rotation_amount := deg_to_rad(snapped(rotation_deg, rotation_snap))
		var translation := Transform2D(rotation_amount, Vector2.ZERO)
		
		for object: ObjectRoth in owner.selected_objects:
			object.data.rotation = int(object.data.original_rotation+Roth.object_relative_degrees_to_rotation(snapped(rotation_deg, rotation_snap))) & 0xFF
			if holding_shift:
				var point := Vector2(-object.data.original_pos_x, object.data.original_pos_y)
				point = translation * (point - mouse_object_rotation_center) + mouse_object_rotation_center
				object.data.posX = -point.x
				object.data.posY = point.y
				object.node_2d.redraw()
		owner.redraw(owner.selected_objects)
	
	if holding_alt:
		return
	
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					var moused_over_object: ObjectRoth
					for object_node: ObjectRoth.ObjectNode2D in %Objects.get_children():
						if object_node.mouse_over:
							moused_over_object = object_node.ref
					if moused_over_object:
						if moused_over_object in owner.selected_objects:
							if event.shift_pressed:
								owner.deselect_resource(moused_over_object)
						else:
							owner.select_resource(moused_over_object, not event.shift_pressed)
						return
					start_box_select = true
					start_box_select_position = (get_global_mouse_position() + global_position)
				else:
					if start_box_select == false:
						return
					var starting_position := start_box_select_position
					var ending_position := (get_global_mouse_position() + global_position)
					var v2 := Vector2(ending_position.x, starting_position.y)
					var v3 := Vector2(starting_position.x, ending_position.y)
					var objects_in_selection: Array = []
					for object_node: ObjectRoth.ObjectNode2D in  %Objects.get_children():
						if Geometry2D.is_point_in_polygon(object_node.position, [
							starting_position,
							v2,
							ending_position,
							v3
						]):
							objects_in_selection.append(object_node)
					
					if objects_in_selection.is_empty():
						if not event.shift_pressed:
							owner.select_resource(null)
					else:
						if not event.shift_pressed:
							owner.select_resource(null)
						for object: ObjectRoth.ObjectNode2D in objects_in_selection:
							owner.select_resource(object.ref, false)
					start_box_select = false
					start_box_select_position = Vector2.ZERO
					queue_redraw()
			MOUSE_BUTTON_RIGHT:
				var moused_over_object: ObjectRoth
				for object_node: ObjectRoth.ObjectNode2D in %Objects.get_children():
					if object_node.mouse_over:
						moused_over_object = object_node.ref
				if moused_over_object:
					if moused_over_object not in owner.selected_objects:
						owner.select_resource(moused_over_object, not event.shift_pressed)
					%OnObjectContextPopupMenu.popup(Rect2(get_viewport().get_parent().global_position.x + event.global_position.x, get_viewport().get_parent().global_position.y + event.global_position.y, 0, 0))
					context_menu_object = moused_over_object
					return
				if event.pressed:
					mouse_paste_position = Vector2(
						get_global_mouse_position().x + global_position.x,
						get_global_mouse_position().y + global_position.y
					)
					%ObjectContextPopupMenu.popup(Rect2i(int(get_viewport().get_parent().global_position.x + event.global_position.x), int(get_viewport().get_parent().global_position.y + event.global_position.y), 0, 0))


func handle_vertex_mode_event(event: InputEvent) -> void:
	if not %VertexCheckBox.button_pressed:
		return
	
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					var moused_over_vertex: VertexNode
					for vertex_node: VertexNode in %Vertices.get_children():
						if vertex_node.mouse_over:
							moused_over_vertex = vertex_node
					if moused_over_vertex:
						if moused_over_vertex in owner.selected_vertex_nodes:
							if event.shift_pressed:
								owner.deselect_resource(moused_over_vertex)
						else:
							owner.select_resource(moused_over_vertex, not event.shift_pressed)
						return
					if not start_sector_split:
						start_box_select = true
						start_box_select_position = (get_global_mouse_position() + global_position)
				else:
					if start_box_select == false:
						return
					var starting_position := start_box_select_position
					var ending_position := (get_global_mouse_position() + global_position)
					var v2 := Vector2(ending_position.x, starting_position.y)
					var v3 := Vector2(starting_position.x, ending_position.y)
					var vertices_in_selection: Array = []
					for vertex_node: VertexNode in  %Vertices.get_children():
						if not vertex_node.split_vertex and Geometry2D.is_point_in_polygon(vertex_node.position, [
							starting_position,
							v2,
							ending_position,
							v3
						]):
							vertices_in_selection.append(vertex_node)
					
					if vertices_in_selection.is_empty():
						if not event.shift_pressed:
							owner.select_resource(null)
					else:
						if not event.shift_pressed:
							owner.select_resource(null)
						for vertex_node: VertexNode in vertices_in_selection:
							owner.select_resource(vertex_node, false)
					start_box_select = false
					start_box_select_position = Vector2.ZERO
					queue_redraw()


func handle_sfx_mode_event(event: InputEvent) -> void:
	if not %SFXCheckBox.button_pressed:
		return
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					var moused_over_sfx: SFX
					for sfx_node: SFX.SFXNode2D in %SFX.get_children():
						if sfx_node.mouse_over:
							moused_over_sfx = sfx_node.ref
					if moused_over_sfx:
						if moused_over_sfx in owner.selected_sfx:
							if event.shift_pressed:
								owner.deselect_resource(moused_over_sfx)
						else:
							owner.select_resource(moused_over_sfx, not event.shift_pressed)
						return
					start_box_select = true
					start_box_select_position = (get_global_mouse_position() + global_position)
				else:
					if start_box_select == false:
						return
					var starting_position := start_box_select_position
					var ending_position := (get_global_mouse_position() + global_position)
					var v2 := Vector2(ending_position.x, starting_position.y)
					var v3 := Vector2(starting_position.x, ending_position.y)
					var sfx_in_selection: Array = []
					for sfx_node: SFX.SFXNode2D in  %SFX.get_children():
						if Geometry2D.is_point_in_polygon(sfx_node.position, [
							starting_position,
							v2,
							ending_position,
							v3
						]):
							sfx_in_selection.append(sfx_node)
					
					if sfx_in_selection.is_empty():
						if not event.shift_pressed:
							owner.select_resource(null)
					else:
						if not event.shift_pressed:
							owner.select_resource(null)
						for sfx_node: SFX.SFXNode2D in sfx_in_selection:
							owner.select_resource(sfx_node.ref, false)
					start_box_select = false
					start_box_select_position = Vector2.ZERO
					queue_redraw()
			MOUSE_BUTTON_RIGHT:
				if event.pressed:
					var moused_over_sfx: SFX
					for sfx_node: SFX.SFXNode2D in %SFX.get_children():
						if sfx_node.mouse_over:
							moused_over_sfx = sfx_node.ref
					if moused_over_sfx:
						if moused_over_sfx not in owner.selected_sfx:
							owner.select_resource(moused_over_sfx, not event.shift_pressed)
						%OnSFXContextPopupMenu.popup(Rect2(get_viewport().get_parent().global_position.x + event.global_position.x, get_viewport().get_parent().global_position.y + event.global_position.y, 0, 0))
						context_menu_sfx = moused_over_sfx
						return
					mouse_paste_position = Vector2(
						get_global_mouse_position().x + global_position.x,
						get_global_mouse_position().y + global_position.y
					)
					%SFXContextPopupMenu.popup(Rect2i(int(get_viewport().get_parent().global_position.x + event.global_position.x), int(get_viewport().get_parent().global_position.y + event.global_position.y), 0, 0))

#endregion

#region Camera

func default_camera_bounds() -> void:
	minimum_x = -409.6
	maximum_x = 409.6
	minimum_y = -409.6
	maximum_y = 409.6


func update_camera_bounds() -> void:
	minimum_x = 10000
	minimum_y = 10000
	maximum_x = -10000
	maximum_y = -10000
	if not map:
		return
	if not map.sectors:
		default_camera_bounds()
		return
	for sector: Sector in map.sectors:
		for face_ref: WeakRef in sector.faces:
			var face: Face = face_ref.get_ref()
			minimum_x = min(minimum_x, face.v1.x / Roth.SCALE_2D_WORLD)
			minimum_x = min(minimum_x, face.v2.x / Roth.SCALE_2D_WORLD)
			minimum_y = min(minimum_y, face.v1.y / Roth.SCALE_2D_WORLD)
			minimum_y = min(minimum_y, face.v2.y / Roth.SCALE_2D_WORLD)
			
			maximum_x = max(maximum_x, face.v1.x / Roth.SCALE_2D_WORLD)
			maximum_x = max(maximum_x, face.v2.x / Roth.SCALE_2D_WORLD)
			maximum_y = max(maximum_y, face.v1.y / Roth.SCALE_2D_WORLD)
			maximum_y = max(maximum_y, face.v2.y / Roth.SCALE_2D_WORLD)


func update_camera_center() -> void:
	var center := Vector2(
		(maximum_x + minimum_x) / 2,
		(maximum_y + minimum_y) / 2,
	)
	%Camera2D.position = center


func update_camera_zoom() -> void:
	var size := Vector2(
		maximum_x - minimum_x,
		maximum_y - minimum_y
	)
	if size.x == 0 or size.y == 0:
		return
	
	var zoom_y: float = %Camera2D.get_viewport().size.y / size.y
	var zoom_x: float = %Camera2D.get_viewport().size.x / size.x
	var zoom: float = min(zoom_x, zoom_y) * 0.95
	
	var mouse_pos := get_global_mouse_position()
	%Camera2D.zoom = Vector2(zoom, zoom) * additional_zoom
	
	# Ensures zoom to mouse works at high speed
	if zooming:
		await get_tree().process_frame
		
	var new_mouse_pos := get_global_mouse_position()
	if zooming:
		%Camera2D.position += mouse_pos - new_mouse_pos
		zooming = false
	
	if prev_viewport_size != %Camera2D.get_viewport().size:
		prev_viewport_size = %Camera2D.get_viewport().size
		update_line_width(additional_zoom)

#endregion

#region Draw

func _draw() -> void:
	draw_grid()
	draw_sectors()
	update_camera_zoom()
	draw_box()
	draw_vertex_select()
	draw_sector_split()


func update_line_width(x: float) -> bool:
	var prev_line_width: float = line_width
	if %Camera2D.zoom.x > 60:
		line_width =  0.025
	elif %Camera2D.zoom.x > 20:
		line_width =  0.05
	elif %Camera2D.zoom.x > 5:
		line_width =  0.1
	elif %Camera2D.zoom.x > 4:
		line_width =  0.3
	elif %Camera2D.zoom.x > 3:
		line_width =  0.4
	elif %Camera2D.zoom.x > 2:
		line_width =  0.5
	elif %Camera2D.zoom.x > 1.5:
		line_width =  0.8
	elif %Camera2D.zoom.x > 1:
		line_width =  1
	else:
		line_width =  2
	
	if prev_line_width != line_width:
		update_vertex_size()
	
	return prev_line_width != line_width


func draw_grid() -> void:
	if not %GridCheckBox.button_pressed:
		return
	var camera: Camera2D = %Camera2D
	var viewport: Viewport = camera.get_viewport()
	var vp_size: Vector2i = viewport.size
	var cam_pos := camera.position
	var vp_right := (vp_size.x / camera.zoom.x)
	var vp_bottom := (vp_size.y / camera.zoom.y)
	
	var leftmost: = -vp_right + cam_pos.x
	var topmost: = -vp_bottom + cam_pos.y
	
	var left: float = ceil(leftmost / grid_size.x) * grid_size.x
	var bottommost: = vp_bottom + cam_pos.y
	for x in range(0, ((vp_size.x * 2 / camera.zoom.x) / grid_size.x) + 1):
		draw_line(Vector2(left, topmost), Vector2(left, bottommost), COLOR_AXIS if left == 0 else COLOR_GRID, line_width*0.95, true)
		left += grid_size.x

	var top: float = ceil(topmost / grid_size.y) * grid_size.y
	var rightmost: = vp_right + cam_pos.x
	for y in range(0, ((vp_size.y * 2 / camera.zoom.y) / grid_size.y) + 1):
		draw_line(Vector2(leftmost, top), Vector2(rightmost, top), COLOR_AXIS if top == 0 else COLOR_GRID, line_width*0.95, true)
		top += grid_size.y
	
	if leftmost < (-32768/Roth.SCALE_2D_WORLD):
		draw_line(Vector2(-32768/Roth.SCALE_2D_WORLD, min(bottommost, 32768/Roth.SCALE_2D_WORLD)), Vector2(-32768/Roth.SCALE_2D_WORLD, max(topmost, -32768/Roth.SCALE_2D_WORLD)), COLOR_AXIS_EDGE, line_width*0.95, true)
	if rightmost > (32768/Roth.SCALE_2D_WORLD):
		draw_line(Vector2(32768/Roth.SCALE_2D_WORLD, min(bottommost, 32768/Roth.SCALE_2D_WORLD)), Vector2(32768/Roth.SCALE_2D_WORLD, max(topmost, -32768/Roth.SCALE_2D_WORLD)), COLOR_AXIS_EDGE, line_width*0.95, true)
	if topmost < (-32768/Roth.SCALE_2D_WORLD):
		draw_line(Vector2(max(leftmost, -32768/Roth.SCALE_2D_WORLD), -32768/Roth.SCALE_2D_WORLD), Vector2(min(rightmost, 32768/Roth.SCALE_2D_WORLD), -32768/Roth.SCALE_2D_WORLD), COLOR_AXIS_EDGE, line_width*0.95, true)
	if bottommost > (32768/Roth.SCALE_2D_WORLD):
		draw_line(Vector2(max(leftmost, -32768/Roth.SCALE_2D_WORLD), 32768/Roth.SCALE_2D_WORLD), Vector2(min(rightmost, 32768/Roth.SCALE_2D_WORLD), 32768/Roth.SCALE_2D_WORLD), COLOR_AXIS_EDGE, line_width*0.95, true)


func draw_sectors() -> void:
	if not map:
		return
	
	for sector: Sector in map.sectors:
		if sector.hidden:
			continue
		for face_ref: WeakRef in sector.faces:
			var face: Face = face_ref.get_ref()
			if face.sister:
				if not face.sister.get_ref():
					continue
				if face.sector.data.floorHeight != face.sister.get_ref().sector.data.floorHeight:
					draw_line(Vector2(face.v1.x/Roth.SCALE_2D_WORLD, face.v1.y/Roth.SCALE_2D_WORLD), Vector2(face.v2.x/Roth.SCALE_2D_WORLD, face.v2.y/Roth.SCALE_2D_WORLD), Color.BLUE, line_width, true)
					
				else:
					draw_line(Vector2(face.v1.x/Roth.SCALE_2D_WORLD, face.v1.y/Roth.SCALE_2D_WORLD), Vector2(face.v2.x/Roth.SCALE_2D_WORLD, face.v2.y/Roth.SCALE_2D_WORLD), Color.STEEL_BLUE, line_width*0.5, true)
			if not face.sister:
				draw_line(Vector2(face.v1.x/Roth.SCALE_2D_WORLD, face.v1.y/Roth.SCALE_2D_WORLD), Vector2(face.v2.x/Roth.SCALE_2D_WORLD, face.v2.y/Roth.SCALE_2D_WORLD), Color.WHITE, line_width, true)
	
	if %SectorCheckBox.button_pressed:
	
		if owner.hovered_sector and len(owner.selected_faces) <= 1:
			for face_ref: WeakRef in owner.hovered_sector.faces:
				var face: Face = face_ref.get_ref()
				draw_line(Vector2(face.v1.x/Roth.SCALE_2D_WORLD, face.v1.y/Roth.SCALE_2D_WORLD), Vector2(face.v2.x/Roth.SCALE_2D_WORLD, face.v2.y/Roth.SCALE_2D_WORLD), Color.CORAL, line_width*2, true)
				var direction: Vector2 = (face.v2 - face.v1).normalized()
				var perendicular := Vector2(direction.y, -direction.x)
				
				var v_center := Vector2(
					(face.v1.x + face.v2.x) / 2,
					(face.v1.y + face.v2.y) / 2
				)
				var v_center_2: Vector2 = v_center + perendicular * 100 * line_width
				draw_line(v_center/Roth.SCALE_2D_WORLD, v_center_2/Roth.SCALE_2D_WORLD, Color.CORAL, line_width*2, true)
		
		for sector: Sector in highlight_sectors:
			if sector.hidden:
				continue
			if sector.map_info != map.map_info:
				continue
			for face_ref: WeakRef in sector.faces:
				var face: Face = face_ref.get_ref()
				draw_line(Vector2(face.v1.x/Roth.SCALE_2D_WORLD, face.v1.y/Roth.SCALE_2D_WORLD), Vector2(face.v2.x/Roth.SCALE_2D_WORLD, face.v2.y/Roth.SCALE_2D_WORLD), Color.CORAL, line_width*2, true)
				var direction: Vector2 = (face.v2 - face.v1).normalized()
				var perendicular := Vector2(direction.y, -direction.x)
				
				var v_center := Vector2(
					(face.v1.x + face.v2.x) / 2,
					(face.v1.y + face.v2.y) / 2
				)
				var v_center_2: Vector2 = v_center + perendicular * 100 * line_width
				draw_line(v_center/Roth.SCALE_2D_WORLD, v_center_2/Roth.SCALE_2D_WORLD, Color.CORAL, line_width*2, true)
		
		for sector: Sector in owner.selected_sectors:
			if sector.hidden:
				continue
			if sector.map_info != map.map_info:
				continue
			if start_box_deselect and sector in highlight_sectors:
				continue
			for face_ref: WeakRef in sector.faces:
				var face: Face = face_ref.get_ref()
				draw_line(Vector2(face.v1.x/Roth.SCALE_2D_WORLD, face.v1.y/Roth.SCALE_2D_WORLD), Vector2(face.v2.x/Roth.SCALE_2D_WORLD, face.v2.y/Roth.SCALE_2D_WORLD), Color.ORANGE, line_width*2, true)
				var direction: Vector2 = (face.v2 - face.v1).normalized()
				var perendicular := Vector2(direction.y, -direction.x)
				
				var v_center := Vector2(
					(face.v1.x + face.v2.x) / 2,
					(face.v1.y + face.v2.y) / 2
				)
				var v_center_2: Vector2 = v_center + perendicular * 100 * line_width
				draw_line(v_center/Roth.SCALE_2D_WORLD, v_center_2/Roth.SCALE_2D_WORLD, Color.ORANGE, line_width*2, true)
		
		if owner.hovered_face:
			draw_line(Vector2(owner.hovered_face.v1.x/Roth.SCALE_2D_WORLD, owner.hovered_face.v1.y/Roth.SCALE_2D_WORLD), Vector2(owner.hovered_face.v2.x/Roth.SCALE_2D_WORLD, owner.hovered_face.v2.y/Roth.SCALE_2D_WORLD), Color.WEB_PURPLE, line_width*2, true)
			var direction: Vector2 = (owner.hovered_face.v2 - owner.hovered_face.v1).normalized()
			var perendicular := Vector2(direction.y, -direction.x)
			
			var v_center := Vector2(
				(owner.hovered_face.v1.x + owner.hovered_face.v2.x) / 2,
				(owner.hovered_face.v1.y + owner.hovered_face.v2.y) / 2
			)
			var v_center_2: Vector2 = v_center + perendicular * 100 * line_width
			draw_line(v_center/Roth.SCALE_2D_WORLD, v_center_2/Roth.SCALE_2D_WORLD, Color.WEB_PURPLE, line_width*2, true)
		
		#if selected_face:
			#draw_line(Vector2(selected_face.v1.x/Roth.SCALE_2D_WORLD, selected_face.v1.y/Roth.SCALE_2D_WORLD), Vector2(selected_face.v2.x/Roth.SCALE_2D_WORLD, selected_face.v2.y/Roth.SCALE_2D_WORLD), Color.PURPLE, line_width*2, true)
		
		for face: Face in owner.selected_faces:
			if face.map_info != map.map_info:
				continue
			draw_line(Vector2(face.v1.x/Roth.SCALE_2D_WORLD, face.v1.y/Roth.SCALE_2D_WORLD), Vector2(face.v2.x/Roth.SCALE_2D_WORLD, face.v2.y/Roth.SCALE_2D_WORLD), Color.PURPLE, line_width*2, true)
			var direction: Vector2 = (face.v2 - face.v1).normalized()
			var perendicular := Vector2(direction.y, -direction.x)
			var v_center := Vector2(
				(face.v1.x + face.v2.x) / 2,
				(face.v1.y + face.v2.y) / 2
			)
			var v_center_2: Vector2 = v_center + perendicular * 100 * line_width
			draw_line(v_center/Roth.SCALE_2D_WORLD, v_center_2/Roth.SCALE_2D_WORLD, Color.PURPLE, line_width*2, true)
		
		if owner.paste_sectors_mode:
			for sector: Sector in owner.current_pasted_sector_data:
				for face: Face in sector.faces:
					draw_line(Vector2(face.v1.x/Roth.SCALE_2D_WORLD, face.v1.y/Roth.SCALE_2D_WORLD), Vector2(face.v2.x/Roth.SCALE_2D_WORLD, face.v2.y/Roth.SCALE_2D_WORLD), Color.FUCHSIA, line_width*2, true)
					var direction: Vector2 = (face.v2 - face.v1).normalized()
					var perendicular := Vector2(direction.y, -direction.x)
					
					var v_center := Vector2(
						(face.v1.x + face.v2.x) / 2,
						(face.v1.y + face.v2.y) / 2
					)
					var v_center_2: Vector2 = v_center + perendicular * 100 * line_width
					draw_line(v_center/Roth.SCALE_2D_WORLD, v_center_2/Roth.SCALE_2D_WORLD, Color.FUCHSIA, line_width*2, true)
			if holding_ctrl and not holding_alt:
				draw_dashed_line(owner.original_copied_sector_center/Roth.SCALE_2D_WORLD, owner.current_copied_sector_center/Roth.SCALE_2D_WORLD, Color.GRAY, line_width, 2.0, false, true)
	
	if Settings.settings.get("options", {}).get("highlight_concave_sectors", false):
		for sector: Sector in concave_sectors:
			for face_ref: WeakRef in sector.faces:
				var face: Face = face_ref.get_ref()
				draw_line(Vector2(face.v1.x/Roth.SCALE_2D_WORLD, face.v1.y/Roth.SCALE_2D_WORLD), Vector2(face.v2.x/Roth.SCALE_2D_WORLD, face.v2.y/Roth.SCALE_2D_WORLD), Color.RED, line_width*2, true)


func draw_box() -> void:
	if not start_box_draw:
		return
	var current_mouse: Vector2 = (get_global_mouse_position() + global_position).snappedf(snap)
	var size: Vector2 = current_mouse - start_box_position
	draw_rect(Rect2(start_box_position.x, start_box_position.y, size.x, size.y), Color.GHOST_WHITE, false, line_width, true)


func draw_vertex_select() -> void:
	if not start_box_select:
		return
	var current_mouse: Vector2 = (get_global_mouse_position() + global_position)
	draw_dashed_line(start_box_select_position, Vector2(current_mouse.x, start_box_select_position.y), Color.GRAY, line_width, 1.0, true, true)
	draw_dashed_line(start_box_select_position, Vector2(start_box_select_position.x, current_mouse.y), Color.GRAY, line_width, 1.0, true, true)
	draw_dashed_line(current_mouse, Vector2(current_mouse.x, start_box_select_position.y), Color.GRAY, line_width, 1.0, true, true)
	draw_dashed_line(current_mouse, Vector2(start_box_select_position.x, current_mouse.y), Color.GRAY, line_width, 1.0, true, true)


func draw_sector_split() -> void:
	if not start_sector_split or not start_sector_split_vertex:
		return
	var current_mouse: Vector2 = (get_global_mouse_position() + global_position)
	var nearest_vertex: VertexNode = find_nearest_vertex(current_mouse)
	if nearest_vertex:
		draw_line(start_sector_split_vertex.coordinate / Roth.SCALE_2D_WORLD, nearest_vertex.global_position, Color.MAGENTA, line_width, true)

#endregion

#region Map

func setup(p_map: Map, p_reset_camera: bool = true) -> void:
	if map:
		close_map(map.map_info)
	map = p_map
	%MapNameLabel.text = map.map_info.name.to_upper()
	if not map.name_changed.is_connected(_on_map_name_changed):
		map.name_changed.connect(_on_map_name_changed)
	if p_reset_camera:
		update_camera_bounds()
		update_camera_center()
	update_camera_zoom()
	update_line_width(additional_zoom)
	_on_sector_check_box_toggled(%SectorCheckBox.button_pressed)
	_on_object_check_box_toggled(%ObjectCheckBox.button_pressed)
	_on_sfx_check_box_toggled(%SFXCheckBox.button_pressed)
	_on_vertex_check_box_toggled(%VertexCheckBox.button_pressed)
	_on_box_check_box_toggled(%BoxCheckBox.button_pressed)
	queue_redraw()
	%CountAndSizeContainer.recalculate()
	update_concave_sectors()


func close_map(map_info: Dictionary, p_reset_camera: bool = true) -> bool:
	if map and map.map_info == map_info:
		if map.name_changed.is_connected(_on_map_name_changed):
			map.name_changed.disconnect(_on_map_name_changed)
		map = null
		%MapNameLabel.text = "No Map Loaded"
		zooming = false
		holding_left_mouse = false
		holding_right_mouse = false
		holding_shift = false
		holding_ctrl = false
		start_box_select = false
		start_box_deselect = false
		highlight_sectors.clear()
		%CountAndSizeContainer.recalculate()
		update_concave_sectors()
		owner.select_resource(null)
		if p_reset_camera:
			default_camera_bounds()
			update_camera_center()
			additional_zoom = 1
			update_camera_zoom()
		queue_redraw()
		for child: Node2D in %Objects.get_children():
			child.queue_free()
		for child: Node2D in %SFX.get_children():
			child.queue_free()
		for child: Node2D in %Vertices.get_children():
			child.queue_free()
		return true
	return false


func _on_map_name_changed(new_map_name: String) -> void:
	%MapNameLabel.text = new_map_name


func update_concave_sectors() -> void:
	concave_sectors.clear()
	if not map:
		return
	concave_sectors = map.find_concave_sectors()
	queue_redraw()

#endregion

#region Objects

func show_objects() -> void:
	if not map:
		return
	for child: Node in %Objects.get_children():
		child.queue_free()
	await get_tree().process_frame
	for object: ObjectRoth in map.objects:
		if object.sector.get_ref().hidden:
			continue
		var object_node: ObjectRoth.ObjectNode2D = object.get_node_2d()
		object_node.object_dragged.connect(_on_object_dragged)
		object_node.object_drag_ended.connect(_on_object_drag_ended)
		%Objects.add_child(object_node)
	update_selections()


func hide_objects() -> void:
	for child: Node in %Objects.get_children():
		child.queue_free()


func _on_object_context_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			var new_object := ObjectRoth.new_object(map.map_info, mouse_paste_position * Roth.SCALE_2D_WORLD)
			if not new_object:
				return
			map.add_object(new_object)
			add_object_to_2d_map(new_object)
			Roth.editor_action.emit(map.map_info, "Add Object")
		1:
			owner.select_resource(null)
			var origin := Vector2(-owner.copied_object_data[0].data.posX, owner.copied_object_data[0].data.posY)
			for each_object: ObjectRoth in owner.copied_object_data:
				var offset := origin - Vector2(-each_object.data.posX, each_object.data.posY)
				var new_object := ObjectRoth.new_from_copied_object(each_object, (mouse_paste_position * Roth.SCALE_2D_WORLD) - offset)
				if not new_object:
					continue
				map.add_object(new_object)
				add_object_to_2d_map(new_object)
				owner.select_resource(new_object, false)
			Roth.editor_action.emit(map.map_info, "Paste Object%s" % ("s" if len(owner.copied_object_data) > 1 else ""))


func _on_on_object_context_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			if context_menu_object not in owner.selected_objects:
				return
			owner.selected_objects.erase(context_menu_object)
			owner.selected_objects.insert(0, context_menu_object)
			owner.copy_objects(owner.selected_objects)
		1:
			for object: ObjectRoth in owner.selected_objects:
				object.delete()
			Roth.editor_action.emit(map.map_info, "Delete Object%s" % ("s" if len(owner.selected_objects) > 1 else ""))
			owner.select_resource(null)


func add_object_to_2d_map(new_object: ObjectRoth) -> void:
	if not %ObjectCheckBox.button_pressed:
		return
	var object_node: ObjectRoth.ObjectNode2D = new_object.get_node_2d()
	object_node.object_dragged.connect(_on_object_dragged)
	object_node.object_drag_ended.connect(_on_object_drag_ended)
	%Objects.add_child(object_node)


func _on_object_dragged(node_dragged: ObjectRoth.ObjectNode2D, relative: Vector2) -> void:
	for object_node: ObjectRoth.ObjectNode2D in %Objects.get_children():
		if object_node != node_dragged:
			object_node.move(relative)


func _on_object_drag_ended(object: ObjectRoth.ObjectNode2D) -> void:
	for object_node: ObjectRoth.ObjectNode2D in %Objects.get_children():
		if object_node != object:
			object_node.end_drag()
	Roth.editor_action.emit(map.map_info, "Move Objects")
	%EditObjectContainer.update_selections()
	%Map3D.update_selections()

#endregion

#region SFX

func show_sfx() -> void:
	if not map:
		return
	for child: Node in %SFX.get_children():
		child.queue_free()
	await get_tree().process_frame
	for sfx: SFX in map.sound_effects:
		var sfx_node: SFX.SFXNode2D = sfx.get_node_2d()
		sfx_node.object_dragged.connect(_on_sfx_dragged)
		sfx_node.object_drag_ended.connect(_on_sfx_drag_ended)
		%SFX.add_child(sfx_node)
	update_selections()


func hide_sfx() -> void:
	for child: Node in %SFX.get_children():
		child.queue_free()


func _on_sfx_context_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			var new_sfx := SFX.new_object(map.map_info, mouse_paste_position * Roth.SCALE_2D_WORLD)
			if not new_sfx:
				return
			map.add_sfx(new_sfx)
			add_sfx_to_2d_map(new_sfx)
			Roth.editor_action.emit(map.map_info, "Add SFX")
		1:
			owner.select_resource(null)
			var origin := Vector2(-owner.copied_sfx_data[0].data.unk0x00, owner.copied_sfx_data[0].data.unk0x02)
			for each_sfx: SFX in owner.copied_sfx_data:
				var offset := origin - Vector2(-each_sfx.data.unk0x00, each_sfx.data.unk0x02)
				var new_sfx := SFX.new_from_copied_object(each_sfx, (mouse_paste_position * Roth.SCALE_2D_WORLD) - offset)
				if not each_sfx:
					continue
				map.add_sfx(new_sfx)
				add_sfx_to_2d_map(new_sfx)
				owner.select_resource(new_sfx, false)
			Roth.editor_action.emit(map.map_info, "Paste SFX%s" % ("s" if len(owner.copied_sfx_data) > 1 else ""))


func _on_on_sfx_context_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			if context_menu_sfx not in owner.selected_sfx:
				return
			owner.selected_sfx.erase(context_menu_sfx)
			owner.selected_sfx.insert(0, context_menu_sfx)
			owner.copy_sfx(owner.selected_sfx)
		1:
			for sfx: SFX in owner.selected_sfx:
				sfx.delete()
			Roth.editor_action.emit(map.map_info, "Delete SFX%s" % ("s" if len(owner.selected_sfx) > 1 else ""))
			owner.select_resource(null)


func _on_sfx_dragged(node_dragged: SFX.SFXNode2D, relative: Vector2) -> void:
	for sfx_node: SFX.SFXNode2D in %SFX.get_children():
		if sfx_node != node_dragged:
			sfx_node.move(relative)


func _on_sfx_drag_ended(object: SFX.SFXNode2D) -> void:
	for sfx_node: SFX.SFXNode2D in %SFX.get_children():
		if sfx_node != object:
			sfx_node.end_drag()
	Roth.editor_action.emit(map.map_info, "Move SFX")
	%Map3D.update_selections()


func add_sfx_to_2d_map(new_sfx: SFX) -> void:
	if not %SFXCheckBox.button_pressed:
		return
	var sfx_node: SFX.SFXNode2D = new_sfx.get_node_2d()
	sfx_node.object_dragged.connect(_on_sfx_dragged)
	sfx_node.object_drag_ended.connect(_on_sfx_drag_ended)
	%SFX.add_child(sfx_node)

#endregion

#region Vertices

func show_vertices(allow_move: bool) -> void:
	if not map:
		return
	hide_vertices()
	last_allow_move = allow_move
	var vertices := {}
	var split_vertices := {}
	for sector: Sector in map.sectors:
		for face_ref: WeakRef in sector.faces:
			var face: Face = face_ref.get_ref()
			face.v1 = face.v1.snappedf(2.0)
			if face.v1 not in vertices:
				vertices[face.v1] = {"faces": [face], "sectors": []}
			else:
				if face not in vertices[face.v1].faces:
					vertices[face.v1].faces.append(face)
			if sector not in vertices[face.v1].sectors:
				vertices[face.v1].sectors.append(sector)
				
			face.v2 = face.v2.snappedf(2.0)
			if face.v2 not in vertices:
				vertices[face.v2] = { "faces": [face], "sectors": []}
			else:
				if face not in vertices[face.v2].faces:
					vertices[face.v2].faces.append(face)
			if sector not in vertices[face.v2].sectors:
				vertices[face.v2].sectors.append(sector)
			
			var split_vertex := (face.v1 + face.v2) / 2
			if split_vertex not in split_vertices:
				split_vertices[split_vertex] = {"faces": [face], "sectors": []}
			else:
				if face not in split_vertices[split_vertex].faces:
					split_vertices[split_vertex].faces.append(face)
			if sector not in split_vertices[split_vertex].sectors:
				split_vertices[split_vertex].sectors.append(sector)
	
	for vertex: Vector2 in split_vertices:
		var vertex_node := VertexNode.new(map.map_info, vertex, split_vertices[vertex], allow_move, line_width, true)
		vertex_node.face_split.connect(_on_face_split)
		%Vertices.add_child(vertex_node)
	for vertex: Vector2 in vertices:
		var vertex_node := VertexNode.new(map.map_info, vertex, vertices[vertex], allow_move, line_width)
		vertex_node.vertex_deleted.connect(_on_vertex_deleted)
		vertex_node.start_sector_split.connect(_on_sector_split)
		vertex_node.vertex_dragged.connect(_on_vertex_dragged)
		vertex_node.vertex_drag_canceled.connect(_on_vertex_drag_canceled)
		vertex_node.vertex_drag_ended.connect(_on_vertex_drag_ended)
		%Vertices.add_child(vertex_node)


func hide_vertices() -> void:
	for child: Node in %Vertices.get_children():
		child.queue_free()


func _on_vertex_deleted() -> void:
	Roth.editor_action.emit(map.map_info, "Delete Vertex")
	show_vertices(last_allow_move)
	queue_redraw()


func _on_face_split() -> void:
	Roth.editor_action.emit(map.map_info, "Split Face")
	show_vertices(last_allow_move)
	queue_redraw()


func _on_sector_split(starting_vertex_node: VertexNode) -> void:
	var selected_vertices_count: int = 0
	for vertex_node: VertexNode in %Vertices.get_children():
		if vertex_node.is_selected:
			selected_vertices_count += 1
	if selected_vertices_count != 0:
		return
	start_sector_split = true
	start_sector_split_vertex = starting_vertex_node


func _on_vertex_dragged(node_dragged: VertexNode, relative: Vector2) -> void:
	vertex_drag_amount += (-relative * Roth.SCALE_2D_WORLD).snappedf(2)
	%"2DManipLabel".text = "%s" % vertex_drag_amount
	queue_redraw()
	for vertex_node: VertexNode in %Vertices.get_children():
		if vertex_node != node_dragged:
			vertex_node.move(relative)
	for vertex_node: VertexNode in %Vertices.get_children():
		if vertex_node.split_vertex:
			vertex_node.redraw_split_vertex()


func _on_vertex_drag_canceled() -> void:
	vertex_drag_amount = Vector2.ZERO
	%"2DManipLabel".text = ""
	queue_redraw()
	for vertex_node: VertexNode in %Vertices.get_children():
		if vertex_node.split_vertex:
			vertex_node.redraw_split_vertex()


func _on_vertex_drag_ended(vertex: VertexNode) -> void:
	for vertex_node: VertexNode in %Vertices.get_children():
		if vertex_node != vertex:
			vertex_node.drag_ended()
	
	vertex_drag_amount = Vector2.ZERO
	%"2DManipLabel".text = ""
	
	var bad_merge_sectors: Array = []
	var unique_sectors: Array = []
	var bad_face_merge: bool = false
	for vertex_face: Face in vertex.faces:
		if vertex_face.sector not in unique_sectors:
			unique_sectors.append(vertex_face.sector)
		for vertex_face_2_ref: WeakRef in vertex_face.sector.faces:
			var vertex_face_2: Face = vertex_face_2_ref.get_ref()
			if vertex_face.v1.is_equal_approx(vertex_face_2.v2) and vertex_face.v2.is_equal_approx(vertex_face_2.v1) and vertex_face.sector == vertex_face_2.sector:
				bad_face_merge = true
				#print("Incorrect Face Merge")
	
	for sector: Sector in unique_sectors:
		if Utility.are_points_collinear_2d(sector.get_vertices()):
			#print("Sector Merge Wanted")
			bad_merge_sectors.append(sector)
	
	var faces_merged: bool = false
	var sectors_merged: bool = false
	var vertices_merged: bool = false
	
	if bad_merge_sectors.is_empty() and not bad_face_merge:
		for sector: Sector in map.sectors:
			for face_ref: WeakRef in sector.faces:
				var face: Face = face_ref.get_ref()
				for vertex_face: Face in vertex.faces:
					if face.sister and face.sister.get_ref() == vertex_face:
						pass
					elif vertex_face.v2.is_equal_approx(face.v1) and vertex_face.v1.is_equal_approx(face.v2):
						face.sister = weakref(vertex_face)
						vertex_face.sister = weakref(face)
						face.initialize_mesh()
						vertex_face.initialize_mesh()
						faces_merged = true
	elif not bad_merge_sectors.is_empty():
		for sector: Sector in bad_merge_sectors:
			for face: WeakRef in sector.faces:
				if face.get_ref() in vertex.faces:
					if face.get_ref().sister:
						#print("Sector Merge Happened")
						map.merge_sectors(face.get_ref().sister.get_ref())
						break
		sectors_merged = true
	
	if faces_merged:
		show_vertices(last_allow_move)
		queue_redraw()
		Roth.editor_action.emit(map.map_info, "Merge Faces")
	else:
		for face: Face in vertex.faces:
			if face.face_length == 0 and face.sector:
				face.sector.delete_face(face)
				vertices_merged = true
				break
		
		if sectors_merged:
			show_vertices(last_allow_move)
			queue_redraw()
			Roth.editor_action.emit(map.map_info, "Merge Sectors")
		elif vertices_merged:
			show_vertices(last_allow_move)
			queue_redraw()
			Roth.editor_action.emit(map.map_info, "Merge Vertices")
		elif bad_face_merge:
			vertex.revert_last_position()
		else:
			Roth.editor_action.emit(map.map_info, "Move Vertices")


func find_nearest_vertex(p_mouse_position: Vector2) -> VertexNode:
	var minimum: float = 1000000.0
	var closest: VertexNode
	for vertex_node: VertexNode in %Vertices.get_children():
		if vertex_node.split_vertex:
			continue
		for sector: Sector in start_sector_split_vertex.sectors:
			if sector not in vertex_node.sectors:
				continue
			else:
				var skip: bool = false
				for face: Face in start_sector_split_vertex.faces:
					if face in vertex_node.faces:
						skip = true
						break
				if skip:
					continue
				var distance_squared := (vertex_node.global_position - p_mouse_position).length_squared()
				if distance_squared < minimum:
					minimum = distance_squared
					closest = vertex_node
	var distance_from_start_vertex := (start_sector_split_vertex.global_position - p_mouse_position).length_squared()
	if distance_from_start_vertex < minimum:
		return
	return closest

#endregion

#region Helper

func update_selections() -> void:
	%Map2D.queue_redraw()
	for object_node: ObjectRoth.ObjectNode2D in %Objects.get_children():
		if object_node.ref in owner.selected_objects:
			object_node.select()
		else:
			object_node.deselect()
	for sfx_node: SFX.SFXNode2D in %SFX.get_children():
		if sfx_node.ref in owner.selected_sfx:
			sfx_node.select()
		else:
			sfx_node.deselect()
	for vertex_node: VertexNode in %Vertices.get_children():
		if vertex_node in owner.selected_vertex_nodes:
			vertex_node.select()
		else:
			vertex_node.deselect()


func is_mouse_inside_sector(sector: Sector) -> bool:
	var points := sector.vertices.slice(0,-1)
	return Geometry2D.is_point_in_polygon((get_global_mouse_position() + global_position) * Roth.SCALE_2D_WORLD, points)


func check_for_hover() -> void:
	if not map or not has_focus:
		return
	if start_box_select and not start_box_deselect:
		highlight_sectors.clear()
		var starting_position := start_box_select_position
		var ending_position := (get_global_mouse_position() + global_position)
		var v2 := Vector2(ending_position.x, starting_position.y)
		var v3 := Vector2(starting_position.x, ending_position.y)
		for sector: Sector in map.sectors:
			if Geometry2D.is_point_in_polygon(sector.get_center()/Roth.SCALE_2D_WORLD, [
				start_box_select_position,
				v2,
				ending_position,
				v3
			]):
				highlight_sectors.append(sector)
	elif start_box_deselect:
		highlight_sectors.clear()
		var starting_position := start_box_select_position
		var ending_position := (get_global_mouse_position() + global_position)
		var v2 := Vector2(ending_position.x, starting_position.y)
		var v3 := Vector2(starting_position.x, ending_position.y)
		for sector: Sector in map.sectors:
			if Geometry2D.is_point_in_polygon(sector.get_center()/Roth.SCALE_2D_WORLD, [
				start_box_select_position,
				v2,
				ending_position,
				v3
			]) and sector in owner.selected_sectors:
				highlight_sectors.append(sector)
	elif not holding_ctrl:
		if skip_sector_hover == skip_sector_hover_prev:
			if owner.hovered_sector and is_mouse_inside_sector(owner.hovered_sector):
				if len(owner.selected_sectors) <= 1:
					check_for_face_hover(owner.hovered_sector)
				return
		skip_sector_hover_prev = skip_sector_hover
		var sectors_to_skip: int = skip_sector_hover
		for sector: Sector in map.sectors:
			if sector.hidden:
				continue
			if is_mouse_inside_sector(sector):
				if sectors_to_skip > 0:
					sectors_to_skip -= 1
					continue
				if len(owner.selected_faces) <= 1:
					if owner.hovered_sector != sector:
						owner.hovered_sector = sector
						if holding_left_mouse:
							owner.select_resource(owner.hovered_sector, not holding_shift)
						elif holding_right_mouse:
							print("Q")
							owner.deselect_resource(owner.hovered_sector)
						queue_redraw()
				check_for_face_hover(sector)
				return
		if skip_sector_hover > 0:
			skip_sector_hover = 0
			check_for_hover()
			return
		owner.hovered_sector = null
		owner.hovered_face = null
		queue_redraw()


func check_for_face_hover(sector: Sector) -> void:
	if len(owner.selected_sectors) > 1:
		return
	var found: bool = false
	var smallest_distance: float = 100.0
	for face_ref: WeakRef in sector.faces:
		var face: Face = face_ref.get_ref()
		var distance: float = Utility.distance_to_face((get_global_mouse_position() + global_position) * Roth.SCALE_2D_WORLD, face)
		if distance < smallest_distance and distance < max(100 / %Camera2D.zoom.x, 8):
			smallest_distance = distance
			found = true
			if owner.hovered_face != face:
				owner.hovered_face = face
				if holding_left_mouse and len(owner.selected_sectors) == 0:
					owner.select_resource(owner.hovered_face, not holding_shift)
				elif holding_right_mouse:
					owner.deselect_resource(owner.hovered_face)
				queue_redraw()
	if not found:
		owner.hovered_face = null
		queue_redraw()

#endregion

#region Options

func _on_sector_check_box_toggled(toggled_on: bool) -> void:
	if not toggled_on:
		owner.paste_sectors_mode = false
	queue_redraw()


func _on_object_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		show_objects()
	else:
		hide_objects()


func _on_sfx_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		show_sfx()
	else:
		hide_sfx()


func _on_vertex_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		show_vertices(true)
	else:
		hide_vertices()


func _on_box_check_box_toggled(_toggled_on: bool) -> void:
	if _toggled_on:
		show_vertices(false)
	else:
		if not %VertexCheckBox.button_pressed:
			hide_vertices()


func _on_grid_check_box_toggled(toggled_on: bool) -> void:
	queue_redraw()
	if toggled_on:
		%GridEdit.editable = true
	else:
		%GridEdit.editable = false


func _on_grid_edit_value_changed(value: float) -> void:
	grid_size = Vector2.ONE * value / Roth.SCALE_2D_WORLD
	queue_redraw()


func _on_snap_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		snap = %SnapEdit.value / Roth.SCALE_2D_WORLD
		%SnapEdit.editable = true
	else:
		snap = 0.2
		%SnapEdit.editable = false


func _on_snap_edit_value_changed(value: float) -> void:
	snap = value / Roth.SCALE_2D_WORLD

#endregion

#region Map Actions

func unmerge_vertices() -> void:
	var selected_vertices := []
	for vertex_node: VertexNode in %Vertices.get_children():
		if vertex_node.is_selected and not vertex_node.split_vertex:
			selected_vertices.append(vertex_node.coordinate)
			vertex_node.queue_free()
	
	if selected_vertices.is_empty():
		return
	
	for sector: Sector in map.sectors:
		var vertices := {}
		for face_ref: WeakRef in sector.faces:
			var face: Face = face_ref.get_ref()
			if face.v1 in selected_vertices:
				if face.v1 not in vertices:
					vertices[face.v1] = {"faces": [face], "sectors": [sector]}
					if face.sister:
						face.sister = null
						face.initialize_mesh()
						queue_redraw()
				else:
					if face not in vertices[face.v1].faces:
						vertices[face.v1].faces.append(face)
						if face.sister:
							face.sister = null
							face.initialize_mesh()
							queue_redraw()
			if face.v2 in selected_vertices:
				if face.v2 not in vertices:
					vertices[face.v2] = {"faces": [face], "sectors": [sector]}
					if face.sister:
						face.sister = null
						face.initialize_mesh()
						queue_redraw()
				else:
					if face not in vertices[face.v2].faces:
						vertices[face.v2].faces.append(face)
						if face.sister:
							face.sister = null
							face.initialize_mesh()
							queue_redraw()
		
		for vertex: Vector2 in vertices:
			var vertex_node := VertexNode.new(map.map_info, vertex, vertices[vertex], last_allow_move, line_width)
			vertex_node.vertex_deleted.connect(_on_vertex_deleted)
			vertex_node.start_sector_split.connect(_on_sector_split)
			vertex_node.vertex_dragged.connect(_on_vertex_dragged)
			vertex_node.vertex_drag_ended.connect(_on_vertex_drag_ended)
			%Vertices.add_child(vertex_node)
	
	Roth.editor_action.emit(map.map_info, "Unmerge Vertices")


func check_for_split(nearest_vertex: VertexNode) -> void:
	if not nearest_vertex:
		return
	
	for face: Face in start_sector_split_vertex.faces:
		if face in nearest_vertex.faces:
			return
	for sector: Sector in start_sector_split_vertex.sectors:
		if sector in nearest_vertex.sectors:
			map.split_sector(sector, start_sector_split_vertex, nearest_vertex)
			Roth.editor_action.emit(map.map_info, "Split Sector")
			owner.select_resource(sector)
			show_vertices(last_allow_move)


func update_vertex_size() -> void:
	if %VertexCheckBox.button_pressed or %BoxCheckBox.button_pressed:
		for vertex_node: VertexNode in %Vertices.get_children():
			vertex_node.redraw(line_width)

#endregion
