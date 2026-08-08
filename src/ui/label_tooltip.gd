extends Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS

func _get_tooltip(_at_position: Vector2) -> String:
	return text
