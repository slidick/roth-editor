extends Object
class_name Utility

const CONVERT_SHADER_FILE: RDShaderFile = preload("uid://ctypdd4htadqj")
const CONVERT_SHADER_FILE_WITH_ALPHA: RDShaderFile = preload("uid://cbrjcrstq4vkq")
const CONVERT_SHADER_FILE_WITH_FULL_ALPHA: RDShaderFile = preload("uid://dewa4njpsve7v")
static var rd: RenderingDevice

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


static func are_points_collinear_2d(points_list: Array, epsilon: float = 0.0001) -> bool:
	if len(points_list) < 3:
		return true
	
	var base: Vector2 = points_list[0]
	var dir := Vector2.ZERO
	
	for i in range(1, len(points_list)):
		dir = points_list[i] - base
		if dir.length() > epsilon:
			break
	
	if dir == Vector2.ZERO:
		return true
	
	for i in range(1, len(points_list)):
		var v: Vector2 = (points_list[i] - base)
		if abs(dir.cross(v)) > epsilon:
			return false
	
	return true


static func distance_to_face(position: Vector2, face: Face) -> float:
	var x1: float = face.v1.x
	var y1: float = face.v1.y
	var x2: float = face.v2.x
	var y2: float = face.v2.y

	# Vector from line segment start to end
	var line_vec_x: float = x2 - x1
	var line_vec_y: float = y2 - y1
	var line_length: float = sqrt(line_vec_x * line_vec_x + line_vec_y * line_vec_y)

	# If the line segment has zero length, return distance to either endpoint
	if (line_length == 0):
		return sqrt((position.x - x1) * (position.x - x1) + (position.y - y1) * (position.y - y1))

	# Calculate projection of position point onto the line
	var t: float = max(0, min(1, ((position.x - x1) * line_vec_x + (position.y - y1) * line_vec_y) / (line_length * line_length)));

	# Find the nearest point on the line segment
	var nearest_x: float = x1 + t * line_vec_x;
	var nearest_y: float = y1 + t * line_vec_y;

	# Return distance to the nearest point
	return sqrt((position.x - nearest_x) * (position.x - nearest_x) + (position.y - nearest_y) * (position.y - nearest_y));


static func remove_dir_recursive(directory: String) -> void:
	if DirAccess.dir_exists_absolute(directory):
		for dir in DirAccess.get_directories_at(directory):
			remove_dir_recursive(directory.path_join(dir))
		for file in DirAccess.get_files_at(directory):
			DirAccess.remove_absolute(directory.path_join(file))
		DirAccess.remove_absolute(directory)


static func init_delta_table() -> Array:
	var delta_table := []
	delta_table.resize(256)
	delta_table[0] = 0
	var delta := 0
	var code := 64
	var step := 45
	for i in range(1, 254, 2):
		delta += (code >> 5)
		code += step
		step += 2
		delta_table[i] = delta
		delta_table[i+1] = -delta
	delta_table[255] = delta + (code >> 5)
	return delta_table


