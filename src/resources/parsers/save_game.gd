extends Object
class_name SaveGame

const PLAYER_STATE: Dictionary = {
	"unk_0x00": Parser.Type.Word,             # 0x00
	"pos_x": Parser.Type.SignedWord,          # 0x02
	"unk_0x04": Parser.Type.Word,             # 0x04
	"pos_z": Parser.Type.SignedWord,          # 0x06
	"unk_0x08": Parser.Type.Word,             # 0x08
	"pos_y": Parser.Type.SignedWord,          # 0x0A
	"unk_0x0C": Parser.Type.Word,             # 0x0C
	"rotation": Parser.Type.Word,             # 0x0E
	"item_left_hand": Parser.Type.DWord,      # 0x10
	"item_right_hand": Parser.Type.DWord,     # 0x14
	"health": Parser.Type.DWord,              # 0x18
	"camera_tilt": Parser.Type.SignedDWord,   # 0x1C
	"unk_0x20": Parser.Type.DWord,            # 0x20
	"unk_0x24": Parser.Type.DWord,            # 0x24
	"unk_0x28": Parser.Type.Word,             # 0x28
	"unk_0x2A": Parser.Type.Word,             # 0x2A
	"unk_0x2C": Parser.Type.DWord,            # 0x2C
}


static func parse_filepath(filepath: String) -> Dictionary:
	var file := FileAccess.open(filepath, FileAccess.READ)
	var data: Dictionary = {}
	data["filepath"] = filepath
	data["filesize"] = file.get_length()
	data["header"] = file.get_32()
	data["entries"] = []
	while file.get_position() < file.get_length() - 4:
		var entry: Dictionary = {
			"type": file.get_16(),
		}
		data.entries.append(entry)
		match entry.type:
			0x02:
				entry.merge(_parse_player_state(file)) # PlayerState
			0x03:
				entry.merge(_parse_name(file)) # CurrentMap
			0x04:
				entry.merge(_parse_buffer(file)) # Unknown
			0x05:
				entry.merge(_parse_buffer(file)) # Unknown
			0x06:
				entry.merge(_parse_buffer(file)) # Unknown
			0x07:
				entry.merge(_parse_player_inventory(file)) # PlayerInventory
			0x08:
				entry.merge(_parse_name(file)) # MapName
			0x09:
				entry.merge(_parse_buffer(file)) # MapData
			0x0A:
				entry.merge(_parse_name(file)) # SaveName
			0x0B:
				entry.merge(_parse_screenshot(file)) # Screenshot
			0x0D:
				entry.merge(_parse_buffer(file)) # Unknown
			0x0E:
				entry.merge(_parse_buffer(file)) # Unknown
	
	data["footer"] = file.get_32()
	
	return data


static func compile_and_save(data: Dictionary) -> void:
	var buffer: PackedByteArray = compile(data)
	var file := FileAccess.open(data.filepath, FileAccess.WRITE)
	file.store_buffer(buffer)
	file.close()


