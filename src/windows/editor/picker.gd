extends Node3D

var highlight_material: StandardMaterial3D
var selected_material: StandardMaterial3D
var mouse_inside: bool = true
var moused_over_node: CollisionObject3D
var selected_node: CollisionObject3D
var has_focus: bool = false :
	set(value):
		has_focus = value
		if has_focus == false:
			if moused_over_node and selected_node != moused_over_node:
				moused_over_node.get_parent().material_overlay = null
var picking_enabled: bool = true
var copied_face_texture_data: Dictionary = {}
var copied_sector_texture_data: Dictionary = {}

func _ready() -> void:
	highlight_material = StandardMaterial3D.new()
	highlight_material.albedo_color = Color("#0000AA22")
	highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	highlight_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	highlight_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	selected_material = StandardMaterial3D.new()
	selected_material.albedo_color = Color("#DD888822")
	selected_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	selected_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	selected_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	selected_material.no_depth_test = true


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
			if moused_over_node:
				moused_over_node.get_parent().material_overlay = null
				moused_over_node = null
			deselect()


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
		if moused_over_node and moused_over_node != selected_node:
			moused_over_node.get_parent().material_overlay = null
			moused_over_node = null
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
	
	
	#if not result.is_empty() and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
	if not result.is_empty():
		if moused_over_node and moused_over_node != result.collider:
			if moused_over_node != selected_node:
				moused_over_node.get_parent().material_overlay = null

		if moused_over_node != result.collider:
			moused_over_node = result.collider
			if moused_over_node != selected_node:
				moused_over_node.get_parent().material_overlay = highlight_material
			if moused_over_node.get_parent() is ObjectRoth.ObjectMesh3D and not ((moused_over_node.get_parent().ref.data.renderType & (1<<7)) > 0):
				highlight_material.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
			else:
				highlight_material.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
		
		if Input.is_action_just_pressed("copy_texture"):
			if moused_over_node:
				if moused_over_node.get_parent().ref is Face:
					copied_face_texture_data = moused_over_node.get_parent().ref.texture_data.duplicate()
				elif moused_over_node.get_parent().ref is Sector:
					copied_sector_texture_data = moused_over_node.get_parent().ref.data.duplicate()
		
		if Input.is_action_just_pressed("paste_texture"):
			if moused_over_node:
				if moused_over_node.get_parent().ref is Face and copied_face_texture_data:
					moused_over_node.get_parent().ref.texture_data.midTextureIndex = copied_face_texture_data.midTextureIndex
					moused_over_node.get_parent().ref.texture_data.upperTextureIndex = copied_face_texture_data.upperTextureIndex
					moused_over_node.get_parent().ref.texture_data.lowerTextureIndex = copied_face_texture_data.lowerTextureIndex
					moused_over_node.get_parent().ref.initialize_mesh()
				elif moused_over_node.get_parent().ref is Sector and copied_sector_texture_data:
					moused_over_node.get_parent().ref.data.ceilingTextureIndex = copied_sector_texture_data.ceilingTextureIndex
					moused_over_node.get_parent().ref.data.floorTextureIndex = copied_sector_texture_data.floorTextureIndex
					moused_over_node.get_parent().ref.initialize_mesh()
				
		
		if Input.is_action_just_pressed("select_face"):
			if selected_node and selected_node != moused_over_node:
				selected_node.get_parent().material_overlay = null
			if selected_node and selected_node == moused_over_node:
				deselect()
				return
			
			selected_node = moused_over_node
			moused_over_node.get_parent().material_overlay = selected_material
			
			if moused_over_node.get_parent() is ObjectRoth.ObjectMesh3D and not ((moused_over_node.get_parent().ref.data.renderType & (1<<7)) > 0):
				selected_material.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
			else:
				selected_material.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
			
			var face: Node3D = moused_over_node.get_parent()
			select(face, false)
	else:
		if moused_over_node and moused_over_node != selected_node:
			moused_over_node.get_parent().material_overlay = null
			moused_over_node = null


func deselect() -> void:
	if selected_node:
		selected_node.get_parent().material_overlay = null
		selected_node = null
	for child in %EditContainer.get_children():
		child.queue_free()
	selected_material.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
	highlight_material.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
	%Arrow3D.clear_target()
	%Map2D.select(null)
	_reset_edits()


