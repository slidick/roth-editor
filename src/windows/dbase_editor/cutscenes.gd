extends Control

var dbase_data: Dictionary = {}
var copy_cutscene: Dictionary = {}

func _ready() -> void:
	%Tree.create_item()
	%Tree.set_column_title(0, "Filename")
	%Tree.set_column_title(1, "Title Offset")
	%Tree.set_column_title(2, "Subtitle Offset")


func load_dbase(p_dbase_data: Dictionary) -> void:
	dbase_data = p_dbase_data
	
	for tree_item: TreeItem in %Tree.get_root().get_children():
		tree_item.free()
	
	for cutscene: Dictionary in dbase_data["dbase100"].cutscenes:
		var tree_item: TreeItem = %Tree.get_root().create_child()
		tree_item.set_text(0, "%s" % cutscene.name)
		tree_item.set_text(1, "%s" % cutscene.offset_dbase400)
		tree_item.set_text(2, "%s" % cutscene.offset_dbase400_subtitles)


func save_cutscenes() -> void:
	var cutscenes := []
	for tree_item: TreeItem in %Tree.get_root().get_children():
		var cutscene: Dictionary = {}
		cutscene.name = tree_item.get_text(0)
		cutscene.offset_dbase400 = int(tree_item.get_text(1))
		cutscene.offset_dbase400_subtitles = int(tree_item.get_text(2))
		if cutscene.offset_dbase400 != 0:
			cutscene.entry = DBase400.get_entry_from_file(dbase_data["dbase400"].filepath, cutscene.offset_dbase400)
		if cutscene.offset_dbase400_subtitles != 0:
			cutscene.subtitles = DBase400.get_subtitle_from_file(dbase_data["dbase400"].filepath, cutscene.offset_dbase400_subtitles)
		cutscenes.append(cutscene)
	print(JSON.stringify(cutscenes, '\t'))
	dbase_data["dbase100"].cutscenes = cutscenes


func _on_tree_item_edited() -> void:
	save_cutscenes()


func _on_tree_item_moved() -> void:
	save_cutscenes()


func _on_tree_item_selected() -> void:
	# Work-around to simulate edit only on double click
	var tree_item: TreeItem = %Tree.get_selected()
	tree_item.set_editable(0, true)
	tree_item.set_editable(1, true)
	tree_item.set_editable(2, true)
	await get_tree().create_timer(0.5).timeout
	if tree_item:
		tree_item.set_editable(0, false)
		tree_item.set_editable(1, false)
		tree_item.set_editable(2, false)


func _on_tree_empty_clicked(click_position: Vector2, mouse_button_index: int) -> void:
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			if copy_cutscene.is_empty():
				%EmptyPopupMenu.set_item_disabled(1, true)
			else:
				%EmptyPopupMenu.set_item_disabled(1, false)
			%EmptyPopupMenu.popup(Rect2i(int(%Tree.global_position.x+click_position.x), int(%Tree.global_position.y+click_position.y), 0, 0))
		MOUSE_BUTTON_LEFT:
			%Tree.deselect_all()
			%Tree.release_focus()


func _on_tree_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			%PopupMenu.popup(Rect2i(int(%Tree.global_position.x+mouse_position.x), int(%Tree.global_position.y+mouse_position.y), 0, 0))


func _on_empty_popup_menu_index_pressed(_index: int) -> void:
	pass # Replace with function body.


func _on_popup_menu_index_pressed(_index: int) -> void:
	pass # Replace with function body.
