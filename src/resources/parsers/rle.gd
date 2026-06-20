extends Node
class_name RLE


static func decode_rle_image(image_data: Dictionary) -> PackedByteArray:
	if not "rle_data" in image_data:
		return PackedByteArray()
	
	var decoded_sprite_size: int = image_data.width * image_data.height
	var decoded_sprite_buffer := PackedByteArray()
	decoded_sprite_buffer.resize(decoded_sprite_size)
	
	var dest_idx: int = 0
	var position: int = 0
	while dest_idx < decoded_sprite_size:
		var byte: int = image_data.rle_data[position]
		position += 1
		var pixel_count: int = 1
		if byte > 0xF0:
			pixel_count = byte & 0x0F
			byte = image_data.rle_data[position]
			position += 1
		
		for i in range(pixel_count):
			decoded_sprite_buffer[dest_idx] = byte
			dest_idx += 1
	
	return decoded_sprite_buffer


static func encode_rle_image(input_image: Dictionary, no_compression: bool = false) -> PackedByteArray:
	if not "raw_image" in input_image:
		return PackedByteArray()
	
	var output_data: PackedByteArray = []
	
	if no_compression:
		for i: int in range(0, len(input_image.raw_image), 1):
			if input_image.raw_image[i] < 0xF0:
				output_data.append(input_image.raw_image[i])
			else:
				output_data.append(0xF1)
				output_data.append(input_image.raw_image[i])
	
	else:
		var repeat: int = 1
		var last_byte: int = input_image.raw_image[0]
		
		for i: int in range(1, len(input_image.raw_image), 1):
			var byte: int = input_image.raw_image[i]
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


static func decode_row_rle_image(input_image: Dictionary) -> PackedByteArray:
	var data := PackedByteArray()
	data.resize(input_image.width * input_image.height)
	
	var src_index: int = input_image.height * 4
	var pos: int = 0
	var row_start_index: int = 0
	for i in range(input_image.height):
		var starting_offset: int = input_image.encoded_image.decode_u16(pos)
		var pixel_run: int = input_image.encoded_image.decode_u16(pos+2)
		pos += 4
		for j in range(pixel_run):
			data[row_start_index+starting_offset+j] = input_image.encoded_image[src_index]
			src_index += 1
		row_start_index += input_image.width
	
	return data


static func encode_row_rle_image(input_image: Dictionary) -> PackedByteArray:
	if not "raw_image" in input_image:
		return PackedByteArray()
	
	var output_data := PackedByteArray()
	output_data.resize(4*input_image.height)
	
	var row_offset: int = 0
	
	for row: int in range(input_image.height):
		var left_offset: int = 0
		while input_image.raw_image[row_offset+left_offset] == 0 and left_offset < input_image.width-1:
			left_offset += 1
		
		var right_offset: int = 0
		while input_image.raw_image[row_offset+input_image.width-1-right_offset] == 0 and right_offset < input_image.width-1:
			right_offset += 1
		
		var pixel_run: int = input_image.width - left_offset - right_offset
		if pixel_run <= 0:
			left_offset = 0
			pixel_run = 0
		
		
		output_data.encode_u16(row*4, left_offset)
		output_data.encode_u16(row*4+2, pixel_run)
		
		for i in range(pixel_run):
			output_data.append(input_image.raw_image[row_offset+left_offset+i])
		
		row_offset += input_image.width
	
	
	return output_data


static func convert_raw_palette(p_raw_palette: PackedByteArray, p_8bit_palette: bool = false) -> Array:
	var palette: Array = []
	for i in range(0, len(p_raw_palette), 3):
		if p_8bit_palette:
			palette.append([p_raw_palette[i], p_raw_palette[i+1], p_raw_palette[i+2]])
		else:
			palette.append([(p_raw_palette[i] * 259 + 33) >> 6, (p_raw_palette[i+1] * 259 + 33) >> 6, (p_raw_palette[i+2] * 259 + 33) >> 6 ])
	return palette


static func convert_to_paletted_image(input_image: Image, raw_palette: Array, p_8bit_palette: bool = false) -> PackedByteArray:
	var input_image_data: PackedByteArray = input_image.data.data
	var palette: Array = convert_raw_palette(raw_palette, p_8bit_palette)
	
	var channels:int = 3
	if input_image.get_format() == Image.FORMAT_RGBA8:
		channels = 4
	
	var _start_time: int = Time.get_ticks_msec()
	var progress: Dictionary = {"value": 0}
	var color_map: Dictionary = {}
	for i in range(len(palette)):
		var rgb_string: String = "%d,%d,%d" % [palette[i][0], palette[i][1], palette[i][2]]
		if rgb_string not in color_map:
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
