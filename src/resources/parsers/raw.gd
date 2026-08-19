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

const NORM_HEADER := {
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
	"posX": Parser.Type.SignedWord,      # Pos X
	"posY": Parser.Type.SignedWord,      # Pos Y
	"sfxIndex": Parser.Type.Word,        # SFX Index
	"sfxID": Parser.Type.Word,           # SFX ID
	"flags": Parser.Type.Byte,           # Flags (Loop, Loop w/delay, Unused*4, Unknown, Autoplay)
	"zoneIndex": Parser.Type.Byte,       # Zone Index
	"audibleRadius": Parser.Type.Word,   # Radius
	"loopDelay": Parser.Type.Word,       # Max Loop Delay
	"unk0x0E": Parser.Type.Word,         # Unused
	"volume": Parser.Type.Byte,          # Volume
	"unk0x11": Parser.Type.Byte,         # Only 0 or 128
}

const NORM_SOUND_EFFECT := {
	"posX": Parser.Type.SignedWord,      # Pos X
	"posY": Parser.Type.SignedWord,      # Pos Y
	"sfxIndex": Parser.Type.Word,        # SFX Index
	"sfxID": Parser.Type.Word,           # SFX ID
	"flags": Parser.Type.Byte,           # Flags (Loop, Loop w/delay, Unused*4, Unknown, Autoplay)
	"zoneIndex": Parser.Type.Byte,       # Zone Index
	"audibleRadius": Parser.Type.Word,   # Radius
	"loopDelay": Parser.Type.Word,       # Max Loop Delay
	"volume": Parser.Type.Byte,          # Volume
	"unk0x11": Parser.Type.Byte,         # Only 0 or 128
}

const SOUND_EFFECT_ZONE := {
	"zoneCount": Parser.Type.Word,
	"zone1Dampen": Parser.Type.Byte,
	"zone1Flags": Parser.Type.Byte,
	"zone1XBoundLower": Parser.Type.SignedWord,
	"zone1YBoundLower": Parser.Type.SignedWord,
	"zone1XBoundUpper": Parser.Type.SignedWord,
	"zone1YBoundUpper": Parser.Type.SignedWord,
	"zone2Dampen": Parser.Type.Byte,
	"zone2Flags": Parser.Type.Byte,
	"zone2XBoundLower": Parser.Type.SignedWord,
	"zone2YBoundLower": Parser.Type.SignedWord,
	"zone2XBoundUpper": Parser.Type.SignedWord,
	"zone2YBoundUpper": Parser.Type.SignedWord,
	"zone3Dampen": Parser.Type.Byte,
	"zone3Flags": Parser.Type.Byte,
	"zone3XBoundLower": Parser.Type.SignedWord,
	"zone3YBoundLower": Parser.Type.SignedWord,
	"zone3XBoundUpper": Parser.Type.SignedWord,
	"zone3YBoundUpper": Parser.Type.SignedWord,
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
	"unk0x07": Parser.Type.Byte,  # Flags [bit 8 is start hidden]
	"lighting": Parser.Type.Byte,
	"renderType": Parser.Type.Byte,
	"posZ": Parser.Type.SignedWord,
	"unk0x0C": Parser.Type.Word,
	"unk0x0E": Parser.Type.Word,
}

const NORM_OBJECT := {
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
}

static func parse_bytes(bytes: PackedByteArray, normality: bool) -> Dictionary:
	
	var file: FileAccess = FileAccess.create_temp(FileAccess.WRITE_READ, "roth", "raw")
	if not file:
		Console.print("Could not create temp file")
		return {}
	
	file.store_buffer(bytes)
	file.seek(0)
	var map: Dictionary = parse(file, normality)
	file.close()
	
	return map


static func parse_file(filepath: String, normality: bool) -> Dictionary:
	#print("Parsing: %s" % filepath)
	var file: FileAccess = FileAccess.open(filepath, FileAccess.READ)
	if not file:
		Console.print("Error: File not found: %s" % filepath)
		return {}
	
	var map: Dictionary = parse(file, normality)
	file.close()
	
	return map


