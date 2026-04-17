extends Object
class_name Das

enum FLAGS_1 {
	FLAG_1 = (1<<0),
	SKY = (1<<1),
	MONSTER = (1<<2), # Needs directional flag
	FLAG_4 = (1<<3),
	FLAG_5 = (1<<4),
	DIRECTIONAL = (1<<5),
	FLAG_7 = (1<<6),
	FLAG_8 = (1<<7),
}

enum FLAGS_2 {
	FLAG_1 = (1<<0),
	FLAG_2 = (1<<1),
	FLAG_3 = (1<<2),
	FLAG_4 = (1<<3),
	FLAG_5 = (1<<4),
	FLAG_6 = (1<<5),
	FLAG_7 = (1<<6),
	FLAG_8 = (1<<7),
}

enum IMAGE_TYPE {
	ANIMATION = (1<<0),
	PALETTE_ZERO_OPAQUE = (1<<1),
	TRANSPARENT = (1<<2),
	MIRROR = (1<<3),
	FLAG_5 = (1<<4),
	FLAG_6 = (1<<5),
	FLAG_7 = (1<<6),
	OBJECT_DATA = (1<<7),
}

enum MODIFIER {
	FLAG_1 = (1<<0),
	FLAG_2 = (1<<1),
	FLAG_3 = (1<<2),
	FLAG_4 = (1<<3),
	DRAW_DOWNWARD = (1<<4),
	FLAG_6 = (1<<5),
	IMAGE_PACK = (1<<6),
	HALF_SIZE = (1<<7),
}

const DEFAULT_PALETTE := [
	[0, 0, 0], [0, 0, 0], [4, 69, 32], [73, 109, 81], [0, 81, 40], [53, 101, 65], [8, 61, 28], [0, 0, 0], [69, 49, 49], [0, 0, 0], [61, 40, 36], [0, 0, 0], [190, 130, 73], [0, 0, 0], [32, 16, 20], [0, 0, 0],
	[45, 130, 93], [0, 0, 0], [61, 45, 101], [0, 0, 0], [85, 45, 12], [0, 0, 0], [101, 121, 158], [0, 0, 0], [53, 138, 93], [0, 0, 0], [69, 36, 16], [0, 0, 0], [65, 61, 57], [0, 0, 0], [223, 174, 134], [0, 0, 0],
	[255, 178, 101], [202, 142, 77], [150, 105, 57], [97, 69, 36], [49, 32, 16], [0, 0, 0], [210, 113, 49], [186, 97, 40], [162, 85, 36], [138, 73, 28], [113, 61, 24], [89, 49, 16], [65, 32, 12], [45, 20, 8], [20, 8, 4], [0, 0, 0],
	[174, 198, 235], [65, 45, 93], [182, 206, 243], [45, 36, 81], [61, 61, 81], [28, 28, 40], [0, 0, 0], [113, 81, 190], [97, 69, 166], [81, 57, 142], [69, 49, 117], [53, 36, 93], [40, 28, 69], [24, 16, 45], [8, 4, 20], [0, 0, 0],
	[255, 255, 255], [235, 235, 235], [219, 219, 219], [202, 202, 202], [186, 186, 186], [166, 166, 166], [150, 150, 150], [134, 134, 134], [117, 117, 117], [97, 97, 97], [81, 81, 81], [65, 65, 65], [49, 49, 49], [28, 28, 28], [12, 12, 12], [0, 0, 0],
	[190, 215, 251], [0, 0, 0], [158, 186, 239], [0, 0, 0], [255, 255, 0], [231, 231, 0], [206, 206, 0], [182, 182, 0], [158, 158, 0], [138, 138, 0], [113, 113, 0], [89, 89, 0], [65, 65, 0], [40, 40, 0], [20, 20, 0], [0, 0, 0],
	[255, 227, 190], [134, 117, 101], [255, 243, 206], [113, 105, 97], [247, 206, 162], [0, 0, 0], [0, 0, 0], [255, 0, 0], [223, 0, 0], [190, 0, 0], [158, 0, 0], [125, 0, 0], [93, 0, 0], [61, 0, 0], [28, 0, 0], [0, 0, 0],
	[235, 186, 146], [206, 162, 130], [182, 142, 113], [154, 121, 93], [130, 101, 77], [101, 81, 61], [73, 57, 45], [49, 36, 28], [20, 16, 12], [0, 0, 0], [215, 130, 109], [105, 61, 53], [0, 0, 0], [247, 85, 0], [215, 73, 0], [182, 61, 0],
	[150, 49, 0], [121, 40, 0], [89, 28, 0], [57, 16, 0], [28, 4, 0], [0, 0, 0], [0, 174, 93], [0, 154, 81], [0, 134, 69], [0, 113, 61], [0, 93, 49], [0, 73, 36], [0, 53, 28], [0, 36, 16], [0, 16, 4], [0, 0, 0],
	[57, 28, 12], [57, 117, 89], [77, 40, 12], [45, 130, 93], [0, 32, 53], [57, 134, 93], [130, 57, 20], [53, 138, 93], [194, 154, 125], [223, 174, 134], [101, 57, 16], [81, 45, 101], [77, 20, 0], [97, 61, 142], [61, 49, 36], [89, 24, 134],
	[85, 69, 49], [109, 69, 150], [113, 93, 69], [117, 77, 158], [8, 45, 24], [134, 89, 166], [109, 32, 0], [142, 97, 178], [16, 8, 36], [49, 40, 81], [36, 24, 49], [57, 40, 77], [32, 20, 61], [49, 45, 73], [61, 57, 61], [36, 36, 36],
	[97, 77, 45], [45, 45, 45], [105, 85, 61], [24, 24, 24], [40, 16, 8], [121, 97, 73], [49, 24, 12], [89, 73, 65], [142, 113, 85], [57, 45, 65], [166, 134, 97], [45, 40, 61], [85, 61, 40], [36, 40, 61], [73, 73, 69], [61, 49, 73],
	[89, 89, 89], [61, 45, 69], [53, 53, 53], [81, 174, 146], [57, 40, 36], [53, 150, 138], [97, 36, 4], [77, 158, 134], [81, 24, 0], [69, 53, 130], [69, 16, 0], [93, 57, 154], [53, 24, 12], [146, 81, 36], [0, 65, 32], [178, 89, 32],
	[45, 40, 69], [0, 0, 125], [130, 97, 53], [130, 109, 231], [121, 85, 40], [142, 130, 235], [170, 117, 65], [142, 158, 251], [190, 186, 223], [0, 0, 0], [142, 174, 223], [0, 0, 0], [130, 162, 215], [0, 0, 0], [113, 142, 210], [0, 0, 0],
	[121, 146, 174], [101, 121, 158], [0, 85, 40], [162, 235, 85], [49, 97, 53], [16, 113, 93], [89, 105, 142], [85, 85, 146], [81, 85, 138], [85, 89, 150], [69, 69, 130], [97, 113, 142], [235, 158, 81], [251, 219, 0], [24, 202, 93], [255, 231, 0],
	[81, 223, 69], [20, 4, 0], [251, 198, 36], [0, 0, 0], [231, 134, 40], [0, 0, 0], [247, 125, 28], [0, 0, 0], [255, 202, 81], [0, 0, 0], [255, 170, 61], [0, 0, 0], [194, 138, 49], [0, 0, 0], [73, 85, 105], [113, 0, 202]
]

const DEFAULT_RAW_PALETTE: Array = [0, 0, 0, 0, 0, 0, 1, 17, 8, 18, 27, 20, 0, 20, 10, 13, 25, 16, 2, 15, 7, 0, 0, 0, 17, 12, 12, 0, 0, 0, 15, 10, 9, 0, 0, 0, 47, 32, 18, 0, 0, 0, 8, 4, 5, 0, 0, 0, 11, 32, 23, 0, 0, 0, 15, 11, 25, 0, 0, 0, 21, 11, 3, 0, 0, 0, 25, 30, 39, 0, 0, 0, 13, 34, 23, 0, 0, 0, 17, 9, 4, 0, 0, 0, 16, 15, 14, 0, 0, 0, 55, 43, 33, 0, 0, 0, 63, 44, 25, 50, 35, 19, 37, 26, 14, 24, 17, 9, 12, 8, 4, 0, 0, 0, 52, 28, 12, 46, 24, 10, 40, 21, 9, 34, 18, 7, 28, 15, 6, 22, 12, 4, 16, 8, 3, 11, 5, 2, 5, 2, 1, 0, 0, 0, 43, 49, 58, 16, 11, 23, 45, 51, 60, 11, 9, 20, 15, 15, 20, 7, 7, 10, 0, 0, 0, 28, 20, 47, 24, 17, 41, 20, 14, 35, 17, 12, 29, 13, 9, 23, 10, 7, 17, 6, 4, 11, 2, 1, 5, 0, 0, 0, 63, 63, 63, 58, 58, 58, 54, 54, 54, 50, 50, 50, 46, 46, 46, 41, 41, 41, 37, 37, 37, 33, 33, 33, 29, 29, 29, 24, 24, 24, 20, 20, 20, 16, 16, 16, 12, 12, 12, 7, 7, 7, 3, 3, 3, 0, 0, 0, 47, 53, 62, 0, 0, 0, 39, 46, 59, 0, 0, 0, 63, 63, 0, 57, 57, 0, 51, 51, 0, 45, 45, 0, 39, 39, 0, 34, 34, 0, 28, 28, 0, 22, 22, 0, 16, 16, 0, 10, 10, 0, 5, 5, 0, 0, 0, 0, 63, 56, 47, 33, 29, 25, 63, 60, 51, 28, 26, 24, 61, 51, 40, 0, 0, 0, 0, 0, 0, 63, 0, 0, 55, 0, 0, 47, 0, 0, 39, 0, 0, 31, 0, 0, 23, 0, 0, 15, 0, 0, 7, 0, 0, 0, 0, 0, 58, 46, 36, 51, 40, 32, 45, 35, 28, 38, 30, 23, 32, 25, 19, 25, 20, 15, 18, 14, 11, 12, 9, 7, 5, 4, 3, 0, 0, 0, 53, 32, 27, 26, 15, 13, 0, 0, 0, 61, 21, 0, 53, 18, 0, 45, 15, 0, 37, 12, 0, 30, 10, 0, 22, 7, 0, 14, 4, 0, 7, 1, 0, 0, 0, 0, 0, 43, 23, 0, 38, 20, 0, 33, 17, 0, 28, 15, 0, 23, 12, 0, 18, 9, 0, 13, 7, 0, 9, 4, 0, 4, 1, 0, 0, 0, 14, 7, 3, 14, 29, 22, 19, 10, 3, 11, 32, 23, 0, 8, 13, 14, 33, 23, 32, 14, 5, 13, 34, 23, 48, 38, 31, 55, 43, 33, 25, 14, 4, 20, 11, 25, 19, 5, 0, 24, 15, 35, 15, 12, 9, 22, 6, 33, 21, 17, 12, 27, 17, 37, 28, 23, 17, 29, 19, 39, 2, 11, 6, 33, 22, 41, 27, 8, 0, 35, 24, 44, 4, 2, 9, 12, 10, 20, 9, 6, 12, 14, 10, 19, 8, 5, 15, 12, 11, 18, 15, 14, 15, 9, 9, 9, 24, 19, 11, 11, 11, 11, 26, 21, 15, 6, 6, 6, 10, 4, 2, 30, 24, 18, 12, 6, 3, 22, 18, 16, 35, 28, 21, 14, 11, 16, 41, 33, 24, 11, 10, 15, 21, 15, 10, 9, 10, 15, 18, 18, 17, 15, 12, 18, 22, 22, 22, 15, 11, 17, 13, 13, 13, 20, 43, 36, 14, 10, 9, 13, 37, 34, 24, 9, 1, 19, 39, 33, 20, 6, 0, 17, 13, 32, 17, 4, 0, 23, 14, 38, 13, 6, 3, 36, 20, 9, 0, 16, 8, 44, 22, 8, 11, 10, 17, 0, 0, 31, 32, 24, 13, 32, 27, 57, 30, 21, 10, 35, 32, 58, 42, 29, 16, 35, 39, 62, 47, 46, 55, 0, 0, 0, 35, 43, 55, 0, 0, 0, 32, 40, 53, 0, 0, 0, 28, 35, 52, 0, 0, 0, 30, 36, 43, 25, 30, 39, 0, 21, 10, 40, 58, 21, 12, 24, 13, 4, 28, 23, 22, 26, 35, 21, 21, 36, 20, 21, 34, 21, 22, 37, 17, 17, 32, 24, 28, 35, 58, 39, 20, 62, 54, 0, 6, 50, 23, 63, 57, 0, 20, 55, 17, 5, 1, 0, 62, 49, 9, 0, 0, 0, 57, 33, 10, 0, 0, 0, 61, 31, 7, 0, 0, 0, 63, 50, 20, 0, 0, 0, 63, 42, 15, 0, 0, 0, 48, 34, 12, 0, 0, 0, 18, 21, 26, 28, 0, 50]

