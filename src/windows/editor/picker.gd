extends Node3D

var highlight_material: StandardMaterial3D
var selected_material: StandardMaterial3D
var mouse_inside: bool = true
var moused_over_node: CollisionObject3D
var selected_node: CollisionObject3D
var has_focus: bool = false
var picking_enabled: bool = true

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
		
		if Input.is_action_just_pressed("select_face"):
			if selected_node and selected_node != moused_over_node:
				selected_node.get_parent().material_overlay = null
			if selected_node and selected_node == moused_over_node:
				deselect()
				return
			
			selected_node = moused_over_node
			moused_over_node.get_parent().material_overlay = selected_material
			
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
	%Arrow3D.clear_target()
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
	
	
	for child in %EditContainer.get_children():
		child.queue_free()
	
	%Arrow3D.set_target(node)
	
	
	if node is ObjectRoth.ObjectMesh3D:
		var object:  ObjectRoth.ObjectMesh3D = node
		add_label("Object Data", HORIZONTAL_ALIGNMENT_CENTER)
		add_label("index: %s" % object.ref.index)
		for key: String in object.ref.data:
			add_label("%s: %s" % [key, object.ref.data[key]])
	elif node is Section7_1.SFXMesh3D:
		var sfx:  Section7_1.SFXMesh3D = node
		add_label("SFX Data", HORIZONTAL_ALIGNMENT_CENTER)
		add_label("index: %s" % sfx.ref.index)
		for key: String in sfx.ref.data:
			add_label("%s: %s" % [key, sfx.ref.data[key]])
	elif node is Face.FaceMesh3D:
		var face: Face.FaceMesh3D = node
		load_edit_face(face)
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
		load_edit_sector(sector)
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
		texture_rect.texture = ImageTexture.create_from_image(
			das.mapping[texture_index].image[0] if typeof(das.mapping[texture_index].image) == TYPE_ARRAY else das.mapping[texture_index].image
		)
		texture_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		%EditContainer.add_child(texture_rect)


func _reset_edits() -> void:
	%EditFaceContainer.hide()
	%EditSectorContainer.hide()


func _reset_edit_sector() -> void:
	%SectorIndexLabel.text = ""
	%SelectFacesPopupMenu.clear()
	%RoofHeightEdit.get_line_edit().clear()
	%RoofScaleOption.select(1)
	%FloorHeightEdit.get_line_edit().clear()
	%FloorScaleOption.select(1)
	%GlowEdit.get_line_edit().clear()
	%FloorTriggerIDEdit.get_line_edit().clear()
	%CandleCheckBox.set_pressed_no_signal(false)
	%Unk0x04Edit.get_line_edit().clear()
	%LightningCheckBox.set_pressed_no_signal(false)
	%TextureHeightOverrideEdit.get_line_edit().clear()
	%RoofTextureOption.clear()
	%RoofOffsetXEdit.get_line_edit().clear()
	%RoofOffsetYEdit.get_line_edit().clear()
	%FloorTextureOption.clear()
	%FloorOffsetXEdit.get_line_edit().clear()
	%FloorOffsetYEdit.get_line_edit().clear()
	%RoofFlipXCheckBox.set_pressed_no_signal(false)
	%RoofFlipYCheckBox.set_pressed_no_signal(false)
	%FloorFlipXCheckBox.set_pressed_no_signal(false)
	%FloorFlipYCheckBox.set_pressed_no_signal(false)
	%EditSectorContainer.show()
	
	%PlatformCheckButton.set_pressed_no_signal(false)
	%PlatformFloorHeightEdit.get_line_edit().clear()
	%PlatformFloorScaleOption.select(1)
	%PlatformRoofHeightEdit.get_line_edit().clear()
	%PlatformRoofScaleOption.select(1)
	%PlatformRoofTextureOption.clear()
	%PlatformRoofOffsetXEdit.get_line_edit().clear()
	%PlatformRoofOffsetYEdit.get_line_edit().clear()
	%PlatformFloorTextureOption.clear()
	%PlatformFloorOffsetXEdit.get_line_edit().clear()
	%PlatformFloorOffsetYEdit.get_line_edit().clear()



