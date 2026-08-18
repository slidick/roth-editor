extends BaseWindow

signal done

var current_event: InputEvent
var event_data: Array = []

func get_event(p_event_data: Array) -> InputEvent:
	current_event = null
	event_data = p_event_data
	if event_data[1] == -1:
		%KeyLabel.text = ""
	else:
		%KeyLabel.text = event_data[2][event_data[1]].as_text()
	%EventEdit.text = ""
	%SaveButton.disabled = false
	%ErrorLabel.text = ""
	toggle(true)
	%EventEdit.grab_focus()
	
	var new_event: InputEvent = await done
	toggle(false)
	return new_event


func _on_cancel_button_pressed() -> void:
	toggle(false)
	done.emit(null)


func _on_save_button_pressed() -> void:
	done.emit(current_event)


func _on_event_edit_editing_toggled(toggled_on: bool) -> void:
	if toggled_on:
		%EventEdit.placeholder_text = "Listening for Input"
	else:
		%EventEdit.placeholder_text = "Filter by Event"


func _on_event_edit_gui_input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton:
		if event.pressed:
			var found: bool = false
			for each: InputEvent in event_data[2]:
				if event.is_match(each) and (event_data[1] == -1 or event_data[2][event_data[1]] != each):
					found = true
			if found:
				%SaveButton.disabled = true
				%ErrorLabel.text = "This action already contains this input event."
			else:
				%SaveButton.disabled = false
				%ErrorLabel.text = ""
			await get_tree().process_frame
			%EventEdit.text = event.as_text()
			%KeyLabel.text = event.as_text()
			current_event = event


func _on_filter_edit_text_changed(_new_text: String) -> void:
	pass # Replace with function body.


func _on_alt_check_box_toggled(_toggled_on: bool) -> void:
	pass # Replace with function body.


func _on_shift_check_box_toggled(_toggled_on: bool) -> void:
	pass # Replace with function body.


func _on_ctrl_check_box_toggled(_toggled_on: bool) -> void:
	pass # Replace with function body.


func _on_meta_check_box_toggled(_toggled_on: bool) -> void:
	pass # Replace with function body.


func _on_auto_check_box_toggled(_toggled_on: bool) -> void:
	pass # Replace with function body.


func _on_key_type_option_item_selected(_index: int) -> void:
	pass # Replace with function body.