const DAS_HEADER := {
	das_id_str = [Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char], # "DASP"
	das_id_num = Parser.Type.Word,             # always 5
	size_fat = Parser.Type.Word,
	img_fat_offset = Parser.Type.DWord,
	palette_offset = Parser.Type.DWord,
	unk_0x10_offset = Parser.Type.DWord,
	filenames_offset = Parser.Type.DWord,
	filenames_size = Parser.Type.Word,
	directional_object_table_size = Parser.Type.Word,
	directional_object_table_offset = Parser.Type.DWord,
	unk_0x20 = Parser.Type.DWord,
	object_collision_section_offset = Parser.Type.DWord,
	monster_mapping_section_offset = Parser.Type.DWord,
	monster_mapping_section_size = Parser.Type.DWord,
	fat_block_1_count = Parser.Type.Word,
	fat_block_2_count = Parser.Type.Word,
	fat_block_3_count = Parser.Type.Word,
	fat_block_4_count = Parser.Type.Word,
	unk_0x38_offset = Parser.Type.DWord,
	unk_0x38_size = Parser.Type.Word,
	unk_0x40_size = Parser.Type.Word,
	unk_0x40_offset = Parser.Type.DWord,
}

const FILE_NAMES_HEADER := {
	section1_element_count = Parser.Type.Word,
	section2_element_count = Parser.Type.Word,
}

const FILE_NAMES_ENTRY := {
	size = Parser.Type.Word,
	index = Parser.Type.Word,
	name = Parser.Type.String,
	desc = Parser.Type.String,
}

const FAT_ENTRY := {
	offset = Parser.Type.DWord,
	size = Parser.Type.Word,
	flags_1 = Parser.Type.Byte,
	flags_2 = Parser.Type.Byte,
}

const IMAGE_STANDARD_HEADER := {
	modifier = Parser.Type.Byte,
	image_type = Parser.Type.Byte,
	width = Parser.Type.Word,
	height = Parser.Type.Word,
}

const IMAGE_COMPRESSED_1_HEADER := {
	modifier = Parser.Type.Byte,
	image_type = Parser.Type.Byte,
	width = Parser.Type.Word,
	height = Parser.Type.Word,
	total_block_size = Parser.Type.DWord,
	first_image_offset = Parser.Type.Word,     # relative to the start of this header
	num_sub_images = Parser.Type.Word,         # the amount of compressed images following the first uncompressed frame. 0xFFFE is type 2
	unk_0x0E = Parser.Type.Word,               # always 0xFFFF ?
	unk_0x10 = Parser.Type.Byte,               # always 0xFF   ?
	animation_speed = Parser.Type.Byte,
}

const IMAGE_COMPRESSED_2_HEADER := {
	modifier = Parser.Type.Byte,
	image_type = Parser.Type.Byte,
	width = Parser.Type.Word,
	height = Parser.Type.Word,
	unk_0x06 = Parser.Type.DWord,             # seems to be always 0
	unk_0x0A = Parser.Type.Word,
	unk_0x0C = Parser.Type.Word,       # if it's  not 0xFFFE, then this is an imgCompressed1Hdr type
	unk_0x0E = Parser.Type.Word,
}

const SUB_IMAGE_COMPRESSED_2_HEADER := {
	image_type = Parser.Type.Word,       # seems to be always 0x17
	unk_0x02 = Parser.Type.Word,            # seems to be always zero
	buf_width = Parser.Type.Word,
	buf_height = Parser.Type.Word,
	num_images = Parser.Type.Word,
	current_image_idx = Parser.Type.Word,
	current_image_size = Parser.Type.DWord,    # including this header
	unk_0x10 = Parser.Type.Word,
	width = Parser.Type.Word,
	unk_0x14 = Parser.Type.Word,
	height = Parser.Type.Word,
}

const IMAGE_PACK_HEADER := {
	modifier = Parser.Type.Byte,
	image_type = Parser.Type.Byte,
	width = Parser.Type.Word,
	height = Parser.Type.Word,
	size_of_offsets = Parser.Type.Byte,
	pack_type = Parser.Type.Byte,
}

const DIRECTIONAL_OBJECT_MAPPING_ENTRY := {
	header = Parser.Type.Word,
	dir_1_fat_idx = Parser.Type.Word,
	dir_2_fat_idx = Parser.Type.Word,
	dir_3_fat_idx = Parser.Type.Word,
	dir_4_fat_idx = Parser.Type.Word,
	dir_5_fat_idx = Parser.Type.Word,
	dir_6_fat_idx = Parser.Type.Word,
	dir_7_fat_idx = Parser.Type.Word,
	dir_8_fat_idx = Parser.Type.Word,
}

const MONSTER_MAPPING_ENTRY := {
	unk_0x00 = Parser.Type.DWord,
	flying_back = Parser.Type.Word,
	flying_back_right = Parser.Type.Word,
	flying_right = Parser.Type.Word,
	flying_front_right = Parser.Type.Word,
	flying_front = Parser.Type.Word,
	flying_front_left = Parser.Type.Word,
	flying_left = Parser.Type.Word,
	flying_back_left = Parser.Type.Word,
	walking_back = Parser.Type.Word,
	walking_back_right = Parser.Type.Word,
	walking_right = Parser.Type.Word,
	walking_front_right = Parser.Type.Word,
	walking_front = Parser.Type.Word,
	walking_front_left = Parser.Type.Word,
	walking_left = Parser.Type.Word,
	walking_back_left = Parser.Type.Word,
	attack1_back = Parser.Type.Word,
	attack1_back_right = Parser.Type.Word,
	attack1_right = Parser.Type.Word,
	attack1_front_right = Parser.Type.Word,
	attack1_front = Parser.Type.Word,
	attack1_front_left = Parser.Type.Word,
	attack1_left = Parser.Type.Word,
	attack1_back_left = Parser.Type.Word,
	attack2_back = Parser.Type.Word,
	attack2_back_right = Parser.Type.Word,
	attack2_right = Parser.Type.Word,
	attack2_front_right = Parser.Type.Word,
	attack2_front = Parser.Type.Word,
	attack2_front_left = Parser.Type.Word,
	attack2_left = Parser.Type.Word,
	attack2_back_left = Parser.Type.Word,
	on_damage_back = Parser.Type.Word,
	on_damage_back_right = Parser.Type.Word,
	on_damage_right = Parser.Type.Word,
	on_damage_front_right = Parser.Type.Word,
	on_damage_front = Parser.Type.Word,
	on_damage_front_left = Parser.Type.Word,
	on_damage_left = Parser.Type.Word,
	on_damage_back_left = Parser.Type.Word,
	dying_normal = Parser.Type.Word,
	dead_normal = Parser.Type.Word,
	dying_crit = Parser.Type.Word,
	dead_crit = Parser.Type.Word,
	spawn = Parser.Type.Word,
	unk_0x5E = Parser.Type.Word,
	unk_0x60 = Parser.Type.DWord,
	unk_0x64 = Parser.Type.DWord,
}

const THREE_DIMENSIONAL_OBJECT_HEADER := {
	modifier = Parser.Type.Byte,
	image_type = Parser.Type.Byte,
	max_bound_x = Parser.Type.Word,
	max_bound_y = Parser.Type.Word,
	unk_0x06 = Parser.Type.Word,
	unk_0x08 = Parser.Type.Word,
	unk_0x0A = Parser.Type.DWord,
	max_bound_z = Parser.Type.Word,
	unk_0x10 = Parser.Type.DWord,
	num_vertices = Parser.Type.Word,
}

const THREE_DIMENSIONAL_OBJECT_VERTEX_DATA := {
	pos_x = Parser.Type.SignedWord,
	pos_y = Parser.Type.SignedWord,
	pos_z = Parser.Type.SignedWord,
	padding1 = Parser.Type.DWord,
	padding2 = Parser.Type.DWord,
	padding3 = Parser.Type.Word,
}

const THREE_DIMENSIONAL_OBJECT_FACE_MAPPING_HEADER := {
	sig = [Parser.Type.Char, Parser.Type.Char, Parser.Type.Char, Parser.Type.Char],
	unk_0x04 = Parser.Type.Word,
	faces_array_size = Parser.Type.BigEndianWord,  # Includes 4 bytes post array padding
}

