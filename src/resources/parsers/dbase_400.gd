extends Node
class_name DBase400


const ARRAY01_ENTRY := {
	"offset": Parser.Type.DWord,
	"length_str": Parser.Type.Word,
	"font_color": Parser.Type.Word,
	"string": Parser.Type.String
}

const ARRAY02_ENTRY := {
	"length": Parser.Type.Word,
	"timestamp": Parser.Type.Word,
	"font_color": Parser.Type.Byte,
	"string": Parser.Type.String,
}

const HEADER := {
	"header": [Parser.Type.Char, Parser.Type.Char, Parser.Type.Char, Parser.Type.Char, Parser.Type.Char, Parser.Type.Char, Parser.Type.Char, Parser.Type.Char]
}


static func parse(filepath: String) -> Array:
	var file := FileAccess.open(filepath, FileAccess.READ)
	
	var _header: String = Parser.parse_section(file, HEADER).header
	
	var array_01 := []
	# First Array -- In Game Subtitles
	while file.get_position() < file.get_length():
		var entry: Dictionary = {}
		entry.dbase_400_offset = file.get_position()
		entry.merge(Parser.parse_section(file, ARRAY01_ENTRY))
		
		while file.get_position() % 4 > 0:
			var _padding := file.get_8()
		array_01.append(entry)
		#print("Offset: %s, Length: %s, Color: %s, String: %s" % [entry.offset, entry.length_str, entry.font_color, entry.string])
		if entry.string.to_lower() == "chullum ashdar in derias.":
			break
	
	return array_01
	
	# Second Array -- Video Subtitles
	#while file.get_position() < file.get_length():
		#var length := file.get_16()
		#var timestamp := file.get_16()
		#if timestamp == 0xFFFF:
			#var _padding := file.get_32()
			#var length_str := file.get_16()
			#_padding = file.get_16()
			#var title := ""
			#for i in range(length_str):
				#title += String.chr(file.get_8())
			#print("Video title: %s" % title)
			#while file.get_position() % 2 > 0:
				#_padding = file.get_8()
			#continue
		#if length == 0:
			#file.seek(file.get_position()-2)
			#continue
		#var font_color := file.get_8()
		#var string := ""
		##for i in range(length_str-5):
			##string += String.chr(file.get_8())
		#string = file.get_line()
		#while file.get_position() % 2 > 0:
			#var _padding := file.get_8()
		#print("Length: %s, Timestamp: %s, Color: %s, String: %s" % [length, timestamp, font_color, string])


static func get_at_offset(offset: int) -> Dictionary:
	var filepath: String = Roth.install_directory.path_join("..").path_join("DATA").path_join("DBASE400.DAT")
	if not FileAccess.file_exists(filepath):
		return {}
	var file := FileAccess.open(filepath, FileAccess.READ)
	file.seek(offset)
	var entry := Parser.parse_section(file, ARRAY01_ENTRY)
	file.close()
	return entry


static func parse_cutscene_subtitle(file: FileAccess, offset: int) -> Dictionary:
	var position: int = file.get_position()
	file.seek(offset)
	var subtitle := {}
	subtitle["entries"] = []
	while file.get_position() < file.get_length():
		var length := file.get_16()
		var timestamp := file.get_16()
		if timestamp == 0xFFFF:
			var _padding := file.get_32()
			var length_str := file.get_16()
			_padding = file.get_16()
			var title := ""
			var bytes2 := PackedByteArray()
			for i in range(length_str):
				bytes2.append(file.get_8())
				#title += String.chr(file.get_8())
			title = bytes2.get_string_from_ascii()
			while file.get_position() % 2 > 0:
				_padding = file.get_8()
			subtitle["title"] = title
			break
		if length == 0:
			file.seek(file.get_position()-2)
			continue
		var font_color := file.get_8()
		var string := ""
		#for i in range(length_str-5):
			#string += String.chr(file.get_8())
		#string = file.get_line()
		var bytes := PackedByteArray()
		var byte: int = file.get_8()
		while byte != 0:
			bytes.append(byte)
			byte = file.get_8()
		string = bytes.get_string_from_ascii()
		while file.get_position() % 2 > 0:
			var _padding := file.get_8()
		subtitle["entries"].append({
			"length": length,
			"timestamp": timestamp,
			"font_color": font_color,
			"string": string,
		})
	
	file.seek(position)
	return subtitle