static func convert_palette_image(p_raw_palette: PackedByteArray, p_raw_img: PackedByteArray, p_with_alpha: bool, p_with_full_alpha: bool = true) -> Array:
	# Renderer
	if not rd:
		rd = RenderingServer.create_local_rendering_device()
	
	if not rd:
		var data: Array = []
		for pixel in p_raw_img:
			data.append((p_raw_palette[3*pixel] * 259 + 33) >> 6)
			data.append((p_raw_palette[3*pixel+1] * 259 + 33) >> 6)
			data.append((p_raw_palette[3*pixel+2] * 259 + 33) >> 6)
			if p_with_alpha:
				if pixel == 0:
					data.append(0)
				if p_with_full_alpha:
					if pixel > 0 and pixel < 128:
						data.append(255)
					else:
						data.append(128)
				else:
					data.append(255)
		return data
	
	# Shader
	var shader_spirv: RDShaderSPIRV
	if p_with_alpha:
		if p_with_full_alpha:
			shader_spirv = CONVERT_SHADER_FILE_WITH_FULL_ALPHA.get_spirv()
		else:
			shader_spirv = CONVERT_SHADER_FILE_WITH_ALPHA.get_spirv()
	else:
		shader_spirv = CONVERT_SHADER_FILE.get_spirv()
	var shader: RID = rd.shader_create_from_spirv(shader_spirv)
	
	# Input Image
	var image_bytes: PackedByteArray = PackedInt32Array(Array(p_raw_img)).to_byte_array()
	var image_rid: RID = rd.storage_buffer_create(image_bytes.size(), image_bytes)
	
	var image_uniform := RDUniform.new()
	image_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	image_uniform.binding = 0
	image_uniform.add_id(image_rid)
	
	
	# Palette
	var palette_bytes: PackedByteArray = PackedInt32Array(Array(p_raw_palette)).to_byte_array()
	var palette_rid: RID = rd.storage_buffer_create(palette_bytes.size(), palette_bytes)
	
	var palette_uniform := RDUniform.new()
	palette_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	palette_uniform.binding = 1
	palette_uniform.add_id(palette_rid)
	
	
	# Output Image
	var size_multiplier: int = 3
	if p_with_alpha:
		size_multiplier = 4
	var output_image_rid: RID = rd.storage_buffer_create(image_bytes.size()*size_multiplier)
	
	var output_image_uniform := RDUniform.new()
	output_image_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	output_image_uniform.binding = 2
	output_image_uniform.add_id(output_image_rid)
	
	
	var uniform_set: RID = rd.uniform_set_create([image_uniform, palette_uniform, output_image_uniform], shader, 0)
	var pipeline: RID = rd.compute_pipeline_create(shader)
	
	
	# Execute shader
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, ceili(image_bytes.size()/32.0), 1, 1)
	rd.compute_list_end()
	rd.submit()
	rd.sync()
	
	
	# Output
	var output := rd.buffer_get_data(output_image_rid)
	
	
	# Cleanup
	rd.free_rid(pipeline)
	rd.free_rid(uniform_set)
	rd.free_rid(image_rid)
	rd.free_rid(palette_rid)
	rd.free_rid(output_image_rid)
	rd.free_rid(shader)
	pipeline = RID()
	uniform_set = RID()
	image_rid = RID()
	palette_rid = RID()
	output_image_rid = RID()
	shader = RID()
	
	
	return output.to_int32_array()


static func deinit_shader() -> void:
	if rd != null:
		rd.free()


static func rotate_raw_image_clockwise(raw_image: PackedByteArray, width: int, height: int) -> PackedByteArray:
	var new_width: int = height
	var new_height: int = width
	var new_data := PackedByteArray()
	for y in range(new_height):
		for x in range(new_width):
			new_data.append(raw_image[(new_width - 1 - x) * new_height + y])
	return new_data


static func rotate_raw_image_counter_clockwise(raw_image: PackedByteArray, width: int, height: int) -> PackedByteArray:
	var new_width: int = height
	var new_height: int = width
	var new_data := PackedByteArray()
	for y in range(new_height):
		for x in range(new_width):
			new_data.append(raw_image[x * new_height + (new_height - 1 - y)])
	return new_data


static func flip_raw_image_horizontal(raw_image: PackedByteArray, width: int, height: int) -> PackedByteArray:
	var new_data := PackedByteArray()
	for y in range(height):
		for x in range(width):
			new_data.append(raw_image[y * width + (width - 1 - x)])
	return new_data


static func flip_raw_image_vertical(raw_image: PackedByteArray, width: int, height: int) -> PackedByteArray:
	var new_data := PackedByteArray()
	for y in range(height):
		for x in range(width):
			new_data.append(raw_image[x + width * (height - 1 - y)])
	return new_data
