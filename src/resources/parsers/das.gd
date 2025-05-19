extends Object
class_name Das

## File to use to get a palette for ADEMO.DAS
const DEFAULT_PALETTE_FILE = "M/DEMO.DAS"


# DAS file header and entry definitions. Taken from https://github.com/Yagotzirck/roth_ripper
enum imgBasicTypes {
	PLAIN_DATA =            0x02,
	PLAIN_DATA_2 =          0x1A,
	PLAIN_DATA_3 =          0x18,
	PLAIN_DATA_4 =          0x04,
	PLAIN_DATA_5 =          0x1C,
	PLAIN_DATA_6 =          0x06,
	PLAIN_DATA_7 =          0x0A,
	PLAIN_DATA_8 =          0x0C,
	PLAIN_DATA_9 =          0x00,
	
	PLAIN_DATA_FLIPPED =    0x10,
	PLAIN_DATA_FLIPPED_2 =  0x12,
	PLAIN_DATA_FLIPPED_3 =  0x14,
	PLAIN_DATA_FLIPPED_4 =  0x30,
	
	COMPRESSED =            0x11,
	COMPRESSED_2 =          0x13,
	COMPRESSED_3 =          0x31,
	COMPRESSED_4 =          0x17,
	COMPRESSED_5 =          0x33,
	COMPRESSED_6 =          0x03
}

const Type := {
	Char="get_8",
	Byte="get_8",
	Word="get_16",
	DWord="get_32",
	String="get_line",
	Array=5,
}

const DAShdr_s := {
	DAS_id_str = [Type.Char,Type.Char,Type.Char,Type.Char],          # "DASP" (no zero-termination)
	DAS_id_num = Type.Word,             # always 5
	size_FAT = Type.Word,               # the total size of the 2 file allocation tables combined together(I guess)
	imgFATOffset = Type.DWord,           # it seems to be always 0x44(immediately following this header)
	paletteOffset = Type.DWord,          # if it's zero, then this file is ADEMO.DAS
	unk_0x10 = Type.DWord,
	fileNamesBlockOffset = Type.DWord,
	fileNamesBlockSize = Type.Word,
	unk_0x1C_size = Type.Word,          # size of data pointed by unk_0x1C
	unk_0x1C = Type.DWord,
	unk_0x20 = Type.DWord,
	unk_0x24 = Type.DWord,               # useless FAT;     size = imgFAT_numEntries * 4
	unk_0x28 = Type.DWord,               # useless FAT 2
	unk_0x28_size = Type.DWord,
	unk_0x30 = Type.DWord,
	imgFAT_numEntries = Type.Word,
	imgFAT_numEntries2 = Type.Word,     # number of 2nd img FAT entries, contiguous to the 1st one
	unk_0x38 = Type.DWord,
	unk_0x38_size = Type.Word,
	unk_0x40_size = Type.Word,
	unk_0x40 = Type.DWord,
}

const DAS_STRINGS_ENTRY := {
	sizeof = Type.Word,            # + 0x00        (sizeof (index) + len(name) + len(desc) + 2)
	index = Type.Word,             # + 0x02
	name = Type.String,            # + 0x04
	desc = Type.String,            # + 0xXX
}

const DAS_STRINGS_HEADER := {
	nb_unk_00 = Type.Word,             # + 0x00
	nb_unk_01 = Type.Word,             # + 0x02
	entries_00 = Type.Array,            # + 0x04
	entries_01 = Type.Array,
}

const image_record := {
	offset_data = Type.DWord,              # + 0x00
	length_data_div_2 = Type.Word,         # + 0x04
	unk_byte_00 = Type.Byte,               # + 0x06
	unk_byte_01 = Type.Byte,               # + 0x07
}

const imgBasicHdr := {
	unk = Type.Byte,
	imageType = Type.Byte,
	width = Type.Word,
	height = Type.Word,
}

const imgCompressed1Hdr := {
	unk = Type.Byte,
	imageType = Type.Byte,
	width = Type.Word,
	height = Type.Word,
	spritesBlockSize = Type.Word,
	unk2 = Type.Word,
	firstImgOffset = Type.Word,     # relative to the start of this header
	numSubImgs = Type.Word,         # the amount of compressed images following the first uncompressed frame
	unk3 = Type.Word,
	unk4 = Type.Word,
}