func load_edit_sector(sector: Sector.SectorMesh3D) -> void:
	_reset_edit_sector()
	%SectorIndexLabel.text = "Sector: %d" % sector.ref.index
	var i: int = 0
	for face_ref: WeakRef in sector.ref.faces:
		var face: Face = face_ref.get_ref()
		%SelectFacesPopupMenu.add_item("%d" % face.index)
		%SelectFacesPopupMenu.set_item_metadata(i, face.node)
		i += 1
	%RoofHeightEdit.get_line_edit().text = "%d" % sector.ref.data.ceilingHeight
	%RoofHeightEdit.set_value_no_signal(sector.ref.data.ceilingHeight)
	var roof_a: int = sector.ref.data.textureFit & Sector.CEILING_A > 0
	var roof_b: int = sector.ref.data.textureFit & Sector.CEILING_B > 0
	if roof_a == 0 and roof_b == 0:
		%RoofScaleOption.select(0)
	elif roof_a == 1 and roof_b == 0:
		%RoofScaleOption.select(1)
	elif roof_a == 0 and roof_b == 1:
		%RoofScaleOption.select(2)
	elif roof_a == 1 and roof_b == 1:
		%RoofScaleOption.select(3)
	
	%FloorHeightEdit.get_line_edit().text = "%d" % sector.ref.data.floorHeight
	%FloorHeightEdit.set_value_no_signal(sector.ref.data.floorHeight)
	var floor_a: int = sector.ref.data.textureFit & Sector.FLOOR_A > 0
	var floor_b: int = sector.ref.data.textureFit & Sector.FLOOR_B > 0
	if floor_a == 0 and floor_b == 0:
		%FloorScaleOption.select(0)
	elif floor_a == 1 and floor_b == 0:
		%FloorScaleOption.select(1)
	elif floor_a == 0 and floor_b == 1:
		%FloorScaleOption.select(2)
	elif floor_a == 1 and floor_b == 1:
		%FloorScaleOption.select(3)
	
	%GlowEdit.get_line_edit().text = "%d" % sector.ref.data.lighting
	%GlowEdit.set_value_no_signal(sector.ref.data.lighting)
	
	%FloorTriggerIDEdit.get_line_edit().text = "%d" % sector.ref.data.floorTriggerID
	%FloorTriggerIDEdit.set_value_no_signal(sector.ref.data.floorTriggerID)
	
	if sector.ref.data.textureFit & Sector.CANDLE > 0:
		%CandleCheckBox.set_pressed_no_signal(true)
	
	%Unk0x04Edit.get_line_edit().text = "%d" % sector.ref.data.unk0x04
	%Unk0x04Edit.set_value_no_signal(sector.ref.data.unk0x04)
	
	if sector.ref.data.textureFit & Sector.LIGHTNING > 0:
		%LightningCheckBox.set_pressed_no_signal(true)
	
	%TextureHeightOverrideEdit.get_line_edit().text = "%d" % sector.ref.data.textureMapOverride
	%TextureHeightOverrideEdit.set_value_no_signal(sector.ref.data.textureMapOverride)
	
	%RoofOffsetXEdit.get_line_edit().text = "%d" % sector.ref.data.ceilingTextureShiftX
	%RoofOffsetXEdit.set_value_no_signal(sector.ref.data.ceilingTextureShiftX)
	%RoofOffsetYEdit.get_line_edit().text = "%d" % sector.ref.data.ceilingTextureShiftY
	%RoofOffsetYEdit.set_value_no_signal(sector.ref.data.ceilingTextureShiftY)
	%FloorOffsetXEdit.get_line_edit().text = "%d" % sector.ref.data.floorTextureShiftX
	%FloorOffsetXEdit.set_value_no_signal(sector.ref.data.floorTextureShiftX)
	%FloorOffsetYEdit.get_line_edit().text = "%d" % sector.ref.data.floorTextureShiftY
	%FloorOffsetYEdit.set_value_no_signal(sector.ref.data.floorTextureShiftY)
	
	if sector.ref.data.unk0x16 & Sector.CEILING_FLIP_X > 0:
		%RoofFlipXCheckBox.set_pressed_no_signal(true)
	if sector.ref.data.unk0x16 & Sector.CEILING_FLIP_Y > 0:
		%RoofFlipYCheckBox.set_pressed_no_signal(true)
	if sector.ref.data.unk0x16 & Sector.FLOOR_FLIP_X > 0:
		%FloorFlipXCheckBox.set_pressed_no_signal(true)
	if sector.ref.data.unk0x16 & Sector.FLOOR_FLIP_Y > 0:
		%FloorFlipYCheckBox.set_pressed_no_signal(true)
	
	
	var das := await Roth.get_das(sector.ref.map_info.das)
	if sector.ref.data.ceilingTextureIndex in das.mapping:
		%RoofTextureOption.add_item( "%s:%s" % [das.mapping[sector.ref.data.ceilingTextureIndex].index, das.mapping[sector.ref.data.ceilingTextureIndex].name] )
	else:
		%RoofTextureOption.add_item( "%d" % sector.ref.data.ceilingTextureIndex )
	if sector.ref.data.floorTextureIndex in das.mapping:
		%FloorTextureOption.add_item( "%s:%s" % [das.mapping[sector.ref.data.floorTextureIndex].index, das.mapping[sector.ref.data.floorTextureIndex].name] )
	else:
		%FloorTextureOption.add_item( "%d" % sector.ref.data.floorTextureIndex )
	
	%RoofTextureOption.add_item("--------")
	%RoofTextureOption.add_item("Sky")
	%RoofTextureOption.add_item("Select Texture")
	%RoofTextureOption.add_item("Select Palette")
	%FloorTextureOption.add_item("--------")
	%FloorTextureOption.add_item("Sky")
	%FloorTextureOption.add_item("Select Texture")
	%FloorTextureOption.add_item("Select Palette")
	
	
	if sector.ref.platform:
		%PlatformCheckButton.set_pressed_no_signal(true)
		%PlatformContainer.show()
	
		%PlatformFloorHeightEdit.get_line_edit().text = "%d" % sector.ref.platform.floorHeight
		%PlatformFloorHeightEdit.set_value_no_signal(sector.ref.platform.floorHeight)
		
		%PlatformRoofHeightEdit.get_line_edit().text = "%d" % sector.ref.platform.ceilingHeight
		%PlatformRoofHeightEdit.set_value_no_signal(sector.ref.platform.ceilingHeight)
		
		var platform_floor_a: int = sector.ref.platform.floorTextureScale & Sector.FLOOR_A > 0
		var platform_floor_b: int = sector.ref.platform.floorTextureScale & Sector.FLOOR_B > 0
		if platform_floor_a == 0 and platform_floor_b == 0:
			%PlatformFloorScaleOption.select(0)
		elif platform_floor_a == 1 and platform_floor_b == 0:
			%PlatformFloorScaleOption.select(1)
		elif platform_floor_a == 0 and platform_floor_b == 1:
			%PlatformFloorScaleOption.select(2)
		elif platform_floor_a == 1 and platform_floor_b == 1:
			%PlatformFloorScaleOption.select(3)
		
		var platform_ceiling_a: int = sector.ref.platform.floorTextureScale & Sector.CEILING_A > 0
		var platform_ceiling_b: int = sector.ref.platform.floorTextureScale & Sector.CEILING_B > 0
		if platform_ceiling_a == 0 and platform_ceiling_b == 0:
			%PlatformRoofScaleOption.select(0)
		elif platform_ceiling_a == 1 and platform_ceiling_b == 0:
			%PlatformRoofScaleOption.select(1)
		elif platform_ceiling_a == 0 and platform_ceiling_b == 1:
			%PlatformRoofScaleOption.select(2)
		elif platform_ceiling_a == 1 and platform_ceiling_b == 1:
			%PlatformRoofScaleOption.select(3)
		
		
		%PlatformRoofOffsetXEdit.get_line_edit().text = "%d" % sector.ref.platform.ceilingTextureShiftX
		%PlatformRoofOffsetXEdit.set_value_no_signal(sector.ref.platform.ceilingTextureShiftX)
		%PlatformRoofOffsetYEdit.get_line_edit().text = "%d" % sector.ref.platform.ceilingTextureShiftY
		%PlatformRoofOffsetYEdit.set_value_no_signal(sector.ref.platform.ceilingTextureShiftY)
		
		%PlatformFloorOffsetXEdit.get_line_edit().text = "%d" % sector.ref.platform.floorTextureShiftX
		%PlatformFloorOffsetXEdit.set_value_no_signal(sector.ref.platform.floorTextureShiftX)
		%PlatformFloorOffsetYEdit.get_line_edit().text = "%d" % sector.ref.platform.floorTextureShiftY
		%PlatformFloorOffsetYEdit.set_value_no_signal(sector.ref.platform.floorTextureShiftY)
		
		if sector.ref.platform.ceilingTextureIndex in das.mapping:
			%PlatformRoofTextureOption.add_item( "%s:%s" % [das.mapping[sector.ref.platform.ceilingTextureIndex].index, das.mapping[sector.ref.platform.ceilingTextureIndex].name] )
		else:
			%PlatformRoofTextureOption.add_item( "%d" % sector.ref.platform.ceilingTextureIndex )
		if sector.ref.platform.floorTextureIndex in das.mapping:
			%PlatformFloorTextureOption.add_item( "%s:%s" % [das.mapping[sector.ref.platform.floorTextureIndex].index, das.mapping[sector.ref.platform.floorTextureIndex].name] )
		else:
			%PlatformFloorTextureOption.add_item( "%d" % sector.ref.platform.floorTextureIndex )
		
		%PlatformRoofTextureOption.add_item("--------")
		%PlatformRoofTextureOption.add_item("Sky")
		%PlatformRoofTextureOption.add_item("Select Texture")
		%PlatformRoofTextureOption.add_item("Select Palette")
		%PlatformFloorTextureOption.add_item("--------")
		%PlatformFloorTextureOption.add_item("Sky")
		%PlatformFloorTextureOption.add_item("Select Texture")
		%PlatformFloorTextureOption.add_item("Select Palette")
		
		
	else:
		%PlatformCheckButton.set_pressed_no_signal(false)
		%PlatformContainer.hide()



