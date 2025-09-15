extends Node
class_name DBase300

const HEADER := {
	"signature": [Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char]
}

const FILETYPE_GDV: int = 0x29111994
const FILETYPE_HMP: int = 0x4D494D48
const FILETYPE_MIDI: int = 0x6468544D

const FILETYPE_IMG1: int = 0x01
const FILETYPE_IMG7: int = 0x03
const FILETYPE_IMG3: int = 0x07

const IMG1_HDR := {
	"imgType": Parser.Type.DWord,
	"width": Parser.Type.Word,
	"height": Parser.Type.Word,
	#"palette": Array[256*3]      # Includes an 8-bit palette rather than the typical 6-bit palette
}

const IMG3_HDR := {
	"imgType": Parser.Type.DWord,
	"width": Parser.Type.Word,
	"height": Parser.Type.Word,
}

const IMG7_HDR := {
	"imgType": Parser.Type.DWord,
	"width": Parser.Type.Word,
	"height": Parser.Type.Word,
	"unk": Parser.Type.Word,
	"width2": Parser.Type.Word,
	"unk2": Parser.Type.Word,
	"height2": Parser.Type.Word,
}

static var dbase300: Dictionary = {}

static func parse() -> void:
	var dbase300_filepath: String =  Roth.install_directory.path_join("..").path_join("DATA").path_join("DBASE300.DAT")
	if not FileAccess.file_exists(dbase300_filepath):
		return
	var file := FileAccess.open(dbase300_filepath, FileAccess.READ)
	var header := Parser.parse_section(file, HEADER)
	assert(header.signature == "DBASE300")
	
	var count: int = 0
	while file.get_position() < file.get_length():
		print(file.get_position())
		var size: int = file.get_32()
		var ending_position: int = file.get_position() + size
		var filetype: int = file.get_32()
		file.seek(file.get_position() - 4)
		match filetype:
			FILETYPE_GDV:
				pass
			FILETYPE_HMP:
				pass
			FILETYPE_MIDI:
				pass
			FILETYPE_IMG1:
				pass
				#parse_rle_image(file)
			FILETYPE_IMG3:
				pass
				#parse_rle_image(file)
			FILETYPE_IMG7:
				pass
				#parse_rle_image(file)
		file.seek(ending_position)
		count += 1
		file.seek((file.get_position() + 7) & ~7)
	
	print("Count: %s" % count)


static func get_midi_offsets() -> Array:
	var dbase300_filepath: String =  Roth.install_directory.path_join("..").path_join("DATA").path_join("DBASE300.DAT")
	if not FileAccess.file_exists(dbase300_filepath):
		return []
	var file := FileAccess.open(dbase300_filepath, FileAccess.READ)
	var header := Parser.parse_section(file, HEADER)
	assert(header.signature == "DBASE300")
	
	var midis := []
	while file.get_position() < file.get_length():
		var current_position: int = file.get_position()
		var size: int = file.get_32()
		var ending_position: int = file.get_position() + size
		var filetype: int = file.get_32()
		file.seek(file.get_position() - 4)
		
		match filetype:
			FILETYPE_GDV:
				pass
			FILETYPE_HMP:
				file.seek(ending_position)
				var next_current_position: int = file.get_position()
				var next_size:int = file.get_32()
				var next_ending_position: int = file.get_position() + next_size
				var next_filetype: int = file.get_32()
				if next_filetype == FILETYPE_MIDI:
					midis.append(next_current_position)
				ending_position = next_ending_position
			FILETYPE_MIDI:
				midis.append(current_position)
			FILETYPE_IMG1:
				pass
			FILETYPE_IMG3:
				pass
			FILETYPE_IMG7:
				pass
			_:
				print(filetype)
		file.seek(ending_position)
		file.seek((file.get_position() + 7) & ~7)
	
	return midis


static func get_gdv_offsets() -> Array:
	var dbase300_filepath: String =  Roth.install_directory.path_join("..").path_join("DATA").path_join("DBASE300.DAT")
	if not FileAccess.file_exists(dbase300_filepath):
		return []
	var file := FileAccess.open(dbase300_filepath, FileAccess.READ)
	var header := Parser.parse_section(file, HEADER)
	assert(header.signature == "DBASE300")
	
	var gdv := []
	while file.get_position() < file.get_length():
		var current_position: int = file.get_position()
		var size: int = file.get_32()
		var ending_position: int = file.get_position() + size
		var filetype: int = file.get_32()
		file.seek(file.get_position() - 4)
		
		match filetype:
			FILETYPE_GDV:
				gdv.append(current_position)
			FILETYPE_HMP:
				pass
			FILETYPE_MIDI:
				pass
			FILETYPE_IMG1:
				pass
			FILETYPE_IMG3:
				pass
			FILETYPE_IMG7:
				pass
			_:
				print(filetype)
		file.seek(ending_position)
		file.seek((file.get_position() + 7) & ~7)
	
	return gdv


static func save_hmps() -> void:
	var dbase300_filepath: String =  Roth.install_directory.path_join("..").path_join("DATA").path_join("DBASE300.DAT")
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
				print(filetype)
		file.seek(ending_position)
		file.seek((file.get_position() + 7) & ~7)
	
	return

static func get_at_offset(offset: int ) -> Variant:
	if offset in dbase300:
		return dbase300[offset]
	var dbase300_filepath: String =  Roth.install_directory.path_join("..").path_join("DATA").path_join("DBASE300.DAT")
	if not FileAccess.file_exists(dbase300_filepath):
		return {}
	var file := FileAccess.open(dbase300_filepath, FileAccess.READ)
	file.seek(offset)
	var _size := file.get_32()
	var filetype := file.get_32()
	file.seek(file.get_position() - 4)
	match filetype:
		FILETYPE_GDV:
			#var video: Dictionary = GDV.parse_file(file)
			dbase300[offset] = RothExt.get_video_by_file(file)
		FILETYPE_HMP:
			dbase300[offset] = file.get_buffer(_size)
		FILETYPE_MIDI:
			dbase300[offset] = file.get_buffer(_size)
		FILETYPE_IMG1:
			dbase300[offset] = parse_rle_image(file)
		FILETYPE_IMG3:
			dbase300[offset] = parse_rle_image(file)
		FILETYPE_IMG7:
			dbase300[offset] = parse_rle_image(file)
		_:
			dbase300[offset] = null
	return dbase300[offset]


static func parse_rle_image(file: FileAccess) -> Image:
	var img_type := file.get_32()
	file.seek(file.get_position() - 4)
	var header: Dictionary
	var palette: Array = Das.get_default_palette()
	if not palette:
		return null
	match img_type:
		FILETYPE_IMG1:
			header = Parser.parse_section(file, IMG1_HDR)
			var raw_palette := file.get_buffer(256*3)
			palette = []
			for i in range(0, len(raw_palette), 3):
				palette.append([raw_palette[i+0], raw_palette[i+1], raw_palette[i+2]])
			return Parser.decode_rle_img(header, file, palette, false)
		FILETYPE_IMG3:
			header = Parser.parse_section(file, IMG3_HDR)
		FILETYPE_IMG7:
			header = Parser.parse_section(file, IMG7_HDR)
	
	return Parser.decode_rle_img(header, file, palette)
