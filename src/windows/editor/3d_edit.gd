extends Node3D

var mouse_inside: bool = true
var moused_over_resource: RefCounted
var shift_switched:bool = false
var selected_nodes: Array = []
var has_focus: bool = false :
	set(value):
		has_focus = value
		if has_focus == false:
			if moused_over_resource and moused_over_resource not in owner.selected_faces and moused_over_resource not in owner.selected_sectors:
				moused_over_resource.node.unhighlight()
				moused_over_resource = null
var picking_enabled: bool = true
var copied_face_texture_data: Dictionary = {}
var copied_face_data: Dictionary = {}
var copied_sector_data: Dictionary = {}
var copied_platform_data: Dictionary = {}
var show_selection_highlight: bool = true

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_MOUSE_EXIT:
			mouse_inside = false
		NOTIFICATION_WM_MOUSE_ENTER:
			mouse_inside = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_mouse_picking"):
		picking_enabled = not picking_enabled
		%CrossHair.toggle(picking_enabled)
		if not picking_enabled:
			deselect_all()
	if not has_focus:
		return
	
	if event.is_action_pressed("copy_texture"):
		if moused_over_resource:
			if moused_over_resource is Face:
				copied_face_texture_data = moused_over_resource.texture_data.duplicate()
				copied_face_data = moused_over_resource.data.duplicate()
			elif moused_over_resource is Sector:
				copied_sector_data = moused_over_resource.data.duplicate()
				copied_platform_data = moused_over_resource.platform.duplicate()
	
	if event.is_action_pressed("paste_texture", true):
		if moused_over_resource:
			var paste_options: Dictionary = Settings.settings.get("3d_paste_options")
			if moused_over_resource is Face and copied_face_texture_data:
				if paste_options.get("lower_texture"):
					moused_over_resource.texture_data.lowerTextureIndex = copied_face_texture_data.lowerTextureIndex
				if paste_options.get("mid_texture"):
					moused_over_resource.texture_data.midTextureIndex = copied_face_texture_data.midTextureIndex
				if paste_options.get("upper_texture"):
					moused_over_resource.texture_data.upperTextureIndex = copied_face_texture_data.upperTextureIndex
				if "additionalMetadata" in copied_face_texture_data and (copied_face_texture_data.type & 0x80) > 0:
					if "additionalMetadata" not in moused_over_resource.texture_data:
						moused_over_resource.texture_data.additionalMetadata = { "shiftTextureX": 0, "shiftTextureY": 0, "unk0x0C": 0 }
					if moused_over_resource.texture_data.type & 0x80 == 0:
						moused_over_resource.texture_data.type += 0x80
					if paste_options.get("texture_x_shift"):
						moused_over_resource.texture_data.additionalMetadata.shiftTextureX = copied_face_texture_data.additionalMetadata.shiftTextureX
					if paste_options.get("texture_y_shift"):
						moused_over_resource.texture_data.additionalMetadata.shiftTextureY = copied_face_texture_data.additionalMetadata.shiftTextureY
					if paste_options.get("face_id"):
						moused_over_resource.texture_data.additionalMetadata.unk0x0C = copied_face_texture_data.additionalMetadata.unk0x0C
				if paste_options.get("face_texture_flags"):
					moused_over_resource.texture_data.unk0x08 = copied_face_texture_data.unk0x08
				if paste_options.get("face_flags"):
					moused_over_resource.data.addCollision = copied_face_data.addCollision
				var value: int = int(ceil(moused_over_resource.face_length))
				moused_over_resource.texture_data.unk0x00 = int(value) & 255
				moused_over_resource.texture_data.type = (int(value) >> 8) | (moused_over_resource.texture_data.type & (1<<7))
				#moused_over_resource.initialize_mesh()
				owner.redraw([moused_over_resource])
				Roth.editor_action.emit(moused_over_resource.map_info, "Paste Face Properties")
				%EditFaceContainer.update_selections()
			elif moused_over_resource is Sector and copied_sector_data:
				if paste_options.get("ceiling_texture"):
					moused_over_resource.data.ceilingTextureIndex = copied_sector_data.ceilingTextureIndex
				if paste_options.get("ceiling_x_shift"):
					moused_over_resource.data.ceilingTextureShiftX = copied_sector_data.ceilingTextureShiftX
				if paste_options.get("ceiling_y_shift"):
					moused_over_resource.data.ceilingTextureShiftY = copied_sector_data.ceilingTextureShiftY
				if paste_options.get("ceiling_height"):
					moused_over_resource.data.ceilingHeight = copied_sector_data.ceilingHeight
				if paste_options.get("floor_texture"):
					moused_over_resource.data.floorTextureIndex = copied_sector_data.floorTextureIndex
				if paste_options.get("floor_x_shift"):
					moused_over_resource.data.floorTextureShiftX = copied_sector_data.floorTextureShiftX
				if paste_options.get("floor_y_shift"):
					moused_over_resource.data.floorTextureShiftY = copied_sector_data.floorTextureShiftY
				if paste_options.get("floor_height"):
					moused_over_resource.data.floorHeight = copied_sector_data.floorHeight
				if paste_options.get("sector_flip"):
					moused_over_resource.data.unk0x16 = copied_sector_data.unk0x16
				if paste_options.get("sector_flags"):
					moused_over_resource.data.textureFit = copied_sector_data.textureFit
				if paste_options.get("glow"):
					moused_over_resource.data.lighting = copied_sector_data.lighting
				if paste_options.get("texture_height_override"):
					moused_over_resource.data.textureMapOverride = copied_sector_data.textureMapOverride
				if paste_options.get("sector_id"):
					moused_over_resource.data.floorTriggerID = copied_sector_data.floorTriggerID
				if paste_options.get("platform"):
					moused_over_resource.platform = copied_platform_data.duplicate()
				owner.redraw([moused_over_resource])
				%EditSectorContainer.update_selections()
				Roth.editor_action.emit(moused_over_resource.map_info, "Paste Sector Properties")
	if event.is_action_pressed("toggle_selection_highlight"):
		show_selection_highlight = not show_selection_highlight
		if moused_over_resource:
			moused_over_resource.node.unhighlight()
			moused_over_resource = null
		update_selections()