func _reset_edit_face() -> void:
	%FaceIndexLabel.text = ""
	%TopTextureOption.clear()
	%MidTextureOption.clear()
	%BottomTextureOption.clear()
	%XShiftEdit.get_line_edit().clear()
	%YShiftEdit.get_line_edit().clear()
	%TransparencyCheckBox.set_pressed_no_signal(false)
	%FlipXCheckBox.set_pressed_no_signal(false)
	%ImageFitCheckBox.set_pressed_no_signal(false)
	%FixedSizeTransparencyCheckBox.set_pressed_no_signal(false)
	%NoReflectCheckBox.set_pressed_no_signal(false)
	%HalfPixelCheckBox.set_pressed_no_signal(false)
	%EdgeMapCheckBox.set_pressed_no_signal(false)
	%DrawFromBottomCheckBox.set_pressed_no_signal(false)
	%Unk0x00Edit.get_line_edit().clear()
	%TypeEdit.get_line_edit().clear()
	%"Unk0x00+TypeEdit".get_line_edit().clear()
	%StopWalkCheckBox.set_pressed_no_signal(false)
	%StopAlenCheckBox.set_pressed_no_signal(false)
	%Flag3CheckBox.set_pressed_no_signal(false)
	%RoomBlkCheckBox.set_pressed_no_signal(false)
	%Flag5CheckBox.set_pressed_no_signal(false)
	%Flag6CheckBox.set_pressed_no_signal(false)
	%Flag7CheckBox.set_pressed_no_signal(false)
	%Flag8CheckBox.set_pressed_no_signal(false)
	%SelectSisterButton.hide()
	%EditFaceContainer.show()
	


