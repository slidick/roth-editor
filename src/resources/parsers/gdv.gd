extends Node
class_name GDV

const PIXEL_8_BITS: int = 1 << 0
const PIXEL_15_BITS: int = 1 << 1
const PIXEL_16_BITS: int = 1 << 2
const PIXEL_24_BITS: int = 1 << 3

const AUDIO_PRESENT: int = 1 << 0
const AUDIO_CHANNELS_STEREO: int = 1 << 1
const SAMPLE_WIDTH_16: int = 1 << 2
const AUDIO_CODING_DPCM: int = 1 << 3

const HEADER := {
	"signature": Parser.Type.DWord,
	"size_id": Parser.Type.Word,
	"nb_frames": Parser.Type.Word,
	"framerate": Parser.Type.Word,
	"sound_flags": Parser.Type.Word,
	"playback_frequency": Parser.Type.Word,
	"image_type": Parser.Type.Word,
	"frame_size": Parser.Type.Word,
	"unk_byte_00": Parser.Type.Byte,
	"lossyness": Parser.Type.Byte,
	"frame_width": Parser.Type.Word,
	"frame_height": Parser.Type.Word,
}

const FRAME_HEADER := {
	"signature": Parser.Type.Word,
	"length": Parser.Type.Word,
	"type_flags": Parser.Type.DWord,
}

static var _stop_loading: bool = false
static var is_loading: bool = false


static func stop_loading() -> void:
	_stop_loading = true


static func parse(filename: String) -> Dictionary:
	if is_loading:
		return {}
	is_loading = true
	var gdv_filepath: String =  Roth.directory.path_join("..").path_join("DATA").path_join("GDV").path_join("%s.GDV" % filename)
	if not FileAccess.file_exists(gdv_filepath):
		return {}
	#print("Parsing: %s" % gdv_filepath)
	var file := FileAccess.open(gdv_filepath, FileAccess.READ)
	
	# Header
	var header := Parser.parse_section(file, HEADER)
	assert(header.signature == 688986516)
	#print(JSON.stringify(header, '\t', false))
	
	# Palette
	var palette: Array = []
	if header.image_type & PIXEL_8_BITS > 0:
		var raw_palette: PackedByteArray = file.get_buffer(256*3)
		for i in range(0, len(raw_palette), 3):
			palette.append([(raw_palette[i] * 259 + 33) >> 6, (raw_palette[i+1] * 259 + 33) >> 6, (raw_palette[i+2] * 259 + 33) >> 6 ])
	else:
		palette = Das.get_default_palette()
	
	# Audio Init
	var delta_table := DBase500._init_delta_table()
	var audio: Array = []
	var left_state: float = 0
	var right_state: float = 0
	
	# Video init
	var video: Array = []
	var previous_frame: PackedByteArray = []
	_stop_loading = false
	# Chunk
	for i in range(header.nb_frames):
		# Audio
		if header.sound_flags & AUDIO_PRESENT > 0:
			var audio_length: int = get_length_audio_data(header)
			var raw_audio: PackedByteArray = file.get_buffer(audio_length)
			var audio_frame: Array = []
			if header.sound_flags & AUDIO_CODING_DPCM > 0:
				for j in range(0, audio_length, 2):
					left_state += delta_table[raw_audio[j]]
					if left_state > 32767:
						left_state -= 65536
					if left_state < -32768:
						left_state += 65536
					
					right_state += delta_table[raw_audio[j+1]]
					if right_state > 32767:
						right_state -= 65536
					if right_state < -32768:
						right_state += 65536
					
					audio_frame.append(Vector2((left_state/pow(2,15)),(right_state/pow(2,15))))
			else:
				for j in range(0, len(raw_audio), 4):
					var left_frame: float = (raw_audio[j]) + (raw_audio[j+1] << 8)
					left_frame = Parser.unsigned16_to_signed(int(left_frame))
					var right_frame: float = (raw_audio[j+2]) + (raw_audio[j+3] << 8)
					right_frame = Parser.unsigned16_to_signed(int(right_frame))
					audio_frame.append(Vector2((left_frame/pow(2,15)),(right_frame/pow(2,15))))
			
			audio.append_array(audio_frame)
		
		
		# Video
		if header.frame_size != 0:
			var frame_header := Parser.parse_section(file, FRAME_HEADER)
			assert(frame_header.signature == 4869)
			var data: PackedByteArray = file.get_buffer(frame_header.length)
			var frame := FrameDecoder.new(header.frame_width, header.frame_height, frame_header, data, palette, previous_frame)
			frame.decode()
			previous_frame = frame.get_pixels()
			video.append(create_frame_image(previous_frame, frame.palette, header))
		
		if _stop_loading:
			_stop_loading = false
			is_loading = false
			return {}
		Roth.gdv_loading_updated.emit.call_deferred(float(i) / header.nb_frames, filename)
	
	is_loading = false
	return {
		"name": filename,
		"header": header,
		"audio": audio,
		"video": video,
	}


