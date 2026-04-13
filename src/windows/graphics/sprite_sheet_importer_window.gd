extends BaseWindow

signal done(data: Dictionary)

var raw_palette: PackedByteArray
var raw_spritesheet: PackedByteArray
var spritesheet_width: int = -1
var spritesheet_height: int = -1
var animation: Array = []

func import_sprite_sheet(p_raw_palette: PackedByteArray) -> Dictionary:
	raw_palette = p_raw_palette
	update_grid()
	toggle(true)
	var return_data: Dictionary = await done
	toggle(false)
	reset()
	return return_data


func reset() -> void:
	raw_spritesheet = PackedByteArray()
	spritesheet_width = -1
	spritesheet_height = -1
	animation.clear()
	%AnimatedSprite.stop()
	%AnimatedSprite.sprite_frames.clear_all()
	%PreviewTextureRect.texture = null
	%SpriteSheetTextureRect.texture = null


func update_grid() -> void:
	%SpriteSheetTextureRect.rows = %RowsSpinBox.value
	%SpriteSheetTextureRect.columns = %ColumnsSpinBox.value
	%SpriteSheetTextureRect.queue_redraw()
	update_preview()


func update_preview() -> void:
	if not %SpriteSheetTextureRect.texture:
		return
	
	%AnimatedSprite.sprite_frames.clear_all()
	%AnimatedSprite.sprite_frames.set_animation_speed("default", %FPSSpinBox.value)
	
	animation = []
	var whole_image: Image = %SpriteSheetTextureRect.texture.get_image()
	var x: int = roundi(whole_image.get_width() / float(%ColumnsSpinBox.value))
	var y: int = roundi(whole_image.get_height() / float(%RowsSpinBox.value))
	
	for i in range(%ColumnsSpinBox.value):
		var rect := Rect2i(x*(i), y*(%UseRowSpinBox.value-1), x, y)
		var image := Image.create_empty(rect.size.x, rect.size.y, false, whole_image.get_format())
		image.blit_rect(whole_image, rect, Vector2.ZERO)
		animation.append(image)
		%AnimatedSprite.sprite_frames.add_frame("default", ImageTexture.create_from_image(image))
		%SizeLabel.text = "%s x %s" % [image.get_width(), image.get_height()]
	
	if not %PreviewCheckButton.button_pressed:
		return
	
	%AnimatedSprite.play("default")
	%PreviewTextureRect.texture = %AnimatedSprite.sprite_frames.get_frame_texture("default", 0)


func _on_browse_button_pressed() -> void:
	%FileDialog.current_path = "/home/slidick/Downloads/Alenia_Dynamic_Fire_Environments/T3/T3_Purple/spritesheet_fuego.png"
	%FileDialog.popup_file_dialog()


func _on_cancel_button_pressed() -> void:
	done.emit({})


func _on_import_button_pressed() -> void:
	if len(animation) == 0:
		return
	%ImportingPanel.toggle(true)
	var animation_array: Array = []
	for frame: Image in animation:
		if %ImportAsRotatedCheckBox.button_pressed:
			frame.flip_x()
			frame.rotate_90(COUNTERCLOCKWISE)
		var raw_frame: PackedByteArray = await RLE.convert_to_paletted_image(frame, raw_palette)
		animation_array.append(raw_frame)
	var animation_data: Dictionary = {
		"width": animation[0].get_width(),
		"height": animation[0].get_height(),
		"animation": animation_array,
	}
	%ImportingPanel.toggle(false)
	done.emit(animation_data)


func _on_file_dialog_file_selected(path: String) -> void:
	%SpriteSheetTextureRect.texture = null
	%AnimatedSprite.stop()
	%PreviewTextureRect.texture = null
	%LoadingContainer.show()
	var import_image := Image.load_from_file(path)
	raw_spritesheet = await RLE.convert_to_paletted_image(import_image, raw_palette)
	spritesheet_width = import_image.get_width()
	spritesheet_height = import_image.get_height()
	%LoadingContainer.hide()
	reload_spritesheet()


func reload_spritesheet() -> void:
	var image: Image = Image.create_from_data(spritesheet_width, spritesheet_height, false, Image.FORMAT_RGBA8 if %BlackAsTransparentCheckBox.button_pressed else Image.FORMAT_RGB8, Utility.convert_palette_image(raw_palette, raw_spritesheet, %BlackAsTransparentCheckBox.button_pressed, false))
	var texture := ImageTexture.create_from_image(image)
	%SpriteSheetTextureRect.texture = texture
	update_grid()


func _on_rows_spin_box_value_changed(value: float) -> void:
	%UseRowSpinBox.max_value = value
	update_grid()


func _on_columns_spin_box_value_changed(_value: float) -> void:
	update_grid()


func _on_animated_sprite_frame_changed() -> void:
	%PreviewTextureRect.texture = %AnimatedSprite.sprite_frames.get_frame_texture("default", %AnimatedSprite.frame)


func _on_fps_spin_box_value_changed(value: float) -> void:
	%AnimatedSprite.sprite_frames.set_animation_speed("default", %FPSSpinBox.value)


func _on_fit_image_check_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		%SpriteSheetTextureRect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	else:
		%SpriteSheetTextureRect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	%SpriteSheetTextureRect.queue_redraw()


func _on_use_row_spin_box_value_changed(_value: float) -> void:
	update_preview()


func _on_preview_check_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		%FPSContainer.show()
		%BlackAsTransparentCheckBox.show()
		update_preview()
	else:
		%FPSContainer.hide()
		%BlackAsTransparentCheckBox.hide()
		%AnimatedSprite.stop()
		%PreviewTextureRect.texture = null


func _on_black_as_transparent_check_box_toggled(_toggled_on: bool) -> void:
	reload_spritesheet()
