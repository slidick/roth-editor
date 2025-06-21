extends BaseWindow

signal texture_selected(texture_index: int)

var das: Dictionary
var vert_tileable: bool = false
var horz_tileable: bool = false
var only_ceilings: bool = false
var rotated_textures: Dictionary = {}

func _fade_out() -> void:
	super._fade_out()
	texture_selected.emit(-1)


func das_ready(p_das: Dictionary) -> void:
	rotated_textures[p_das.name] = {}
	for texture: Dictionary in das.textures:
		if not "image" in texture:
			continue
		


func show_texture(p_das: Dictionary, p_only_ceilings: bool = false) -> void:
	das = p_das
	only_ceilings = p_only_ceilings
	
	
	if das.name not in rotated_textures:
		rotated_textures[das.name] = {}
	
	%TextureList.clear()
	
	if only_ceilings:
		%WallOptions.hide()
	else:
		%WallOptions.show()
	
	for texture: Dictionary in das.textures:
		if not "image" in texture:
			continue
		
		if ( ((only_ceilings or (vert_tileable and horz_tileable))
			and (texture.width > 0
				and (texture.width & (texture.width - 1)) == 0
				and texture.height > 0
				and (texture.height & (texture.height - 1)) == 0
				))
			or (not only_ceilings
				and not vert_tileable
				and not horz_tileable
				)
			or (not only_ceilings
				and vert_tileable
				and not horz_tileable
				and texture.height > 0
				and (texture.height & (texture.height - 1)) == 0
				)
			or (not only_ceilings
				and horz_tileable
				and not vert_tileable
				and texture.width > 0
				and (texture.width & (texture.width - 1)) == 0
				)
		):
			var index: int = %TextureList.add_item("%s: %s (%s) %sx%s" % [texture["index"], texture["name"], texture["desc"], texture["width"], texture["height"]])
			%TextureList.set_item_metadata(index, texture)
			var image_texture: ImageTexture = texture.image[0] if typeof(texture.image) == TYPE_ARRAY else texture.image
			if not only_ceilings:
				if texture.index in rotated_textures[das.name]:
					print("Getting stored")
					image_texture = rotated_textures[das.name][texture.index]
				else:
					var rotated_image: Image = image_texture.get_image()
					rotated_image.rotate_90(CLOCKWISE)
					rotated_image.flip_x()
					image_texture = ImageTexture.create_from_image(rotated_image)
					rotated_textures[das.name][texture.index] = image_texture
				
			%TextureList.set_item_icon(index, image_texture)
	
	toggle(true)



func _on_texture_list_item_activated(index: int) -> void:
	texture_selected.emit(%TextureList.get_item_metadata(index).index)
	toggle(false)


func _on_tileable_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		vert_tileable = true
		horz_tileable = false
		show_texture(das, only_ceilings)


func _on_horz_tileable_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		horz_tileable = true
		vert_tileable = false
		show_texture(das, only_ceilings)


func _on_all_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		horz_tileable = false
		vert_tileable = false
		show_texture(das, only_ceilings)


func _on_both_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		horz_tileable = true
		vert_tileable = true
		show_texture(das, only_ceilings)