func select(node: Node3D, highlight: bool = true) -> void:
	_reset_edits()
	
	if highlight:
		if not node is MeshInstance3D:
			node = node.get_child(0)
		if node.get_child_count() > 0:
			if selected_node and selected_node != node.get_child(0):
				selected_node.get_parent().material_overlay = null
			selected_node = node.get_child(0)
		else:
			if selected_node:
				selected_node.get_parent().material_overlay = null
			selected_node = null
		node.material_overlay = selected_material
		if node is ObjectRoth.ObjectMesh3D and not ((node.ref.data.renderType & (1<<7)) > 0):
			selected_material.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
		else:
			selected_material.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
	
	
	for child in %EditContainer.get_children():
		child.queue_free()
	
	%Arrow3D.set_target(node)
	%Map2D.select(node.ref)
	
	if node is ObjectRoth.ObjectMesh3D:
		var object:  ObjectRoth.ObjectMesh3D = node
		%EditObjectContainer.load_edit_object(object)
		add_label("Object Data", HORIZONTAL_ALIGNMENT_CENTER)
		add_label("index: %s" % object.ref.index)
		for key: String in object.ref.data:
			add_label("%s: %s" % [key, object.ref.data[key]])
	elif node is Section7_1.SFXMesh3D:
		var sfx:  Section7_1.SFXMesh3D = node
		%EditSFXContainer.load_edit_sfx(sfx)
		add_label("SFX Data", HORIZONTAL_ALIGNMENT_CENTER)
		add_label("index: %s" % sfx.ref.index)
		for key: String in sfx.ref.data:
			add_label("%s: %s" % [key, sfx.ref.data[key]])
	elif node is Face.FaceMesh3D:
		var face: Face.FaceMesh3D = node
		%EditFaceContainer.load_edit_face(face.ref)
		var das: Dictionary = await Roth.get_das(face.ref.map_info.das)
		add_label("Face Data", HORIZONTAL_ALIGNMENT_CENTER)
		add_label("index: %s" % face.ref.index)
		add_label("v1: %s" % face.ref.v1)
		add_label("v2: %s" % face.ref.v2)
		add_label("length: %s" % face.ref.face_length)
		for key: String in face.ref.data:
			add_label("%s: %s" % [key, face.ref.data[key]])
		add_separator()
		add_label("Texture Mapping Data", HORIZONTAL_ALIGNMENT_CENTER)
		for key: String in face.ref.texture_data:
			if key == "additionalMetadata":
				continue
			elif key == "unk0x08":
				add_label("Transparent: %s" % [int(face.ref.texture_data[key]) & (1<<0) > 0])
				add_label("Flip X: %s" % [int(face.ref.texture_data[key]) & (1<<1) > 0])
				add_label("Image Fit: %s" % [int(face.ref.texture_data[key]) & (1<<2) > 0])
				add_label("Override Height: %s" % [int(face.ref.texture_data[key]) & (1<<3) > 0])
				add_label("No Reflect: %s" % [int(face.ref.texture_data[key]) & (1<<4) > 0])
				add_label("Half Pixel: %s" % [int(face.ref.texture_data[key]) & (1<<5) > 0])
				add_label("Edge Map: %s" % [int(face.ref.texture_data[key]) & (1<<6) > 0])
				add_label("Draw From Bottom: %s" % [int(face.ref.texture_data[key]) & (1<<7) > 0])
				
				continue
			add_label("%s: %s" % [key, face.ref.texture_data[key]])
		
		if "additionalMetadata" in face.ref.texture_data:
			for key: String in face.ref.texture_data.additionalMetadata:
				add_label("%s: %s" % [key, face.ref.texture_data.additionalMetadata[key]])
		
		if face.ref.texture_data.midTextureIndex in das.mapping:
			add_separator()
			add_label("Texture Mid", HORIZONTAL_ALIGNMENT_CENTER)
			add_texture(face.ref.texture_data.midTextureIndex, face.ref.map_info.das)
			for key: String in das.mapping[face.ref.texture_data.midTextureIndex]:
				if key == "image" or key == "animation":
					continue
				add_label("%s: %s" % [key, das.mapping[face.ref.texture_data.midTextureIndex][key]])
	
		
		if face.ref.texture_data.lowerTextureIndex in das.mapping:
			add_separator()
			add_label("Texture Lower", HORIZONTAL_ALIGNMENT_CENTER)
			add_texture(face.ref.texture_data.lowerTextureIndex, face.ref.map_info.das)
			for key: String in das.mapping[face.ref.texture_data.lowerTextureIndex]:
				if key == "image" or key == "animation":
					continue
				add_label("%s: %s" % [key, das.mapping[face.ref.texture_data.lowerTextureIndex][key]])
			
			
			
		if face.ref.texture_data.upperTextureIndex in das.mapping:
			add_separator()
			add_label("Texture Upper", HORIZONTAL_ALIGNMENT_CENTER)
			add_texture(face.ref.texture_data.upperTextureIndex, face.ref.map_info.das)
			for key: String in das.mapping[face.ref.texture_data.upperTextureIndex]:
				if key == "image" or key == "animation":
					continue
				add_label("%s: %s" % [key, das.mapping[face.ref.texture_data.upperTextureIndex][key]])
		
	elif node is Sector.SectorMesh3D:
		var sector: Sector.SectorMesh3D = node
		%EditSectorContainer.load_edit_sector(sector.ref)
		var das: Dictionary = await Roth.get_das(sector.ref.map_info.das)
		add_label("Sector Data", HORIZONTAL_ALIGNMENT_CENTER)
		add_label("index: %s" % sector.ref.index)
		for key: String in sector.ref.data:
			if key == "objectInformation":
				continue
			elif key == "unk0x16":
				add_label("FloorFlipX: %s" % [int(sector.ref.data[key]) & (1<<8) > 0])
				add_label("FloorFlipY: %s" % [int(sector.ref.data[key]) & (1<<9) > 0])
				add_label("CeilingFlipX: %s" % [int(sector.ref.data[key]) & (1<<10) > 0])
				add_label("CeilingFlipY: %s" % [int(sector.ref.data[key]) & (1<<11) > 0])
				continue
			add_label("%s: %s" % [key, sector.ref.data[key]])
		
		for i in range(len(sector.ref.vertices)):
			add_label("v%s: %s" % [i, sector.ref.vertices[i]])
		
		if sector.ref.data.ceilingTextureIndex in das.mapping:
			add_separator()
			add_label("Ceiling Texture", HORIZONTAL_ALIGNMENT_CENTER)
			add_texture(sector.ref.data.ceilingTextureIndex, sector.ref.map_info.das)
			for key: String in das.mapping[sector.ref.data.ceilingTextureIndex]:
				if key == "image" or key == "animation":
					continue
				add_label("%s: %s" % [key, das.mapping[sector.ref.data.ceilingTextureIndex][key]])
		if sector.ref.data.floorTextureIndex in das.mapping:
			add_separator()
			add_label("Floor Texture", HORIZONTAL_ALIGNMENT_CENTER)
			add_texture(sector.ref.data.floorTextureIndex, sector.ref.map_info.das)
			for key: String in das.mapping[sector.ref.data.floorTextureIndex]:
				if key == "image" or key == "animation":
					continue
				add_label("%s: %s" % [key, das.mapping[sector.ref.data.floorTextureIndex][key]])
		if sector.ref.platform:
			add_separator()
			add_label("Platform Data", HORIZONTAL_ALIGNMENT_CENTER)
			for key: String in sector.ref.platform:
				add_label("%s: %s" % [key, sector.ref.platform[key]])
			
			if int(sector.ref.platform.ceilingTextureIndex) in das.mapping:
				add_label("Platform Ceiling")
				add_texture(int(sector.ref.platform.ceilingTextureIndex), sector.ref.map_info.das)
			if int(sector.ref.platform.floorTextureIndex) in das.mapping:
				add_label("Platform Floor")
				add_texture(int(sector.ref.platform.floorTextureIndex), sector.ref.map_info.das)