func load_edit_face(face: Face.FaceMesh3D) -> void:
	_reset_edit_face()
	%FaceIndexLabel.text = "Face: %d" % face.ref.index
	if face.ref.texture_data.unk0x08 & (1 << 0) > 0:
		%TransparencyCheckBox.set_pressed_no_signal(true)
	if face.ref.texture_data.unk0x08 & (1 << 1) > 0:
		%FlipXCheckBox.set_pressed_no_signal(true)
	if face.ref.texture_data.unk0x08 & (1 << 2) > 0:
		%ImageFitCheckBox.set_pressed_no_signal(true)
	if face.ref.texture_data.unk0x08 & (1 << 3) > 0:
		%FixedSizeTransparencyCheckBox.set_pressed_no_signal(true)
	if face.ref.texture_data.unk0x08 & (1 << 4) > 0:
		%NoReflectCheckBox.set_pressed_no_signal(true)
	if face.ref.texture_data.unk0x08 & (1 << 5) > 0:
		%HalfPixelCheckBox.set_pressed_no_signal(true)
	if face.ref.texture_data.unk0x08 & (1 << 6) > 0:
		%EdgeMapCheckBox.set_pressed_no_signal(true)
	if face.ref.texture_data.unk0x08 & (1 << 7) > 0:
		%DrawFromBottomCheckBox.set_pressed_no_signal(true)
	
	if face.ref.data.addCollision & (1 << 0) > 0:
		%StopWalkCheckBox.set_pressed_no_signal(true)
	if face.ref.data.addCollision & (1 << 1) > 0:
		%StopAlenCheckBox.set_pressed_no_signal(true)
	if face.ref.data.addCollision & (1 << 2) > 0:
		%Flag3CheckBox.set_pressed_no_signal(true)
	if face.ref.data.addCollision & (1 << 3) > 0:
		%RoomBlkCheckBox.set_pressed_no_signal(true)
	if face.ref.data.addCollision & (1 << 4) > 0:
		%Flag5CheckBox.set_pressed_no_signal(true)
	if face.ref.data.addCollision & (1 << 5) > 0:
		%Flag6CheckBox.set_pressed_no_signal(true)
	if face.ref.data.addCollision & (1 << 6) > 0:
		%Flag7CheckBox.set_pressed_no_signal(true)
	if face.ref.data.addCollision & (1 << 7) > 0:
		%Flag8CheckBox.set_pressed_no_signal(true)
	
	
	%Unk0x00Edit.set_value_no_signal(face.ref.texture_data.unk0x00)
	%Unk0x00Edit.get_line_edit().text = "%d" % face.ref.texture_data.unk0x00
	%TypeEdit.set_value_no_signal(face.ref.texture_data.type)
	%TypeEdit.get_line_edit().text = "%d" % face.ref.texture_data.type
	%"Unk0x00+TypeEdit".set_value_no_signal(face.ref.texture_data.unk0x00 + ((face.ref.texture_data.type & ~(1<<7))<<8))
	%"Unk0x00+TypeEdit".get_line_edit().text = "%d" % (face.ref.texture_data.unk0x00 + ((face.ref.texture_data.type & ~(1<<7))<<8))
	
	if "additionalMetadata" in face.ref.texture_data and face.ref.texture_data.type & 128 > 0:
		%XShiftEdit.set_value_no_signal(face.ref.texture_data.additionalMetadata.shiftTextureX)
		%XShiftEdit.get_line_edit().text = "%d" % face.ref.texture_data.additionalMetadata.shiftTextureX
		%YShiftEdit.set_value_no_signal(face.ref.texture_data.additionalMetadata.shiftTextureY)
		%YShiftEdit.get_line_edit().text = "%d" % face.ref.texture_data.additionalMetadata.shiftTextureY
		%"0x0CEdit".text = str(face.ref.texture_data.additionalMetadata.unk0x0C)
		%AdditionalCheckButton.set_pressed_no_signal(true)
		%XShiftEdit.editable = true
		%YShiftEdit.editable = true
		%"0x0CEdit".editable = true
	else:
		%XShiftEdit.set_value_no_signal(0)
		%XShiftEdit.get_line_edit().text = "0"
		%YShiftEdit.set_value_no_signal(0)
		%YShiftEdit.get_line_edit().text = "0"
		%"0x0CEdit".text = str(0)
		%AdditionalCheckButton.set_pressed_no_signal(false)
		%XShiftEdit.editable = false
		%YShiftEdit.editable = false
		%"0x0CEdit".editable = false
		
	var das := await Roth.get_das(face.ref.map_info.das)
	if face.ref.texture_data.upperTextureIndex in das.mapping:
		%TopTextureOption.add_item( "%s:%s" % [das.mapping[face.ref.texture_data.upperTextureIndex].index, das.mapping[face.ref.texture_data.upperTextureIndex].name] )
	elif face.ref.texture_data.upperTextureIndex == 65535:
		pass
	else:
		%TopTextureOption.add_item( "%d" % face.ref.texture_data.upperTextureIndex )
	if face.ref.texture_data.midTextureIndex in das.mapping:
		%MidTextureOption.add_item( "%s:%s" % [das.mapping[face.ref.texture_data.midTextureIndex].index, das.mapping[face.ref.texture_data.midTextureIndex].name] )
	elif face.ref.texture_data.midTextureIndex == 65535:
		pass
	else:
		%MidTextureOption.add_item( "%d" % face.ref.texture_data.midTextureIndex )
	if face.ref.texture_data.lowerTextureIndex in das.mapping:
		%BottomTextureOption.add_item( "%s:%s" % [das.mapping[face.ref.texture_data.lowerTextureIndex].index, das.mapping[face.ref.texture_data.lowerTextureIndex].name] )
	elif face.ref.texture_data.lowerTextureIndex == 65535:
		pass
	else:
		%BottomTextureOption.add_item( "%d" % face.ref.texture_data.lowerTextureIndex )
	
	%TopTextureOption.add_item("--------")
	%TopTextureOption.add_item("Sky")
	%TopTextureOption.add_item("Select Texture")
	%TopTextureOption.add_item("Select Palette")
	%MidTextureOption.add_item("--------")
	%MidTextureOption.add_item("Sky")
	%MidTextureOption.add_item("Select Texture")
	%MidTextureOption.add_item("Select Palette")
	%BottomTextureOption.add_item("--------")
	%BottomTextureOption.add_item("Sky")
	%BottomTextureOption.add_item("Select Texture")
	%BottomTextureOption.add_item("Select Palette")
	
	if face.ref.sister:
		%SelectSisterButton.show()



func _on_bottom_texture_option_item_selected(index: int) -> void:
	if index == %BottomTextureOption.item_count - 1:
		var das: Dictionary = await Roth.get_das(selected_node.get_parent().ref.map_info.das)
		%Palette.show_palette(das.palette)
		%BottomTextureOption.select(0)
		var palette_index: int = await %Palette.color_selected
		if palette_index < 0:
			return
		selected_node.get_parent().ref.texture_data.lowerTextureIndex = palette_index + 32768
		load_edit_face(selected_node.get_parent())
		_redraw_selected_node()
	elif index == %BottomTextureOption.item_count - 2:
		var das: Dictionary = await Roth.get_das(selected_node.get_parent().ref.map_info.das)
		%Texture.show_texture(das)
		%BottomTextureOption.select(0)
		var texture_index: int = await %Texture.texture_selected
		if texture_index < 0:
			return
		selected_node.get_parent().ref.texture_data.lowerTextureIndex = texture_index
		load_edit_face(selected_node.get_parent())
		_redraw_selected_node()
	elif index == %BottomTextureOption.item_count - 3:
		selected_node.get_parent().ref.texture_data.lowerTextureIndex = Roth.get_map(selected_node.get_parent().ref.map_info).metadata.skyTexture
		load_edit_face(selected_node.get_parent())
		_redraw_selected_node()
	elif index == %BottomTextureOption.item_count - 4:
		%BottomTextureOption.select(0)


func _on_mid_texture_option_item_selected(index: int) -> void:
	if index == %MidTextureOption.item_count - 1:
		var das: Dictionary = await Roth.get_das(selected_node.get_parent().ref.map_info.das)
		%Palette.show_palette(das.palette)
		%MidTextureOption.select(0)
		var palette_index: int = await %Palette.color_selected
		if palette_index < 0:
			return
		selected_node.get_parent().ref.texture_data.midTextureIndex = palette_index + 32768
		load_edit_face(selected_node.get_parent())
		_redraw_selected_node()
	elif index == %MidTextureOption.item_count - 2:
		var das: Dictionary = await Roth.get_das(selected_node.get_parent().ref.map_info.das)
		%Texture.show_texture(das)
		%MidTextureOption.select(0)
		var texture_index: int = await %Texture.texture_selected
		if texture_index < 0:
			return
		selected_node.get_parent().ref.texture_data.midTextureIndex = texture_index
		load_edit_face(selected_node.get_parent())
		_redraw_selected_node()
	elif index == %MidTextureOption.item_count - 3:
		selected_node.get_parent().ref.texture_data.midTextureIndex = Roth.get_map(selected_node.get_parent().ref.map_info).metadata.skyTexture
		load_edit_face(selected_node.get_parent())
		_redraw_selected_node()
	elif index == %MidTextureOption.item_count - 4:
		%MidTextureOption.select(0)


