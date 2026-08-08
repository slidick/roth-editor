extends Node
class_name DBase300

enum {
	FILETYPE_GDV = 0x29111994,
	FILETYPE_HMP = 0x4D494D48,
	FILETYPE_MIDI = 0x6468544D,
	FILETYPE_IMG1 = 0x01,
	FILETYPE_IMG3 = 0x03,
	FILETYPE_IMG7 = 0x07,
}

const HEADER := {
	"signature": [Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char]
}

const IMG1_HDR := {
	"image_type": Parser.Type.DWord,
	"width": Parser.Type.Word,
	"height": Parser.Type.Word,
	#"palette": Array[256*3]      # Includes an 8-bit palette rather than the typical 6-bit palette
}

const IMG3_HDR := {
	"image_type": Parser.Type.DWord,
	"width": Parser.Type.Word,
	"height": Parser.Type.Word,
}

const IMG7_HDR := {
	"image_type": Parser.Type.DWord,
	"buffer_width": Parser.Type.Word,
	"buffer_height": Parser.Type.Word,
	"x_offset": Parser.Type.Word,
	"width": Parser.Type.Word,
	"y_offset": Parser.Type.Word,
	"height": Parser.Type.Word,
}


static func get_offsets_by_type(dbase300_filepath: String, type: int) -> Array:
	if not FileAccess.file_exists(dbase300_filepath):
		return []
	var file := FileAccess.open(dbase300_filepath, FileAccess.READ)
	var header := Parser.parse_section(file, HEADER)
	if header.signature != "DBASE300":
		return []
	var offsets: Array = []
	while file.get_position() < file.get_length():
		var current_position: int = file.get_position()
		var size: int = file.get_32()
		var ending_position: int = file.get_position() + size
		var filetype: int = file.get_32()
		file.seek(file.get_position() - 4)
		match filetype:
			FILETYPE_GDV:
				if type == FILETYPE_GDV:
					offsets.append(current_position)
			FILETYPE_HMP:
				if type == FILETYPE_HMP:
					offsets.append(current_position)
				if type == FILETYPE_MIDI:
					file.seek(ending_position)
					var next_current_position: int = file.get_position()
					var next_size:int = file.get_32()
					var next_ending_position: int = file.get_position() + next_size
					var next_filetype: int = file.get_32()
					if next_filetype == FILETYPE_MIDI:
						offsets.append(next_current_position)
						ending_position = next_ending_position
			FILETYPE_MIDI:
				if type == FILETYPE_MIDI:
					offsets.append(current_position)
			FILETYPE_IMG1:
				if type == FILETYPE_IMG1:
					offsets.append(current_position)
			FILETYPE_IMG3:
				if type == FILETYPE_IMG3:
					offsets.append(current_position)
			FILETYPE_IMG7:
				if type == FILETYPE_IMG7:
					offsets.append(current_position)
			_:
				pass
		file.seek(ending_position)
		file.seek((file.get_position() + 7) & ~7)
	return offsets


static func save_hmps(installation: ROTHInstallation) -> void:
	var dbase300_filepath: String =  installation.dbase300
	if not FileAccess.file_exists(dbase300_filepath):
		return
	var file := FileAccess.open(dbase300_filepath, FileAccess.READ)
	var header := Parser.parse_section(file, HEADER)
	assert(header.signature == "DBASE300")
	
	var i := 0
	while file.get_position() < file.get_length():
		var _current_position: int = file.get_position()
		var size: int = file.get_32()
		var ending_position: int = file.get_position() + size
		var filetype: int = file.get_32()
		file.seek(file.get_position() - 4)
		match filetype:
			FILETYPE_GDV:
				pass
			FILETYPE_HMP:
				var buffer := file.get_buffer(size)
				var savefile := FileAccess.open(OS.get_user_data_dir().path_join("%d.hmp" % i), FileAccess.WRITE)
				savefile.store_buffer(buffer)
				savefile.close()
				i += 1
			FILETYPE_MIDI:
				pass
			FILETYPE_IMG1:
				pass
			FILETYPE_IMG3:
				pass
			FILETYPE_IMG7:
				pass
			_:
				pass
		file.seek(ending_position)
		file.seek((file.get_position() + 7) & ~7)
	return


