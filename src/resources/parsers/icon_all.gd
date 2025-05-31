extends Node
class_name IconsAll

const ICON_HEADER := {
	"offset": Parser.Type.DWord,
	"size": Parser.Type.DWord,
}

const RLE_IMG_HDR := {
	"imgType": Parser.Type.Word,
	"unk": Parser.Type.Word,
	"width": Parser.Type.Word,
	"height": Parser.Type.Word,
}


static func get_icon_offsets() -> Array:
	var icon_filepath: String =  Roth.directory.path_join("..").path_join("DATA").path_join("DATA").path_join("ICONS.ALL")
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
	var icon_filepath: String =  Roth.directory.path_join("..").path_join("DATA").path_join("DATA").path_join("ICONS.ALL")
	if not FileAccess.file_exists(icon_filepath):
		return
	var palette: Array = Das.get_default_palette()
	if palette.is_empty():
		return
	var file := FileAccess.open(icon_filepath, FileAccess.READ)
	
	file.seek(offset)
	var rle_image_hdr := Parser.parse_section(file, RLE_IMG_HDR)
	return Parser.decode_rle_img(rle_image_hdr, file, palette)