func _process(_delta: float) -> void:
	if (
			not mouse_inside
			or not has_focus
			or not picking_enabled
	):
		return
	
	var viewport := get_viewport()
	var mouse_position := viewport.get_mouse_position()
	
	var viewport_size: Vector2i = viewport.size
	if viewport.get("content_scale_size"):
		
		viewport_size = viewport.content_scale_size
	
	if (	(mouse_position.x < 0 or
			mouse_position.y < 0 or
			mouse_position.x > viewport_size.x or
			mouse_position.y > viewport_size.y) and 
			Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
	):
		if moused_over_resource and moused_over_resource not in owner.selected_faces and moused_over_resource not in owner.selected_sectors:
			moused_over_resource.node.unhighlight()
			moused_over_resource = null
		return
	
	var camera := viewport.get_camera_3d()
	var origin_position: Vector2 = mouse_position
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		origin_position = viewport_size / 2
	var origin := camera.project_ray_origin(origin_position)
	var direction := camera.project_ray_normal(origin_position)
	var ray_length := camera.far
	var end := origin + direction * ray_length
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	var result := space_state.intersect_ray(query)
	var moused_node_changed: bool = false
	
	
	if not result.is_empty():
		if moused_over_resource and not moused_over_resource.node:
			moused_over_resource = null
		
		if moused_over_resource != result.collider.get_parent().ref:
			if moused_over_resource and moused_over_resource not in owner.selected_faces and (moused_over_resource not in owner.selected_sectors or len(owner.selected_faces) == 1) and moused_over_resource not in owner.selected_objects and moused_over_resource not in owner.selected_sfx:
				moused_over_resource.node.unhighlight()
			moused_node_changed = true
			moused_over_resource = result.collider.get_parent().ref
			if moused_over_resource not in owner.selected_faces and (moused_over_resource not in owner.selected_sectors or len(owner.selected_faces) == 1) and moused_over_resource not in owner.selected_objects and moused_over_resource not in owner.selected_sfx:
				var amount := 2
				if Input.is_physical_key_pressed(KEY_SHIFT):
					amount = 1
					if moused_over_resource and moused_over_resource.node not in selected_nodes:
						moused_over_resource.node.unhighlight()
						
				if moused_over_resource is not Face and len(owner.selected_faces) >= amount:
					pass
				elif moused_over_resource is not Sector and len(owner.selected_sectors) >= amount and len(owner.selected_faces) != 1:
					pass
				elif moused_over_resource is not ObjectRoth and len(owner.selected_objects) >= amount:
					pass
				elif moused_over_resource is not Section7_1 and len(owner.selected_sfx) >= amount:
					pass
				else:
					if show_selection_highlight:
						moused_over_resource.node.highlight()
		
		if Input.is_action_just_pressed("select_face", true):
			if moused_over_resource in owner.selected_faces or (moused_over_resource in owner.selected_sectors and len(owner.selected_faces) != 1) or moused_over_resource in owner.selected_objects or moused_over_resource in owner.selected_sfx:
				deselect_all()
			else:
				if moused_over_resource is not Face and len(owner.selected_faces) >= 2:
					deselect_all()
				elif moused_over_resource is not Sector and len(owner.selected_sectors) >= 2:
					deselect_all()
				elif moused_over_resource is not ObjectRoth and len(owner.selected_objects) >= 2:
					deselect_all()
				elif moused_over_resource is not Section7_1 and len(owner.selected_sfx) >= 2:
					deselect_all()
				else:
					show_selection_highlight = true
					owner.select_resource(moused_over_resource)
		if not moused_node_changed and Input.is_action_just_pressed("select_additional_face", true):
			if moused_over_resource in owner.selected_faces or (moused_over_resource in owner.selected_sectors and len(owner.selected_faces) != 1) or moused_over_resource in owner.selected_objects or moused_over_resource in owner.selected_sfx:
				owner.deselect_resource(moused_over_resource)
			else:
				if moused_over_resource is Face:
					if ((len(owner.selected_sectors) == 1 and len(owner.selected_faces) == 1 and owner.selected_faces[0] in owner.selected_sectors[0].faces.map(func (face_ref: WeakRef) -> Face: return face_ref.get_ref())) or len(owner.selected_sectors) == 0) and len(owner.selected_objects) == 0 and len(owner.selected_sfx) == 0:
						owner.select_resource(moused_over_resource, false)
				elif moused_over_resource is Sector:
					if len(owner.selected_faces) == 0 and len(owner.selected_objects) == 0 and len(owner.selected_sfx) == 0:
						owner.select_resource(moused_over_resource, false)
				elif moused_over_resource is ObjectRoth:
					if len(owner.selected_sectors) == 0 and len(owner.selected_faces) == 0 and len(owner.selected_sfx) == 0:
						owner.select_resource(moused_over_resource, false)
				elif moused_over_resource is Section7_1:
					if len(owner.selected_sectors) == 0 and len(owner.selected_faces) == 0 and len(owner.selected_objects) == 0:
						owner.select_resource(moused_over_resource, false)
				
		if moused_node_changed and Input.is_action_pressed("select_additional_face", true):
			if moused_over_resource in owner.selected_faces or (moused_over_resource in owner.selected_sectors and len(owner.selected_faces) != 1) or moused_over_resource in owner.selected_objects or moused_over_resource in owner.selected_sfx:
				pass
				#owner.deselect_resource(moused_over_resource)
			else:
				if moused_over_resource is Face:
					if len(owner.selected_faces) >= 1:
						owner.select_resource(moused_over_resource, false)
				elif moused_over_resource is Sector:
					if len(owner.selected_faces) == 0 and len(owner.selected_objects) < 1 and len(owner.selected_sfx) < 1:
						owner.select_resource(moused_over_resource, false)
				elif moused_over_resource is ObjectRoth:
					if len(owner.selected_objects) >= 1:
						owner.select_resource(moused_over_resource, false)
				elif moused_over_resource is Section7_1:
					if len(owner.selected_sfx) >= 1:
						owner.select_resource(moused_over_resource, false)
		if Input.is_action_pressed("deselect_additional_face"):
			if moused_over_resource in owner.selected_faces or (moused_over_resource in owner.selected_sectors and len(owner.selected_faces) != 1) or moused_over_resource in owner.selected_objects or moused_over_resource in owner.selected_sfx:
				owner.deselect_resource(moused_over_resource)
			
	else:
		if moused_over_resource and moused_over_resource not in owner.selected_faces and moused_over_resource not in owner.selected_sectors and moused_over_resource not in owner.selected_objects and moused_over_resource not in owner.selected_sfx:
			moused_over_resource.node.unhighlight()
			moused_over_resource = null
	
	if shift_switched != Input.is_physical_key_pressed(KEY_SHIFT):
		shift_switched = Input.is_physical_key_pressed(KEY_SHIFT)
		moused_over_resource = null

func update_selections() -> void:
	for node: Variant in selected_nodes:
		if node:
			node.deselect()
	selected_nodes.clear()
	if not show_selection_highlight:
		return
	if moused_over_resource:
		moused_over_resource.node.highlight()
	if len(owner.selected_faces) == 0:
		for sector: Sector in owner.selected_sectors:
			sector.node.select()
			selected_nodes.append(sector.node)
	for face: Face in owner.selected_faces:
		face.node.select()
		selected_nodes.append(face.node)
	for object: ObjectRoth in owner.selected_objects:
		object.node.select()
		selected_nodes.append(object.node)
	for sfx: Section7_1 in owner.selected_sfx:
		sfx.node.select()
		selected_nodes.append(sfx.node)


func deselect_all() -> void:
	moused_over_resource = null
	show_selection_highlight = true
	owner.select_resource(null)
