extends Node
class_name DBase200

const IMGTYPE_RLE = 0x03
const IMGTYPE_ROWBGN_LEN = 0x1E

const HEADER := {
	"signature": [Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char]
}

const RLE_IMG_HDR := {
	"image_type": Parser.Type.DWord,
	"width": Parser.Type.Word,
	"height": Parser.Type.Word,
}

const ROW_RLE_IMG_HDR := {
	"image_type": Parser.Type.DWord,
	"buffer_width": Parser.Type.Word,
	"buffer_height": Parser.Type.Word,
	"num_images": Parser.Type.Word,
	"current_image_idx": Parser.Type.Word,
	"current_image_size": Parser.Type.DWord,   # including this header
	"x_offset": Parser.Type.Word,
	"width": Parser.Type.Word,
	"y_offset": Parser.Type.Word,      # from top to bottom
	"height": Parser.Type.Word,
}


static func get_icons(dbase200_filepath: String) -> Array:
	if not FileAccess.file_exists(dbase200_filepath):
		return []
	var file := FileAccess.open(dbase200_filepath, FileAccess.READ)
	var _header := Parser.parse_section(file, HEADER)
	var data := []
	while file.get_position() < file.get_length():
		var size: int = file.get_32()
		var image := Parser.parse_section(file, RLE_IMG_HDR)
		match image.image_type:
			IMGTYPE_RLE:
				image["rle_data"] = file.get_buffer(size - 8)
				image["raw_image"] = RLE.decode_rle_image_data(image)
				data.append(image)
			IMGTYPE_ROWBGN_LEN:
				file.seek(file.get_position() - 8 + size)
			_:
				assert(false)
		
		var pos:int = file.get_position()
		pos = (pos + 7) & ~7
		file.seek(pos)
	
	return data


static func get_animation_offsets(dbase200_filepath: String) -> Array:
	if not FileAccess.file_exists(dbase200_filepath):
		return []
	var file := FileAccess.open(dbase200_filepath, FileAccess.READ)
	var _header := Parser.parse_section(file, HEADER)
	var offsets := []
	while file.get_position() < file.get_length():
		var size: int = file.get_32()
		var rle_image_hdr := Parser.parse_section(file, RLE_IMG_HDR)
		file.seek(file.get_position() - 8)
		if rle_image_hdr["image_type"] == IMGTYPE_ROWBGN_LEN:
			offsets.append(file.get_position()-4)
		file.seek(file.get_position() + size)
		var pos:int = file.get_position()
		pos = (pos + 7) & ~7
		file.seek(pos)
	return offsets


static func get_at_offset(dbase200_filepath: String, offset: int) -> Dictionary:
	if not FileAccess.file_exists(dbase200_filepath):
		return {}
	var file := FileAccess.open(dbase200_filepath, FileAccess.READ)
	file.seek(offset)
	var size := file.get_32()
	var data := Parser.parse_section(file, RLE_IMG_HDR)
	match data.image_type:
		IMGTYPE_RLE:
			data["rle_data"] = file.get_buffer(size - 8)
			data["raw_image"] = RLE.decode_rle_image_data(data)
		IMGTYPE_ROWBGN_LEN:
			file.seek(file.get_position() - 8)
			var sub_image: Dictionary = Parser.parse_section(file, ROW_RLE_IMG_HDR)
			data = {}
			data["animation_2"] = []
			# Some animations (pistol reload, shield) have an incorrectly defined num_images.
			# Engine doesn't seem to use that value though
			#for sub_image_index: int in range(num_images):
			while sub_image.image_type == IMGTYPE_ROWBGN_LEN:
				sub_image["encoded_image"] = file.get_buffer(sub_image.current_image_size - 24)
				sub_image["raw_image"] = RLE.decode_row_rle_image(sub_image)
				data["animation_2"].append(sub_image)
				sub_image = Parser.parse_section(file, ROW_RLE_IMG_HDR)
		_:
			return {}
	return data