static func compile(data: Dictionary) -> PackedByteArray:
	var buffer: PackedByteArray = []
	buffer.resize(_calculate_size(data))
	var pos: int = 0
	
	buffer.encode_u32(pos, data.header)
	pos += 4
	
	for entry: Dictionary in data.entries:
		buffer.encode_u16(pos, entry.type)
		buffer.encode_u16(pos+2, entry.size)
		pos += 4
		if "buffer" in entry:
			for byte: int in entry.buffer:
				buffer.encode_u8(pos, byte)
				pos += 1
		elif "item_left_hand" in entry:
			buffer.encode_u16(pos, entry.unk_0x00)
			buffer.encode_s16(pos+2, entry.pos_x)
			buffer.encode_u16(pos+4, entry.unk_0x04)
			buffer.encode_s16(pos+6, entry.pos_z)
			buffer.encode_u16(pos+8, entry.unk_0x08)
			buffer.encode_s16(pos+10, entry.pos_y)
			buffer.encode_u16(pos+12, entry.unk_0x0C)
			buffer.encode_u16(pos+14, entry.rotation)
			buffer.encode_u32(pos+16, entry.item_left_hand)
			buffer.encode_u32(pos+20, entry.item_right_hand)
			buffer.encode_u32(pos+24, entry.health)
			buffer.encode_s32(pos+28, entry.camera_tilt)
			buffer.encode_u32(pos+32, entry.unk_0x20)
			buffer.encode_u32(pos+36, entry.unk_0x24)
			buffer.encode_u16(pos+40, entry.unk_0x28)
			buffer.encode_u16(pos+42, entry.unk_0x2A)
			buffer.encode_u32(pos+44, entry.unk_0x2C)
			pos += 48
		elif "name" in entry:
			for byte: int in entry.name.to_ascii_buffer():
				buffer.encode_u8(pos, byte)
				pos += 1
			buffer.encode_u8(pos, 0)
			pos += 1
			if entry.type == 0x0A:
				pos += 48 - (entry.name.length() + 1)
			else:
				pos += 14 - (entry.name.length() + 1)
		elif "items" in entry:
			for item: Dictionary in entry.items:
				buffer.encode_u16(pos, item.item_id)
				buffer.encode_u16(pos+2, item.quantity)
				pos += 4
		elif "raw_image" in entry:
			buffer.encode_u32(pos, entry.image_type)
			buffer.encode_u16(pos+4, entry.width)
			buffer.encode_u16(pos+6, entry.height)
			pos += 8
			for byte: int in entry.raw_image:
				buffer.encode_u8(pos, byte)
				pos += 1
			for byte: int in entry.footer:
				buffer.encode_u8(pos, byte)
				pos += 1
		else:
			assert(false)
	
	buffer.encode_u32(pos, data.footer)
	pos += 4
	
	return buffer


static func _parse_buffer(file: FileAccess) -> Dictionary:
	var data: Dictionary = {
		"size": file.get_16(),
	}
	data["buffer"] = file.get_buffer(data.size)
	return data


static func _parse_name(file: FileAccess) -> Dictionary:
	var data: Dictionary = {
		"size": file.get_16(),
	}
	data["name"] = ""
	var stop_parsing: bool = false
	for i in range(data.size):
		var c: int = file.get_8()
		if c != 0 and not stop_parsing:
			data["name"] += String.chr(c)
		else:
			stop_parsing = true
	return data


static func _parse_screenshot(file: FileAccess) -> Dictionary:
	var data: Dictionary = {
		"size": file.get_16(),
	}
	data["image_type"] = file.get_32()
	data["width"] = file.get_16()
	data["height"] = file.get_16()
	data["raw_image"] = file.get_buffer(data.width * data.height)
	assert(data.width*data.height+8 == data.size-24)
	data["footer"] = file.get_buffer(24)
	return data


static func _parse_player_state(file: FileAccess) -> Dictionary:
	var data: Dictionary = {
		"size": file.get_16(),
	}
	return data.merged(Parser.parse_section(file, PLAYER_STATE))


static func _parse_player_inventory(file: FileAccess) -> Dictionary:
	var data: Dictionary = {
		"size": file.get_16(),
	}
	data["items"] = []
	for i in range(data.size/4):
		data.items.append({
			"item_id": file.get_16(),
			"quantity": file.get_16(),
		})
	return data


static func _calculate_size(data: Dictionary) -> int:
	var size: int = 8
	for entry: Dictionary in data.entries:
		size += 4
		if "buffer" in entry:
			entry.size = entry.buffer.size()
		elif "item_left_hand" in entry:
			entry.size = 0x30
		elif "name" in entry:
			if entry.type == 0x0A:
				entry.size = 48
			else:
				entry.size = 14
		elif "items" in entry:
			entry.size = (4 * len(entry.items))
		elif "raw_image" in entry:
			entry.size = 8 + entry.raw_image.size() + entry.footer.size()
		else:
			assert(false)
		size += entry.size
	return size