static func create_frame_image(raw_img: PackedByteArray, palette: Array, header: Dictionary) -> Image:
	var data: Array
	for pixel in raw_img:
		data.append_array(palette[pixel])
	return Image.create_from_data(header.frame_width, header.frame_height, false, Image.FORMAT_RGB8, data)


static func get_length_audio_data(header: Dictionary) -> int:
	var amount: int = 0
	if header.sound_flags & AUDIO_PRESENT == 0:
		return 0
	amount = header.playback_frequency / header.framerate
	if header.sound_flags & AUDIO_CHANNELS_STEREO > 0:
		amount *= 2
	if header.sound_flags & SAMPLE_WIDTH_16 > 0:
		amount *= 2
	if header.sound_flags & AUDIO_CODING_DPCM > 0:
		amount = amount >> 1
	return amount


class BitReader extends RefCounted:
	var bytes: Array
	var pos: int
	var size: int
	var queue: int
	func _init(data: PackedByteArray, _skip: int) -> void:
		if len(data) == 0:
			return
		bytes = data.duplicate()
		pos = 0
		queue = (bytes[pos]) + (bytes[pos+1] << 8) + (bytes[pos+2] << 16) + (bytes[pos+3] << 24)
		pos += 4
		size = 16
	
	func get_bits(num: int) -> int:
		var val: int = queue & ((1 << num) - 1)
		queue = queue >> num
		size -= num
		if size <= 0:
			size += 16
			queue = queue | (((bytes[pos]) + (bytes[pos+1] << 8)) << size)
			pos += 2
		return val
	
	func get_bit() -> int:
		return get_bits(1)
	
	func get_byte() -> int:
		var val: int = bytes[pos]
		pos += 1
		return val


