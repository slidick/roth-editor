extends Object
class_name Raw


const HEADER := {
	"verticesOffset": Parser.Type.Word,
	"version": Parser.Type.Word,
	"sectorsOffset": Parser.Type.Word,
	"facesOffset": Parser.Type.Word,
	"faceTextureMapsOffset": Parser.Type.Word,
	"mapMetadataOffset": Parser.Type.Word,
	"verticesOffsetRepeat": Parser.Type.Word,
	"signature": [Parser.Type.Char, Parser.Type.Char],
	"midPlatformsSection": Parser.Type.Word,
	"section7Size": Parser.Type.Word,
	"verticesSectionSize": Parser.Type.Word,
	"objectsSectionsSize": Parser.Type.Word,
	"footerSize": Parser.Type.Word,
	"commandSectionSize": Parser.Type.Word,
	"sectorCount": Parser.Type.Word,
}

const SECTOR := {
	"ceilingHeight": Parser.Type.SignedWord,
	"floorHeight": Parser.Type.SignedWord,
	"unk0x04": Parser.Type.Word,
	"ceilingTextureIndex": Parser.Type.Word,
	"floorTextureIndex": Parser.Type.Word,
	"textureFit": Parser.Type.Byte,
	"lighting": Parser.Type.Byte,
	"textureMapOverride": Parser.Type.SignedByte,
	"facesCount": Parser.Type.Byte,
	"firstFaceOffset": Parser.Type.Word,
	"ceilingTextureShiftX": Parser.Type.Byte,
	"ceilingTextureShiftY": Parser.Type.Byte,
	"floorTextureShiftX": Parser.Type.Byte,
	"floorTextureShiftY": Parser.Type.Byte,
	"floorTriggerID": Parser.Type.Word,
	"unk0x16": Parser.Type.Word,
	"intermediateFloorOffset": Parser.Type.Word,
}

const FACE := {
	"vertexOffset01": Parser.Type.Word,
	"vertexOffset02": Parser.Type.Word,
	"textureMapOffset": Parser.Type.Word,
	"sectorOffset": Parser.Type.Word,
	"sisterFaceOffset": Parser.Type.Word,
	"addCollision": Parser.Type.Word,
}

const TEXTURE_MAPPING := {
	"unk0x00": Parser.Type.Byte,
	"type": Parser.Type.Byte,
	"midTextureIndex": Parser.Type.Word,
	"upperTextureIndex": Parser.Type.Word,
	"lowerTextureIndex": Parser.Type.Word,
	"unk0x08": Parser.Type.Word,
}

const ADDITIONAL_METADATA := {
	"shiftTextureX": Parser.Type.Byte,
	"shiftTextureY": Parser.Type.Byte,
	"unk0x0C": Parser.Type.Word,
}

const MID_PLATFORM := {
	"ceilingTextureIndex": Parser.Type.Word,
	"ceilingHeight": Parser.Type.SignedWord,
	"ceilingTextureShiftX": Parser.Type.Byte,
	"ceilingTextureShiftY": Parser.Type.Byte,
	"floorTextureIndex": Parser.Type.Word,
	"floorHeight": Parser.Type.SignedWord,
	"floorTextureShiftX": Parser.Type.Byte,
	"floorTextureShiftY": Parser.Type.Byte,
	"floorTextureScale": Parser.Type.Byte,
	"padding": Parser.Type.Byte,
}

const MAP_METADATA := {
	"initPosX": Parser.Type.SignedWord,
	"initPosZ": Parser.Type.SignedWord,
	"initPosY": Parser.Type.SignedWord,
	"rotation": Parser.Type.SignedWord,
	"moveSpeed": Parser.Type.Word,
	"playerHeight": Parser.Type.Word,
	"maxClimb": Parser.Type.Word,
	"minFit": Parser.Type.Word,
	"unk0x10": Parser.Type.Word,
	"candleGlow": Parser.Type.SignedWord,
	"lightAmbience": Parser.Type.Word,
	"unk0x16": Parser.Type.Word,
	"skyTexture": Parser.Type.Word,
	"unk0x1A": Parser.Type.Word,
}

const VERTICES_HEADER := {
	"sectionSize": Parser.Type.Word,
	"sectionHeaderSize": Parser.Type.Word,
	"blank": Parser.Type.Word,
	"verticesCount": Parser.Type.Word,
}

const VERTEX := {
	"unk0x00": Parser.Type.Word,
	"unk0x02": Parser.Type.Word,
	"unk0x04": Parser.Type.Word,
	"unk0x06": Parser.Type.Word,
	"x": Parser.Type.SignedWord,
	"y": Parser.Type.SignedWord,
}

const COMMAND_HEADER := {
	"signature": [Parser.Type.Char, Parser.Type.Char],
	"unk0x02": Parser.Type.Word,
	"commandsOffset": Parser.Type.Word,
	"commandCount": Parser.Type.Word,
}

const ENTRY_COMMAND_COUNT := {
	"categoryOffset": Parser.Type.Word,
	"count": Parser.Type.Word,
}

const ENTRY_COMMAND_REFERENCES := {
	"offset": Parser.Type.Word,
}

