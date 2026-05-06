extends Container
class_name RotationContainer

var enabled: bool = true :
	set(p_enabled):
		enabled = p_enabled
		queue_sort()
var mirror: bool = false :
	set(p_mirror):
		mirror = p_mirror
		queue_sort()

func _get_minimum_size() -> Vector2:
	var children_size := Vector2.ZERO
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
					if mirror:
						child.scale.y = 1
						child.set_deferred("position", Vector2(s.x, 0))
					else:
						child.scale.y = -1
						child.set_deferred("position", Vector2(0, 0))
					child.set_deferred("size", Vector2(s.y, s.x))
				else:
					child.rotation = 0
					if mirror:
						child.scale.y = -1
						child.set_deferred("position", Vector2(0, s.x))
					else:
						child.scale.y = 1
						child.set_deferred("position", Vector2(0, 0))
					child.set_deferred("size", Vector2(s.x, s.y))
