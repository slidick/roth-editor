extends RefCounted
class_name Sector

# Texture scaling (A, B)
# (0, 0) = 1:2
# (1, 0) = 1:1
# (0, 1) = 2:1
# (1, 1) = 4:1

# "Texture Fit" Flags
const LINK_EXISTS = 1 << 0
const CANDLE = 1 << 1
const CEILING_A = 1 << 2
const CEILING_B = 1 << 3
const FLOOR_A = 1 << 4
const FLOOR_B = 1 << 5
const LIGHTNING = 1 << 6
const UNUSED = 1 << 7

# Texture Flip Flags (unk0x16)
const FLOOR_FLIP_X = 1 << 8
const FLOOR_FLIP_Y = 1 << 9
const CEILING_FLIP_X = 1 << 10
const CEILING_FLIP_Y = 1 << 11


var data: Dictionary
var index: int
var map_info: Dictionary

var faces: Array = []
var vertices: Array
var platform: Dictionary
#var objects: Array = []
var node: Node3D

static func check_flag(byte_value: int, flag: int) -> bool:
	return (byte_value & flag) > 0


func _init(p_data: Dictionary, p_index: int, p_map_info: Dictionary, p_platforms: Array = []) -> void:
	data = p_data
	index = p_index
	map_info = p_map_info
	if "intermediateFloorIndex" in data:
		platform = p_platforms[data.intermediateFloorIndex]
	#if "objectInformation" in data:
		#objects = data.objectInformation


func duplicate() -> Sector:
	var new_sector := Sector.new(data.duplicate(true), Roth.get_map(map_info).get_next_sector_index(), map_info)
	if platform:
		new_sector.platform = platform.duplicate(true)
	new_sector.faces = []
	return new_sector


func update_faces(faces_array: Array) -> void:
	for i in range(data.firstFaceIndex, data.firstFaceIndex + data.facesCount):
		faces.append(weakref(faces_array[i]))
	_update_vertices()


## Get all vertices of a sector in clockwise order
func _update_vertices() -> void:
	var _vertices := []
	for face_ref: WeakRef in faces:
		var face: Face = face_ref.get_ref()
		_vertices.append(face.v1)
		_vertices.append(face.v2)
	vertices = Geometry2D.convex_hull(_vertices)

func delete_vertex(vertex_node: VertexNode) -> void:
	var vertex_to_delete: Vector2 = vertex_node.coordinate
	var only_two: bool = true if len(vertex_node.sectors) == 2 else false
	var face_to_change: Face
	var face_to_delete: WeakRef
	var faces_remaining := []
	
	for face_ref: WeakRef in faces:
		var face: Face = face_ref.get_ref()
		if face.v1 == vertex_to_delete:
			face_to_delete = face_ref
		elif face.v2 == vertex_to_delete:
			face_to_change = face
		else:
			faces_remaining.append(face)
	
	if len(faces_remaining) < 2:
		delete_sector()
		return
	
	if only_two:
		if face_to_delete.get_ref().sister:
			if face_to_change.sister:
				face_to_delete.get_ref().sister.get_ref().sister = weakref(face_to_change)
			else:
				face_to_delete.get_ref().sister.get_ref().sister = null
	else:
		if face_to_delete and face_to_delete.get_ref().sister:
			face_to_delete.get_ref().sister.get_ref().sister = null
	
	
	var current_vertices := get_vertices()
	var next_index := current_vertices.find(vertex_to_delete) + 1
	if next_index == -1:
		print("ERROR")
		return
	
	face_to_change.v2 = current_vertices[next_index % len(current_vertices)]
	face_to_change.update_horizontal_fit()
	faces.erase(face_to_delete)
	if face_to_delete:
		face_to_delete.get_ref().delete()
	_update_vertices()
	initialize_mesh()
	for face_ref: WeakRef in faces:
		var face: Face = face_ref.get_ref()
		if face.sister:
			face.sister.get_ref().initialize_mesh()
			face.sister.get_ref().update_horizontal_fit()
		face.initialize_mesh()
		face.update_horizontal_fit()


func delete_sector() -> void:
	for face_ref: WeakRef in faces:
		var face: Face = face_ref.get_ref()
		if face.sister:
			face.sister.get_ref().sister = null
			face.sister.get_ref().initialize_mesh()
		face.delete()
	faces.clear()
	node.queue_free()
	Roth.get_map(map_info).delete_sector(self)


