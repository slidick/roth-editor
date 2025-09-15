extends Node
class_name DBase100

const DBASE100_HEADER := {
	"signature": [Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char],             # + 0x00
	"filesize": Parser.Type.DWord,                  # + 0x08
	"unk_dword_02": Parser.Type.DWord,              # + 0x0C
	"inventory_count": Parser.Type.DWord,     # + 0x10
	"inventory_offset": Parser.Type.DWord,  # + 0x14        // offset
	"action_count": Parser.Type.DWord,        # + 0x18
	"action_offset": Parser.Type.DWord,     # + 0x1C        // offset
	"cutscene_count": Parser.Type.DWord,      # + 0x20        // nb * 0x14
	"cutscene_offset": Parser.Type.DWord,   # + 0x24        // offset
	"interface_count": Parser.Type.DWord,     # + 0x28        // nb * 0x04
	"interface_offset": Parser.Type.DWord,  # + 0x2C        // offset
	"unk_dword_11": Parser.Type.DWord,              # + 0x30
}

const DBASE100_CUTSCENE_ENTRY := {
	"name": [Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char],
	"unk_word_01": Parser.Type.Word,                  # Always 0 (Padding?)
	"length_subtitles": Parser.Type.Word,             # Zero if no subtitles
	"offset_dbase400": Parser.Type.DWord,      
	"offset_dbase400_subtitles": Parser.Type.DWord,   # Zero if no subtitles
}

const DBASE_100_INVENTORY_OFFSET := {
	"offset": Parser.Type.DWord,
}

const DBASE100_INVENTORY_ENTRY := {
	"length": Parser.Type.Word,
	"object_texture_index": Parser.Type.Word,
	"closeup_type": Parser.Type.Byte,           # 0x00 - simple object (infinitive looping), 0x09 - play once
	"item_type": Parser.Type.Byte,
	"unk_byte_02": Parser.Type.Byte,            # always 0
	"unk_byte_03": Parser.Type.Byte,            # always 0
	"closeup_image": Parser.Type.DWord,         # animated image in inventory
	"inventory_image": Parser.Type.DWord,       # image in inventory
	"offset_dbase400": Parser.Type.DWord,
	#"add_length": Parser.Type.Word,
	#"unk_byte_04": Parser.Type.Byte,            # always 0
	#"unk_byte_05": Parser.Type.Byte,
	#"unk_word_06": Parser.Type.Word,
	#"unk_word_07": Parser.Type.Word,
	#"unk_bytes_01"              / Bytes(lambda ctx: ctx.add_length)
}

const DBASE_100_ACTION_OFFSET := {
	"offset": Parser.Type.DWord,
}

const DBASE_100_ACTION_ENTRY := {
	"length": Parser.Type.Word,
	"unk_word_00": Parser.Type.Word,
	#"opcodes"                   / If(lambda ctx: ctx.length != 0, Array(lambda ctx: ctx.length / 4 - 1, dbase100_opcode))
}

const DBASE_100_OPCODE := {
	"value_1": Parser.Type.Byte,
	"value_2": Parser.Type.Byte,
	"value_3": Parser.Type.Byte,
	"opcode": Parser.Type.Byte,
}

static func parse() -> Dictionary:
	var dbase100_filepath: String =  Roth.install_directory.path_join("..").path_join("DATA").path_join("DBASE100.DAT")
	if not FileAccess.file_exists(dbase100_filepath):
		return {}
	var dbase400_filepath: String = Roth.install_directory.path_join("..").path_join("DATA").path_join("DBASE400.DAT")
	if not FileAccess.file_exists(dbase400_filepath):
		return {}
	return parse_files(dbase100_filepath, dbase400_filepath)


