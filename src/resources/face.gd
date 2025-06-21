extends RefCounted
class_name Face

const SCALE_3D_WORLD: float = 100.0

# Texture Flags ( Unk0x08 )
const TRANSPARENT = 1 << 0
const FLIP_X = 1 << 1
const IMAGE_FIT = 1 << 2
const TRANSPARENT_UPPER_LOWER = 1 << 3
const NO_REFLECT = 1 << 4
const HALF_PIXEL = 1 << 5
const EDGE_MAP = 1 << 6
const PIN_BOTTOM = 1 << 7

# Texture Flags Additional ( Unk0x0C )
const FLAG1_UNK = 1 << 0
const FLAG2_UNK = 1 << 1
const FLAG3_UNK = 1 << 2
const FLAG4_UNK = 1 << 3
const FLAG5_UNK = 1 << 4
const FLAG6_UNK = 1 << 5
const FLAG7_UNK = 1 << 6
const FLAG8_UNK = 1 << 7

# Face Flags ( AddCollision )
const STOP_WALK = 1 << 0 # Stop player
const STOP_ALEN = 1 << 1 # Stop enemies
const TRIGGER = 1 << 2 # Set when toggling trigger in demo editor. Mostly unused across retail maps.
const ROOMBLK = 1 << 3 # No idea. Used to mark the entrances of certain rooms.
const FLAG5 = 1 << 4 # Only one face in whole game. An inconsequential face on DOPPLE
const FLAG6 = 1 << 5 # ^^ Same face has this plus a few faces on LRINTH and LRINTH1
const FLAG7 = 1 << 6 # Nothing
const FLAG8 = 1 << 7 # When combined with STOP_WALK, only stops movement under a platform. Seems to be used in a lot of unnecessary places though.


var data: Dictionary
var index: int
var map_info: Dictionary

var sector: Sector
var sister: WeakRef
var v1: Vector2
var v2: Vector2
var face_length: float :
	set(value):
		pass
	get():
		return (v2-v1).length()

var texture_data: Dictionary

var node: Node3D

static func are_points_collinear(points_list: Array) -> bool:
	# Check if there are fewer than 3 points, which can only form a line
	if len(points_list) < 3:
		return true
	
	# Iterate over all possible triplets
	for i in range(len(points_list)):
		for j in range(i + 1, len(points_list)):
			for k in range(j + 1, len(points_list)):
				var vector1: Vector3 = (points_list[j] - points_list[i])
				var vector2: Vector3 = (points_list[k] - points_list[i])
				
				# Compute the cross product of vector1 and vector2
				var cross_product: Vector3 = vector1.cross(vector2)
				
				# Check if the magnitude of the cross product is close to zero
				if cross_product.length() < 0.0001:
					continue
				
				# If any triplet is not collinear, return False
				return false
	
	# If all triplets are collinear, return True
	return true


static func check_flag(byte_value: int, flag: int) -> bool:
	return (byte_value & flag) > 0


func _init(p_data: Dictionary, p_index: int, p_map_info: Dictionary, p_vertices: Array = [], p_sectors: Array = [], p_texture_mappings: Array = []) -> void:
	data = p_data
	index = p_index
	map_info = p_map_info
	
	if not p_sectors.is_empty():
		sector = p_sectors[data.sectorIndex]
	if not p_vertices.is_empty():
		v1 = Vector2(-p_vertices[data.vertexIndex01].x, p_vertices[data.vertexIndex01].y)
		v2 = Vector2(-p_vertices[data.vertexIndex02].x, p_vertices[data.vertexIndex02].y)
	
	data.erase("vertexIndex01")
	data.erase("vertexIndex02")
	
	if not p_texture_mappings.is_empty():
		texture_data = p_texture_mappings[data.textureMappingIndex].duplicate(true)
	data.erase("textureMappingIndex")


func duplicate() -> Face:
	var new_face := Face.new(data.duplicate(true), Roth.get_map(map_info).get_next_face_index(), map_info)
	new_face.v1 = Vector2(v1)
	new_face.v2 = Vector2(v2)
	new_face.sector = sector
	new_face.texture_data = texture_data.duplicate(true)
	return new_face

