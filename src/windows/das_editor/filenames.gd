extends MarginContainer

signal jump_to_index_pressed(index: int)

var das: Dictionary = {}
var key: String = ""


func _ready() -> void:
	%FilenamesContainer.jump_to_index_pressed.connect(jump_to_index_pressed.emit)


func reset() -> void:
	das = {}
	%ItemList.clear()
	%FilenamesContainer.reset()

func load_das(p_das: Dictionary, p_key: String) -> void:
	das = p_das
	key = p_key
	
	for filename_info: Dictionary in p_das[key]:
		var idx: int = %ItemList.add_item(filename_info.name)
		%ItemList.set_item_metadata(idx, filename_info)


func _on_item_list_item_selected(index: int) -> void:
	%FilenamesContainer.reset()
	%FilenamesContainer.load_das(das[key], index)
