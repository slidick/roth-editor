extends BaseWindow

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
		"width": image.get_width(),
		"height": image.get_height(),
		"data": await convert_to_paletted_image(dup.data.data, Das.get_default_palette())
	}
	if cancel_load:
		reset()
		return
	var reconstructed_image: Array = []
	var palette := Das.get_default_palette()
	for pixel: int in paletted_image.data:
		var pixel_array := [palette[pixel][0],palette[pixel][1],palette[pixel][2]]
		reconstructed_image.append_array(pixel_array)
	var texture_image := Image.create_from_data(paletted_image.width, paletted_image.height, false, Image.FORMAT_RGB8, reconstructed_image)
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
		var buffer: PackedByteArray = Parser.encode_rle_img(paletted_image)
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_buffer(buffer)
		file.close()


func convert_to_paletted_image(input_image_data: Array, palette: Array) -> PackedByteArray:
	var _start_time: int = Time.get_ticks_msec()
	var progress: Dictionary = {"value": 0}
	var color_map: Dictionary = {}
	for i in range(len(palette)):
		var rgb_string: String = "%d,%d,%d" % [palette[i][0], palette[i][1], palette[i][2]]
		color_map[rgb_string] = i
	
	var mutex := Mutex.new()
	var worker: Callable = func (worker_image_data: PackedByteArray) -> PackedByteArray:
		var worker_paletted_image: PackedByteArray = []
		@warning_ignore("integer_division")
		worker_paletted_image.resize(len(worker_image_data) / 3)
		for i in range(0, len(worker_image_data), 3):
			if cancel_load:
				return PackedByteArray()
			var rgb_string: String = "%d,%d,%d" % [worker_image_data[i], worker_image_data[i+1], worker_image_data[i+2]]
			if rgb_string not in color_map:
				var min_diff: int = 10000
				var closest_index: int = 0
				for j in range(len(palette)):
					var diff: int = abs(worker_image_data[i] - palette[j][0]) + abs(worker_image_data[i+1] - palette[j][1]) + abs(worker_image_data[i+2] - palette[j][2])
					if diff < min_diff:
						min_diff = diff
						closest_index = j
				mutex.lock()
				color_map[rgb_string] = closest_index
				mutex.unlock()
			mutex.lock()
			@warning_ignore("integer_division")
			worker_paletted_image[i/3] = color_map[rgb_string]
			progress.value += 3
			mutex.unlock()
		return worker_paletted_image
	
	var num_threads: int = OS.get_processor_count()
	#print("Threads: %d" % num_threads)
	var chunk_size: int = snappedi(int(len(input_image_data) / float(num_threads)), 3)
	#print("Chunk Size: %d" % chunk_size)
	var threads: Array = []
	for i in range(num_threads):
		var start_index: int = i  * chunk_size
		var end_index: int = 0
		if i == num_threads - 1:
			end_index = len(input_image_data)
		else:
			end_index = (i+1) * chunk_size
		var thread := Thread.new()
		thread.start(worker.bind(input_image_data.slice(start_index, end_index)))
		threads.append(thread)
	
	while threads[0].is_alive():
		%ProgressBar.value = float(progress.value) / len(input_image_data) * 100
		await Roth.get_tree().process_frame
	
	var paletted_image_data: PackedByteArray = []
	for i in range(num_threads):
		while threads[i].is_alive():
			%ProgressBar.value = float(progress.value) / len(input_image_data) * 100
			await Roth.get_tree().process_frame
		var results: PackedByteArray = threads[i].wait_to_finish()
		paletted_image_data.append_array(results)
	
	#print("Time: %.1fs" % ((Time.get_ticks_msec() - _start_time) / 1000.0))
	return paletted_image_data
