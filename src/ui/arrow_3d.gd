extends Node3D

@export var target: Variant
@export var enabled: bool = true

var target_position: Variant


func _ready() -> void:
	if not enabled:
		hide()


func _process(_delta: float) -> void:
	if target:
		target_position = target.node.get_child(0).global_position
	elif not target_position:
		return
	if target_position is Vector3 and enabled:
		look_at(target_position)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_pointer_arrow"):
		enabled = not enabled
		if not enabled:
			hide()
		else:
			if target or target_position:
				show()


func set_target(resource: RefCounted) -> void:
	clear_target()
	if not resource:
		return
	if resource is Face:
		var node_pos: Vector2 = (resource.v2 + resource.v1) / 2
		var node_z: int = (resource.sector.data.ceilingHeight + resource.sector.data.floorHeight) / 2
		target_position = Vector3(node_pos.x / Roth.SCALE_3D_WORLD, node_z / Roth.SCALE_3D_WORLD, node_pos.y / Roth.SCALE_3D_WORLD)
	elif resource is Sector:
		var node_pos: Vector2 = calculate_center(resource.get_vertices())
		var node_z: int = (resource.data.ceilingHeight + resource.data.floorHeight) / 2
		target_position = Vector3(node_pos.x / Roth.SCALE_3D_WORLD, node_z / Roth.SCALE_3D_WORLD, node_pos.y / Roth.SCALE_3D_WORLD)
	elif resource is ObjectRoth or resource is Section7_1:
		target = resource
	else:
		target = resource
	if enabled:
		show()


func clear_target() -> void:
	target = null
	target_position = null
	hide()


func unset_target(resource: RefCounted) -> void:
	if resource == target:
		clear_target()


func calculate_center(vertices: Array) -> Vector2:
	var sum_x: float = 0.0
	var sum_y: float = 0.0
	for vertex: Vector2 in vertices:
		sum_x += vertex.x
		sum_y += vertex.y
	
	return Vector2(
			sum_x / len(vertices),
			sum_y / len(vertices)
	)