static func get_preview(filepath: String, normality: bool) -> Dictionary:
	var file: FileAccess = FileAccess.open(filepath, FileAccess.READ)
	if not file:
		Console.print("Error: File not found: %s" % filepath)
		return {}
	
	var header: Dictionary = {}
	if normality:
		header = Parser.parse_section(file, NORM_HEADER)
	else:
		header = Parser.parse_section(file, HEADER)
	
	var sectors := []
	for i in range(header["sectorCount"]):
		var sector: Dictionary = Parser.parse_section(file, SECTOR)
		sectors.append({
			"floorHeight": sector.floorHeight,
			"facesCount": sector.facesCount,
			"firstFaceOffset": sector.firstFaceOffset
		})
	
	var face_count: int = file.get_16()
	var faces := []
	var faces_offset_map := {}
	for i in range(face_count):
		faces_offset_map[file.get_position()] = i
		faces.append(Parser.parse_section(file, FACE))
	
	file.seek(header["verticesOffset"])
	var vertices_header := Parser.parse_section(file, VERTICES_HEADER)
	var vertices := []
	var vertices_relative_offset_map := {}
	for i in range(vertices_header["verticesCount"]):
		vertices_relative_offset_map[file.get_position() - header["verticesOffset"]] = i
		var vertex := Parser.parse_section(file, VERTEX)
		vertex.x *= -1
		vertex.erase("unk0x00")
		vertex.erase("unk0x02")
		vertex.erase("unk0x04")
		vertex.erase("unk0x06")
		vertices.append(vertex)
	
	var command_header: Dictionary = {"commandCount": 0}
	if not normality:
		command_header = Parser.parse_section(file, COMMAND_HEADER)
		file.seek(header["verticesOffset"] + header["verticesSectionSize"] + header["commandSectionSize"] + header["section7Size"])
	else:
		file.seek(header["verticesOffset"] + header["verticesSectionSize"] + header["section7Size"])
	
	var object_start_position: int = file.get_position()
	var current_position: int = file.get_position()
	var objects_count: int = 0
	for i in range(header["sectorCount"]):
		file.seek(current_position)
		current_position += 0x02
		
		var relative_offset: int = file.get_16()
		if relative_offset == 0x0000:
			continue
		file.seek(object_start_position + relative_offset)
		var objects_container := Parser.parse_section(file, OBJECTS_CONTAINER)
		objects_count += objects_container.count
	
	file.close()
	
	
	for i in range(len(sectors)):
		var sector: Dictionary = sectors[i]
		for j in range(sector["facesCount"]):
			var face_index: int = faces_offset_map[sector["firstFaceOffset"] + 0x0C * j]
			faces[face_index]["sector"] = sector
		sector.erase("facesCount")
		sector.erase("firstFaceOffset")
	
	for face: Dictionary in faces:
		face["v1"] = vertices[vertices_relative_offset_map[face["vertexOffset01"]]]
		face["v2"] = vertices[vertices_relative_offset_map[face["vertexOffset02"]]]
		
		if face["sisterFaceOffset"] != 0xFFFF:
			if face["sisterFaceOffset"] == 0x0000:
				print("Found offset of 0x00. Skipping.")
				continue
			face["sister"] = faces[faces_offset_map[face["sisterFaceOffset"]]]
		
		face.erase("vertexOffset01")
		face.erase("vertexOffset02")
		face.erase("textureMapOffset")
		face.erase("sisterFaceOffset")
		face.erase("sectorOffset")
		face.erase("addCollision")
		face.erase("firstFaceOffset")
	
	
	return {
		faces = faces,
		sector_count = len(sectors),
		vertices_count = len(vertices),
		objects_count = objects_count,
		commands_count = command_header.commandCount
	}


