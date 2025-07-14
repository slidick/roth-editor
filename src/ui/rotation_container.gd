extends Container
class_name RotationContainer

var enabled: bool = true

func _get_minimum_size() -> Vector2:
	var children_size: Vector2
	for child: Control in get_children():
		var min_size: Vector2 = child.get_combined_minimum_size()
		if child.visible:
			children_size.x = max(children_size.x, min_size.x)
			children_size.y = max(children_size.y, min_size.y)
	
	if enabled:
		return Vector2(children_size.y, children_size.x)
	
	return children_size

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SORT_CHILDREN:
			var s:Vector2 = size
			for child in get_children():
				if enabled:
					child.rotation = PI / 2
					child.scale.y = -1
					child.set_deferred("size", Vector2(s.y, s.x))
				else:
					child.rotation = 0
					child.scale.y = 1
