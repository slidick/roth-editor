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


func wait_for_object_selection(p_das: String) -> Dictionary:
	%RotatableItemList.clear()
	%RecentItemList.clear()
	%FavoriteItemList.clear()
	load_das(p_das)
	load_favorites(p_das)
	load_recents(p_das)
	load_ademo()
	toggle(true)
	var selected_object: Dictionary = await item_selected
	toggle(false)
	return selected_object


func load_das(p_das: String) -> void:
	var das := await Roth.get_das(p_das)
	for texture: Dictionary in das.textures:
		if texture.index >= 4096 and texture.index < 4352:
			if texture.name == "Invalid":
				continue
			var tex: Texture2D
			if "image" in texture:
				tex = texture.image[0] if typeof(texture.image) == TYPE_ARRAY else texture.image
			else:
				tex =  ImageTexture.create_from_image(Image.create_empty(1,1, false, Image.FORMAT_L8))
			
			var idx: int = %RotatableItemList.add_item("%s: %s\n%s x %s" % [texture.index, texture.name, texture.height, texture.width], tex, Vector2(150,150), Array(["Add to Favorites"], TYPE_STRING, "", null))
			%RotatableItemList.set_item_metadata(idx, texture)


func load_favorites(p_das: String) -> void:
	for data: Dictionary in favorites:
		var texture_index: int = data.index
		var das_name: String = data.das
		var texture_data: Dictionary = Roth.get_index_from_das(texture_index, das_name)
		var tex: Texture2D
		if "image" in texture_data:
			tex = texture_data.image[0] if typeof(texture_data.image) == TYPE_ARRAY else texture_data.image
		else:
			tex =  ImageTexture.create_from_image(Image.create_empty(1,1, false, Image.FORMAT_L8))
		var idx: int = %FavoriteItemList.add_item("%s: %s\n%s x %s" % [texture_data.index, texture_data.name, texture_data.height, texture_data.width], tex, Vector2(75,75), Array(["Remove from Favorites"], TYPE_STRING, "", null))
		%FavoriteItemList.set_item_metadata(idx, texture_data)
		if texture_data.das != p_das and texture_data.das != "M/ADEMO.DAS":
			%FavoriteItemList.set_hidden(idx, true)


func load_recents(p_das: String) -> void:
	for data: Dictionary in recents:
		var texture_index: int = data.index
		var das_name: String = data.das
		var texture_data: Dictionary = Roth.get_index_from_das(texture_index, das_name)
		var tex: Texture2D
		if "image" in texture_data:
			tex = texture_data.image[0] if typeof(texture_data.image) == TYPE_ARRAY else texture_data.image
		else:
			tex =  ImageTexture.create_from_image(Image.create_empty(1,1, false, Image.FORMAT_L8))
		var idx: int = %RecentItemList.add_item("%s: %s\n%s x %s" % [texture_data.index, texture_data.name, texture_data.height, texture_data.width], tex, Vector2(75,75))
		%RecentItemList.set_item_metadata(idx, texture_data)
		if texture_data.das != p_das and texture_data.das != "M/ADEMO.DAS":
			%RecentItemList.set_hidden(idx, true)


func load_ademo() -> void:
	#var das := await Roth.get_das("M/ADEMO.DAS")
	for i in range(256):
		var texture: Dictionary = Roth.get_index_from_das(i, "M/ADEMO.DAS")
		if texture.name == "Invalid":
			continue
		var tex: Texture2D
		if "image" in texture:
			tex = texture.image[0] if typeof(texture.image) == TYPE_ARRAY else texture.image
		else:
			tex =  ImageTexture.create_from_image(Image.create_empty(1,1, false, Image.FORMAT_L8))
			
		var idx: int = %RotatableItemList.add_item("%s: %s\n%s x %s" % [texture.index, texture.name, texture.height, texture.width], tex, Vector2(150,150), Array(["Add to Favorites"], TYPE_STRING, "", null))
		%RotatableItemList.set_item_metadata(idx, texture)


func _on_rotatable_item_list_item_activated(index: int) -> void:
	item_selected.emit(%RotatableItemList.get_item_metadata(index))
	var texture_data: Dictionary = %RotatableItemList.get_item_metadata(index)
	add_to_recent(texture_data)


func add_to_recent(texture_data: Dictionary) -> void:
	for i in range(%RecentItemList.item_count):
		if texture_data.index == %RecentItemList.get_item_metadata(i).index:
			%RecentItemList.move_item(i, 0)
			recents.pop_at(i)
			recents.push_front({"das": texture_data.das, "index": texture_data.index})
			return
	
	
	var tex: Texture2D
	if "image" in texture_data:
		tex = texture_data.image[0] if typeof(texture_data.image) == TYPE_ARRAY else texture_data.image
	else:
		tex =  ImageTexture.create_from_image(Image.create_empty(1,1, false, Image.FORMAT_L8))
	var idx: int = %RecentItemList.add_item("%s: %s\n%s x %s" % [texture_data.index, texture_data.name, texture_data.height, texture_data.width], tex, Vector2(75,75))
	%RecentItemList.set_item_metadata(idx, texture_data)
	%RecentItemList.move_item(idx, 0)
	recents.push_front({"das": texture_data.das, "index": texture_data.index})
	
	if len(recents) > 30:
		recents.pop_back()
		%RecentItemList.remove_item(30)



func _on_rotatable_item_list_item_selected(index: int) -> void:
	var texture: Dictionary = %RotatableItemList.get_item_metadata(index)
	for child: Node in %ObjectInfoContainer.get_children():
		child.queue_free()
	for key: String in texture:
		var label := Label.new()
		label.text = "%s: %s" % [key, texture[key]]
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
				if favorite.index == texture_data.index and favorite.das == texture_data.das:
					return
			
			var tex: Texture2D
			if "image" in texture_data:
				tex = texture_data.image[0] if typeof(texture_data.image) == TYPE_ARRAY else texture_data.image
			else:
				tex =  ImageTexture.create_from_image(Image.create_empty(1,1, false, Image.FORMAT_L8))
			var idx: int = %FavoriteItemList.add_item("%s: %s\n%s x %s" % [texture_data.index, texture_data.name, texture_data.height, texture_data.width], tex, Vector2(75,75), Array(["Remove from Favorites"], TYPE_STRING, "", null))
			%FavoriteItemList.set_item_metadata(idx, texture_data)
			favorites.append({"das": texture_data.das, "index": texture_data.index})
			Settings.update_settings("objects", {"favorites": favorites})


func _on_favorite_item_list_item_activated(index: int) -> void:
	item_selected.emit(%FavoriteItemList.get_item_metadata(index))
	var texture_data: Dictionary = %FavoriteItemList.get_item_metadata(index)
	add_to_recent(texture_data)


func _on_favorite_item_list_context_option_selected(index: int, context_index: int) -> void:
	match context_index:
		0:
			print("Remove from favorite: ", %FavoriteItemList.get_item_metadata(index).index)
			%FavoriteItemList.remove_item(index)
			favorites.pop_at(index)
			Settings.update_settings("objects", {"favorites": favorites})
