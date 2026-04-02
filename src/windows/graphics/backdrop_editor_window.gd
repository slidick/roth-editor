extends BaseWindow
class_name BackdropEditor
var paletted_image: Dictionary
var cancel_load: bool = false


func _hide() -> void:
	super._hide()
	reset()


func reset() -> void:
	%ProgressBarContainer.hide()
	%NoImageLabel.show()
	paletted_image.clear()
	%TabContainer.hide()
	%"Original Texture".texture = null
	%"Paletted Texture".texture = null
	%SaveButton.disabled = true
	%BrowseButton.disabled = false
	%InputEdit.clear()
	cancel_load = true


func _on_browse_button_pressed() -> void:
	%FileDialog.popup_centered()


func _on_file_dialog_file_selected(path: String) -> void:
	%InputEdit.text = path
	if not FileAccess.file_exists(path):
		return
	var image := Image.new()
	var error: Error = image.load(path)
	if error:
		await Dialog.information("Error opening image", "Erro", false, Vector2(400, 150))
		return
	image.resize(640, 400, Image.INTERPOLATE_LANCZOS)
	%"Original Texture".texture = ImageTexture.create_from_image(image)
	%"Paletted Texture".texture = null
	%ProgressBarContainer.show()
	%TabContainer.show()
	%BrowseButton.disabled = true
	%NoImageLabel.hide()
	paletted_image.clear()
	%"Original Texture".show()
	%SaveButton.disabled = true
	var dup: Image = image.duplicate(true)
	dup.convert(Image.FORMAT_RGB8)
	cancel_load = false
	paletted_image = {
		"header": {
			"imgType": 3,
			"xOffset": 0,
			"yOffset": 0,
			"width": image.get_width(),
			"height": image.get_height(),
		},
		"raw_data": await RLE.convert_to_paletted_image(dup, Das.DEFAULT_RAW_PALETTE)
	}
	if cancel_load:
		reset()
		return
	var reconstructed_image: Array = []
	var palette := Das.DEFAULT_PALETTE
	for pixel: int in paletted_image.raw_data:
		var pixel_array := [palette[pixel][0],palette[pixel][1],palette[pixel][2]]
		reconstructed_image.append_array(pixel_array)
	var texture_image := Image.create_from_data(paletted_image.header.width, paletted_image.header.height, false, Image.FORMAT_RGB8, reconstructed_image)
	%"Paletted Texture".texture = ImageTexture.create_from_image(texture_image)
	%ProgressBarContainer.hide()
	%BrowseButton.disabled = false
	%"Paletted Texture".show()
	%SaveButton.disabled = false


func _on_save_button_pressed() -> void:
	if paletted_image:
		%SaveFileDialog.current_file = "BACKDROP.RAW"
		%SaveFileDialog.popup_centered()


func _on_save_file_dialog_file_selected(path: String) -> void:
	if paletted_image:
		paletted_image.rle_data = RLE.encode_rle_img(paletted_image)
		var buffer: PackedByteArray = Backdrop.compile(paletted_image)
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_buffer(buffer)
		file.close()
