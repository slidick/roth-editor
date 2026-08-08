extends BaseWindow

signal done(new_palette: Array)


func edit_8bit_palette(p_8bit_raw_palette: Array) -> Array:
	var editable_palette: Array = []
	for i in range(0, len(p_8bit_raw_palette), 3):
		editable_palette.append([p_8bit_raw_palette[i], p_8bit_raw_palette[i+1], p_8bit_raw_palette[i+2]])
	%Palette.load_8bit_palette(editable_palette)
	toggle(true)
	var palette: Array = await done
	toggle(false)
	return palette


func _on_cancel_button_pressed() -> void:
	done.emit([])
	toggle(false)


func _on_save_button_pressed() -> void:
	var new_palette: Array = []
	for each: Array in %Palette.das.palette:
		new_palette.append_array(each)
	done.emit(new_palette)