const THREE_DIMENSIONAL_OBJECT_FACE_HEADER := {
	size = Parser.Type.Word,
	unk_0x02 = Parser.Type.DWord,
	unk_0x06 = Parser.Type.Word,
	unk_0x08 = Parser.Type.Word,    # 0x00, 0x08, or 0x0E
	unk_0x0A = Parser.Type.Word,    # 0x00, 0x03, or 0x04
	texture_fat_index_base = Parser.Type.BigEndianWord,
	unk_0x0E = Parser.Type.Word,
	unk_0x10 = Parser.Type.Word,
	unk_0x10_2 = Parser.Type.DWord,
	render_flag_1 = Parser.Type.Byte,
	render_flag_2 = Parser.Type.Byte,
	unk_0x18 = Parser.Type.DWord,
	sub_texture_index = Parser.Type.Byte,
	unk_0x1D = Parser.Type.Byte,
	unk_0x1E = Parser.Type.Byte,
	unk_0x1F = Parser.Type.Byte,    # render related
	unk_0x20 = Parser.Type.DWord,   # render related
	unk_0x24 = Parser.Type.Word,    # render related
	unk_0x26 = Parser.Type.Word,    # render related
	unk_0x28 = Parser.Type.DWord,   # Only 0x00
	unk_0x2C = Parser.Type.DWord,   # Only 0x00
	unk_0x30 = Parser.Type.Word,    # Only 0x32
	unk_0x32 = Parser.Type.Word,    # Only 0x00
	edge_count = Parser.Type.Word,
}


static func load_das(das_info: Dictionary) -> Dictionary:
	Utility.deinit_shader()
	Roth.das_loading_started.emit()
	var thread := Thread.new()
	Console.print("Loading das: %s" % das_info.filepath)
	var _err: Error = thread.start(_load_das_thread.bind(das_info))
	var das: Dictionary = await Roth.das_loading_finished
	thread.wait_to_finish()
	return das


static func _load_das_thread(das_info: Dictionary) -> Dictionary:
	var file := FileAccess.open(das_info.filepath, FileAccess.READ)
	var das: Dictionary = {
		"das_info": das_info,
		"textures": [],
		"mapping": {},
	}
	
	# Header
	var header: Dictionary = Parser.parse_section(file, DAS_HEADER)
	das.header = header
	
	# Palette
	das.merge(_parse_palette(file, header.palette_offset))
	
	# Monster Mapping Section
	file.seek(header.monster_mapping_section_offset)
	var monster_mappings: Array = []
	for i in range(header.monster_mapping_section_size / 104):
		var monster_mapping: Dictionary = Parser.parse_section(file, MONSTER_MAPPING_ENTRY)
		monster_mappings.append(monster_mapping)
	das.monster_mappings = monster_mappings
	
	# Directional Objects
	var directional_mappings: Array = []
	for i in range(header.directional_object_table_size/20):
		file.seek(header.directional_object_table_offset + (header.directional_object_table_size/20*2) + (i*18))
		var directional_mapping: Dictionary = Parser.parse_section(file, DIRECTIONAL_OBJECT_MAPPING_ENTRY)
		directional_mappings.append(directional_mapping)
	das.directional_object_mappings = directional_mappings
	
	# Filenames
	file.seek(header.filenames_offset)
	var filenames_header: Dictionary = Parser.parse_section(file, FILE_NAMES_HEADER)
	for i in range(filenames_header.section1_element_count):
		var entry: Dictionary = Parser.parse_section(file, FILE_NAMES_ENTRY)
		das.textures.append(entry)
	for i in range(filenames_header.section2_element_count):
		var entry: Dictionary = Parser.parse_section(file, FILE_NAMES_ENTRY)
		das.textures.append(entry)
	
	# Load textures
	var i: int = 0
	for texture: Dictionary in das.textures:
		texture["das_info"] = das.das_info
		das.mapping[texture.index] = _load_texture_from_file(file, texture, das)
		i += 1
		Roth.das_loading_updated.emit.call_deferred(float(i) / len(das.textures), das_info)
	Roth.das_loading_finished.emit.call_deferred(das)
	Utility.deinit_shader()
	return das


static func get_index_from_das(das_info: Dictionary, index: int, p_range: int = 1) -> Array:
	#print("Getting index: %d from das: %s" %[index, das_info.name])
	
	# Init
	var das: Dictionary = {
		das_info = das_info
	}
	var file := FileAccess.open(das_info.filepath, FileAccess.READ)
	
	# Header
	var header: Dictionary = Parser.parse_section(file, DAS_HEADER)
	das.header = header
	
	# Palette
	das.merge(_parse_palette(file, header.palette_offset))
	
	# Monster Mapping Section
	file.seek(header.monster_mapping_section_offset)
	var monster_mappings: Array = []
	for i in range(header.monster_mapping_section_size / 104):
		var monster_mapping: Dictionary = Parser.parse_section(file, MONSTER_MAPPING_ENTRY)
		monster_mappings.append(monster_mapping)
	das.monster_mappings = monster_mappings
	
	# Directional Objects
	var directional_mappings: Array = []
	for i in range(header.directional_object_table_size/20):
		file.seek(header.directional_object_table_offset + (header.directional_object_table_size/20*2) + (i*18))
		var directional_mapping: Dictionary = Parser.parse_section(file, DIRECTIONAL_OBJECT_MAPPING_ENTRY)
		directional_mappings.append(directional_mapping)
	das.directional_object_mappings = directional_mappings
	
	# Textures
	var mappings := {}
	var texture_array: Array = []
	file.seek(header.filenames_offset)
	var filenames_header: Dictionary = Parser.parse_section(file, FILE_NAMES_HEADER)
	for i in range(filenames_header.section1_element_count):
		var entry: Dictionary = Parser.parse_section(file, FILE_NAMES_ENTRY)
		mappings[entry.index] = entry
	for i in range(filenames_header.section2_element_count):
		var entry: Dictionary = Parser.parse_section(file, FILE_NAMES_ENTRY)
		mappings[entry.index] = entry
	
	# Load requested textures
	for i in range(index, index+p_range):
		if i in mappings:
			var texture: Dictionary = _load_texture_from_file(file, mappings[i], das)
			texture["das_info"] = das_info
			texture_array.append(texture)
		else:
			texture_array.append({"index": i, "name": "Invalid", "desc": ""})
	
	return texture_array


