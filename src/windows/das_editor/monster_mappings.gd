extends MarginContainer


var das: Dictionary = {}
var key: String = ""


func reset() -> void:
	das = {}
	key = ""
	%ItemList.clear()
	%Container.reset()


func load_das(p_das: Dictionary, p_key: String, p_starting_index: int = 0) -> void:
	das = p_das
	key = p_key
	
	for i in range(len(das[key])):
		var idx: int = %ItemList.add_item(str(p_starting_index + i))
		%ItemList.set_item_metadata(idx, das[key][i])


func _on_item_list_item_selected(index: int) -> void:
	%Container.reset()
	%Container.load_das(das[key], index)
