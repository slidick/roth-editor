extends Container
class_name RotationContainer

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SORT_CHILDREN:
			var s:Vector2 = size
			for child in get_children():
				child.rotation = PI / 2
				child.scale.y = -1
				child.set_deferred("size", Vector2(s.y, s.x))
