extends Node
class_name Backdrop

const RLE_IMG_HDR := {
	"image_type": Parser.Type.Word,
	"x_offset": Parser.Type.Byte,
	"y_offset": Parser.Type.Byte,
	"width": Parser.Type.Word,
	"height": Parser.Type.Word,
}


static func parse(filepath: String) -> Dictionary:
	if not FileAccess.file_exists(filepath):
		return {}
	var file := FileAccess.open(filepath, FileAccess.READ)
	var data: Dictionary = Parser.parse_section(file, RLE_IMG_HDR)
	data["rle_data"] = file.get_buffer(file.get_length()-file.get_position())
	data["raw_image"] = RLE.decode_rle_image(data)
	return data


static func compile(input_data: Dictionary) -> PackedByteArray:
	var output_data := PackedByteArray()
	output_data.resize(8)
	output_data.encode_u16(0, input_data.image_type)
	output_data.encode_u8(2, input_data.x_offset)
	output_data.encode_u8(3, input_data.y_offset)
	output_data.encode_u16(4, input_data.width)
	output_data.encode_u16(6, input_data.height)
	output_data.append_array(input_data.rle_data)
	return output_data
