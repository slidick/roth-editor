extends BaseWindow


func _ready() -> void:
	super._ready()
	reset()


func reset() -> void:
	%IconsList.clear()
	%BrowseLineEdit.text = ""
	%TypeEdit.get_line_edit().text = ""
	%xOffsetEdit.get_line_edit().text = ""
	%yOffsetEdit.get_line_edit().text = ""
	%TypeEdit.editable = false
	%xOffsetEdit.editable = false
	%yOffsetEdit.editable = false
	%SaveButton.disabled = true


func _on_browse_button_pressed() -> void:
	%FileDialog.current_dir = Roth.install_directory.path_join("DATA")
	%FileDialog.popup_centered()


func _on_file_dialog_file_selected(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	reset()
	%SaveButton.disabled = false
	%BrowseLineEdit.text = path
	%SaveFileDialog.current_dir = %FileDialog.current_dir
	var icons_data: Array = IconsAll.parse_for_editing(path)
	var palette: Array = Das.DEFAULT_PALETTE
	for icon: Dictionary in icons_data:
		RLE.add_image_to_raw_rle_dict(icon, palette)
		var index: int = %IconsList.add_item("%d\n%d-%d\n%dx%d" % [icon.header.imgType, icon.header.xOffset, icon.header.yOffset, icon.header.width, icon.header.height], ImageTexture.create_from_image(icon.image))
		%IconsList.set_item_metadata(index, icon)


func _on_save_button_pressed() -> void:
	%SaveFileDialog.current_file = "ICONS.ALL"
	%SaveFileDialog.popup_centered()


func _on_save_file_dialog_file_selected(path: String) -> void:
	var icons_data: Array = []
	for i in range(%IconsList.item_count):
		var icon: Dictionary = %IconsList.get_item_metadata(i)
		var image: Image = icon.image.duplicate(true)
		#image.convert(Image.FORMAT_RGB8)
		icon.raw_data = await RLE.convert_to_paletted_image(image, Das.DEFAULT_PALETTE)
		icon.rle_data = RLE.encode_rle_img(icon)
		icons_data.append(icon)
		
	var data: PackedByteArray = IconsAll.compile(icons_data)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(data)
	file.close()


func _on_icons_list_item_selected(index: int) -> void:
	var icon: Dictionary = %IconsList.get_item_metadata(index)
	%TypeEdit.set_value_no_signal(icon.header.imgType)
	%TypeEdit.get_line_edit().text = str(icon.header.imgType)
	%xOffsetEdit.set_value_no_signal(icon.header.xOffset)
	%xOffsetEdit.get_line_edit().text = str(icon.header.xOffset)
	%yOffsetEdit.set_value_no_signal(icon.header.yOffset)
	%yOffsetEdit.get_line_edit().text = str(icon.header.yOffset)
	%TypeEdit.editable = true
	%xOffsetEdit.editable = true
	%yOffsetEdit.editable = true


func _on_type_edit_value_changed(value: float) -> void:
	if len(%IconsList.get_selected_items()) != 1:
		return
	var index: int = %IconsList.get_selected_items()[0]
	var icon: Dictionary = %IconsList.get_item_metadata(index)
	icon.header.imgType = int(value)
	%IconsList.set_item_text(index, "%d\n%d-%d\n%dx%d" % [icon.header.imgType, icon.header.xOffset, icon.header.yOffset, icon.header.width, icon.header.height])


func _on_x_offset_edit_value_changed(value: float) -> void:
	if len(%IconsList.get_selected_items()) != 1:
		return
	var index: int = %IconsList.get_selected_items()[0]
	var icon: Dictionary = %IconsList.get_item_metadata(index)
	icon.header.xOffset = int(value)
	%IconsList.set_item_text(index, "%d\n%d-%d\n%dx%d" % [icon.header.imgType, icon.header.xOffset, icon.header.yOffset, icon.header.width, icon.header.height])


func _on_y_offset_edit_value_changed(value: float) -> void:
	if len(%IconsList.get_selected_items()) != 1:
		return
	var index: int = %IconsList.get_selected_items()[0]
	var icon: Dictionary = %IconsList.get_item_metadata(index)
	icon.header.yOffset = int(value)
	%IconsList.set_item_text(index, "%d\n%d-%d\n%dx%d" % [icon.header.imgType, icon.header.xOffset, icon.header.yOffset, icon.header.width, icon.header.height])


func _on_icons_list_item_activated(index: int) -> void:
	var icon: Dictionary = %IconsList.get_item_metadata(index)
	var new_image: Image = await %ImageEditor.edit_image(icon.image)
	if new_image:
		icon.image = new_image
		%IconsList.set_item_icon(index, ImageTexture.create_from_image(icon.image))