static func parse(file: FileAccess, normality: bool) -> Dictionary:
	# Header
	# -------------
	var header: Dictionary = {}
	if normality:
		header = Parser.parse_section(file, NORM_HEADER)
	else:
		header = Parser.parse_section(file, HEADER)
	
	
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
	var command_header: Dictionary = {}
	var commands: Array = []
	var command_entry_points: Array = []
	if not normality:
		command_header = Parser.parse_section(file, COMMAND_HEADER)
		
		for i in range(15):
			var _entry_command_count := Parser.parse_section(file, ENTRY_COMMAND_COUNT)
		
		var command_entry_points_offsets := []
		for i in range(command_header["commandCount"]):
			var command_offset := Parser.parse_section(file, ENTRY_COMMAND_REFERENCES)
			command_entry_points_offsets.append(command_offset.offset)
		
		var commands_relative_offset_map := {}
		for i in range(command_header["commandCount"]):
			commands_relative_offset_map[file.get_position() - (header["verticesOffset"] + header["verticesSectionSize"])] = i + 1
			var command := Parser.parse_section(file, COMMAND)
			command.erase("size")
			commands.append(command)
		
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
			Parser.parse_section(file, NORM_SOUND_EFFECT) if normality else Parser.parse_section(file, SOUND_EFFECT)
		)
	
	var unk_array_02 := []
	if header["section7Size"] > section_7_header["sizeA"]:
		while file.get_position() < header["section7Size"] + header["commandSectionSize"] + header["verticesOffset"] + header["verticesSectionSize"]:
			unk_array_02.append(
				Parser.parse_section(file, SOUND_EFFECT_ZONE)
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
				Parser.parse_section(file, OBJECT) if not normality else Parser.parse_section(file, NORM_OBJECT)
			)
		sectors[i]["objectInformation"] = objects
	
	
	file.seek(object_start_position + objects_header["size"])
	
	
	# Footer
	# -------------
	var footer := []
	while file.get_position() < file.get_length():
		footer.append(file.get_8())
	
	
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
	parsed_file["sectorsSection"] = { "sectors": sectors }
	parsed_file["facesSection"] = { "faces": faces }
	parsed_file["faceTextureMappingSection"] = { "mappings": texture_mappings }
	if mid_platforms:
		parsed_file["midPlatformsSection"] = { "platforms": mid_platforms }
	parsed_file["mapMetadataSection"] = map_metadata
	parsed_file["verticesSection"] = { "vertices": vertices }
	if not normality:
		parsed_file["commandsSection"] = {
				"header": command_header,
				"entryCommandIndexes": command_entry_points,
				"allCommands": commands
		}
	parsed_file["section7"] = { "unkArray01": unk_array_01 }
	if unk_array_02:
		parsed_file["section7"]["unkArray02"] = unk_array_02
	
	
	return parsed_file


static func compile(json: Dictionary, normality: bool = false) -> PackedByteArray:
	var section_sizes: Dictionary = _calculate_section_sizes_and_offsets(json, normality)
	if section_sizes.verticesSection.startsAt > 65535:
		return []
	var buffer := PackedByteArray()
	buffer.resize(section_sizes.footer.startsAt + section_sizes.footer.size)
	_write_header(buffer, json, section_sizes, normality)
	_write_sectors(buffer, json, section_sizes)
	var texture_mapping_offsets: Array = _write_texture_mapping_section(buffer, json, section_sizes)
	_write_faces(buffer, json, section_sizes, texture_mapping_offsets)
	_write_mid_platform_section(buffer, json, section_sizes)
	_write_map_metadata(buffer, json, section_sizes)
	_write_vertices_section(buffer, json, section_sizes)
	if not normality:
		_write_commands_section(buffer, json, section_sizes)
	_write_section7(buffer, json, section_sizes)
	_write_objects_section(buffer, json, section_sizes)
	_write_footer(buffer, json, section_sizes)
	
	return buffer


