extends Node
class_name DBase500


const HEADER := {
	"header": [Parser.Type.Char, Parser.Type.Char, Parser.Type.Char, Parser.Type.Char, Parser.Type.Char, Parser.Type.Char, Parser.Type.Char, Parser.Type.Char]
}

const WAV_HEADER := {
	"chunkID": [Parser.Type.Char, Parser.Type.Char, Parser.Type.Char, Parser.Type.Char],
	"chunkSize": Parser.Type.DWord,
	"format": [Parser.Type.Char, Parser.Type.Char, Parser.Type.Char, Parser.Type.Char],
	
	"subChunk1ID": [Parser.Type.Char, Parser.Type.Char, Parser.Type.Char, Parser.Type.Char],
	"subChunk1Size": Parser.Type.DWord,
	"audioFormat": Parser.Type.Word,
	"numChannels": Parser.Type.Word,
	"sampleRate": Parser.Type.DWord,
	"byteRate": Parser.Type.DWord,
	"blockAlign": Parser.Type.Word,
	"bitsPerSample": Parser.Type.Word,
	
	"subChunk2ID": [Parser.Type.Char, Parser.Type.Char, Parser.Type.Char, Parser.Type.Char],
	"subChunk2Size": Parser.Type.DWord,
}

static func add_entries_to_dbase(dbase: Dictionary) -> void:
	for text_entry: Dictionary in dbase.text_entrys:
		if text_entry.dbase500_offset != 0:
			text_entry.dbase500 = get_data_for_entry(text_entry, dbase.directory)
		else:
			text_entry.dbase500 = {}


static func get_data_for_entry(entry: Dictionary, directory: String) -> Dictionary:
	var filepath: String = directory.path_join("DBASE500.DAT")
	if not FileAccess.file_exists(filepath):
		return {}
	var file := FileAccess.open(filepath, FileAccess.READ)
	file.seek(8 * entry.dbase500_offset)
	
	var wav := Parser.parse_section(file, WAV_HEADER)
	if wav.chunkID != "FFIR":
		return {}
	
	wav["raw_data"] = file.get_buffer(wav.subChunk2Size)
	
	return wav


static func get_entry_at_offset(offset: int) -> Dictionary:
	var filepath: String = Roth.install_directory.path_join("..").path_join("DATA").path_join("DBASE500.DAT")
	if not FileAccess.file_exists(filepath):
		return {}
	var file := FileAccess.open(filepath, FileAccess.READ)
	var delta_table: Array = Utility.init_delta_table()
	
	file.seek(8 * offset)
	
	var wav_header := Parser.parse_section(file, WAV_HEADER)
	
	if wav_header.chunkID != "FFIR":
		return {}
	
	var dpcm_state := 0.0
	var data_end: int = file.get_position() + wav_header.subChunk2Size
	var data: Array = []
	data.resize(wav_header.subChunk2Size)
	var i: int = 0
	while file.get_position() < data_end:
		dpcm_state += delta_table[file.get_8()]
		if dpcm_state > 32767:
			dpcm_state -= 65536
		if dpcm_state < -32768:
			dpcm_state += 65536
		data[i] = (Vector2.ONE * (dpcm_state/pow(2,15)))
		i += 1
	
	wav_header["data"] = data
	return wav_header


static func compile(dbase100: Dictionary) -> PackedByteArray:
	
	var text_array := DBase400.assemble_text_array(dbase100)
	
	var length: int = 8
	for entry: Dictionary in text_array:
		if "dbase500" in entry and "raw_data" in entry.dbase500:
			length += 44 + len(entry.dbase500.raw_data)
			while length % 8 != 0:
				length += 1
	
	var data: PackedByteArray = "DBASE500".to_ascii_buffer()
	data.resize(length)
	var position: int = 8
	
	for entry: Dictionary in text_array:
		if "dbase500" in entry and "raw_data" in entry.dbase500:
			entry.dbase500_offset = int(position / 8.0)
			for letter: int in "FFIR".to_ascii_buffer():
				data.encode_u8(position, letter)
				position += 1
			data.encode_u32(position, 36 + len(entry.dbase500.raw_data))
			position += 4
			for letter: int in "WAVE".to_ascii_buffer():
				data.encode_u8(position, letter)
				position += 1
			for letter: int in "fmt ".to_ascii_buffer():
				data.encode_u8(position, letter)
				position += 1
			data.encode_u32(position, 16) # SubChunk Size
			position += 4
			data.encode_u16(position, 42) # DPCM Format
			position += 2
			data.encode_u16(position, entry.dbase500.numChannels)
			position += 2
			data.encode_u32(position, entry.dbase500.sampleRate)
			position += 4
			data.encode_u32(position, entry.dbase500.sampleRate * entry.dbase500.numChannels * (entry.dbase500.bitsPerSample / 8))
			position += 4
			data.encode_u16(position, entry.dbase500.numChannels * (entry.dbase500.bitsPerSample / 8))
			position += 2
			data.encode_u16(position, entry.dbase500.bitsPerSample)
			position += 2
			for letter: int in "data".to_ascii_buffer():
				data.encode_u8(position, letter)
				position += 1
			data.encode_u32(position, len(entry.dbase500.raw_data))
			position += 4
			for byte: int in entry.dbase500.raw_data:
				data.encode_u8(position, byte)
				position += 1
			while position % 8 != 0:
				position += 1
		else:
			print(entry)
			entry.dbase500_offset = 0
	return data
