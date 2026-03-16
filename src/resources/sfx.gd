extends RefCounted
class_name SFX

var data: Dictionary = {}
var index: int :
	get():
		return map.sound_effects.find(self)
var map: Map
var node: SFXNode3D
var node_2d: SFXNode2D


static func new_from_copied_sfx(p_sfx: SFX, p_position: Vector2) -> SFX:	
	var sfx := SFX.new(p_sfx.data.duplicate(true), p_sfx.map)
	sfx.data.unk0x00 = -p_position.x
	sfx.data.unk0x02 = p_position.y
	
	return sfx


static func new_sfx(p_map: Map, p_position: Vector2) -> SFX:
	var default_data := {
		"unk0x00": 0,
		"unk0x02": 0,
		"unk0x04": 0,
		"unk0x06": 0,
		"unk0x08": 0,
		"zoneIndex": 0,
		"unk0x0A": 64,
		"unk0x0C": 0,
		"unk0x0E": 0,
		"volume": 64,
		"unk0x11": 0,
	}
	
	var sfx := SFX.new(default_data, p_map)
	sfx.data.unk0x00 = -p_position.x
	sfx.data.unk0x02 = p_position.y
	
	return sfx


func _init(p_data: Dictionary, p_map: Map) -> void:
	data = p_data
	map = p_map

func duplicate() -> SFX:
	return SFX.new(data.duplicate(true), map)

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
	var sector_floor_height:int = map.get_sector_floor_height_from_vertex(Vector2(-data.unk0x00, data.unk0x02))
	mesh_instance.position = Vector3(
			-data.unk0x00 / Roth.SCALE_3D_WORLD,
			sector_floor_height / Roth.SCALE_3D_WORLD,
			data.unk0x02 / Roth.SCALE_3D_WORLD,
	)
	mesh_instance.ref = self
	node.add_child(mesh_instance)



func get_node_2d() -> Node2D:
	if not node_2d:
		node_2d = SFXNode2D.new(self)
	return node_2d

func delete() -> void:
	if node:
		node.queue_free()
	if node_2d:
		node_2d.queue_free()
	map.sound_effects.erase(self)


class CircleDraw2D extends Node2D:
	var ref: SFX
	var radius: int = 1
	var highlighted: bool = false :
		set(value):
			highlighted = value
			queue_redraw()
	var selected: bool = false :
		set(value):
			selected = value
			queue_redraw()
	func _init(p_ref: SFX) -> void:
		ref = p_ref
	func _draw() -> void:
		var color := Color.ORANGE_RED
		if selected:
			color = Color.ORANGE
		elif highlighted:
			color = Color.CORAL
		draw_circle(Vector2.ZERO, radius, color)
		if (selected or highlighted or Settings.settings.get("options", {}).get("always_show_sfx_zones", false)):
			draw_circle(Vector2.ZERO, ref.data.unk0x0A / Roth.SCALE_2D_WORLD, color, false)
			if ref.data.zoneIndex > 0:
				if len(ref.map.sfx_zones) < ref.data.zoneIndex:
					return
				var zone_data: Dictionary = ref.map.sfx_zones[ref.data.zoneIndex-1]
				
				for i in range(1, zone_data.zoneCount+1):
					var x: float = -zone_data["zone%dXBoundUpper" % i] / Roth.SCALE_2D_WORLD
					var y: float = zone_data["zone%dYBoundLower" % i] / Roth.SCALE_2D_WORLD
					var length_x: float = (zone_data["zone%dXBoundUpper" % i] - zone_data["zone%dXBoundLower" % i]) / Roth.SCALE_2D_WORLD
					var length_y: float = (zone_data["zone%dYBoundUpper" % i] - zone_data["zone%dYBoundLower" % i]) / Roth.SCALE_2D_WORLD
					var zone_flags: int = zone_data["zone%dFlags" % i]
					var invert_zone: bool = (zone_flags & (1<<0)) > 0
					if invert_zone:
						color = Color.CRIMSON
					else:
						color = Color.SEA_GREEN
					draw_rect(Rect2(x, y, length_x, length_y), color, false)
				




class SFXNode2D extends Node2D:
	signal object_dragged(object: SFX)
	signal object_drag_ended(object: SFX)
	
	var ref: SFX
	var circle: CircleDraw2D
	var mouse_over: bool = false
	var dragging: bool = false
	var drag_started: bool = false
	var dragging_amount := Vector2.ZERO
	var start_drag_position: Vector2
	
	func _init(p_ref: SFX) -> void:
		ref = p_ref
		set_position_from_data()
		circle = CircleDraw2D.new(ref)
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
	
	func set_position_from_data() -> void:
		position = Vector2(
			-ref.data.unk0x00 / Roth.SCALE_2D_WORLD,
			ref.data.unk0x02 / Roth.SCALE_2D_WORLD
		)
	
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
		ref.data.unk0x00 = -int(pos.x)
		ref.data.unk0x02 = int(pos.y)
		ref.initialize_mesh()


class SFXNode3D extends Node3D:
	var ref: SFX
	func highlight() -> void:
		for child: MeshInstance3D in get_children():
			child.material_overlay = Roth.HIGHLIGHT_MATERIAL
	func unhighlight() -> void:
		for child: MeshInstance3D in get_children():
			child.material_overlay = null
	func select() -> void:
		for child: MeshInstance3D in get_children():
			child.material_overlay = Roth.SELECTED_MATERIAL
	func deselect() -> void:
		for child: MeshInstance3D in get_children():
			child.material_overlay = null


class SFXMesh3D extends MeshInstance3D:
	var ref: SFX
