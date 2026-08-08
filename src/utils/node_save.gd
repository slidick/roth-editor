class_name NodeSave
extends Object


static func reset(_things: Dictionary) -> void:
	for outer_key: String in _things:
		var settings: Dictionary = Settings.settings.get(outer_key, {})
		var modified: bool = false
		var save_data: Dictionary = {}
		for key: String in _things[outer_key]:
			if key in settings:
				_handle_node_reset(_things[outer_key][key].node, settings[key])
				_things[outer_key][key].value = settings[key]
			else:
				_handle_node_reset(_things[outer_key][key].node, _things[outer_key][key].value)
				save_data[key] = _things[outer_key][key].value
				modified = true
		if modified:
			Settings.update_settings(outer_key, save_data)


static func save(_things: Dictionary) -> void:
	for outer_key: String in _things:
		var save_data  : Dictionary = {}
		for key: String in _things[outer_key]:
			_handle_node_save(_things[outer_key][key])
			save_data[key] = _things[outer_key][key].value
		Settings.update_settings(outer_key, save_data)


static func _handle_node_reset(node: Control, value: Variant) -> void:
	if node is LineEdit:
		node.text = value
	if (node is CheckBox or
			node is CheckButton):
		node.button_pressed = value
	if node is OptionButton:
		for i in range(node.item_count):
			if node.get_item_text(i).to_lower() == value.to_lower():
				node.selected = i
	if node is SpinBox:
		node.value = value


static func _handle_node_save(node_data: Dictionary) -> void:
	if node_data.node is LineEdit:
		node_data.value = node_data.node.text
	if (node_data.node is CheckBox or
			node_data.node is CheckButton):
		node_data.value = node_data.node.button_pressed
	if node_data.node is OptionButton:
		node_data.value = node_data.node.text.to_lower()
	if node_data.node is SpinBox:
		node_data.value = int(node_data.node.value)
