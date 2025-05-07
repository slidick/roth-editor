extends RefCounted
class_name Map

var metadata := {}
var sectors := []
var faces := []
var objects := []
var sound_effects := []
var section7_2 := []
var vertices_count: int = 0
var map_info := {}
var commands_section := {}

func _init(p_map_info: Dictionary) -> void:
	var filepath: String
	if p_map_info.custom:
		filepath = Roth.ROTH_CUSTOM_MAP_DIRECTORY.path_join(p_map_info.raw)
	else:
		filepath = Roth.directory.path_join(p_map_info.raw)
	Console.print("Loading map: %s" % filepath)
	
	map_info = p_map_info
	
	var map_json: Dictionary = Raw.parse_file(filepath)
	
	var temp_object_list := []
	
	
	for i in range(len(map_json.sectorsSection.sectors)):
		sectors.append( Sector.new( 
				map_json.sectorsSection.sectors[i],
				i,
				map_info,
				map_json.midPlatformsSection.platforms if "midPlatformsSection" in map_json else [],
			)
		)
		for object: Dictionary in sectors[i].data.objectInformation:
			object["sector_index"] = i
			temp_object_list.append(object)
	
	for i in range(len(temp_object_list)):
		objects.append( ObjectRoth.new(
				temp_object_list[i],
				i,
				map_info,
				sectors
			)
		)
	
	for i in range(len(map_json.facesSection.faces)):
		faces.append( Face.new(
				map_json.facesSection.faces[i],
				i,
				map_info,
				map_json.verticesSection.vertices,
				sectors,
				map_json.faceTextureMappingSection.mappings,
			)
		)
	
	for face: Face in faces:
		face.update_sister_face(faces)
	
	for sector: Sector in sectors:
		sector.update_faces(faces)
	
	for i in range(len(map_json.section7.unkArray01)):
		sound_effects.append(Section7_1.new(map_json.section7.unkArray01[i], i, map_info))
	
	if "unkArray02" in map_json.section7:
		section7_2 = map_json.section7.unkArray02
	
	metadata = map_json.mapMetadataSection
	vertices_count = len(map_json.verticesSection.vertices)
	commands_section = map_json.commandsSection


func compile(player_position: Variant = null, player_rotation: Variant = null) -> PackedByteArray:
	var json := {}
	json["mapMetadataSection"] = metadata.duplicate()
	json["sectorsSection"] = { "sectors": sectors.map(func (sector: Sector) -> Dictionary: return sector.data) }
	json["facesSection"] = { "faces": faces.map(func (face: Face) -> Dictionary: return face.data) }
	
	var texture_mappings := []
	for face: Face in faces:
		if face.texture_data not in texture_mappings:
			texture_mappings.append(face.texture_data)
			face.data["textureMappingIndex"] = len(texture_mappings) - 1
		else:
			face.data["textureMappingIndex"] = texture_mappings.find(face.texture_data)
	
	json["faceTextureMappingSection"] = { "mappings": texture_mappings }
	
	var platforms := []
	for sector: Sector in sectors:
		if sector.platform.is_empty():
			sector.data.erase("intermediateFloorIndex")
		else:
			platforms.append(sector.platform)
			sector.data["intermediateFloorIndex"] = len(platforms) - 1

	if not platforms.is_empty():
		json["midPlatformsSection"] = { "platforms": platforms }
	
	var vertices := []
	for face: Face in faces:
		var v1: Dictionary = {
			"x": -int(face.v1.x),
			"y": int(face.v1.y)
		}
		if v1 not in vertices:
			vertices.append(v1)
			face.data["vertexIndex01"] = len(vertices)-1
		else:
			face.data["vertexIndex01"] = vertices.find(v1)
		var v2: Dictionary = {
			"x": -int(face.v2.x),
			"y": int(face.v2.y)
		}
		if v2 not in vertices:
			vertices.append(v2)
			face.data["vertexIndex02"] = len(vertices)-1
		else:
			face.data["vertexIndex02"] = vertices.find(v2)
	
	json["verticesSection"] = { "vertices": vertices }
	json["commandsSection"] = commands_section
	json["section7"] = { "unkArray01": sound_effects.map(func (sfx: Section7_1) -> Dictionary: return sfx.data) }
	if section7_2:
		json["section7"]["unkArray02"] = section7_2
	
	
	
	if player_position:
		json["mapMetadataSection"]["initPosX"] = -player_position.x
		json["mapMetadataSection"]["initPosY"] = player_position.z
		json["mapMetadataSection"]["initPosZ"] = player_position.y
	if player_rotation:
		json["mapMetadataSection"]["rotation"] = player_rotation
	
	
	var section_sizes: Dictionary = calculate_section_sizes_and_offsets(json)
	var buffer := PackedByteArray()
	buffer.resize(section_sizes.footer.startsAt + section_sizes.footer.size)
	
	write_header(buffer, json, section_sizes)
	write_sectors(buffer, json, section_sizes)
	var texture_mapping_offsets: Array = write_texture_mapping_section(buffer, json, section_sizes)
	write_faces(buffer, json, section_sizes, texture_mapping_offsets)
	write_mid_platform_section(buffer, json, section_sizes)
	write_map_metadata(buffer, json, section_sizes)
	write_vertices_section(buffer, json, section_sizes)
	write_commands_section(buffer, json, section_sizes)
	write_section7(buffer, json, section_sizes)
	write_objects_section(buffer, json, section_sizes)
	write_footer(buffer, json, section_sizes)
	
	return buffer


