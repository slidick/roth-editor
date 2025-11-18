extends RefCounted
class_name ObjectRoth

var data: Dictionary = {}
var index: int :
	get():
		return Roth.get_map(map_info).objects.find(self)
var map_info: Dictionary = {}
var sectors: Array = []
var node: ObjectNode3D
var node_2d: ObjectNode2D
var sector: WeakRef


static func new_from_copied_object(p_object: ObjectRoth, p_position: Vector2) -> ObjectRoth:
	var new_sector_index: int = -1
	var floor_height: int = 0
	for f_sector: Sector in p_object.sectors:
		if Geometry2D.is_point_in_polygon(p_position, f_sector.vertices.slice(0,-1)):
			new_sector_index = f_sector.index
			floor_height = f_sector.data.floorHeight
	
	if new_sector_index == -1:
		Console.print("Can't paste object outside a sector")
		return
	
	var object := ObjectRoth.new(p_object.data.duplicate(true), p_object.map_info, p_object.sectors)
	object.data.posX = -p_position.x
	object.data.posY = p_position.y
	object.data.posZ = floor_height
	object.sectors[new_sector_index].data.objectInformation.append(object.data)
	object.sector = weakref(object.sectors[new_sector_index])
	#object.data.sector_index = new_sector_index
	
	return object


static func new_from_copied_object_3d(p_map_info: Dictionary, p_object: ObjectRoth, p_position: Vector3, extra_info: Dictionary) -> ObjectRoth:
	var new_sector_index: int = -1
	for f_sector: Sector in Roth.get_map(p_map_info).sectors:
		if Geometry2D.is_point_in_polygon(Vector2(p_position.x, p_position.z), f_sector.vertices.slice(0,-1)):
			new_sector_index = f_sector.index
	
	#if "sector_index" in extra_info:
		#new_sector_index = extra_info.sector_index
	if new_sector_index == -1:
		Console.print("Can't paste object outside a sector")
		return
	
	var object := ObjectRoth.new(p_object.data.duplicate(true), p_map_info, Roth.get_map(p_map_info).sectors)
	object.data.posX = -p_position.x
	object.data.posY = p_position.z
	object.data.posZ = p_position.y
	object.sectors[new_sector_index].data.objectInformation.append(object.data)
	object.sector = weakref(object.sectors[new_sector_index])
	#object.data.sector_index = new_sector_index
	
	if extra_info["render_type"] == "fixed":
		object.data.renderType |= 128
	elif extra_info["render_type"] == "billboard":
		object.data.renderType &= 0
	object.data.rotation = extra_info.rotation
	
	return object


static func new_object(p_map_info: Dictionary, p_position: Vector2) -> ObjectRoth:
	var new_sector_index: int = -1
	var floor_height: int = 0
	for f_sector: Sector in Roth.get_map(p_map_info).sectors:
		if Geometry2D.is_point_in_polygon(p_position, f_sector.vertices.slice(0,-1)):
			new_sector_index = f_sector.index
			floor_height = f_sector.data.floorHeight
	
	if new_sector_index == -1:
		Console.print("Can't create object outside a sector")
		return
	
	var default_data := {
		"posX": 0,
		"posY": 0,
		"textureIndex": 0,
		"textureSource": 2,
		"rotation": 0,
		"unk0x07": 0,
		"lighting": 128,
		"renderType": 0,
		"posZ": floor_height,
		"unk0x0C": 0,
		"unk0x0E": 0,
	}
	
	var object := ObjectRoth.new(default_data, p_map_info, Roth.get_map(p_map_info).sectors)
	object.data.posX = -p_position.x
	object.data.posY = p_position.y
	object.sectors[new_sector_index].data.objectInformation.append(object.data)
	object.sector = weakref(object.sectors[new_sector_index])
	#object.data.sector_index = new_sector_index
	
	return object


