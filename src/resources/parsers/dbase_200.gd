extends Node
class_name DBase200

const IMGTYPE_RLE = 0x03
const IMGTYPE_ROWBGN_LEN = 0x1E

const HEADER := {
	"signature": [Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char]
}

const RLE_IMG_HDR := {
	"imgType": Parser.Type.DWord,
	"width": Parser.Type.Word,
	"height": Parser.Type.Word,
}

const ROW_BGN_LEN_IMG_HDR := {
	#"imgType": Parser.Type.DWord,
	#"frameBufWidth": Parser.Type.Word,
	#"frameBufHeight": Parser.Type.Word,
	"numSubSprites": Parser.Type.Word,
	"currSubSpriteIdx": Parser.Type.Word,
	"currSubSpriteDataSize": Parser.Type.DWord,   # including this header
	"unk1": Parser.Type.Word,
	"width": Parser.Type.Word,
	"yOffset": Parser.Type.Word,      # from top to bottom
	"height": Parser.Type.Word,
}

const IMG_ROW_DEFS := {
	"startingOffset": Parser.Type.Word,   # the offset where to start drawing; skipped bytes(pixels) stay set to 0 (transparent)
	"pixelRun": Parser.Type.Word,         # the amount of pixels to copy at the offset specified in the field above
}


static func parse_full() -> Array:
	var dbase200_filepath: String =  Roth.install_directory.path_join("..").path_join("DATA").path_join("DBASE200.DAT")
	if not FileAccess.file_exists(dbase200_filepath):
		return []
	var palette: Array = Das.get_default_palette()
	if palette.is_empty():
		return []
	var file := FileAccess.open(dbase200_filepath, FileAccess.READ)
	var _header := Parser.parse_section(file, HEADER)
	
	var images := []
	while file.get_position() < file.get_length():
		var _size: int = file.get_32()
		var rle_image_hdr := Parser.parse_section(file, RLE_IMG_HDR)
		
		match rle_image_hdr["imgType"]:
			IMGTYPE_RLE:
				images.append(Parser.decode_rle_img(rle_image_hdr, file, palette))
			IMGTYPE_ROWBGN_LEN:
				images.append(_decode_row_bgn_img(rle_image_hdr, file, palette))
		
		var pos:int = file.get_position()
		pos = (pos + 7) & ~7
		file.seek(pos)
		
	return images


static func get_animation_offsets() -> Array:
	var dbase200_filepath: String =  Roth.install_directory.path_join("..").path_join("DATA").path_join("DBASE200.DAT")
	if not FileAccess.file_exists(dbase200_filepath):
		return []
	var file := FileAccess.open(dbase200_filepath, FileAccess.READ)
	var _header := Parser.parse_section(file, HEADER)
	var offsets := []
	while file.get_position() < file.get_length():
		var size: int = file.get_32()
		var rle_image_hdr := Parser.parse_section(file, RLE_IMG_HDR)
		file.seek(file.get_position() - 8)
		if rle_image_hdr["imgType"] == IMGTYPE_ROWBGN_LEN:
			offsets.append(file.get_position()-4)
		file.seek(file.get_position() + size)
		var pos:int = file.get_position()
		pos = (pos + 7) & ~7
		file.seek(pos)
	return offsets


static func get_at_offset(offset: int) -> Variant:
	var dbase200_filepath: String =  Roth.install_directory.path_join("..").path_join("DATA").path_join("DBASE200.DAT")
	if not FileAccess.file_exists(dbase200_filepath):
		return
	var palette: Array = Das.get_default_palette()
	if palette.is_empty():
		return
	
	var file := FileAccess.open(dbase200_filepath, FileAccess.READ)
	file.seek(offset)
	var _size := file.get_32()
	var rle_image_hdr := Parser.parse_section(file, RLE_IMG_HDR)
	match rle_image_hdr["imgType"]:
		IMGTYPE_RLE:
			return Parser.decode_rle_img(rle_image_hdr, file, palette)
		IMGTYPE_ROWBGN_LEN:
			return _decode_row_bgn_img(rle_image_hdr, file, palette)
	return


static func _decode_row_bgn_img(rle_image_hdr: Dictionary, file: FileAccess, palette: Array) -> Array:
	rle_image_hdr.merge(Parser.parse_section(file, ROW_BGN_LEN_IMG_HDR), true)
	var images: Array = []
	while rle_image_hdr.imgType == IMGTYPE_ROWBGN_LEN:
		var decoded_sprite_buffer: Array = []
		decoded_sprite_buffer.resize(rle_image_hdr.width * rle_image_hdr.height)
		decoded_sprite_buffer.fill(0)
		
		var src_index: int = file.get_position() + rle_image_hdr.height * 4 # sizeof(IMG_ROW_DEFS)
		var pos: int = file.get_position()
		var ending_pos: int = file.get_position() + rle_image_hdr.currSubSpriteDataSize - 24
		var row_start_index: int = 0
		
		for i in range(rle_image_hdr.height):
			file.seek(pos)
			var img_row_defs := Parser.parse_section(file, IMG_ROW_DEFS)
			pos = file.get_position()
			file.seek(src_index)
			for j in range(img_row_defs.pixelRun):
				var value: int = file.get_8()
				decoded_sprite_buffer[row_start_index+img_row_defs.startingOffset+j] = value
				src_index += 1
			row_start_index += rle_image_hdr.width
		
		var data: Array
		for pixel: int in decoded_sprite_buffer:
			data.append_array(palette[pixel])
			if palette[pixel] == [0,0,0] and pixel == 0:
				data.append(0)
			else:
				data.append(255)
		var image := Image.create_from_data(rle_image_hdr.width, rle_image_hdr.height, false, Image.FORMAT_RGBA8, data)
		images.append(image)
		
		file.seek(ending_pos)
		rle_image_hdr = Parser.parse_section(file, RLE_IMG_HDR)
		rle_image_hdr.merge(Parser.parse_section(file, ROW_BGN_LEN_IMG_HDR), true)
	
	if file.get_position() != file.get_length():
		file.seek(file.get_position()-24)
	
	return images
