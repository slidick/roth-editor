extends BaseWindow

const DRAG_TREE: Script = preload("uid://bh8vniea2yee2")

enum SaveListMenu {
	COPY,
	PASTE,
	DUPLICATE,
	RENAME,
	DELETE,
}
enum MapListMenu {
	DELETE,
}

var original_data: Array = []
var save_tween: Tween
var copied_data: Dictionary = {}
var first_call: bool = true


func _ready() -> void:
	super._ready()
	for type: String in ["General", "Player", "Inventory", "MapData", "Unknown"]:
		%ItemList.add_item(type)
	%ItemList.select(0)
	%TabContainer.current_tab = 0
	%SelectLabel.show()
	%Container.hide()
	%SaveLabel.modulate.a = 0.0
	Roth.settings_loaded.connect(_on_settings_loaded)


func _on_settings_loaded() -> void:
	if first_call:
		first_call = false
		%FileDialog.current_dir = Roth.install_directory.path_join("../ROTH/SAVEGAME")


func toggle(_bool: Variant = null) -> void:
	super.toggle(_bool)
	%SaveList.clear()
	%SelectLabel.show()
	%Container.hide()


func load_savegame_directory(directory: String) -> void:
	if not DirAccess.dir_exists_absolute(directory):
		return
	%SaveList.clear()
	original_data = []
	for filename: String in DirAccess.get_files_at(directory):
		if filename.get_extension() != "SAV":
			continue
		var data: Dictionary = SaveGame.parse_filepath(directory.path_join(filename))
		original_data.append(data.duplicate(true))
		var idx: int = %SaveList.add_item(filename)
		%SaveList.set_item_metadata(idx, data)
		var image_entry: Dictionary = data.entries.filter(func (e: Dictionary) -> bool: return true if e.type == 0x0B else false)[0]
		%SaveList.set_item_icon(idx, ImageTexture.create_from_image(Image.create_from_data(
			image_entry.width,
			image_entry.height,
			false,
			Image.FORMAT_RGB8,
			Utility.convert_palette_image(Das.DEFAULT_RAW_PALETTE, image_entry.raw_image, false, false)
		)))
	if %SaveList.item_count > 0:
		%SaveList.select(0)
		%SaveList.ensure_current_is_visible()
		_on_save_list_item_selected(0)
		%SelectLabel.hide()
		%Container.show()
		%SaveButton.disabled = false
	else:
		%SelectLabel.show()
		%Container.hide()
		%SaveButton.disabled = true


func _on_item_list_item_selected(index: int) -> void:
	%TabContainer.current_tab = index


func _on_browse_button_pressed() -> void:
	%FileDialog.popup_file_dialog()


func _on_default_install_button_pressed() -> void:
	_on_file_dialog_dir_selected(Roth.install_directory.path_join("../ROTH/SAVEGAME"))


func _on_editor_install_button_pressed() -> void:
	_on_file_dialog_dir_selected(Roth.ROTH_CUSTOM_INSTALL_DIRECTORY.path_join("SAVEGAME"))


func _on_file_dialog_dir_selected(dir: String) -> void:
	%DirectoryEdit.text = dir
	%FileDialog.current_dir = dir
	load_savegame_directory(dir)