class FrameDecoder extends RefCounted:
	var frame_width: int
	var frame_height: int
	var frame_header: Dictionary
	var pixels: PackedByteArray
	var previous_frame_vertical_scaling: bool
	var reader: BitReader
	var palette: Array
	
	var encoding_type: int
	var horizontal_scaling: bool
	var vertical_scaling: bool
	var intraframe: bool
	var unknown: bool
	var pixel_skip: int
	
	var current_position: int
	
	var decoding_method := {
		0: decode_method_00,
		1: decode_method_01,
		2: decode_method_02,
		3: decode_method_03,
		4: decode_method_04,
		5: decode_method_05,
		6: decode_method_06,
		7: decode_method_07,
		8: decode_method_08,
	}
	
	var subdecoding_method_08 := {
		0: method_08_tag_00,
		1: method_08_tag_01,
		2: method_08_tag_02,
		3: method_08_tag_03,
	}
	
	func _init(p_frame_width: int, p_frame_height: int, p_frame_header: Dictionary, data: PackedByteArray, p_palette: Array, prev_frame: PackedByteArray = []) -> void:
		frame_width = p_frame_width
		frame_height = p_frame_height
		frame_header = p_frame_header.duplicate()
		pixels = []
		palette = p_palette
		
		encoding_type = frame_header.type_flags & 0x0F
		horizontal_scaling = frame_header.type_flags & 0b00010000
		vertical_scaling = frame_header.type_flags & 0b00100000
		intraframe = frame_header.type_flags & 0b01000000
		unknown = frame_header.type_flags & 0b10000000
		pixel_skip = frame_header.type_flags >> 8
		
		reader = BitReader.new(data, pixel_skip)
		current_position = 4096 + pixel_skip
		
		for i in range(256):
			for j in range(8):
				pixels.append(i)
		pixels.append_array(pixels.duplicate())
		
		if prev_frame.is_empty():
			for i in range(frame_width):
				for j in range(frame_height):
					pixels.append(0)
		else:
			pixels.append_array(prev_frame.duplicate())
		
		if vertical_scaling:
			for y in range(float(frame_height)/2):
				for x in range(frame_width):
					pixels[4096 + x + y * frame_width] = pixels[4096 + x + y*2 * frame_width]
	
	
	func get_bits(num: int) -> int:
		return reader.get_bits(num)
	
	func get_bit() -> int:
		return reader.get_bit()
	
	func get_byte() -> int:
		return reader.get_byte()
	
	func copy_pixels(offset: int, length: int) -> void:
		var copied_data: PackedByteArray = pixels.slice(current_position + offset, current_position + offset + length)
		for i in range(len(copied_data)):
			pixels[current_position] = copied_data[i]
			current_position += 1
	
	func get_pixel(offset: int) -> int:
		return pixels[current_position + offset]
	
	func get_pixels() -> PackedByteArray:
		if vertical_scaling:
			var new_pixels := []
			new_pixels.resize(frame_width*frame_height)
			
			var sidx: int = 4096
			var didx: int = 0
			for y in range(frame_height):
				for x in range(frame_width):
					new_pixels[didx + x] = pixels[sidx + x]
				if (y & 1) == 1:
					sidx += frame_width
				didx += frame_width
			
			return new_pixels
		return pixels.slice(4096)
	
	func decode() -> void:
		decoding_method[encoding_type].call()
	
	func decode_method_00() -> void:
		assert(false, "Not implemented")
	
	func decode_method_01() -> void:
		assert(len(reader.bytes) == 256 * 3)
		var raw_palette: PackedByteArray = reader.bytes
		palette.clear()
		for i in range(0, len(raw_palette), 3):
			palette.append([(raw_palette[i] * 259 + 33) >> 6, (raw_palette[i+1] * 259 + 33) >> 6, (raw_palette[i+2] * 259 + 33) >> 6 ])
		
		if pixel_skip == 0:
			pixels.fill(0)
		else:
			pixels.fill(255)
	
	func decode_method_02() -> void:
		assert(false, "Not implemented")
	
	func decode_method_03() -> void:
		pass
	
	func decode_method_04() -> void:
		assert(false, "Unknown encoding")
	
	func decode_method_05() -> void:
		assert(false, "Not implemented")
	
	func decode_method_06() -> void:
		assert(false, "Not implemented")
	
	func decode_method_07() -> void:
		assert(false, "Unknown encoding")
	
	func decode_method_08() -> void:
		while true:
			var tag:int = get_bits(2)
			if subdecoding_method_08[tag].call() == false:
				#print("End frame gracefully")
				break
			if current_position >= len(pixels):
				#print("End frame read past end")
				break
	
	func method_08_tag_00() -> bool:
		if get_bits(1) == 0:
			pixels[current_position] = get_byte()
			current_position += 1
			return true
		var length: int = 2
		var count: int = 0
		while true:
			count += 1
			var step: int = get_bits(count)
			length += step
			if step != ((1 << count) - 1):
				break
		for i in range(length):
			if current_position >= len(pixels):
				return false
			pixels[current_position] = get_byte()
			current_position += 1
		return true
	
	func method_08_tag_01() -> bool:
		if get_bits(1) == 0:
			current_position += get_bits(4) + 2
			return true
		var length: int = get_byte()
		if length & 0x80 == 0:
			current_position += length + 18
			return true
		current_position += (((length & 0x7F) << 8) | get_byte()) + 146
		return true
	
	func method_08_tag_02() -> bool:
		var sub_tag: int = get_bits(2)
		var offset: int
		var length: int
		if sub_tag == 3:
			offset = get_byte()
			length = 2 + int((offset & 0x80) == 0x80)
			offset = offset & 0x7F
			if offset == 0:
				for i in range(length):
					if current_position == 0:
						pixels[current_position] = 255
					else:
						pixels[current_position] = get_pixel(-1)
					current_position += 1
				return true
			else:
				offset += 1
				copy_pixels(-offset, length)
				return true
		var next_4: int = get_bits(4)
		var next_byte: int = get_byte()
		offset = (next_4 << 8) | next_byte
		if sub_tag == 0 and offset == 0xFFF:
			return false
		if sub_tag == 0 and offset > 0xF80:
			length = (offset & 0x0F) + 2
			offset = (offset >> 4) & 7
			var px1: int = get_pixel(-(offset + 1))
			var px2: int = get_pixel(-offset)
			for i in range(length):
				pixels[current_position] = px1
				pixels[current_position+1] = px2
				current_position += 2
			return true
		length = sub_tag + 3
		if offset == 0XFFF:
			for i in range(length):
				if current_position == 0:
					pixels[current_position] = 255
				else:
					pixels[current_position] = get_pixel(-1)
				current_position += 1
			return true
		offset = 4096 - offset
		copy_pixels(-offset, length)
		return true
	
	func method_08_tag_03() -> bool:
		var first_byte: int = get_byte()
		var length: int
		var offset: int
		if first_byte & 0xC0 == 0xC0:
			var top_4: int = get_bits(4)
			var next_byte: int = get_byte()
			length = (first_byte & 0x3F) + 8
			offset = (top_4 << 8) | next_byte
			copy_pixels(offset+1, length)
			return true
		if first_byte & 0x80 == 0:
			var bits_6_to_4: int = first_byte >> 4
			var bits_3_to_0: int = first_byte & 0x0F
			var next_byte: int = get_byte()
			length = bits_6_to_4 + 6
			offset = (bits_3_to_0 << 8) | next_byte
		else:
			var top_4: int = get_bits(4)
			var next_byte: int = get_byte()
			length = 14 + (first_byte & 0x3F)
			offset = (top_4 << 8) | next_byte
		if offset == 0xFFF:
			for i in range(length):
				if current_position == 0:
					pixels[current_position] = 255
				else:
					pixels[current_position] = get_pixel(-1)
				current_position += 1
			return true
		offset = 4096 - offset
		copy_pixels(-offset, length)
		return true
