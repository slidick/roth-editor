extends RefCounted
class_name ObjectRoth

enum Direction {
	FRONT,
	FRONT_RIGHT,
	RIGHT,
	BACK_RIGHT,
	BACK,
	BACK_LEFT,
	LEFT,
	FRONT_LEFT
}

var data: Dictionary = {}
var index: int :
	get():
		return map.objects.find(self)
var map: Map
#var sectors: Array = []
var node: ObjectNode3D
var node_2d: ObjectNode2D
var sector: WeakRef
var directional_object: bool = false
var direction := Direction.FRONT


static func new_from_copied_object(p_object: ObjectRoth, p_position: Vector2) -> ObjectRoth:
	var new_sector_index: int = -1
	var floor_height: int = 0
	for f_sector: Sector in p_object.map.sectors:
		if Geometry2D.is_point_in_polygon(p_position, f_sector.vertices.slice(0,-1)):
			new_sector_index = f_sector.index
			floor_height = f_sector.data.floorHeight
	
	if new_sector_index == -1:
		Console.print("Can't paste object outside a sector")
		return
	
	var object := ObjectRoth.new(p_object.data.duplicate(true), p_object.map)
	object.data.posX = -p_position.x
	object.data.posY = p_position.y
	object.data.posZ = floor_height
	object.map.sectors[new_sector_index].data.objectInformation.append(object.data)
	object.sector = weakref(object.map.sectors[new_sector_index])
	
	return object


static func new_from_copied_object_3d(p_map: Map, p_object: ObjectRoth, p_position: Vector3, extra_info: Dictionary) -> ObjectRoth:
	var new_sector_index: int = -1
	for f_sector: Sector in p_map.sectors:
		if Geometry2D.is_point_in_polygon(Vector2(p_position.x, p_position.z), f_sector.vertices.slice(0,-1)):
			new_sector_index = f_sector.index
	
	if new_sector_index == -1:
		Console.print("Can't paste object outside a sector")
		return
	
	var object := ObjectRoth.new(p_object.data.duplicate(true), p_map)
	object.data.posX = -p_position.x
	object.data.posY = p_position.z
	object.data.posZ = p_position.y
	object.map.sectors[new_sector_index].data.objectInformation.append(object.data)
	object.sector = weakref(object.map.sectors[new_sector_index])
	
	if extra_info["render_type"] == "fixed":
		object.data.renderType |= 128
	elif extra_info["render_type"] == "billboard":
		object.data.renderType &= 0
	object.data.rotation = extra_info.rotation
	
	return object


static func new_object(p_map: Map, p_position: Vector2) -> ObjectRoth:
	var new_sector_index: int = -1
	var floor_height: int = 0
	for f_sector: Sector in p_map.sectors:
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
		"textureSource": 0,
		"rotation": 0,
		"flags": 0,
		"lighting": 128,
		"renderType": 0,
		"posZ": floor_height,
		"unk0x0C": 0,
		"objectID": 0,
	}
	
	var object := ObjectRoth.new(default_data, p_map)
	object.data.posX = -p_position.x
	object.data.posY = p_position.y
	object.map.sectors[new_sector_index].data.objectInformation.append(object.data)
	object.sector = weakref(object.map.sectors[new_sector_index])
	
	return object


static func new_object_3d(p_map: Map, p_position: Vector3, extra_info: Dictionary) -> ObjectRoth:
	var new_sector_index: int = -1
	var floor_height: int = 0
	for f_sector: Sector in p_map.sectors:
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
		"textureSource": 0,
		"rotation": 0,
		"flags": 0,
		"lighting": 128,
		"renderType": 0,
		"posZ": floor_height,
		"unk0x0C": 0,
		"objectID": 0,
	}
	
	var object := ObjectRoth.new(default_data, p_map)
	object.data.posX = -p_position.x
	object.data.posY = p_position.z
	object.data.posZ = p_position.y
	object.map.sectors[new_sector_index].data.objectInformation.append(object.data)
	object.sector = weakref(object.map.sectors[new_sector_index])
	
	if extra_info["render_type"] == "fixed":
		object.data.renderType = 128
	object.data.rotation = extra_info.rotation
	
	return object