func delete_face(face_to_delete: Face) -> void:
	var face_to_delete_ref: WeakRef
	var remaining_faces := []
	for face_ref: WeakRef in faces:
		var face: Face = face_ref.get_ref()
		if face == face_to_delete:
			face_to_delete_ref = face_ref
		else:
			remaining_faces.append(face_ref)
	
	if len(remaining_faces) < 3:
		delete_sector()
		return
	
	faces.erase(face_to_delete_ref)
	
	if face_to_delete.sister:
		var sister: Face = face_to_delete.sister.get_ref()
		sister.sister = null
		sister.sector.delete_face(sister)
	face_to_delete.delete()


func split_face(face_to_split: Face) -> Face:
	var idx: int
	var new_face: Face
	for i in range(len(faces)):
		var face: Face = faces[i].get_ref()
		if face == face_to_split:
			idx = i
			new_face = face.duplicate()
			var mid_point: Vector2 = (face.v1 + face.v2) / 2
			face.v2 = mid_point
			new_face.v1 = mid_point
			var mesh: Node3D = await new_face.initialize_mesh()
			node.get_parent().get_parent().get_node("Faces").add_child(mesh)
	if not new_face:
		return
	faces.insert(idx+1, weakref(new_face))
	_update_vertices()
	initialize_mesh()
	for face_ref: WeakRef in faces:
		var face: Face = face_ref.get_ref()
		if face.sister:
			face.sister.get_ref().initialize_mesh()
			face.sister.get_ref().update_horizontal_fit()
		face.initialize_mesh()
		face.update_horizontal_fit()
	return new_face



func get_vertices() -> Array:
	# Collect all vertices from the sector's faces
	var vertex_pairs := []
	for face_ref: WeakRef in faces:
		var face: Face = face_ref.get_ref()
		vertex_pairs.append({
			"start": Vector2(face.v1.x, face.v1.y ),
			"end": Vector2(face.v2.x, face.v2.y )
		})
	
	
	# Sort vertices to form a connected polygon
	var ordered_vertices := []
	if len(vertex_pairs) > 0:
		ordered_vertices.append(vertex_pairs[0].start)
		ordered_vertices.append(vertex_pairs[0].end)
		vertex_pairs.pop_front()
		
		while len(vertex_pairs) > 0:
			var last_vertex: Vector2 = ordered_vertices[len(ordered_vertices) - 1]
			var foundNext := false
			
			for i in range(len(vertex_pairs)):
				var pair: Dictionary = vertex_pairs[i]
				
				# If last_vertex connects to start of pair
				if (approx_equal(last_vertex.x, pair.start.x) && approx_equal(last_vertex.y, pair.start.y)):
					ordered_vertices.append(pair.end)
					vertex_pairs.pop_at(i)
					foundNext = true
					break
				# If last_vertex connects to end of pair
				elif (approx_equal(last_vertex.x, pair.end.x) && approx_equal(last_vertex.y, pair.end.y)):
					ordered_vertices.append(pair.start)
					vertex_pairs.pop_at(i)
					foundNext = true
					break
			
			if not foundNext:
				break
	return ordered_vertices.slice(0,-1)


func is_convex() -> bool:
	var ordered_vertices := get_vertices()
	 # Get the number of vertices
	var n: int = len(ordered_vertices)
	
	# If there are less than 3 vertices, we cannot form a polygon
	if n < 3:
		return false
	
	
	var orientation: float = cross_sign(ordered_vertices[0], ordered_vertices[1], ordered_vertices[2])
	
	for i in range(1, n):
		# For each triplet of consecutive points
		var p1: Vector2 = ordered_vertices[i % n]
		var p2: Vector2 = ordered_vertices[(i + 1) % n]
		var p3: Vector2 = ordered_vertices[(i + 2) % n]
		
		var new_orientation: float = cross_sign(p1, p2, p3)
		# If orientation changes, the polygon is concave
		if sign(orientation) * sign(new_orientation) < 0:
			return false
		
		if orientation == 0.0:
			orientation = new_orientation
	
	return true


# Check if two points are approximately equal
func approx_equal(a: float, b: float, epsilon: float = 0.001) -> bool:
	return abs(a - b) < epsilon


func cross_sign(p1: Vector2, p2: Vector2, p3: Vector2) -> float:
	# Calculate cross product component
	return (p2.x - p1.x) * (p3.y - p1.y) - (p2.y - p1.y) * (p3.x - p1.x)


