extends TextureRect
class_name AnimatedTextureRect

var animated_image: AnimatedSprite2D


func _ready() -> void:
	var sprite_frames := SpriteFrames.new()
	animated_image = AnimatedSprite2D.new()
	animated_image.sprite_frames = sprite_frames
	animated_image.frame_changed.connect(func () -> void: self.texture = sprite_frames.get_frame_texture("default", animated_image.frame))
	animated_image.hide()
	add_child(animated_image)


func set_data(animation_data: Dictionary, raw_palette: PackedByteArray) -> void:
	animated_image.sprite_frames.clear_all()
	animated_image.sprite_frames.set_animation_speed("default", 12)
	if len(animation_data.animation) == 0:
		return
	var is_transparent: bool = animation_data.image_type & Das.IMAGE_TYPE.TRANSPARENT > 0 or animation_data.image_type & Das.IMAGE_TYPE.PALETTE_ZERO_OPAQUE == 0
	var is_fully_transparent: bool = animation_data.image_type & Das.IMAGE_TYPE.TRANSPARENT > 0
	for i in range(len(animation_data.animation)):
		var raw_img: Array = animation_data.animation[i]
		var image: Image = Image.create_from_data(animation_data.width, animation_data.height, false, Image.FORMAT_RGBA8 if is_transparent else Image.FORMAT_RGB8, Utility.convert_palette_image(raw_palette, raw_img, is_transparent, is_fully_transparent))
		var image_texture := ImageTexture.create_from_image(image)
		animated_image.sprite_frames.add_frame("default", image_texture)
	
	animated_image.play("default")
	self.texture = animated_image.sprite_frames.get_frame_texture("default", 0)
