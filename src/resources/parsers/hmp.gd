extends Object
class_name Hmp

const HEADER: Dictionary = {
	"signature": [Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char],
	"padding_1": Parser.Type.DWord,
	"padding_2": Parser.Type.DWord,
	"padding_3": Parser.Type.DWord,
	"padding_4": Parser.Type.DWord,
	"padding_5": Parser.Type.Word,
	"file_length": Parser.Type.DWord,
	"padding_6": Parser.Type.DWord,
	"padding_7": Parser.Type.DWord,
	"padding_8": Parser.Type.DWord,
	"num_chunks": Parser.Type.DWord,
	"unknown": Parser.Type.DWord,
	"bpm": Parser.Type.DWord,
	"song_time": Parser.Type.DWord,
}

const CHUNK_HEADER: Dictionary = {
	"chunk_number": Parser.Type.DWord,
	"chunk_length": Parser.Type.DWord,
	"hmp_track": Parser.Type.DWord,
}


static func parse_at_offset(filepath: String, offset: int) -> Dictionary:
	if not FileAccess.file_exists(filepath):
		return {}
	var file := FileAccess.open(filepath, FileAccess.READ)
	file.seek(offset)
	return parse_file(file)


static func parse_file(file: FileAccess) -> Dictionary:
	var _size: int = file.get_32()
	var header: Dictionary = Parser.parse_section(file, HEADER)
	assert(header.signature == "HMIMIDIP013195")
	header["unknown"] = file.get_buffer(840)
	header["chunks"] = []
	for i in range(header.num_chunks):
		var chunk_start: int = file.get_position()
		var chunk: Dictionary = Parser.parse_section(file, CHUNK_HEADER)
		header["chunks"].append(chunk)
		var data_array: Array = []
		chunk["data"] = data_array
		while (file.get_position()-chunk_start) < chunk.chunk_length:
			# Delta
			var data: Dictionary = {}
			data_array.append(data)
			
			var delta: int = get_variable_length_hmp(file)
			data["delta"] = delta
			
			# Command
			
			var command: int = file.get_8()
			if command == 0xFF:
				var command_arg: int = file.get_8()
				var size: int = get_variable_length_midi(file)
				var command_arg_2: PackedByteArray = file.get_buffer(size)
				var event: Dictionary = {
					command = command,
					command_arg = command_arg,
					command_arg_2 = command_arg_2,
				}
				data["event"] = event
			else:
				var command_arg: int = file.get_8()
				var command_arg_2: int = file.get_8()
				var event: Dictionary = {
					command = command,
					command_arg = command_arg,
					command_arg_2 = command_arg_2,
				}
				data["event"] = event
		assert(file.get_position() == (chunk_start+chunk.chunk_length))
		
		
		
		
		#var chunk_delta: int = 0
		#var var_len_shift: int = 0
		#var byte: int = file.get_8()
		#while byte < 0x80:
			#chunk_delta = chunk_delta | ((byte & 0x7F) << var_len_shift)
			#var_len_shift += 7
			#byte = file.get_8()
		#chunk_delta = chunk_delta | ((byte & 0x7F) << var_len_shift)
		#if (chunk_delta < smallest_delta):
			#smallest_delta = chunk_delta
		
		
		
	#var hmp_divisions: int = 60
	#var tempo_f: float = (60000000 / header.bpm) + 0.5
	
	#var samples_per_delta_f: float = get_samples_per_tick(hmp_divisions, tempo_f);
	#Console.print("S/D: %s" % samples_per_delta_f)
	#var smallest_delta: int = 0x7fffffff
	#var subtract_delta: int = 0
	#var sample_remainder: float = 0.0
	
	#if (smallest_delta >= 0x7fffffff):
		#return
	#if (smallest_delta >= 0x7fffffff / samples_per_delta_f):
		#return
	#
	#subtract_delta = smallest_delta
	#var sample_count_f: float = ((smallest_delta * samples_per_delta_f) + sample_remainder)
	#
	#var sample_count := int(sample_count_f)
	#sample_remainder = sample_count_f - sample_count
	
	return header


static func get_samples_per_tick(divisions: int, tempo: float) -> float:
	var microseconds_per_tick: float = tempo / divisions
	var secs_per_tick: float = microseconds_per_tick / 1000000.0
	var samples_per_tick: float = 44100 * secs_per_tick
	return samples_per_tick


static func get_variable_length_midi(file: FileAccess) -> int:
	var size_byte: int = file.get_8()
	var size: int = 0
	while (size_byte & 0x80):
		size = (size << 7) + (size_byte & 0x7f)
		size_byte = file.get_8()
	size = (size << 7) + (size_byte)
	return size


static func get_variable_length_hmp(file: FileAccess) -> int:
	var var_len_shift: int = 0
	var size_byte: int = file.get_8()
	var size: int = 0
	while (size_byte < 0x80):
		size = size | ((size_byte & 0x7F) << var_len_shift)
		var_len_shift += 7
		size_byte = file.get_8()
	
	size = size | ((size_byte & 0x7F) << var_len_shift)
	return size