static func _calculate_section_sizes_and_offsets(json: Dictionary, normality: bool) -> Dictionary:
	var header := {
		"startsAt": 0x00,
		"size": 0x1E if not normality else 0x1C,
	}
	
	var sectorsSection := {
		"startsAt": header.size,
		"size": len(json.sectorsSection.sectors) * 0x1A + 0x02
	}
	
	var facesSection := {
		"startsAt": sectorsSection.startsAt + sectorsSection.size,
		"size": len(json.facesSection.faces) * 0x0C + 0x02
	}
	
	var texture_mapping_section_size: int = 0x00
	for mapping: Dictionary in json.faceTextureMappingSection.mappings:
		texture_mapping_section_size += 0x0A
		if "additionalMetadata" in mapping and mapping.type & 128 > 0:
			texture_mapping_section_size += 0x04
	
	var textureMappingSection := {
		"startsAt": facesSection.startsAt + facesSection.size,
		"size": texture_mapping_section_size
	}
	
	var midPlatformSection := {
		"startsAt": textureMappingSection.startsAt + textureMappingSection.size + 0x02 if "midPlatformsSection" in json else 0x00,
		"size": len(json.midPlatformsSection.platforms) * 0x0E if "midPlatformsSection" in json else 0x00
	}
	
	var mapMetadataSection := {
		"startsAt": textureMappingSection.startsAt + textureMappingSection.size if midPlatformSection.startsAt == 0x00 else midPlatformSection.startsAt + midPlatformSection.size,
		"size": 0x1C
	}
	
	var verticesSection := {
		"startsAt": mapMetadataSection.startsAt + mapMetadataSection.size,
		"size": 0x08 + len(json.verticesSection.vertices) * 0x0C
	}
	
	var commandSectionSize: int = 0x44 + len(json.commandsSection.allCommands) * 0x02
	for command: Dictionary in json.commandsSection.allCommands:
		commandSectionSize += 0x06 + len(command.args) * 0x02
	
	var commandsSection := {
		"startsAt": verticesSection.startsAt + verticesSection.size,
		"size": commandSectionSize
	}
	
	if normality:
		commandsSection.size = 0
	
	var section7A := {
		"startsAt": commandsSection.startsAt + commandsSection.size,
		"size": 0x04 + len(json.section7.unkArray01) * (0x12 if not normality else 0x10)
	}
	
	var section7B := {
		"startsAt": section7A.startsAt + section7A.size,
		"size": len(json.section7.unkArray02) * 0x20 if "unkArray02" in json.section7 else 0x00
	}
	
	var objectsSectionSize: int = 0x02 + 0x02 * len(json.sectorsSection.sectors)
	for sector: Dictionary in json.sectorsSection.sectors:
		if len(sector.objectInformation) > 0:
			objectsSectionSize += 0x02 + len(sector.objectInformation) * (0x10 if not normality else 0x0E)
	
	var objectsSection := {
		"startsAt": section7B.startsAt + section7B.size,
		"size": objectsSectionSize
	}
	
	var footer := {
		"startsAt": objectsSection.startsAt + objectsSection.size,
		"size": 0x08
	}
	
	return {
		header = header,
		sectorsSection = sectorsSection,
		facesSection = facesSection,
		textureMappingSection = textureMappingSection,
		midPlatformSection = midPlatformSection,
		mapMetadataSection = mapMetadataSection,
		verticesSection = verticesSection,
		commandsSection = commandsSection,
		section7A = section7A,
		section7B = section7B,
		objectsSection = objectsSection,
		footer = footer,
	}


static func _write_header(buffer: PackedByteArray, json: Dictionary, section_sizes: Dictionary, normality: bool) -> void:
	buffer.encode_u16(0x00, section_sizes.verticesSection.startsAt)  # VERTICES_OFFSET
	if normality:
		buffer.encode_u16(0x02, 0x006D)  # VERSION 
	else:
		buffer.encode_u16(0x02, 0x0070)  # VERSION 
	buffer.encode_u16(0x04, section_sizes.sectorsSection.startsAt)  # SECTORS_OFFSET
	buffer.encode_u16(0x06, section_sizes.facesSection.startsAt)  # FACES_OFFSET
	buffer.encode_u16(0x08, section_sizes.textureMappingSection.startsAt)  # FACE_TEXTURE_MAPS_OFFSET
	buffer.encode_u16(0x0A, section_sizes.mapMetadataSection.startsAt)  # MAP_METADATA_OFFSET
	buffer.encode_u16(0x0C, section_sizes.verticesSection.startsAt)  # VERTICES_OFFSET_REPEAT
	buffer.encode_u16(0x0E, 21079)  # SIGNATURE
	buffer.encode_u16(0x10, section_sizes.midPlatformSection.startsAt)  # MID_PLATFORMS_SECTION
	buffer.encode_u16(0x12, section_sizes.section7A.size + section_sizes.section7B.size)  # SECTION_7_SIZE
	buffer.encode_u16(0x14, section_sizes.verticesSection.size)  # VERTICES_SECTION_SIZE
	buffer.encode_u16(0x16, section_sizes.objectsSection.size)  # OBJECTS_SECTION_SIZE
	buffer.encode_u16(0x18, section_sizes.footer.size)  # FOOTER_SIZE
	if not normality:
		buffer.encode_u16(0x1A, section_sizes.commandsSection.size)  # COMMANDS_SECTION_SIZE
		buffer.encode_u16(0x1C, len(json.sectorsSection.sectors))  # SECTOR_COUNT
	else:
		buffer.encode_u16(0x1A, len(json.sectorsSection.sectors))  # SECTOR_COUNT


