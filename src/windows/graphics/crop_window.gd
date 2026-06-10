extends BaseWindow

signal done(data: Dictionary)
signal changed(data: Dictionary)

var texture_data: Dictionary = {}
var rotated_canvas: bool = false

func crop_image(p_texture_data: Dictionary, p_rotated_canvas: bool) -> Dictionary:
	texture_data = p_texture_data
	rotated_canvas = p_rotated_canvas
	%LeftSpinBox.set_value_no_signal(0)
	%TopSpinBox.set_value_no_signal(0)
	%RightSpinBox.set_value_no_signal(0)
	%BottomSpinBox.set_value_no_signal(0)
	if rotated_canvas:
		%LeftSpinBox.max_value = texture_data.height - 1
		%TopSpinBox.max_value = texture_data.width - 1
		%RightSpinBox.max_value = texture_data.height - 1
		%BottomSpinBox.max_value = texture_data.width - 1
	else:
		%LeftSpinBox.max_value = texture_data.width - 1
		%TopSpinBox.max_value = texture_data.height - 1
		%RightSpinBox.max_value = texture_data.width - 1
		%BottomSpinBox.max_value = texture_data.height - 1
	toggle(true)
	var data: Dictionary = await done
	toggle(false)
	return data


func update() -> void:
	if %PreviewButton.button_pressed:
		changed.emit({
			"left": int(%LeftSpinBox.value),
			"top": int(%TopSpinBox.value),
			"right": int(%RightSpinBox.value),
			"bottom": int(%BottomSpinBox.value),
		})
	if rotated_canvas:
		%LeftSpinBox.max_value = texture_data.height - %RightSpinBox.value - 1
		%RightSpinBox.max_value = texture_data.height - %LeftSpinBox.value - 1
		%TopSpinBox.max_value = texture_data.width - %BottomSpinBox.value - 1
		%BottomSpinBox.max_value = texture_data.width - %TopSpinBox.value - 1
	else:
		%LeftSpinBox.max_value = texture_data.width - %RightSpinBox.value - 1
		%RightSpinBox.max_value = texture_data.width - %LeftSpinBox.value - 1
		%TopSpinBox.max_value = texture_data.height - %BottomSpinBox.value - 1
		%BottomSpinBox.max_value = texture_data.height - %TopSpinBox.value - 1


func _on_cancel_button_pressed() -> void:
	done.emit({})
	toggle(false)


func _on_save_button_pressed() -> void:
	done.emit({
		"left": int(%LeftSpinBox.value),
		"top": int(%TopSpinBox.value),
		"right": int(%RightSpinBox.value),
		"bottom": int(%BottomSpinBox.value),
	})


func _on_preview_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		update()
	else:
		changed.emit({
			"left": 0,
			"top": 0,
			"right": 0,
			"bottom": 0,
		})


func _on_left_spin_box_value_changed(_value: float) -> void:
	update()


func _on_top_spin_box_value_changed(_value: float) -> void:
	update()


func _on_right_spin_box_value_changed(_value: float) -> void:
	update()


func _on_bottom_spin_box_value_changed(_value: float) -> void:
	update()
