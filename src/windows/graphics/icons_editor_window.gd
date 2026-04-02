extends BaseWindow

const ALLOW_PARTIAL_TRANSPARENCY: Array = [
	true,
	true,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	true,
	true,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	false,
	false,
	true,
	false,
	true,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
	true,
]

var raw_palette: PackedByteArray = Das.DEFAULT_RAW_PALETTE

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
	
	for i in range(len(icons_data)):
		var icon: Dictionary = icons_data[i]
		icon.is_transparent = ALLOW_PARTIAL_TRANSPARENCY[i]
		var index: int = %IconsList.add_item(
			"%d\n%d-%d\n%dx%d" % [icon.image_type, icon.x_offset, icon.y_offset, icon.width, icon.height],
			ImageTexture.create_from_image(Image.create_from_data(icon.width, icon.height, false, Image.FORMAT_RGBA8 if icon.is_transparent else Image.FORMAT_RGB8, Utility.convert_palette_image(raw_palette, icon.raw_image, icon.is_transparent, false)))
		)
		%IconsList.set_item_metadata(index, icon)


func _on_save_button_pressed() -> void:
	%SaveFileDialog.current_file = "ICONS.ALL"
	%SaveFileDialog.popup_centered()


func _on_save_file_dialog_file_selected(path: String) -> void:
	var icons_data: Array = []
	for i in range(%IconsList.item_count):
		var icon: Dictionary = %IconsList.get_item_metadata(i)
		icon.rle_data = RLE.encode_rle_img(icon)
		icons_data.append(icon)
		
	var data: PackedByteArray = IconsAll.compile(icons_data)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(data)
	file.close()


func _on_icons_list_item_selected(index: int) -> void:
	var icon: Dictionary = %IconsList.get_item_metadata(index)
	%TypeEdit.set_value_no_signal(icon.image_type)
	%TypeEdit.get_line_edit().text = str(icon.image_type)
	%xOffsetEdit.set_value_no_signal(icon.x_offset)
	%xOffsetEdit.get_line_edit().text = str(icon.x_offset)
	%yOffsetEdit.set_value_no_signal(icon.y_offset)
	%yOffsetEdit.get_line_edit().text = str(icon.y_offset)
	%TypeEdit.editable = false
	%xOffsetEdit.editable = true
	%yOffsetEdit.editable = true


func _on_type_edit_value_changed(value: float) -> void:
	if len(%IconsList.get_selected_items()) != 1:
		return
	var index: int = %IconsList.get_selected_items()[0]
	var icon: Dictionary = %IconsList.get_item_metadata(index)
	icon.image_type = int(value)
	%IconsList.set_item_text(index, "%d\n%d-%d\n%dx%d" % [icon.image_type, icon.x_offset, icon.y_offset, icon.width, icon.height])


func _on_x_offset_edit_value_changed(value: float) -> void:
	if len(%IconsList.get_selected_items()) != 1:
		return
	var index: int = %IconsList.get_selected_items()[0]
	var icon: Dictionary = %IconsList.get_item_metadata(index)
	icon.x_offset = int(value)
	%IconsList.set_item_text(index, "%d\n%d-%d\n%dx%d" % [icon.image_type, icon.x_offset, icon.y_offset, icon.width, icon.height])


func _on_y_offset_edit_value_changed(value: float) -> void:
	if len(%IconsList.get_selected_items()) != 1:
		return
	var index: int = %IconsList.get_selected_items()[0]
	var icon: Dictionary = %IconsList.get_item_metadata(index)
	icon.y_offset = int(value)
	%IconsList.set_item_text(index, "%d\n%d-%d\n%dx%d" % [icon.image_type, icon.x_offset, icon.y_offset, icon.width, icon.height])


func _on_icons_list_item_activated(index: int) -> void:
	var icon: Dictionary = %IconsList.get_item_metadata(index)
	var new_icon: Dictionary = await %ImageEditor.edit_image(icon, raw_palette, icon.is_transparent)
	if not new_icon.is_empty():
		icon = new_icon
		%IconsList.set_item_metadata(index, icon)
		%IconsList.set_item_icon(index, ImageTexture.create_from_image(Image.create_from_data(icon.width, icon.height, false, Image.FORMAT_RGBA8 if icon.is_transparent else Image.FORMAT_RGB8, Utility.convert_palette_image(raw_palette, icon.raw_image, icon.is_transparent, false))))
