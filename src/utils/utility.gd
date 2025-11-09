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