func create_mesh(p_vertices: Array, texture: int, das: Dictionary, y_pos: int, is_ceiling: bool, texture_shift_x: int, texture_shift_y: int, is_platform: bool) -> SectorMesh3D:
	var mapping: Dictionary = das.mapping
	
	var static_body := StaticBody3D.new()
	var collision_shape := CollisionShape3D.new()
	var convex_polygon_shape := ConvexPolygonShape3D.new()
	
	var mesh_instance := SectorMesh3D.new()
	var mesh_tool := SurfaceTool.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	
	var image := Image.new()
	if texture in mapping and "image" in mapping[texture]:
		if mapping[texture].is_sky:
			material.albedo_color = Color.TRANSPARENT
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		
		if is_platform:
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		
		image.copy_from(mapping[texture].image)
		if mapping[texture].flipped:
			image.rotate_90(COUNTERCLOCKWISE)
			image.flip_y()
		
		
		if not is_ceiling:
			if check_flag(data.unk0x16, FLOOR_FLIP_X):
				image.flip_x()
			if check_flag(data.unk0x16, FLOOR_FLIP_Y):
				image.flip_y()
		if is_ceiling:
			if check_flag(data.unk0x16, CEILING_FLIP_X):
				image.flip_x()
			if check_flag(data.unk0x16, CEILING_FLIP_Y):
				image.flip_y()
		
		var img_texture := ImageTexture.create_from_image(image)
		material.albedo_texture = img_texture
	else:
		if texture >= 65280:
			var color: Array = das.palette[texture - 65280]
			material.albedo_color = Color(color[0] / 256.0, color[1] / 256.0, color[2] / 256.0)
		else:
			Console.print("Sector has invalid texture index: %s, texture: %s" % [index, texture])
			material.albedo_color = Color.BLUE
	
	mesh_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var verts := Geometry2D.triangulate_polygon(p_vertices)
	if not verts:
		# Hack around strange failure on some small sectors
		if len(p_vertices) == 5:
			verts = [0,1,2,0,2,3]
		else:
			Console.print("Sector couldn't triangulate polygon: %s, vertices: %s, verts: %s" % [index, p_vertices, verts])
			static_body.queue_free()
			collision_shape.queue_free()
	
	
	if is_ceiling:
		verts.reverse()
	var collision_points := []
	
	var min_x: int = 10000
	var min_y: int = 10000
	var max_x: int = -10000
	var max_y: int = -10000
	
	
	for v_in in verts:
		var v: Vector2 = p_vertices[v_in]
		min_x = min(min_x, v.x)
		min_y = min(min_y, v.y)
		max_x = max(max_x, v.x)
		max_y = max(max_y, v.y)
	
	
	for v_in in verts:
		var v: Vector2 = p_vertices[v_in]
		var u: float = float(v.x - min_x) / (max_x - min_x)
		var vv: float = float(v.y - min_y) / (max_y - min_y)
		mesh_tool.set_uv(Vector2(u,vv))
		mesh_tool.add_vertex(Vector3(v.x/100.0, y_pos/100.0, v.y/100.0))
		collision_points.append(Vector3(v.x/100.0, y_pos/100.0, v.y/100.0))

	var mesh: ArrayMesh = mesh_tool.commit()
	
	
	if texture in mapping:
		var mesh_length: int = max_x - min_x
		var mesh_height: int = max_y - min_y
		
		var texture_width: float = mapping[texture].width
		var texture_height: float = mapping[texture].height
		
		if mapping[texture].flipped:
			texture_width = mapping[texture].height
			texture_height = mapping[texture].width
		
		if texture_width == 256:
			texture_width /= 2
			texture_height /= 2
		
		
		
		var floor_a: int = 0
		var floor_b: int = 0
		
		if not is_platform:
			if is_ceiling:
				if check_flag(data.textureFit, CEILING_A):
					floor_a = 1
				if check_flag(data.textureFit, CEILING_B):
					floor_b = 1
			else:
				if check_flag(data.textureFit, FLOOR_A):
					floor_a = 1
				if check_flag(data.textureFit, FLOOR_B):
					floor_b = 1
		else:
			if is_ceiling:
				if check_flag(platform.floorTextureScale, CEILING_A):
					floor_a = 1
				if check_flag(platform.floorTextureScale, CEILING_B):
					floor_b = 1
			else:
				if check_flag(platform.floorTextureScale, FLOOR_A):
					floor_a = 1
				if check_flag(platform.floorTextureScale, FLOOR_B):
					floor_b = 1
		
		
		if floor_a == 0 and floor_b == 0:
			#Console.print("TYPE 1:2")
			texture_width *= 0.5
			texture_height *= 0.5
			
			material.uv1_scale.x = float(mesh_length) / (texture_width * 2)
			material.uv1_scale.y = float(mesh_height) / (texture_height * 2)
			
			var x_shift: float = texture_shift_x * 0.5
			var y_shift: float = texture_shift_y * 0.5
			var grid_x_shift: int = min_x % 1024
			material.uv1_offset.x = (float(grid_x_shift + x_shift) / (texture_width * 2))
			var grid_y_shift: int = min_y % 1024
			material.uv1_offset.y = (float(grid_y_shift - y_shift) / (texture_height * 2))
			
		if floor_a == 1 and floor_b == 0:
			#Console.print("TYPE 1:1")
			material.uv1_scale.x = float(mesh_length) / (texture_width * 2)
			material.uv1_scale.y = float(mesh_height) / (texture_height * 2)
			
			var x_shift: int = texture_shift_x 
			var y_shift: int = texture_shift_y
			var grid_x_shift: int = min_x % 1024
			material.uv1_offset.x = float(grid_x_shift + x_shift)/ (texture_width * 2)
			var grid_y_shift: int = min_y % 1024
			material.uv1_offset.y = float(grid_y_shift - y_shift)/ (texture_height * 2)
			
		if floor_a == 0 and floor_b == 1:
			#Console.print("TYPE 2:1")
			texture_width *= 2
			texture_height *= 2
			
			material.uv1_scale.x = float(mesh_length) / (texture_width * 2)
			material.uv1_scale.y = float(mesh_height) / (texture_height * 2)
			
			var x_shift: int = texture_shift_x * 2
			var y_shift: int = texture_shift_y * 2
			var grid_x_shift: int = min_x % 1024
			material.uv1_offset.x = (float(grid_x_shift + x_shift) / (texture_width * 2))
			var grid_y_shift: int = min_y % 1024
			material.uv1_offset.y = (float(grid_y_shift - y_shift) / (texture_height * 2))
		
		
		if floor_a == 1 and floor_b == 1:
			#Console.print("TYPE 4:1")
			texture_width *= 4
			texture_height *= 4
			
			material.uv1_scale.x = float(mesh_length) / (texture_width * 2)
			material.uv1_scale.y = float(mesh_height) / (texture_height * 2)
			
			var x_shift: int = texture_shift_x * 4
			var y_shift: int = texture_shift_y * 4
			var grid_x_shift: int = min_x % 1024
			material.uv1_offset.x = (float(grid_x_shift + x_shift) / (texture_width * 2))
			var grid_y_shift: int = min_y % 1024
			material.uv1_offset.y = (float(grid_y_shift - y_shift) / (texture_height * 2))
	
	if not collision_points.is_empty():
		convex_polygon_shape.points = collision_points
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
	
	node = Sector3D.new()
	node.ref = self
	await _initialize_meshes()
	return node

