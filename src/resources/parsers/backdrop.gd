extends Node
class_name Backdrop

static func parse() -> Variant:
	var backdrop_filepath: String =  Roth.directory.path_join("..").path_join("DATA").path_join("DATA").path_join("BACKDROP.RAW")
	if not FileAccess.file_exists(backdrop_filepath):
		return 
	var palette: Array = Das.get_default_palette()
	if palette.is_empty():
		return
	var file := FileAccess.open(backdrop_filepath, FileAccess.READ)
	var rle_image_hdr := Parser.parse_section(file, DBase200.RLE_IMG_HDR)
	return Parser.decode_rle_img(rle_image_hdr, file, palette)
