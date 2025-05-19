extends BaseWindow
signal finished(results: Array)

var tree_root: TreeItem
var selected_item: TreeItem

func _ready() -> void:
	super._ready()
	tree_root = %Tree.create_item()
	%Tree.set_column_title(0, "unk0x00")
	%Tree.set_column_title(1, "unk0x02")
	%Tree.set_column_title(2, "unk0x04")
	%Tree.set_column_title(3, "unk0x06")
	%Tree.set_column_title(4, "unk0x08")
	%Tree.set_column_title(5, "unk0x0A")
	%Tree.set_column_title(6, "unk0x0C")
	%Tree.set_column_title(7, "unk0x0E")
	%Tree.set_column_title(8, "unk0x10")
	%Tree.set_column_title(9, "unk0x12")
	%Tree.set_column_title(10, "unk0x14")
	%Tree.set_column_title(11, "unk0x16")
	%Tree.set_column_title(12, "unk0x18")
	%Tree.set_column_title(13, "unk0x1A")
	%Tree.set_column_title(14, "unk0x1C")
	%Tree.set_column_title(15, "unk0x1E")


func _fade_out() -> void:
	super._fade_out()
	finished.emit([false])


func edit_data(array_02: Array) -> Array:
	for child: TreeItem in tree_root.get_children():
		tree_root.remove_child(child)
	
	for row: Dictionary in array_02:
		var tree_item: TreeItem = tree_root.create_child()
		var i: int = 0
		for key: String in row:
			tree_item.set_text(i, "%d" % row[key])
			tree_item.set_editable(i, true)
			i += 1
	toggle(true)
	var results: Array = await finished
	toggle(false)
	return results


func _on_cancel_button_pressed() -> void:
	finished.emit([false])


func _on_save_button_pressed() -> void:
	var array_02 := []
	for tree_item: TreeItem in tree_root.get_children():
		var row := {}
		for i in range(%Tree.columns):
			row[%Tree.get_column_title(i)] = int(tree_item.get_text(i))
		array_02.append(row)
		
	finished.emit([true, array_02])


func _on_tree_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		selected_item = %Tree.get_item_at_position(mouse_position)
		%PopupMenu.popup(Rect2i(int(mouse_position.x + %Tree.global_position.x), int(mouse_position.y + %Tree.global_position.y), 0, 0))


func _on_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			tree_root.remove_child(selected_item)
			selected_item.free()
			selected_item = null


func _on_add_row_button_pressed() -> void:
	var tree_item: TreeItem = tree_root.create_child()
	for i in range(%Tree.columns):
		tree_item.set_text(i, "0")
		tree_item.set_editable(i, true)