static func get_at_offset(dbase300_filepath: String, offset: int ) -> Variant:
	if not FileAccess.file_exists(dbase300_filepath):
		return {}
	var file := FileAccess.open(dbase300_filepath, FileAccess.READ)
	file.seek(offset)
	var size: int = file.get_32()
	var filetype: int = file.get_32()
	file.seek(file.get_position() - 4)
	match filetype:
		FILETYPE_GDV:
			return GDV.get_video_by_file(file)
		FILETYPE_HMP:
			var buffer: PackedByteArray = file.get_buffer(size)
			file.seek(file.get_position() - size - 4)
			var data: Dictionary = Hmp.parse_file(file)
			return {"raw_hmp": buffer, "hash": Array(buffer).hash(), "data": data}
		FILETYPE_MIDI:
			return {"raw_midi": file.get_buffer(size)}
		FILETYPE_IMG1:
			return _parse_image(file, size)
		FILETYPE_IMG3:
			return _parse_image(file, size)
		FILETYPE_IMG7:
			return _parse_image(file, size)
		_:
			return null


static func _parse_image(file: FileAccess, size: int) -> Dictionary:
	var img_type := file.get_32()
	file.seek(file.get_position() - 4)
	var data: Dictionary = {}
	match img_type:
		FILETYPE_IMG1:
			data = Parser.parse_section(file, IMG1_HDR)
			data["raw_palette"] = file.get_buffer(256*3)
			data["rle_data"] = file.get_buffer(size-(256*3)-8)
			data["raw_image"] = RLE.decode_rle_image(data)
		FILETYPE_IMG3:
			data = Parser.parse_section(file, IMG3_HDR)
			data["rle_data"] = file.get_buffer(size-8)
			data["raw_image"] = RLE.decode_rle_image(data)
		FILETYPE_IMG7:
			data = Parser.parse_section(file, IMG7_HDR)
			data["rle_data"] = file.get_buffer(size-16)
			data["raw_image"] = RLE.decode_rle_image(data)
	return data

