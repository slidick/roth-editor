extends Node
class_name DBase100

const DBASE100_HEADER := {
	"signature": [Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char],             # + 0x00
	"filesize": Parser.Type.DWord,                  # + 0x08
	"unk_dword_02": Parser.Type.DWord,              # + 0x0C
	"nb_dbase100_inventory": Parser.Type.DWord,     # + 0x10
	"dbase100_table_inventory": Parser.Type.DWord,  # + 0x14        // offset
	"nb_dbase100_action": Parser.Type.DWord,        # + 0x18
	"dbase100_table_action": Parser.Type.DWord,     # + 0x1C        // offset
	"nb_dbase400_cutscene": Parser.Type.DWord,      # + 0x20        // nb * 0x14
	"dbase400_table_cutscene": Parser.Type.DWord,   # + 0x24        // offset
	"nb_dbase400_interface": Parser.Type.DWord,     # + 0x28        // nb * 0x04
	"dbase400_table_interface": Parser.Type.DWord,  # + 0x2C        // offset
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
	"unk_word_01": Parser.Type.Word,
	"closeup_type": Parser.Type.Byte,           # 0x00 - simple object (infinitive looping), 0x09 - play once
	"item_type": Parser.Type.Byte,
	"unk_byte_02": Parser.Type.Byte,            # always 0
	"unk_byte_03": Parser.Type.Byte,            # always 0
	"closeup_image": Parser.Type.DWord,         # animated image in inventory
	"inventory_image": Parser.Type.DWord,       # image in inventory
	"offset_dbase400": Parser.Type.DWord,
	"add_length": Parser.Type.Word,
	"unk_byte_04": Parser.Type.Byte,            # always 0
	"unk_byte_05": Parser.Type.Byte,
	"unk_word_06": Parser.Type.Word,
	"unk_word_07": Parser.Type.Word,
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
	"command": Parser.Type.Byte,
}

static func parse() -> Dictionary:
	var dbase100_filepath: String =  Roth.install_directory.path_join("..").path_join("DATA").path_join("DBASE100.DAT")
	if not FileAccess.file_exists(dbase100_filepath):
		return {}
	var dbase400_filepath: String = Roth.install_directory.path_join("..").path_join("DATA").path_join("DBASE400.DAT")
	if not FileAccess.file_exists(dbase400_filepath):
		return {}
	
	var dbase100 := FileAccess.open(dbase100_filepath, FileAccess.READ)
	var dbase400 := FileAccess.open(dbase400_filepath, FileAccess.READ)
	
	var header := Parser.parse_section(dbase100, DBASE100_HEADER)
	#print(JSON.stringify(header, '\t', false))
	
	assert(dbase100.get_position() == header["dbase400_table_cutscene"])
	
	var cutscenes := []
	for i in range(header["nb_dbase400_cutscene"]):
		var cutscene := Parser.parse_section(dbase100, DBASE100_CUTSCENE_ENTRY)
		if cutscene["offset_dbase400"] != 0:
			dbase400.seek(cutscene["offset_dbase400"])
			cutscene["entry"] = Parser.parse_section(dbase400, DBase400.ARRAY01_ENTRY)
		if cutscene["offset_dbase400_subtitles"] != 0:
			dbase400.seek(cutscene["offset_dbase400_subtitles"])
			cutscene["subtitles"] = DBase400.parse_cutscene_subtitle(dbase400, cutscene["offset_dbase400_subtitles"])
		
		cutscenes.append(cutscene)
	
	assert(dbase100.get_position() == header["dbase400_table_interface"])
	
	var interfaces := []
	for i in range(header["nb_dbase400_interface"]):
		var interface := {}
		interface["offset"] = dbase100.get_32()
		dbase400.seek(interface["offset"])
		interface["subtitle"] = Parser.parse_section(dbase400, DBase400.ARRAY01_ENTRY)
		interfaces.append(interface)
	
	assert(dbase100.get_position() == header["dbase100_table_inventory"])
	
	var inventory := []
	for i in range(header["nb_dbase100_inventory"]):
		var offset: int = dbase100.get_32()
		var position: int = dbase100.get_position()
		dbase100.seek(offset)
		var inventory_item := Parser.parse_section(dbase100, DBASE100_INVENTORY_ENTRY)
		inventory_item["offset"] = offset
		if inventory_item["add_length"] > 0:
			inventory_item["additional_data"] = []
			for j in range(inventory_item["add_length"] / 2):
				inventory_item["additional_data"].append(dbase100.get_16())
		
		if inventory_item["offset_dbase400"] != 0:
			dbase400.seek(inventory_item["offset_dbase400"])
			inventory_item["subtitle"] = Parser.parse_section(dbase400, DBase400.ARRAY01_ENTRY)
			while dbase400.get_position() % 4 > 0:
				var _padding := dbase400.get_8()
			inventory_item["next_subtitle"] = Parser.parse_section(dbase400, DBase400.ARRAY01_ENTRY)
		
		if inventory_item["unk_word_06"] != 0:
			dbase400.seek(inventory_item["unk_word_06"])
			inventory_item["right_click"] = Parser.parse_section(dbase400, DBase400.ARRAY01_ENTRY)
		
		inventory.append(inventory_item)
		dbase100.seek(position)
	
	assert(dbase100.get_position() == header["dbase100_table_action"])
	
	var actions := []
	for i in range(header["nb_dbase100_action"]):
		var action := {}
		action["offset"] = dbase100.get_32()
		if action["offset"] != 0:
			var position: int = dbase100.get_position()
			dbase100.seek(action["offset"])
			#var v1: int = dbase100.get_8()
			#var v2: int = dbase100.get_8()
			#var v3: int = dbase100.get_8()
			#var c: int = dbase100.get_8()
			#var arg: int = (v3 << 16) + (v2 << 8) + v1
			#if c != 3:
				#print('C: ', c, ' A: ', arg)
			#dbase100.seek(action["offset"])
			action["length"] = dbase100.get_16()
			action["unk_word_00"] = dbase100.get_16()
			if action["length"] != 0:
				action["opcodes"] = []
				# Length includes header unless no opcodes??
				for j in range((action["length"] / 4) - 1):
					var opcode := Parser.parse_section(dbase100, DBASE_100_OPCODE)
					opcode["full_value"] = (opcode["value_3"] << 16) + (opcode["value_2"] << 8) + opcode["value_1"]
					action["opcodes"].append(opcode)
					
			dbase100.seek(position)
		actions.append(action)
	
	return {
		"header": header,
		"cutscenes": cutscenes,
		"inventory": inventory,
		"interfaces": interfaces,
		"actions": actions,
	}