static func create_new_face(p_map_info: Dictionary, p_sector: Sector) -> Face:
	var initial_data := {
		"addCollision": 0,
	}
	var new_face := Face.new(initial_data, Roth.get_map(p_map_info).get_next_face_index(), p_map_info)
	#new_face.v1 = Vector2(v1)
	#new_face.v2 = Vector2(v2)
	new_face.sector = p_sector
	var initial_texture_data := {
		"unk0x00": 16,
		"type": 0,
		"midTextureIndex": 3,
		"upperTextureIndex": 65535,
		"lowerTextureIndex": 65535,
		"unk0x08": 0,
	}
	new_face.texture_data = initial_texture_data
	return new_face

func update_sister_face(faces_array: Array) -> void:
	if "sisterFaceIndex" in data:
		sister = weakref(faces_array[data.sisterFaceIndex])

func update_horizontal_fit() -> void:
	var value := int(ceil(face_length))
	texture_data.unk0x00 = int(value) & 255
	texture_data.type = (int(value) >> 8) | (texture_data.type & (1<<7))


func delete() -> void:
	node.queue_free()
	sector = null


func create_mesh(vertices: Array, texture: int, das: Dictionary, mesh_height: float, mid: bool = false) -> FaceMesh3D:
	var mapping: Dictionary = das.mapping
	
	var static_body := StaticBody3D.new()
	var collision_shape := CollisionShape3D.new()
	var convex_polygon_shape := ConvexPolygonShape3D.new()
	var mesh_instance := FaceMesh3D.new()
	
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	#if not sister:
		#material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if (check_flag(texture_data.unk0x08, TRANSPARENT) and mid):
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	
	
	if sector.data.floorTriggerID == 65534 and sister:
		material.albedo_color = Color.TRANSPARENT
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	elif texture in mapping and "image" in mapping[texture]:
		if mapping[texture].is_sky:
			material.albedo_color = Color.TRANSPARENT
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		else:
			var mapping_image: ImageTexture
			if typeof(mapping[texture].image) == TYPE_ARRAY:
				mapping_image = mapping[texture].image[0]
			else:
				mapping_image = mapping[texture].image
			
			material.albedo_texture = mapping_image

	else:
		if texture == 65535:
			var color: Array = das.palette[texture - 65280]
			material.albedo_color = Color(color[0] / 256.0, color[1] / 256.0, color[2] / 256.0)
		elif texture >= 32768:
			var color: Array = das.palette[texture - 32768]
			material.albedo_color = Color(color[0] / 256.0, color[1] / 256.0, color[2] / 256.0)
		else:
			Console.print("Face has invalid texture; index: %s, texture: %s" % [index, texture])
			material.albedo_color = Color.WHITE
	
	
	var mesh_tool := SurfaceTool.new()
	mesh_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	mesh_tool.set_uv(Vector2(1,0))
	mesh_tool.add_vertex(vertices[0])
	mesh_tool.set_uv(Vector2(0,0))
	mesh_tool.add_vertex(vertices[1])
	mesh_tool.set_uv(Vector2(0,1))
	mesh_tool.add_vertex(vertices[2])
	
	mesh_tool.set_uv(Vector2(1,0))
	mesh_tool.add_vertex(vertices[0])
	mesh_tool.set_uv(Vector2(0,1))
	mesh_tool.add_vertex(vertices[2])
	mesh_tool.set_uv(Vector2(1,1))
	mesh_tool.add_vertex(vertices[3])
	mesh_tool.generate_normals()
	
	var mesh: ArrayMesh = mesh_tool.commit()
	
	
	if check_flag(texture_data.unk0x08, PIN_BOTTOM):
		mesh_tool = SurfaceTool.new()
		mesh_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		mesh_tool.set_uv(Vector2(0,0))
		mesh_tool.add_vertex(vertices[0])
		mesh_tool.set_uv(Vector2(1,0))
		mesh_tool.add_vertex(vertices[1])
		mesh_tool.set_uv(Vector2(1,1))
		mesh_tool.add_vertex(vertices[2])
		
		mesh_tool.set_uv(Vector2(0,0))
		mesh_tool.add_vertex(vertices[0])
		mesh_tool.set_uv(Vector2(1,1))
		mesh_tool.add_vertex(vertices[2])
		mesh_tool.set_uv(Vector2(0,1))
		mesh_tool.add_vertex(vertices[3])
		mesh_tool.generate_normals()
		mesh = mesh_tool.commit()
	
	
	var texture_width: float = 128
	var texture_height: float = 128
	
	if texture in mapping:
		texture_width = mapping[texture].height
		texture_height = mapping[texture].width
		
	if check_flag(texture_data.unk0x08, HALF_PIXEL):
		texture_width *= 0.5
		texture_height *= 0.5
		
	
	if not check_flag(texture_data.unk0x08, IMAGE_FIT) or (check_flag(texture_data.unk0x08, TRANSPARENT) and not mid):
		#material.uv1_scale.x = face_length / (2 * texture_width)
		material.uv1_scale.y = (texture_data.unk0x00 + ((texture_data.type & ~(1<<7))<<8)) / (2 * texture_width)
		material.uv1_scale.x = mesh_height / (2 * texture_height)
		
		
		
	if sector.data.textureMapOverride > 0 and sister and mid and check_flag(texture_data.unk0x08, TRANSPARENT_UPPER_LOWER):
		
		if not check_flag(texture_data.unk0x08, IMAGE_FIT):
			material.uv1_scale.x = float(sector.data.textureMapOverride * 2) / texture_height
		
		
		
		var new_points: Array = [
			Vector3(vertices[0].x, vertices[0].y + ((mesh_height - float(sector.data.textureMapOverride*4))/SCALE_3D_WORLD), vertices[0].z),
			Vector3(vertices[1].x, vertices[1].y, vertices[1].z),
			Vector3(vertices[2].x, vertices[2].y, vertices[2].z),
			Vector3(vertices[3].x, vertices[3].y + ((mesh_height - float(sector.data.textureMapOverride*4))/SCALE_3D_WORLD), vertices[3].z),
		]
		
		mesh_tool = SurfaceTool.new()
		mesh_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		mesh_tool.set_uv(Vector2(1,0))
		mesh_tool.add_vertex(new_points[0])
		mesh_tool.set_uv(Vector2(0,0))
		mesh_tool.add_vertex(new_points[1])
		mesh_tool.set_uv(Vector2(0,1))
		mesh_tool.add_vertex(new_points[2])
		
		mesh_tool.set_uv(Vector2(1,0))
		mesh_tool.add_vertex(new_points[0])
		mesh_tool.set_uv(Vector2(0,1))
		mesh_tool.add_vertex(new_points[2])
		mesh_tool.set_uv(Vector2(1,1))
		mesh_tool.add_vertex(new_points[3])
		mesh_tool.generate_normals()
		mesh = mesh_tool.commit()
		
	if sector.data.textureMapOverride < 0 and sister and mid and check_flag(texture_data.unk0x08, TRANSPARENT_UPPER_LOWER):
		
		if not check_flag(texture_data.unk0x08, IMAGE_FIT):
			material.uv1_scale.x = abs(float(sector.data.textureMapOverride * 2)) / texture_height
		
		var new_points: Array = [
			Vector3(vertices[0].x, vertices[0].y, vertices[0].z),
			Vector3(vertices[1].x, vertices[0].y + abs(float(sector.data.textureMapOverride*4)/SCALE_3D_WORLD), vertices[1].z),
			Vector3(vertices[2].x, vertices[0].y + abs(float(sector.data.textureMapOverride*4)/SCALE_3D_WORLD), vertices[2].z),
			Vector3(vertices[3].x, vertices[3].y, vertices[3].z),
		]
		
		mesh_tool = SurfaceTool.new()
		mesh_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		mesh_tool.set_uv(Vector2(1,0))
		mesh_tool.add_vertex(new_points[0])
		mesh_tool.set_uv(Vector2(0,0))
		mesh_tool.add_vertex(new_points[1])
		mesh_tool.set_uv(Vector2(0,1))
		mesh_tool.add_vertex(new_points[2])
		
		mesh_tool.set_uv(Vector2(1,0))
		mesh_tool.add_vertex(new_points[0])
		mesh_tool.set_uv(Vector2(0,1))
		mesh_tool.add_vertex(new_points[2])
		mesh_tool.set_uv(Vector2(1,1))
		mesh_tool.add_vertex(new_points[3])
		mesh_tool.generate_normals()
		mesh = mesh_tool.commit()
	
	
	
	if texture in mapping and "additionalMetadata" in texture_data and not check_flag(texture_data.unk0x08, IMAGE_FIT):
		if texture_data.additionalMetadata.shiftTextureX != 0:
				if texture_data.additionalMetadata.shiftTextureX > 0:
					material.uv1_offset.y = float(texture_data.additionalMetadata.shiftTextureX) / texture_width
				else:
					material.uv1_offset.y = float(texture_data.additionalMetadata.shiftTextureX + 256) / texture_width
		
		if texture_data.additionalMetadata.shiftTextureY != 0:
				if texture_data.additionalMetadata.shiftTextureY > 0:
					material.uv1_offset.x = float(texture_data.additionalMetadata.shiftTextureY) / texture_height
				else:
					material.uv1_offset.x = float(texture_data.additionalMetadata.shiftTextureY + 256) / texture_height
	
	
	
	
	if check_flag(texture_data.unk0x08, PIN_BOTTOM):
		material.uv1_scale.x *= -1
		material.uv1_offset.x *= -1
	
	if check_flag(texture_data.unk0x08, FLIP_X):
		material.uv1_scale.y *= -1
		material.uv1_offset.y *= -1
	
	
	if check_flag(texture_data.unk0x08, TRANSPARENT) and mid:
		if material.uv1_scale.x < 0:
			material.uv1_offset.x += 1
	
	
	if are_points_collinear(vertices):
		Console.print("Face forms a straight line (has no height): %s" % index)
		static_body.queue_free()
		collision_shape.queue_free()
	else:
		if sister:
			var collision_points: Array = []
			var mdt := MeshDataTool.new()
			mdt.create_from_surface(mesh, 0)
			for i in range(mdt.get_vertex_count()):
				var vertex := mdt.get_vertex(i)
				vertex += mdt.get_vertex_normal(i)*0.01
				if vertex not in collision_points:
					collision_points.append(vertex)
			
			convex_polygon_shape.points = collision_points
		
		else:
			convex_polygon_shape.points = vertices
		collision_shape.shape = convex_polygon_shape
		static_body.add_child(collision_shape)
		mesh_instance.add_child(static_body)
	
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	return mesh_instance