func _init(p_data: Dictionary, p_map: Map, p_sector: Sector = null) -> void:
	data = p_data
	map = p_map
	#sectors = p_sectors
	if p_sector:
		sector = weakref(p_sector)
	if "renderType" not in data:
		data["renderType"] = 0


func duplicate() -> ObjectRoth:
	return ObjectRoth.new(data.duplicate(true), map)


func initialize_mesh() -> Node3D:
	if node:
		for child: Node in node.get_children():
			child.queue_free()
		if sector.get_ref().hidden:
			return
		_initialize_mesh()
		return
	
	node = ObjectNode3D.new()
	node.ref = self
	_initialize_mesh()
	return node


func _initialize_mesh_invalid() -> void:
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


func _initialize_mesh() -> void:
	var object_das: Dictionary = {}
	var object_index: int
	if data.textureSource == 0:
		object_das = map.map_info.das_info
		object_index = data.textureIndex + 4096
	elif data.textureSource == 1:
		object_das = map.map_info.das_info
		object_index = data.textureIndex + 4096 + 256
	elif not "normality" in map.map_info and data.textureSource == 2:
		object_das = map.map_info.map_pack.das2_info
		object_index = data.textureIndex
	elif not "normality" in map.map_info and data.textureSource == 3:
		object_das = map.map_info.map_pack.das2_info
		object_index = data.textureIndex + 256
	else:
		_initialize_mesh_invalid()
		return
	
	var texture := Das.get_index_from_das(object_index, object_das)
	if texture.name == "Invalid":
		_initialize_mesh_invalid()
		return
	elif "object_data" in texture:
		_initialize_3d_object(texture)
		return
	_initialize_mesh_texture(texture)


