extends Control

signal item_activated(index: int)
signal item_selected(index: int)
signal context_option_selected(index: int, context_index: int)

var item_count : int :
	get():
		return %HFlowContainer.get_child_count()
	set(new_value):
		pass

func clear() -> void:
	for child: RotatedIconNode in %HFlowContainer.get_children():
		%HFlowContainer.remove_child(child)
		child.queue_free()


func deselect_all() -> void:
	for child: RotatedIconNode in %HFlowContainer.get_children():
		child.deselect()


func add_item(p_text: String, p_icon: Texture2D, p_icon_size := Vector2(150,150), p_context_options: Array[String] = []) -> int:
	var new_index: int = %HFlowContainer.get_child_count()
	var rotated_icon_node := RotatedIconNode.new(new_index, p_text, p_icon, true, p_icon_size, p_context_options)
	rotated_icon_node.activated.connect(func (p_index: int) -> void:
		item_activated.emit(p_index)
	)
	rotated_icon_node.selected.connect(func (p_index: int) -> void:
		for child: RotatedIconNode in %HFlowContainer.get_children():
			if child.index != p_index:
				child.deselect()

		item_selected.emit(p_index)
	)
	rotated_icon_node.context_option_selected.connect(func (p_index: int, p_context_index: int) -> void:
		context_option_selected.emit(p_index, p_context_index)
	)
	%HFlowContainer.add_child(rotated_icon_node)
	return new_index


func move_item(at_index: int, to_index: int) -> void:
	if at_index == to_index:
		return
	
	var child: Node = %HFlowContainer.get_child(at_index)
	%HFlowContainer.move_child(child, to_index)
	child.index = to_index
	
	if to_index < at_index:
		for i in range(to_index+1, at_index+1):
			%HFlowContainer.get_child(i).index += 1
	if to_index > at_index:
		for i in range(at_index, to_index):
			%HFlowContainer.get_child(i).index -= 1


func remove_item(at_index: int) -> void:
	var child: Node = %HFlowContainer.get_child(at_index)
	%HFlowContainer.remove_child(child)
	child.queue_free()
	
	for i in range(at_index, %HFlowContainer.get_child_count()):
		%HFlowContainer.get_child(i).index -= 1


func set_hidden(p_index: int, p_hidden: bool) -> void:
	%HFlowContainer.get_child(p_index).visible = not p_hidden


func set_rotated(p_index: int, p_rotated: bool) -> void:
	%HFlowContainer.get_child(p_index).set_rotated(p_rotated)


func set_item_text(p_index: int, p_text: String) -> void:
	var child: RotatedIconNode = %HFlowContainer.get_child(p_index)
	if child:
		child.set_text(p_text)


func set_item_icon(p_index: int, p_icon: Texture2D) -> void:
	var child: RotatedIconNode = %HFlowContainer.get_child(p_index)
	if child:
		child.set_icon(p_icon)


func set_item_metadata(p_index: int, p_metadata: Variant) -> void:
	var child: RotatedIconNode = %HFlowContainer.get_child(p_index)
	if child:
		child.set_metadata(p_metadata)


func get_item_metadata(p_index: int) -> Variant:
	var child: RotatedIconNode = %HFlowContainer.get_child(p_index)
	if child:
		return child.get_metadata()
	return null


func select(p_index: int) -> void:
	if p_index == -1:
		for child: RotatedIconNode in %HFlowContainer.get_children():
			child.deselect()
		item_selected.emit(-1)
		return
	var child: RotatedIconNode = %HFlowContainer.get_child(p_index)
	if child:
		child.select()
	item_selected.emit(p_index)


func get_item_position(p_index: int) -> Variant:
	var child: RotatedIconNode = %HFlowContainer.get_child(p_index)
	if child:
		return child.position
	return null


func scroll_to_index(p_index: int) -> void:
	var child: RotatedIconNode = %HFlowContainer.get_child(p_index)
	if child:
		await get_tree().process_frame
		%ScrollContainer.scroll_vertical = child.position.y - (%ScrollContainer.size.y / 2.0) + (child.size.y / 2.0)
