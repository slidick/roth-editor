extends MarginContainer

var last_selection_length: int = -1


func clear() -> void:
	%SFXPosXEdit.get_line_edit().clear()
	%SFXPosYEdit.get_line_edit().clear()
	%SFXSoundIndexEdit.get_line_edit().clear()
	%SFXUnk0x06Edit.get_line_edit().clear()
	%SFXUnk0x08Edit.get_line_edit().clear()
	%SFXUnk0x0AEdit.get_line_edit().clear()
	%SFXUnk0x0CEdit.get_line_edit().clear()
	%SFXUnk0x0EEdit.get_line_edit().clear()
	%SFXUnk0x10Edit.get_line_edit().clear()
	%EditSFXContainer.hide()
	last_selection_length = 0


func update_selections() -> void:
	clear()
	if len(owner.selected_sfx) == 0:
		return
	
	%EditSFXContainer.show()
	last_selection_length = len(owner.selected_sfx)
	var sfx: Section7_1 = owner.selected_sfx[0]
	
	if len(owner.selected_sfx) == 1:
		pass
	elif len(owner.selected_sfx) > 1:
		pass
	
	%SFXIndexLabel.text = "SFX: %d" % sfx.index
	%SFXPosXEdit.get_line_edit().text = "%d" % sfx.data.unk0x00
	%SFXPosXEdit.set_value_no_signal(sfx.data.unk0x00)
	%SFXPosYEdit.get_line_edit().text = "%d" % sfx.data.unk0x02
	%SFXPosYEdit.set_value_no_signal(sfx.data.unk0x02)
	%SFXSoundIndexEdit.get_line_edit().text = "%d" % sfx.data.unk0x04
	%SFXSoundIndexEdit.set_value_no_signal(sfx.data.unk0x04)
	%SFXUnk0x06Edit.get_line_edit().text = "%d" % sfx.data.unk0x06
	%SFXUnk0x06Edit.set_value_no_signal(sfx.data.unk0x06)
	%SFXUnk0x08Edit.get_line_edit().text = "%d" % sfx.data.unk0x08
	%SFXUnk0x08Edit.set_value_no_signal(sfx.data.unk0x08)
	%SFXUnk0x0AEdit.get_line_edit().text = "%d" % sfx.data.unk0x0A
	%SFXUnk0x0AEdit.set_value_no_signal(sfx.data.unk0x0A)
	%SFXUnk0x0CEdit.get_line_edit().text = "%d" % sfx.data.unk0x0C
	%SFXUnk0x0CEdit.set_value_no_signal(sfx.data.unk0x0C)
	%SFXUnk0x0EEdit.get_line_edit().text = "%d" % sfx.data.unk0x0E
	%SFXUnk0x0EEdit.set_value_no_signal(sfx.data.unk0x0E)
	%SFXUnk0x10Edit.get_line_edit().text = "%d" % sfx.data.unk0x10
	%SFXUnk0x10Edit.set_value_no_signal(sfx.data.unk0x10)


func _on_sfx_pos_x_edit_value_changed(value: float) -> void:
	for sfx: Section7_1 in owner.selected_sfx:
		sfx.data.unk0x00 = value
	owner.redraw(owner.selected_sfx)
	%EditSFXTimer.start()


func _on_sfx_pos_y_edit_value_changed(value: float) -> void:
	for sfx: Section7_1 in owner.selected_sfx:
		sfx.data.unk0x02 = value
	owner.redraw(owner.selected_sfx)
	%EditSFXTimer.start()


func _on_sfx_sound_index_edit_value_changed(value: float) -> void:
	for sfx: Section7_1 in owner.selected_sfx:
		sfx.data.unk0x04 = value
	%EditSFXTimer.start()


func _on_sfx_unk_0x_06_edit_value_changed(value: float) -> void:
	for sfx: Section7_1 in owner.selected_sfx:
		sfx.data.unk0x06 = value
	%EditSFXTimer.start()


func _on_sfx_unk_0x_08_edit_value_changed(value: float) -> void:
	for sfx: Section7_1 in owner.selected_sfx:
		sfx.data.unk0x08 = value
	%EditSFXTimer.start()


func _on_sfx_unk_0x_0a_edit_value_changed(value: float) -> void:
	for sfx: Section7_1 in owner.selected_sfx:
		sfx.data.unk0x0A = value
	%EditSFXTimer.start()


func _on_sfx_unk_0x_0c_edit_value_changed(value: float) -> void:
	for sfx: Section7_1 in owner.selected_sfx:
		sfx.data.unk0x0C = value
	%EditSFXTimer.start()


func _on_sfx_unk_0x_0e_edit_value_changed(value: float) -> void:
	for sfx: Section7_1 in owner.selected_sfx:
		sfx.data.unk0x0E = value
	%EditSFXTimer.start()


func _on_sfx_unk_0x_10_edit_value_changed(value: float) -> void:
	for sfx: Section7_1 in owner.selected_sfx:
		sfx.data.unk0x10 = value
	%EditSFXTimer.start()


func _on_edit_sfx_timer_timeout() -> void:
	if last_selection_length == 1:
		Roth.editor_action.emit(owner.selected_sfx[0].map_info, "Edit SFX")
	elif last_selection_length > 1:
		Roth.editor_action.emit(owner.selected_sfx[0].map_info, "Edit SFXs")


func _on_sfx_play_button_pressed() -> void:
	var data := FXScript.get_from_index(%SFXSoundIndexEdit.value)
	Roth.play_audio_entry(data)
