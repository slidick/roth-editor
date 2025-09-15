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


static func get_entry_at_offset(offset: int) -> Dictionary:
	var filepath: String = Roth.install_directory.path_join("..").path_join("DATA").path_join("DBASE500.DAT")
	if not FileAccess.file_exists(filepath):
		return {}
	var file := FileAccess.open(filepath, FileAccess.READ)
	var delta_table: Array = _init_delta_table()
	
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


static func _init_delta_table() -> Array:
	var delta_table := []
	delta_table.resize(256)
	delta_table[0] = 0
	var delta := 0
	var code := 64
	var step := 45
	for i in range(1, 254, 2):
		delta += (code >> 5)
		code += step
		step += 2
		delta_table[i] = delta
		delta_table[i+1] = -delta
	delta_table[255] = delta + (code >> 5)
	
	return delta_table