func add_separator() -> void:
	%EditContainer.add_child(HSeparator.new())


func add_label(text: String, h_alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	label.horizontal_alignment = h_alignment
	label.add_theme_font_size_override("font_size", 32)
	%EditContainer.add_child(label)


func add_texture(texture_index: int, das_name: String) -> void:
	var das: Dictionary = await Roth.get_das(das_name)
	if texture_index in das.mapping:
		var texture_rect := TextureRect.new()
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		texture_rect.custom_minimum_size.y = 100
		if "image" in das.mapping[texture_index]:
			texture_rect.texture = das.mapping[texture_index].image[0] if typeof(das.mapping[texture_index].image) == TYPE_ARRAY else das.mapping[texture_index].image
		texture_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		%EditContainer.add_child(texture_rect)


func _reset_edits() -> void:
	%EditFaceContainer.hide()
	%EditSectorContainer.hide()
	%EditObjectContainer.hide()
	%EditSFXContainer.hide()
	%EditFaceContainer.current_face = null
	%EditSectorContainer.current_sector = null
	%EditObjectContainer.current_object = null
	%EditSFXContainer.current_object = null


func redraw_selected_node(node: Variant = null) -> void:
	var caret: int = 0
	if node:
		caret = node.get_line_edit().caret_column
	
	var child_index: int = -1
	for i in range(selected_node.get_parent().ref.node.get_child_count()):
		if selected_node.get_parent().ref.node.get_child(i) == selected_node.get_parent():
			child_index = i
	selected_node.get_parent().ref.initialize_mesh()
	
	if selected_node.get_parent().ref is Sector:
		for face_ref: WeakRef in selected_node.get_parent().ref.faces:
			var face: Face = face_ref.get_ref()
			if face.sister:
				face.sister.get_ref().initialize_mesh()
			face.initialize_mesh()
	
	var ref_node: Node3D = selected_node.get_parent().ref.node
	await selected_node.tree_exited
	await get_tree().process_frame
	if child_index > ref_node.get_child_count() - 1:
		child_index = ref_node.get_child_count() - 1
	if child_index < 0:
		return
	select(ref_node.get_child(child_index))
	
	if node:
		node.get_line_edit().grab_focus()
		await get_tree().process_frame
		node.get_line_edit().caret_column = caret
