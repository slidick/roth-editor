extends Node
class_name Backdrop

static func parse() -> Variant:
	var backdrop_filepath: String =  Roth.install_directory.path_join("..").path_join("DATA").path_join("DATA").path_join("BACKDROP.RAW")
	if not FileAccess.file_exists(backdrop_filepath):
		return 
	var palette: Array = Das.DEFAULT_PALETTE
	if palette.is_empty():
		return
	var file := FileAccess.open(backdrop_filepath, FileAccess.READ)
	var rle_image_hdr := Parser.parse_section(file, DBase200.RLE_IMG_HDR)
	return RLE.decode_rle_img(rle_image_hdr, file, palette)


static func compile(input_data: Dictionary) -> PackedByteArray:
	var output_data := PackedByteArray()
	output_data.resize(8)
	output_data.encode_u16(0, input_data.header.imgType)
	output_data.encode_u8(2, input_data.header.xOffset)
	output_data.encode_u8(3, input_data.header.yOffset)
	output_data.encode_u16(4, input_data.header.width)
	output_data.encode_u16(6, input_data.header.height)
	output_data.append_array(input_data.rle_data)
	return output_data
