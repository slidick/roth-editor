extends BaseWindow

signal done
var current_hex: bool = false

func reset_actions(current_opcode: int, as_hex: bool, hide_item_actions: bool) -> void:
	current_hex = as_hex
	%ItemList.clear()
	%ItemActionsCheckBox.show()
	%ItemActionsCheckBox.set_pressed_no_signal(hide_item_actions)
	for key: int in Opcodes.dbase100:
		var opcode_data: Dictionary = Opcodes.dbase100[key]
		if hide_item_actions and opcode_data.only_item:
			continue
		opcode_data.opcode = key
		var idx: int = %ItemList.add_item(("0x%02X: %s" % [opcode_data.opcode, opcode_data.name]) if as_hex else ("%d: %s" % [opcode_data.opcode, opcode_data.name]))
		%ItemList.set_item_metadata(idx, opcode_data)
	if current_opcode != -1:
		for i in range(%ItemList.item_count):
			var opcode_data: Dictionary = %ItemList.get_item_metadata(i)
			if opcode_data.opcode == current_opcode:
				%ItemList.select(i)
				_on_item_list_item_selected(i)
				break
	if not %ItemList.is_anything_selected():
		%ItemList.select(0)
		_on_item_list_item_selected(0)
	
	# Bugfix: Ensures proper scroll on first load
	await get_tree().process_frame
	%ItemList.ensure_current_is_visible()


func reset_trigger(current_trigger: int, as_hex: bool) -> void:
	current_hex = as_hex
	%ItemActionsCheckBox.hide()
	%ItemList.clear()
	for key: int in Opcodes.triggers:
		var trigger_data: Dictionary = Opcodes.triggers[key]
		trigger_data.trigger = key
		var idx: int = %ItemList.add_item(("0x%02X: %s" % [trigger_data.trigger, trigger_data.name]) if as_hex else ("%d: %s" % [trigger_data.trigger, trigger_data.name]))
		%ItemList.set_item_metadata(idx, trigger_data)
	if current_trigger != -1:
		for i in range(%ItemList.item_count):
			var trigger_data: Dictionary = %ItemList.get_item_metadata(i)
			if trigger_data.trigger == current_trigger:
				%ItemList.select(i)
				_on_item_list_item_selected(i)
				break
	else:
		%ItemList.select(0)
		_on_item_list_item_selected(0)
	
	# Bugfix: Ensures proper scroll on first load
	await get_tree().process_frame
	%ItemList.ensure_current_is_visible()


func _on_item_list_item_selected(index: int) -> void:
	var opcode_data: Dictionary = %ItemList.get_item_metadata(index)
	%DescLabel.text = opcode_data.desc


func action_selection(current_opcode: int = -1, as_hex: bool = false, hide_item_actions: bool = false) -> int:
	reset_actions(current_opcode, as_hex, hide_item_actions)
	toggle(true)
	var opcode: int = await done
	toggle(false)
	return opcode


func trigger_selection(current_trigger: int = -1, as_hex: bool = false) -> int:
	reset_trigger(current_trigger, as_hex)
	toggle(true)
	var trigger: int = await done
	toggle(false)
	return trigger


func _on_item_list_item_activated(_index: int) -> void:
	_on_save_button_pressed()


func _on_cancel_button_pressed() -> void:
	done.emit(-1)


func _on_save_button_pressed() -> void:
	var data: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	if "opcode" in data:
		done.emit(data.opcode)
	elif "trigger" in data:
		done.emit(data.trigger)


func _on_item_actions_check_box_toggled(toggled_on: bool) -> void:
	reset_actions(%ItemList.get_item_metadata(%ItemList.get_selected_items()[0]).opcode, current_hex, toggled_on)
