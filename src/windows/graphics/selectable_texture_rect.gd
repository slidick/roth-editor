extends TextureRect

signal clicked(shift_pressed: bool)
signal move_right
signal move_left
signal move_up
signal move_down

var selected: bool = false :
	set(p_selected):
		selected = p_selected
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(event.shift_pressed)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_RIGHT:
			move_right.emit()
		if event.keycode == KEY_LEFT:
			move_left.emit()
		if event.keycode == KEY_UP:
			move_up.emit()
		if event.keycode == KEY_DOWN:
			move_down.emit()


func _draw() -> void:
	if selected:
		var color := Color.BLACK
		draw_dashed_line(Vector2.ZERO, Vector2(texture.get_width(), 0), color)
		draw_dashed_line(Vector2(texture.get_width(), 0), Vector2(texture.get_width(), texture.get_height()), color)
		draw_dashed_line(Vector2(texture.get_width(), texture.get_height()), Vector2(0, texture.get_height()), color)
		draw_dashed_line(Vector2(0, texture.get_height()), Vector2.ZERO, color)
