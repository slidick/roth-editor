extends Node
class_name DBase400


const ARRAY01_ENTRY := {
	"dbase500_offset": Parser.Type.DWord,
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


static func parse_full(filepath: String) -> Dictionary:
	var file := FileAccess.open(filepath, FileAccess.READ)
	
	var _header: String = Parser.parse_section(file, HEADER).header
	
	var array_01 := []
	# First Array -- In Game Subtitles
	while file.get_position() < file.get_length():
		var entry: Dictionary = Parser.parse_section(file, ARRAY01_ENTRY)
		entry.erase("length_str")
		while file.get_position() % 4 > 0:
			var _padding := file.get_8()
		array_01.append(entry)
		#print("Offset: %s, Length: %s, Color: %s, String: %s" % [entry.offset, entry.length_str, entry.font_color, entry.string])
		if entry.string.to_lower() == "chullum ashdar in derias.":
			break
	
	#return array_01
	
	# Second Array -- Video Subtitles
	var array_02 := []
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
			for i in range(length_str):
				title += String.chr(file.get_8())
			#print("Video title: %s" % title)
			while file.get_position() % 4 > 0:
				_padding = file.get_8()
			subtitle["title"] = title
			array_02.append(subtitle)
			subtitle = {}
			subtitle["entries"] = []
			continue
		if length == 0:
			file.seek(file.get_position()-4)
			var entry: Dictionary = Parser.parse_section(file, ARRAY01_ENTRY)
			entry.erase("length_str")
			while file.get_position() % 4 > 0:
				var _padding := file.get_8()
			array_02.append(entry)
			continue
		var font_color := file.get_8()
		var string := ""
		#for i in range(length_str-5):
			#string += String.chr(file.get_8())
		string = file.get_line()
		while file.get_position() % 2 > 0:
			var _padding := file.get_8()
		#print("Length: %s, Timestamp: %s, Color: %s, String: %s" % [length, timestamp, font_color, string])
		subtitle["entries"].append({
			#"length": length,
			"timestamp": timestamp,
			"font_color": font_color,
			"string": string,
		})
	return {
		"game": array_01,
		"videos": array_02,
	}


static func get_at_offset(offset: int) -> Dictionary:
	var filepath: String = Roth.install_directory.path_join("..").path_join("DATA").path_join("DBASE400.DAT")
	if not FileAccess.file_exists(filepath):
		return {}
	var file := FileAccess.open(filepath, FileAccess.READ)
	file.seek(offset)
	var entry := Parser.parse_section(file, ARRAY01_ENTRY)
	entry.erase("length_str")
	file.close()
	return entry


static func get_entry_from_file(filepath: String, offset: int) -> Dictionary:
	if not FileAccess.file_exists(filepath):
		return {}
	var file := FileAccess.open(filepath, FileAccess.READ)
	file.seek(offset)
	var entry := Parser.parse_section(file, ARRAY01_ENTRY)
	entry.erase("length_str")
	file.close()
	return entry


static func get_subtitle_from_file(filepath: String, offset: int) -> Dictionary:
	if not FileAccess.file_exists(filepath):
		return {}
	var file := FileAccess.open(filepath, FileAccess.READ)
	file.seek(offset)
	var subtitle := {}
	subtitle["entries"] = []
	while file.get_position() < file.get_length():
		var length := file.get_16()
		var timestamp := file.get_16()
		if timestamp == 0xFFFF:
			print("0xFFFF")
			break
			var entry: Dictionary = Parser.parse_section(file, ARRAY01_ENTRY)
			entry.erase("length_str")
			while file.get_position() % 2 > 0:
				file.get_8()
			subtitle["title_entry"] = entry
			break
		if length == 0:
			file.seek(file.get_position()-2)
			continue
		var font_color := file.get_8()
		var string := file.get_buffer(length-5).get_string_from_ascii()
		while file.get_position() % 2 > 0:
			file.get_8()
		subtitle["entries"].append({
			"timestamp": timestamp,
			"font_color": font_color,
			"string": string,
		})
	file.close()
	return subtitle


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
		var bytes := file.get_buffer(length-5)
		#var bytes := PackedByteArray()
		#var byte: int = file.get_8()
		#while byte != 0:
			#bytes.append(byte)
			#byte = file.get_8()
		string = bytes.get_string_from_ascii()
		while file.get_position() % 2 > 0:
			var _padding := file.get_8()
		#if length != len(string) + 5:
			#print(length - (len(string) + 5), " ", string)
			##print({
				##"length": length,
				##"timestamp": timestamp,
				##"font_color": font_color,
				##"string": string,
			##})
		subtitle["entries"].append({
			#"length": length,
			"timestamp": timestamp,
			"font_color": font_color,
			"string": string,
		})
	
	file.seek(position)
	return subtitle


# Array.has() or the 'in' keyword only checks for the same value.
# This will check for the same ref.
static func text_entry_in_array(p_text_array: Array, p_text_entry: Dictionary) -> bool:
	for text_entry: Dictionary in p_text_array:
		if is_same(text_entry, p_text_entry):
			return true
	return false


static func compile(dbase100: Dictionary) -> PackedByteArray:
	
	# Assemble text array
	# Even though we have dbase100.text_entrys, we reassemble
	# so as to not include any orphan text entries
	var text_array := []
	for interface: Dictionary in dbase100.interfaces:
		if (not interface.text_entry.is_empty()
				and not text_entry_in_array(text_array, interface.text_entry)
		):
			text_array.append(interface.text_entry)
	for inventory_item: Dictionary in dbase100.inventory:
		if (not inventory_item.text_entry.is_empty()
				and not text_entry_in_array(text_array, inventory_item.text_entry)
		):
			text_array.append(inventory_item.text_entry)
		for action: Dictionary in inventory_item.actions_section:
			for command: Dictionary in action.commands:
				if (command.opcode == 5
						or command.opcode == 8
						or command.opcode == 15
						or command.opcode == 16
				):
					if (not command.text_entry.is_empty()
							and not text_entry_in_array(text_array, command.text_entry)
					):
						text_array.append(command.text_entry)
	for action: Dictionary in dbase100.actions:
		for command: Dictionary in action.commands:
			if (command.opcode == 5
					or command.opcode == 8
					or command.opcode == 15
					or command.opcode == 16
			):
				if (not command.text_entry.is_empty()
						and not text_entry_in_array(text_array, command.text_entry)
				):
					text_array.append(command.text_entry)
	
	# Don't even update text_entrys, reselecting orphans will work fine until reload
	#dbase100.text_entrys = text_array
	
	
	# Calculate length and offsets
	# We could do this at the same time we assemble 
	# but this is simpler
	var length: int = 8
	for text_entry: Dictionary in text_array:
		text_entry["offset"] = length
		text_entry["length_str"] = len(text_entry.string) + 1
		length += 8 + text_entry["length_str"]
		while length % 4 > 0:
			length +=  1
	
	
	
	
	
	# Calculate subtitle lengths and offsets
	for cutscene: Dictionary in dbase100.cutscenes:
		cutscene.computed_length_subtitles = 0
		cutscene.offset_dbase400_subtitles = 0
		cutscene.offset_dbase400 = 0
		if "subtitles" in cutscene and not cutscene.subtitles.is_empty():
			cutscene.computed_length_subtitles = 4
			cutscene.offset_dbase400_subtitles = length
			for entry: Dictionary in cutscene.subtitles.entries:
				entry["length"] = len(entry.string) + 6
				length += len(entry.string) + 6
				while length % 2 > 0:
					length += 1
					entry["length"] += 1
				cutscene.computed_length_subtitles += entry["length"]
			length += 4
		if "text_entry" in cutscene and not cutscene.text_entry.is_empty():
			cutscene.offset_dbase400 = length
			cutscene.text_entry["length_str"] = len(cutscene.text_entry.string) + 1
			length += 8 + cutscene.text_entry["length_str"]
			while length % 4 > 0:
				length += 1
	
	
	var data := "DBASE400".to_ascii_buffer()
	data.resize(length)
	
	var position: int = 8
	for text_entry: Dictionary in text_array:
		data.encode_u32(position, text_entry.dbase500_offset)
		data.encode_u16(position+4, text_entry.length_str)
		data.encode_u16(position+6, text_entry.font_color)
		position += 8
		for value: int in text_entry.string.to_ascii_buffer():
			data.encode_u8(position, value)
			position += 1
		data.encode_u8(position, 0)
		position += 1
		while position % 4 > 0:
			data.encode_u8(position, 0)
			position += 1
	
	
	for cutscene: Dictionary in dbase100.cutscenes:
		if "subtitles" in cutscene and not cutscene.subtitles.is_empty():
			for entry: Dictionary in cutscene.subtitles.entries:
				data.encode_u16(position, entry.length)
				data.encode_u16(position+2, entry.timestamp)
				data.encode_u8(position+4, entry.font_color)
				position += 5
				for value: int in entry.string.to_ascii_buffer():
					data.encode_u8(position, value)
					position += 1
				data.encode_u8(position, 0)
				position += 1
				while position % 2 > 0:
					data.encode_u8(position, 0)
					position += 1
			data.encode_u16(position, 0)
			data.encode_u16(position+2, 0xFFFF)
			position += 4
		if "text_entry" in cutscene and not cutscene.text_entry.is_empty():
			data.encode_u32(position, cutscene.text_entry.dbase500_offset)
			data.encode_u16(position+4, cutscene.text_entry.length_str)
			cutscene.text_entry.erase("length_str")
			data.encode_u16(position+6, cutscene.text_entry.font_color)
			position += 8
			for value: int in cutscene.text_entry.string.to_ascii_buffer():
				data.encode_u8(position, value)
				position += 1
			data.encode_u8(position, 0)
			position += 1
			while position % 4 > 0:
				data.encode_u8(position, 0)
				position += 1
	
	
	# Remove length from text array
	for text_entry: Dictionary in text_array:
		text_entry.erase("length_str")
	
	
	return data
