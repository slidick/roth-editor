extends Control

signal text_entry_selected(text_entry: Dictionary)

var dbase_data: Dictionary = {}
var is_selection_window: bool = false

func reset() -> void:
	dbase_data = {}
	is_selection_window = false
	%Tree.clear()
	%Tree.create_item()
	%SearchEdit.text = ""
	%Tree.scroll_to_item(%Tree.get_root())


func load_dbase(p_dbase_data: Dictionary, p_is_selection_window: bool = false) -> void:
	reset()
	dbase_data = p_dbase_data
	is_selection_window = p_is_selection_window
	search()

func search(filter: String = "") -> void:
	%Tree.clear()
	%Tree.create_item()
	for text_entry: Dictionary in dbase_data["dbase100"].text_entrys:
		if not filter.is_empty():
			if text_entry.string.to_lower().find(filter.to_lower()) == -1:
				continue
		var tree_item: TreeItem = %Tree.get_root().create_child()
		if "string" in text_entry:
			tree_item.set_text(0, text_entry.string)
			if not is_selection_window:
				tree_item.add_button(0, owner.get_texture_color_with_color(text_entry.font_color))
		else:
			tree_item.set_text(0, "(Empty)")
			if not is_selection_window:
				tree_item.add_button(0, owner.get_texture_color_with_color(0))
		tree_item.set_autowrap_mode(0, TextServer.AUTOWRAP_WORD_SMART)
		tree_item.set_metadata(0, text_entry)


func _on_tree_item_activated() -> void:
	var tree_item: TreeItem = %Tree.get_selected()
	var text_entry: Dictionary = tree_item.get_metadata(0)
	if is_selection_window:
		text_entry_selected.emit(text_entry)
		return
	await owner.edit_text_entry(text_entry)
	if "string" in text_entry:
		tree_item.set_text(0, text_entry.string)
		tree_item.set_button(0, 0, owner.get_texture_color_with_color(text_entry.font_color))
	else:
		tree_item.set_text(0, "(Empty)")
		tree_item.set_button(0, 0, owner.get_texture_color_with_color(0))


func refresh_text(p_text_entry: Dictionary) -> void:
	for tree_item: TreeItem in %Tree.get_root().get_children():
		if is_same(tree_item.get_metadata(0), p_text_entry):
			if "string" in p_text_entry:
				tree_item.set_text(0, p_text_entry.string)
				tree_item.set_button(0, 0, owner.get_texture_color_with_color(p_text_entry.font_color))
			else:
				tree_item.set_text(0, "(Empty)")
				tree_item.set_button(0, 0, owner.get_texture_color_with_color(0))
	
	
	for text_entry: Dictionary in dbase_data["dbase100"].text_entrys:
		if is_same(text_entry, p_text_entry):
			return
	
	var tree_item: TreeItem = %Tree.get_root().create_child()
	tree_item.set_autowrap_mode(0, TextServer.AUTOWRAP_WORD_SMART)
	tree_item.set_metadata(0, p_text_entry)
	if "string" in p_text_entry:
		tree_item.set_text(0, p_text_entry.string)
		tree_item.add_button(0, owner.get_texture_color_with_color(p_text_entry.font_color))
	else:
		tree_item.set_text(0, "(Empty)")
		tree_item.add_button(0, owner.get_texture_color_with_color(0))
	dbase_data["dbase100"].text_entrys.append(p_text_entry)
	await get_tree().process_frame
	%Tree.queue_redraw()
	search(%SearchEdit.text)


func _on_search_edit_text_changed(new_text: String) -> void:
	search(new_text)
