extends RefCounted
class_name ObjectRoth

var data: Dictionary = {}
var index: int = -1
var map_info: Dictionary = {}
var sectors: Array = []
var node: ObjectNode3D


static func new_from_copied_object(p_object: ObjectRoth, p_position: Vector2) -> ObjectRoth:
	var new_sector_index: int = -1
	for sector: Sector in p_object.sectors:
		if Geometry2D.is_point_in_polygon(p_position, sector.vertices.slice(0,-1)):
			new_sector_index = sector.index
	
	if new_sector_index == -1:
		Console.print("Can't paste object outside a sector")
		return
	
	var object := ObjectRoth.new(p_object.data.duplicate(true), Roth.get_map(p_object.map_info).get_next_object_index(), p_object.map_info, p_object.sectors)
	object.data.posX = -p_position.x
	object.data.posY = p_position.y
	object.sectors[new_sector_index].data.objectInformation.append(object.data)
	object.data.sector_index = new_sector_index
	
	return object


static func new_object(p_map_info: Dictionary, p_position: Vector2) -> ObjectRoth:
	var new_sector_index: int = -1
	for sector: Sector in Roth.get_map(p_map_info).sectors:
		if Geometry2D.is_point_in_polygon(p_position, sector.vertices.slice(0,-1)):
			new_sector_index = sector.index
	
	if new_sector_index == -1:
		Console.print("Can't create object outside a sector")
		return
	
	var default_data := {
		"posX": 0,
		"posY": 0,
		"textureIndex": 2,
		"textureSource": 0,
		"rotation": 0,
		"unk0x07": 0,
		"lighting": 128,
		"renderType": 0,
		"posZ": 0,
		"unk0x0C": 0,
		"unk0x0E": 0,
	}
	
	var object := ObjectRoth.new(default_data, Roth.get_map(p_map_info).get_next_object_index(), p_map_info, Roth.get_map(p_map_info).sectors)
	object.data.posX = -p_position.x
	object.data.posY = p_position.y
	object.sectors[new_sector_index].data.objectInformation.append(object.data)
	object.data.sector_index = new_sector_index
	
	return object


func _init(p_data: Dictionary, p_index: int, p_map_info: Dictionary, p_sectors: Array) -> void:
	data = p_data
	index = p_index
	map_info = p_map_info
	sectors = p_sectors


func duplicate() -> ObjectRoth:
	return ObjectRoth.new(data.duplicate(true), index, map_info, sectors)


func initialize_mesh() -> Node3D:
	if node:
		for child: Node in node.get_children():
			child.queue_free()
		_initialize_mesh()
		return
	
	node = ObjectNode3D.new()
	node.ref = self
	_initialize_mesh()
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


func get_node_2d() -> Node2D:
	var object := ObjectNode2D.new(self)
	return object



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
	
	signal object_selected(object: ObjectNode2D, tell_3d: bool)
	signal object_copied(object: ObjectRoth)
	signal object_deleted(object: ObjectRoth)
	
	const DRAGGING_THRESHOLD: float = 2.0
	
	var ref: ObjectRoth
	var circle: CircleDraw2D
	var mouse_over: bool = false
	var dragging: bool = false
	var drag_started: bool = false
	var dragging_amount := Vector2.ZERO
	var popup_menu: PopupMenu
	
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
		
		popup_menu = PopupMenu.new()
		popup_menu.add_item("Copy")
		popup_menu.add_item("Delete")
		popup_menu.index_pressed.connect(_on_popup_menu_index_pressed)
		add_child(popup_menu)
		
	
	func _on_mouse_entered() -> void:
		mouse_over = true
		circle.highlighted = true
	
	func _on_mouse_exited() -> void:
		mouse_over = false
		circle.highlighted = false
	
	func _input(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					if mouse_over:
						dragging = true
						dragging_amount = Vector2.ZERO
						drag_started = false
						circle.selected = true
						object_selected.emit(self, true)
				else:
					if dragging:
						dragging = false
						update_position()
			if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and mouse_over:
				popup_menu.popup(Rect2i(int(get_viewport().get_parent().global_position.x + event.global_position.x), int(get_viewport().get_parent().global_position.y + event.global_position.y), 0, 0))
				circle.selected = true
				object_selected.emit(self, true)
			
		if event is InputEventMouseMotion and dragging:
			dragging_amount += event.relative
			if dragging_amount.length() > DRAGGING_THRESHOLD * get_viewport().get_camera_2d().zoom.x or drag_started:
				drag_started = true
				var mouse: Vector2 = get_global_mouse_position() + get_parent().get_parent().global_position
				global_position = mouse.snappedf(get_parent().get_parent().snap)
	
	
	func _on_popup_menu_index_pressed(index: int) -> void:
		match index:
			0:
				object_copied.emit(ref.duplicate())
			1:
				ref.sectors[ref.data.sector_index].data.objectInformation.erase(ref.data)
				object_deleted.emit(ref)
				ref.node.queue_free()
				queue_free()
	
	
	func deselect() -> void:
		circle.selected = false
	
	func select() -> void:
		circle.selected = true
		object_selected.emit(self, false)
	
	func update_position() -> void:
		var pos := Vector2(
			position.x * Roth.SCALE_2D_WORLD,
			position.y * Roth.SCALE_2D_WORLD
		)
		
		var current_sector_index: int = ref.data.sector_index
		var new_sector_index: int = -1
		for sector: Sector in ref.sectors:
			if is_inside(pos, sector):
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
			ref.data.sector_index = new_sector_index
		
		ref.initialize_mesh()
		await get_tree().process_frame
		object_selected.emit(self, true)


	func is_inside(point: Vector2, sector: Sector) -> bool:
		var polygon_path_finder := PolygonPathFinder.new()
		var points := sector.vertices.slice(0,-1)
		var connections := []
		for i in range(len(points)-1):
			connections.append(i)
			connections.append(i+1)
		connections.append(len(points)-1)
		connections.append(0)
		polygon_path_finder.setup(points, connections)
		return polygon_path_finder.is_point_inside(point)

class ObjectNode3D extends Node3D:
	var ref: ObjectRoth

class ObjectMesh3D extends MeshInstance3D:
	var ref: ObjectRoth
