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
				value += String.chr(file.call(sub))
			return value
		TYPE_STRING:
			var call_string: String = type.trim_suffix("_signed")
			if call_string == "get_line":
				return file.call(call_string)
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