func _initialize_mesh_texture(texture: Dictionary) -> void:
	var width: float = texture.height / Roth.SCALE_3D_WORLD
	var height: float = texture.width / Roth.SCALE_3D_WORLD
	var modifier: int = texture.modifier
	
	var mesh_instance := ObjectMesh3D.new()
	mesh_instance.position = Vector3(
			-data.posX / Roth.SCALE_3D_WORLD,
			data.posZ / Roth.SCALE_3D_WORLD,
			data.posY / Roth.SCALE_3D_WORLD,
	)
	
	var material := StandardMaterial3D.new()
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if data.renderType & (1<<7) > 0:
		pass
	else:
		material.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	
	if texture.image_type & Das.IMAGE_TYPE.TRANSPARENT > 0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	else:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.grow = true
	material.grow_amount = 0.001
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	if "image" in texture and "image_pack" not in texture:
		if texture.flags_1 & (1<<3):
			var i_width: int = texture.image.get_width() + (abs(texture.shift_data[1]) / 2.0) 
			var i_height: int = texture.image.get_height() + abs(texture.shift_data[0])
			var shifted_image := Image.create_empty(i_width, i_height, false, texture.image.get_format())
			shifted_image.blit_rect(texture.image.get_image(), Rect2i(Vector2.ZERO, texture.image.get_size()), Vector2(0 if texture.shift_data[1] < 0 else (texture.shift_data[1] / 2.0), 0 if texture.shift_data[0] < 0 else texture.shift_data[0]))
			material.albedo_texture = ImageTexture.create_from_image(shifted_image)
			if texture.shift_data[1] > 0:
				mesh_instance.position.y -= (texture.shift_data[1]/2) / Roth.SCALE_3D_WORLD
		else:
			material.albedo_texture = texture.image
	elif "animation" in texture:
		material.albedo_texture = texture.animation[0]
	elif "monster" in texture:
		directional_object = true
		var player_rotation: float = node.get_viewport().get_camera_3d().global_rotation_degrees.y + 180 if node.get_viewport() else 0.0
		if player_rotation > 180:
			player_rotation -= 360
		var object_rotation: float = (data.rotation/256.0) * 360
		if object_rotation > 180:
			object_rotation -= 360
		object_rotation *= -1
		var diff: float = player_rotation - object_rotation
		direction = get_direction(diff)
		var texture_index: int = -1
		match direction:
			Direction.FRONT:
				texture_index = texture.monster.walking_front
			Direction.FRONT_RIGHT:
				texture_index = texture.monster.walking_front_right
			Direction.RIGHT:
				texture_index = texture.monster.walking_right
			Direction.BACK_RIGHT:
				texture_index = texture.monster.walking_back_right
			Direction.BACK:
				texture_index = texture.monster.walking_back
			Direction.BACK_LEFT:
				texture_index = texture.monster.walking_back_left
			Direction.LEFT:
				texture_index = texture.monster.walking_left
			Direction.FRONT_LEFT:
				texture_index = texture.monster.walking_front_left
		if texture_index > -1 and texture_index & 0x8000:
			texture_index &= 0x7FFF
			material.uv1_scale.y *= -1
		if texture_index > 4608:
			texture_index -= 4608
		if texture_index > -1:
			var monster_texture: Dictionary = Das.get_index_from_das(texture_index, texture.das_info)
			if monster_texture.name == "Invalid":
				_initialize_mesh_invalid()
				return
			if monster_texture.flags_1 & (1<<3):
				var i_width: int = monster_texture.image.get_width() + (abs(monster_texture.shift_data[1]) / 2.0) 
				var i_height: int = monster_texture.image.get_height() + abs(monster_texture.shift_data[0])
				var shifted_image := Image.create_empty(i_width, i_height, false, monster_texture.image.get_format())
				shifted_image.blit_rect(monster_texture.image.get_image(), Rect2i(Vector2.ZERO, monster_texture.image.get_size()), Vector2(0 if monster_texture.shift_data[1] < 0 else (monster_texture.shift_data[1] / 2.0), 0 if monster_texture.shift_data[0] < 0 else monster_texture.shift_data[0]))
				material.albedo_texture = ImageTexture.create_from_image(shifted_image)
				if monster_texture.shift_data[1] > 0:
					mesh_instance.position.y -= (monster_texture.shift_data[1]/2) / Roth.SCALE_3D_WORLD
			else:
				material.albedo_texture = monster_texture.image
			width = monster_texture.height / Roth.SCALE_3D_WORLD
			height = monster_texture.width / Roth.SCALE_3D_WORLD
			modifier = monster_texture.modifier
		else:
			_initialize_mesh_invalid()
	elif "directional" in texture:
		directional_object = true
		var player_rotation: float = node.get_viewport().get_camera_3d().global_rotation_degrees.y + 180 if node.get_viewport() else 0.0
		if player_rotation > 180:
			player_rotation -= 360
		var object_rotation: float = (data.rotation/256.0) * 360
		if object_rotation > 180:
			object_rotation -= 360
		object_rotation *= -1
		var diff: float = player_rotation - object_rotation
		direction = get_direction(diff)
		var texture_index: int = -1
		match direction:
			Direction.FRONT:
				texture_index = texture.directional.dir_5_fat_idx
			Direction.FRONT_RIGHT:
				texture_index = texture.directional.dir_4_fat_idx
			Direction.RIGHT:
				texture_index = texture.directional.dir_3_fat_idx
			Direction.BACK_RIGHT:
				texture_index = texture.directional.dir_2_fat_idx
			Direction.BACK:
				texture_index = texture.directional.dir_1_fat_idx
			Direction.BACK_LEFT:
				texture_index = texture.directional.dir_8_fat_idx
			Direction.LEFT:
				texture_index = texture.directional.dir_7_fat_idx
			Direction.FRONT_LEFT:
				texture_index = texture.directional.dir_6_fat_idx
		if texture_index > -1 and texture_index & 0x8000:
			texture_index &= 0x7FFF
			material.uv1_scale.y *= -1
		if texture_index > 4608:
			texture_index -= 4608
		if texture_index > -1:
			var directional_texture: Dictionary = Das.get_index_from_das(texture_index, texture.das_info)
			if directional_texture.name == "Invalid":
				_initialize_mesh_invalid()
				return
			if directional_texture.flags_1 & (1<<3):
				var i_width: int = directional_texture.image.get_width() + (abs(directional_texture.shift_data[1]) / 2.0)
				var i_height: int = directional_texture.image.get_height() + (abs(directional_texture.shift_data[0]))
				var shifted_image := Image.create_empty(i_width, i_height, false, directional_texture.image.get_format())
				shifted_image.blit_rect(directional_texture.image.get_image(), Rect2i(Vector2.ZERO, directional_texture.image.get_size()), Vector2(0 if directional_texture.shift_data[1] < 0 else (directional_texture.shift_data[1] / 2.0), 0 if directional_texture.shift_data[0] < 0 else directional_texture.shift_data[0]))
				if directional_texture.shift_data[1] > 0:
					mesh_instance.position.y -= (directional_texture.shift_data[1]/2) / Roth.SCALE_3D_WORLD
				material.albedo_texture = ImageTexture.create_from_image(shifted_image)
			else:
				material.albedo_texture = directional_texture.image
			width = directional_texture.height / Roth.SCALE_3D_WORLD
			height = directional_texture.width / Roth.SCALE_3D_WORLD
			modifier = directional_texture.modifier
		else:
			_initialize_mesh_invalid()
	elif "image_pack" in texture:
		directional_object = true
		var player_rotation: float = node.get_viewport().get_camera_3d().global_rotation_degrees.y + 180 if node.get_viewport() else 0.0
		if player_rotation > 180:
			player_rotation -= 360
		var object_rotation: float = (data.rotation/256.0) * 360
		if object_rotation > 180:
			object_rotation -= 360
		object_rotation *= -1
		var diff: float = player_rotation - object_rotation
		direction = get_direction(diff)
		var texture_data: Dictionary = {}
		match direction:
			Direction.FRONT:
				texture_data = texture.image_pack[texture.offsets_index[4]]
				if texture.offsets_flipped[4]:
					material.uv1_scale.y *= -1
			Direction.FRONT_RIGHT:
				texture_data = texture.image_pack[texture.offsets_index[3]]
				if texture.offsets_flipped[3]:
					material.uv1_scale.y *= -1
			Direction.RIGHT:
				texture_data = texture.image_pack[texture.offsets_index[2]]
				if texture.offsets_flipped[2]:
					material.uv1_scale.y *= -1
			Direction.BACK_RIGHT:
				texture_data = texture.image_pack[texture.offsets_index[1]]
				if texture.offsets_flipped[1]:
					material.uv1_scale.y *= -1
			Direction.BACK:
				texture_data = texture.image_pack[texture.offsets_index[0]]
				if texture.offsets_flipped[0]:
					material.uv1_scale.y *= -1
			Direction.BACK_LEFT:
				texture_data = texture.image_pack[texture.offsets_index[7]]
				if texture.offsets_flipped[7]:
					material.uv1_scale.y *= -1
			Direction.LEFT:
				texture_data = texture.image_pack[texture.offsets_index[6]]
				if texture.offsets_flipped[6]:
					material.uv1_scale.y *= -1
			Direction.FRONT_LEFT:
				texture_data = texture.image_pack[texture.offsets_index[5]]
				if texture.offsets_flipped[5]:
					material.uv1_scale.y *= -1
		if texture_data.is_empty():
			_initialize_mesh_invalid()
		else:
			material.albedo_texture = texture_data.image
			width = texture_data.height / Roth.SCALE_3D_WORLD
			height = texture_data.width / Roth.SCALE_3D_WORLD
			modifier = texture_data.modifier
	else:
		_initialize_mesh_invalid()
		return
	
	if data.lighting == 128:
		if Settings.settings.get("options", {}).get("shaded_lighting", true) and sector.get_ref().data.lighting > 0:
			if sector.get_ref().data.textureFit & sector.get_ref().CANDLE > 0:
				material.albedo_color.r8 /= 2
				material.albedo_color.g8 /= 2
				material.albedo_color.b8 /= 2
			var lighting_change: int = (sector.get_ref().data.lighting - 128) * 4
			material.albedo_color.r8 = clampi(material.albedo_color.r8 + lighting_change, 0, 255)
			material.albedo_color.g8 = clampi(material.albedo_color.g8 + lighting_change, 0, 255)
			material.albedo_color.b8 = clampi(material.albedo_color.b8 + lighting_change, 0, 255)
	
	
	#print(texture)
	if (modifier & (1<<7)) > 0:
		width /= 2
		height /= 2
	
	var low_y: float = 0
	var high_y: float = height * 2
	if (texture.flags_1 & (1<<3) > 0):
		pass
		#low_y -= height
		#high_y -= height
	
	if (texture.modifier & (1<<4) > 0):
		low_y -= (height * 2)
		high_y -= (height * 2)
	
	
	
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
	
	if (data.flags & (1<<4)) > 0:
		mdt.set_vertex_uv(0, Vector2(1,0))
		mdt.set_vertex_uv(1, Vector2(1,1))
		mdt.set_vertex_uv(2, Vector2(0,0))
		mdt.set_vertex_uv(3, Vector2(0,1))
	
	
	mesh_array.clear_surfaces()
	mdt.commit_to_surface(mesh_array)
	
	
	mesh_instance.mesh = mesh_array
	mesh_instance.material_override = material
	mesh_instance.ref = self
	node.add_child(mesh_instance)
	
	var shape := BoxShape3D.new()
	shape.size.z = 0.005
	shape.size.x = width * 2
	shape.size.y = height * 2
	
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = height
	
	#if (texture.flags_1 & (1<<3) > 0):
		#collision.position.y = 0
	if (texture.modifier & (1<<4) > 0):
		collision.position.y = -height
	
	var static_body := StaticBodyObject3D.new(not data.renderType & (1<<7) > 0)
	static_body.add_child(collision)
	mesh_instance.add_child(static_body)
	
	if data.renderType & (1<<7) > 0:
		var angle_degrees: float = ((float(data.rotation) / 256) * 360) - 180
		mesh_instance.rotation_degrees.y -= angle_degrees


