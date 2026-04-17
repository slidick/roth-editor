extends TextureRect
class_name AnimatedTextureRect

var animated_image: AnimatedSprite2D
var speed: int :
	set(p_speed):
		if p_speed == 0:
			p_speed = 1
		speed = p_speed
		# Not very good approximation
		var fps: int = roundi(0.05 * pow(speed,2) - 2.50 * speed + 30)
		if fps < 0:
			fps = 30
		animated_image.sprite_frames.set_animation_speed("default", fps)


func _ready() -> void:
	var sprite_frames := SpriteFrames.new()
	animated_image = AnimatedSprite2D.new()
	animated_image.sprite_frames = sprite_frames
	animated_image.frame_changed.connect(func () -> void: self.texture = sprite_frames.get_frame_texture("default", animated_image.frame))
	animated_image.hide()
	add_child(animated_image)


func set_data(animation_data: Dictionary, raw_palette: PackedByteArray, shift_data: Array = []) -> void:
	var current_frame: int = animated_image.frame
	var current_progress: float = animated_image.frame_progress
	animated_image.sprite_frames.clear_all()
	speed = animation_data.animation_speed
	if len(animation_data.animation) == 0:
		return
	var is_transparent: bool = animation_data.image_type & Das.IMAGE_TYPE.TRANSPARENT > 0 or animation_data.image_type & Das.IMAGE_TYPE.PALETTE_ZERO_OPAQUE == 0
	var is_fully_transparent: bool = animation_data.image_type & Das.IMAGE_TYPE.TRANSPARENT > 0
	for i in range(len(animation_data.animation)):
		var raw_img: Array = animation_data.animation[i]
		var image: Image = Image.create_from_data(animation_data.width, animation_data.height, false, Image.FORMAT_RGBA8 if is_transparent else Image.FORMAT_RGB8, Utility.convert_palette_image(raw_palette, raw_img, is_transparent, is_fully_transparent))
		
		if not shift_data.is_empty() and %ShowShiftCheckButton.button_pressed:
			var x: int = animation_data.width - 1 + (-1 * shift_data[1]) / 2
			var y: int = roundi(animation_data.height / 2) + (-1 * shift_data[0]) / 2
			if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
				image.set_pixel(x, y, Color.RED)
		
		var image_texture := ImageTexture.create_from_image(image)
		animated_image.sprite_frames.add_frame("default", image_texture)
	
	animated_image.play("default")
	animated_image.set_frame_and_progress(current_frame, current_progress)
	self.texture = animated_image.sprite_frames.get_frame_texture("default", 0)