static func new_object_3d(p_map_info: Dictionary, p_position: Vector3, extra_info: Dictionary) -> ObjectRoth:
	var new_sector_index: int = -1
	var floor_height: int = 0
	for f_sector: Sector in Roth.get_map(p_map_info).sectors:
		if Geometry2D.is_point_in_polygon(Vector2(p_position.x, p_position.y), f_sector.vertices.slice(0,-1)):
			new_sector_index = f_sector.index
			floor_height = f_sector.data.floorHeight
	
	if "sector_index" in extra_info:
		new_sector_index = extra_info.sector_index
	if new_sector_index == -1:
		Console.print("Can't create object outside a sector")
		return
	
	var default_data := {
		"posX": 0,
		"posY": 0,
		"textureIndex": 0,
		"textureSource": 2,
		"rotation": 0,
		"unk0x07": 0,
		"lighting": 128,
		"renderType": 0,
		"posZ": floor_height,
		"unk0x0C": 0,
		"unk0x0E": 0,
	}
	
	var object := ObjectRoth.new(default_data, p_map_info, Roth.get_map(p_map_info).sectors)
	object.data.posX = -p_position.x
	object.data.posY = p_position.z
	object.data.posZ = p_position.y
	object.sectors[new_sector_index].data.objectInformation.append(object.data)
	object.sector = weakref(object.sectors[new_sector_index])
	#object.data.sector_index = new_sector_index
	
	if extra_info["render_type"] == "fixed":
		object.data.renderType = 128
	object.data.rotation = extra_info.rotation
	
	return object


func _init(p_data: Dictionary, p_map_info: Dictionary, p_sectors: Array, p_sector: Sector = null) -> void:
	data = p_data
	map_info = p_map_info
	sectors = p_sectors
	if p_sector:
		sector = weakref(p_sector)


func duplicate() -> ObjectRoth:
	return ObjectRoth.new(data.duplicate(true), map_info, sectors)


func initialize_mesh() -> Node3D:
	if node:
		for child: Node in node.get_children():
			child.queue_free()
		#_initialize_mesh()
		if sector.get_ref().hidden:
			return
		_initialize_mesh_actual()
		return
	
	node = ObjectNode3D.new()
	node.ref = self
	_initialize_mesh_actual()
	#_initialize_mesh()
	return node


func _initialize_mesh() -> void:
	var shape := SphereShape3D.new()
	shape.radius = 0.125
	var static_body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	collision.shape = shape
	static_body.add_child(collision)
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.125
	sphere_mesh.height = 0.25
	var mesh_instance := ObjectMesh3D.new()
	mesh_instance.mesh = sphere_mesh
	mesh_instance.add_child(static_body)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color.REBECCA_PURPLE
	mesh_instance.material_override = material
	mesh_instance.position = Vector3(
			-data.posX / Roth.SCALE_3D_WORLD,
			data.posZ / Roth.SCALE_3D_WORLD,
			data.posY / Roth.SCALE_3D_WORLD,
	)
	mesh_instance.ref = self
	node.add_child(mesh_instance)


func _initialize_mesh_actual() -> void:
	var object_das: String
	var object_index: int
	if data.textureSource == 0:
		object_das = map_info.das
		object_index = data.textureIndex + 4096
	elif data.textureSource == 1:
		object_das = map_info.das
		object_index = data.textureIndex + 4096 + 256
	elif data.textureSource == 2:
		object_das = "M/ADEMO.DAS"
		object_index = data.textureIndex
	elif data.textureSource == 3:
		object_das = "M/ADEMO.DAS"
		object_index = data.textureIndex + 256
	else:
		_initialize_mesh()
		return
	
	var texture := Roth.get_index_from_das(object_index, object_das)
	if texture.name == "Invalid":
		_initialize_mesh()
		return
	var width: float = texture.height / Roth.SCALE_3D_WORLD
	var height: float = texture.width / Roth.SCALE_3D_WORLD
	if (texture.unk & (1<<7)) > 0:
		width /= 2
		height /= 2
	
	var low_y: float = 0
	var high_y: float = height * 2
	if (texture.unk_byte_00 & (1<<3) > 0):
		pass
		#low_y -= height
		#high_y -= height
	
	if (texture.unk_byte_00 & (1<<4) > 0):
		low_y -= (height * 2)
		high_y -= (height * 2)
	
	
	var material := StandardMaterial3D.new()
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if data.renderType & (1<<7) > 0:
		pass
	else:
		material.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	if "image" in texture:
		material.albedo_texture = texture.image[0] if typeof(texture.image) == TYPE_ARRAY else texture.image
	elif "animation" in texture:
		material.albedo_texture = texture.animation[0]
	else:
		_initialize_mesh()
		return
	
	var mesh := QuadMesh.new()
	mesh.material = material
	
	var mesh_array := ArrayMesh.new()
	mesh_array.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh.get_mesh_arrays())
	var mdt := MeshDataTool.new()
	mdt.create_from_surface(mesh_array, 0)
	mdt.set_vertex_uv(1, Vector2(1,0))
	mdt.set_vertex_uv(2, Vector2(0,1))
	
	
	
	mdt.set_vertex(0, Vector3(width, low_y, 0))
	mdt.set_vertex(1, Vector3(-width, low_y, 0))
	mdt.set_vertex(2, Vector3(width, high_y, 0))
	mdt.set_vertex(3, Vector3(-width, high_y, 0))
	
	if (data.unk0x07 & (1<<4)) > 0:
		mdt.set_vertex_uv(0, Vector2(1,0))
		mdt.set_vertex_uv(1, Vector2(1,1))
		mdt.set_vertex_uv(2, Vector2(0,0))
		mdt.set_vertex_uv(3, Vector2(0,1))
	
	
	mesh_array.clear_surfaces()
	#mesh_array.material = material
	mdt.commit_to_surface(mesh_array)


	
	var mesh_instance := ObjectMesh3D.new()
	mesh_instance.mesh = mesh_array
	mesh_instance.material_override = material
	mesh_instance.ref = self
	mesh_instance.position = Vector3(
			-data.posX / Roth.SCALE_3D_WORLD,
			data.posZ / Roth.SCALE_3D_WORLD,
			data.posY / Roth.SCALE_3D_WORLD,
	)
	node.add_child(mesh_instance)
	
	var shape := BoxShape3D.new()
	shape.size.z = 0.005
	shape.size.x = width * 2
	shape.size.y = height * 2
	
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = height
	
	if (texture.unk_byte_00 & (1<<3) > 0):
		collision.position.y = 0
	if (texture.unk_byte_00 & (1<<4) > 0):
		collision.position.y = -height
	
	var static_body := StaticBodyObject3D.new(not data.renderType & (1<<7) > 0)
	static_body.add_child(collision)
	mesh_instance.add_child(static_body)
	
	if data.renderType & (1<<7) > 0:
		var angle_degrees: float = ((float(data.rotation) / 256) * 360) - 180
		mesh_instance.rotation_degrees.y -= angle_degrees