func calculate_section_sizes_and_offsets(json: Dictionary) -> Dictionary:
	var header := {
		"startsAt": 0x00,
		"size": 0x1E,
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
	
	var section7A := {
		"startsAt": commandsSection.startsAt + commandsSection.size,
		"size": 0x04 + len(json.section7.unkArray01) * 0x12
	}
	
	var section7B := {
		"startsAt": section7A.startsAt + section7A.size,
		"size": len(json.section7.unkArray02) * 0x20 if "unkArray02" in json.section7 else 0x00
	}
	
	var objectsSectionSize: int = 0x02 + 0x02 * len(json.sectorsSection.sectors)
	for sector: Dictionary in json.sectorsSection.sectors:
		if len(sector.objectInformation) > 0:
			objectsSectionSize += 0x02 + len(sector.objectInformation) * 0x10
	
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


func write_header(buffer: PackedByteArray, json: Dictionary, section_sizes: Dictionary) -> void:
	buffer.encode_u16(0x00, section_sizes.verticesSection.startsAt)  # VERTICES_OFFSET
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
	buffer.encode_u16(0x1A, section_sizes.commandsSection.size)  # COMMANDS_SECTION_SIZE
	buffer.encode_u16(0x1C, len(json.sectorsSection.sectors))  # SECTOR_COUNT


func write_sectors(buffer: PackedByteArray, json: Dictionary, section_sizes: Dictionary) -> void:
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


func write_texture_mapping_section(buffer: PackedByteArray, json: Dictionary, section_sizes: Dictionary) -> Array:
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
		if "additionalMetadata" in mapping and mapping.type & 128 > 0:
			buffer.encode_u8(position, mapping.additionalMetadata.shiftTextureX)
			buffer.encode_u8(position + 0x01, mapping.additionalMetadata.shiftTextureY)
			buffer.encode_u16(position + 0x02, mapping.additionalMetadata.unk0x0C)
			position += 0x04
	return offsets


func write_faces(buffer: PackedByteArray, json: Dictionary, section_sizes: Dictionary, texture_mapping_offsets: Array) -> void:
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


func write_mid_platform_section(buffer: PackedByteArray, json: Dictionary, section_sizes: Dictionary) -> void:
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


func write_map_metadata(buffer: PackedByteArray, json: Dictionary, section_sizes: Dictionary) -> void:
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


func write_vertices_section(buffer: PackedByteArray, json: Dictionary, section_sizes: Dictionary) -> void:
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


func write_commands_section(buffer: PackedByteArray, json: Dictionary, section_sizes: Dictionary) -> void:
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


func write_section7(buffer: PackedByteArray, json: Dictionary, section_sizes: Dictionary) -> void:
	var position: int = section_sizes.section7A.startsAt
	buffer.encode_u16(position + 0x00, section_sizes.section7A.size)
	buffer.encode_u16(position + 0x02, len(json.section7.unkArray01))
	position += 0x04
	for array1_obj: Dictionary in json.section7.unkArray01:
		buffer.encode_s16(position + 0x00, array1_obj.unk0x00)
		buffer.encode_s16(position + 0x02, array1_obj.unk0x02)
		buffer.encode_u16(position + 0x04, array1_obj.unk0x04)
		buffer.encode_u16(position + 0x06, array1_obj.unk0x06)
		buffer.encode_u16(position + 0x08, array1_obj.unk0x08)
		buffer.encode_u16(position + 0x0A, array1_obj.unk0x0A)
		buffer.encode_u16(position + 0x0C, array1_obj.unk0x0C)
		buffer.encode_u16(position + 0x0E, array1_obj.unk0x0E)
		buffer.encode_u16(position + 0x10, array1_obj.unk0x10)
		position += 0x12
	if "unkArray02" not in json.section7:
		return
	for array2_obj: Dictionary in json.section7.unkArray02:
		buffer.encode_u16(position + 0x00, array2_obj.unk0x00)
		buffer.encode_u16(position + 0x02, array2_obj.unk0x02)
		buffer.encode_u16(position + 0x04, array2_obj.unk0x04)
		buffer.encode_u16(position + 0x06, array2_obj.unk0x06)
		buffer.encode_u16(position + 0x08, array2_obj.unk0x08)
		buffer.encode_u16(position + 0x0A, array2_obj.unk0x0A)
		buffer.encode_u16(position + 0x0C, array2_obj.unk0x0C)
		buffer.encode_u16(position + 0x0E, array2_obj.unk0x0E)
		buffer.encode_u16(position + 0x10, array2_obj.unk0x10)
		buffer.encode_u16(position + 0x12, array2_obj.unk0x12)
		buffer.encode_u16(position + 0x14, array2_obj.unk0x14)
		buffer.encode_u16(position + 0x16, array2_obj.unk0x16)
		buffer.encode_u16(position + 0x18, array2_obj.unk0x18)
		buffer.encode_u16(position + 0x1A, array2_obj.unk0x1A)
		buffer.encode_u16(position + 0x1C, array2_obj.unk0x1C)
		buffer.encode_u16(position + 0x1E, array2_obj.unk0x1E)
		position += 0x20


func write_objects_section(buffer: PackedByteArray, json: Dictionary, section_sizes: Dictionary) -> void:
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
				buffer.encode_u16(object_container_pos + 0x0E, object.unk0x0E)
				object_container_pos += 0x10
		sector_object_mapping_pos += 0x02


func write_footer(buffer: PackedByteArray, _json: Dictionary, section_sizes: Dictionary) -> void:
	const footer := [0x08, 0x00, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00]
	var position: int = section_sizes.footer.startsAt
	for byte: int in footer:
		buffer.encode_u8(position, byte)
		position += 0x01


class MapNode3D extends Node3D:
	var map_info: Dictionary
	var ref: Map
