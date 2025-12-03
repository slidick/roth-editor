extends BaseWindow

signal done

var item: Dictionary = {}
var text_entry: Dictionary = {}
var palette_index: int = -1


func edit_item_with_text_entry(p_item: Dictionary, p_references: Array = []) -> void:
	item = p_item
	if len(p_references) > 1:
		%MakeUniqueButton.show()
	if len(p_references) > 0:
		%SelectButton.show()
	await edit_text_entry(item.text_entry, p_references)
	%MakeUniqueButton.hide()
	%SelectButton.hide()
	item = {}


func edit_text_entry(p_text_entry: Dictionary, p_references: Array = []) -> void:
	text_entry = p_text_entry
	palette_index = p_text_entry.font_color if "font_color" in p_text_entry else 0
	var palette: Array = Das.get_default_palette()
	%ColorRect.color = Color(palette[palette_index][0] / float(255), palette[palette_index][1] / float(255), palette[palette_index][2] / float(255))
	%TextEdit.text = p_text_entry.string if "string" in p_text_entry else ""
	
	%ReferencesList.clear()
	if p_references.is_empty():
		%ReferencesContainer.hide()
	else:
		%ReferencesContainer.show()
	for reference: Dictionary in p_references:
		if "sub_index" in reference:
			%ReferencesList.add_item("%s: %d:%d" % [reference.type, reference.index, reference.sub_index])
		else:
			%ReferencesList.add_item("%s: %d" % [reference.type, reference.index])
		%ReferencesList.set_item_metadata(%ReferencesList.item_count-1, reference)
	
	if "dbase500" not in text_entry or text_entry.dbase500.is_empty():
		text_entry["dbase500"] = {}
		%EmptyLabel.show()
	else:
		%EmptyLabel.hide()
	
	toggle(true)
	await done
	Roth.stop_audio_buffer()
	toggle(false)


func _on_color_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var palette: Array = Das.get_default_palette()
		%PaletteWindow.show_palette(palette)
		var color: int = await %PaletteWindow.color_selected
		if color == -1:
			return
		palette_index = color
		%ColorRect.color = Color(palette[palette_index][0] / float(255), palette[palette_index][1] / float(255), palette[palette_index][2] / float(255))


func _fade_out() -> void:
	super._fade_out()
	done.emit()


func _on_save_button_pressed() -> void:
	text_entry.font_color = palette_index
	text_entry.string = %TextEdit.text
	done.emit()


func _on_text_edit_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		_on_save_button_pressed()
		get_viewport().set_input_as_handled()


func _on_clear_button_pressed() -> void:
	text_entry.clear()
	done.emit()


func _on_play_audio_button_pressed() -> void:
	if not text_entry.dbase500.is_empty():
		Roth.play_audio_entry(FXScript.convert_to_playable_entry(text_entry.dbase500.duplicate(true)))


func _on_edit_audio_button_pressed() -> void:
	if not text_entry.dbase500.is_empty():
		pass
	if "string" in text_entry:
		text_entry.dbase500.string = text_entry.string
	else:
		text_entry.dbase500.string = "(Empty)"
	var new_dbase500_entry: Dictionary = await %AudioClipEditor.edit_audio(text_entry.dbase500)
	if not new_dbase500_entry.is_empty():
		text_entry.dbase500 = new_dbase500_entry
		%EmptyLabel.hide()
		owner.audio_changed = true


func _on_references_list_item_activated(_index: int) -> void:
	jump_to()


func jump_to() -> void:
	done.emit()
	owner.jump_to_reference(%ReferencesList.get_item_metadata(%ReferencesList.get_selected_items()[0]))


func _on_select_button_pressed() -> void:
	if item.is_empty():
		return
	var new_text_entry: Dictionary = await %TextSelection.make_selection(owner.dbase_data)
	if new_text_entry.is_empty():
		return
	item.text_entry = new_text_entry
	text_entry = item.text_entry
	update_references(item.text_entry)
	done.emit()


func _on_make_unique_button_pressed() -> void:
	if item.is_empty():
		return
	item.text_entry = text_entry.duplicate(true)
	text_entry = item.text_entry
	update_references(item.text_entry)


func update_references(p_text_entry: Dictionary) -> void:
	var references: Array = owner.get_text_entry_references(p_text_entry)
	%ReferencesList.clear()
	for reference: Dictionary in references:
		if "sub_index" in reference:
			%ReferencesList.add_item("%s: %d:%d" % [reference.type, reference.index, reference.sub_index])
		else:
			%ReferencesList.add_item("%s: %d" % [reference.type, reference.index])
		%ReferencesList.set_item_metadata(%ReferencesList.item_count-1, reference)


func _on_clear_audio_button_pressed() -> void:
	if await Dialog.confirm("Are you sure?", "Confirm Clear Audio", false, Vector2(400,140)):
		text_entry.dbase500 = {}
		%EmptyLabel.show()


func _on_stop_audio_button_pressed() -> void:
	Roth.stop_audio_buffer()


func select_sfx() -> Dictionary:
	return await %TextSelection.make_selection(owner.dbase_data, true)