func initialize_mesh() -> Node3D:
	if node:
		for child: Node in node.get_children():
			child.queue_free()
		await _initialize_meshes()
		return
	
	node = Face3D.new()
	node.ref = self
	await _initialize_meshes()
	return node


func _initialize_meshes() -> void:
	var das: Dictionary = await Roth.get_das(map_info.das)
	assert(not das.is_empty())
	
	if not sister:
		var mesh_height: int = sector.data.ceilingHeight - sector.data.floorHeight
		var mesh_instance: FaceMesh3D = create_mesh(
			[
				Vector3(v1.x/SCALE_3D_WORLD, sector.data.floorHeight/SCALE_3D_WORLD, v1.y/SCALE_3D_WORLD),
				Vector3(v1.x/SCALE_3D_WORLD, sector.data.ceilingHeight/SCALE_3D_WORLD, v1.y/SCALE_3D_WORLD),
				Vector3(v2.x/SCALE_3D_WORLD, sector.data.ceilingHeight/SCALE_3D_WORLD, v2.y/SCALE_3D_WORLD),
				Vector3(v2.x/SCALE_3D_WORLD, sector.data.floorHeight/SCALE_3D_WORLD, v2.y/SCALE_3D_WORLD),
			],
			texture_data.midTextureIndex,
			das,
			mesh_height,
			true,
		)
		mesh_instance.ref = self
		node.add_child(mesh_instance)
	else:
		if check_flag(texture_data.unk0x08, TRANSPARENT):
			var floor_height: int = max(sector.data.floorHeight, sister.get_ref().sector.data.floorHeight)
			var ceiling_height: int = min(sector.data.ceilingHeight, sister.get_ref().sector.data.ceilingHeight)
			var mesh_height: int = ceiling_height - floor_height
			
			var mesh_instance: FaceMesh3D = create_mesh(
				[
					Vector3(v1.x/SCALE_3D_WORLD, floor_height/SCALE_3D_WORLD, v1.y/SCALE_3D_WORLD),
					Vector3(v1.x/SCALE_3D_WORLD, ceiling_height/SCALE_3D_WORLD, v1.y/SCALE_3D_WORLD),
					Vector3(v2.x/SCALE_3D_WORLD, ceiling_height/SCALE_3D_WORLD, v2.y/SCALE_3D_WORLD),
					Vector3(v2.x/SCALE_3D_WORLD, floor_height/SCALE_3D_WORLD, v2.y/SCALE_3D_WORLD),
				],
				texture_data.midTextureIndex,
				das,
				mesh_height,
				true,
			)
			mesh_instance.ref = self
			node.add_child(mesh_instance)
		
		if sector.data.floorHeight < sister.get_ref().sector.data.floorHeight:
			var mesh_height: int = sister.get_ref().sector.data.floorHeight - sector.data.floorHeight
			var mesh_instance: FaceMesh3D = create_mesh(
				[
					Vector3(v1.x/SCALE_3D_WORLD, sector.data.floorHeight/SCALE_3D_WORLD, v1.y/SCALE_3D_WORLD),
					Vector3(v1.x/SCALE_3D_WORLD, sister.get_ref().sector.data.floorHeight/SCALE_3D_WORLD, v1.y/SCALE_3D_WORLD),
					Vector3(v2.x/SCALE_3D_WORLD, sister.get_ref().sector.data.floorHeight/SCALE_3D_WORLD, v2.y/SCALE_3D_WORLD),
					Vector3(v2.x/SCALE_3D_WORLD, sector.data.floorHeight/SCALE_3D_WORLD, v2.y/SCALE_3D_WORLD),
				],
				texture_data.lowerTextureIndex,
				das,
				mesh_height,
				false,
			)
			mesh_instance.ref = self
			node.add_child(mesh_instance)
		
		if sector.data.ceilingHeight > sister.get_ref().sector.data.ceilingHeight:
			var mesh_height: int = sector.data.ceilingHeight - sister.get_ref().sector.data.ceilingHeight
			var mesh_instance: FaceMesh3D = create_mesh(
				[
					Vector3(v1.x/SCALE_3D_WORLD, sister.get_ref().sector.data.ceilingHeight/SCALE_3D_WORLD, v1.y/SCALE_3D_WORLD),
					Vector3(v1.x/SCALE_3D_WORLD, sector.data.ceilingHeight/SCALE_3D_WORLD, v1.y/SCALE_3D_WORLD),
					Vector3(v2.x/SCALE_3D_WORLD, sector.data.ceilingHeight/SCALE_3D_WORLD, v2.y/SCALE_3D_WORLD),
					Vector3(v2.x/SCALE_3D_WORLD, sister.get_ref().sector.data.ceilingHeight/SCALE_3D_WORLD, v2.y/SCALE_3D_WORLD),
				],
				texture_data.upperTextureIndex,
				das,
				mesh_height,
				false,
			)
			mesh_instance.ref = self
			node.add_child(mesh_instance)
		
		
		if true:
			var direction: Vector2 = (v2-v1).normalized()
			var right_perendicular := Vector2(-direction.y, direction.x)
			#var left_perendicular: Vector2 = -right_perendicular
			
			var a1: Vector2 = v1 + right_perendicular * 5
			#var a2: Vector2 = v1 + left_perendicular * 5
			#var a3: Vector2 = v2 + left_perendicular * 5
			var a2: Vector2 = v1
			var a3: Vector2 = v2
			var a4: Vector2 = v2 + right_perendicular * 5
			
			var static_body := StaticBody3D.new()
			var collision_shape := CollisionShape3D.new()
			var convex_polygon_shape := ConvexPolygonShape3D.new()
			var material := StandardMaterial3D.new()
			material.albedo_color = Color.TRANSPARENT
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			
			var mesh_instance := FaceMesh3D.new()
			var mesh_tool := SurfaceTool.new()
			mesh_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			
			var collision_points := [
				Vector3(a1.x/SCALE_3D_WORLD, sector.data.floorHeight/SCALE_3D_WORLD+0.01, a1.y/SCALE_3D_WORLD),
				Vector3(a2.x/SCALE_3D_WORLD, sector.data.floorHeight/SCALE_3D_WORLD+0.01, a2.y/SCALE_3D_WORLD),
				Vector3(a3.x/SCALE_3D_WORLD, sector.data.floorHeight/SCALE_3D_WORLD+0.01, a3.y/SCALE_3D_WORLD),
				Vector3(a4.x/SCALE_3D_WORLD, sector.data.floorHeight/SCALE_3D_WORLD+0.01, a4.y/SCALE_3D_WORLD),
			]
			
			mesh_tool.add_vertex(Vector3(a1.x/SCALE_3D_WORLD, sector.data.floorHeight/SCALE_3D_WORLD+0.01, a1.y/SCALE_3D_WORLD))
			mesh_tool.add_vertex(Vector3(a2.x/SCALE_3D_WORLD, sector.data.floorHeight/SCALE_3D_WORLD+0.01, a2.y/SCALE_3D_WORLD))
			mesh_tool.add_vertex(Vector3(a3.x/SCALE_3D_WORLD, sector.data.floorHeight/SCALE_3D_WORLD+0.01, a3.y/SCALE_3D_WORLD))
			
			mesh_tool.add_vertex(Vector3(a1.x/SCALE_3D_WORLD, sector.data.floorHeight/SCALE_3D_WORLD+0.01, a1.y/SCALE_3D_WORLD))
			mesh_tool.add_vertex(Vector3(a3.x/SCALE_3D_WORLD, sector.data.floorHeight/SCALE_3D_WORLD+0.01, a3.y/SCALE_3D_WORLD))
			mesh_tool.add_vertex(Vector3(a4.x/SCALE_3D_WORLD, sector.data.floorHeight/SCALE_3D_WORLD+0.01, a4.y/SCALE_3D_WORLD))
			mesh_tool.generate_normals()
			var mesh: ArrayMesh = mesh_tool.commit()
			
			convex_polygon_shape.points = collision_points
			collision_shape.shape = convex_polygon_shape
			static_body.add_child(collision_shape)
			mesh_instance.add_child(static_body)
			mesh_instance.mesh = mesh
			mesh_instance.material_override = material
			mesh_instance.ref = self
			node.add_child(mesh_instance)
		
		if sister and sister.get_ref().sector.platform and not check_flag(texture_data.unk0x08, TRANSPARENT):
			var mesh_height: int = sister.get_ref().sector.platform.floorHeight - sister.get_ref().sector.platform.ceilingHeight
			if mesh_height > 0:
				var mesh_instance: FaceMesh3D = create_mesh(
					[
						Vector3(v1.x/SCALE_3D_WORLD, sister.get_ref().sector.platform.ceilingHeight/SCALE_3D_WORLD, v1.y/SCALE_3D_WORLD),
						Vector3(v1.x/SCALE_3D_WORLD, sister.get_ref().sector.platform.floorHeight/SCALE_3D_WORLD, v1.y/SCALE_3D_WORLD),
						Vector3(v2.x/SCALE_3D_WORLD, sister.get_ref().sector.platform.floorHeight/SCALE_3D_WORLD, v2.y/SCALE_3D_WORLD),
						Vector3(v2.x/SCALE_3D_WORLD, sister.get_ref().sector.platform.ceilingHeight/SCALE_3D_WORLD, v2.y/SCALE_3D_WORLD),
					],
					texture_data.midTextureIndex,
					das,
					mesh_height,
					false,
				)
				mesh_instance.ref = self
				node.add_child(mesh_instance)



class Face3D extends Node3D:
	var ref: Face

class FaceMesh3D extends MeshInstance3D:
	var ref: Face