const imgCompressed2Hdr := {
	unk = Type.Byte,
	imageType = Type.Byte,
	width = Type.Word,
	height = Type.Word,
	unk2 = Type.Word,       # seems to be always 0
	unk3 = Type.Word,       # as above
	unk4 = Type.Word,
	imageType2 = Type.Word, # if it's  not 0xFFFE, then this is an imgCompressed1Hdr type
	unk5 = Type.Word,
}

const subImgCompressed2Hdr := {
	subImgID = Type.Word,       # seems to be always 0x17
	unk = Type.Word,            # seems to be always zero
	bufWidth = Type.Word,
	bufHeight = Type.Word,
	numImgs = Type.Word,
	currImgIdx = Type.Word,
	currImgSize = Type.DWord,    # including this header
	unk2 = Type.Word,
	width = Type.Word,
	unk4 = Type.Word,
	height = Type.Word,
}

const multiPlainImgsHdr := {
	unknown1 = Type.DWord,
	unknown2 = Type.DWord,
	unknown3 = Type.DWord,
	unknown4 = Type.DWord,
	unknown5 = Type.DWord,
	unknown6 = Type.DWord,
	unknown7 = Type.DWord,
	unknown8 = Type.DWord,
}

static var loaded_das := {}


static func load_das(das_file: String) -> Dictionary:
	Roth.das_loading_started.emit()
	var thread := Thread.new()
	Console.print("Loading das: %s" % Roth.directory.path_join(das_file))
	var _err: Error = thread.start(_load_das_thread.bind(das_file))
	var das: Dictionary = await Roth.das_loading_finished
	thread.wait_to_finish()
	return das


static func _load_das_thread(das_file: String) -> void:
	var das: Dictionary = _parse_das(das_file)
	Roth.das_loading_finished.emit.call_deferred(das)


static func get_default_palette(palette_file: String = DEFAULT_PALETTE_FILE) -> Array:
	var file := FileAccess.open(Roth.directory.path_join(palette_file), FileAccess.READ)
	var das_header: Dictionary = _parse_header(file)
	var palette: Array = _parse_palette(file, das_header.paletteOffset)
	file.close()
	return palette


static func _parse_header(file: FileAccess) -> Dictionary:
	var file_position := file.get_position()
	file.seek(0)
	var header: Dictionary = {}
	for key: String in DAShdr_s:
		if typeof(DAShdr_s[key]) == TYPE_STRING:
			header[key] = file.call(DAShdr_s[key])
		elif typeof(DAShdr_s[key]) == TYPE_ARRAY:
			var value := ""
			for each: String in DAShdr_s[key]:
				if each == "get_8":
					value += String.chr(file.call(each))
			header[key] = value
	file.seek(file_position)
	return header


static func _parse_palette(file: FileAccess, offset: int) -> Array:
	if offset == 0:
		return get_default_palette()
	var file_position := file.get_position()
	file.seek(offset)
	var palette: Array = []
	var raw_palette: PackedByteArray = file.get_buffer(256*3)
	for i in range(0, len(raw_palette), 3):
		palette.append([(raw_palette[i] * 259 + 33) >> 6, (raw_palette[i+1] * 259 + 33) >> 6, (raw_palette[i+2] * 259 + 33) >> 6 ])
	file.seek(file_position)
	return palette


