extends BaseWindow

signal item_selected(object: Dictionary)

var recents: Array = []
var favorites: Array = []


func _fade_out() -> void:
	super._fade_out()
	item_selected.emit({})


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			Settings.update_cache("objects", {"recents": recents})


func _ready() -> void:
	super._ready()
	var objects: Dictionary = Settings.cache.get("objects", {})
	if "recents" in objects:
		recents = objects.recents
	objects = Settings.settings.get("objects", {})
	if "favorites" in objects:
		favorites = objects.favorites


func wait_for_object_selection(p_current_object: ObjectRoth) -> Dictionary:
	%RotatableItemList.clear()
	%RecentItemList.clear()
	%FavoriteItemList.clear()
	%SearchEdit.show()
	load_das(p_current_object.map.das)
	load_favorites(p_current_object.map.das.das_info)
	load_recents(p_current_object.map.das.das_info)
	load_ademo(true)
	_on_search_edit_text_changed(%SearchEdit.text)
	select_object(p_current_object)
	toggle(true)
	var selected_object: Dictionary = await item_selected
	toggle(false)
	return selected_object


func ademo_object_selection() -> Dictionary:
	%FavRecentContainer.hide()
	%InfoContainer.hide()
	%RotatableItemList.clear()
	%RecentItemList.clear()
	%FavoriteItemList.clear()
	%SearchEdit.show()
	%SearchEdit.clear()
	load_ademo(false)
	toggle(true)
	var item: Dictionary = await item_selected
	toggle(false)
	if item.is_empty():
		return {}
	
	return item


func dbase200_object_selection(dbase100: Dictionary) -> Dictionary:
	%FavRecentContainer.hide()
	%InfoContainer.hide()
	%RotatableItemList.clear()
	%SearchEdit.hide()
	load_dbase200(dbase100)
	toggle(true)
	var item: Dictionary = await item_selected
	toggle(false)
	return item


func dbase300_object_selection(dbase100: Dictionary) -> Dictionary:
	%FavRecentContainer.hide()
	%InfoContainer.hide()
	%RotatableItemList.clear()
	%SearchEdit.hide()
	load_dbase300(dbase100)
	toggle(true)
	var item: Dictionary = await item_selected
	toggle(false)
	return item


func load_das(p_das: Dictionary) -> void:
	var das: Dictionary = p_das
	for texture: Dictionary in das.textures:
		if texture.index >= 4096 and texture.index < 4352:
			if texture.name == "Invalid":
				continue
			var tex: Texture2D
			if "image" in texture:
				tex = texture.image[0] if typeof(texture.image) == TYPE_ARRAY else texture.image
			elif "monster_index" in texture:
				var monster_texture: Dictionary = das.mapping[texture.monster_index]
				tex = monster_texture.image
			elif "directional_index" in texture:
				var directional_texture: Dictionary = das.mapping[texture.directional_index]
				tex = directional_texture.image
			else:
				tex =  ImageTexture.create_from_image(Image.create_empty(1,1, false, Image.FORMAT_L8))
			
			var idx: int = %RotatableItemList.add_item("%s: %s\n%s x %s" % [texture.index, texture.name, texture.height, texture.width], tex, Vector2(150,150), Array(["Add to Favorites"], TYPE_STRING, "", null))
			%RotatableItemList.set_item_metadata(idx, texture)


func load_favorites(p_das_info: Dictionary) -> void:
	var active_ademo: Dictionary = Roth.get_active_ademo()
	for favorite_data: Dictionary in favorites:
		var das_info: Dictionary = Roth.get_das_info_by_name(favorite_data.das)
		var texture_data: Dictionary = Roth.get_index_from_das(favorite_data.index, das_info)
		var tex: Texture2D
		if "image" in texture_data:
			tex = texture_data.image[0] if typeof(texture_data.image) == TYPE_ARRAY else texture_data.image
		else:
			tex =  ImageTexture.create_from_image(Image.create_empty(1,1, false, Image.FORMAT_L8))
		var idx: int = %FavoriteItemList.add_item("%s" % [texture_data.name], tex, Vector2(75,75), Array(["Remove from Favorites"], TYPE_STRING, "", null))
		%FavoriteItemList.set_item_metadata(idx, texture_data)
		if texture_data.das_info.name != p_das_info.name and texture_data.das_info != active_ademo:
			%FavoriteItemList.set_hidden(idx, true)


