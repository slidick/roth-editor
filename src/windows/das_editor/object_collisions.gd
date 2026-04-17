extends MarginContainer

signal jump_to_object_pressed(index: int)

var das: Dictionary = {}
var key: String = ""


func reset() -> void:
	das = {}
	key = ""
	%ItemList.clear()
	%Container.hide()
	%HeightEdit.text = ""
	%WidthEdit.text = ""
	%Unk0x00Edit.text = ""
	%WidthPerpendicularEdit.text = ""
	%WidthParallelEdit.text = ""


func load_das(p_das: Dictionary, p_key: String, p_starting_index: int = 0) -> void:
	das = p_das
	key = p_key
	
	for i in range(len(das[key])):
		var idx: int = %ItemList.add_item(str(p_starting_index + i))
		%ItemList.set_item_metadata(idx, das[key][i])


func _on_item_list_item_selected(index: int) -> void:
	var data: Dictionary = %ItemList.get_item_metadata(index)
	if "data" in das.fat_3[index]:
		%Container.show()
		if "num_vertices" not in das.fat_3[index].data:
			%"3DObjectContainer".hide()
			%RegularContainer.show()
			%HeightEdit.text = "%d" % int(data.raw_data & 65535)
			%WidthEdit.text = "%d" % (int(data.raw_data & 4294901760) >> 16)
		else:
			%Unk0x00Edit.text = "%d" % int(data.raw_data & 255)
			%HeightEdit.text = "%d" % (int(data.raw_data & 65280) >> 8)
			%WidthPerpendicularEdit.text = "%d" % (int(data.raw_data & 16711680) >> 16)
			%WidthParallelEdit.text = "%d" % (int(data.raw_data & 4278190080) >> 24)
			%"3DObjectContainer".show()
			%RegularContainer.hide()
	elif das.fat_3[index].flags_1 & 32 > 0:
		%Container.show()
		%"3DObjectContainer".hide()
		%RegularContainer.show()
		%HeightEdit.text = "%d" % int(data.raw_data & 65535)
		%WidthEdit.text = "%d" % (int(data.raw_data & 4294901760) >> 16)
	else:
		%Container.hide()


func update_data() -> void:
	var index: int = %ItemList.get_selected_items()[0]
	var data: Dictionary = %ItemList.get_item_metadata(index)
	if "data" in das.fat_3[index]:
		if "num_vertices" not in das.fat_3[index].data:
			data.raw_data = int(%HeightEdit.text) + (int(%WidthEdit.text) << 16)
		else:
			data.raw_data = int(%Unk0x00Edit.text) + (int(%HeightEdit.text) << 8) + (int(%WidthPerpendicularEdit.text) << 16) + (int(%WidthParallelEdit.text) << 24)


func _on_height_edit_text_changed(_new_text: String) -> void:
	update_data()


func _on_width_edit_text_changed(_new_text: String) -> void:
	update_data()


func _on_width_perpendicular_edit_text_changed(_new_text: String) -> void:
	update_data()


func _on_width_parallel_edit_text_changed(_new_text: String) -> void:
	update_data()


func _on_unk_0x_00_edit_text_changed(_new_text: String) -> void:
	update_data()


func select(index: int) -> void:
	%ItemList.select(index)
	_on_item_list_item_selected(index)


func _on_jump_to_object_button_pressed() -> void:
	jump_to_object_pressed.emit(%ItemList.get_selected_items()[0])
