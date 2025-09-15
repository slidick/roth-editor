extends BaseWindow

signal selection_done(text_entry: Dictionary)

func make_selection(dbase_data: Dictionary) -> Dictionary:
	%Text.load_dbase(dbase_data, true)
	toggle(true)
	var text_entry: Dictionary = await selection_done
	toggle(false)
	return text_entry


func _fade_out() -> void:
	if _tween and _tween.is_running():
		await _tween.finished
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0, 0.2)
	if exclusive:
		_tween.tween_property(%Background, "visible", false, 0)
	_tween.tween_callback(self.hide)
	window_shown.emit(false)
	await _tween.finished
	selection_done.emit({})


func _on_text_text_entry_selected(text_entry: Dictionary) -> void:
	selection_done.emit(text_entry)
