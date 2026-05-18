extends HSlider

var percent: float = 0.0 :
	set(p_percent):
		percent = p_percent
		queue_redraw()

func _draw() -> void:
	var color := Color.SLATE_BLUE
	draw_line(Vector2(0, size.y/2), Vector2(size.x*percent, size.y/2), color, 2)