static func _load_texture_from_file(file: FileAccess, texture: Dictionary, das: Dictionary) -> Dictionary:
	
	# Seek to FAT offset
	file.seek(das.header.img_fat_offset + (texture.index * 0x08))
	
	# Read FAT
	texture.merge(Parser.parse_section(file, FAT_ENTRY))
	
	# Seek to Data
	file.seek(texture.offset)
	
	# Read standard header
	texture.merge(Parser.parse_section(file, IMAGE_STANDARD_HEADER))
	
	# Parse as Monster
	if (texture.flags_1 & FLAGS_1.DIRECTIONAL > 0 and texture.flags_1 & FLAGS_1.MONSTER > 0):
		if das.das_info.is_ademo:
			var first_byte: int = das.monster_mappings[texture.flags_2].walking_front & 0xFF
			var second_byte: int = das.monster_mappings[texture.flags_2].walking_front >> 8
			var monster_index: int = first_byte | (((second_byte & 0x7F) - 0x12) << 8)
			texture.monster_index = monster_index
		else:
			texture.monster_index = das.monster_mappings[texture.flags_2].walking_front & 0x7FFF
		
	
	# Parse as Directional object
	elif texture.flags_1 & FLAGS_1.DIRECTIONAL > 0:
		if das.das_info.is_ademo:
			var first_byte: int = das.directional_object_mappings[texture.flags_2].dir_5_fat_idx & 0xFF
			var second_byte: int = das.directional_object_mappings[texture.flags_2].dir_5_fat_idx >> 8
			var directional_index: int = first_byte | (((second_byte & 0x7F) - 0x12) << 8)
			texture.directional_index = directional_index
		else:
			texture.directional_index = das.directional_object_mappings[texture.flags_2].dir_5_fat_idx & 0x7FFF
	
	# Return if no offset
	elif texture.offset == 0:
		return texture
	
	# Parse as animated image
	elif texture.image_type & IMAGE_TYPE.ANIMATION > 0:
		var _block_size := file.get_16()
		var _unk := file.get_16()
		var firstImgOffset := file.get_16()
		var img_type_2 := file.get_16()
		# Type 1
		if img_type_2 != 0xFFFE:
			file.seek(texture["offset"] + firstImgOffset)
			
			if texture.width == 0:
				das.loading_errors.append("Image has zero width. Index: %s, Name: %s" % [texture.index, texture.name])
				return texture
			
			if texture.height == 0:
				das.loading_errors.append("Image has zero height. Index: %s, Name: %s" % [texture.index, texture.name])
				return texture
			
			var _mod: int = file.get_8()
			var _type: int = file.get_8()
			var _w: int = file.get_16()
			var _h: int = file.get_16()
			
			var raw_img := file.get_buffer(texture.width * texture.height)
			var is_transparent: bool = _type & IMAGE_TYPE.TRANSPARENT > 0 or _type & IMAGE_TYPE.PALETTE_ZERO_OPAQUE == 0
			var data: Array = Utility.convert_palette_image(das.raw_palette, raw_img, is_transparent)
			var img := Image.create_from_data(texture.width, texture.height, false, Image.FORMAT_RGBA8 if is_transparent else Image.FORMAT_RGB8, data)
			var image_texture := ImageTexture.create_from_image(img)
			texture["image"] = image_texture
			texture["animation"] = [image_texture]
			for j in range(img_type_2):
				var finished := false
				var pos := 0
				while true:
					var code := file.get_8()
					if code == 0:
						code = file.get_8()
						if code == 0:
							finished = true
							break
						var value := file.get_8()
						for k in range(code):
							raw_img[pos+k] = value
						pos += code
					elif code > 0x80:
						code &= 0x7F
						pos += code
					elif code < 0x80:
						for k in range(code):
							raw_img[pos+k] = file.get_8()
						pos += code
					else:
						var code_word := file.get_16()
						if code_word == 0:
							break
						if code_word & 0x8000:
							code_word &= 0x3FFF
							var value := file.get_8()
							if value == 0:
								for k in range(code_word):
									raw_img[pos+k] = 0
							else:
								break
						
						pos += code_word
				
				if finished:
					break
				
				var data2: Array = Utility.convert_palette_image(das.raw_palette, raw_img, is_transparent)
				var img2 := Image.create_from_data(texture.width, texture.height, false, Image.FORMAT_RGBA8 if is_transparent else Image.FORMAT_RGB8, data2)
				var image_texture2 := ImageTexture.create_from_image(img2)
				texture["animation"].append(image_texture2)
		
		# Type 2
		else:
			file.seek(texture["offset"] + 16)
			
			texture["animation"] = []
			
			var starting_position: int = file.get_position()
			
			var sub_img_header := {}
			for key: String in SUB_IMAGE_COMPRESSED_2_HEADER:
				sub_img_header[key] = file.call(SUB_IMAGE_COMPRESSED_2_HEADER[key])
			
			var num_imgs: int = sub_img_header.num_images
			while num_imgs == sub_img_header.num_images:
				var img_size: int = sub_img_header.width * sub_img_header.height
				var img_buffer: Array = []
				img_buffer.resize(img_size)
				var pos := 0
				
				while pos < img_size:
					var byte := file.get_8()
					if byte > 0xF0:
						var count := byte & 0x0F
						var next_byte := file.get_8()
						for j in range(count):
							img_buffer[pos+j] = next_byte
						pos += count
					else:
						img_buffer[pos] = byte
						pos += 1
				
				var is_transparent: bool = texture.image_type & IMAGE_TYPE.TRANSPARENT > 0 or texture.image_type & IMAGE_TYPE.PALETTE_ZERO_OPAQUE == 0
				var data: Array = Utility.convert_palette_image(das.raw_palette, img_buffer, is_transparent)
				var img := Image.create_from_data(sub_img_header.width, sub_img_header.height, false, Image.FORMAT_RGBA8 if is_transparent else Image.FORMAT_RGB8, data)
				var image_texture := ImageTexture.create_from_image(img)
				texture["animation"].append(image_texture)
				
				file.seek(starting_position + sub_img_header.current_image_size)
				starting_position = file.get_position()
				
				for key: String in SUB_IMAGE_COMPRESSED_2_HEADER:
					sub_img_header[key] = file.call(SUB_IMAGE_COMPRESSED_2_HEADER[key])
			if len(texture["animation"]) > 0:
				texture["image"] = texture["animation"][0]
	
	# Parse as 3D object data
	elif texture.image_type & IMAGE_TYPE.OBJECT_DATA > 0:
		file.seek(texture.offset)
		
		var object_data := Parser.parse_section(file, THREE_DIMENSIONAL_OBJECT_HEADER)
		
		var vertex_array := []
		for i in range(object_data.num_vertices):
			var vertex_data := Parser.parse_section(file, THREE_DIMENSIONAL_OBJECT_VERTEX_DATA)
			var vertex := Vector3(vertex_data.pos_x, vertex_data.pos_y, vertex_data.pos_z)
			vertex_array.append(vertex)
		
		var faces_mapping_header := Parser.parse_section(file, THREE_DIMENSIONAL_OBJECT_FACE_MAPPING_HEADER)
		var current_size := 4
		var face_array := []
		while current_size < faces_mapping_header.faces_array_size:
			var face := Parser.parse_section(file, THREE_DIMENSIONAL_OBJECT_FACE_HEADER)
			current_size += 54
			face.edge_array = []
			for i in range(face.edge_count+1):
				face.edge_array.append(file.get_16())
				current_size += 2
			face_array.append(face)
		
		object_data["vertices"] = vertex_array
		object_data["faces_header"] = faces_mapping_header
		object_data["faces"] = face_array
		texture["object_data"] = object_data
	
	
	# Parse as directional images
	elif texture.modifier & MODIFIER.IMAGE_PACK > 0:
		var size_of_offsets: int = file.get_8()
		var pack_type: int = file.get_8()
		if pack_type & 128 > 0:
			var unique_offsets: Array = []
			for i in range(size_of_offsets/2.0):
				var offset: int = file.get_16()
				if offset & 0x7FF not in unique_offsets:
					unique_offsets.append(offset & 0x7FF)
			file.seek(texture["offset"] + 32)
			var alignment := file.get_position() & 0xF
			texture["image"] = []
			for i in range(len(unique_offsets)):
				var _modifier := file.get_8()
				var _type := file.get_8()
				var width := file.get_16()
				var height := file.get_16()
				var raw_img := file.get_buffer(width * height)
				if len(raw_img) == 0:
					print(texture)
				var is_transparent: bool = _type & IMAGE_TYPE.TRANSPARENT > 0 or _type & IMAGE_TYPE.PALETTE_ZERO_OPAQUE == 0
				var data: Array = Utility.convert_palette_image(das.raw_palette, raw_img, is_transparent)
				var img := Image.create_from_data(width, height, false, Image.FORMAT_RGBA8 if is_transparent else Image.FORMAT_RGB8, data)
				var image_texture := ImageTexture.create_from_image(img)
				texture["image"].append(image_texture)
				
				var lower_ptr_4_bits := file.get_position() & 0xF
				var pos := file.get_position()
				if lower_ptr_4_bits > alignment:
					pos = pos + (alignment + 0x10 - lower_ptr_4_bits)
				else:
					pos = pos + (alignment - lower_ptr_4_bits)
				file.seek(pos)
				
		
		# Parse as 3d object images pack
		else:
			file.seek(file.get_position() - 2)
			var numImgs := 0
			while file.get_16() != 0:
				numImgs += 1
			numImgs -= 1
			
			while file.get_8() == 0:
				pass
			file.seek(file.get_position() - 2)
			
			var alignment := file.get_position() & 0xF
			var _img_reference := file.get_8()
			var _type := file.get_8()
			var width := file.get_16()
			var height := file.get_16()
			texture["image"] = []
			for j in range(numImgs):
				#Console.print("3D Objs Textures: %s, ref: %s, type: %s, width: %s, height: %s" % [texture.name, img_reference, type, width, height])
				if width == 0:
					continue
				
				var raw_img := file.get_buffer(width * height)
				var is_transparent: bool = _type & IMAGE_TYPE.TRANSPARENT > 0 or _type & IMAGE_TYPE.PALETTE_ZERO_OPAQUE == 0
				var data: Array = Utility.convert_palette_image(das.raw_palette, raw_img, is_transparent)
				var img := Image.create_from_data(width, height, false, Image.FORMAT_RGBA8 if is_transparent else Image.FORMAT_RGB8, data)
				var image_texture := ImageTexture.create_from_image(img)
				texture["image"].append(image_texture)
				
				var lower_ptr_4_bits := file.get_position() & 0xF
				var pos := file.get_position()
				if lower_ptr_4_bits > alignment:
					pos = pos + (alignment + 0x10 - lower_ptr_4_bits)
				else:
					pos = pos + (alignment - lower_ptr_4_bits)
				file.seek(pos)
				
				_img_reference = file.get_8()
				_type = file.get_8()
				width = file.get_16()
				height = file.get_16()
	
	# Parse as plain image
	else:
		if texture.width == 0:
			das.loading_errors.append("Image has zero width. Index: %s, Name: %s" % [texture.index, texture.name])
			return texture
		if texture.height == 0:
			das.loading_errors.append("Image has zero height. Index: %s, Name: %s" % [texture.index, texture.name])
			return texture
		
		var raw_img := file.get_buffer(texture.width * texture.height)
		if len(raw_img) != texture.width * texture.height:
			das.loading_errors.append("Unexpected image mismatch! (Read past end of file) Expected: %s (%sx%s), Found: %s, Index: %s, Name: %s, Unk: %s" % [texture.width * texture.height, texture.width, texture.height, len(raw_img), texture.index, texture.name, texture.unk])
			return texture
		
		var is_transparent: bool = texture.image_type & IMAGE_TYPE.TRANSPARENT > 0 or texture.image_type & IMAGE_TYPE.PALETTE_ZERO_OPAQUE == 0
		var data: Array = Utility.convert_palette_image(das.raw_palette, raw_img, is_transparent)
		var img := Image.create_from_data(texture.width, texture.height, false, Image.FORMAT_RGBA8 if is_transparent else Image.FORMAT_RGB8, data)
		var image_texture := ImageTexture.create_from_image(img)
		texture["image"] = image_texture
	
	
	return texture


#region Parse for editing
static func parse_das(das_info: Dictionary) -> Dictionary:
	var file := FileAccess.open(das_info.filepath, FileAccess.READ)
	if not file:
		return {}
	
	var das: Dictionary = {
		"das_info": das_info
	}
	
	# Header
	das["header"] = Parser.parse_section(file, DAS_HEADER)
	
	# Palette
	if das.header.palette_offset != 0:
		das.merge(_parse_palette(file, das.header.palette_offset))
		das["palette_shading"] = _parse_palette_shading(file, das.header.palette_offset)
	else:
		das["palette"] = []
		das["raw_palette"] = []
		das["palette_shading"] = []
	
	
	# FAT
	das["fat_1"] = []
	var index: int = 0
	for i in range(das.header.fat_block_1_count):
		file.seek(das.header.img_fat_offset + (index*8))
		var data: Dictionary = _parse_fat(file, das_info.is_ademo, index)
		data.index = index
		if "data" in data:
			data.data.erase("shift_data")
		das["fat_1"].append(data)
		index += 1

	das["fat_2"] = []
	for i in range(das.header.fat_block_2_count):
		file.seek(das.header.img_fat_offset + (index*8))
		var data: Dictionary = _parse_fat(file, das_info.is_ademo, index)
		data.index = index
		if "data" in data:
			data.data.erase("shift_data")
		das["fat_2"].append(data)
		index += 1

	das["fat_3"] = []
	for i in range(das.header.fat_block_3_count):
		file.seek(das.header.img_fat_offset + (index*8))
		var data: Dictionary = _parse_fat(file, das_info.is_ademo, index)
		data.index = index
		if "data" in data:
			data.data.erase("shift_data")
		das["fat_3"].append(data)
		index += 1

	das["fat_4"] = []
	for i in range(das.header.fat_block_4_count):
		file.seek(das.header.img_fat_offset + (index*8))
		var data: Dictionary = _parse_fat(file, das_info.is_ademo, index)
		data.index = index
		das["fat_4"].append(data)
		index += 1
	
	
	# Filenames
	file.seek(das.header.filenames_offset)
	das["filenames_header"] = Parser.parse_section(file, FILE_NAMES_HEADER)
	das["filenames_1"] = []
	das["filenames_2"] = []
	for i in range(das.filenames_header.section1_element_count):
		var filename: Dictionary = Parser.parse_section(file, FILE_NAMES_ENTRY)
		if filename.index < len(das.fat_1):
			das.fat_1[filename.index]["filename"] = filename
		elif filename.index < len(das.fat_1) + len(das.fat_2):
			das.fat_2[filename.index-len(das.fat_1)]["filename"] = filename
		elif filename.index < len(das.fat_1) + len(das.fat_2) + len(das.fat_3):
			das.fat_3[filename.index-len(das.fat_1)-len(das.fat_2)]["filename"] = filename
		elif filename.index < len(das.fat_1) + len(das.fat_2) + len(das.fat_3) + len(das.fat_4):
			das.fat_4[filename.index-len(das.fat_1)-len(das.fat_2)-len(das.fat_3)]["filename"] = filename
		das["filenames_1"].append(filename)
	for i in range(das.filenames_header.section2_element_count):
		var filename: Dictionary = Parser.parse_section(file, FILE_NAMES_ENTRY)
		if filename.index < len(das.fat_1):
			das.fat_1[filename.index]["filename"] = filename
		elif filename.index < len(das.fat_1) + len(das.fat_2):
			das.fat_2[filename.index-len(das.fat_1)]["filename"] = filename
		elif filename.index < len(das.fat_1) + len(das.fat_2) + len(das.fat_3):
			das.fat_3[filename.index-len(das.fat_1)-len(das.fat_2)]["filename"] = filename
		elif filename.index < len(das.fat_1) + len(das.fat_2) + len(das.fat_3) + len(das.fat_4):
			das.fat_4[filename.index-len(das.fat_1)-len(das.fat_2)-len(das.fat_3)]["filename"] = filename
		das["filenames_2"].append(filename)
	
	
	# Directional Objects
	var directional_offsets: Array = []
	var directional_mappings: Array = []
	file.seek(das.header.directional_object_table_offset)
	for i in range(das.header.directional_object_table_size/20):
		directional_offsets.append(file.get_16())
	for i in range(das.header.directional_object_table_size/20):
		file.seek(das.header.directional_object_table_offset + (das.header.directional_object_table_size/20*2) + (i*18))
		#var relative_offset: int = file.get_16()
		#file.seek(das.header.directional_object_table_offset + relative_offset)
		
		var directional_mapping: Dictionary = Parser.parse_section(file, DIRECTIONAL_OBJECT_MAPPING_ENTRY)
		directional_mappings.append(directional_mapping)
	
	das["directional_object_mappings"] = directional_mappings
	
	
	
	# Object Collision
	file.seek(das.header.object_collision_section_offset)
	var object_collisions: Array = []
	for i in range(das.header.fat_block_3_count):
		var object_collision_data := {
			"raw_data": file.get_32(),
		}
		object_collisions.append(object_collision_data)
	das["object_collisions"] = object_collisions
	
	
	# Monster Mapping Section
	file.seek(das.header.monster_mapping_section_offset)
	var monster_mappings: Array = []
	for i in range(das.header.monster_mapping_section_size / 104):
		var monster_mapping: Dictionary = Parser.parse_section(file, MONSTER_MAPPING_ENTRY)
		monster_mappings.append(monster_mapping)
	das["monster_mappings"] = monster_mappings
	
	
	# Unk_0x10 Section
	if das.header.unk_0x10_offset != 0:
		file.seek(das.header.unk_0x10_offset)
		das["unk_0x10_section"] = {"raw_data": file.get_buffer(4096)}
	else:
		das["unk_0x10_section"] = {"raw_data": []}
	
	
	# Unk_0x38 Section
	if das.header.unk_0x38_offset != 0:
		file.seek(das.header.unk_0x38_offset)
		das["unk_0x38_section"] = {"raw_data": file.get_buffer(das.header.unk_0x38_size)}
	else:
		das["unk_0x38_section"] = {"raw_data": []}
	
	
	# Unk_0x40 Section
	if das.header.unk_0x40_offset != 0:
		file.seek(das.header.unk_0x40_offset)
		das["unk_0x40_section"] = {"raw_data": file.get_buffer(das.header.unk_0x40_size)}
	else:
		das["unk_0x40_section"] = {"raw_data": []}
	
	
	return das