func _on_top_texture_option_item_selected(index: int) -> void:
	if index == %TopTextureOption.item_count - 1:
		var das: Dictionary = await Roth.get_das(selected_node.get_parent().ref.map_info.das)
		%Palette.show_palette(das.palette)
		%TopTextureOption.select(0)
		var palette_index: int = await %Palette.color_selected
		if palette_index < 0:
			return
		selected_node.get_parent().ref.texture_data.upperTextureIndex = palette_index + 32768
		load_edit_face(selected_node.get_parent())
		_redraw_selected_node()
	elif index == %TopTextureOption.item_count - 2:
		var das: Dictionary = await Roth.get_das(selected_node.get_parent().ref.map_info.das)
		%Texture.show_texture(das)
		%TopTextureOption.select(0)
		var texture_index: int = await %Texture.texture_selected
		if texture_index < 0:
			return
		selected_node.get_parent().ref.texture_data.upperTextureIndex = texture_index
		load_edit_face(selected_node.get_parent())
		_redraw_selected_node()
	elif index == %TopTextureOption.item_count - 3:
		selected_node.get_parent().ref.texture_data.upperTextureIndex = Roth.get_map(selected_node.get_parent().ref.map_info).metadata.skyTexture
		load_edit_face(selected_node.get_parent())
		_redraw_selected_node()
	elif index == %TopTextureOption.item_count - 4:
		%TopTextureOption.select(0)


func _redraw_selected_node(node: Variant = null) -> void:
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


func _on_transparency_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		selected_node.get_parent().ref.texture_data.unk0x08 |= (1 << 0)
	else:
		selected_node.get_parent().ref.texture_data.unk0x08 &= ~(1 << 0)
	_redraw_selected_node()


func _on_flip_x_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		selected_node.get_parent().ref.texture_data.unk0x08 |= (1 << 1)
	else:
		selected_node.get_parent().ref.texture_data.unk0x08 &= ~(1 << 1)
	_redraw_selected_node()


func _on_image_fit_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		selected_node.get_parent().ref.texture_data.unk0x08 |= (1 << 2)
	else:
		selected_node.get_parent().ref.texture_data.unk0x08 &= ~(1 << 2)
	_redraw_selected_node()


func _on_fixed_size_transparency_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		selected_node.get_parent().ref.texture_data.unk0x08 |= (1 << 3)
	else:
		selected_node.get_parent().ref.texture_data.unk0x08 &= ~(1 << 3)
	_redraw_selected_node()


func _on_no_reflect_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		selected_node.get_parent().ref.texture_data.unk0x08 |= (1 << 4)
	else:
		selected_node.get_parent().ref.texture_data.unk0x08 &= ~(1 << 4)
	_redraw_selected_node()


func _on_half_pixel_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		selected_node.get_parent().ref.texture_data.unk0x08 |= (1 << 5)
	else:
		selected_node.get_parent().ref.texture_data.unk0x08 &= ~(1 << 5)
	_redraw_selected_node()


func _on_edge_map_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		selected_node.get_parent().ref.texture_data.unk0x08 |= (1 << 6)
	else:
		selected_node.get_parent().ref.texture_data.unk0x08 &= ~(1 << 6)
	_redraw_selected_node()


func _on_draw_from_bottom_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		selected_node.get_parent().ref.texture_data.unk0x08 |= (1 << 7)
	else:
		selected_node.get_parent().ref.texture_data.unk0x08 &= ~(1 << 7)
	_redraw_selected_node()


func _on_stop_walk_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		selected_node.get_parent().ref.data.addCollision |= (1 << 0)
	else:
		selected_node.get_parent().ref.data.addCollision &= ~(1 << 0)


func _on_stop_alen_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		selected_node.get_parent().ref.data.addCollision |= (1 << 1)
	else:
		selected_node.get_parent().ref.data.addCollision &= ~(1 << 1)


func _on_flag_3_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		selected_node.get_parent().ref.data.addCollision |= (1 << 2)
	else:
		selected_node.get_parent().ref.data.addCollision &= ~(1 << 2)


func _on_room_blk_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		selected_node.get_parent().ref.data.addCollision |= (1 << 3)
	else:
		selected_node.get_parent().ref.data.addCollision &= ~(1 << 3)


func _on_flag_5_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		selected_node.get_parent().ref.data.addCollision |= (1 << 4)
	else:
		selected_node.get_parent().ref.data.addCollision &= ~(1 << 4)


func _on_flag_6_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		selected_node.get_parent().ref.data.addCollision |= (1 << 5)
	else:
		selected_node.get_parent().ref.data.addCollision &= ~(1 << 5)


func _on_flag_7_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		selected_node.get_parent().ref.data.addCollision |= (1 << 6)
	else:
		selected_node.get_parent().ref.data.addCollision &= ~(1 << 6)


func _on_flag_8_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		selected_node.get_parent().ref.data.addCollision |= (1 << 7)
	else:
		selected_node.get_parent().ref.data.addCollision &= ~(1 << 7)


func _on_additional_check_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		if not "additionalMetadata" in selected_node.get_parent().ref.texture_data:
			selected_node.get_parent().ref.texture_data["additionalMetadata"] = {
				"shiftTextureX": 0,
				"shiftTextureY": 0,
				"unk0x0C": 0,
			}
		selected_node.get_parent().ref.texture_data.type += 0x80
		%XShiftEdit.editable = true
		%YShiftEdit.editable = true
		%"0x0CEdit".editable = true
	else:
		selected_node.get_parent().ref.texture_data.type -= 0x80
		%XShiftEdit.editable = false
		%YShiftEdit.editable = false
		%"0x0CEdit".editable = false
		selected_node.get_parent().ref.texture_data.additionalMetadata.shiftTextureX = 0
		selected_node.get_parent().ref.texture_data.additionalMetadata.shiftTextureY = 0
		selected_node.get_parent().ref.texture_data.additionalMetadata.unk0x0C = 0
		_redraw_selected_node()



