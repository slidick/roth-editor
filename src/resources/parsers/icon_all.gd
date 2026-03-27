extends Node
class_name IconsAll

const ICON_HEADER := {
	"offset": Parser.Type.DWord,
	"size": Parser.Type.DWord,
}

const RLE_IMG_HDR := {
	"imgType": Parser.Type.Word,
	"xOffset": Parser.Type.Byte,
	"yOffset": Parser.Type.Byte,
	"width": Parser.Type.Word,
	"height": Parser.Type.Word,
}


static func get_icon_offsets() -> Array:
	var icon_filepath: String =  Roth.install_directory.path_join("..").path_join("DATA").path_join("DATA").path_join("ICONS.ALL")
	if not FileAccess.file_exists(icon_filepath):
		return []
	var file := FileAccess.open(icon_filepath, FileAccess.READ)
	
	var first_offset: int = file.get_32()
	file.seek(0)
	var offsets := []
	for i in range(first_offset/float(8)):
		var icon_header := Parser.parse_section(file, ICON_HEADER)
		offsets.append(icon_header.offset)
	
	return offsets


static func get_at_offset(offset: int) -> Variant:
	var icon_filepath: String =  Roth.install_directory.path_join("..").path_join("DATA").path_join("DATA").path_join("ICONS.ALL")
	if not FileAccess.file_exists(icon_filepath):
		return
	var palette: Array = Das.DEFAULT_PALETTE
	if palette.is_empty():
		return
	var file := FileAccess.open(icon_filepath, FileAccess.READ)
	
	file.seek(offset)
	var rle_image_hdr := Parser.parse_section(file, RLE_IMG_HDR)
	return RLE.decode_rle_img(rle_image_hdr, file, palette)


static func parse_for_editing(icon_filepath: String) -> Array:
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
	for offset: Dictionary in offsets:
		file.seek(offset.offset)
		data.append({
			"header": Parser.parse_section(file, RLE_IMG_HDR),
			"rle_data": file.get_buffer(offset.size-8)
		})
	
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
		data.encode_u16(offset_position, entry.header.imgType)
		data.encode_u8(offset_position+2, entry.header.xOffset)
		data.encode_u8(offset_position+3, entry.header.yOffset)
		data.encode_u16(offset_position+4, entry.header.width)
		data.encode_u16(offset_position+6, entry.header.height)
		offset_position += 8
		for byte: int in entry.rle_data:
			data.encode_u8(offset_position, byte)
			offset_position += 1
		while offset_position % 4 != 0:
			offset_position += 1
	
	return data