static func _parse_palette(file: FileAccess, offset: int) -> Dictionary:
	if offset == 0:
		return {
			palette = DEFAULT_PALETTE,
			raw_palette = DEFAULT_RAW_PALETTE,
		}
	file.seek(offset)
	var palette: Array = []
	var raw_palette: PackedByteArray = file.get_buffer(256*3)
	for i in range(0, len(raw_palette), 3):
		palette.append([(raw_palette[i] * 259 + 33) >> 6, (raw_palette[i+1] * 259 + 33) >> 6, (raw_palette[i+2] * 259 + 33) >> 6 ])
	return {
		palette = palette,
		raw_palette = raw_palette,
	}


static func _parse_palette_shading(file: FileAccess, offset: int) -> Array:
	var palette_shading_tables := []
	file.seek(offset+2+(256*3))
	for i in range(322):
		var table := []
		for j in range(256):
			table.append(file.get_8())
		palette_shading_tables.append(table)
	return palette_shading_tables


static func _parse_fat(file: FileAccess, is_ademo: bool, index: int) -> Dictionary:
	var entry: Dictionary = Parser.parse_section(file, FAT_ENTRY)
	if entry.size != 0:
		if (entry.flags_1 & 32) > 0:
			pass
			#if is_ademo:
				#entry.shift_data = []
				#file.seek(file.get_position() - 4)
				#for i in range(2):
					#entry.shift_data.append(file.get_16())
			#entry["raw_data"] = file.get_buffer(entry.size*2)
			
		elif entry.offset > 0:
			file.seek(entry.offset)
			entry["data"] = _parse_image(file, is_ademo, index)
		else:
			assert(false)
	return entry


static func _parse_image(file: FileAccess, is_ademo: bool, _index: int) -> Dictionary:
	var modifier: int = file.get_8()
	var image_type: int = file.get_8()
	file.seek(file.get_position() - 2)
	var data: Dictionary = {}
	if image_type & IMAGE_TYPE.ANIMATION > 0:
		data = _parse_animated_image(file, is_ademo, _index)
	elif image_type & IMAGE_TYPE.OBJECT_DATA > 0:
		data = _parse_object_data(file, is_ademo)
	elif modifier & MODIFIER.IMAGE_PACK > 0:
		data = _parse_image_pack(file, is_ademo)
	else:
		data = _parse_standard_image(file, is_ademo)
	
	return data


static func _parse_standard_image(file: FileAccess, is_ademo: bool) -> Dictionary:
	var texture_data: Dictionary = {}
	if is_ademo:
		file.seek(file.get_position()-4)
		texture_data.shift_data = []
		for i in range(2):
			texture_data.shift_data.append(Parser.unsigned16_to_signed(file.get_16()))
	texture_data.merge(Parser.parse_section(file, IMAGE_STANDARD_HEADER))
	if texture_data.width == 0 or texture_data.height == 0:
		print("ZERO WIDTH OR HEIGHT")
		return {}
	var raw_img: PackedByteArray = file.get_buffer(texture_data.width * texture_data.height)
	if len(raw_img) != texture_data.width * texture_data.height:
		print("INCORRECT LENGTH READ")
		return {}
	texture_data["raw_image"] = raw_img

	return texture_data


static func _parse_animated_image(file: FileAccess, is_ademo: bool, _index: int) -> Dictionary:
	var texture_data: Dictionary = {}
	if is_ademo:
		file.seek(file.get_position()-4)
		texture_data.shift_data = []
		for i in range(2):
			texture_data.shift_data.append(Parser.unsigned16_to_signed(file.get_16()))
	var start_offset: int = file.get_position()
	texture_data.merge(Parser.parse_section(file, IMAGE_COMPRESSED_1_HEADER))
	if texture_data.num_sub_images != 0xFFFE:
		#Console.print("COMPRESS TYPE 1")
		texture_data["offsets_array"] = []
		for i in range(texture_data.num_sub_images):
			texture_data["offsets_array"].append(file.get_32())
		while file.get_position() != (start_offset + texture_data.first_image_offset):
			assert(file.get_8() == 0)
		assert(file.get_position() == (start_offset + texture_data.first_image_offset))
		texture_data.modifier_2 = file.get_8()
		texture_data.image_type_2 = file.get_8()
		texture_data.width_2 = file.get_16()
		texture_data.height_2 = file.get_16()
		if texture_data.width == 0 or texture_data.height == 0:
			print("ZERO WIDTH OR HEIGHT")
			return {}
		
		var raw_img := file.get_buffer(texture_data.width * texture_data.height)
		texture_data["animation"] = [raw_img.duplicate()]
		texture_data["offset_mapping"] = {}
		
		for j in range(texture_data.num_sub_images):
			#Console.print("SubImage: %s" % j)
			
			var current_offset: int = (file.get_position() - start_offset) + 10
			
			var finished := false
			var pos := 0
			while true:
				var code := file.get_8()
				if code == 0:
					code = file.get_8()
					if code == 0:
						finished = true
						break
					var value := file.get_8()
					#Console.print("Repeating Bytes")
					for k in range(code):
						raw_img[pos+k] = value
					pos += code
				elif code > 0x80:
					#Console.print("Moving forward")
					code &= 0x7F
					pos += code
				elif code < 0x80:
					#Console.print("Copying whole")
					for k in range(code):
						raw_img[pos+k] = file.get_8()
					pos += code
				else:
					var code_word := file.get_16()
					if code_word == 0:
						break
					if code_word & 0x8000:
						#Console.print("Codeword & 0x8000")
						code_word &= 0x3FFF
						var value := file.get_8()
						if value == 0:
							#Console.print("Repeating 0s")
							for k in range(code_word):
								raw_img[pos+k] = 0
						else:
							break
					else:
						pass
					pos += code_word
			if finished:
				break
			
			texture_data["offset_mapping"][current_offset] = raw_img.duplicate()
		
		for k in range(len(texture_data.offsets_array)):
			var offset: int = texture_data.offsets_array[k]
			if offset == 0:
				texture_data["animation"].append(texture_data["animation"][k])
			else:
				texture_data["animation"].append(texture_data.offset_mapping[offset])
		
		# Last frame is always same as first so remove it
		texture_data["animation"].pop_back()
		
	else:
		#Console.print("COMPRESS TYPE 2")
		texture_data.erase("unk_0x10")
		texture_data.erase("animation_speed")
		assert(file.get_position()-2 == start_offset+16)
		file.seek(start_offset + 16)
		texture_data["animation_2"] = []
		texture_data["raw_animation_2"] = []
		var starting_position: int = file.get_position()
		var sub_image_header := Parser.parse_section(file, SUB_IMAGE_COMPRESSED_2_HEADER)
		var num_imgs: int = sub_image_header.num_images
		while num_imgs == sub_image_header.num_images:
			file.seek(starting_position)
			texture_data["raw_animation_2"].append(file.get_buffer(sub_image_header.current_image_size))
			file.seek(starting_position + 24)
			var image_size: int = sub_image_header.width * sub_image_header.height
			var image_rid: Array = []
			image_rid.resize(image_size)
			var pos := 0
			while pos < image_size:
				var byte := file.get_8()
				if byte > 0xF0:
					var count := byte & 0x0F
					var next_byte := file.get_8()
					for j in range(count):
						image_rid[pos+j] = next_byte
					pos += count
				else:
					image_rid[pos] = byte
					pos += 1
			
			texture_data["animation_2"].append({"header": sub_image_header, "raw_image": image_rid})
			file.seek(starting_position + sub_image_header.current_image_size)
			starting_position = file.get_position()
			
			sub_image_header = Parser.parse_section(file, SUB_IMAGE_COMPRESSED_2_HEADER)
		
		file.seek(file.get_position()-24)
		
	
	
	return texture_data


