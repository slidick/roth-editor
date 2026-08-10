extends Node
class_name IconsAll

const ALLOW_PARTIAL_TRANSPARENCY: Array = [
	true,
	true,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	true,
	true,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	false,
	false,
	true,
	false,
	true,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	false,
]

const ICON_HEADER := {
	"offset": Parser.Type.DWord,
	"size": Parser.Type.DWord,
}

const RLE_IMG_HDR := {
	"image_type": Parser.Type.Word,
	"x_offset": Parser.Type.Byte,
	"y_offset": Parser.Type.Byte,
	"width": Parser.Type.Word,
	"height": Parser.Type.Word,
}


static func parse(icon_filepath: String) -> Array:
	if not FileAccess.file_exists(icon_filepath):
		return []
	var file := FileAccess.open(icon_filepath, FileAccess.READ)
	var first_offset: int = file.get_32()
	file.seek(0)
	var offsets := []
	for i in range(first_offset/float(8)):
		var icon_header := Parser.parse_section(file, ICON_HEADER)
		offsets.append(icon_header)
	
	var data: Array = []
	for i in range(len(offsets)):
		var offset: Dictionary = offsets[i]
		file.seek(offset.offset)
		var icon_data: Dictionary = Parser.parse_section(file, RLE_IMG_HDR)
		icon_data["rle_data"] = file.get_buffer(offset.size-8)
		icon_data["raw_image"] = RLE.decode_rle_image(icon_data)
		icon_data["is_transparent"] = ALLOW_PARTIAL_TRANSPARENCY[i]
		data.append(icon_data)
	
	return data


static func compile(input: Array) -> PackedByteArray:
	var total_size: int = len(input) * 8
	for entry: Dictionary in input:
		entry.offset = total_size
		total_size += (len(entry.rle_data) + 8)
		while total_size % 4 != 0:
			total_size += 1
	var data := PackedByteArray()
	data.resize(total_size)
	var position: int = 0
	for entry: Dictionary in input:
		data.encode_u32(position, entry.offset)
		data.encode_u32(position + 4, len(entry.rle_data)+8)
		position += 8
		var offset_position: int = entry.offset
		data.encode_u16(offset_position, entry.image_type)
		data.encode_u8(offset_position+2, entry.x_offset)
		data.encode_u8(offset_position+3, entry.y_offset)
		data.encode_u16(offset_position+4, entry.width)
		data.encode_u16(offset_position+6, entry.height)
		offset_position += 8
		for byte: int in entry.rle_data:
			data.encode_u8(offset_position, byte)
			offset_position += 1
		while offset_position % 4 != 0:
			offset_position += 1
	
	return data
