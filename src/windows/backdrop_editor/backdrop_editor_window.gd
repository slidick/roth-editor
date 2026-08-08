extends BaseWindow
class_name BackdropEditor
var paletted_image: Dictionary
var cancel_load: bool = false


func _ready() -> void:
	super._ready()
	Roth.settings_updated.connect(_on_settings_updated)


func _hide() -> void:
	super._hide()
	%RothTexture.clear()
	%ItemList.deselect_all()
	%EditButton.hide()


func _on_settings_updated() -> void:
	%ItemList.clear()
	%RothTexture.clear()
	for backdrop_info: Dictionary in BackdropPack.backdrop_packs:
		var idx: int = %ItemList.add_item(backdrop_info.name)
		%ItemList.set_item_metadata(idx, backdrop_info)


func select(p_backdrop_info: Dictionary) -> void:
	for i in range(%ItemList.item_count):
		if p_backdrop_info == %ItemList.get_item_metadata(i):
			%ItemList.select(i)
			_on_item_list_item_selected(i)


func _on_item_list_item_selected(index: int) -> void:
	var backdrop_info: Dictionary = %ItemList.get_item_metadata(index)
	var image_data: Dictionary = Backdrop.parse(backdrop_info.filepath)
	%RothTexture.load_data({"data": image_data}, Das.DEFAULT_RAW_PALETTE)
	if "vanilla" in backdrop_info:
		%EditButton.hide()
	else:
		%EditButton.show()


func _on_item_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			var backdrop_info: Dictionary = %ItemList.get_item_metadata(index)
			if "vanilla" in backdrop_info:
				%PopupMenu.set_item_disabled(0, true)
				%PopupMenu.set_item_disabled(1, true)
			else:
				%PopupMenu.set_item_disabled(0, false)
				%PopupMenu.set_item_disabled(1, false)
			%PopupMenu.popup(Rect2(%ItemList.global_position+at_position, Vector2.ZERO))


func _on_popup_menu_index_pressed(index: int) -> void:
	var backdrop_info: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	match index:
		0:
			var new_name: String = await query_for_name("Renaming Backdrop: %s" % backdrop_info.name)
			if new_name.is_empty():
				return
			BackdropPack.rename(backdrop_info, new_name)
			select(backdrop_info)
		1:
			if await Dialog.confirm("Delete %s" % backdrop_info.name, "Confirm Delete", false, Vector2(400,200)):
				BackdropPack.delete(backdrop_info)
				%EditButton.hide()
		2:
			var new_name: String = await query_for_name("Duplicating Backdrop: %s" % backdrop_info.name)
			if new_name.is_empty():
				return
			var new_info: Dictionary = BackdropPack.duplicate_pack(backdrop_info, new_name)
			select(new_info)


func query_for_name(title: String) -> String:
	var err: String = "init"
	var results: Array = [false, ""]
	while not err.is_empty():
		results = await Dialog.input("New Name", title, results[1], err if err != "init" else "", false, Vector2(400,200))
		if not results[0]:
			return ""
		err = BackdropPack.check_name(results[1])
	return results[1]


func _on_new_button_pressed() -> void:
	var new_name: String = await query_for_name("Create Backdrop")
	if new_name.is_empty():
		return
	var new_info: Dictionary = BackdropPack.create(new_name)
	select(new_info)


func _on_edit_button_pressed() -> void:
	var backdrop_info: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	var image_data: Dictionary = Backdrop.parse(backdrop_info.filepath)
	var new_data: Dictionary = await %ImageEditor.edit_image(image_data, Das.DEFAULT_RAW_PALETTE, false, false, false, false, false)
	if new_data:
		image_data.raw_image = new_data.raw_image
		image_data.width = new_data.width
		image_data.height = new_data.height
		image_data.rle_data = RLE.encode_rle_image(image_data)
		var buffer: PackedByteArray = Backdrop.compile(image_data)
		var file := FileAccess.open(backdrop_info.filepath, FileAccess.WRITE)
		file.store_buffer(buffer)
		file.close()
		paletted_image.raw_image = new_data.raw_image
		%RothTexture.load_data({"data": image_data}, Das.DEFAULT_RAW_PALETTE)
