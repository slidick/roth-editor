extends Node
class_name FXScript

const HEADER := {
	"SFX_id_str": [Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char], # "0XFS" (no zero-termination)
	"SFX_id_num": Parser.Type.Word,           # always 1?
	"unk": Parser.Type.Word,
	"sndsFAT_offset": Parser.Type.DWord,
	"unk_offset": Parser.Type.DWord,
	"sndsFAT_size": Parser.Type.DWord,        # expressed as bytes' size, not as the number of entries
	"sndNameFAT_offset": Parser.Type.DWord,
	"sndNameFAT_size": Parser.Type.DWord,     # expressed as bytes' size, not as the number of entries
}

const SNDS_FAT := {
	"offset": Parser.Type.DWord,
	"size": Parser.Type.DWord,
	"index": Parser.Type.Word,
	"type": Parser.Type.Word,  # 0 = null entry/placeholder
							   # 1 = 16 bit, 11025 Hz
							   # 3 = 16 bit, 22050 Hz */
}

const SND_NAME_ENTRY := {
	"index": Parser.Type.Word,
	"name": Parser.Type.String,
	"desc": Parser.Type.String,
}


static func get_sfx_entries() -> Array:
	var sfx_filepath: String =  Roth.install_directory.path_join("..").path_join("DATA").path_join("DATA").path_join("FXSCRIPT.SFX")
	if not FileAccess.file_exists(sfx_filepath):
		return []
	var file := FileAccess.open(sfx_filepath, FileAccess.READ)
	var header := Parser.parse_section(file, HEADER)
	
	assert(header["sndsFAT_offset"] == file.get_position())
	
	var snds_fat: int = header["sndsFAT_offset"]
	var snds_name: int = header["sndNameFAT_offset"]
	var number_sounds: int = header["sndsFAT_size"] / 12 # sizeof(SNDS_FAT)
	var i: int = 0
	var entries := []
	while i < number_sounds:
		file.seek(snds_name)
		var sound_name_entry := Parser.parse_section(file, SND_NAME_ENTRY)
		snds_name = file.get_position()
		file.seek(snds_fat)
		var snds_fat_entry := Parser.parse_section(file, SNDS_FAT)
		snds_fat = file.get_position()
		i += 1
		assert(sound_name_entry.index == snds_fat_entry.index)
		entries.append(sound_name_entry.merged(snds_fat_entry))
	
	assert(len(entries) == number_sounds)
	return entries


static func get_from_entry(entry: Dictionary) -> Dictionary:
	var sfx_filepath: String =  Roth.install_directory.path_join("..").path_join("DATA").path_join("DATA").path_join("FXSCRIPT.SFX")
	if not FileAccess.file_exists(sfx_filepath):
		return {}
	var file := FileAccess.open(sfx_filepath, FileAccess.READ)
	file.seek(entry.offset)
	var raw_data: PackedByteArray = file.get_buffer(entry.size)
	var data: Array = []
	for i in range(0, len(raw_data), 2):
		var frame: float = (raw_data[i]) + (raw_data[i+1] << 8)
		frame = Parser.unsigned16_to_signed(int(frame))
		data.append(Vector2.ONE * (frame/pow(2,15)) )
	return entry.merged({"data": data})
