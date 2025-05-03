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
		var entry := Parser.parse_section(file, ARRAY01_ENTRY)
		while file.get_position() % 4 > 0:
			var _padding := file.get_8()
		array_01.append(entry)
		#print("Offset: %s, Length: %s, Color: %s, String: %s" % [entry.offset, entry.length_str, entry.font_color, entry.string])
		if entry.string == "The Making of Realms":
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