static func _parse_das(das_file: String) -> Dictionary:
	var file := FileAccess.open(Roth.directory.path_join(das_file), FileAccess.READ)
	var das: Dictionary = {}
	
	das["name"] = das_file
	das["header"] = _parse_header(file)
	das["palette"] = _parse_palette(file, das.header.paletteOffset)
	das["textures"] = []
	das["mapping"] = {}
	das["das_strings_header"] = {}
	das["loading_errors"] = []
	das["sky"] = 0
	
	file.seek(das.header.fileNamesBlockOffset)
	for key: String in DAS_STRINGS_HEADER:
		if typeof(DAS_STRINGS_HEADER[key]) == TYPE_STRING:
			das["das_strings_header"][key] = file.call(DAS_STRINGS_HEADER[key])
		else:
			while file.get_position() < file.get_length():
				var entry: Dictionary
				for key2: String in DAS_STRINGS_ENTRY:
					entry[key2] = file.call(DAS_STRINGS_ENTRY[key2])
				das["textures"].append(entry)
				
	
	for i in range(len(das.textures)):
		file.seek(das.header.imgFATOffset + (das.textures[i].index * 0x08))
		
		for key: String in image_record:
			das.textures[i][key] = file.call(image_record[key])
		
		if das.textures[i].unk_byte_00 & 2 > 0:
			das.textures[i]["is_sky"] = true
			das.sky = i
		else:
			das.textures[i]["is_sky"] = false
		
		file.seek(das.textures[i]["offset_data"])
		
		for key: String in imgBasicHdr:
			das.textures[i][key] = file.call(imgBasicHdr[key])
			#Console.print("%s: %s" % [key, das.textures[i][key]])
		
		
		if (das.textures[i].imageType == imgBasicTypes.PLAIN_DATA or
				das.textures[i].imageType == imgBasicTypes.PLAIN_DATA_2 or
				das.textures[i].imageType == imgBasicTypes.PLAIN_DATA_3 or
				das.textures[i].imageType == imgBasicTypes.PLAIN_DATA_4 or
				das.textures[i].imageType == imgBasicTypes.PLAIN_DATA_5 or
				das.textures[i].imageType == imgBasicTypes.PLAIN_DATA_6 or
				das.textures[i].imageType == imgBasicTypes.PLAIN_DATA_7 or
				das.textures[i].imageType == imgBasicTypes.PLAIN_DATA_8 or
				das.textures[i].imageType == imgBasicTypes.PLAIN_DATA_9
		):
			#Console.print("Plain: %s" % das.textures[i].name)
			#file.seek(das.textures[i]["offset_data"] + 0x06)
			if das.textures[i].width == 0:
				das.loading_errors.append("Image has zero width. Index: %s, Name: %s" % [das.textures[i].index, das.textures[i].name])
				continue
			
			if das.textures[i].height == 0:
				das.loading_errors.append("Image has zero height. Index: %s, Name: %s" % [das.textures[i].index, das.textures[i].name])
				continue
			
			var raw_img := file.get_buffer(das.textures[i].width * das.textures[i].height)
			if len(raw_img) != das.textures[i].width * das.textures[i].height:
				das.loading_errors.append("Expected image mismatch! (Read past end of file) Expected: %s (%sx%s), Found: %s, Index: %s, Name: %s, Unk: %s" % [das.textures[i].width * das.textures[i].height, das.textures[i].width, das.textures[i].height, len(raw_img), das.textures[i].index, das.textures[i].name, das.textures[i].unk])
				continue
			var data: Array
			for pixel in raw_img:
				data.append_array(das.palette[pixel])
				if das.palette[pixel] == [0,0,0] and pixel == 0:
					data.append(0)
				else:
					data.append(255)
			
			
			var img := Image.create_from_data(das.textures[i].width, das.textures[i].height, false, Image.FORMAT_RGBA8, data)
			
			das.textures[i]["image"] = img
			das.textures[i]["flipped"] = false
		
		elif (das.textures[i].imageType == imgBasicTypes.PLAIN_DATA_FLIPPED or
				das.textures[i].imageType == imgBasicTypes.PLAIN_DATA_FLIPPED_2 or
				das.textures[i].imageType == imgBasicTypes.PLAIN_DATA_FLIPPED_3 or
				das.textures[i].imageType == imgBasicTypes.PLAIN_DATA_FLIPPED_4 
		):
			
			if das.textures[i].unk > 0xC0:
				
				
				file.seek(das.textures[i]["offset_data"] + 32)
				
				var alignment := file.get_position() & 0xF
				
				var img_reference := file.get_8()
				var _type := file.get_8()
				var width := file.get_16()
				var height := file.get_16()
				
				
				das.textures[i]["image"] = []
				while true:
					#Console.print("MULTI PLAIN IMGS: %s, ref: %s, width: %s, height: %s" % [das.textures[i].name, img_reference, width, height])
					var raw_img := file.get_buffer(width * height)
					var data: Array
					for pixel in raw_img:
						data.append_array(das.palette[pixel])
						if das.palette[pixel] == [0,0,0] and pixel == 0:
							data.append(0)
						else:
							data.append(255)
					var img := Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, data)
					img.flip_y()
					img.rotate_90(CLOCKWISE)
					
					das.textures[i]["image"].append(img)
					das.textures[i]["flipped"] = true
					
					
					var lower_ptr_4_bits := file.get_position() & 0xF
					var pos := file.get_position()
					if lower_ptr_4_bits > alignment:
						pos = pos + (alignment + 0x10 - lower_ptr_4_bits)
					else:
						pos = pos + (alignment - lower_ptr_4_bits)
					file.seek(pos)
					
					var img_reference_new := file.get_8()
					_type = file.get_8()
					width = file.get_16()
					height = file.get_16()
					#Console.print("MULTI PLAIN IMGS: %s, ref: %s, width: %s, height: %s" % [das.textures[i].name, img_reference_new, width, height])
					if img_reference != img_reference_new:
						break
				
				
				var tmp_width: int = das.textures[i].width
				var tmp_height: int = das.textures[i].height
				das.textures[i].width = tmp_height
				das.textures[i].height = tmp_width
				
				
				
			elif das.textures[i].unk == 0x40:
				#Console.print("3D Objs Textures: %s" % das.textures[i].name)
				var numImgs := 0
				while file.get_16() != 0:
					numImgs += 1
				numImgs -= 1
				#Console.print("numImgs: %s" % numImgs)
				
				while file.get_8() == 0:
					pass
				file.seek(file.get_position() - 2)
				
				var alignment := file.get_position() & 0xF
				var _img_reference := file.get_8()
				var _type := file.get_8()
				var width := file.get_16()
				var height := file.get_16()
				das.textures[i]["image"] = []
				for j in range(numImgs):
					#Console.print("3D Objs Textures: %s, ref: %s, type: %s, width: %s, height: %s" % [das.textures[i].name, img_reference, type, width, height])
					var raw_img := file.get_buffer(width * height)
					var data: Array
					for pixel in raw_img:
						data.append_array(das.palette[pixel])
						if das.palette[pixel] == [0,0,0] and pixel == 0:
							data.append(0)
						else:
							data.append(255)
					
					if width == 0:
						das.loading_errors.append("Image width is zero! Index: %s, Name: %s, Subimage: %s, Of: %s" % [das.textures[i].index, das.textures[i].name, j, numImgs])
					else:
						var img := Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, data)
						img.flip_y()
						img.rotate_90(CLOCKWISE)
						
						das.textures[i]["image"].append(img)
						das.textures[i]["flipped"] = true
					
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
					#Console.print("MULTI PLAIN NEXT: %s, ref: %s, type: %s, width: %s, height: %s" % [das.textures[i].name, img_reference_new, type_new, width, height])
					#if img_reference != img_reference_new:
						#Console.print("NOT SAME REF")
					#if type != type_new:
						#Console.print("NOT SAME TYPE REF")
					
				var tmp_width: int  = das.textures[i].width
				var tmp_height: int  = das.textures[i].height
				das.textures[i].width = tmp_height
				das.textures[i].height = tmp_width
			else:
				#Console.print("Flipped: %s" % das.textures[i].name)
				#file.seek(das.textures[i]["offset_data"] + 0x06)
				var raw_img := file.get_buffer(das.textures[i].width * das.textures[i].height)
				var data: Array
				for pixel in raw_img:
					data.append_array(das.palette[pixel])
					if das.palette[pixel] == [0,0,0] and pixel == 0:
						data.append(0)
					else:
						data.append(255)
				var img := Image.create_from_data(das.textures[i].width, das.textures[i].height, false, Image.FORMAT_RGBA8, data)
				img.flip_y()
				img.rotate_90(CLOCKWISE)
				var tmp_width: int  = das.textures[i].width
				var tmp_height: int  = das.textures[i].height
				das.textures[i].width = tmp_height
				das.textures[i].height = tmp_width
				
				das.textures[i]["image"] = img
				das.textures[i]["flipped"] = true
		
		elif (das.textures[i].imageType == imgBasicTypes.COMPRESSED or 
				das.textures[i].imageType == imgBasicTypes.COMPRESSED_2 or 
				das.textures[i].imageType == imgBasicTypes.COMPRESSED_3 or 
				das.textures[i].imageType == imgBasicTypes.COMPRESSED_4 or 
				das.textures[i].imageType == imgBasicTypes.COMPRESSED_5 or 
				das.textures[i].imageType == imgBasicTypes.COMPRESSED_6
		):
			#Console.print("COMPRESSED: %s" % das.textures[i].name)
			var _block_size := file.get_16()
			var _unk := file.get_16()
			var firstImgOffset := file.get_16()
			var img_type_2 := file.get_16()
			if img_type_2 != 0xFFFE:
				#Console.print("COMPRESS TYPE 1: %s, Count: %s" % [das.textures[i].name, img_type_2])
				file.seek(das.textures[i]["offset_data"] + firstImgOffset + 0x06)
				
				if das.textures[i].width == 0:
					das.loading_errors.append("Image has zero width. Index: %s, Name: %s" % [das.textures[i].index, das.textures[i].name])
					continue
				
				if das.textures[i].height == 0:
					das.loading_errors.append("Image has zero height. Index: %s, Name: %s" % [das.textures[i].index, das.textures[i].name])
					continue
				
				var raw_img := file.get_buffer(das.textures[i].width * das.textures[i].height)
				var data: Array
				for pixel in raw_img:
					data.append_array(das.palette[pixel])
					if das.palette[pixel] == [0,0,0] and pixel == 0:
						data.append(0)
					else:
						data.append(255)
				var img := Image.create_from_data(das.textures[i].width, das.textures[i].height, false, Image.FORMAT_RGBA8, data)
				
				if das.textures[i].imageType != 1:
					img.flip_y()
					img.rotate_90(CLOCKWISE)
					das.textures[i]["flipped"] = true
				else:
					Console.print("NOT FLIPPED??")
				
				das.textures[i]["image"] = img
				das.textures[i]["animation"] = [img]
				#Console.print("Index: %s, Name: %s, Subimages: %s" % [das.textures[i].index, das.textures[i].name, img_type_2])
				for j in range(img_type_2):
					#Console.print("SubImage: %s" % j)
					
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
								#Console.print("Codeword 0")
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
									# This path is only triggered by DEMO1/588:ANICE3.
									# Happens at the end of the last frame so nothing is lost.
									# Not sure if something is wrong with my code translation from the c code
									# but breaking out here seems to work ok.
									break
							else:
								pass
								#Console.print("Codeword other")
							
							pos += code_word
					
					if finished:
						#Console.print("Finished?")
						break
					
					var data2: Array
					for pixel in raw_img:
						data2.append_array(das.palette[pixel])
						if das.palette[pixel] == [0,0,0] and pixel == 0:
							data2.append(0)
						else:
							data2.append(255)
					var img2 := Image.create_from_data(das.textures[i].width, das.textures[i].height, false, Image.FORMAT_RGBA8, data2)
					img2.flip_y()
					img2.rotate_90(CLOCKWISE)
		
				
					das.textures[i]["animation"].append(img2)
				var tmp_width: int  = das.textures[i].width
				var tmp_height: int = das.textures[i].height
				das.textures[i].width = tmp_height
				das.textures[i].height = tmp_width
				das.textures[i]["flipped"] = true
			
			else:
				#Console.print("COMPRESS TYPE 2, Index: %s, Name: %s" % [das.textures[i].index, das.textures[i].name])
				
				file.seek(das.textures[i]["offset_data"] + 16)
				
				das.textures[i]["animation"] = []
				
				var starting_position: int = file.get_position()
				
				var sub_img_header := {}
				for key: String in subImgCompressed2Hdr:
					sub_img_header[key] = file.call(subImgCompressed2Hdr[key])
				
				
				var num_imgs: int = sub_img_header.numImgs
				while num_imgs == sub_img_header.numImgs:
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
					
					var data: Array
					for pixel: int in img_buffer:
						data.append_array(das.palette[pixel])
						if das.palette[pixel] == [0,0,0] and pixel == 0:
							data.append(0)
						else:
							data.append(255)
					
					var image := Image.create_from_data(sub_img_header.width, sub_img_header.height, false, Image.FORMAT_RGBA8, data)
					image.flip_y()
					image.rotate_90(CLOCKWISE)
					
					das.textures[i]["animation"].append(image)
					
					file.seek(starting_position + sub_img_header.currImgSize)
					starting_position = file.get_position()
					
					for key: String in subImgCompressed2Hdr:
						sub_img_header[key] = file.call(subImgCompressed2Hdr[key])
				das.textures[i]["flipped"] = true
				if len(das.textures[i]["animation"]) > 0:
					das.textures[i]["image"] = das.textures[i]["animation"][0]
				var tmp_width: int  = das.textures[i].width
				var tmp_height: int = das.textures[i].height
				das.textures[i].width = tmp_height
				das.textures[i].height = tmp_width
		
		elif das.textures[i].imageType == 0x80:
			das.loading_errors.append("Object not loaded: %s, Desc: %s, Index: %s" % [das.textures[i].name, das.textures[i].desc, das.textures[i].index])
			
		else:
			das.loading_errors.append("Unknown Type: %s, Name: %s" % [das.textures[i].imageType, das.textures[i].name])
		
		
		das.mapping[das.textures[i].index] = das.textures[i]
		Roth.das_loading_updated.emit.call_deferred(float(i) / len(das.textures), das_file.get_file())
	
	return das


