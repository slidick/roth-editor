extends Control

var dbase_data: Dictionary = {}


func _ready() -> void:
	%Tree.create_item()
	%Tree.set_column_title(0, "Index")
	%Tree.set_column_title(1, "Filename")
	%Tree.set_column_title(2, "Title")
	%Tree.set_column_title(3, "Subtitles")
	%Tree.set_column_expand(0, false)
	%Tree.set_column_expand(1, false)
	%Tree.set_column_custom_minimum_width(1, 200)


func reset() -> void:
	dbase_data = {}
	for tree_item: TreeItem in %Tree.get_root().get_children():
		tree_item.free()
	%Tree.scroll_to_item(%Tree.get_root())


func load_dbase(p_dbase_data: Dictionary) -> void:
	reset()
	dbase_data = p_dbase_data
	
	for cutscene: Dictionary in dbase_data["dbase100"].cutscenes:
		add_cutscene(cutscene)


func add_cutscene(cutscene: Dictionary) -> TreeItem:
	var tree_item: TreeItem = %Tree.get_root().create_child()
	tree_item.set_text(0, "%s" % %Tree.get_root().get_child_count())
	tree_item.set_text(1, "%s" % cutscene.name)
	tree_item.set_metadata(0, cutscene)
	if not cutscene.text_entry.is_empty():
		tree_item.set_text(2, "%s" % cutscene.text_entry.string)
	else:
		tree_item.set_text(2, "(Empty)")
	tree_item.set_text(3, "%s" % cutscene.offset_dbase400_subtitles)
	return tree_item


func save_cutscenes() -> void:
	var cutscenes := []
	var i: int = 1
	for tree_item: TreeItem in %Tree.get_root().get_children():
		tree_item.set_text(0, str(i))
		i += 1
		var cutscene: Dictionary = tree_item.get_metadata(0)
		cutscene.name = tree_item.get_text(1)
		cutscenes.append(cutscene)
	dbase_data["dbase100"].cutscenes = cutscenes


func _on_tree_item_edited() -> void:
	save_cutscenes()


func _on_tree_item_moved() -> void:
	save_cutscenes()


func _on_tree_item_selected() -> void:
	# Work-around to simulate edit only on double click
	var tree_item: TreeItem = %Tree.get_selected()
	tree_item.set_editable(1, true)
	await get_tree().create_timer(0.5).timeout
	if tree_item:
		tree_item.set_editable(1, false)




func _on_tree_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			%PopupMenu.popup(Rect2i(int(%Tree.global_position.x+mouse_position.x), int(%Tree.global_position.y+mouse_position.y), 0, 0))


func _on_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			var tree_item := add_cutscene(%Tree.get_selected().get_metadata(0).duplicate(true))
			tree_item.select(1)
			%Tree.scroll_to_item(tree_item)
			save_cutscenes()
		1:
			if not await Dialog.confirm("This will alter array order!\nReferences to cutscene will not be updated!\nConfirm delete?", "Warning!", false, Vector2(400, 20)):
				return
			var tree_item: TreeItem = %Tree.get_selected()
			%Tree.get_root().remove_child(tree_item)
			tree_item.free()
			save_cutscenes()


func _on_tree_item_activated() -> void:
	if %Tree.get_selected_column() == 2:
		var tree_item: TreeItem = %Tree.get_selected()
		var cutscene: Dictionary = tree_item.get_metadata(0)
		await owner.edit_item_with_text_entry(cutscene)
		if "string" in cutscene.text_entry:
			tree_item.set_text(2, cutscene.text_entry.string)
		else:
			tree_item.set_text(2, "(Empty)")


func _on_add_button_pressed() -> void:
	var cutscene := {
		"name": "",
		"text_entry": {},
		"offset_dbase400_subtitles": 0,
		"subtitles": {},
	}
	var tree_item: TreeItem = add_cutscene(cutscene)
	tree_item.select(1)
	%Tree.scroll_to_item(tree_item)
	save_cutscenes()
