extends Node
class_name Backdrop


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
