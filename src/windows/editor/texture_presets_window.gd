extends BaseWindow

signal done

var das: Dictionary = {}
var texture_data: Dictionary = {}


func edit_presets(das_name: String, preset_name: String, copied_data: Dictionary = {}) -> Variant:
	das = await Roth.get_das(das_name)
	toggle(true)
	texture_data = Settings.settings.get("texture_presets", {}).get(das_name, {}).duplicate(true)
	%ItemList.clear()
	%RotatableItemList.clear()
	var i: int = 0
	for key: String in texture_data:
		var idx: int = %ItemList.add_item(key)
		%ItemList.set_item_metadata(idx, texture_data[key])
		if i == 0:
			%ItemList.select(i)
			_on_item_list_item_selected(i)
			i += 1
		if key == preset_name:
			%ItemList.select(idx)
			_on_item_list_item_selected(idx)
	
	if not copied_data.is_empty():
		create_from_copied_data(copied_data)
	
	var out: bool = await done
	if out:
		if %ItemList.item_count > 0:
			return %ItemList.get_item_text(%ItemList.get_selected_items()[0])
		else:
			return ""
	return -1


func _on_close_button_pressed() -> void:
	done.emit(false)
	toggle()


func create_from_copied_data(copied_data: Dictionary) -> void:
	var new_name: Array = await Dialog.input("Enter a name:", "Create Texture Presest From Data", "", "", false, Vector2(400, 150))
	if new_name[0] == false:
		return
	while new_name[1].to_upper() in texture_data.keys() or new_name[1].to_upper() == "CUSTOM" or new_name[1].to_upper() == "COPIED DATA":
		new_name = await Dialog.input("Enter a name:", "Create Texture Presest From Data", "", "Name already in use.", false, Vector2(400, 150))
		if new_name[0] == false:
			return
	add_preset(new_name[1], copied_data)


func _on_item_list_item_selected(index: int) -> void:
	var texture_preset_data: Dictionary = %ItemList.get_item_metadata(index)
	%RotatableItemList.clear()
	for key: String in ["ceiling", "floor", "wall"]:
		if texture_preset_data[key] in das.mapping:
			var texture: Dictionary = das.mapping[texture_preset_data[key]]
			if not "image" in texture:
				continue
			var tex: Texture2D = texture.image[0] if typeof(texture.image) == TYPE_ARRAY else texture.image
			var idx: int = %RotatableItemList.add_item("%s\n%d: %s" % [key, texture.index, texture.name], tex, Vector2(150,150), Array(["Select from palette"], TYPE_STRING, "", null))
			%RotatableItemList.set_item_metadata(idx, texture)
			if key != "wall":
				%RotatableItemList.set_rotated(idx, false)
		else:
			var adjustment: int = 65280
			if key == "wall":
				adjustment = 32768
			var palette_index: int = texture_preset_data[key] - adjustment
			var image := Image.create_empty(1, 1 , false, Image.FORMAT_RGB8)
			image.set_pixel(0, 0, Color(das.palette[palette_index][0] / float(255), das.palette[palette_index][1] / float(255), das.palette[palette_index][2] / float(255)))
			var tex: Texture2D = ImageTexture.create_from_image(image)
			var idx: int = %RotatableItemList.add_item("%s\n%d" % [key, texture_preset_data[key]], tex, Vector2(150,150), Array(["Select from palette"], TYPE_STRING, "", null))
			%RotatableItemList.set_item_metadata(idx, texture_preset_data[key])
			if key != "wall":
				%RotatableItemList.set_rotated(idx, false)


func _on_save_button_pressed() -> void:
	Settings.update_settings("texture_presets", {das.das_file: texture_data})
	toggle(false)
	done.emit(true)


func _on_rotatable_item_list_item_activated(index: int) -> void:
	var key: String = ""
	match index:
		0:
			key = "ceiling"
		1:
			key = "floor"
		_:
			key = "wall"
	var current_texture: Variant = %RotatableItemList.get_item_metadata(index)
	if current_texture is Dictionary:
		%Texture.show_texture(das, true if key != "wall" else false, current_texture.index)
	else:
		%Texture.show_texture(das, true if key != "wall" else false)
	var texture_index: int = await %Texture.texture_selected
	if texture_index == -1:
		return
	var new_texture: Dictionary = das.mapping[texture_index]
	var tex: Texture2D = new_texture.image[0] if typeof(new_texture.image) == TYPE_ARRAY else new_texture.image
	%RotatableItemList.set_item_text(index, "%s\n%d: %s" % [key, new_texture.index, new_texture.name])
	%RotatableItemList.set_item_icon(index, tex)
	%RotatableItemList.set_item_metadata(index, new_texture)
	texture_data[%ItemList.get_item_text(%ItemList.get_selected_items()[0])][key] = new_texture.index


