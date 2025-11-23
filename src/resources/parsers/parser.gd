extends Object
class_name Parser


const Type := {
	Char="get_8",
	Byte="get_8",
	Word="get_16",
	DWord="get_32",
	SignedByte="get_8_signed",
	SignedWord="get_16_signed",
	SignedDWord="get_32_signed",
	String="get_line",
}


static func unsigned8_to_signed(unsigned: int) -> int:
	return (unsigned + (1 << 7)) % (1 << 8) - (1 << 7)


static func unsigned16_to_signed(unsigned: int) -> int:
	return (unsigned + (1 << 15)) % (1 << 16) - (1 << 15)


static func unsigned32_to_signed(unsigned: int) -> int:
	return (unsigned + (1 << 31)) % (1 << 32) - (1 << 31)


static func signed8_to_unsigned(signed: int) -> int:
	return signed & 0xFF


static func signed16_to_unsigned(signed: int) -> int:
	return signed & 0xFFFF


static func signed32_to_unsigned(signed: int) -> int:
	return signed & 0xFFFFFFFF


static func parse_section(file: FileAccess, section_definition: Dictionary) -> Dictionary:
	var section := {}
	for key: String in section_definition:
		section[key] = parse_section_value(file, section_definition[key])
	
	if section_definition == Raw.TEXTURE_MAPPING and section["type"] >= 0x80:
		section["additionalMetadata"] = {}
		for key: String in Raw.ADDITIONAL_METADATA:
			section["additionalMetadata"][key] = parse_section_value(file, Raw.ADDITIONAL_METADATA[key])
			
	if section_definition == Raw.COMMAND:
		section["args"] = []
		for i in range((section.size - 0x06) / 2):
			section["args"].append(file.get_16())
	return section


static func parse_section_value(file: FileAccess, type: Variant) -> Variant:
	match typeof(type):
		TYPE_ARRAY:
			var value: String = ""
			for sub: String in type:
				var c: int = file.call(sub)
				if c != 0:
					value += String.chr(c)
			return value
		TYPE_STRING:
			var call_string: String = type.trim_suffix("_signed")
			if call_string == "get_line":
				
				var bytes := PackedByteArray()
				var byte: int = file.get_8()
				while byte != 0:
					bytes.append(byte)
					byte = file.get_8()
				return bytes.get_string_from_ascii()
				
				#return file.call(call_string)
			var value: int = 0
			value = file.call(call_string)
			if type.ends_with("8_signed"):
				value = unsigned8_to_signed(value)
			if type.ends_with("16_signed"):
				value = unsigned16_to_signed(value)
			if type.ends_with("32_signed"):
				value = unsigned32_to_signed(value)
			return value
		_:
			return null


static func decode_rle_img(rle_image_hdr: Dictionary, file: FileAccess, palette: Array, with_alpha: bool = true) -> Image:
	var decoded_sprite_size: int = rle_image_hdr.width * rle_image_hdr.height
	if with_alpha:
		decoded_sprite_size *= 4
	else:
		decoded_sprite_size *= 3
	var decoded_sprite_buffer: Array = []
	decoded_sprite_buffer.resize(decoded_sprite_size)
	
	var dest_idx: int = 0
	while dest_idx < decoded_sprite_size:
		var byte: int = file.get_8()
		if byte > 0xF0:
			var pixel_count: int = byte & 0x0F
			var value: int = file.get_8()
			var pixel_value: Array = palette[value].duplicate()
			if palette[value] == [0,0,0] and value == 0:
				pixel_value.append(0)
			else:
				pixel_value.append(255)
			for i in range(pixel_count):
				decoded_sprite_buffer[dest_idx] = pixel_value[0]
				decoded_sprite_buffer[dest_idx+1] = pixel_value[1]
				decoded_sprite_buffer[dest_idx+2] = pixel_value[2]
				if with_alpha:
					decoded_sprite_buffer[dest_idx+3] = pixel_value[3]
					dest_idx += 4
				else:
					dest_idx += 3
		else:
			var pixel_value: Array = palette[byte].duplicate()
			if palette[byte] == [0,0,0] and byte == 0:
				pixel_value.append(0)
			else:
				pixel_value.append(255)
			decoded_sprite_buffer[dest_idx] = pixel_value[0]
			decoded_sprite_buffer[dest_idx+1] = pixel_value[1]
			decoded_sprite_buffer[dest_idx+2] = pixel_value[2]
			if with_alpha:
				decoded_sprite_buffer[dest_idx+3] = pixel_value[3]
				dest_idx += 4
			else:
				dest_idx += 3
	
	var image := Image.create_from_data(rle_image_hdr.width, rle_image_hdr.height, false, Image.FORMAT_RGBA8, decoded_sprite_buffer)
	
	return image