func get_node_2d() -> Node2D:
	if not node_2d:
		node_2d = ObjectNode2D.new(self)
	return node_2d


func delete() -> void:
	if node:
		node.queue_free()
	if node_2d:
		node_2d.queue_free()
	sector.get_ref().data.objectInformation.erase(data)
	Roth.get_map(map_info).objects.erase(self)


class CircleDraw2D extends Node2D:
	var roth_rotation: int = 0
	var radius: int = 1
	var highlighted: bool = false :
		set(value):
			highlighted = value
			queue_redraw()
	var selected: bool = false :
		set(value):
			selected = value
			queue_redraw()
	func _init(p_rotation: int) -> void:
		roth_rotation = p_rotation
	func _draw() -> void:
		var color := Color.REBECCA_PURPLE
		if selected:
			color = Color.WEB_PURPLE
		elif highlighted:
			color = Color.MEDIUM_PURPLE
		draw_circle(Vector2.ZERO, radius, color)
		var angle_degrees: float = ((float(roth_rotation) / 256) * 360) - 90
		draw_line(Vector2.ZERO, Vector2(cos(deg_to_rad(angle_degrees)), sin(deg_to_rad(angle_degrees))) * 1.5, color, 0.1)


class ObjectNode2D extends Node2D:
	signal object_dragged(object: ObjectNode2D, relative: Vector2)
	signal object_drag_ended(object: ObjectNode2D)
	
	var ref: ObjectRoth
	var circle: CircleDraw2D
	var mouse_over: bool = false
	var dragging: bool = false
	var drag_started: bool = false
	var dragging_amount := Vector2.ZERO
	var start_drag_position: Vector2
	
	func _init(p_ref: ObjectRoth) -> void:
		ref = p_ref
		position = Vector2(
			-ref.data.posX / Roth.SCALE_2D_WORLD,
			ref.data.posY / Roth.SCALE_2D_WORLD
		)
		circle = CircleDraw2D.new(ref.data.rotation)
		add_child(circle)
		var shape := CircleShape2D.new()
		shape.radius = 1
		var collision := CollisionShape2D.new()
		collision.shape = shape
		var area := Area2D.new()
		area.add_child(collision)
		area.mouse_entered.connect(_on_mouse_entered)
		area.mouse_exited.connect(_on_mouse_exited)
		add_child(area)
	
	func _on_mouse_entered() -> void:
		mouse_over = true
		circle.highlighted = true
	
	func _on_mouse_exited() -> void:
		mouse_over = false
		circle.highlighted = false
	
	func _input(event: InputEvent) -> void:
		if event is InputEventKey:
			if drag_started and event.keycode == KEY_ESCAPE and event.pressed:
				dragging = false
				drag_started = false
				position = start_drag_position
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if not event.shift_pressed:
					if event.pressed:
						if mouse_over:
							dragging = true
							dragging_amount = Vector2.ZERO
							drag_started = false
					else:
						if dragging:
							dragging = false
							if drag_started:
								drag_started = false
								update_position()
								object_drag_ended.emit(self)
		
		if event is InputEventMouseMotion and dragging:
			dragging_amount += event.relative
			if dragging_amount.length() > Roth.DRAGGING_THRESHOLD * get_viewport().get_camera_2d().zoom.x or drag_started:
				if drag_started == false:
					drag_started = true
					start_drag_position = position
				
				var mouse: Vector2 = get_global_mouse_position() + get_parent().get_parent().global_position
				var relative: Vector2 = global_position - mouse.snappedf(get_parent().get_parent().snap)
				global_position -= relative
				object_dragged.emit(self, relative)
	
	func deselect() -> void:
		circle.selected = false
	
	func select() -> void:
		circle.selected = true
	
	func move(relative: Vector2) -> void:
		if circle.selected:
			if drag_started == false:
				drag_started = true
				start_drag_position = position
			global_position -= relative
	
	func end_drag() -> void:
		if circle.selected:
			drag_started = false
			update_position()
	
	func update_position() -> void:
		var pos := Vector2(
			position.x * Roth.SCALE_2D_WORLD,
			position.y * Roth.SCALE_2D_WORLD
		)
		
		var current_sector_index: int = ref.sector.get_ref().index
		var new_sector_index: int = -1
		for sector: Sector in ref.sectors:
			if Geometry2D.is_point_in_polygon(pos, sector.vertices.slice(0,-1)):
				new_sector_index = sector.index
		
		for object: Dictionary in ref.sectors[new_sector_index].data.objectInformation:
			if object.posX == -int(pos.x) and object.posY == int(pos.y):
				position = Vector2(
					-ref.data.posX / Roth.SCALE_2D_WORLD,
					ref.data.posY / Roth.SCALE_2D_WORLD
				)
				return
				
		
		if new_sector_index == -1:
			position = Vector2(
				-ref.data.posX / Roth.SCALE_2D_WORLD,
				ref.data.posY / Roth.SCALE_2D_WORLD
			)
			return
		
		if new_sector_index == current_sector_index:
			ref.data.posX = -int(pos.x)
			ref.data.posY = int(pos.y)
		else:
			ref.data.posX = -int(pos.x)
			ref.data.posY = int(pos.y)
			ref.sectors[current_sector_index].data.objectInformation.erase(ref.data)
			ref.sectors[new_sector_index].data.objectInformation.append(ref.data)
			ref.sector = weakref(ref.sectors[new_sector_index])
		
		ref.initialize_mesh()