func load_recents(p_das_info: Dictionary) -> void:
	var active_ademo: Dictionary = Roth.get_active_ademo()
	for recent_data: Dictionary in recents:
		var das_info: Dictionary = Roth.get_das_info_by_name(recent_data.das)
		var texture_data: Dictionary = Roth.get_index_from_das(recent_data.index, das_info)
		var tex: Texture2D
		if "image" in texture_data:
			tex = texture_data.image[0] if typeof(texture_data.image) == TYPE_ARRAY else texture_data.image
		else:
			tex =  ImageTexture.create_from_image(Image.create_empty(1,1, false, Image.FORMAT_L8))
		var idx: int = %RecentItemList.add_item("%s" % [texture_data.name], tex, Vector2(75,75))
		%RecentItemList.set_item_metadata(idx, texture_data)
		if texture_data.das_info.name != p_das_info.name and texture_data.das_info != active_ademo:
			%RecentItemList.set_hidden(idx, true)


func load_ademo(p_show_add_to_favorites: bool = false) -> void:
	for i in range(293):
		var texture: Dictionary = Roth.get_index_from_das(i, Roth.get_active_ademo())
		if texture.name == "Invalid":
			continue
		var tex: Texture2D
		if "image" in texture:
			tex = texture.image[0] if typeof(texture.image) == TYPE_ARRAY else texture.image
		elif "monster_index" in texture:
			var monster_texture: Dictionary = Roth.get_index_from_das(texture.monster_index, Roth.get_active_ademo())
			tex = monster_texture.image
		elif "directional_index" in texture:
			var directional_texture: Dictionary = Roth.get_index_from_das(texture.directional_index, Roth.get_active_ademo())
			tex = directional_texture.image
		else:
			tex =  ImageTexture.create_from_image(Image.create_empty(1,1, false, Image.FORMAT_L8))
		
		var right_click_array: Array[String] = []
		if p_show_add_to_favorites:
			right_click_array = Array(["Add to Favorites"], TYPE_STRING, "", null)
		
		var idx: int = %RotatableItemList.add_item("%s: %s\n%s x %s" % [texture.index, texture.name, texture.height, texture.width], tex, Vector2(150,150), right_click_array)
		%RotatableItemList.set_item_metadata(idx, texture)


func load_dbase200(dbase100: Dictionary) -> void:
	var unique: Array = []
	for inventory_item: Dictionary in dbase100.inventory:
		if inventory_item.image_data:
			if inventory_item.image_data not in unique:
				unique.append(inventory_item.image_data)
				var image: Image = Image.create_from_data(inventory_item.image_data.width, inventory_item.image_data.height, false, Image.FORMAT_RGBA8, Utility.convert_palette_image(Das.DEFAULT_RAW_PALETTE, inventory_item.image_data.raw_image, true, false))
				var tex := ImageTexture.create_from_image(image)
				var idx: int = %RotatableItemList.add_item("" , tex, Vector2(150,150))
				%RotatableItemList.set_item_metadata(idx, inventory_item.image_data)
				%RotatableItemList.set_rotated(idx, false)


func load_dbase300(dbase100: Dictionary) -> void:
	var unique: Array = []
	for inventory_item: Dictionary in dbase100.inventory:
		if inventory_item.closeup_video:
			if inventory_item.closeup_video not in unique:
				unique.append(inventory_item.closeup_video)
				var tex := ImageTexture.create_from_image(GDV.get_first_frame(inventory_item.closeup_video))
				var idx: int = %RotatableItemList.add_item("" , tex, Vector2(150,150))
				%RotatableItemList.set_item_metadata(idx, inventory_item.closeup_video)
				%RotatableItemList.set_rotated(idx, false)


func select_object(p_object: ObjectRoth) -> void:
	var texture: Dictionary = Das.get_texture_from_object(p_object)
	for i in range(%RotatableItemList.item_count):
		var object_texture: Dictionary = %RotatableItemList.get_item_metadata(i)
		if object_texture == texture:
			%RotatableItemList.select(i)
			%RotatableItemList.scroll_to_index(i)


func _on_rotatable_item_list_item_activated(index: int) -> void:
	item_selected.emit(%RotatableItemList.get_item_metadata(index))
	var texture_data: Dictionary = %RotatableItemList.get_item_metadata(index)
	if %FavRecentContainer.visible:
		add_to_recent(texture_data)