const COMMAND := {
	"size": Parser.Type.Word,
	"commandModifier": Parser.Type.Byte,
	"commandBase": Parser.Type.Byte,
	"nextCommandIndex": Parser.Type.Word
}

const SECTION_7_HEADER := {
	"sizeA": Parser.Type.Word,
	"count": Parser.Type.Word,
}

const SOUND_EFFECT := {
	"unk0x00": Parser.Type.SignedWord,
	"unk0x02": Parser.Type.SignedWord,
	"unk0x04": Parser.Type.Word,
	"unk0x06": Parser.Type.Word,
	"unk0x08": Parser.Type.Word,
	"unk0x0A": Parser.Type.Word,
	"unk0x0C": Parser.Type.Word,
	"unk0x0E": Parser.Type.Word,
	"unk0x10": Parser.Type.Word,
}

const UNKOWN_ARRAY_2 := {
	"unk0x00": Parser.Type.Word,
	"unk0x02": Parser.Type.Word,
	"unk0x04": Parser.Type.Word,
	"unk0x06": Parser.Type.Word,
	"unk0x08": Parser.Type.Word,
	"unk0x0A": Parser.Type.Word,
	"unk0x0C": Parser.Type.Word,
	"unk0x0E": Parser.Type.Word,
	"unk0x10": Parser.Type.Word,
	"unk0x12": Parser.Type.Word,
	"unk0x14": Parser.Type.Word,
	"unk0x16": Parser.Type.Word,
	"unk0x18": Parser.Type.Word,
	"unk0x1A": Parser.Type.Word,
	"unk0x1C": Parser.Type.Word,
	"unk0x1E": Parser.Type.Word,
}

const OBJECTS_HEADER := {
	"size": Parser.Type.Word,
}

const OBJECTS_CONTAINER := {
	"count": Parser.Type.Byte,
	"countRepeat": Parser.Type.Byte,
}

const OBJECT := {
	"posX": Parser.Type.SignedWord,
	"posY": Parser.Type.SignedWord,
	"textureIndex": Parser.Type.Byte,
	"textureSource": Parser.Type.Byte,
	"rotation": Parser.Type.Byte,
	"unk0x07": Parser.Type.Byte,
	"lighting": Parser.Type.Byte,
	"renderType": Parser.Type.Byte,
	"posZ": Parser.Type.SignedWord,
	"unk0x0C": Parser.Type.Word,
	"unk0x0E": Parser.Type.Word,
}