func _initialize_meshes() -> void:
	var das: Dictionary = await Roth.get_das(map_info.das)
	assert(not das.is_empty())
	
	# Flooring
	var mesh_instance: SectorMesh3D = create_mesh(vertices, data.floorTextureIndex, das, data.floorHeight, false, data.floorTextureShiftX, data.floorTextureShiftY, false)
	mesh_instance.ref = self
	node.add_child(mesh_instance)
	
	# Ceiling
	mesh_instance = create_mesh(vertices, data.ceilingTextureIndex, das, data.ceilingHeight, true, data.ceilingTextureShiftX, data.ceilingTextureShiftY, false)
	mesh_instance.ref = self
	node.add_child(mesh_instance)
	
	# Platform
	if platform:
		# Platform Flooring
		mesh_instance = create_mesh(vertices, platform.floorTextureIndex, das, platform.floorHeight, false, platform.floorTextureShiftX, platform.floorTextureShiftY, true)
		mesh_instance.ref = self
		node.add_child(mesh_instance)
		
		# Platform Ceiling
		mesh_instance = create_mesh(vertices, platform.ceilingTextureIndex, das, platform.ceilingHeight, true, platform.ceilingTextureShiftX, platform.ceilingTextureShiftY, true)
		mesh_instance.ref = self
		node.add_child(mesh_instance)


class Sector3D extends Node3D:
	var ref: Sector
class SectorMesh3D extends MeshInstance3D:
	var ref: Sector