func _on_save_list_item_clicked(_index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		%SaveListMenu.popup(Rect2(%SaveList.global_position+at_position, Vector2.ZERO))


func _on_save_list_menu_index_pressed(menu_index: int) -> void:
	var selected_index: int = %SaveList.get_selected_items()[0]
	var selected_data: Dictionary = %SaveList.get_item_metadata(selected_index)
	match menu_index:
		SaveListMenu.COPY:
			copied_data = selected_data.duplicate(true)
			%SaveListMenu.set_item_disabled(SaveListMenu.PASTE, false)
		SaveListMenu.PASTE:
			selected_data.entries = copied_data.entries.duplicate(true)
			selected_data.header = copied_data.header
			selected_data.footer = copied_data.footer
			_on_save_list_item_selected(selected_index)
		SaveListMenu.DUPLICATE:
			var results: Array = await Dialog.input("Name", "Duplicate File", "", "", false)
			if results[0]:
				if FileAccess.file_exists(selected_data.filepath.get_base_dir().path_join(results[1])):
					if not await Dialog.confirm("File already exists!\nOverwrite?", "Confirm Overwrite", false, Vector2(400,200)):
						return
				DirAccess.copy_absolute(selected_data.filepath, selected_data.filepath.get_base_dir().path_join(results[1]))
				_on_file_dialog_dir_selected(%DirectoryEdit.text)
				_select_save_by_name(results[1])
		SaveListMenu.RENAME:
			var results: Array = await Dialog.input("New Name", "Rename File", selected_data.filepath.get_file(), "", false)
			if results[0]:
				if FileAccess.file_exists(selected_data.filepath.get_base_dir().path_join(results[1])):
					if not await Dialog.confirm("File already exists!\nOverwrite?", "Confirm Overwrite", false, Vector2(400,200)):
						return
				DirAccess.rename_absolute(selected_data.filepath, selected_data.filepath.get_base_dir().path_join(results[1]))
				_on_file_dialog_dir_selected(%DirectoryEdit.text)
				_select_save_by_name(results[1])
		SaveListMenu.DELETE:
			if await Dialog.confirm("Are you sure?", "Confirm Delete", false, Vector2(400,150)):
				DirAccess.remove_absolute(selected_data.filepath)
				_on_file_dialog_dir_selected(%DirectoryEdit.text)
				%SaveList.select(selected_index-1)
				_on_save_list_item_selected(selected_index-1)


func _select_save_by_name(p_name: String) -> void:
	for i in range(%SaveList.item_count):
		if %SaveList.get_item_text(i) == p_name:
			%SaveList.select(i)
			%SaveList.ensure_current_is_visible()
			_on_save_list_item_selected(i)
			break


func _on_save_list_item_selected(index: int) -> void:
	var data: Dictionary = %SaveList.get_item_metadata(index)
	%MapList.clear()
	%MapDataEdit.clear()
	%MapDataEdit.editable = false
	for child: Node in %UnknownContainer.get_children():
		child.queue_free()
	%FileHeaderEdit.text = str(data.header)
	%FileFooterEdit.text = str(data.footer)
	for entry: Dictionary in data.entries:
		match entry.type:
			0x02:
				_load_player_data(entry)
			0x03:
				%CurrentMapEdit.text = entry.name
			0x07:
				_load_inventory_data(entry)
			0x08:
				_load_map_data(entry)
			0x09:
				pass
			0x0A:
				%SaveNameEdit.text = entry.name
			0x0B:
				%RothTextureContainer.load_data({"data": entry}, Das.DEFAULT_RAW_PALETTE)
			_:
				_load_other_data(entry)


func _on_map_list_item_clicked(_index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		%MapListMenu.popup(Rect2i(%MapList.global_position+at_position, Vector2.ZERO))


func _on_map_list_menu_index_pressed(menu_index: int) -> void:
	var data: Dictionary = %SaveList.get_item_metadata(%SaveList.get_selected_items()[0])
	var selected_index: int = %MapList.get_selected_items()[0]
	match menu_index:
		MapListMenu.DELETE:
			var entry: Dictionary = %SaveList.get_item_metadata(%SaveList.get_selected_items()[0]).entries.filter(func (e: Dictionary) -> bool: return true if e.type == 0x09 else false)[selected_index]
			var entry_index: int = data.entries.find(entry)
			data.entries.pop_at(entry_index)
			data.entries.pop_at(entry_index-1)
			%MapList.remove_item(selected_index)
			if selected_index > 0:
				%MapList.select(selected_index-1)
				_on_map_list_item_selected(selected_index-1)
			else:
				%MapDataEdit.clear()
				%MapDataEdit.editable = false


func _on_map_list_item_selected(index: int) -> void:
	var map_data: Dictionary = %MapList.get_item_metadata(index)
	%MapDataEdit.text = str(map_data.buffer)
	%MapDataEdit.editable = true


func _load_player_data(entry: Dictionary) -> void:
	for child: Node in %Player.get_children():
		child.queue_free()
	var scroll := ScrollContainer.new()
	scroll.add_theme_constant_override("scrollbar_h_separation", 10)
	%Player.add_child(scroll)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_bottom", 2)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)
	var vbox := VBoxContainer.new()
	margin.add_child(vbox)
	for key: String in entry:
		if key in ["type", "size"]:
			continue
		var hbox := HBoxContainer.new()
		vbox.add_child(hbox)
		var label := Label.new()
		label.text = key.to_pascal_case()
		label.custom_minimum_size.x = 160
		hbox.add_child(label)
		var line_edit := LineEdit.new()
		line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line_edit.text = str(entry[key])
		line_edit.text_changed.connect(func (new_text: String) -> void:
			entry[key] = int(new_text)
		)
		hbox.add_child(line_edit)


func _load_inventory_data(entry: Dictionary) -> void:
	for child: Node in %Inventory.get_children():
		child.queue_free()
	var tree := Tree.new()
	%Inventory.add_child(tree)
	tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree.column_titles_visible = true
	tree.hide_root = true
	tree.allow_rmb_select = true
	tree.hide_folding = true
	tree.columns = 2
	tree.set_column_title(0, "Item")
	tree.set_column_title(1, "Quantity")
	tree.set_script(DRAG_TREE)
	var root: TreeItem = tree.create_item()
	for item: Dictionary in entry.items:
		var tree_item: TreeItem = root.create_child()
		tree_item.set_text(0, str(item.item_id))
		tree_item.set_text(1, str(item.quantity))
		tree_item.set_editable(0, true)
		tree_item.set_editable(1, true)
	
	var update_inventory: Callable = func () -> void:
		var items: Array = []
		for i in range(root.get_child_count()):
			var tree_item: TreeItem = root.get_child(i)
			var item: Dictionary = {
				"item_id": int(tree_item.get_text(0)),
				"quantity": int(tree_item.get_text(1)),
			}
			items.append(item)
		entry.items = items
	
	tree.item_edited.connect(update_inventory)
	tree.connect.call_deferred("item_moved", update_inventory)


func _load_map_data(entry: Dictionary) -> void:
	var idx: int = %MapList.add_item(entry.name)
	var map_data: Dictionary = %SaveList.get_item_metadata(%SaveList.get_selected_items()[0]).entries.filter(func (e: Dictionary) -> bool:
		return true if e.type == 0x09 else false
	)[idx]
	%MapList.set_item_metadata(idx, map_data)
	if %MapList.item_count == 1:
		%MapList.select(0)
		%MapList.ensure_current_is_visible()
		_on_map_list_item_selected(0)


func _load_other_data(entry: Dictionary) -> void:
	var hbox := HBoxContainer.new()
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	%UnknownContainer.add_child(hbox)
	
	var label := Label.new()
	label.custom_minimum_size.x = 100
	label.text = str(entry.type)
	hbox.add_child(label)
	
	var edit := TextEdit.new()
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	edit.caret_blink = true
	edit.text = str(entry.buffer)
	hbox.add_child(edit)
	
	edit.text_changed.connect(func () -> void:
		entry.buffer = PackedByteArray(Array(edit.text.trim_prefix("[").trim_suffix("]").split(", ")).map(func (i: String) -> int: return int(i)))
	)


func _on_map_data_edit_text_changed() -> void:
	var map_data: Dictionary = %MapList.get_item_metadata(%MapList.get_selected_items()[0])
	map_data.buffer = PackedByteArray(Array(%MapDataEdit.text.trim_prefix("[").trim_suffix("]").split(", ")).map(func (i: String) -> int: return int(i)))


func _on_save_name_edit_text_changed(new_text: String) -> void:
	var entry: Dictionary = %SaveList.get_item_metadata(%SaveList.get_selected_items()[0]).entries.filter(func (e: Dictionary) -> bool: return true if e.type == 0x0A else false)[0]
	entry.name = new_text


func _on_current_map_edit_text_changed(new_text: String) -> void:
	var entry: Dictionary = %SaveList.get_item_metadata(%SaveList.get_selected_items()[0]).entries.filter(func (e: Dictionary) -> bool: return true if e.type == 0x03 else false)[0]
	entry.name = new_text


func _on_file_header_edit_text_changed(new_text: String) -> void:
	var data: Dictionary = %SaveList.get_item_metadata(%SaveList.get_selected_items()[0])
	data.header = int(new_text)


func _on_file_footer_edit_text_changed(new_text: String) -> void:
	var data: Dictionary = %SaveList.get_item_metadata(%SaveList.get_selected_items()[0])
	data.footer = int(new_text)


func _on_edit_image_button_pressed() -> void:
	var entry: Dictionary = %SaveList.get_item_metadata(%SaveList.get_selected_items()[0]).entries.filter(func (e: Dictionary) -> bool: return true if e.type == 0x0B else false)[0]
	var new_image_data: Dictionary = await %ImageEditor.edit_image(entry, Das.DEFAULT_RAW_PALETTE, false, false, true, false, true)
	if new_image_data:
		entry.raw_image = new_image_data.raw_image
		entry.width = new_image_data.width
		entry.height = new_image_data.height
		%RothTextureContainer.load_data({"data": entry}, Das.DEFAULT_RAW_PALETTE)


func _on_save_button_pressed() -> void:
	var save_count: int = 0
	for i in range(%SaveList.item_count):
		var data: Dictionary = %SaveList.get_item_metadata(i)
		if original_data[i] != data:
			save_count += 1
			Console.print("Saving changes to file: %s" % data.filepath.get_file())
			SaveGame.compile_and_save(data)
			var image_entry: Dictionary = data.entries.filter(func (e: Dictionary) -> bool: return true if e.type == 0x0B else false)[0]
			%SaveList.set_item_icon(i, ImageTexture.create_from_image(Image.create_from_data(
				image_entry.width,
				image_entry.height,
				false,
				Image.FORMAT_RGB8,
				Utility.convert_palette_image(Das.DEFAULT_RAW_PALETTE, image_entry.raw_image, false, false)
			)))
			original_data[i] = data.duplicate(true)
	
	if save_count > 0:
		%SaveLabel.add_theme_color_override("font_color", Color.GREEN)
		%SaveLabel.text = "Saved %d file%s successfully!" % [save_count, "s" if save_count > 1 else ""]
	else:
		%SaveLabel.add_theme_color_override("font_color", Color.YELLOW)
		%SaveLabel.text = "No changes to save."
	
	%SaveLabel.modulate.a = 1.0
	if save_tween:
		save_tween.kill()
	save_tween = get_tree().create_tween()
	save_tween.tween_property(%SaveLabel, "modulate:a", 1.0, 0.5)
	save_tween.tween_property(%SaveLabel, "modulate:a", 0.0, 2.0)
