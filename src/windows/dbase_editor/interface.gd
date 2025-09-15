extends Control

var dbase_data: Dictionary = {}


func _ready() -> void:
	%Tree.create_item()


func reset() -> void:
	dbase_data = {}
	for tree_item: TreeItem in %Tree.get_root().get_children():
		tree_item.free()
	%Tree.scroll_to_item(%Tree.get_root())


func load_dbase(p_dbase_data:Dictionary) -> void:
	reset()
	dbase_data = p_dbase_data
	
	for interface: Dictionary in dbase_data["dbase100"].interfaces:
		var tree_item: TreeItem = %Tree.get_root().create_child()
		if "string" in interface.text_entry:
			tree_item.set_text(0, "%s" % interface.text_entry.string)
			tree_item.add_button(0, owner.get_texture_color_with_color(interface.text_entry.font_color))
		else:
			tree_item.set_text(0, "%s" % "(Empty)")
			tree_item.add_button(0, owner.get_texture_color_with_color(0))
		
		tree_item.set_metadata(0, interface)


func _update_interfaces() -> void:
	var interfaces := []
	for tree_item: TreeItem in %Tree.get_root().get_children():
		interfaces.append(tree_item.get_metadata(0))
	dbase_data["dbase100"].interfaces = interfaces


func _on_tree_item_moved() -> void:
	_update_interfaces()


func _on_tree_item_activated() -> void:
	var tree_item: TreeItem = %Tree.get_selected()
	var interface: Dictionary = tree_item.get_metadata(0)
	await owner.edit_item_with_text_entry(interface)
	if "string" in interface.text_entry:
		tree_item.set_text(0, interface.text_entry.string)
		tree_item.set_button(0, 0, owner.get_texture_color_with_color(interface.text_entry.font_color))
	else:
		tree_item.set_text(0, "(Empty)")
		tree_item.set_button(0, 0, owner.get_texture_color_with_color(0))


func refresh_text(text_entry: Dictionary) -> void:
	for tree_item: TreeItem in %Tree.get_root().get_children():
		var interface: Dictionary = tree_item.get_metadata(0)
		if "text_entry" in interface and is_same(interface.text_entry, text_entry):
			if "string" in text_entry:
				tree_item.set_text(0, text_entry.string)
				tree_item.set_button(0, 0, owner.get_texture_color_with_color(text_entry.font_color))
			else:
				tree_item.set_text(0, "(Empty)")
				tree_item.set_button(0, 0, owner.get_texture_color_with_color(0))


func jump_to_reference(p_reference: Dictionary) -> void:
	var tree_item: TreeItem = %Tree.get_root().get_child(p_reference.index-1)
	tree_item.select(0)
	%Tree.scroll_to_item(tree_item)