static func _parse_image_pack(file: FileAccess, is_ademo: bool) -> Dictionary:
	var texture_data: Dictionary
	if is_ademo:
		file.seek(file.get_position()-4)
		texture_data.shift_data = []
		for i in range(2):
			texture_data.shift_data.append(Parser.unsigned16_to_signed(file.get_16()))
	
	var starting_offset: int = file.get_position()
	
	texture_data.merge(Parser.parse_section(file, IMAGE_PACK_HEADER))
	texture_data["offsets"] = []
	texture_data["offsets_flipped"] = []
	var unique_offsets: = []
	while true:
		var word: int = file.get_16()
		if word == 0:
			break
		texture_data.offsets.append(word & 0x7FF)
		if word & 0x7FF not in unique_offsets:
			unique_offsets.append(word & 0x7FF)
		texture_data.offsets_flipped.append((word & 0x8000) > 0)
	
	assert(file.get_16() == 0)
	assert(file.get_32() == 0)
	while (starting_offset - file.get_position()) % 16 != 0:
		file.get_8()
	
	texture_data["image_pack"] = []
	for _unique_offset: int in unique_offsets:
		var sub_image_data: Dictionary = Parser.parse_section(file, IMAGE_STANDARD_HEADER)
		sub_image_data["raw_image"] = file.get_buffer(sub_image_data.width * sub_image_data.height)
		texture_data["image_pack"].append(sub_image_data)
		
		while (starting_offset - file.get_position()) % 16 != 0:
			file.get_8()
	
	unique_offsets.sort()
	var offsets_mappings := {}
	for i in range(len(unique_offsets)):
		offsets_mappings[unique_offsets[i]] = i
	
	texture_data["offsets_index"] = []
	for offset: int in texture_data.offsets:
		texture_data.offsets_index.append(offsets_mappings[offset])
	
	return texture_data


static func _parse_object_data(file: FileAccess, is_ademo: bool) -> Dictionary:
	var object_data: Dictionary = {}
	if is_ademo:
		file.seek(file.get_position()-4)
		object_data.shift_data = []
		for i in range(2):
			object_data.shift_data.append(Parser.unsigned16_to_signed(file.get_16()))
	
	object_data.merge(Parser.parse_section(file, THREE_DIMENSIONAL_OBJECT_HEADER))
	
	var vertex_array := []
	for i in range(object_data.num_vertices):
		var vertex_data := Parser.parse_section(file, THREE_DIMENSIONAL_OBJECT_VERTEX_DATA)
		var vertex := Vector3i(vertex_data.pos_x, vertex_data.pos_y, vertex_data.pos_z)
		vertex_array.append(vertex)
	
	var faces_mapping_header := Parser.parse_section(file, THREE_DIMENSIONAL_OBJECT_FACE_MAPPING_HEADER)
	var current_size := 4
	var face_array := []
	while current_size < faces_mapping_header.faces_array_size:
		var face := Parser.parse_section(file, THREE_DIMENSIONAL_OBJECT_FACE_HEADER)
		current_size += 54
		face.edge_array = []
		for i in range(face.edge_count+1):
			face.edge_array.append(file.get_16())
			current_size += 2
		face_array.append(face)
	object_data["vertices"] = vertex_array
	object_data["faces_header"] = faces_mapping_header
	object_data["faces"] = face_array
	
	
	return object_data
#endregion

#region Compile
static func compile(das: Dictionary) -> PackedByteArray:
	# Calculate sizes and offsets
	var section_sizes: Dictionary = _calculate_section_sizes_and_offsets(das)
	if section_sizes.is_empty():
		return []
	
	
	#print(JSON.stringify(section_sizes, '\t', false))
	#print("Total size: ", section_sizes.total_size)
	
	
	# Initialize
	var data: PackedByteArray = []
	data.resize(section_sizes.total_size)
	var pos: int = 0
	
	# Header
	assert(pos == section_sizes.header.starts_at)
	data.encode_u8(pos, ord("D"))
	data.encode_u8(pos+1, ord("A"))
	data.encode_u8(pos+2, ord("S"))
	data.encode_u8(pos+3, ord("P"))
	data.encode_u16(pos+4, 5)
	data.encode_u16(pos+6, section_sizes.fat.size)
	data.encode_u32(pos+8, section_sizes.fat.starts_at)
	data.encode_u32(pos+12, section_sizes.palette.starts_at)
	data.encode_u32(pos+16, section_sizes.unk_0x10.starts_at)
	data.encode_u32(pos+20, section_sizes.filenames.starts_at)
	data.encode_u16(pos+24, section_sizes.filenames.size)
	data.encode_u16(pos+26, section_sizes.directional_objects.size)
	data.encode_u32(pos+28, section_sizes.directional_objects.starts_at)
	data.encode_u32(pos+32, das.header.unk_0x20)
	data.encode_u32(pos+36, section_sizes.object_collisions.starts_at)
	data.encode_u32(pos+40, section_sizes.monster_mappings.starts_at)
	data.encode_u32(pos+44, section_sizes.monster_mappings.size)
	data.encode_u16(pos+48, len(das.fat_1))
	data.encode_u16(pos+50, len(das.fat_2))
	data.encode_u16(pos+52, len(das.fat_3))
	data.encode_u16(pos+54, len(das.fat_4))
	data.encode_u32(pos+56, section_sizes.unk_0x38.starts_at)
	data.encode_u16(pos+60, section_sizes.unk_0x38.size)
	data.encode_u16(pos+62, section_sizes.unk_0x40.size)
	data.encode_u32(pos+64, section_sizes.unk_0x40.starts_at)
	pos += 68
	
	
	# FAT Table
	assert(pos == section_sizes.fat.starts_at)
	for fat_table: String in ["fat_1", "fat_2", "fat_3", "fat_4"]:
		for fat_entry: Dictionary in das[fat_table]:
			data.encode_u32(pos, fat_entry.offset)
			data.encode_u16(pos+4, fat_entry.size)
			data.encode_u8(pos+6, fat_entry.flags_1)
			data.encode_u8(pos+7, fat_entry.flags_2)
			pos += 8
	
	
	# Palette
	if section_sizes.palette.size > 0:
		assert(pos == section_sizes.palette.starts_at)
		for value: int in das.raw_palette:
			data.encode_u8(pos, value)
			pos += 1
		data.encode_u16(pos, 0) # Padding
		pos += 2
		for table: Array in das.palette_shading:
			for value: int in table:
				data.encode_u8(pos, value)
				pos += 1
	
	
	# Unk0x10
	if section_sizes.unk_0x10.size > 0:
		assert(pos == section_sizes.unk_0x10.starts_at)
		for byte: int in das.unk_0x10_section.raw_data:
			data.encode_u8(pos, byte)
			pos += 1
	
	
	# Data
	if section_sizes.data.size > 0:
		if das.das_info.is_ademo:
			pos += 4
		#pos = section_sizes.data.starts_at
		assert(pos == section_sizes.data.starts_at)
		for fat_table: String in ["fat_1", "fat_2", "fat_3", "fat_4"]:
			for data_entry: Dictionary in das[fat_table]:
				pos = _write_data_entry(data_entry, data, pos, das.das_info.is_ademo)
	
	
	# Directional Objects
	if section_sizes.directional_objects.size > 0:
		#pos = section_sizes.directional_objects.starts_at
		assert(pos == section_sizes.directional_objects.starts_at)
		for i in range(len(das.directional_object_mappings)):
			var offset: int = (len(das.directional_object_mappings)*2) + (i*18)
			data.encode_u16(pos, offset)
			pos += 2
		for directional_mapping: Dictionary in das.directional_object_mappings:
			data.encode_u16(pos, directional_mapping.header)
			data.encode_u16(pos+2, directional_mapping.dir_1_fat_idx)
			data.encode_u16(pos+4, directional_mapping.dir_2_fat_idx)
			data.encode_u16(pos+6, directional_mapping.dir_3_fat_idx)
			data.encode_u16(pos+8, directional_mapping.dir_4_fat_idx)
			data.encode_u16(pos+10, directional_mapping.dir_5_fat_idx)
			data.encode_u16(pos+12, directional_mapping.dir_6_fat_idx)
			data.encode_u16(pos+14, directional_mapping.dir_7_fat_idx)
			data.encode_u16(pos+16, directional_mapping.dir_8_fat_idx)
			pos += 18
	
	
	# Object Collision
	if section_sizes.object_collisions.size > 0:
		assert(pos == section_sizes.object_collisions.starts_at)
		for object_collision: Dictionary in das.object_collisions:
			data.encode_u32(pos, object_collision.raw_data)
			pos += 4
	
	
	# Monster Mapping
	if section_sizes.monster_mappings.size > 0:
		assert(pos == section_sizes.monster_mappings.starts_at)
		for monster_mapping: Dictionary in das.monster_mappings:
			data.encode_u32(pos, monster_mapping.unk_0x00)
			data.encode_u16(pos+4, monster_mapping.flying_back)
			data.encode_u16(pos+6, monster_mapping.flying_back_right)
			data.encode_u16(pos+8, monster_mapping.flying_right)
			data.encode_u16(pos+10, monster_mapping.flying_front_right)
			data.encode_u16(pos+12, monster_mapping.flying_front)
			data.encode_u16(pos+14, monster_mapping.flying_front_left)
			data.encode_u16(pos+16, monster_mapping.flying_left)
			data.encode_u16(pos+18, monster_mapping.flying_back_left)
			pos += 20
			
			data.encode_u16(pos, monster_mapping.walking_back)
			data.encode_u16(pos+2, monster_mapping.walking_back_right)
			data.encode_u16(pos+4, monster_mapping.walking_right)
			data.encode_u16(pos+6, monster_mapping.walking_front_right)
			data.encode_u16(pos+8, monster_mapping.walking_front)
			data.encode_u16(pos+10, monster_mapping.walking_front_left)
			data.encode_u16(pos+12, monster_mapping.walking_left)
			data.encode_u16(pos+14, monster_mapping.walking_back_left)
			pos += 16
			
			data.encode_u16(pos, monster_mapping.attack1_back)
			data.encode_u16(pos+2, monster_mapping.attack1_back_right)
			data.encode_u16(pos+4, monster_mapping.attack1_right)
			data.encode_u16(pos+6, monster_mapping.attack1_front_right)
			data.encode_u16(pos+8, monster_mapping.attack1_front)
			data.encode_u16(pos+10, monster_mapping.attack1_front_left)
			data.encode_u16(pos+12, monster_mapping.attack1_left)
			data.encode_u16(pos+14, monster_mapping.attack1_back_left)
			pos += 16
			
			data.encode_u16(pos, monster_mapping.attack2_back)
			data.encode_u16(pos+2, monster_mapping.attack2_back_right)
			data.encode_u16(pos+4, monster_mapping.attack2_right)
			data.encode_u16(pos+6, monster_mapping.attack2_front_right)
			data.encode_u16(pos+8, monster_mapping.attack2_front)
			data.encode_u16(pos+10, monster_mapping.attack2_front_left)
			data.encode_u16(pos+12, monster_mapping.attack2_left)
			data.encode_u16(pos+14, monster_mapping.attack2_back_left)
			pos += 16
			
			data.encode_u16(pos, monster_mapping.on_damage_back)
			data.encode_u16(pos+2, monster_mapping.on_damage_back_right)
			data.encode_u16(pos+4, monster_mapping.on_damage_right)
			data.encode_u16(pos+6, monster_mapping.on_damage_front_right)
			data.encode_u16(pos+8, monster_mapping.on_damage_front)
			data.encode_u16(pos+10, monster_mapping.on_damage_front_left)
			data.encode_u16(pos+12, monster_mapping.on_damage_left)
			data.encode_u16(pos+14, monster_mapping.on_damage_back_left)
			pos += 16
			
			data.encode_u16(pos, monster_mapping.dying_normal)
			data.encode_u16(pos+2, monster_mapping.dead_normal)
			data.encode_u16(pos+4, monster_mapping.dying_crit)
			data.encode_u16(pos+6, monster_mapping.dead_crit)
			data.encode_u16(pos+8, monster_mapping.spawn)
			data.encode_u16(pos+10, monster_mapping.unk_0x5E)
			data.encode_u32(pos+12, monster_mapping.unk_0x60)
			data.encode_u32(pos+16, monster_mapping.unk_0x64)
			pos += 20
	
	
	# Unk0x38 Section
	if section_sizes.unk_0x38.size > 0:
		assert(pos == section_sizes.unk_0x38.starts_at)
		for byte: int in das.unk_0x38_section.raw_data:
			data.encode_u8(pos, byte)
			pos += 1
	
	
	# Unk0x40 Section
	if section_sizes.unk_0x40.size > 0:
		assert(pos == section_sizes.unk_0x40.starts_at)
		for byte: int in das.unk_0x40_section.raw_data:
			data.encode_u8(pos, byte)
			pos += 1
	
	
	# Filenames Section
	if section_sizes.filenames.size > 0:
		assert(pos == section_sizes.filenames.starts_at)
		data.encode_u16(pos, len(das.filenames_1))
		data.encode_u16(pos+2, len(das.filenames_2))
		pos += 4
		for filename_table: String in ["filenames_1", "filenames_2"]:
			for filename: Dictionary in das[filename_table]:
				data.encode_u16(pos, filename.size)
				data.encode_u16(pos+2, filename.index)
				pos += 4
				for c: String in filename.name:
					data.encode_u8(pos, ord(c))
					pos += 1
				data.encode_u8(pos, 0)
				pos += 1
				for c: String in filename.desc:
					data.encode_u8(pos, ord(c))
					pos += 1
				data.encode_u8(pos, 0)
				pos += 1
	
	return data


