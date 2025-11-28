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


static func get_sfx_entries(sfx_filepath: String = Roth.install_directory.path_join("../DATA/DATA/FX22.SFX")) -> Array:
	
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
		snds_fat_entry.sfx_filepath = sfx_filepath
		entries.append(sound_name_entry.merged(snds_fat_entry))
	
	assert(len(entries) == number_sounds)
	
	return entries


static func get_from_entry(entry: Dictionary) -> Dictionary:
	var sfx_filepath: String = entry.sfx_filepath
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


static func get_from_index(index: int) -> Dictionary:
	var current_sfx_pack: Dictionary = Roth.get_active_sfx_info()
	
	if not current_sfx_pack:
		return {}
	
	var sfx_filepath: String
	if "vanilla" in current_sfx_pack:
		sfx_filepath = Roth.install_directory.path_join("../DATA/DATA/FX22.SFX")
	else:
		sfx_filepath = Roth.ROTH_CUSTOM_SFX_DIRECTORY.path_join(current_sfx_pack.name).path_join("FXSCRIPT.SFX")
	
	var entries: Array = get_sfx_entries(sfx_filepath)
	if index < len(entries):
		return get_from_entry(entries[index])
	
	return {}


static func parse_sfx_info(p_sfx_info: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(p_sfx_info.filepath):
		return {}
	var file := FileAccess.open(p_sfx_info.filepath, FileAccess.READ)
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
		file.seek(snds_fat_entry.offset)
		var raw_data: PackedByteArray = file.get_buffer(snds_fat_entry.size)
		snds_fat_entry["raw_data"] = raw_data
		entries.append(sound_name_entry.merged(snds_fat_entry))
	assert(len(entries) == number_sounds)
	var return_data: Dictionary = {}
	return_data["header"] = header
	return_data["entries"] = entries
	return_data["sfx_info"] = p_sfx_info
	return return_data


static func compile(fxscript: Dictionary) -> PackedByteArray:
	# Calculate Size
	var data_size: int = 0
	var name_size: int = 0
	var fat_size: int = 0
	for entry: Dictionary in fxscript.entries:
		name_size += len(entry.name)
		name_size += len(entry.desc)
		name_size += 4
		data_size += len(entry.raw_data)
		fat_size += 12
	name_size += 2
	
	# Header
	var position: int = 0
	var data: PackedByteArray = "0XFS".to_ascii_buffer()
	data.resize(data_size+name_size+fat_size+28)
	data.encode_u16(position+4, 1)
	data.encode_u16(position+6, 0)
	data.encode_u32(position+8, 28)
	data.encode_u32(position+12, fat_size+data_size)
	data.encode_u32(position+16, fat_size)
	data.encode_u32(position+20, 28+fat_size+data_size)
	data.encode_u32(position+24, name_size)
	position += 28
	
	# Data
	var current_data_offset: int = 28 + fat_size
	var current_name_offset: int = 28+fat_size+data_size
	var index: int = 1
	for entry: Dictionary in fxscript.entries:
		data.encode_u32(position, current_data_offset)
		data.encode_u32(position+4, len(entry.raw_data))
		data.encode_u16(position+8, index)
		data.encode_u16(position+10, entry.type)
		
		for j in range(len(entry.raw_data)):
			data.encode_u8(current_data_offset+j, entry.raw_data[j])
		
		var current_name_size: int = 0
		data.encode_u16(current_name_offset, index)
		current_name_size += 2
		for value: int in entry.name.to_ascii_buffer():
			data.encode_u8(current_name_offset+current_name_size, value)
			current_name_size += 1
		data.encode_u16(current_name_offset+current_name_size, 0)
		current_name_size += 1
		for value: int in entry.desc.to_ascii_buffer():
			data.encode_u8(current_name_offset+current_name_size, value)
			current_name_size += 1
		data.encode_u16(current_name_offset+current_name_size, 0)
		current_name_size += 1
		
		index += 1
		position += 12
		current_data_offset += len(entry.raw_data)
		current_name_offset += current_name_size
	
	# Footer
	data.encode_u8(current_name_offset, 0xFF)
	data.encode_u8(current_name_offset+1, 0xFF)
	
	return data


static func convert_to_playable_entry(entry: Dictionary, start_index: int = 0, end_index: int = -1) -> Dictionary:
	if end_index == -1:
		end_index = len(entry.raw_data) - 1
	var raw_data: PackedByteArray = entry.raw_data.slice(start_index*2, end_index*2)
	var data: Array = []
	for i in range(0, len(raw_data), 2):
		var frame: float = raw_data.decode_s16(i)
		data.append(Vector2.ONE * (frame/pow(2,15)) )
	return entry.merged({"data": data})


static func get_info(filepath: String) -> Dictionary:
	var file := FileAccess.open(filepath, FileAccess.READ)
	var header := Parser.parse_section(file, HEADER)
	var number_sounds: int = header["sndsFAT_size"] / 12 # sizeof(SNDS_FAT)
	var info := {
		"count": number_sounds,
		"filesize": file.get_length(),
		"filepath": filepath
	}
	file.close()
	return info