static func _write_sectors(buffer: PackedByteArray, json: Dictionary, section_sizes: Dictionary) -> void:
	var position: int = section_sizes.sectorsSection.startsAt
	for sector: Dictionary in json.sectorsSection.sectors:
		var first_face_offset: int = section_sizes.facesSection.startsAt + sector.firstFaceIndex * 0x0C
		var mid_platform_offset: int = 0x00
		if section_sizes.midPlatformSection.size > 0x00 and "intermediateFloorIndex" in sector:
			mid_platform_offset = section_sizes.midPlatformSection.startsAt + sector.intermediateFloorIndex * 0x0E
		
		buffer.encode_s16(position, sector.ceilingHeight)
		buffer.encode_s16(position + 0x02, sector.floorHeight)
		buffer.encode_u16(position + 0x04, sector.unk0x04)
		buffer.encode_u16(position + 0x06, sector.ceilingTextureIndex)
		buffer.encode_u16(position + 0x08, sector.floorTextureIndex)
		buffer.encode_u8(position + 0x0A, sector.textureFit)
		buffer.encode_u8(position + 0x0B, sector.lighting)
		buffer.encode_s8(position + 0x0C, sector.textureMapOverride)
		buffer.encode_u8(position + 0x0D, sector.facesCount)
		buffer.encode_u16(position + 0x0E, first_face_offset)
		buffer.encode_u8(position + 0x10, sector.ceilingTextureShiftX)
		buffer.encode_u8(position + 0x11, sector.ceilingTextureShiftY)
		buffer.encode_u8(position + 0x12, sector.floorTextureShiftX)
		buffer.encode_u8(position + 0x13, sector.floorTextureShiftY)
		buffer.encode_u16(position + 0x14, sector.floorTriggerID)
		buffer.encode_u16(position + 0x16, sector.unk0x16)
		buffer.encode_u16(position + 0x18, mid_platform_offset)
		position += 0x1A
	buffer.encode_u16(position, len(json.facesSection.faces))


static func _write_texture_mapping_section(buffer: PackedByteArray, json: Dictionary, section_sizes: Dictionary) -> Array:
	var position: int = section_sizes.textureMappingSection.startsAt
	var offsets := []
	for mapping: Dictionary in json.faceTextureMappingSection.mappings:
		offsets.append(position)
		buffer.encode_u8(position, mapping.unk0x00)
		buffer.encode_u8(position + 0x01, mapping.type)
		buffer.encode_u16(position + 0x02, mapping.midTextureIndex)
		buffer.encode_u16(position + 0x04, mapping.upperTextureIndex)
		buffer.encode_u16(position + 0x06, mapping.lowerTextureIndex)
		buffer.encode_u16(position + 0x08, mapping.unk0x08)
		position += 0x0A
		if "additionalMetadata" in mapping and (mapping.type & 128) > 0:
			buffer.encode_u8(position, mapping.additionalMetadata.shiftTextureX)
			buffer.encode_u8(position + 0x01, mapping.additionalMetadata.shiftTextureY)
			buffer.encode_u16(position + 0x02, mapping.additionalMetadata.unk0x0C)
			position += 0x04
	return offsets


