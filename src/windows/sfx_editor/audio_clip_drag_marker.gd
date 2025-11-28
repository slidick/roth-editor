extends Label

signal moved

var pressed: bool = false

func initialize() -> void:
	if name == "StartMarker":
		position.x = -size.x/2
	else:
		if is_equal_approx(get_parent().size.x, 0):
			await get_tree().process_frame
		position.x = get_parent().size.x-size.x/2

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and pressed:
		var prev_x: float = position.x
		position.x += event.relative.x
		if name == "StartMarker":
			position.x = clamp(position.x, -size.x/2, %EndMarker.position.x)
		else:
			position.x = clamp(position.x, %StartMarker.position.x, get_parent().size.x-size.x/2)
		if position.x != prev_x:
			moved.emit()
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			pressed = true
		else:
			pressed = false
