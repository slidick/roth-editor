extends Control

var dbase_data: Dictionary = {}


func _ready() -> void:
	%Tree.create_item()
	%Tree.set_column_title(0, "Offset")


func load_dbase(p_dbase_data:Dictionary) -> void:
	dbase_data = p_dbase_data
	
	for tree_item: TreeItem in %Tree.get_root().get_children():
		tree_item.free()
	
	for interface: Dictionary in dbase_data["dbase100"].interfaces:
		var tree_item: TreeItem = %Tree.get_root().create_child()
		tree_item.set_text(0, "%s" % interface.offset)


func _update_interfaces() -> void:
	var interfaces := []
	for tree_item: TreeItem in %Tree.get_root().get_children():
		interfaces.append({"offset": int(tree_item.get_text(0))})
	dbase_data["dbase100"].interfaces = interfaces


func _on_tree_item_edited() -> void:
	_update_interfaces()


func _on_tree_item_moved() -> void:
	_update_interfaces()


func _on_tree_item_selected() -> void:
	# Work-around to simulate edit only on double click
	var tree_item: TreeItem = %Tree.get_selected()
	tree_item.set_editable(0, true)
	await get_tree().create_timer(0.5).timeout
	if tree_item:
		tree_item.set_editable(0, false)
