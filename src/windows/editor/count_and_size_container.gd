extends FoldableContainer


func _on_recalculate_button_pressed() -> void:
	recalculate()


func recalculate() -> void:
	if not %Map2D.map:
		%CountMapNameLabel.text = "No Map Loaded"
		%SectorsCountLabel.text = ""
		%SectorsSizeTotalLabel.text = ""
		%FacesCountLabel.text = ""
		%FacesSizeTotalLabel.text = ""
		%TexturesCountLabel.text = ""
		%TexturesSizeTotalLabel.text = ""
		%TexturesAdditionalCountLabel.text = ""
		%TexturesAdditionalSizeTotal.text = ""
		%PlatformsCountLabel.text = ""
		%PlatformsSizeLabel.text =  ""
		%SizeTotalLabel.text = ""
		#folded = true
		return
	
	var map: Map = %Map2D.map
	%CountMapNameLabel.text = map.map_info.name
	
	%SectorsCountLabel.text = "%d" % len(map.sectors)
	%SectorsSizeTotalLabel.text = "%d" % (len(map.sectors) * 26)
	
	%FacesCountLabel.text = "%d" % len(map.faces)
	%FacesSizeTotalLabel.text = "%d" % (len(map.faces) * 12)
	
	var texture_counts: Array = map.get_texture_mappings_counts()
	%TexturesCountLabel.text = "%d" % texture_counts[0]
	%TexturesSizeTotalLabel.text = "%d" % (texture_counts[0] * 10)
	
	%TexturesAdditionalCountLabel.text = "%d" % texture_counts[1]
	%TexturesAdditionalSizeTotal.text = "%d" % (texture_counts[1] * 4)
	
	var platforms_count: int = 0
	for sector: Sector in map.sectors:
		if sector.platform:
			platforms_count += 1
	
	%PlatformsCountLabel.text = "%d" % platforms_count
	var platforms_size: int = platforms_count * 14
	if platforms_count > 0:
		platforms_size += 2
	%PlatformsSizeLabel.text =  "%d" % platforms_size
	
	var total: int = (
		(len(map.sectors) * 26) +
		(len(map.faces) * 12) +
		(texture_counts[0] * 10) +
		(texture_counts[1] * 4) +
		platforms_size
	)
	
	%SizeTotalLabel.text = "%d" % total
	if total > 65474:
		%SizeTotalLabel.add_theme_color_override("font_color", Color.RED)
	else:
		%SizeTotalLabel.add_theme_color_override("font_color", Color.GREEN)