func add_to_recent(texture_data: Dictionary) -> void:
	for i in range(%RecentItemList.item_count):
		if texture_data.index == %RecentItemList.get_item_metadata(i).index:
			%RecentItemList.move_item(i, 0)
			recents.pop_at(i)
			recents.push_front({"das": texture_data.das_info.name, "index": texture_data.index})
			return
	
	
	var tex: Texture2D
	if "image" in texture_data:
		tex = texture_data.image[0] if typeof(texture_data.image) == TYPE_ARRAY else texture_data.image
	else:
		tex =  ImageTexture.create_from_image(Image.create_empty(1,1, false, Image.FORMAT_L8))
	var idx: int = %RecentItemList.add_item("%s" % [texture_data.name], tex, Vector2(75,75))
	%RecentItemList.set_item_metadata(idx, texture_data)
	%RecentItemList.move_item(idx, 0)
	recents.push_front({"das": texture_data.das_info.name, "index": texture_data.index})
	
	if len(recents) > 30:
		recents.pop_back()
		%RecentItemList.remove_item(30)


func _on_rotatable_item_list_item_selected(index: int) -> void:
	display_texture_data(%RotatableItemList.get_item_metadata(index))
	%RecentItemList.deselect_all()
	%FavoriteItemList.deselect_all()


func display_texture_data(texture_data: Dictionary) -> void:
	if %InfoContainer.visible:
		for child: Node in %ObjectInfoContainer.get_children():
			child.queue_free()
		for key: String in texture_data:
			var label := Label.new()
			label.text = "%s: %s" % [key, texture_data[key]]
			%ObjectInfoContainer.add_child(label)


func _on_recent_item_list_item_activated(index: int) -> void:
	item_selected.emit(%RecentItemList.get_item_metadata(index))
	var texture_data: Dictionary = %RecentItemList.get_item_metadata(index)
	add_to_recent(texture_data)


func _on_rotatable_item_list_context_option_selected(index: int, context_index: int) -> void:
	match context_index:
		0:
			var texture_data: Dictionary = %RotatableItemList.get_item_metadata(index)
			
			for favorite: Dictionary in favorites:
				if favorite.index == texture_data.index and favorite.das == texture_data.das_info.name:
					return
			
			var tex: Texture2D
			if "image" in texture_data:
				tex = texture_data.image[0] if typeof(texture_data.image) == TYPE_ARRAY else texture_data.image
			else:
				tex =  ImageTexture.create_from_image(Image.create_empty(1,1, false, Image.FORMAT_L8))
			var idx: int = %FavoriteItemList.add_item("%s\n" % [texture_data.name], tex, Vector2(75,75), Array(["Remove from Favorites"], TYPE_STRING, "", null))
			%FavoriteItemList.set_item_metadata(idx, texture_data)
			favorites.append({"das": texture_data.das_info.name, "index": texture_data.index})
			Settings.update_settings("objects", {"favorites": favorites})


func _on_favorite_item_list_item_activated(index: int) -> void:
	item_selected.emit(%FavoriteItemList.get_item_metadata(index))
	var texture_data: Dictionary = %FavoriteItemList.get_item_metadata(index)
	add_to_recent(texture_data)


func _on_favorite_item_list_context_option_selected(index: int, context_index: int) -> void:
	match context_index:
		0:
			%FavoriteItemList.remove_item(index)
			favorites.pop_at(index)
			Settings.update_settings("objects", {"favorites": favorites})


func _on_favorite_item_list_item_selected(index: int) -> void:
	%RecentItemList.deselect_all()
	%RotatableItemList.deselect_all()
	display_texture_data(%FavoriteItemList.get_item_metadata(index))


func _on_recent_item_list_item_selected(index: int) -> void:
	%RotatableItemList.deselect_all()
	%FavoriteItemList.deselect_all()
	display_texture_data(%RecentItemList.get_item_metadata(index))


func _on_search_edit_text_changed(new_text: String) -> void:
	for i in range(%RotatableItemList.item_count):
		if (%RotatableItemList.get_item_metadata(i).name.to_lower().contains(new_text.to_lower())
			or %RotatableItemList.get_item_metadata(i).desc.to_lower().contains(new_text.to_lower())
			or str(%RotatableItemList.get_item_metadata(i).index).to_lower().contains(new_text.to_lower())
			or new_text.is_empty()
		):
			%RotatableItemList.set_hidden(i, false)
		else:
			%RotatableItemList.set_hidden(i, true)
