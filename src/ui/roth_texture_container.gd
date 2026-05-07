extends RotationContainer
class_name RothTextureContainer

func clear() -> void:
	for child: Node in get_children():
		child.queue_free()


func load_data(data: Dictionary, raw_palette: PackedByteArray) -> void:
	clear()
	
	if not "data" in data:
		return
	
	if "raw_image" in data.data:
		var is_transparent: bool = data.data.image_type & Das.IMAGE_TYPE.TRANSPARENT > 0 or data.data.image_type & Das.IMAGE_TYPE.PALETTE_ZERO_OPAQUE == 0
		var is_fully_transparent: bool = data.data.image_type & Das.IMAGE_TYPE.TRANSPARENT > 0
		var image: Image = Image.create_from_data(data.data.width, data.data.height, false, Image.FORMAT_RGBA8 if is_transparent else Image.FORMAT_RGB8, Utility.convert_palette_image(raw_palette, data.data.raw_image, is_transparent, is_fully_transparent))
		var image_texture := ImageTexture.create_from_image(image)
		var texture_rect := TextureRect.new()
		texture_rect.texture = image_texture
		texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		add_child(texture_rect)
	
	elif "animation" in data.data or "animation_2" in data.data:
		var texture_rect := AnimatedTextureRect.new()
		texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		add_child(texture_rect)
		texture_rect.set_data.call_deferred(data.data, raw_palette)
