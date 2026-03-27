extends Node
class_name RLE


static func decode_rle_img(rle_image_hdr: Dictionary, file: FileAccess, palette: Array, with_alpha: bool = true) -> Image:
	var decoded_sprite_size: int = rle_image_hdr.width * rle_image_hdr.height
	if with_alpha:
		decoded_sprite_size *= 4
	else:
		decoded_sprite_size *= 3
	var decoded_sprite_buffer: Array = []
	decoded_sprite_buffer.resize(decoded_sprite_size)
	
	var dest_idx: int = 0
	while dest_idx < decoded_sprite_size:
		var byte: int = file.get_8()
		if byte > 0xF0:
			var pixel_count: int = byte & 0x0F
			var value: int = file.get_8()
			var pixel_value: Array = palette[value].duplicate()
			if palette[value] == [0,0,0] and value == 0:
				pixel_value.append(0)
			else:
				pixel_value.append(255)
			for i in range(pixel_count):
				decoded_sprite_buffer[dest_idx] = pixel_value[0]
				decoded_sprite_buffer[dest_idx+1] = pixel_value[1]
				decoded_sprite_buffer[dest_idx+2] = pixel_value[2]
				if with_alpha:
					decoded_sprite_buffer[dest_idx+3] = pixel_value[3]
					dest_idx += 4
				else:
					dest_idx += 3
		else:
			var pixel_value: Array = palette[byte].duplicate()
			if palette[byte] == [0,0,0] and byte == 0:
				pixel_value.append(0)
			else:
				pixel_value.append(255)
			decoded_sprite_buffer[dest_idx] = pixel_value[0]
			decoded_sprite_buffer[dest_idx+1] = pixel_value[1]
			decoded_sprite_buffer[dest_idx+2] = pixel_value[2]
			if with_alpha:
				decoded_sprite_buffer[dest_idx+3] = pixel_value[3]
				dest_idx += 4
			else:
				dest_idx += 3
	
	var image := Image.create_from_data(rle_image_hdr.width, rle_image_hdr.height, false, Image.FORMAT_RGBA8, decoded_sprite_buffer)
	
	return image


static func add_image_to_raw_rle_dict(input_image: Dictionary, palette: Array, with_alpha: bool = true) -> void:
	var decoded_sprite_size: int = input_image.header.width * input_image.header.height
	if with_alpha:
		decoded_sprite_size *= 4
	else:
		decoded_sprite_size *= 3
	var decoded_sprite_buffer: Array = []
	decoded_sprite_buffer.resize(decoded_sprite_size)
	var dest_idx: int = 0
	var position: int = 0
	while dest_idx < decoded_sprite_size:
		var byte: int = input_image.rle_data[position]
		position += 1
		if byte > 0xF0:
			var pixel_count: int = byte & 0x0F
			var value: int = input_image.rle_data[position]
			position += 1
			var pixel_value: Array = palette[value].duplicate()
			if palette[value] == [0,0,0] and value == 0:
				pixel_value.append(0)
			else:
				pixel_value.append(255)
			for i in range(pixel_count):
				decoded_sprite_buffer[dest_idx] = pixel_value[0]
				decoded_sprite_buffer[dest_idx+1] = pixel_value[1]
				decoded_sprite_buffer[dest_idx+2] = pixel_value[2]
				if with_alpha:
					decoded_sprite_buffer[dest_idx+3] = pixel_value[3]
					dest_idx += 4
				else:
					dest_idx += 3
		else:
			var pixel_value: Array = palette[byte].duplicate()
			if palette[byte] == [0,0,0] and byte == 0:
				pixel_value.append(0)
			else:
				pixel_value.append(255)
			decoded_sprite_buffer[dest_idx] = pixel_value[0]
			decoded_sprite_buffer[dest_idx+1] = pixel_value[1]
			decoded_sprite_buffer[dest_idx+2] = pixel_value[2]
			if with_alpha:
				decoded_sprite_buffer[dest_idx+3] = pixel_value[3]
				dest_idx += 4
			else:
				dest_idx += 3
	
	var image := Image.create_from_data(input_image.header.width, input_image.header.height, false, Image.FORMAT_RGBA8, decoded_sprite_buffer)
	input_image["image"] = image


static func encode_rle_img(input_image: Dictionary) -> PackedByteArray:
	if not "raw_data" in input_image:
		return input_image.rle_data
	
	var output_data: PackedByteArray = []
	var repeat: int = 1
	var last_byte: int = input_image.raw_data[0]
	
	for i: int in range(1, len(input_image.raw_data), 1):
		var byte: int = input_image.raw_data[i]
		if byte == last_byte and repeat < 15:
			repeat += 1
		else:
			if repeat > 1 or last_byte >= 0xF0:
				output_data.append(0xF0 | repeat)
			output_data.append(last_byte)
			last_byte = byte
			repeat = 1
	if repeat > 1 or last_byte >= 0xF0:
		output_data.append(0xF0 | repeat)
	output_data.append(last_byte)
	
	return output_data


static func convert_to_paletted_image(input_image: Image, palette: Array) -> PackedByteArray:
	var input_image_data: PackedByteArray = input_image.data.data
	
	var channels:int = 3
	if input_image.get_format() == Image.FORMAT_RGBA8:
		channels = 4
	
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
		worker_paletted_image.resize(len(worker_image_data) / channels)
		for i in range(0, len(worker_image_data), channels):
			#if cancel_load:
			#	return PackedByteArray()
			
			if input_image.get_format() == Image.FORMAT_RGBA8:
				if is_equal_approx(worker_image_data[i+3], 0):
					mutex.lock()
					@warning_ignore("integer_division")
					worker_paletted_image[i/channels] = 0
					progress.value += channels
					mutex.unlock()
					continue
			
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
			worker_paletted_image[i/channels] = color_map[rgb_string]
			progress.value += channels
			mutex.unlock()
		return worker_paletted_image
	
	var num_threads: int = OS.get_processor_count()
	var chunk_size: int = snappedi(len(input_image_data) / float(num_threads), channels)
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
		#%ProgressBar.value = float(progress.value) / len(input_image_data) * 100
		await Roth.get_tree().process_frame
	
	var paletted_image_data: PackedByteArray = []
	for i in range(num_threads):
		while threads[i].is_alive():
			#%ProgressBar.value = float(progress.value) / len(input_image_data) * 100
			await Roth.get_tree().process_frame
		var results: PackedByteArray = threads[i].wait_to_finish()
		paletted_image_data.append_array(results)
	
	return paletted_image_data