static func _write_faces(buffer: PackedByteArray, json: Dictionary, section_sizes: Dictionary, texture_mapping_offsets: Array) -> void:
	var position: int = section_sizes.facesSection.startsAt
	for face: Dictionary in json.facesSection.faces:
		var vertex_offset_01: int = 0x08 + face.vertexIndex01 * 0x0C
		var vertex_offset_02: int = 0x08 + face.vertexIndex02 * 0x0C
		var texture_mapping_offset: int = texture_mapping_offsets[face.textureMappingIndex]
		var sector_offset: int = section_sizes.sectorsSection.startsAt + face.sectorIndex * 0x1A
		var sister_face_offset: int = 0xFFFF
		if "sisterFaceIndex" in face:
			sister_face_offset = section_sizes.facesSection.startsAt + face.sisterFaceIndex * 0x0C
		
		buffer.encode_u16(position + 0x00, vertex_offset_01)
		buffer.encode_u16(position + 0x02, vertex_offset_02)
		buffer.encode_u16(position + 0x04, texture_mapping_offset)
		buffer.encode_u16(position + 0x06, sector_offset)
		buffer.encode_u16(position + 0x08, sister_face_offset)
		buffer.encode_u16(position + 0x0A, face.addCollision)
		position += 0x0C
	buffer.encode_u16(position, len(json.faceTextureMappingSection.mappings))


static func _write_mid_platform_section(buffer: PackedByteArray, json: Dictionary, section_sizes: Dictionary) -> void:
	var position: int = section_sizes.midPlatformSection.startsAt - 0x02
	if "midPlatformsSection" not in json:
		return
	buffer.encode_u16(position, len(json.midPlatformsSection.platforms))
	position += 0x02
	for platform: Dictionary in json.midPlatformsSection.platforms:
		buffer.encode_u16(position + 0x00, platform.ceilingTextureIndex)
		buffer.encode_s16(position + 0x02, platform.ceilingHeight)
		buffer.encode_u8(position + 0x04, platform.ceilingTextureShiftX)
		buffer.encode_u8(position + 0x05, platform.ceilingTextureShiftY)
		buffer.encode_u16(position + 0x06, platform.floorTextureIndex)
		buffer.encode_s16(position + 0x08, platform.floorHeight)
		buffer.encode_u8(position + 0x0A, platform.floorTextureShiftX)
		buffer.encode_u8(position + 0x0B, platform.floorTextureShiftY)
		buffer.encode_u8(position + 0x0C, platform.floorTextureScale)
		buffer.encode_u8(position + 0x0D, platform.padding)
		position += 0x0E


static func _write_map_metadata(buffer: PackedByteArray, json: Dictionary, section_sizes: Dictionary) -> void:
	var position: int = section_sizes.mapMetadataSection.startsAt
	buffer.encode_s16(position + 0x00, json.mapMetadataSection.initPosX)
	buffer.encode_s16(position + 0x02, json.mapMetadataSection.initPosZ)
	buffer.encode_s16(position + 0x04, json.mapMetadataSection.initPosY)
	buffer.encode_s16(position + 0x06, json.mapMetadataSection.rotation)
	buffer.encode_u16(position + 0x08, json.mapMetadataSection.moveSpeed)
	buffer.encode_u16(position + 0x0A, json.mapMetadataSection.playerHeight)
	buffer.encode_u16(position + 0x0C, json.mapMetadataSection.maxClimb)
	buffer.encode_u16(position + 0x0E, json.mapMetadataSection.minFit)
	buffer.encode_u16(position + 0x10, json.mapMetadataSection.unk0x10)
	buffer.encode_s16(position + 0x12, json.mapMetadataSection.candleGlow)
	buffer.encode_u16(position + 0x14, json.mapMetadataSection.lightAmbience)
	buffer.encode_u16(position + 0x16, json.mapMetadataSection.unk0x16)
	buffer.encode_u16(position + 0x18, json.mapMetadataSection.skyTexture)
	buffer.encode_u16(position + 0x1A, json.mapMetadataSection.unk0x1A)


static func _write_vertices_section(buffer: PackedByteArray, json: Dictionary, section_sizes: Dictionary) -> void:
	var position: int = section_sizes.verticesSection.startsAt
	buffer.encode_u16(position, section_sizes.verticesSection.size)
	buffer.encode_u16(position + 0x02, 0x08)
	buffer.encode_u16(position + 0x04, 0x00)
	buffer.encode_u16(position + 0x06, len(json.verticesSection.vertices))
	position += 0x08
	for vertex: Dictionary in json.verticesSection.vertices:
		buffer.encode_u16(position + 0x00, 0x00)
		buffer.encode_u16(position + 0x02, 0x00)
		buffer.encode_u16(position + 0x04, 0x00)
		buffer.encode_u16(position + 0x06, 0x00)
		buffer.encode_s16(position + 0x08, vertex.x)
		buffer.encode_s16(position + 0x0A, vertex.y)
		position += 0x0C