static func parse_files(dbase100_filepath: String, dbase400_filepath: String) -> Dictionary:
	var dbase100 := FileAccess.open(dbase100_filepath, FileAccess.READ)
	var dbase400 := FileAccess.open(dbase400_filepath, FileAccess.READ)
	
	var text_offsets: Dictionary = {}
	var text_entrys: Array = []
	var subtitle_entrys: Array = []
	
	var header := Parser.parse_section(dbase100, DBASE100_HEADER)
	#print(JSON.stringify(header, '\t', false))
	
	assert(dbase100.get_position() == header["cutscene_offset"])
	
	var cutscenes := []
	for i in range(header["cutscene_count"]):
		var cutscene := Parser.parse_section(dbase100, DBASE100_CUTSCENE_ENTRY)
		if cutscene["offset_dbase400"] != 0:
			dbase400.seek(cutscene["offset_dbase400"])
			cutscene["text_entry"] = Parser.parse_section(dbase400, DBase400.ARRAY01_ENTRY)
			cutscene["text_entry"].erase("length_str")
			#text_entrys.append(cutscene["text_entry"])
		else:
			cutscene["text_entry"] = {}
		if cutscene["offset_dbase400_subtitles"] != 0:
			dbase400.seek(cutscene["offset_dbase400_subtitles"])
			cutscene["subtitles"] = DBase400.parse_cutscene_subtitle(dbase400, cutscene["offset_dbase400_subtitles"])
			subtitle_entrys.append(cutscene["subtitles"])
		else:
			cutscene["subtitles"] = {}
		
		cutscenes.append(cutscene)
	
	assert(dbase100.get_position() == header["interface_offset"])
	
	var interfaces := []
	for i in range(header["interface_count"]):
		var interface := {}
		interface["offset"] = dbase100.get_32()
		if interface["offset"] != 0:
			dbase400.seek(interface["offset"])
			interface["text_entry"] = Parser.parse_section(dbase400, DBase400.ARRAY01_ENTRY)
			interface["text_entry"].erase("length_str")
			
			if interface["offset"] not in text_offsets:
				text_offsets[interface["offset"]] = interface["text_entry"]
				text_entrys.append(interface["text_entry"])
			else:
				interface["text_entry"] = text_offsets[interface["offset"]]
		else:
			interface["text_entry"] = {}
		interfaces.append(interface)
		interface.erase("offset")
	
	assert(dbase100.get_position() == header["inventory_offset"])
	
	var inventory := []
	for i in range(header["inventory_count"]):
		var offset: int = dbase100.get_32()
		var position: int = dbase100.get_position()
		dbase100.seek(offset)
		var inventory_item := Parser.parse_section(dbase100, DBASE100_INVENTORY_ENTRY)
		inventory_item["actions_section"] = []
		
		var v1 := dbase100.get_8()
		var v2 := dbase100.get_8()
		var v3 := dbase100.get_8() 
		var command_length := (v3 << 16) + (v2 << 8) + v1
		var command_trigger := dbase100.get_8()
		while command_length != 0:
			var action := {"trigger": command_trigger, "commands": []}
			command_length -= 4
			while command_length > 0:
				v1 = dbase100.get_8()
				v2 = dbase100.get_8()
				v3 = dbase100.get_8() 
				var command_args := (v3 << 16) + (v2 << 8) + v1
				var command_opcode := dbase100.get_8()
				var command := {"opcode": command_opcode, "args": command_args}
				action.commands.append(command)
				command_length -= 4
				if (command_opcode == 5 
						or command_opcode == 8
						or command_opcode == 15
						or command_opcode == 16
				):
					dbase400.seek(command_args)
					command["text_entry"] = Parser.parse_section(dbase400, DBase400.ARRAY01_ENTRY)
					command["text_entry"].erase("length_str")
					if command_args not in text_offsets:
						text_offsets[command_args] = command.text_entry
						text_entrys.append(command.text_entry)
					else:
						command["text_entry"] = text_offsets[command_args]
			v1 = dbase100.get_8()
			v2 = dbase100.get_8()
			v3 = dbase100.get_8() 
			command_length = (v3 << 16) + (v2 << 8) + v1
			command_trigger = dbase100.get_8()
			inventory_item["actions_section"].append(action)
		if inventory_item["offset_dbase400"] != 0:
			dbase400.seek(inventory_item["offset_dbase400"])
			inventory_item["text_entry"] = Parser.parse_section(dbase400, DBase400.ARRAY01_ENTRY)
			inventory_item["text_entry"].erase("length_str")
			if inventory_item["offset_dbase400"] not in text_offsets:
				text_offsets[inventory_item["offset_dbase400"]] = inventory_item["text_entry"]
				text_entrys.append(inventory_item["text_entry"])
			else:
				inventory_item["text_entry"] = text_entrys[text_entrys.find(inventory_item.text_entry)]
		else:
			inventory_item["text_entry"] = {}
		
		inventory_item.erase("length")
		inventory.append(inventory_item)
		dbase100.seek(position)
	
	assert(dbase100.get_position() == header["action_offset"])
	
	var actions := []
	for i in range(header["action_count"]):
		var action := {}
		action["offset"] = dbase100.get_32()
		action["commands"] = []
		if action["offset"] != 0:
			var position: int = dbase100.get_position()
			dbase100.seek(action["offset"])
			action["length"] = dbase100.get_16()
			action["unk_word_00"] = dbase100.get_16()
			if action["length"] != 0:
				# Length includes header unless no opcodes??
				for j in range((action["length"] / 4) - 1):
					var v1 := dbase100.get_8()
					var v2 := dbase100.get_8()
					var v3 := dbase100.get_8() 
					var command_args := (v3 << 16) + (v2 << 8) + v1
					var command_opcode := dbase100.get_8()
					var command := {"opcode": command_opcode, "args": command_args}
					action["commands"].append(command)
					if (command.opcode == 5 
							or command.opcode == 8
							or command.opcode == 15
							or command.opcode == 16
					):
						dbase400.seek(command.args)
						command["text_entry"] = Parser.parse_section(dbase400, DBase400.ARRAY01_ENTRY)
						command["text_entry"].erase("length_str")
						if command_args not in text_offsets:
							text_offsets[command_args] = command.text_entry
							text_entrys.append(command.text_entry)
						else:
							command["text_entry"] = text_offsets[command_args]
						
			dbase100.seek(position)
		action.erase("offset")
		action.erase("length")
		action.erase("unk_word_00")
		actions.append(action)
	
	
	return {
		"header": header,
		"cutscenes": cutscenes,
		"inventory": inventory,
		"interfaces": interfaces,
		"actions": actions,
		"text_entrys": text_entrys,
		"subtitle_entrys": subtitle_entrys
	}