static func compile(dbase100: Dictionary) -> PackedByteArray:
	# Gather unique icons and animations
	var unique_icons: Array = []
	var unique_animations: Array = []
	for inventory_item: Dictionary in dbase100.inventory:
		if inventory_item.image_data.is_empty():
			inventory_item.inventory_image = 0
		else:
			if inventory_item.image_data not in unique_icons:
				unique_icons.append(inventory_item.image_data)
		for action: Dictionary in inventory_item.actions_section:
			if action.trigger == 5:
				for command: Dictionary in action.commands:
					if command.opcode == 31 or command.opcode == 18:
						if command.data not in unique_animations:
							unique_animations.append(command.data)
	
	# Calculate sizes and offsets of animations
	var size: int = 8
	var animation_offsets: Array = []
	var animation_sizes: Array = []
	for animation: Dictionary in unique_animations:
		animation_offsets.append(int(size/8.0))
		var block_size: int = 0
		for frame: Dictionary in animation.animation_2:
			block_size += 24 # Header
			block_size += len(frame.encoded_image) # Data
		animation_sizes.append(block_size)
		size += block_size + 4 # w/size entry
		size = (size + 7) & ~7 # 8-byte align
	
	# Calculate sizes and offsets of icons
	var icon_offsets: Array = []
	var icon_sizes: Array = []
	for image_data: Dictionary in unique_icons:
		icon_offsets.append(int(size / 8.0))
		size += 4 # Size
		size += 8 # Header
		size += len(image_data.rle_data)
		icon_sizes.append(8 + len(image_data.rle_data))
		size = (size + 7) & ~7 # 8-byte align
	
	# Apply offsets to dbase100
	for inventory_item: Dictionary in dbase100.inventory:
		if not inventory_item.image_data.is_empty():
			assert(unique_icons.find(inventory_item.image_data) != -1)
			inventory_item.inventory_image = icon_offsets[unique_icons.find(inventory_item.image_data)] # Update animation offset
		for action: Dictionary in inventory_item.actions_section:
			if action.trigger == 5:
				for command: Dictionary in action.commands:
					if command.opcode == 31 or command.opcode == 18:
						assert(unique_animations.find(command.data) != -1)
						command.args = animation_offsets[unique_animations.find(command.data)] # Update animation offset
	
	
	var data: PackedByteArray = "DBASE200".to_ascii_buffer()
	data.resize(size)
	
	# Write animations
	for i in range(len(unique_animations)):
		var animation: Dictionary = unique_animations[i]
		var pos: int = animation_offsets[i]*8
		var block_size: int = animation_sizes[i]
		
		data.encode_u32(pos, block_size)
		pos += 4
		
		for j in range(len(animation.animation_2)):
			var frame: Dictionary = animation.animation_2[j]
			data.encode_u32(pos, frame.image_type)
			data.encode_u16(pos+4, frame.buffer_width)
			data.encode_u16(pos+6, frame.buffer_height)
			data.encode_u16(pos+8, len(animation.animation_2)) # num_images
			#data.encode_u16(pos+8, 555) # num_images
			data.encode_u16(pos+10, j) # current_image_idx
			data.encode_u32(pos+12, 24+len(frame.encoded_image)) # current_image_size
			data.encode_u16(pos+16, frame.x_offset)
			data.encode_u16(pos+18, frame.width)
			data.encode_u16(pos+20, frame.y_offset)
			data.encode_u16(pos+22, frame.height)
			pos += 24
			for byte: int in frame.encoded_image:
				data.encode_u8(pos, byte)
				pos += 1
	
	# Write icons
	for i in range(len(unique_icons)):
		var image_data: Dictionary = unique_icons[i]
		var pos: int = icon_offsets[i]*8
		var block_size: int = icon_sizes[i]
		
		data.encode_u32(pos, block_size)
		data.encode_u32(pos+4, image_data.image_type)
		data.encode_u16(pos+8, image_data.width)
		data.encode_u16(pos+10, image_data.height)
		pos += 12
		for byte: int in image_data.rle_data:
			data.encode_u8(pos, byte)
			pos += 1
	
	return data