static func _write_commands_section(buffer: PackedByteArray, json: Dictionary, section_sizes: Dictionary) -> void:
	const command_base_to_category := {
		0x08: 1,
		0x02: 1,
		0x03: 3,
		0x13: 4,
		0x18: 5,
		0x19: 6,
		0x1A: 7,
		0x1B: 8,
		0x25: 9,
		0x32: 11,
		0x31: 12,
		0x30: 13,
		0x37: 14,
		0x39: 15,
	}
	var section_start: int = section_sizes.commandsSection.startsAt
	var all_commands_relative_offset: int = 0x44 + len(json.commandsSection.allCommands) * 0x02
	var all_commands_offset: int = section_start + all_commands_relative_offset
	var entry_command_references_offset: int = section_start + 0x44
	
	var position: int = section_sizes.commandsSection.startsAt
	
	buffer.encode_u16(position, 30003)
	buffer.encode_u16(position + 0x02, json.commandsSection.header.unk0x02)
	buffer.encode_u16(position + 0x04, all_commands_relative_offset)
	buffer.encode_u16(position + 0x06, len(json.commandsSection.allCommands))
	
	position = all_commands_offset
	var all_command_offset := []
	for command: Dictionary in json.commandsSection.allCommands:
		all_command_offset.append(position - section_start)
		var size: int = 0x06 + len(command.args) * 0x02
		buffer.encode_u16(position + 0x00, size)
		buffer.encode_u8(position + 0x02, command.commandModifier)
		buffer.encode_u8(position + 0x03, command.commandBase)
		buffer.encode_u16(position + 0x04, command.nextCommandIndex)
		position += 0x06
		for arg: int in command.args:
			buffer.encode_u16(position, arg)
			position += 0x02
	
	var categories := {}
	var i: int = 0
	for entry_command_index: int in json.commandsSection.entryCommandIndexes:
		var command_type: int = json.commandsSection.allCommands[entry_command_index - 1].commandBase
		var mapped_category: int = command_base_to_category[command_type]
		if mapped_category not in categories:
			categories[mapped_category] = {
				"count": 0,
				"firstCommandIndex": i,
			}
		categories[mapped_category].count += 1
		buffer.encode_u16(entry_command_references_offset + i * 0x02, all_command_offset[entry_command_index - 1])
		i += 1
	
	position = section_start + 0x08
	for j in range(1,16):
		if j in categories:
			var category: Dictionary = categories[j]
			if category.count > 0:
				buffer.encode_u16(position, category.firstCommandIndex * 0x02 + 0x44)
				buffer.encode_u16(position + 0x02, category.count)
		position += 0x04


