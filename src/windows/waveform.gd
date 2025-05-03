extends Control

var data: Array = []

func setup(p_data: Array) -> void:
	data = p_data
	queue_redraw()


func _draw() -> void:
	for i in range(0, len(data)-1):
		var v1 := Vector2(
			(float(i) / len(data)) * float(size.x),
			(size.y / 2) + (data[i].x * (size.y/2)),
		)
		var v2 := Vector2(
			(float(i+1) / len(data)) * float(size.x),
			(size.y / 2) + (data[i+1].x * (size.y/2)),
		)
		draw_line(v1, v2, Color.WEB_GREEN, 1.0)