func _initialize_3d_object(texture: Dictionary) -> void:
	for object_face: Dictionary in texture.object_data.faces:
		var vertices := []
		for edge: int in object_face.edge_array:
			var vertex: Vector3 = texture.object_data.vertices[edge>>4]
			vertex.x *= -1
			vertices.append(vertex)
		
		var verts := []
		if len(vertices) == 5:
			verts = [0,1,2,0,2,3]
		elif len(vertices) == 4:
			verts = [0,1,2]
		
		
		var collision_points := []
		var mesh_tool := SurfaceTool.new()
		mesh_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		var uvs: Array = []
		if len(vertices) == 5:
			uvs = [Vector2(0,0), Vector2(0,1), Vector2(1,1), Vector2(0,0), Vector2(1,1), Vector2(1,0)]
		elif len(vertices) == 4:
			uvs = [Vector2(0,0), Vector2(0,1), Vector2(1,1)]
		for i: int in range(len(verts)):
			var v: Vector3 = vertices[verts[i]]
			mesh_tool.set_uv(uvs[i])
			mesh_tool.add_vertex(v / Roth.SCALE_3D_WORLD)
			collision_points.append(v / Roth.SCALE_3D_WORLD)
		
		
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		if object_face.render_flag_1 & (1<<1) > 0:
			material.uv1_scale.y *= -1
			material.uv1_offset.y *= -1
		
		var fat_index: int = object_face.texture_fat_index_base
		if len(vertices) == 0:
			fat_index += 0x1000
		
		if fat_index in map.das.mapping:
			var texture_data: Dictionary = map.das.mapping[fat_index]
			var texture_image: ImageTexture
			if "image_pack" in texture_data:
				texture_image = texture_data.image_pack[object_face.sub_texture_index].image
			else:
				texture_image = texture_data.image
			material.albedo_texture = texture_image
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			if texture_data.image_type & Das.IMAGE_TYPE.TRANSPARENT > 0:
				material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			elif texture_data.image_type & Das.IMAGE_TYPE.PALETTE_ZERO_OPAQUE == 0:
				material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		else:
			if fat_index >= 65280:
				var color: Array = map.das.palette[fat_index - 65280]
				material.albedo_color = Color(color[0] / 256.0, color[1] / 256.0, color[2] / 256.0)
			else:
				material.albedo_color = Color.REBECCA_PURPLE
		
		if data.lighting == 128:
			if Settings.settings.get("options", {}).get("shaded_lighting", true) and sector.get_ref().data.lighting > 0:
				if sector.get_ref().data.textureFit & sector.get_ref().CANDLE > 0:
					material.albedo_color.r8 /= 2
					material.albedo_color.g8 /= 2
					material.albedo_color.b8 /= 2
				var lighting_change: int = (sector.get_ref().data.lighting - 128) * 4
				material.albedo_color.r8 = clampi(material.albedo_color.r8 + lighting_change, 0, 255)
				material.albedo_color.g8 = clampi(material.albedo_color.g8 + lighting_change, 0, 255)
				material.albedo_color.b8 = clampi(material.albedo_color.b8 + lighting_change, 0, 255)
		
		mesh_tool.generate_normals()
		mesh_tool.index()
		var mesh_instance := ObjectMesh3D.new()
		mesh_instance.ref = self
		mesh_instance.mesh = mesh_tool.commit()
		mesh_instance.material_override = material
		mesh_instance.position = Vector3(
			-data.posX / Roth.SCALE_3D_WORLD,
			data.posZ / Roth.SCALE_3D_WORLD,
			data.posY / Roth.SCALE_3D_WORLD,
		)
		var angle_degrees: float = ((float(data.rotation) / 256) * 360)
		mesh_instance.rotation_degrees.y -= angle_degrees
		node.add_child(mesh_instance)
		
		if not Utility.are_points_collinear(collision_points):
			var static_body := StaticBody3D.new()
			var collision_shape := CollisionShape3D.new()
			var convex_polygon_shape := ConvexPolygonShape3D.new()
			convex_polygon_shape.points = collision_points
			collision_shape.shape = convex_polygon_shape
			static_body.add_child(collision_shape)
			mesh_instance.add_child(static_body)


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
	map.objects.erase(self)


