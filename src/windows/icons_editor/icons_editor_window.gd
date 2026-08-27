extends BaseWindow

var raw_palette: PackedByteArray = Das.DEFAULT_RAW_PALETTE
var previous_select: int = -1
var modified: bool = false

func _ready() -> void:
	super._ready()
	Roth.settings_updated.connect(_on_settings_updated)


func _hide() -> void:
	if modified:
		if not await Dialog.confirm("There are unsaved changes!\nAre you sure?", "Changes will be lost!", false, Vector2(400,200)):
			%ItemList.select(previous_select)
			return
	super._hide()
	%IconsList.clear()
	%ItemList.deselect_all()
	%HotspotContainer.hide()
	modified = false


func _on_settings_updated() -> void:
	%IconsList.clear()
	%ItemList.clear()
	%HotspotContainer.hide()
	for icon_info: Dictionary in IconPack.icon_packs:
		var idx: int = %ItemList.add_item(icon_info.name)
		%ItemList.set_item_metadata(idx, icon_info)


func _on_item_list_item_selected(index: int) -> void:
	if modified:
		if not await Dialog.confirm("There are unsaved changes!\nAre you sure?", "Changes will be lost!", false, Vector2(400,200)):
			%ItemList.select(previous_select)
			return
	modified = false
	previous_select = index
	%IconsList.clear()
	var icon_info: Dictionary = %ItemList.get_item_metadata(index)
	var icon_data: Array = IconsAll.parse(icon_info.filepath)
	for i in range(len(icon_data)):
		var icon: Dictionary = icon_data[i]
		var image_name: String = "%dx%d" % [icon.width, icon.height]
		if icon.y_offset or icon.x_offset:
			image_name += "\n%d,%d" % [icon.x_offset, icon.y_offset]
		var idx: int = %IconsList.add_item(
			image_name,
			ImageTexture.create_from_image(Image.create_from_data(icon.width, icon.height, false, Image.FORMAT_RGBA8 if icon.is_transparent else Image.FORMAT_RGB8, Utility.convert_palette_image(raw_palette, icon.raw_image, icon.is_transparent, false)))
		)
		%IconsList.set_item_metadata(idx, icon)
		if "vanilla" in icon_info:
			%IconsList.set_item_disabled(idx, true)
	%xOffsetEdit.editable = false
	%yOffsetEdit.editable = false
	%xOffsetEdit.set_value_no_signal(0)
	%yOffsetEdit.set_value_no_signal(0)
	%xOffsetEdit.get_line_edit().text = "0"
	%yOffsetEdit.get_line_edit().text = "0"
	if "vanilla" in icon_info:
		%HotspotContainer.hide()
	else:
		%HotspotContainer.show()


func _on_item_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			var icon_info: Dictionary = %ItemList.get_item_metadata(index)
			if "vanilla" in icon_info:
				%PopupMenu.set_item_disabled(0, true)
				%PopupMenu.set_item_disabled(1, true)
			else:
				%PopupMenu.set_item_disabled(0, false)
				%PopupMenu.set_item_disabled(1, false)
			%PopupMenu.popup(Rect2i(%ItemList.global_position+at_position, Vector2.ZERO))


func _on_popup_menu_index_pressed(index: int) -> void:
	var icon_info: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	match index:
		0:
			var new_name: String = await query_for_name("Rename IconPack: %s" % icon_info.name)
			if new_name.is_empty():
				return
			IconPack.rename(icon_info, new_name)
			select(icon_info)
		1:
			if await Dialog.confirm("Delete %s" % icon_info.name, "Confirm Delete", false, Vector2(400,200)):
				IconPack.delete(icon_info)
		2:
			var new_name: String = await query_for_name("Duplicate IconPack: %s" % icon_info.name)
			if new_name.is_empty():
				return
			var new_info: Dictionary = IconPack.duplicate_pack(icon_info, new_name)
			select(new_info)


func _on_add_button_pressed() -> void:
	pass # Replace with function body.


func query_for_name(title: String) -> String:
	var err: String = "init"
	var results: Array = [false, ""]
	while not err.is_empty():
		results = await Dialog.input("New Name", title, results[1], err if err != "init" else "", false, Vector2(400,200))
		if not results[0]:
			return ""
		err = IconPack.check_name(results[1])
	return results[1]


func select(icon_info: Dictionary) -> void:
	for i in range(%ItemList.item_count):
		if icon_info == %ItemList.get_item_metadata(i):
			%ItemList.select(i)
			_on_item_list_item_selected(i)


func _on_icons_list_item_selected(index: int) -> void:
	var icon: Dictionary = %IconsList.get_item_metadata(index)
	%xOffsetEdit.set_value_no_signal(icon.x_offset)
	%xOffsetEdit.get_line_edit().text = str(icon.x_offset)
	%yOffsetEdit.set_value_no_signal(icon.y_offset)
	%yOffsetEdit.get_line_edit().text = str(icon.y_offset)
	%xOffsetEdit.editable = true
	%yOffsetEdit.editable = true


func _on_icons_list_item_activated(index: int) -> void:
	var icon: Dictionary = %IconsList.get_item_metadata(index)
	var new_icon: Dictionary = await %ImageEditor.edit_image(icon, raw_palette, icon.is_transparent)
	if not new_icon.is_empty():
		icon = new_icon
		%IconsList.set_item_metadata(index, icon)
		%IconsList.set_item_icon(index, ImageTexture.create_from_image(Image.create_from_data(icon.width, icon.height, false, Image.FORMAT_RGBA8 if icon.is_transparent else Image.FORMAT_RGB8, Utility.convert_palette_image(raw_palette, icon.raw_image, icon.is_transparent, false))))
		modified = true


func _on_x_offset_edit_value_changed(value: float) -> void:
	if len(%IconsList.get_selected_items()) != 1:
		return
	var index: int = %IconsList.get_selected_items()[0]
	var icon: Dictionary = %IconsList.get_item_metadata(index)
	icon.x_offset = int(value)
	var image_name: String = "%dx%d" % [icon.width, icon.height]
	if icon.y_offset or icon.x_offset:
		image_name += "\n%d,%d" % [icon.x_offset, icon.y_offset]
	%IconsList.set_item_text(index, image_name)
	modified = true


func _on_y_offset_edit_value_changed(value: float) -> void:
	if len(%IconsList.get_selected_items()) != 1:
		return
	var index: int = %IconsList.get_selected_items()[0]
	var icon: Dictionary = %IconsList.get_item_metadata(index)
	icon.y_offset = int(value)
	var image_name: String = "%dx%d" % [icon.width, icon.height]
	if icon.y_offset or icon.x_offset:
		image_name += "\n%d,%d" % [icon.x_offset, icon.y_offset]
	%IconsList.set_item_text(index, image_name)
	modified = true


func _on_save_button_pressed() -> void:
	var icons_data: Array = []
	for i in range(%IconsList.item_count):
		var icon: Dictionary = %IconsList.get_item_metadata(i)
		icon.rle_data = RLE.encode_rle_image(icon)
		icons_data.append(icon)
	
	var data: PackedByteArray = IconsAll.compile(icons_data)
	var file := FileAccess.open(%ItemList.get_item_metadata(%ItemList.get_selected_items()[0]).filepath, FileAccess.WRITE)
	file.store_buffer(data)
	file.close()
	modified = false


func get_modified_icon_name() -> String:
	if modified:
		return %ItemList.get_item_text(%ItemList.get_selected_items()[0])
	return ""
