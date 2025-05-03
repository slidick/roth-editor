extends Node3D

@export var target_node: Node3D
@export var enabled: bool = true

var target_position: Variant


func _ready() -> void:
	if not enabled:
		hide()


func _process(_delta: float) -> void:
	if target_node:
		target_position = target_node.global_position
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
			if target_node or target_position:
				show()


func set_target(node: Node3D) -> void:
	clear_target()
	if node is Face.FaceMesh3D:
		var node_pos: Vector2 = (node.ref.v2 + node.ref.v1) / 2
		var node_z: int = (node.ref.sector.data.ceilingHeight + node.ref.sector.data.floorHeight) / 2
		target_position = Vector3(node_pos.x / Roth.SCALE_3D_WORLD, node_z / Roth.SCALE_3D_WORLD, node_pos.y / Roth.SCALE_3D_WORLD)
	elif node is Sector.SectorMesh3D:
		var node_pos: Vector2 = calculate_center(node.ref.vertices)
		var node_z: int = (node.ref.data.ceilingHeight + node.ref.data.floorHeight) / 2
		target_position = Vector3(node_pos.x / Roth.SCALE_3D_WORLD, node_z / Roth.SCALE_3D_WORLD, node_pos.y / Roth.SCALE_3D_WORLD)
	elif node is ObjectRoth.ObjectMesh3D or node is Section7_1.SFXMesh3D:
		target_node = node
	else:
		target_node = node
	if enabled:
		show()


func clear_target() -> void:
	target_node = null
	target_position = null
	hide()


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
