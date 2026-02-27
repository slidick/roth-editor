extends BaseWindow

signal texture_selected(texture_index: int)

var current_das: Dictionary = {}
var vert_tileable: bool = false
var horz_tileable: bool = false
var only_ceilings: bool = false
var loaded_das: Dictionary = {}
var favorites: Dictionary = {}
var recents: Dictionary = {}


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			Settings.update_cache("recent_textures", recents)


func _ready() -> void:
	super._ready()
	favorites = Settings.settings.get("favorite_textures", {})
	recents = Settings.cache.get("recent_textures", {})


func _fade_out() -> void:
	super._fade_out()
	texture_selected.emit(-1)
	%SearchEdit.clear()


func init_das(p_das: Dictionary) -> void:
	loaded_das[p_das.name] = {}
	if p_das.name not in favorites:
		favorites[p_das.name] = []
	if p_das.name not in recents:
		recents[p_das.name] = []
	for texture: Dictionary in p_das.textures:
		if not "image" in texture:
			continue
		var tex: Texture2D = texture.image[0] if typeof(texture.image) == TYPE_ARRAY else texture.image
		var idx: int = %RotatableItemList.add_item("%s: %s\n%s x %s" % [texture.index, texture.name, texture.height, texture.width], tex, Vector2(150,150), Array(["Add to Favorites"], TYPE_STRING, "", null))
		%RotatableItemList.set_item_metadata(idx, texture)


func show_texture(p_das: Dictionary, p_only_ceilings: bool = false, p_selected_index: int = -1) -> void:
	current_das = p_das
	only_ceilings = p_only_ceilings
	
	if only_ceilings:
		%WallOptions.hide()
	else:
		%WallOptions.show()
	
	if p_das.name not in loaded_das:
		init_das(p_das)
	
	
	%FavoriteItemList.clear()
	for texture_index: int in favorites[p_das.name]:
		var texture_data: Dictionary = p_das.mapping[texture_index]
		if is_viable(texture_data):
			var idx: int = %FavoriteItemList.add_item("%s" % [texture_data.name], texture_data.image[0] if typeof(texture_data.image) == TYPE_ARRAY else texture_data.image, Vector2(75,75), Array(["Remove from Favorites"], TYPE_STRING, "", null))
			%FavoriteItemList.set_item_metadata(idx, texture_data)
			if only_ceilings:
				%FavoriteItemList.set_rotated(idx, false)
	
	
	%RecentItemList.clear()
	for texture_index: int in recents[p_das.name]:
		var texture_data: Dictionary = p_das.mapping[texture_index]
		if is_viable(texture_data):
			var idx: int = %RecentItemList.add_item("%s" % [texture_data.name], texture_data.image[0] if typeof(texture_data.image) == TYPE_ARRAY else texture_data.image, Vector2(75,75))
			%RecentItemList.set_item_metadata(idx, texture_data)
			if only_ceilings:
				%RecentItemList.set_rotated(idx, false)
	
	
	for i in range(%RotatableItemList.item_count):
		var texture: Dictionary = %RotatableItemList.get_item_metadata(i)
		if is_viable(texture):
			%RotatableItemList.set_hidden(i, false)
			if only_ceilings:
				%RotatableItemList.set_rotated(i, false)
			else:
				%RotatableItemList.set_rotated(i, true)
		else:
			%RotatableItemList.set_hidden(i, true)
	
	for i in range(%RotatableItemList.item_count):
		var texture_data: Dictionary = %RotatableItemList.get_item_metadata(i)
		if texture_data.index == p_selected_index:
			%RotatableItemList.select(i)
			%RotatableItemList.scroll_to_index(i)
	
	if p_selected_index == -1:
		%RotatableItemList.select(-1)
	
	toggle(true)


func is_viable(texture_data: Dictionary) -> bool:
	if texture_data.das.get_file().get_basename() != current_das.name:
		return false
	if ( ((only_ceilings or (vert_tileable and horz_tileable))
		and (texture_data.width > 0
			and (texture_data.width & (texture_data.width - 1)) == 0
			and texture_data.height > 0
			and (texture_data.height & (texture_data.height - 1)) == 0
			))
		or (not only_ceilings
			and not vert_tileable
			and not horz_tileable
			)
		or (not only_ceilings
			and vert_tileable
			and not horz_tileable
			and texture_data.width > 0
			and (texture_data.width & (texture_data.width - 1)) == 0
			)
		or (not only_ceilings
			and horz_tileable
			and not vert_tileable
			and texture_data.height > 0
			and (texture_data.height & (texture_data.height - 1)) == 0
			)
	):
		return true
	else:
		return false


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