static func compile(dbase100: Dictionary) -> PackedByteArray:
	
	# Gather unique gdvs and images
	var unique_gdvs: Array = []
	var unique_images: Array = []
	for inventory_item: Dictionary in dbase100.inventory:
		if inventory_item.closeup_video:
			if inventory_item.closeup_video not in unique_gdvs:
				unique_gdvs.append(inventory_item.closeup_video)
		
		for action: Dictionary in inventory_item.actions_section:
			if action.trigger == 7:
				for command: Dictionary in action.commands:
					if command.opcode == 0:
						if command.data not in unique_images:
							unique_images.append(command.data)
	
	# Gather unique music
	var unique_music: Array = []
	for action: Dictionary in dbase100.actions:
		for command: Dictionary in action.commands:
			if command.opcode == 26:
				if command.data not in unique_music:
					unique_music.append(command.data)
			if command.opcode == 14:
				if command.data not in unique_images:
					unique_images.append(command.data)
	
	# Calculate sizes and offsets of gdvs
	var size: int = 8
	var gdv_offsets: Array = []
	var gdv_sizes: Array = []
	for gdv_data: Dictionary in unique_gdvs:
		gdv_offsets.append(int(size/8.0))
		var block_size: int = 24 # Header
		if "raw_palette" in gdv_data.header:
			block_size += 256*3
		for audio_frame: Dictionary in gdv_data.audio:
			block_size += len(audio_frame.raw_audio)
		for video_frame: Dictionary in gdv_data.video:
			block_size += 8 # Frame header
			block_size += len(video_frame.raw_video)
		gdv_sizes.append(block_size)
		size += block_size + 4 # w/size entry
		size = (size + 7) & ~7 # 8-byte align
	
	# Calculate sizes and offsets of images
	var image_offsets: Array = []
	var image_sizes: Array = []
	for image_data: Dictionary in unique_images:
		image_offsets.append(int(size/8.0))
		var block_size: int = 0
		match image_data.image_type:
			FILETYPE_IMG1:
				block_size += 8 # Header
				block_size += 256*3 # Palette
			FILETYPE_IMG3:
				block_size += 8 # Header
			FILETYPE_IMG7:
				block_size += 16 # Header
		block_size += len(image_data.rle_data)
		image_sizes.append(block_size)
		size += block_size + 4 # w/size entry
		size = (size + 7) & ~7 # 8-byte align
	
	# Calculate sizes and offsets of music
	var music_offsets: Array = []
	var music_sizes: Array = []
	for music_data: Dictionary in unique_music:
		music_offsets.append(int(size/8.0))
		var block_size: int = 0
		block_size += len(music_data.raw_hmp)
		music_sizes.append(block_size)
		size += block_size + 4 # w/size entry
		size = (size + 7) & ~7 # 8-byte align
	
	# Update offsets for gdvs and images
	for inventory_item: Dictionary in dbase100.inventory:
		if inventory_item.closeup_video:
			assert(unique_gdvs.find(inventory_item.closeup_video) != -1)
			inventory_item.closeup_video_offset = gdv_offsets[unique_gdvs.find(inventory_item.closeup_video)]
		else:
			inventory_item.closeup_video_offset = 0
		
		for action: Dictionary in inventory_item.actions_section:
			if action.trigger == 7:
				for command: Dictionary in action.commands:
					if command.opcode == 0:
						assert(unique_images.find(command.data) != -1)
						command.args = image_offsets[unique_images.find(command.data)]
	
	# Update offsets for music
	for action: Dictionary in dbase100.actions:
		for command: Dictionary in action.commands:
			if command.opcode == 26:
				assert(unique_music.find(command.data) != -1)
				command.args = music_offsets[unique_music.find(command.data)]
			if command.opcode == 14:
				assert(unique_images.find(command.data) != -1)
				command.args = image_offsets[unique_images.find(command.data)]
	
	# Compile the file
	var data: PackedByteArray = "DBASE300".to_ascii_buffer()
	data.resize(size)
	
	# Write the gdvs
	for i in range(len(unique_gdvs)):
		var gdv_data: Dictionary = unique_gdvs[i]
		var pos: int = gdv_offsets[i]*8
		var block_size: int = gdv_sizes[i]
		data.encode_u32(pos, block_size)
		pos += 4
		
		data.encode_u32(pos, gdv_data.header.signature)
		data.encode_u16(pos+4, gdv_data.header.size_id)
		data.encode_u16(pos+6, gdv_data.header.nb_frames)
		data.encode_u16(pos+8, gdv_data.header.framerate)
		data.encode_u16(pos+10, gdv_data.header.sound_flags)
		data.encode_u16(pos+12, gdv_data.header.playback_frequency)
		data.encode_u16(pos+14, gdv_data.header.image_type)
		data.encode_u16(pos+16, gdv_data.header.frame_size)
		data.encode_u8(pos+18, gdv_data.header.unk_byte_00)
		data.encode_u8(pos+19, gdv_data.header.lossyness)
		data.encode_u16(pos+20, gdv_data.header.frame_width)
		data.encode_u16(pos+22, gdv_data.header.frame_height)
		pos += 24
		
		if "raw_palette" in gdv_data.header:
			for byte: int in gdv_data.header.raw_palette:
				data.encode_u8(pos, byte)
				pos += 1
		
		for j in range(gdv_data.header.nb_frames):
			if len(gdv_data.audio) > j:
				for byte: int in gdv_data.audio[j].raw_audio:
					data.encode_u8(pos, byte)
					pos += 1
			if len(gdv_data.video) > j:
				data.encode_u16(pos, gdv_data.video[j].header.signature)
				data.encode_u16(pos+2, gdv_data.video[j].header.length)
				data.encode_u32(pos+4, gdv_data.video[j].header.type_flags)
				pos += 8
				for byte: int in gdv_data.video[j].raw_video:
					data.encode_u8(pos, byte)
					pos += 1
	
	# Write the images
	for i in range(len(unique_images)):
		var image_data: Dictionary = unique_images[i]
		var pos: int = image_offsets[i]*8
		var block_size: int = image_sizes[i]
		data.encode_u32(pos, block_size)
		pos += 4
		
		match image_data.image_type:
			FILETYPE_IMG1:
				data.encode_u32(pos, image_data.image_type)
				data.encode_u16(pos+4, image_data.width)
				data.encode_u16(pos+6, image_data.height)
				pos += 8
				for byte: int in image_data.raw_palette:
					data.encode_u8(pos, byte)
					pos += 1
			FILETYPE_IMG3:
				data.encode_u32(pos, image_data.image_type)
				data.encode_u16(pos+4, image_data.width)
				data.encode_u16(pos+6, image_data.height)
				pos += 8
			FILETYPE_IMG7:
				data.encode_u32(pos, image_data.image_type)
				data.encode_u16(pos+4, image_data.buffer_width)
				data.encode_u16(pos+6, image_data.buffer_height)
				data.encode_u16(pos+8, image_data.x_offset)
				data.encode_u16(pos+10, image_data.width)
				data.encode_u16(pos+12, image_data.y_offset)
				data.encode_u16(pos+14, image_data.height)
				pos += 16
		
		for byte: int in image_data.rle_data:
			data.encode_u8(pos, byte)
			pos += 1
	
	
	# Write the music
	for i in range(len(unique_music)):
		var music_data: Dictionary = unique_music[i]
		var pos: int = music_offsets[i]*8
		var block_size: int = music_sizes[i]
		data.encode_u32(pos, block_size)
		pos += 4
		
		for byte: int in music_data.raw_hmp:
			data.encode_u8(pos, byte)
			pos += 1
	
	return data