static func _get_index_from_das(index:int, das_file: String) -> Dictionary:
	if das_file in loaded_das:
		if index in loaded_das[das_file]:
			return loaded_das[das_file][index]
	else:
		loaded_das[das_file] = {}
	
	
	var file := FileAccess.open(Roth.directory.path_join(das_file), FileAccess.READ)
	var das: Dictionary = {}
	
	das["name"] = das_file
	das["header"] = _parse_header(file)
	das["palette"] = _parse_palette(file, das.header.paletteOffset)
	das["textures"] = []
	das["mapping"] = {}
	das["das_strings_header"] = {}
	das["loading_errors"] = []
	das["sky"] = 0
	
	var texture := {}
	
	file.seek(das.header.fileNamesBlockOffset)
	for key: String in DAS_STRINGS_HEADER:
		if typeof(DAS_STRINGS_HEADER[key]) == TYPE_STRING:
			das["das_strings_header"][key] = file.call(DAS_STRINGS_HEADER[key])
		else:
			while file.get_position() < file.get_length():
				var entry: Dictionary
				for key2: String in DAS_STRINGS_ENTRY:
					entry[key2] = file.call(DAS_STRINGS_ENTRY[key2])
				das["textures"].append(entry)
				if entry.index == index:
					texture = entry
	
	if not "name" in texture:
		texture["name"] = "Invalid"
	if not "desc" in texture:
		texture["desc"] = ""
	if "index" not in texture:
		texture["index"] = index
		return texture
	
	file.seek(das.header.imgFATOffset + (index * 0x08))
	
	for key: String in image_record:
		texture[key] = file.call(image_record[key])
	
	if texture.unk_byte_00 & 2 > 0:
		texture["is_sky"] = true
	else:
		texture["is_sky"] = false
	
	file.seek(texture["offset_data"])
	
	for key: String in imgBasicHdr:
		texture[key] = file.call(imgBasicHdr[key])
		#Console.print("%s: %s" % [key, texture[key]])
	
	
	if (texture.imageType == imgBasicTypes.PLAIN_DATA or
			texture.imageType == imgBasicTypes.PLAIN_DATA_2 or
			texture.imageType == imgBasicTypes.PLAIN_DATA_3 or
			texture.imageType == imgBasicTypes.PLAIN_DATA_4 or
			texture.imageType == imgBasicTypes.PLAIN_DATA_5 or
			texture.imageType == imgBasicTypes.PLAIN_DATA_6 or
			texture.imageType == imgBasicTypes.PLAIN_DATA_7 or
			texture.imageType == imgBasicTypes.PLAIN_DATA_8 or
			texture.imageType == imgBasicTypes.PLAIN_DATA_9
	):
		#Console.print("Plain: %s" % texture.name)
		#file.seek(texture["offset_data"] + 0x06)
		if texture.width == 0:
			das.loading_errors.append("Image has zero width. Index: %s, Name: %s" % [texture.index, texture.name])
			loaded_das[das_file][index] = texture
			return texture
		
		if texture.height == 0:
			das.loading_errors.append("Image has zero height. Index: %s, Name: %s" % [texture.index, texture.name])
			loaded_das[das_file][index] = texture
			return texture
		
		var raw_img := file.get_buffer(texture.width * texture.height)
		if len(raw_img) != texture.width * texture.height:
			das.loading_errors.append("Expected image mismatch! (Read past end of file) Expected: %s (%sx%s), Found: %s, Index: %s, Name: %s, Unk: %s" % [texture.width * texture.height, texture.width, texture.height, len(raw_img), texture.index, texture.name, texture.unk])
			loaded_das[das_file][index] = texture
			return texture
		var data: Array
		for pixel in raw_img:
			data.append_array(das.palette[pixel])
			if das.palette[pixel] == [0,0,0] and pixel == 0:
				data.append(0)
			else:
				data.append(255)
		
		
		var img := Image.create_from_data(texture.width, texture.height, false, Image.FORMAT_RGBA8, data)
		
		texture["image"] = img
		texture["flipped"] = false
	
	elif (texture.imageType == imgBasicTypes.PLAIN_DATA_FLIPPED or
			texture.imageType == imgBasicTypes.PLAIN_DATA_FLIPPED_2 or
			texture.imageType == imgBasicTypes.PLAIN_DATA_FLIPPED_3 or
			texture.imageType == imgBasicTypes.PLAIN_DATA_FLIPPED_4 
	):
		
		if texture.unk > 0xC0:
			
			
			file.seek(texture["offset_data"] + 32)
			
			var alignment := file.get_position() & 0xF
			
			var img_reference := file.get_8()
			var _type := file.get_8()
			var width := file.get_16()
			var height := file.get_16()
			
			
			texture["image"] = []
			while true:
				#Console.print("MULTI PLAIN IMGS: %s, ref: %s, width: %s, height: %s" % [texture.name, img_reference, width, height])
				var raw_img := file.get_buffer(width * height)
				var data: Array
				for pixel in raw_img:
					data.append_array(das.palette[pixel])
					if das.palette[pixel] == [0,0,0] and pixel == 0:
						data.append(0)
					else:
						data.append(255)
				var img := Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, data)
				img.flip_y()
				img.rotate_90(CLOCKWISE)
				
				texture["image"].append(img)
				texture["flipped"] = true
				
				
				var lower_ptr_4_bits := file.get_position() & 0xF
				var pos := file.get_position()
				if lower_ptr_4_bits > alignment:
					pos = pos + (alignment + 0x10 - lower_ptr_4_bits)
				else:
					pos = pos + (alignment - lower_ptr_4_bits)
				file.seek(pos)
				
				var img_reference_new := file.get_8()
				_type = file.get_8()
				width = file.get_16()
				height = file.get_16()
				#Console.print("MULTI PLAIN IMGS: %s, ref: %s, width: %s, height: %s" % [texture.name, img_reference_new, width, height])
				if img_reference != img_reference_new:
					break
			
			
			var tmp_width: int = texture.width
			var tmp_height: int = texture.height
			texture.width = tmp_height
			texture.height = tmp_width
			
			
			
		elif texture.unk == 0x40:
			#Console.print("3D Objs Textures: %s" % texture.name)
			var numImgs := 0
			while file.get_16() != 0:
				numImgs += 1
			numImgs -= 1
			#Console.print("numImgs: %s" % numImgs)
			
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
				var raw_img := file.get_buffer(width * height)
				var data: Array
				for pixel in raw_img:
					data.append_array(das.palette[pixel])
					if das.palette[pixel] == [0,0,0] and pixel == 0:
						data.append(0)
					else:
						data.append(255)
				
				if width == 0:
					das.loading_errors.append("Image width is zero! Index: %s, Name: %s, Subimage: %s, Of: %s" % [texture.index, texture.name, j, numImgs])
				else:
					var img := Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, data)
					img.flip_y()
					img.rotate_90(CLOCKWISE)
					
					texture["image"].append(img)
					texture["flipped"] = true
				
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
				#Console.print("MULTI PLAIN NEXT: %s, ref: %s, type: %s, width: %s, height: %s" % [texture.name, img_reference_new, type_new, width, height])
				#if img_reference != img_reference_new:
					#Console.print("NOT SAME REF")
				#if type != type_new:
					#Console.print("NOT SAME TYPE REF")
				
			var tmp_width: int  = texture.width
			var tmp_height: int  = texture.height
			texture.width = tmp_height
			texture.height = tmp_width
		else:
			#Console.print("Flipped: %s" % texture.name)
			#file.seek(texture["offset_data"] + 0x06)
			var raw_img := file.get_buffer(texture.width * texture.height)
			var data: Array
			for pixel in raw_img:
				data.append_array(das.palette[pixel])
				if das.palette[pixel] == [0,0,0] and pixel == 0:
					data.append(0)
				else:
					data.append(255)
			var img := Image.create_from_data(texture.width, texture.height, false, Image.FORMAT_RGBA8, data)
			img.flip_y()
			img.rotate_90(CLOCKWISE)
			var tmp_width: int  = texture.width
			var tmp_height: int  = texture.height
			texture.width = tmp_height
			texture.height = tmp_width
			
			texture["image"] = img
			texture["flipped"] = true
	
	elif (texture.imageType == imgBasicTypes.COMPRESSED or 
			texture.imageType == imgBasicTypes.COMPRESSED_2 or 
			texture.imageType == imgBasicTypes.COMPRESSED_3 or 
			texture.imageType == imgBasicTypes.COMPRESSED_4 or 
			texture.imageType == imgBasicTypes.COMPRESSED_5 or 
			texture.imageType == imgBasicTypes.COMPRESSED_6
	):
		#Console.print("COMPRESSED: %s" % texture.name)
		var _block_size := file.get_16()
		var _unk := file.get_16()
		var firstImgOffset := file.get_16()
		var img_type_2 := file.get_16()
		if img_type_2 != 0xFFFE:
			#Console.print("COMPRESS TYPE 1: %s, Count: %s" % [texture.name, img_type_2])
			file.seek(texture["offset_data"] + firstImgOffset + 0x06)
			
			if texture.width == 0:
				das.loading_errors.append("Image has zero width. Index: %s, Name: %s" % [texture.index, texture.name])
				loaded_das[das_file][index] = texture
				return texture
			
			if texture.height == 0:
				das.loading_errors.append("Image has zero height. Index: %s, Name: %s" % [texture.index, texture.name])
				loaded_das[das_file][index] = texture
				return texture
			
			var raw_img := file.get_buffer(texture.width * texture.height)
			var data: Array
			for pixel in raw_img:
				data.append_array(das.palette[pixel])
				if das.palette[pixel] == [0,0,0] and pixel == 0:
					data.append(0)
				else:
					data.append(255)
			var img := Image.create_from_data(texture.width, texture.height, false, Image.FORMAT_RGBA8, data)
			
			if texture.imageType != 1:
				img.flip_y()
				img.rotate_90(CLOCKWISE)
				texture["flipped"] = true
			else:
				Console.print("NOT FLIPPED??")
			
			texture["image"] = img
			texture["animation"] = [img]
			#Console.print("Index: %s, Name: %s, Subimages: %s" % [texture.index, texture.name, img_type_2])
			for j in range(img_type_2):
				#Console.print("SubImage: %s" % j)
				
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
							#Console.print("Codeword 0")
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
								# This path is only triggered by DEMO1/588:ANICE3.
								# Happens at the end of the last frame so nothing is lost.
								# Not sure if something is wrong with my code translation from the c code
								# but breaking out here seems to work ok.
								break
						else:
							pass
							#Console.print("Codeword other")
						
						pos += code_word
				
				if finished:
					#Console.print("Finished?")
					break
				
				var data2: Array
				for pixel in raw_img:
					data2.append_array(das.palette[pixel])
					if das.palette[pixel] == [0,0,0] and pixel == 0:
						data2.append(0)
					else:
						data2.append(255)
				var img2 := Image.create_from_data(texture.width, texture.height, false, Image.FORMAT_RGBA8, data2)
				img2.flip_y()
				img2.rotate_90(CLOCKWISE)
	
			
				texture["animation"].append(img2)
			var tmp_width: int  = texture.width
			var tmp_height: int = texture.height
			texture.width = tmp_height
			texture.height = tmp_width
			texture["flipped"] = true
		
		else:
			#Console.print("COMPRESS TYPE 2, Index: %s, Name: %s" % [texture.index, texture.name])
			
			file.seek(texture["offset_data"] + 16)
			
			texture["animation"] = []
			
			var starting_position: int = file.get_position()
			
			var sub_img_header := {}
			for key: String in subImgCompressed2Hdr:
				sub_img_header[key] = file.call(subImgCompressed2Hdr[key])
			
			
			var num_imgs: int = sub_img_header.numImgs
			while num_imgs == sub_img_header.numImgs:
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
				
				var data: Array
				for pixel: int in img_buffer:
					data.append_array(das.palette[pixel])
					if das.palette[pixel] == [0,0,0] and pixel == 0:
						data.append(0)
					else:
						data.append(255)
				
				var image := Image.create_from_data(sub_img_header.width, sub_img_header.height, false, Image.FORMAT_RGBA8, data)
				image.flip_y()
				image.rotate_90(CLOCKWISE)
				
				texture["animation"].append(image)
				
				file.seek(starting_position + sub_img_header.currImgSize)
				starting_position = file.get_position()
				
				for key: String in subImgCompressed2Hdr:
					sub_img_header[key] = file.call(subImgCompressed2Hdr[key])
			texture["flipped"] = true
			if len(texture["animation"]) > 0:
				texture["image"] = texture["animation"][0]
			var tmp_width: int  = texture.width
			var tmp_height: int = texture.height
			texture.width = tmp_height
			texture.height = tmp_width
	
	elif texture.imageType == 0x80:
		das.loading_errors.append("Object not loaded: %s, Desc: %s, Index: %s" % [texture.name, texture.desc, texture.index])
		Console.print("Object not loaded: %s, Desc: %s, Index: %s" % [texture.name, texture.desc, texture.index])
	else:
		das.loading_errors.append("Unknown Type: %s, Name: %s" % [texture.imageType, texture.name])
		Console.print("Unknown Type: %s, Name: %s" % [texture.imageType, texture.name])
	
	
	loaded_das[das_file][index] = texture
	return texture
