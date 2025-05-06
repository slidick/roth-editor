extends Control

const JUMP: int = 40

var data: Array = []


func setup(p_data: Array) -> void:
	data = p_data
	queue_redraw()

func _draw() -> void:
	var vertices := []
	for i in range(0, len(data)-1, JUMP):
		var v1 := Vector2(
			(float(i) / len(data)) * float(size.x),
			(size.y / 2) + (data[i].x * (size.y/2)),
		)
		vertices.append(v1)
	draw_polyline(vertices, Color.WEB_GREEN, 1.0, true)
