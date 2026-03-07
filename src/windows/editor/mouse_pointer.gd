extends Node2D


func _draw() -> void:
	if Settings.settings.get("options", {}).get("show_mouse_point", true):
		var mouse: Vector2 = (get_global_mouse_position() + global_position).snappedf(%Map2D.snap)
		draw_circle(mouse, .5, Color.GREEN)