func _on_add_button_pressed() -> void:
	var new_name: Array = await Dialog.input("Enter a name:", "New Texture Presest", "", "", false, Vector2(400, 150))
	if new_name[0] == false:
		return
	while new_name[1].to_upper() in texture_data.keys() or new_name[1].to_upper() == "CUSTOM" or new_name[1].to_upper() == "COPIED DATA":
		new_name = await Dialog.input("Enter a name:", "New Texture Presest", "", "Name already in use.", false, Vector2(400, 150))
		if new_name[0] == false:
			return
	var new_data: Dictionary = {
		"ceiling": 65535,
		"floor": 65535,
		"wall": 33023,
	}
	add_preset(new_name[1], new_data)

func add_preset(new_name: String, new_data: Dictionary) -> void:
	var idx: int = %ItemList.add_item(new_name.to_upper())
	%ItemList.set_item_metadata(idx, new_data)
	texture_data[new_name.to_upper()] = new_data
	%ItemList.select(idx)
	_on_item_list_item_selected(idx)


func _on_item_list_item_clicked(_index: int, at_position: Vector2, mouse_button_index: int) -> void:
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			%PopupMenu.popup_on_parent(Rect2(at_position.x+%ItemList.global_position.x, at_position.y+%ItemList.global_position.y,0,0))


func _on_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			var new_name: Array = await Dialog.input("Enter a name:", "Rename Texture Presest", "", "", false, Vector2(400, 150))
			if new_name[0] == false:
				return
			while new_name[1].to_upper() in texture_data.keys() or new_name[1].to_upper() == "CUSTOM" or new_name[1].to_upper() == "COPIED DATA":
				new_name = await Dialog.input("Enter a name:", "Rename Texture Presest", "", "Name already in use.", false, Vector2(400, 150))
				if new_name[0] == false:
					return
			
			var old_name: String = %ItemList.get_item_text(%ItemList.get_selected_items()[0])
			texture_data[new_name[1].to_upper()] = texture_data[old_name]
			texture_data.erase(old_name)
			%ItemList.set_item_text(%ItemList.get_selected_items()[0], new_name[1].to_upper())
			
		1:
			var selected_index: int = %ItemList.get_selected_items()[0]
			var preset: String = %ItemList.get_item_text(selected_index)
			texture_data.erase(preset)
			%ItemList.remove_item(selected_index)
			%RotatableItemList.clear()
			if selected_index == 0:
				selected_index += 1
			if %ItemList.item_count > 0:
				%ItemList.select(selected_index-1)
				_on_item_list_item_selected(selected_index-1)


func _on_rotatable_item_list_context_option_selected(index: int, context_index: int) -> void:
	match context_index:
		0:
			var key: String = ""
			match index:
				0:
					key = "ceiling"
				1:
					key = "floor"
				_:
					key = "wall"
			%Palette.show_palette(das.palette)
			var palette_index: int = await %Palette.color_selected
			if palette_index < 0:
				return
			var image := Image.create_empty(1, 1 , false, Image.FORMAT_RGB8)
			image.set_pixel(0, 0, Color(das.palette[palette_index][0] / float(255), das.palette[palette_index][1] / float(255), das.palette[palette_index][2] / float(255)))
			var tex: Texture2D = ImageTexture.create_from_image(image)
			var adjustment: int = 65280
			if key == "wall":
				adjustment = 32768
			%RotatableItemList.set_item_text(index, "%s\n%d" % [key, palette_index + adjustment])
			%RotatableItemList.set_item_icon(index, tex)
			%RotatableItemList.set_item_metadata(index, palette_index + adjustment)
			texture_data[%ItemList.get_item_text(%ItemList.get_selected_items()[0])][key] = palette_index + adjustment
