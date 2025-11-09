extends CheckBox

var indeterminate: bool = false :
	set(value):
		indeterminate = value
		if indeterminate:
			set_pressed_no_signal(false)
		queue_redraw()

func _ready() -> void:
	pressed.connect(_on_pressed)

func _draw() -> void:
	if indeterminate:
		var from := Vector2( 5, size.y / 2  + 1 )
		var to := Vector2( 20, size.y / 2  + 1)
		draw_line(from, to, Color.LIGHT_GRAY, 3)

func _on_pressed() -> void:
	if indeterminate:
		indeterminate = false
		button_pressed = true
		queue_redraw()