class ObjectNode3D extends Node3D:
	var ref: ObjectRoth
	var _highlighted: bool = false
	var _selected: bool = false
	func highlight() -> void:
		if not _selected:
			_highlighted = true
			for child: MeshInstance3D in get_children():
				if not ((ref.data.renderType & (1<<7)) > 0):
					child.material_overlay = Roth.HIGHLIGHT_FIXED_Y_MATERIAL
				else:
					child.material_overlay = Roth.HIGHLIGHT_MATERIAL
	func unhighlight() -> void:
		if _highlighted and not _selected:
			_highlighted = false
			for child: MeshInstance3D in get_children():
				child.material_overlay = null
	func select() -> void:
		_selected = true
		for child: MeshInstance3D in get_children():
			if not ((ref.data.renderType & (1<<7)) > 0):
				child.material_overlay = Roth.SELECTED_FIXED_Y_MATERIAL
			else:
				child.material_overlay = Roth.SELECTED_MATERIAL
	func deselect() -> void:
		_selected = false
		for child: MeshInstance3D in get_children():
			child.material_overlay = null


class ObjectMesh3D extends MeshInstance3D:
	var ref: ObjectRoth


class StaticBodyObject3D extends StaticBody3D:
	var follow: bool = false
	func _init(p_follow: bool) -> void:
		follow = p_follow
	func _process(_delta: float) -> void:
		if follow:
			look_at(get_viewport().get_camera_3d().global_position)
			rotation.x = 0