func get_direction(diff: float) -> Direction:
	if diff > 180:
		diff -= 360
	if diff < -180:
		diff += 360
	if diff > -22.5 and diff < 22.5:
		return Direction.FRONT
	if diff >= -67.5 and diff <= -22.5:
		return Direction.FRONT_RIGHT
	if diff > -112.5 and diff < -67.5:
		return Direction.RIGHT
	if diff >= -157.5 and diff <= -112.5:
		return Direction.BACK_RIGHT
	if diff < -157.5 or diff > 157.5:
		return Direction.BACK
	if diff >= 22.5 and diff <= 67.5:
		return Direction.FRONT_LEFT
	if diff > 67.5 and diff < 112.5:
		return Direction.LEFT
	if diff >= 112.5 and diff <= 157.5:
		return Direction.BACK_LEFT
	return direction


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
		var angle_degrees: float = Utility.object_rotation_to_degrees(roth_rotation)
		draw_line(Vector2.ZERO, Vector2(cos(deg_to_rad(angle_degrees)), sin(deg_to_rad(angle_degrees))) * 2.0, color, 0.2)


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
	
	func redraw() -> void:
		position = Vector2(
			-ref.data.posX / Roth.SCALE_2D_WORLD,
			ref.data.posY / Roth.SCALE_2D_WORLD
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
		
		var current_sector_index: int = ref.sector.get_ref().index
		var closest_sector_index: int = -1
		var new_sector_index: int = -1
		var closest_distance: float = INF
		for sector: Sector in ref.map.sectors:
			for face_ref: WeakRef in sector.faces:
				var face: Face = face_ref.get_ref()
				var distance: float = Utility.distance_to_face(pos, face)
				if distance < closest_distance:
					closest_distance = distance
					closest_sector_index = sector.index
			
			if Geometry2D.is_point_in_polygon(pos, sector.vertices.slice(0,-1)):
				new_sector_index = sector.index
		
		if new_sector_index == -1:
			new_sector_index = closest_sector_index
		
		if new_sector_index == -1:
			position = Vector2(
				-ref.data.posX / Roth.SCALE_2D_WORLD,
				ref.data.posY / Roth.SCALE_2D_WORLD
			)
			return
		
		ref.data.posX = -int(pos.x)
		ref.data.posY = int(pos.y)
		
		
		
		if current_sector_index != new_sector_index:
			ref.map.sectors[current_sector_index].data.objectInformation.erase(ref.data)
			ref.map.sectors[new_sector_index].data.objectInformation.append(ref.data)
			ref.sector = weakref(ref.map.sectors[new_sector_index])
		
		ref.initialize_mesh()


class ObjectNode3D extends Node3D:
	var ref: ObjectRoth
	var _highlighted: bool = false
	var _selected: bool = false
	func highlight() -> void:
		if not _selected:
			_highlighted = true
			for child: MeshInstance3D in get_children():
				if not ((ref.data.renderType & (1<<7)) > 0) and not (ref.data.flags & (1 << 0)) > 0:
					child.material_overlay = Roth.highlight_fixed_y_material
				else:
					child.material_overlay = Roth.highlight_material
	func unhighlight() -> void:
		if _highlighted and not _selected:
			_highlighted = false
			for child: MeshInstance3D in get_children():
				child.material_overlay = null
	func select() -> void:
		_selected = true
		for child: MeshInstance3D in get_children():
			if not ((ref.data.renderType & (1<<7)) > 0) and not (ref.data.flags & (1 << 0)) > 0:
				child.material_overlay = Roth.selected_fixed_y_material
			else:
				child.material_overlay = Roth.selected_material
	func deselect() -> void:
		_selected = false
		for child: MeshInstance3D in get_children():
			child.material_overlay = null


class ObjectMesh3D extends MeshInstance3D:
	var ref: ObjectRoth
	func _process(_delta: float) -> void:
		if ref.directional_object:
			var player_rotation: float = get_viewport().get_camera_3d().global_rotation_degrees.y + 180
			if player_rotation > 180:
				player_rotation -= 360
			var object_rotation: float = (ref.data.rotation/256.0) * 360
			if object_rotation > 180:
				object_rotation -= 360
			object_rotation *= -1
			var diff: float = player_rotation - object_rotation
			if ref.direction != ref.get_direction(diff):
				ref.initialize_mesh()
				if ref in ref.map.node.owner.selected_objects:
					ref.map.node.owner.redraw(ref.map.node.owner.selected_objects)


class StaticBodyObject3D extends StaticBody3D:
	var follow: bool = false
	func _init(p_follow: bool) -> void:
		follow = p_follow
	func _process(_delta: float) -> void:
		if follow:
			rotation.y = get_viewport().get_camera_3d().global_rotation.y + PI
			rotation.x = 0