static func _calculate_section_sizes_and_offsets(das: Dictionary) -> Dictionary:
	var header := {
		"starts_at": 0,
		"size": 68
	}
	var fat := {
		"starts_at": header.size,
		"size": (len(das.fat_1) + len(das.fat_2) + len(das.fat_3) + len(das.fat_4)) * 8
	}
	var palette := {
		"starts_at": (header.size + fat.size) if not das.palette.is_empty() else 0,
		"size": ((256*3) + 2 + (256*322)) if not das.palette.is_empty() else 0
	}
	var unk_0x10 := {
		"starts_at": (header.size + fat.size + palette.size) if not das.unk_0x10_section.raw_data.is_empty() else 0,
		"size": len(das.unk_0x10_section.raw_data)
	}
	
	var start_data_offset: int = header.size + fat.size + palette.size + unk_0x10.size
	if das.das_info.is_ademo:
		start_data_offset += 4
	
	var final_data_offset: int = _calculate_data_size(das.fat_1, start_data_offset, das.das_info.is_ademo)
	final_data_offset = _calculate_data_size(das.fat_2, final_data_offset, das.das_info.is_ademo)
	final_data_offset = _calculate_data_size(das.fat_3, final_data_offset, das.das_info.is_ademo)
	final_data_offset = _calculate_data_size(das.fat_4, final_data_offset, das.das_info.is_ademo)
	
	var data := {
		"starts_at": start_data_offset,
		"size": final_data_offset - start_data_offset
	}
	if das.das_info.is_ademo:
		data.size += 4
	
	
	var directional_objects := {
		"starts_at": (header.size + fat.size + palette.size + unk_0x10.size + data.size) if not das.directional_object_mappings.is_empty() else 0,
		"size": len(das.directional_object_mappings) * 20,
	}
	
	var object_collisions := {
		"starts_at": (header.size + fat.size + palette.size + unk_0x10.size + data.size + directional_objects.size) if not das.object_collisions.is_empty() else 0,
		"size": len(das.object_collisions) * 4,
	}
	
	var monster_mappings := {
		"starts_at": (header.size + fat.size + palette.size + unk_0x10.size + data.size + directional_objects.size + object_collisions.size) if not das.monster_mappings.is_empty() else 0,
		"size": len(das.monster_mappings) * 104
	}
	
	var unk_0x38 := {
		"starts_at": (header.size + fat.size + palette.size + unk_0x10.size + data.size + directional_objects.size + object_collisions.size + monster_mappings.size) if not das.unk_0x38_section.raw_data.is_empty() else 0,
		"size": len(das.unk_0x38_section.raw_data),
	}
	var unk_0x40 := {
		"starts_at": (header.size + fat.size + palette.size + unk_0x10.size + data.size + directional_objects.size + object_collisions.size + monster_mappings.size + unk_0x38.size) if not das.unk_0x40_section.raw_data.is_empty() else 0,
		"size": len(das.unk_0x40_section.raw_data),
	}
	
	das.filenames_1.sort_custom(func (a: Dictionary, b: Dictionary) -> bool:
		return a.index < b.index
	)
	das.filenames_2.sort_custom(func (a: Dictionary, b: Dictionary) -> bool:
		return a.index < b.index
	)
	
	var filenames_size: int = 4 # Header
	for filename: Dictionary in das.filenames_1:
		filename.size = 4 # Header
		filename.size += len(filename.name) + 1
		filename.size += len(filename.desc) + 1
		filenames_size += filename.size
	for filename: Dictionary in das.filenames_2:
		filename.size = 4 # Header
		filename.size += len(filename.name) + 1
		filename.size += len(filename.desc) + 1
		filenames_size += filename.size
	if filenames_size % 2 != 0:
		filenames_size += 1
	var filenames := {
		"starts_at": (header.size + fat.size + palette.size + unk_0x10.size + data.size + directional_objects.size + object_collisions.size + monster_mappings.size + unk_0x38.size + unk_0x40.size),
		"size": filenames_size
	}
	
	return {
		header = header,
		fat = fat,
		palette = palette,
		unk_0x10 = unk_0x10,
		data = data,
		directional_objects = directional_objects,
		object_collisions = object_collisions,
		monster_mappings = monster_mappings,
		unk_0x38 = unk_0x38,
		unk_0x40 = unk_0x40,
		filenames = filenames,
		total_size = filenames.starts_at+filenames.size,
	}


static func _calculate_data_size(fat: Array, total_size: int, is_ademo: bool) -> int:
	for entry: Dictionary in fat:
		var size: int = 0
		if entry.size != 0:
			if entry.flags_1 & 32 > 0:
				#print(entry.index)
				entry.offset = 0
				entry.size = 4
				continue
			
			#if "raw_data" in entry:
				#size += len(entry.raw_data)
				#if size % 2 != 0:
					#size += 1
			if "data" in entry:
				entry.offset = total_size
				if "raw_image" in entry.data:
					size += 6  # Header
					size += len(entry.data.raw_image)
					if size % 2 != 0:
						size += 1
				if "animation" in entry.data:
					var animation_data_size: int = _compile_animation(entry.data)
					size += 18 # Header
					size += (len(entry.data.offsets_array) * 4)
					size += 8 # Padding
					entry.data.first_image_offset = size
					size += 6 # Sub-header
					size += len(entry.data.animation[0]) # Base image
					size += animation_data_size
					entry.data.total_block_size = size
					while size % 16 != 0:
						size += 1
				if "animation_2" in entry.data:
					size += 16 # Header
					for sub_image: Array in entry.data.raw_animation_2:
						size += len(sub_image)
					while size % 16 != 0:
						size += 1
				if "image_pack" in entry.data:
					var starting_offset: int = size
					size += 8 # Header
					size += (2*len(entry.data.image_pack)) # Offsets
					size += 8 # Padding
					while (size-starting_offset) % 16 != 0:
						size += 1
					entry.data.offsets = []
					var offsets_mappings := {}
					for i in range(len(entry.data.image_pack)):
						var sub_image: Dictionary = entry.data.image_pack[i]
						offsets_mappings[i] = int((size - starting_offset) / 16.0)
						if entry.data.pack_type & 128 == 0:
							entry.data.offsets.append(int((size - starting_offset) / 16.0))
						size += 6 # Sub-image header
						size += len(sub_image.raw_image)
						while (size-starting_offset) % 16 != 0:
							size += 1
					if entry.data.pack_type & 128 > 0:
						for index: int in entry.data.offsets_index:
							entry.data.offsets.append(offsets_mappings[index])
					if size % 2 != 0:
						size += 1
				if "num_vertices" in entry.data:
					size += 22 # Header
					size += (16 * len(entry.data.vertices))
					size += 8 # Faces section header
					for face: Dictionary in entry.data.faces:
						size += 54 # Face header
						size += len(face.edge_array) * 2
					size += 4 # TODO ?
					if size % 2 != 0:
						size += 1
		
		total_size += size
		
		if is_ademo and size != 0 and "shift_data" in entry.data:
			total_size += 4
			entry.offset += 4
		
		if entry.offset != 0:
			#if "raw_data" in entry:
				##if entry.size != size >> 1:
					##print("ERROR SIZE: ", entry.index)
				##else:
					#entry.size = size >> 1
			if "data" in entry:
				if "animation" in entry.data or "animation_2" in entry.data:
					#if entry.size != size >>4:
						#print("ERROR SIZE: ", entry.index)
						#print("Orig: ", entry.size, " New: ", size)
						#print("=====")
					#else:
						entry.size = size >> 4
				else:
					#if entry.size != size >> 1:
						#print("ERROR SIZE: ", entry.index)
					#else:
						entry.size = size >> 1
	
	return total_size