static func parse_file(filepath: String = "res://TEST.RAW") -> Dictionary:
	#print("Parsing: %s" % filepath)
	var file: FileAccess = FileAccess.open(filepath, FileAccess.READ)
	
	# Header
	# -------------
	var header: Dictionary = Parser.parse_section(file, HEADER)
	
	
	# Sectors
	# -------------
	var sectors := []
	for i in range(header["sectorCount"]):
		sectors.append(
			Parser.parse_section(file, SECTOR)
		)
	
	
	# Faces
	# -------------
	var face_count: int = file.get_16()
	var faces := []
	var faces_offset_map := {}
	for i in range(face_count):
		faces_offset_map[file.get_position()] = i
		faces.append(
			Parser.parse_section(file, FACE)
		)
	
	
	# Texture Mappings
	# -------------
	var texture_mappings_count: int = file.get_16()
	var texture_mappings := []
	var texture_mappings_offset_map := {}
	for i in range(texture_mappings_count):
		texture_mappings_offset_map[file.get_position()] = i
		texture_mappings.append(
			Parser.parse_section(file, TEXTURE_MAPPING)
		)
	
	# Mid-platforms
	# -------------
	var mid_platforms := []
	var mid_platforms_offset_map := {}
	if header["midPlatformsSection"] != 0x00:
		var mid_platform_count: int = file.get_16()
		for i in range(mid_platform_count):
			mid_platforms_offset_map[file.get_position()] = i
			mid_platforms.append(
				Parser.parse_section(file, MID_PLATFORM)
			)
	
	
	# Map Metadata
	# -------------
	var map_metadata := Parser.parse_section(file, MAP_METADATA)
	
	file.seek(header["verticesOffset"])
	
	# Vertices
	# -------------
	var vertices_header := Parser.parse_section(file, VERTICES_HEADER)
	
	var vertices := []
	var vertices_relative_offset_map := {}
	for i in range(vertices_header["verticesCount"]):
		vertices_relative_offset_map[file.get_position() - header["verticesOffset"]] = i
		var vertex := Parser.parse_section(file, VERTEX)
		vertex.erase("unk0x00")
		vertex.erase("unk0x02")
		vertex.erase("unk0x04")
		vertex.erase("unk0x06")
		vertices.append(vertex)
	
	
	# Commands
	# -------------
	var command_header := Parser.parse_section(file, COMMAND_HEADER)
	
	for i in range(15):
		var _entry_command_count := Parser.parse_section(file, ENTRY_COMMAND_COUNT)
		
	
	var command_entry_points_offsets := []
	for i in range(command_header["commandCount"]):
		var command_offset := Parser.parse_section(file, ENTRY_COMMAND_REFERENCES)
		command_entry_points_offsets.append(command_offset.offset)
	
	var commands := []
	var commands_relative_offset_map := {}
	for i in range(command_header["commandCount"]):
		commands_relative_offset_map[file.get_position() - (header["verticesOffset"] + header["verticesSectionSize"])] = i + 1
		var command := Parser.parse_section(file, COMMAND)
		command.erase("size")
		commands.append(command)
	
	var command_entry_points := []
	for command_offset: int in command_entry_points_offsets:
		if command_offset == 0x000:
			continue
		var command_index: int = commands_relative_offset_map[command_offset]
		command_entry_points.append(command_index)
	command_header.erase("commandCount")
	command_header.erase("commandsOffset")
	
	
	# Section 7
	# -------------
	var section_7_header := Parser.parse_section(file, SECTION_7_HEADER)
	var unk_array_01 := []
	for i in range(section_7_header["count"]):
		unk_array_01.append(
			Parser.parse_section(file, SOUND_EFFECT)
		)
	
	var unk_array_02 := []
	if header["section7Size"] > section_7_header["sizeA"]:
		while file.get_position() < header["section7Size"] + header["commandSectionSize"] + header["verticesOffset"] + header["verticesSectionSize"]:
			unk_array_02.append(
				Parser.parse_section(file, UNKOWN_ARRAY_2)
			)
	
	
	# Objects
	# -------------
	var object_start_position: int = file.get_position()
	var objects_header := Parser.parse_section(file, OBJECTS_HEADER)
	var current_position: int = file.get_position()
	for i in range(header["sectorCount"]):
		file.seek(current_position)
		current_position += 0x02
		
		var relative_offset: int = file.get_16()
		if relative_offset == 0x0000:
			sectors[i]["objectInformation"] = []
			continue
		
		file.seek(object_start_position + relative_offset)
		
		var objects_container := Parser.parse_section(file, OBJECTS_CONTAINER)
		var objects := []
		for j in range(objects_container.count):
			objects.append(
				Parser.parse_section(file, OBJECT)
			)
		sectors[i]["objectInformation"] = objects
	
	
	file.seek(object_start_position + objects_header["size"])
	
	
	# Footer
	# -------------
	var footer := []
	while file.get_position() < file.get_length():
		footer.append(file.get_8())
	
	
	file.close()
	
	
	# Additional Relations
	# --------------------
	
	for i in range(len(sectors)):
		var sector: Dictionary = sectors[i]
		if sector["intermediateFloorOffset"] > 0x0000:
			var mid_platform_index: int = mid_platforms_offset_map[sector["intermediateFloorOffset"]]
			sector["intermediateFloorIndex"] = mid_platform_index
		
		sector["firstFaceIndex"] = faces_offset_map[sector["firstFaceOffset"]]
		
		for j in range(sector["facesCount"]):
			var face_index: int = faces_offset_map[sector["firstFaceOffset"] + 0x0C * j]
			faces[face_index]["sectorIndex"] = i
		
		sector.erase("intermediateFloorOffset")
		sector.erase("firstFaceOffset")
	
	for face: Dictionary in faces:
		face["vertexIndex01"] = vertices_relative_offset_map[face["vertexOffset01"]]
		face["vertexIndex02"] = vertices_relative_offset_map[face["vertexOffset02"]]
		face["textureMappingIndex"] = texture_mappings_offset_map[face["textureMapOffset"]]
		
		if face["sisterFaceOffset"] != 0xFFFF:
			if face["sisterFaceOffset"] == 0x0000:
				print("Found offset of 0x00. Skipping.")
				continue
			face["sisterFaceIndex"] = faces_offset_map[face["sisterFaceOffset"]]
	
		face.erase("vertexOffset01")
		face.erase("vertexOffset02")
		face.erase("textureMapOffset")
		face.erase("sisterFaceOffset")
		face.erase("sectorOffset")
	
	
	
	
	var parsed_file := {}
	parsed_file["rawrMetadata"] = { "mapName": filepath.get_file().get_basename() }
	parsed_file["sectorsSection"] = { "sectors": sectors }
	parsed_file["facesSection"] = { "faces": faces }
	parsed_file["faceTextureMappingSection"] = { "mappings": texture_mappings }
	if mid_platforms:
		parsed_file["midPlatformsSection"] = { "platforms": mid_platforms }
	parsed_file["mapMetadataSection"] = map_metadata
	parsed_file["verticesSection"] = { "vertices": vertices }
	parsed_file["commandsSection"] = {
			"header": command_header,
			"entryCommandIndexes": command_entry_points,
			"allCommands": commands
	}
	parsed_file["section7"] = { "unkArray01": unk_array_01 }
	if unk_array_02:
		parsed_file["section7"]["unkArray02"] = unk_array_02
	
	
	parsed_file["commandsSection"]["entryCommandIndexes"].sort()
	parsed_file["commandsSection"]["entryCommandIndexes"].sort_custom(func (i1: int, i2: int) -> bool: return parsed_file["commandsSection"]["allCommands"][i1-1].commandBase < parsed_file["commandsSection"]["allCommands"][i2-1].commandBase)
	
	
	return parsed_file
