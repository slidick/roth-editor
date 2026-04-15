extends BaseWindow

signal done(data: Dictionary)
signal changed(data: Dictionary)

var image_data: Dictionary = {}
var original_width: int = -1
var original_height: int = -1
var locked_width: int = -1
var locked_height: int = -1
var locked_width_percent: float = 0.0
var locked_height_percent: float = 0.0


func scale_image(p_image_data: Dictionary, is_rotated: bool) -> Dictionary:
	image_data = p_image_data
	if is_rotated:
		original_width = image_data.height
		original_height = image_data.width
	else:
		original_width = image_data.width
		original_height = image_data.height
	
	locked_width = original_width
	locked_height = original_height
	%ScaleWidthPixelSpinBox.set_value_no_signal(original_width)
	%ScaleWidthPixelSpinBox.get_line_edit().text = str(original_width)
	%ScaleWidthPixelSpinBox.max_value = int(65536.0 / original_height)
	%ScaleHeightPixelSpinBox.set_value_no_signal(original_height)
	%ScaleHeightPixelSpinBox.get_line_edit().text = str(original_height)
	%ScaleHeightPixelSpinBox.max_value = int(65536.0 / original_width)
	%ScaleWidthPercentSpinBox.set_value_no_signal(100)
	%ScaleWidthPercentSpinBox.get_line_edit().text = str(100)
	%ScaleWidthPercentSpinBox.max_value = 65536.0 / original_height / original_width * 100
	%ScaleHeightPercentSpinBox.set_value_no_signal(100)
	%ScaleHeightPercentSpinBox.get_line_edit().text = str(100)
	%ScaleHeightPercentSpinBox.max_value = 65536.0 / original_width / original_height * 100
	toggle(true)
	var data: Dictionary = await done
	toggle(false)
	return data


func update() -> void:
	if %ShowPreview.button_pressed:
		changed.emit({
			"width": int(%ScaleWidthPixelSpinBox.value),
			"height": int(%ScaleHeightPixelSpinBox.value),
		})


func _on_cancel_button_pressed() -> void:
	done.emit({})


func _on_confirm_button_pressed() -> void:
	done.emit({
		"width": %ScaleWidthPixelSpinBox.value,
		"height": %ScaleHeightPixelSpinBox.value,
	})


func _on_scale_width_pixel_spin_box_value_changed(value: float) -> void:
	%ScaleWidthPercentSpinBox.set_value_no_signal(value/original_width * 100)
	%ScaleHeightPixelSpinBox.max_value = int(65536 / value)
	%ScaleHeightPercentSpinBox.max_value = 65536 / value / original_height * 100
	if %KeepAspectRatioCheckBox.button_pressed:
		var percent_change: float = value / locked_width
		%ScaleHeightPercentSpinBox.set_value_no_signal((percent_change * locked_height) / original_height * 100)
		%ScaleHeightPixelSpinBox.set_value_no_signal(percent_change * locked_height)
	update()


func _on_scale_height_pixel_spin_box_value_changed(value: float) -> void:
	%ScaleHeightPercentSpinBox.set_value_no_signal(value/original_height * 100)
	%ScaleWidthPixelSpinBox.max_value = int(65536 / value)
	%ScaleWidthPercentSpinBox.max_value = 65536 / value / original_width * 100
	if %KeepAspectRatioCheckBox.button_pressed:
		var percent_change: float = value / locked_height
		%ScaleWidthPercentSpinBox.set_value_no_signal((percent_change * locked_width) / original_width * 100)
		%ScaleWidthPixelSpinBox.set_value_no_signal(percent_change * locked_width)
	update()


func _on_scale_width_percent_spin_box_value_changed(value: float) -> void:
	%ScaleWidthPixelSpinBox.set_value_no_signal(original_width * value / 100.0)
	%ScaleHeightPercentSpinBox.max_value = 65536.0 / (original_width * value / 100.0) / original_height * 100
	if %KeepAspectRatioCheckBox.button_pressed:
		var percent_change: float = value / locked_width_percent
		%ScaleHeightPercentSpinBox.set_value_no_signal(percent_change * locked_height_percent)
		%ScaleHeightPixelSpinBox.set_value_no_signal(original_height * percent_change * locked_height_percent / 100.0)
		%ScaleWidthPercentSpinBox.max_value = 65536.0 / (original_height * percent_change * locked_height_percent / 100.0) / original_width * 100
	update()


func _on_scale_height_percent_spin_box_value_changed(value: float) -> void:
	%ScaleHeightPixelSpinBox.set_value_no_signal(original_height * value / 100.0)
	%ScaleWidthPercentSpinBox.max_value = 65536.0 / (original_height * value / 100.0) / original_width * 100
	if %KeepAspectRatioCheckBox.button_pressed:
		var percent_change: float = value / locked_height_percent
		%ScaleWidthPercentSpinBox.set_value_no_signal(percent_change * locked_width_percent)
		%ScaleWidthPixelSpinBox.set_value_no_signal(original_width * percent_change * locked_width_percent / 100.0)
		%ScaleHeightPercentSpinBox.max_value = 65536.0 / (original_width * percent_change * locked_width_percent / 100.0) / original_height * 100
	update()


func _on_keep_aspect_ratio_check_box_pressed() -> void:
	locked_width = %ScaleWidthPixelSpinBox.value
	locked_height = %ScaleHeightPixelSpinBox.value
	locked_width_percent = %ScaleWidthPercentSpinBox.value
	locked_height_percent = %ScaleHeightPercentSpinBox.value


func _on_show_preview_toggled(toggled_on: bool) -> void:
	if toggled_on:
		update()
	else:
		changed.emit({
			"width": original_width,
			"height": original_height,
		})