static func parse_files_at_directory(directory: String) -> Dictionary:
	var dbase100_filepath: String =  directory.path_join("DBASE100.DAT")
	if not FileAccess.file_exists(dbase100_filepath):
		return {}
	var dbase400_filepath: String = directory.path_join("DBASE400.DAT")
	if not FileAccess.file_exists(dbase400_filepath):
		return {}
	
	return parse_files(dbase100_filepath, dbase400_filepath)


static func compile(dbase100: Dictionary) -> PackedByteArray:
	var section_sizes := calculate_section_sizes_and_offsets(dbase100)
	var data: PackedByteArray = "DBASE100".to_ascii_buffer()
	data.resize(section_sizes.total_size)
	var position: int = 8
	
	# Header
	data.encode_u32(position, section_sizes.total_size)
	data.encode_u32(position+4, dbase100.header.unk_dword_02)
	data.encode_u32(position+8, len(dbase100.inventory))
	data.encode_u32(position+12, section_sizes.inventory_list.starts_at)
	data.encode_u32(position+16, len(dbase100.actions))
	data.encode_u32(position+20, section_sizes.actions_list.starts_at)
	data.encode_u32(position+24, len(dbase100.cutscenes))
	data.encode_u32(position+28, section_sizes.cutscenes.starts_at)
	data.encode_u32(position+32, len(dbase100.interfaces))
	data.encode_u32(position+36, section_sizes.interfaces.starts_at)
	data.encode_u32(position+40, dbase100.header.unk_dword_11)
	position += 44
	
	
	
	# Cutscenes
	assert(position == section_sizes.cutscenes.starts_at)
	for cutscene: Dictionary in dbase100.cutscenes:
		var i: int = 0
		for value: int in cutscene.name.to_ascii_buffer():
			data.encode_u8(position, value)
			position += 1
			i += 1
		while i < 8:
			data.encode_u8(position, 0)
			position += 1
			i += 1
		
		data.encode_u16(position, 0) # unk_word_01
		data.encode_u16(position + 2, cutscene.computed_length_subtitles)
		data.encode_u32(position + 4, cutscene.offset_dbase400)
		data.encode_u32(position + 8, cutscene.offset_dbase400_subtitles)
		cutscene.erase("computed_length_subtitles")
		cutscene.erase("offset_dbase400")
		#cutscene.erase("offset_dbase400_subtitles")
		position += 12
	
	
	
	# Interface
	assert(position == section_sizes.interfaces.starts_at)
	for interface: Dictionary in dbase100.interfaces:
		if not interface.text_entry.is_empty():
			data.encode_u32(position, interface.text_entry.offset)
		else:
			data.encode_u32(position, 0)
		position += 4
	
	
	
	# Inventory List
	assert(position == section_sizes.inventory_list.starts_at)
	position += 4 * len(dbase100.inventory)
	
	
	# Actions List
	assert(position == section_sizes.actions_list.starts_at)
	position += 4 * len(dbase100.actions)
	
	# Inventory
	assert(position == section_sizes.inventory.starts_at)
	for item: Dictionary in dbase100.inventory:
		item.offset = position
		var length := 24
		for action: Dictionary in item.actions_section:
			length += 4 + (len(action.commands) * 4)
		data.encode_u16(position, length)
		data.encode_u16(position + 2, item.object_texture_index)
		data.encode_u8(position + 4, item.closeup_type)
		data.encode_u8(position + 5, item.item_type)
		data.encode_u8(position + 6, 0) # unk_byte_02
		data.encode_u8(position + 7, 0) # unk_byte_03
		data.encode_u32(position + 8, item.closeup_image)
		data.encode_u32(position + 12, item.inventory_image)
		
		if not item.text_entry.is_empty():
			data.encode_u32(position + 16, item.text_entry.offset)
		else:
			data.encode_u32(position + 16, 0)
		
		position += 20
		for action: Dictionary in item.actions_section:
			var v1 := (4 + len(action.commands) * 4) & 0xFF
			var v2 := ((4 + len(action.commands) * 4) & 0xFF00) >> 8
			var v3 := ((4 + len(action.commands) * 4) & 0xFF0000) >> 16
			data.encode_u8(position, v1)
			data.encode_u8(position + 1, v2)
			data.encode_u8(position + 2, v3)
			data.encode_u8(position + 3, action.trigger)
			position += 4
			for command: Dictionary in action.commands:
				if (command.opcode == 5
						or command.opcode == 8
						or command.opcode == 15
						or command.opcode == 16
				):
					if not command.text_entry.is_empty():
						command.args = command.text_entry.offset
					else:
						command.args = 0
				
				v1 = command.args & 0xFF
				v2 = (command.args & 0xFF00) >> 8
				v3 = (command.args & 0xFF0000) >> 16
				data.encode_u8(position, v1)
				data.encode_u8(position + 1, v2)
				data.encode_u8(position + 2, v3)
				data.encode_u8(position + 3, command.opcode)
				position += 4
		data.encode_u32(position, 0x00000000)
		position += 4
	
	
	# Actions
	assert(position == section_sizes.actions.starts_at)
	for action: Dictionary in dbase100.actions:
		if action.commands.is_empty():
			action.offset = 0
			continue
		action.offset = position
		var length := (len(action.commands) * 4) + 4
		var unk_word_00 := 768
		data.encode_u16(position, length)
		data.encode_u16(position + 2, unk_word_00)
		position += 4
		for command: Dictionary in action.commands:
			if (command.opcode == 5
					or command.opcode == 8
					or command.opcode == 15
					or command.opcode == 16
			):
				if not command.text_entry.is_empty():
					command.args = command.text_entry.offset
				else:
					command.args = 0
			
			var v1: int = command.args & 0xFF
			var v2: int = (command.args & 0xFF00) >> 8
			var v3: int = (command.args & 0xFF0000) >> 16
			data.encode_u8(position, v1)
			data.encode_u8(position + 1, v2)
			data.encode_u8(position + 2, v3)
			data.encode_u8(position + 3, command.opcode)
			position += 4
	
	
	# Inventory List
	position = section_sizes.inventory_list.starts_at
	assert(position == section_sizes.inventory_list.starts_at)
	for item: Dictionary in dbase100.inventory:
		data.encode_u32(position, item.offset)
		item.erase("offset")
		position += 4
	
	# Actions List
	assert(position == section_sizes.actions_list.starts_at)
	for action: Dictionary in dbase100.actions:
		data.encode_u32(position, action.offset)
		action.erase("offset")
		position += 4
	
	
	# Remove offsets from text array
	if "text_entrys" in dbase100:
		for text_entry: Dictionary in dbase100.text_entrys:
			text_entry.erase("offset")
	
	
	return data



