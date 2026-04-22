extends Control
class_name RotationControl

var enabled: bool = true :
	set(p_enabled):
		enabled = p_enabled
		queue_redraw()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_DRAW:
			for child in get_children():
				if enabled:
					child.rotation = PI / 2
					child.scale.y = -1
				else:
					child.rotation = 0
					child.scale.y = 1