func _on_x_shift_edit_value_changed(value: float) -> void:
	selected_node.get_parent().ref.texture_data.additionalMetadata.shiftTextureX = int(value)
	var caret: int = %XShiftEdit.get_line_edit().caret_column
	await _redraw_selected_node()
	%XShiftEdit.get_line_edit().grab_focus()
	await get_tree().process_frame
	%XShiftEdit.get_line_edit().caret_column = caret


func _on_y_shift_edit_value_changed(value: float) -> void:
	selected_node.get_parent().ref.texture_data.additionalMetadata.shiftTextureY = int(value)
	var caret: int = %YShiftEdit.get_line_edit().caret_column
	await _redraw_selected_node()
	%YShiftEdit.get_line_edit().grab_focus()
	await get_tree().process_frame
	%YShiftEdit.get_line_edit().caret_column = caret


func _on_x_0c_edit_text_changed(new_text: String) -> void:
	selected_node.get_parent().ref.texture_data.additionalMetadata.unk0x0C = int(new_text)



func _on_unk_0x_00_edit_value_changed(value: float) -> void:
	selected_node.get_parent().ref.texture_data.unk0x00 = int(value)


func _on_type_edit_value_changed(value: float) -> void:
	selected_node.get_parent().ref.texture_data.type = int(value)


func _on_unk_0x_00_type_edit_value_changed(value: float) -> void:
	selected_node.get_parent().ref.texture_data.unk0x00 = int(value) & 255
	selected_node.get_parent().ref.texture_data.type = (int(value) >> 8) | (selected_node.get_parent().ref.texture_data.type & (1<<7))
	var caret: int = %"Unk0x00+TypeEdit".get_line_edit().caret_column
	await _redraw_selected_node()
	%"Unk0x00+TypeEdit".get_line_edit().grab_focus()
	await get_tree().process_frame
	%"Unk0x00+TypeEdit".get_line_edit().caret_column = caret


func _on_auto_button_pressed() -> void:
	_on_unk_0x_00_type_edit_value_changed(int(selected_node.get_parent().ref.face_length))


func _on_roof_height_edit_value_changed(value: float) -> void:
	selected_node.get_parent().ref.data.ceilingHeight = value
	var caret: int = %RoofHeightEdit.get_line_edit().caret_column
	await _redraw_selected_node()
	%RoofHeightEdit.get_line_edit().grab_focus()
	await get_tree().process_frame
	%RoofHeightEdit.get_line_edit().caret_column = caret


func _on_floor_height_edit_value_changed(value: float) -> void:
	selected_node.get_parent().ref.data.floorHeight = value
	var caret: int = %FloorHeightEdit.get_line_edit().caret_column
	await _redraw_selected_node()
	%FloorHeightEdit.get_line_edit().grab_focus()
	await get_tree().process_frame
	%FloorHeightEdit.get_line_edit().caret_column = caret


func _on_glow_edit_value_changed(value: float) -> void:
	selected_node.get_parent().ref.data.lighting = value


func _on_floor_trigger_id_edit_value_changed(value: float) -> void:
	selected_node.get_parent().ref.data.floorTriggerID = value


func _on_candle_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		selected_node.get_parent().ref.data.textureFit |= (Sector.CANDLE)
	else:
		selected_node.get_parent().ref.data.textureFit &= ~(Sector.CANDLE)


func _on_unk_0x_04_edit_value_changed(value: float) -> void:
	selected_node.get_parent().ref.data.unk0x04 = value


func _on_lightning_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		selected_node.get_parent().ref.data.textureFit |= (Sector.LIGHTNING)
	else:
		selected_node.get_parent().ref.data.textureFit &= ~(Sector.LIGHTNING)


func _on_texture_height_override_edit_value_changed(value: float) -> void:
	selected_node.get_parent().ref.data.textureMapOverride = value
	var caret: int = %TextureHeightOverrideEdit.get_line_edit().caret_column
	await _redraw_selected_node()
	%TextureHeightOverrideEdit.get_line_edit().grab_focus()
	await get_tree().process_frame
	%TextureHeightOverrideEdit.get_line_edit().caret_column = caret



func _on_roof_offset_x_edit_value_changed(value: float) -> void:
	selected_node.get_parent().ref.data.ceilingTextureShiftX = value
	var caret: int = %RoofOffsetXEdit.get_line_edit().caret_column
	await _redraw_selected_node()
	%RoofOffsetXEdit.get_line_edit().grab_focus()
	await get_tree().process_frame
	%RoofOffsetXEdit.get_line_edit().caret_column = caret


func _on_roof_offset_y_edit_value_changed(value: float) -> void:
	selected_node.get_parent().ref.data.ceilingTextureShiftY = value
	var caret: int = %RoofOffsetYEdit.get_line_edit().caret_column
	await _redraw_selected_node()
	%RoofOffsetYEdit.get_line_edit().grab_focus()
	await get_tree().process_frame
	%RoofOffsetYEdit.get_line_edit().caret_column = caret


func _on_floor_offset_x_edit_value_changed(value: float) -> void:
	selected_node.get_parent().ref.data.floorTextureShiftX = value
	var caret: int = %FloorOffsetXEdit.get_line_edit().caret_column
	await _redraw_selected_node()
	%FloorOffsetXEdit.get_line_edit().grab_focus()
	await get_tree().process_frame
	%FloorOffsetXEdit.get_line_edit().caret_column = caret



func _on_floor_offset_y_edit_value_changed(value: float) -> void:
	selected_node.get_parent().ref.data.floorTextureShiftY = value
	var caret: int = %FloorOffsetYEdit.get_line_edit().caret_column
	await _redraw_selected_node()
	%FloorOffsetYEdit.get_line_edit().grab_focus()
	await get_tree().process_frame
	%FloorOffsetYEdit.get_line_edit().caret_column = caret



func _on_roof_scale_option_item_selected(index: int) -> void:
	match index:
		0:
			selected_node.get_parent().ref.data.textureFit &= ~Sector.CEILING_A
			selected_node.get_parent().ref.data.textureFit &= ~Sector.CEILING_B
		1:
			selected_node.get_parent().ref.data.textureFit |= Sector.CEILING_A
			selected_node.get_parent().ref.data.textureFit &= ~Sector.CEILING_B
		2:
			selected_node.get_parent().ref.data.textureFit &= ~Sector.CEILING_A
			selected_node.get_parent().ref.data.textureFit |= Sector.CEILING_B
		3:
			selected_node.get_parent().ref.data.textureFit |= Sector.CEILING_A
			selected_node.get_parent().ref.data.textureFit |= Sector.CEILING_B
	_redraw_selected_node()