static func calculate_section_sizes_and_offsets(dbase100: Dictionary) -> Dictionary:
	var header := {
		"starts_at": 0,
		"size": 52,
	}
	var cutscenes := {
		"starts_at": header.starts_at + header.size,
		"size": len(dbase100.cutscenes) * 20
	}
	var interfaces := {
		"starts_at": cutscenes.starts_at + cutscenes.size,
		"size": len(dbase100.interfaces) * 4
	}
	var inventory_list := {
		"starts_at": interfaces.starts_at + interfaces.size,
		"size": len(dbase100.inventory) * 4,
	}
	var actions_list := {
		"starts_at": inventory_list.starts_at + inventory_list.size,
		"size": len(dbase100.actions) * 4
	}
	
	
	var inventory_size: int = 0
	for item: Dictionary in dbase100.inventory:
		inventory_size += 24
		for action: Dictionary in item.actions_section:
			inventory_size += 4 + (len(action.commands) * 4)
	
	var inventory := {
		"starts_at": actions_list.starts_at + actions_list.size,
		"size": inventory_size,
	}
	
	var actions_size: int = 0
	for action: Dictionary in dbase100.actions:
		if not action.commands.is_empty():
			actions_size += (len(action.commands) * 4) + 4
	var actions := {
		"starts_at": inventory.starts_at + inventory.size,
		"size": actions_size,
	}
	
	return {
		total_size = actions.starts_at + actions.size,
		header = header,
		cutscenes = cutscenes,
		interfaces = interfaces,
		inventory_list = inventory_list,
		actions_list = actions_list,
		inventory = inventory,
		actions = actions,
	}
