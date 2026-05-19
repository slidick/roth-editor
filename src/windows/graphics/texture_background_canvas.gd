extends Control

@export var canvas_texture: TextureRect

func _draw() -> void:
	if not canvas_texture.texture or owner.texture_data.is_empty():
		return
	
	var is_transparent: bool = owner.texture_data.image_type & Das.IMAGE_TYPE.TRANSPARENT > 0 or owner.texture_data.image_type & Das.IMAGE_TYPE.PALETTE_ZERO_OPAQUE == 0 or owner.force_partial_alpha
	if not is_transparent:
		return
	for x: int in range(canvas_texture.texture.get_width()):
		for y: int in range(canvas_texture.texture.get_height()):
			draw_rect(Rect2(x, y, 0.5, 0.5), Color.GRAY)
			draw_rect(Rect2(x+0.5, y, 0.5, 0.5), Color.DIM_GRAY)
			draw_rect(Rect2(x, y+0.5, 0.5, 0.5), Color.DIM_GRAY)
			draw_rect(Rect2(x+0.5, y+0.5, 0.5, 0.5), Color.GRAY)