func _on_floor_scale_option_item_selected(index: int) -> void:
	match index:
		0:
			selected_node.get_parent().ref.data.textureFit &= ~Sector.FLOOR_A
			selected_node.get_parent().ref.data.textureFit &= ~Sector.FLOOR_B
		1:
			selected_node.get_parent().ref.data.textureFit |= Sector.FLOOR_A
			selected_node.get_parent().ref.data.textureFit &= ~Sector.FLOOR_B
		2:
			selected_node.get_parent().ref.data.textureFit &= ~Sector.FLOOR_A
			selected_node.get_parent().ref.data.textureFit |= Sector.FLOOR_B
		3:
			selected_node.get_parent().ref.data.textureFit |= Sector.FLOOR_A
			selected_node.get_parent().ref.data.textureFit |= Sector.FLOOR_B
	_redraw_selected_node()


func _on_roof_texture_option_item_selected(index: int) -> void:
	if index == %RoofTextureOption.item_count - 1:
		var das: Dictionary = await Roth.get_das(selected_node.get_parent().ref.map_info.das)
		%Palette.show_palette(das.palette)
		%RoofTextureOption.select(0)
		var palette_index: int = await %Palette.color_selected
		if palette_index < 0:
			return
		selected_node.get_parent().ref.data.ceilingTextureIndex = palette_index + 65280
		load_edit_sector(selected_node.get_parent())
		_redraw_selected_node()
	elif index == %RoofTextureOption.item_count - 2:
		var das: Dictionary = await Roth.get_das(selected_node.get_parent().ref.map_info.das)
		%Texture.show_texture(das, true)
		%RoofTextureOption.select(0)
		var texture_index: int = await %Texture.texture_selected
		if texture_index < 0:
			return
		selected_node.get_parent().ref.data.ceilingTextureIndex = texture_index
		load_edit_sector(selected_node.get_parent())
		_redraw_selected_node()
	elif index == %RoofTextureOption.item_count - 3:
		selected_node.get_parent().ref.data.ceilingTextureIndex = Roth.get_map(selected_node.get_parent().ref.map_info).metadata.skyTexture
		load_edit_sector(selected_node.get_parent())
		_redraw_selected_node()
	elif index == %RoofTextureOption.item_count - 4:
		%RoofTextureOption.select(0)


func _on_floor_texture_option_item_selected(index: int) -> void:
	if index == %FloorTextureOption.item_count - 1:
		var das: Dictionary = await Roth.get_das(selected_node.get_parent().ref.map_info.das)
		%Palette.show_palette(das.palette)
		%FloorTextureOption.select(0)
		var palette_index: int = await %Palette.color_selected
		if palette_index < 0:
			return
		selected_node.get_parent().ref.data.floorTextureIndex = palette_index + 65280
		load_edit_sector(selected_node.get_parent())
		_redraw_selected_node()
	elif index == %FloorTextureOption.item_count - 2:
		var das: Dictionary = await Roth.get_das(selected_node.get_parent().ref.map_info.das)
		%Texture.show_texture(das, true)
		%FloorTextureOption.select(0)
		var texture_index: int = await %Texture.texture_selected
		if texture_index < 0:
			return
		selected_node.get_parent().ref.data.floorTextureIndex = texture_index
		load_edit_sector(selected_node.get_parent())
		_redraw_selected_node()
	elif index == %FloorTextureOption.item_count - 3:
		selected_node.get_parent().ref.data.floorTextureIndex = Roth.get_map(selected_node.get_parent().ref.map_info).metadata.skyTexture
		load_edit_sector(selected_node.get_parent())
		_redraw_selected_node()
	elif index == %FloorTextureOption.item_count - 4:
		%FloorTextureOption.select(0)




func _on_roof_flip_x_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		selected_node.get_parent().ref.data.unk0x16 |= (Sector.CEILING_FLIP_X)
	else:
		selected_node.get_parent().ref.data.unk0x16 &= ~(Sector.CEILING_FLIP_X)
	_redraw_selected_node()


func _on_roof_flip_y_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		selected_node.get_parent().ref.data.unk0x16 |= (Sector.CEILING_FLIP_Y)
	else:
		selected_node.get_parent().ref.data.unk0x16 &= ~(Sector.CEILING_FLIP_Y)
	_redraw_selected_node()


func _on_floor_flip_x_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		selected_node.get_parent().ref.data.unk0x16 |= (Sector.FLOOR_FLIP_X)
	else:
		selected_node.get_parent().ref.data.unk0x16 &= ~(Sector.FLOOR_FLIP_X)
	_redraw_selected_node()


func _on_floor_flip_y_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		selected_node.get_parent().ref.data.unk0x16 |= (Sector.FLOOR_FLIP_Y)
	else:
		selected_node.get_parent().ref.data.unk0x16 &= ~(Sector.FLOOR_FLIP_Y)
	_redraw_selected_node()


func _on_platform_floor_height_edit_value_changed(value: float) -> void:
	selected_node.get_parent().ref.platform.floorHeight = value
	_redraw_selected_node(%PlatformFloorHeightEdit)


func _on_platform_floor_scale_option_item_selected(index: int) -> void:
	match index:
		0:
			selected_node.get_parent().ref.platform.floorTextureScale &= ~Sector.FLOOR_A
			selected_node.get_parent().ref.platform.floorTextureScale &= ~Sector.FLOOR_B
		1:
			selected_node.get_parent().ref.platform.floorTextureScale |= Sector.FLOOR_A
			selected_node.get_parent().ref.platform.floorTextureScale &= ~Sector.FLOOR_B
		2:
			selected_node.get_parent().ref.platform.floorTextureScale &= ~Sector.FLOOR_A
			selected_node.get_parent().ref.platform.floorTextureScale |= Sector.FLOOR_B
		3:
			selected_node.get_parent().ref.platform.floorTextureScale |= Sector.FLOOR_A
			selected_node.get_parent().ref.platform.floorTextureScale |= Sector.FLOOR_B
	_redraw_selected_node()


func _on_platform_roof_height_edit_value_changed(value: float) -> void:
	selected_node.get_parent().ref.platform.ceilingHeight = value
	_redraw_selected_node(%PlatformRoofHeightEdit)


