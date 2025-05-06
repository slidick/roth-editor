extends RefCounted
class_name ObjectRoth

var data: Dictionary = {}
var index: int = -1
var map_info: Dictionary = {}


func _init(p_data: Dictionary, p_index: int, p_map_info: Dictionary) -> void:
	data = p_data
	index = p_index
	map_info = p_map_info


func initialize_mesh() -> Array:
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
	return [mesh_instance]


func get_node_2d() -> Node2D:
	var object := ObjectNode2D.new()
	object.ref = self
	object.position = Vector2(
		-data.posX / Roth.SCALE_2D_WORLD,
		data.posY / Roth.SCALE_2D_WORLD
	)
	object.add_child(CircleDraw2D.new())
	var shape := CircleShape2D.new()
	shape.radius = 1
	var collision := CollisionShape2D.new()
	collision.shape = shape
	var area := Area2D.new()
	area.add_child(collision)
	area.mouse_entered.connect(_on_mouse_entered.bind(object))
	area.mouse_exited.connect(_on_mouse_exited.bind(object))
	object.add_child(area)
	
	return object



func _on_mouse_entered(object: ObjectNode2D) -> void:
	print("Mouse over object: %s" % object.ref.index)


func _on_mouse_exited(object: ObjectNode2D) -> void:
	print("Mouse left object: %s" % object.ref.index)


class CircleDraw2D extends Node2D:
	var radius: int = 1
	func _draw() -> void:
		draw_circle(Vector2.ZERO, radius, Color.REBECCA_PURPLE)

class ObjectNode2D extends Node2D:
	var ref: ObjectRoth

class ObjectMesh3D extends MeshInstance3D:
	var ref: ObjectRoth
