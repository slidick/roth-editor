extends Object
class_name Utility

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


static func are_points_collinear_2d(points_list: Array) -> bool:
	if len(points_list) < 3:
		return true
	var vector1: Vector2 = points_list[1] - points_list[0]
	for i in range(1, len(points_list)):
		var vector2: Vector2 = (points_list[(i+1)%len(points_list)] - points_list[i])
		var cross_product: float = vector1.cross(vector2)
		if cross_product < 0.0001:
			continue
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