func _on_platform_roof_scale_option_item_selected(index: int) -> void:
	match index:
		0:
			selected_node.get_parent().ref.platform.floorTextureScale &= ~Sector.CEILING_A
			selected_node.get_parent().ref.platform.floorTextureScale &= ~Sector.CEILING_B
		1:
			selected_node.get_parent().ref.platform.floorTextureScale |= Sector.CEILING_A
			selected_node.get_parent().ref.platform.floorTextureScale &= ~Sector.CEILING_B
		2:
			selected_node.get_parent().ref.platform.floorTextureScale &= ~Sector.CEILING_A
			selected_node.get_parent().ref.platform.floorTextureScale |= Sector.CEILING_B
		3:
			selected_node.get_parent().ref.platform.floorTextureScale |= Sector.CEILING_A
			selected_node.get_parent().ref.platform.floorTextureScale |= Sector.CEILING_B
	_redraw_selected_node()


func _on_platform_floor_texture_option_item_selected(index: int) -> void:
	if index == %PlatformFloorTextureOption.item_count - 1:
		var das: Dictionary = await Roth.get_das(selected_node.get_parent().ref.map_info.das)
		%Palette.show_palette(das.palette)
		var palette_index: int = await %Palette.color_selected
		if palette_index < 0:
			return
		selected_node.get_parent().ref.platform.floorTextureIndex = palette_index + 65280
		load_edit_sector(selected_node.get_parent())
		_redraw_selected_node()
	elif index == %PlatformFloorTextureOption.item_count - 2:
		var das: Dictionary = await Roth.get_das(selected_node.get_parent().ref.map_info.das)
		%Texture.show_texture(das, true)
		var texture_index: int = await %Texture.texture_selected
		if texture_index < 0:
			return
		selected_node.get_parent().ref.platform.floorTextureIndex = texture_index
		load_edit_sector(selected_node.get_parent())
		_redraw_selected_node()
	elif index == %PlatformFloorTextureOption.item_count - 3:
		selected_node.get_parent().ref.platform.floorTextureIndex = Roth.get_map(selected_node.get_parent().ref.map_info).metadata.skyTexture
		load_edit_sector(selected_node.get_parent())
		_redraw_selected_node()
	elif index == %PlatformFloorTextureOption.item_count - 4:
		%PlatformFloorTextureOption.select(0)


func _on_platform_floor_offset_x_edit_value_changed(value: float) -> void:
	selected_node.get_parent().ref.platform.floorTextureShiftX = value
	_redraw_selected_node(%PlatformFloorOffsetXEdit)


func _on_platform_floor_offset_y_edit_value_changed(value: float) -> void:
	selected_node.get_parent().ref.platform.floorTextureShiftY = value
	_redraw_selected_node(%PlatformFloorOffsetYEdit)


func _on_platform_roof_texture_option_item_selected(index: int) -> void:
	if index == %PlatformRoofTextureOption.item_count - 1:
		var das: Dictionary = await Roth.get_das(selected_node.get_parent().ref.map_info.das)
		%Palette.show_palette(das.palette)
		var palette_index: int = await %Palette.color_selected
		if palette_index < 0:
			return
		selected_node.get_parent().ref.platform.ceilingTextureIndex = palette_index + 65280
		load_edit_sector(selected_node.get_parent())
		_redraw_selected_node()
	elif index == %PlatformRoofTextureOption.item_count - 2:
		var das: Dictionary = await Roth.get_das(selected_node.get_parent().ref.map_info.das)
		%Texture.show_texture(das, true)
		var texture_index: int = await %Texture.texture_selected
		if texture_index < 0:
			return
		selected_node.get_parent().ref.platform.ceilingTextureIndex = texture_index
		load_edit_sector(selected_node.get_parent())
		_redraw_selected_node()
	elif index == %PlatformRoofTextureOption.item_count - 3:
		selected_node.get_parent().ref.platform.ceilingTextureIndex = Roth.get_map(selected_node.get_parent().ref.map_info).metadata.skyTexture
		load_edit_sector(selected_node.get_parent())
		_redraw_selected_node()
	elif index == %PlatformRoofTextureOption.item_count - 4:
		%PlatformRoofTextureOption.select(0)


func _on_platform_roof_offset_x_edit_value_changed(value: float) -> void:
	selected_node.get_parent().ref.platform.ceilingTextureShiftX = value
	_redraw_selected_node(%PlatformRoofOffsetXEdit)


func _on_platform_roof_offset_y_edit_value_changed(value: float) -> void:
	selected_node.get_parent().ref.platform.ceilingTextureShiftY = value
	_redraw_selected_node(%PlatformRoofOffsetYEdit)


func _on_platform_check_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		selected_node.get_parent().ref.platform = {
			"ceilingTextureIndex": 2,
			"ceilingHeight": ((selected_node.get_parent().ref.data.ceilingHeight + selected_node.get_parent().ref.data.floorHeight) / 2) - 10,
			"ceilingTextureShiftX": 0,
			"ceilingTextureShiftY": 0,
			"floorTextureIndex": 2,
			"floorHeight": ((selected_node.get_parent().ref.data.ceilingHeight + selected_node.get_parent().ref.data.floorHeight) / 2) + 10,
			"floorTextureShiftX": 0,
			"floorTextureShiftY": 0,
			"floorTextureScale": Sector.FLOOR_A | Sector.CEILING_A,
			"padding": 0,
		}
	else:
		selected_node.get_parent().ref.platform = {}
	load_edit_sector(selected_node.get_parent())
	_redraw_selected_node(%PlatformRoofOffsetYEdit)


func _on_select_sister_button_pressed() -> void:
	select(selected_node.get_parent().ref.sister.get_ref().node, true)


func _on_select_sector_button_pressed() -> void:
	select(selected_node.get_parent().ref.sector.node, true)


func _on_select_faces_button_pressed() -> void:
	%SelectFacesPopupMenu.popup(Rect2i(%SelectFacesButton.global_position.x, %SelectFacesButton.global_position.y+%SelectFacesButton.size.y, %SelectFacesButton.size.x, 0))


func _on_select_faces_popup_menu_index_pressed(index: int) -> void:
	var face_node: Node3D = %SelectFacesPopupMenu.get_item_metadata(index)
	select(face_node, true)
