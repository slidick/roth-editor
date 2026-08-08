extends BaseWindow
signal finished(results: Array)

var tree_root: TreeItem
var selected_item: TreeItem

func _ready() -> void:
	super._ready()
	tree_root = %Tree.create_item()
	%Tree.set_column_title(0, "index")
	%Tree.set_column_title(1, "zoneCount")
	%Tree.set_column_title(2, "zone1Dampen")
	%Tree.set_column_title(3, "zone1Flags")
	%Tree.set_column_title(4, "zone1XBoundLower")
	%Tree.set_column_title(5, "zone1YBoundLower")
	%Tree.set_column_title(6, "zone1XBoundUpper")
	%Tree.set_column_title(7, "zone1YBoundUpper")
	%Tree.set_column_title(8, "zone2Dampen")
	%Tree.set_column_title(9, "zone2Flags")
	%Tree.set_column_title(10, "zone2XBoundLower")
	%Tree.set_column_title(11, "zone2YBoundLower")
	%Tree.set_column_title(12, "zone2XBoundUpper")
	%Tree.set_column_title(13, "zone2YBoundUpper")
	%Tree.set_column_title(14, "zone3Dampen")
	%Tree.set_column_title(15, "zone3Flags")
	%Tree.set_column_title(16, "zone3XBoundLower")
	%Tree.set_column_title(17, "zone3YBoundLower")
	%Tree.set_column_title(18, "zone3XBoundUpper")
	%Tree.set_column_title(19, "zone3YBoundUpper")


func _fade_out() -> void:
	super._fade_out()
	finished.emit([false])


func edit_data(array_02: Array) -> Array:
	for child: TreeItem in tree_root.get_children():
		tree_root.remove_child(child)
		child.free()
	
	for row: Dictionary in array_02:
		var tree_item: TreeItem = tree_root.create_child()
		var i: int = 0
		for key: String in row:
			tree_item.set_text(i+1, "%d" % row[key])
			tree_item.set_editable(i+1, true)
			i += 1
	update_row_indices()
	toggle(true)
	var results: Array = await finished
	toggle(false)
	return results


func update_row_indices() -> void:
	var i: int = 1
	for tree_item: TreeItem in tree_root.get_children():
		tree_item.set_text(0, "%d" % i)
		i += 1


func _on_cancel_button_pressed() -> void:
	finished.emit([false])


func _on_save_button_pressed() -> void:
	var array_02 := []
	for tree_item: TreeItem in tree_root.get_children():
		var row := {}
		for i in range(1, %Tree.columns):
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
	%Tree.scroll_to_item(tree_item)


func _on_tree_item_moved() -> void:
	update_row_indices()
