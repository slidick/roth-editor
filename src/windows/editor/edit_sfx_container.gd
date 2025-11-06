extends MarginContainer

var current_object: Section7_1 :
	set(value):
		if not %EditSFXTimer.is_stopped():
			%EditSFXTimer.stop()
			%EditSFXTimer.timeout.emit()
		current_object = value

func _redraw_object(node: Variant = null) -> void:
	var caret: int = 0
	if node:
		caret = node.get_line_edit().caret_column
	current_object.initialize_mesh()
	await get_tree().process_frame
	%Picker.select(current_object.node)
	%Map2D.redraw_sfx(current_object)
	if node:
		node.get_line_edit().grab_focus()
		await get_tree().process_frame
		node.get_line_edit().caret_column = caret


func _reset_edit_sfx() -> void:
	%SFXPosXEdit.get_line_edit().clear()
	%SFXPosYEdit.get_line_edit().clear()
	%SFXSoundIndexEdit.get_line_edit().clear()
	%SFXUnk0x06Edit.get_line_edit().clear()
	%SFXUnk0x08Edit.get_line_edit().clear()
	%SFXUnk0x0AEdit.get_line_edit().clear()
	%SFXUnk0x0CEdit.get_line_edit().clear()
	%SFXUnk0x0EEdit.get_line_edit().clear()
	%SFXUnk0x10Edit.get_line_edit().clear()
	%EditSFXContainer.show()


func load_edit_sfx(sfx: Section7_1.SFXMesh3D) -> void:
	_reset_edit_sfx()
	current_object = sfx.ref
	%SFXIndexLabel.text = "SFX: %d" % sfx.ref.index
	%SFXPosXEdit.get_line_edit().text = "%d" % sfx.ref.data.unk0x00
	%SFXPosXEdit.set_value_no_signal(sfx.ref.data.unk0x00)
	%SFXPosYEdit.get_line_edit().text = "%d" % sfx.ref.data.unk0x02
	%SFXPosYEdit.set_value_no_signal(sfx.ref.data.unk0x02)
	%SFXSoundIndexEdit.get_line_edit().text = "%d" % sfx.ref.data.unk0x04
	%SFXSoundIndexEdit.set_value_no_signal(sfx.ref.data.unk0x04)
	%SFXUnk0x06Edit.get_line_edit().text = "%d" % sfx.ref.data.unk0x06
	%SFXUnk0x06Edit.set_value_no_signal(sfx.ref.data.unk0x06)
	%SFXUnk0x08Edit.get_line_edit().text = "%d" % sfx.ref.data.unk0x08
	%SFXUnk0x08Edit.set_value_no_signal(sfx.ref.data.unk0x08)
	%SFXUnk0x0AEdit.get_line_edit().text = "%d" % sfx.ref.data.unk0x0A
	%SFXUnk0x0AEdit.set_value_no_signal(sfx.ref.data.unk0x0A)
	%SFXUnk0x0CEdit.get_line_edit().text = "%d" % sfx.ref.data.unk0x0C
	%SFXUnk0x0CEdit.set_value_no_signal(sfx.ref.data.unk0x0C)
	%SFXUnk0x0EEdit.get_line_edit().text = "%d" % sfx.ref.data.unk0x0E
	%SFXUnk0x0EEdit.set_value_no_signal(sfx.ref.data.unk0x0E)
	%SFXUnk0x10Edit.get_line_edit().text = "%d" % sfx.ref.data.unk0x10
	%SFXUnk0x10Edit.set_value_no_signal(sfx.ref.data.unk0x10)


func _on_sfx_pos_x_edit_value_changed(value: float) -> void:
	current_object.data.unk0x00 = value
	_redraw_object(%SFXPosXEdit)
	%EditSFXTimer.start()


func _on_sfx_pos_y_edit_value_changed(value: float) -> void:
	current_object.data.unk0x02 = value
	_redraw_object(%SFXPosYEdit)
	%EditSFXTimer.start()


func _on_sfx_sound_index_edit_value_changed(value: float) -> void:
	current_object.data.unk0x04 = value
	%EditSFXTimer.start()


func _on_sfx_unk_0x_06_edit_value_changed(value: float) -> void:
	current_object.data.unk0x06 = value
	%EditSFXTimer.start()


func _on_sfx_unk_0x_08_edit_value_changed(value: float) -> void:
	current_object.data.unk0x08 = value
	%EditSFXTimer.start()


func _on_sfx_unk_0x_0a_edit_value_changed(value: float) -> void:
	current_object.data.unk0x0A = value
	%EditSFXTimer.start()


func _on_sfx_unk_0x_0c_edit_value_changed(value: float) -> void:
	current_object.data.unk0x0C = value
	%EditSFXTimer.start()


func _on_sfx_unk_0x_0e_edit_value_changed(value: float) -> void:
	current_object.data.unk0x0E = value
	%EditSFXTimer.start()


func _on_sfx_unk_0x_10_edit_value_changed(value: float) -> void:
	current_object.data.unk0x10 = value
	%EditSFXTimer.start()


func _on_edit_sfx_timer_timeout() -> void:
	if current_object:
		Roth.editor_action.emit(current_object.map_info, "Edit SFX")
