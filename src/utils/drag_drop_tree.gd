extends Tree

signal item_moved

func _get_drag_data(_at_position: Vector2) -> Variant:
	var items := []
	var next: TreeItem = get_next_selected(null)
	var v := VBoxContainer.new()
	while next:
		#if get_root() == next.get_parent():
		items.append(next)
		var l := Label.new()
		l.text = next.get_text(0)
		v.add_child(l)
		next = get_next_selected(next)
	set_drag_preview(v)
	return items


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	drop_mode_flags = Tree.DROP_MODE_INBETWEEN
	var drop_section := get_drop_section_at_position(at_position)
	if drop_section == -100:
		return false
	var item := get_item_at_position(at_position)
	while item != get_root():
		if item in data:
			return false
		item = item.get_parent()
	return true


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var drop_section := get_drop_section_at_position(at_position)
	var other_item := get_item_at_position(at_position)
	for i: int in range(data.size()):
		var item := data[i] as TreeItem
		if drop_section == -1:
			item.move_before(other_item)
		elif drop_section == 0:
			if other_item.get_child_count() > 0:
				if i == 0:
					item.move_after(other_item.get_child(other_item.get_child_count()-1))
				else:
					item.move_after(data[i - 1])
			else:
				if i == 0:
					item.get_parent().remove_child(item)
					other_item.add_child(item)
				else:
					item.move_after(data[i - 1])
			other_item.collapsed = false
		elif drop_section == 1:
			if other_item.get_child_count() > 0 and not other_item.collapsed:
				if i == 0:
					item.move_before(other_item.get_child(0))
				else:
					item.move_after(data[i - 1])
			else:
				if i == 0:
					item.move_after(other_item)
				else:
					item.move_after(data[i - 1])
	item_moved.emit()
