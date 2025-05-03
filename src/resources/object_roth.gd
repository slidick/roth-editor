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


class ObjectMesh3D extends MeshInstance3D:
	var ref: ObjectRoth
