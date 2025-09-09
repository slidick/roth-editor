extends RefCounted
class_name Section7_1

var data: Dictionary = {}
var index: int :
	get():
		return Roth.get_map(map_info).sound_effects.find(self)
var map_info: Dictionary = {}
var node: SFXNode3D


static func new_from_copied_object(p_object: Section7_1, p_position: Vector2) -> Section7_1:	
	var object := Section7_1.new(p_object.data.duplicate(true), p_object.map_info)
	object.data.unk0x00 = -p_position.x
	object.data.unk0x02 = p_position.y
	
	return object


static func new_object(p_map_info: Dictionary, p_position: Vector2) -> Section7_1:
	var default_data := {
		"unk0x00": 0,
		"unk0x02": 0,
		"unk0x04": 0,
		"unk0x06": 0,
		"unk0x08": 0,
		"unk0x0A": 0,
		"unk0x0C": 0,
		"unk0x0E": 0,
		"unk0x10": 0,
	}
	
	var object := Section7_1.new(default_data, p_map_info)
	object.data.unk0x00 = -p_position.x
	object.data.unk0x02 = p_position.y
	
	return object


func _init(p_data: Dictionary, p_map_info: Dictionary) -> void:
	data = p_data
	#index = p_index
	map_info = p_map_info

func duplicate() -> Section7_1:
	return Section7_1.new(data.duplicate(true), map_info)

func initialize_mesh() -> Node3D:
	if node:
		for child: Node in node.get_children():
			child.queue_free()
		_initialize_mesh()
		return
	
	node = SFXNode3D.new()
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
	var mesh_instance := SFXMesh3D.new()
	mesh_instance.mesh = sphere_mesh
	mesh_instance.add_child(static_body)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color.ORANGE_RED
	mesh_instance.material_override = material
	var sector_floor_height:int = Roth.get_map(map_info).get_sector_floor_height_from_vertex(Vector2(-data.unk0x00, data.unk0x02))
	mesh_instance.position = Vector3(
			-data.unk0x00 / Roth.SCALE_3D_WORLD,
			sector_floor_height / Roth.SCALE_3D_WORLD,
			data.unk0x02 / Roth.SCALE_3D_WORLD,
	)
	mesh_instance.ref = self
	node.add_child(mesh_instance)



func get_node_2d() -> Node2D:
	var sfx_node := SFXNode2D.new(self)
	return sfx_node



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
		var color := Color.ORANGE_RED
		if selected:
			color = Color.ORANGE
		elif highlighted:
			color = Color.CORAL
		draw_circle(Vector2.ZERO, radius, color)
		if roth_rotation >= 0:
			var angle_degrees: float = ((float(roth_rotation) / 256) * 360) - 90
			draw_line(Vector2.ZERO, Vector2(cos(deg_to_rad(angle_degrees)), sin(deg_to_rad(angle_degrees))) * 1.5, color, 0.1)



class SFXNode2D extends Node2D:
	signal object_selected(object: SFXNode2D, tell_3d: bool)
	signal object_copied(object: Section7_1)
	signal object_deleted(object: Section7_1)
	
	const DRAGGING_THRESHOLD: float = 2.0
	
	var ref: Section7_1
	var circle: CircleDraw2D
	var mouse_over: bool = false
	var dragging: bool = false
	var drag_started: bool = false
	var dragging_amount := Vector2.ZERO
	var popup_menu: PopupMenu
	
	func _init(p_ref: Section7_1) -> void:
		ref = p_ref
		position = Vector2(
			-ref.data.unk0x00 / Roth.SCALE_2D_WORLD,
			ref.data.unk0x02 / Roth.SCALE_2D_WORLD
		)
		circle = CircleDraw2D.new(-1)
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
						if drag_started:
							drag_started = false
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
		ref.data.unk0x00 = -int(pos.x)
		ref.data.unk0x02 = int(pos.y)
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


class SFXNode3D extends Node3D:
	var ref: Section7_1

class SFXMesh3D extends MeshInstance3D:
	var ref: Section7_1