static func _write_section7(buffer: PackedByteArray, json: Dictionary, section_sizes: Dictionary) -> void:
	var position: int = section_sizes.section7A.startsAt
	buffer.encode_u16(position + 0x00, section_sizes.section7A.size)
	buffer.encode_u16(position + 0x02, len(json.section7.unkArray01))
	position += 0x04
	for array1_obj: Dictionary in json.section7.unkArray01:
		buffer.encode_s16(position + 0x00, array1_obj.posX)
		buffer.encode_s16(position + 0x02, array1_obj.posY)
		buffer.encode_u16(position + 0x04, array1_obj.sfxIndex)
		buffer.encode_u16(position + 0x06, array1_obj.sfxID)
		buffer.encode_u8(position + 0x08, array1_obj.flags)
		buffer.encode_u8(position + 0x09, array1_obj.zoneIndex)
		buffer.encode_u16(position + 0x0A, array1_obj.audibleRadius)
		buffer.encode_u16(position + 0x0C, array1_obj.loopDelay)
		if "unk0x0E" in array1_obj:
			buffer.encode_u16(position + 0x0E, array1_obj.unk0x0E)
			buffer.encode_u8(position + 0x10, array1_obj.volume)
			buffer.encode_u8(position + 0x11, array1_obj.unk0x11)
			position += 0x12
		else:
			buffer.encode_u8(position + 0x0E, array1_obj.volume)
			buffer.encode_u8(position + 0x0F, array1_obj.unk0x11)
			position += 0x10
	if "unkArray02" not in json.section7:
		return
	for array2_obj: Dictionary in json.section7.unkArray02:
		buffer.encode_u16(position + 0x00, array2_obj.zoneCount)
		buffer.encode_u8(position + 0x02, array2_obj.zone1Dampen)
		buffer.encode_u8(position + 0x03, array2_obj.zone1Flags)
		buffer.encode_s16(position + 0x04, array2_obj.zone1XBoundLower)
		buffer.encode_s16(position + 0x06, array2_obj.zone1YBoundLower)
		buffer.encode_s16(position + 0x08, array2_obj.zone1XBoundUpper)
		buffer.encode_s16(position + 0x0A, array2_obj.zone1YBoundUpper)
		buffer.encode_u8(position + 0x0C, array2_obj.zone2Dampen)
		buffer.encode_u8(position + 0x0D, array2_obj.zone2Flags)
		buffer.encode_s16(position + 0x0E, array2_obj.zone2XBoundLower)
		buffer.encode_s16(position + 0x10, array2_obj.zone2YBoundLower)
		buffer.encode_s16(position + 0x12, array2_obj.zone2XBoundUpper)
		buffer.encode_s16(position + 0x14, array2_obj.zone2YBoundUpper)
		buffer.encode_u8(position + 0x16, array2_obj.zone3Dampen)
		buffer.encode_u8(position + 0x17, array2_obj.zone3Flags)
		buffer.encode_s16(position + 0x18, array2_obj.zone3XBoundLower)
		buffer.encode_s16(position + 0x1A, array2_obj.zone3YBoundLower)
		buffer.encode_s16(position + 0x1C, array2_obj.zone3XBoundUpper)
		buffer.encode_s16(position + 0x1E, array2_obj.zone3YBoundUpper)
		position += 0x20


static func _write_objects_section(buffer: PackedByteArray, json: Dictionary, section_sizes: Dictionary) -> void:
	var section_start: int = section_sizes.objectsSection.startsAt
	
	buffer.encode_u16(section_start, section_sizes.objectsSection.size)
	
	var sector_object_mapping_pos: int = section_start + 0x02
	var object_container_pos: int = section_start + 0x02 + len(json.sectorsSection.sectors) * 0x02
	for sector: Dictionary in json.sectorsSection.sectors:
		if len(sector.objectInformation) > 0:
			buffer.encode_u16(sector_object_mapping_pos, object_container_pos - section_start)
			
			buffer.encode_u8(object_container_pos, len(sector.objectInformation))
			buffer.encode_u8(object_container_pos + 0x01, len(sector.objectInformation))
			object_container_pos += 0x02
			for object: Dictionary in sector.objectInformation:
				buffer.encode_s16(object_container_pos + 0x00, object.posX)
				buffer.encode_s16(object_container_pos + 0x02, object.posY)
				buffer.encode_u8(object_container_pos + 0x04, object.textureIndex)
				buffer.encode_u8(object_container_pos + 0x05, object.textureSource)
				buffer.encode_u8(object_container_pos + 0x06, object.rotation)
				buffer.encode_u8(object_container_pos + 0x07, object.unk0x07)
				buffer.encode_u8(object_container_pos + 0x08, object.lighting)
				buffer.encode_u8(object_container_pos + 0x09, object.renderType)
				buffer.encode_s16(object_container_pos + 0x0A, object.posZ)
				buffer.encode_u16(object_container_pos + 0x0C, object.unk0x0C)
				if "unk0x0E" in object:
					buffer.encode_u16(object_container_pos + 0x0E, object.unk0x0E)
					object_container_pos += 0x10
				else:
					object_container_pos += 0x0E
		sector_object_mapping_pos += 0x02


static func _write_footer(buffer: PackedByteArray, _json: Dictionary, section_sizes: Dictionary) -> void:
	const footer := [0x08, 0x00, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00]
	var position: int = section_sizes.footer.startsAt
	for byte: int in footer:
		buffer.encode_u8(position, byte)
		position += 0x01