static func _compile_animation(animation_data: Dictionary) -> int:
	var animation_array: Array = animation_data.animation.duplicate(true)
	var base_image: PackedByteArray = animation_array[0]
	animation_array.append(base_image)
	var starting_offset: int = 18 + ((len(animation_array)-1) * 4) + 8 + 6 + len(base_image)
	var compiled_animation := PackedByteArray()
	var offsets_array: Array = []
	for i in range(1, len(animation_array)):
		var frame: PackedByteArray = animation_array[i]
		
		if frame == base_image:
			offsets_array.append(0)
			continue
		else:
			offsets_array.append( starting_offset + len(compiled_animation) + 10 )
		
		var same_count: int = 0
		var diff_count: int = 0
		for j in range(len(base_image)):
			if same_count > 0 and (frame[j] != base_image[j] or same_count == 32767):
				# Same code
				if same_count < 128:
					compiled_animation.append(0x80 + same_count) # Code w/ count
				elif same_count < 255:
					compiled_animation.append(0x80 + 127) # Code w/ count
					compiled_animation.append(0x80 + same_count-127) # Code w/ count
				else:
					compiled_animation.append(0x80) # Code
					compiled_animation.append(same_count & 0xFF) # Count
					compiled_animation.append((same_count & 0xFF00) >> 8) # Count
					
				same_count = 0
			
			elif diff_count > 0 and (frame[j] == base_image[j] or diff_count == 127):
				# Diff code
				compiled_animation.append(diff_count)
				for k in range(diff_count, 0, -1):
					compiled_animation.append(frame[j-k])
				diff_count = 0
			
			if frame[j] == base_image[j] and diff_count == 0:
				same_count += 1
			elif same_count == 0:
				diff_count += 1
			else:
				assert(false)
		
		
		# FINAL
		if same_count > 0:
			if same_count < 128:
				compiled_animation.append(0x80 + same_count) # Code w/ count
			elif same_count < 255:
				compiled_animation.append(0x80 + 127) # Code w/ count
				compiled_animation.append(0x80 + same_count-127) # Code w/ count
			else:
				compiled_animation.append(0x80) # Code
				compiled_animation.append(same_count & 0xFF) # Count
				compiled_animation.append((same_count & 0xFF00) >> 8) # Count
		elif diff_count > 0:
			compiled_animation.append(diff_count)
			for k in range(diff_count, 0, -1):
				compiled_animation.append(frame[len(frame)-k])
		
		# End frame code
		compiled_animation.append(0x80)
		compiled_animation.append(0)
		compiled_animation.append(0)
		base_image = frame
	
	# End animation code
	compiled_animation.append(0)
	compiled_animation.append(0)
	
	animation_data["compiled_animation"] = compiled_animation
	animation_data["offsets_array"] = offsets_array
	return len(compiled_animation)


static func _write_data_entry(entry: Dictionary, data: PackedByteArray, pos: int, is_ademo: bool) -> int:
	var size: int = 0
	if entry.offset != 0:
		#pos = entry.offset
		if is_ademo and "data" in entry and "shift_data" in entry.data:
			assert(pos == entry.offset-4)
		else:
			assert(pos == entry.offset)
		
		#if "raw_data" in entry:
			#if "shift_data" in entry:
				##pos -= 4
				#for word: int in entry.shift_data:
					#data.encode_u16(pos, word)
					#pos += 2
			#for byte: int in entry.raw_data:
				#data.encode_u8(pos, byte)
				#pos += 1
				#size += 1
			#if size % 2 != 0:
				#pos += 1
				#size += 1
		
		if "data" in entry:
			if "shift_data" in entry.data:
				#pos -= 4
				for word: int in entry.data.shift_data:
					data.encode_s16(pos, word)
					pos += 2
			if "raw_image" in entry.data:
				data.encode_u8(pos, entry.data.modifier)
				data.encode_u8(pos+1, entry.data.image_type)
				data.encode_u16(pos+2, entry.data.width)
				data.encode_u16(pos+4, entry.data.height)
				pos += 6
				size += 6
				for byte: int in entry.data.raw_image:
					data.encode_u8(pos, byte)
					pos += 1
					size += 1
				if size % 2 != 0:
					pos += 1
					size += 1
			if "animation" in entry.data:
				data.encode_u8(pos, entry.data.modifier)
				data.encode_u8(pos+1, entry.data.image_type)
				data.encode_u16(pos+2, entry.data.width)
				data.encode_u16(pos+4, entry.data.height)
				data.encode_u32(pos+6, entry.data.total_block_size)
				data.encode_u16(pos+10, entry.data.first_image_offset)
				data.encode_u16(pos+12, len(entry.data.offsets_array))
				data.encode_u16(pos+14, entry.data.unk_0x0E)  # 0xFFFF
				data.encode_u8(pos+16, entry.data.unk_0x10)   # 0xFF
				data.encode_u8(pos+17, entry.data.animation_speed)
				
				pos += 18
				size += 18
				for dword: int in entry.data.offsets_array:
					data.encode_u32(pos, dword)
					pos += 4
					size += 4
				pos += 8 # Padding
				size += 8
				assert(size == entry.data.first_image_offset)
				# These values don't actually seem to do anything
				data.encode_u8(pos, 0)       # modifier_2
				data.encode_u8(pos+1, 0)     # image_type_2
				data.encode_u16(pos+2, 0)    # width_2
				data.encode_u16(pos+4, 0)    # height_2
				pos += 6
				size += 6
				for byte: int in entry.data.animation[0]:
					data.encode_u8(pos, byte)
					pos += 1
					size += 1
				for byte: int in entry.data.compiled_animation:
					data.encode_u8(pos, byte)
					pos += 1
					size += 1
				while size % 16 != 0:
					pos += 1
					size += 1
			if "animation_2" in entry.data:
				data.encode_u8(pos, entry.data.modifier)
				data.encode_u8(pos+1, entry.data.image_type)
				data.encode_u16(pos+2, entry.data.width)
				data.encode_u16(pos+4, entry.data.height)
				data.encode_u32(pos+6, entry.data.total_block_size)
				data.encode_u16(pos+10, entry.data.first_image_offset)
				data.encode_u16(pos+12, entry.data.num_sub_images)
				data.encode_u16(pos+14, entry.data.unk_0x0E)
				pos += 16
				size += 16
				for sub_image: Array in entry.data.raw_animation_2:
					for byte: int in sub_image:
						data.encode_u8(pos, byte)
						pos += 1
						size += 1
				while size % 16 != 0:
					pos += 1
					size += 1
			if "image_pack" in entry.data:
				var starting_offset: int = pos
				data.encode_u8(pos, entry.data.modifier)
				data.encode_u8(pos+1, entry.data.image_type)
				data.encode_u16(pos+2, entry.data.width)
				data.encode_u16(pos+4, entry.data.height)
				data.encode_u16(pos+6, len(entry.data.offsets) * 2)
				data.encode_u16(pos+7, entry.data.pack_type)
				pos += 8
				size += 8
				for i in range(len(entry.data.offsets)):
					var offset: int = entry.data.offsets[i]
					if entry.data.offsets_flipped[i]:
						offset |= 0x8000
					data.encode_u16(pos, offset)
					pos += 2
					size += 2
				pos += 8
				size += 8
				while (pos - starting_offset) % 16 != 0:
					pos += 1
					size += 1
				for sub_image: Dictionary in entry.data.image_pack:
					data.encode_u8(pos, sub_image.modifier)
					data.encode_u8(pos+1, sub_image.image_type)
					data.encode_u16(pos+2, sub_image.width)
					data.encode_u16(pos+4, sub_image.height)
					pos += 6
					size += 6
					for byte: int in sub_image.raw_image:
						data.encode_u8(pos, byte)
						pos += 1
						size += 1
					while (pos - starting_offset) % 16 != 0:
						pos += 1
						size += 1
				if size % 2 != 0:
					pos += 1
					size += 1
			if "num_vertices" in entry.data:
				data.encode_u8(pos, entry.data.modifier)
				data.encode_u8(pos+1, entry.data.image_type)
				data.encode_u16(pos+2, entry.data.max_bound_x)
				data.encode_u16(pos+4, entry.data.max_bound_y)
				data.encode_u16(pos+6, entry.data.unk_0x06)
				data.encode_u16(pos+8, entry.data.unk_0x08)
				data.encode_u32(pos+10, entry.data.unk_0x0A)
				data.encode_u16(pos+14, entry.data.max_bound_z)
				data.encode_u32(pos+16, entry.data.unk_0x10)
				data.encode_u16(pos+20, len(entry.data.vertices))
				pos += 22
				size += 22
				
				for vertex: Vector3i in entry.data.vertices:
					data.encode_u16(pos, vertex.x)
					data.encode_u16(pos+2, vertex.y)
					data.encode_u16(pos+4, vertex.z)
					data.encode_u16(pos+6, 0)
					data.encode_u32(pos+8, 0)
					data.encode_u32(pos+12, 0)
					pos += 16
					size += 16
				
				
				var face_size: int = 4  # Includes post padding
				for face: Dictionary in entry.data.faces:
					face_size += 54 # Face header
					face_size += len(face.edge_array) * 2
				
				for letter: String in entry.data.faces_header.sig:
					data.encode_u8(pos, ord(letter))
					pos += 1
					size += 1
				
				data.encode_u16(pos, 0)
				data.encode_u8(pos+2, face_size >> 8)
				data.encode_u8(pos+3, face_size & 0xFF)
				pos += 4
				size += 4
				
				for face: Dictionary in entry.data.faces:
					data.encode_u16(pos, face.size)
					data.encode_u32(pos+2, face.unk_0x02)
					data.encode_u16(pos+6, face.unk_0x06)
					data.encode_u16(pos+8, face.unk_0x08)
					data.encode_u16(pos+10, face.unk_0x0A)
					data.encode_u8(pos+12, face.texture_fat_index_base >> 8)
					data.encode_u8(pos+13, face.texture_fat_index_base & 0xFF)
					data.encode_u16(pos+14, face.unk_0x0E)
					data.encode_u16(pos+16, face.unk_0x10)
					data.encode_u32(pos+18, face.unk_0x10_2)
					data.encode_u8(pos+22, face.render_flag_1)
					data.encode_u8(pos+23, face.render_flag_2)
					data.encode_u32(pos+24, face.unk_0x18)
					data.encode_u8(pos+28, face.sub_texture_index)
					data.encode_u8(pos+29, face.unk_0x1D)
					data.encode_u8(pos+30, face.unk_0x1E)
					data.encode_u8(pos+31, face.unk_0x1F)
					data.encode_u32(pos+32, face.unk_0x20)
					data.encode_u16(pos+36, face.unk_0x24)
					data.encode_u16(pos+38, face.unk_0x26)
					data.encode_u32(pos+40, face.unk_0x28)
					data.encode_u32(pos+44, face.unk_0x2C)
					data.encode_u16(pos+48, face.unk_0x30)
					data.encode_u16(pos+50, face.unk_0x32)
					data.encode_u16(pos+52, face.edge_count)
					pos += 54
					size += 54 # Face header
					
					for edge: int in face.edge_array:
						data.encode_u16(pos, edge)
						pos += 2
						size += 2
				
				
				
				data.encode_u32(pos, 0)
				pos += 4
				size += 4
				
				if size % 2 != 0:
					pos += 1
					size += 1
	
	return pos
#endregion

#region Utility
static func get_texture_from_object(p_object: ObjectRoth) -> Dictionary:
	var object_das: Dictionary = {}
	var object_index: int = -1
	var object_texture: Dictionary = {}
	if p_object.data.textureSource == 0:
		object_das = p_object.map.das
		object_index = p_object.data.textureIndex + 4096
		object_texture = object_das.mapping[object_index]
	elif p_object.data.textureSource == 1:
		object_das = p_object.map.das
		object_index = p_object.data.textureIndex + 4096 + 256
		object_texture = object_das.mapping[object_index]
	elif p_object.data.textureSource == 2:
		object_texture = Roth.get_index_from_das(p_object.data.textureIndex, Roth.get_active_ademo())
	elif p_object.data.textureSource == 3:
		object_texture = Roth.get_index_from_das(p_object.data.textureIndex + 256, Roth.get_active_ademo())
	return object_texture
#endregion
