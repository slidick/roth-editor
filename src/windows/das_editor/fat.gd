extends MarginContainer


var das: Dictionary = {}
var key: String = ""


func reset() -> void:
	das = {}
	key = ""
	%ItemList.clear()
	%FATContainer.reset()


func load_das(p_das: Dictionary, p_key: String, p_starting_index: int) -> void:
	das = p_das
	key = p_key
	
	for i in range(len(das[key])):
		var idx: int = %ItemList.add_item(str(p_starting_index + i))
		%ItemList.set_item_metadata(idx, das[key][i])


func _on_item_list_item_selected(index: int) -> void:
	%FATContainer.reset()
	%FATContainer.load_das(das[key], index, das.palette)


func select_index(index: int) -> bool:
	for i in range(%ItemList.item_count):
		if %ItemList.get_item_text(i) == str(index):
			%ItemList.select(i)
			%ItemList.ensure_current_is_visible()
			_on_item_list_item_selected(i)
			return true
	return false