func _on_favorite_item_list_item_activated(index: int) -> void:
	texture_selected.emit(%FavoriteItemList.get_item_metadata(index).index)
	%SearchEdit.clear()
	add_to_recents(%FavoriteItemList.get_item_metadata(index).index)
	toggle(false)


func _on_favorite_item_list_context_option_selected(index: int, context_index: int) -> void:
	match context_index:
		0:
			var texture_index: int = %FavoriteItemList.get_item_metadata(index).index
			%FavoriteItemList.remove_item(index)
			var idx: int = favorites[current_das.name].find(texture_index)
			if idx == -1:
				idx = favorites[current_das.name].find(float(texture_index))
			favorites[current_das.name].pop_at(idx)
			Settings.update_settings("favorite_textures", favorites)


func _on_recent_item_list_item_activated(index: int) -> void:
	texture_selected.emit(%RecentItemList.get_item_metadata(index).index)
	%SearchEdit.clear()
	add_to_recents(%RecentItemList.get_item_metadata(index).index)
	toggle(false)


func add_to_recents(texture_index: int) -> void:
	if texture_index == -1:
		return
	
	if (texture_index in recents[current_das.name]
		or float(texture_index) in recents[current_das.name]
	):
		var idx: int = recents[current_das.name].find(texture_index)
		if idx == -1:
			idx = recents[current_das.name].find(float(texture_index))
		recents[current_das.name].pop_at(idx)
		recents[current_das.name].push_front(texture_index)
		return
	
	recents[current_das.name].push_front(texture_index)
	
	if len(recents[current_das.name]) > 20:
		recents[current_das.name].pop_back()


func _on_rotatable_item_list_item_activated(index: int) -> void:
	texture_selected.emit(%RotatableItemList.get_item_metadata(index).index)
	%SearchEdit.clear()
	add_to_recents(%RotatableItemList.get_item_metadata(index).index)
	toggle(false)


func _on_rotatable_item_list_context_option_selected(index: int, context_index: int) -> void:
	match context_index:
		0:
			var texture_data: Dictionary = %RotatableItemList.get_item_metadata(index)
			if texture_data.index in favorites[current_das.name]:
				return
			var idx: int = %FavoriteItemList.add_item("%s" % [texture_data.name], texture_data.image[0] if typeof(texture_data.image) == TYPE_ARRAY else texture_data.image, Vector2(75,75), Array(["Remove from Favorites"], TYPE_STRING, "", null))
			%FavoriteItemList.set_item_metadata(idx, texture_data)
			favorites[current_das.name].append(texture_data.index)
			Settings.update_settings("favorite_textures", favorites)


func _on_rotatable_item_list_item_selected(index: int) -> void:
	%FavoriteItemList.deselect_all()
	%RecentItemList.deselect_all()
	var texture_data: Dictionary = %RotatableItemList.get_item_metadata(index)
	if index == -1:
		texture_data = {}
	display_texture_data(texture_data)
	
func display_texture_data(texture_data: Dictionary) -> void:
	for child: Node in %InfoContainer.get_children():
		child.queue_free()
	if texture_data.is_empty():
		return
	for key: String in texture_data:
		var label := Label.new()
		label.text = "%s: %s" % [key, texture_data[key]]
		%InfoContainer.add_child(label)


func _on_favorite_item_list_item_selected(index: int) -> void:
	%RecentItemList.deselect_all()
	%RotatableItemList.deselect_all()
	display_texture_data(%FavoriteItemList.get_item_metadata(index))


func _on_recent_item_list_item_selected(index: int) -> void:
	%FavoriteItemList.deselect_all()
	%RotatableItemList.deselect_all()
	display_texture_data(%RecentItemList.get_item_metadata(index))


func _on_search_edit_text_changed(search_text: String) -> void:
	for i in range(%RotatableItemList.item_count):
		var texture: Dictionary = %RotatableItemList.get_item_metadata(i)
		if is_viable(texture) and (search_text.to_upper() in texture.name.to_upper() or search_text.to_upper() in texture.desc.to_upper() or search_text.is_empty()):
			%RotatableItemList.set_hidden(i, false)
		else:
			%RotatableItemList.set_hidden(i, true)
