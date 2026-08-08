extends Control

var _show_crosshair: bool = true

# TODO: Fix lazy hack. Maybe setup a global signal to use when changing mouse mode.
func _process(_delta: float) -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and _show_crosshair:
		show()
	else:
		hide()


func toggle(_bool: Variant) -> void:
	if typeof(_bool) == TYPE_BOOL:
		_show_crosshair = _bool
	else:
		_show_crosshair = not _show_crosshair


func _draw() -> void:
	draw_line(Vector2(0, 5), Vector2(10, 5), Color(0.8, 0.8, 0.8, 0.8), 2, true)
	draw_line(Vector2(5, 0), Vector2(5, 10), Color(0.8, 0.8, 0.8, 0.8), 2, true)
