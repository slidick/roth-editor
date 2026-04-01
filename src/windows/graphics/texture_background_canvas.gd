extends Control

@export var canvas_texture: TextureRect

func _draw() -> void:
	if not canvas_texture.texture:
		return
	for x: int in range(canvas_texture.texture.get_width()):
		for y: int in range(canvas_texture.texture.get_height()):
			draw_rect(Rect2(x, y, 0.5, 0.5), Color.GRAY)
			draw_rect(Rect2(x+0.5, y, 0.5, 0.5), Color.DIM_GRAY)
			draw_rect(Rect2(x, y+0.5, 0.5, 0.5), Color.DIM_GRAY)
			draw_rect(Rect2(x+0.5, y+0.5, 0.5, 0.5), Color.GRAY)
