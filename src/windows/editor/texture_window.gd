extends BaseWindow

signal texture_selected(texture_index: int)

var current_das: Dictionary = {}
var vert_tileable: bool = false
var horz_tileable: bool = false
var only_ceilings: bool = false
var loaded_das: Dictionary = {}
var favorites: Dictionary = {}
var recents: Dictionary = {}
var selected_favorite: int = -1


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			Settings.update_cache("recent_textures", recents)


func _ready() -> void:
	super._ready()
	favorites = Settings.settings.get("favorite_textures", {})
	for das_name: String in favorites:
		for i in range(len(favorites[das_name])):
			favorites[das_name][i] = int(favorites[das_name][i])
	
	recents = Settings.cache.get("recent_textures", {})
	for das_name: String in recents:
		for i in range(len(recents[das_name])):
			recents[das_name][i] = int(recents[das_name][i])


func _fade_out() -> void:
	super._fade_out()
	texture_selected.emit(-1)


func das_ready(p_das: Dictionary) -> void:
	loaded_das[p_das.name] = {}
	if p_das.name not in favorites:
		favorites[p_das.name] = []
	if p_das.name not in recents:
		recents[p_das.name] = []
	for texture: Dictionary in p_das.textures:
		if not "image" in texture:
			continue
		var texture_select_node := TextureSelectNode.new(texture)
		texture_select_node.selected.connect(_on_texture_list_item_activated)
		texture_select_node.add_to_favorites_selected.connect(_on_add_to_favorites_selected)
		%TextureContainer.add_child(texture_select_node)
		loaded_das[p_das.name][texture.index] = texture_select_node


func show_texture(p_das: Dictionary, p_only_ceilings: bool = false) -> void:
	current_das = p_das
	only_ceilings = p_only_ceilings
	
	if only_ceilings:
		%WallOptions.hide()
	else:
		%WallOptions.show()
	
	if p_das.name not in loaded_das:
		das_ready(p_das)
	
	#%TextureList.clear()
	#for child: Control in %TextureContainer.get_children():
		#child.queue_free()
	
	for das_name: String in loaded_das:
		for texture_index: int in loaded_das[das_name]:
			var texture_select_node: TextureSelectNode = loaded_das[das_name][texture_index]
			texture_select_node.hide()
	
	%FavoritesList.clear()
	for texture_index: int in favorites[p_das.name]:
		var texture_data: Dictionary = p_das.mapping[texture_index]
		var idx: int = %FavoritesList.add_item("%s: %s" % [texture_data.index, texture_data.name], texture_data.image[0] if typeof(texture_data.image) == TYPE_ARRAY else texture_data.image)
		%FavoritesList.set_item_metadata(idx, texture_data)
	
	%RecentlyUsedList.clear()
	for texture_index: int in recents[p_das.name]:
		var texture_data: Dictionary = p_das.mapping[texture_index]
		var idx: int = %RecentlyUsedList.add_item("%s: %s" % [texture_data.index, texture_data.name], texture_data.image[0] if typeof(texture_data.image) == TYPE_ARRAY else texture_data.image)
		%RecentlyUsedList.set_item_metadata(idx, texture_data)
	
	#for das_name: String in loaded_das:
	for texture_index: int in loaded_das[p_das.name]:
		var texture_select_node: TextureSelectNode = loaded_das[p_das.name][texture_index]
		var texture: Dictionary = texture_select_node.texture_data
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
			
			texture_select_node.show()
			if only_ceilings:
				texture_select_node.set_rotated(false)
			else:
				texture_select_node.set_rotated(true)

	
	toggle(true)



func _on_texture_list_item_activated(index: int) -> void:
	#texture_selected.emit(%TextureList.get_item_metadata(index).index)
	texture_selected.emit(index)
	toggle(false)


func _on_add_to_favorites_selected(texture_data: Dictionary) -> void:
	if texture_data.index in favorites[current_das.name]:
		return
	var idx: int = %FavoritesList.add_item("%s: %s" % [texture_data.index, texture_data.name], texture_data.image[0] if typeof(texture_data.image) == TYPE_ARRAY else texture_data.image)
	%FavoritesList.set_item_metadata(idx, texture_data)
	favorites[current_das.name].append(texture_data.index)
	Settings.update_settings("favorite_textures", favorites)


func _on_tileable_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		vert_tileable = true
		horz_tileable = false
		show_texture(current_das, only_ceilings)


func _on_horz_tileable_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		horz_tileable = true
		vert_tileable = false
		show_texture(current_das, only_ceilings)


func _on_all_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		horz_tileable = false
		vert_tileable = false
		show_texture(current_das, only_ceilings)


func _on_both_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		horz_tileable = true
		vert_tileable = true
		show_texture(current_das, only_ceilings)


func _on_favorites_list_item_activated(index: int) -> void:
	texture_selected.emit(%FavoritesList.get_item_metadata(index).index)
	toggle(false)


func _on_favorites_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		selected_favorite = index
		%FavoritesPopupMenu.popup(Rect2i(int(%FavoritesList.global_position.x + at_position.x), int(%FavoritesList.global_position.y + at_position.y), 0, 0))


func _on_favorites_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			print("Remove index: %s" % selected_favorite)
			%FavoritesList.remove_item(selected_favorite)
			favorites[current_das.name].pop_at(selected_favorite)
			selected_favorite = -1
			Settings.update_settings("favorite_textures", favorites)


func _on_recently_used_list_item_activated(index: int) -> void:
	texture_selected.emit(%RecentlyUsedList.get_item_metadata(index).index)
	toggle(false)


func _on_texture_selected(texture_index: int) -> void:
	if texture_index == -1:
		return
	
	for i in range(%RecentlyUsedList.item_count):
		if texture_index == %RecentlyUsedList.get_item_metadata(i).index:
			%RecentlyUsedList.move_item(i, 0)
			recents[current_das.name].pop_at(i)
			recents[current_das.name].push_front(texture_index)
			return
	
	var texture_data: Dictionary = current_das.mapping[texture_index]
	var idx: int = %RecentlyUsedList.add_item("%s: %s" % [texture_data.index, texture_data.name], texture_data.image[0] if typeof(texture_data.image) == TYPE_ARRAY else texture_data.image)
	%RecentlyUsedList.set_item_metadata(idx, texture_data)
	%RecentlyUsedList.move_item(idx, 0)
	recents[current_das.name].push_front(texture_index)
	
	if len(recents[current_das.name]) > 20:
		recents[current_das.name].pop_back()
		%RecentlyUsedList.remove_item(20)
