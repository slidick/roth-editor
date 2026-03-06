extends MarginContainer

var last_selection_length: int = -1


func clear() -> void:
	%SFXPosXEdit.get_line_edit().clear()
	%SFXPosYEdit.get_line_edit().clear()
	%SFXSoundIndexEdit.get_line_edit().clear()
	%SFXUnk0x06Edit.get_line_edit().clear()
	%SFXUnk0x08Edit.get_line_edit().clear()
	%SFXZoneIndexEdit.get_line_edit().clear()
	%SFXUnk0x0AEdit.get_line_edit().clear()
	%SFXUnk0x0CEdit.get_line_edit().clear()
	%SFXUnk0x0EEdit.get_line_edit().clear()
	%SFXVolumeEdit.get_line_edit().clear()
	%SFXUnk0x11Edit.get_line_edit().clear()
	%SFXPlayButton.show()
	%EditSFXContainer.hide()
	%SFXFlag1CheckBox.set_pressed_no_signal(false)
	%SFXFlag2CheckBox.set_pressed_no_signal(false)
	%SFXFlag3CheckBox.set_pressed_no_signal(false)
	%SFXFlag4CheckBox.set_pressed_no_signal(false)
	%SFXFlag5CheckBox.set_pressed_no_signal(false)
	%SFXFlag6CheckBox.set_pressed_no_signal(false)
	%SFXFlag7CheckBox.set_pressed_no_signal(false)
	%SFXFlag8CheckBox.set_pressed_no_signal(false)
	%SFXFlag1CheckBox.indeterminate = false
	%SFXFlag2CheckBox.indeterminate = false
	%SFXFlag3CheckBox.indeterminate = false
	%SFXFlag4CheckBox.indeterminate = false
	%SFXFlag5CheckBox.indeterminate = false
	%SFXFlag6CheckBox.indeterminate = false
	%SFXFlag7CheckBox.indeterminate = false
	%SFXFlag8CheckBox.indeterminate = false
	last_selection_length = 0


func update_selections() -> void:
	clear()
	if len(owner.selected_sfx) == 0:
		return
	
	%EditSFXContainer.show()
	last_selection_length = len(owner.selected_sfx)
	var sfx: SFX = owner.selected_sfx[0]
	
	if len(owner.selected_sfx) == 1:
		%SFXIndexLabel.text = "SFX: %d" % sfx.index
		
	elif len(owner.selected_sfx) > 1:
		%SFXIndexLabel.text = "SFX: %d Selected" % len(owner.selected_sfx)
	
	%SFXPosXEdit.get_line_edit().text = "%d" % -sfx.data.unk0x00
	%SFXPosXEdit.set_value_no_signal(-sfx.data.unk0x00)
	%SFXPosYEdit.get_line_edit().text = "%d" % sfx.data.unk0x02
	%SFXPosYEdit.set_value_no_signal(sfx.data.unk0x02)
	%SFXSoundIndexEdit.get_line_edit().text = "%d" % (sfx.data.unk0x04+1)
	%SFXSoundIndexEdit.set_value_no_signal(sfx.data.unk0x04+1)
	%SFXUnk0x06Edit.get_line_edit().text = "%d" % sfx.data.unk0x06
	%SFXUnk0x06Edit.set_value_no_signal(sfx.data.unk0x06)
	%SFXUnk0x08Edit.get_line_edit().text = "%d" % sfx.data.unk0x08
	%SFXUnk0x08Edit.set_value_no_signal(sfx.data.unk0x08)
	%SFXZoneIndexEdit.get_line_edit().text = "%d" % sfx.data.zoneIndex
	%SFXZoneIndexEdit.set_value_no_signal(sfx.data.zoneIndex)
	%SFXUnk0x0AEdit.get_line_edit().text = "%d" % sfx.data.unk0x0A
	%SFXUnk0x0AEdit.set_value_no_signal(sfx.data.unk0x0A)
	%SFXUnk0x0CEdit.get_line_edit().text = "%d" % sfx.data.unk0x0C
	%SFXUnk0x0CEdit.set_value_no_signal(sfx.data.unk0x0C)
	%SFXUnk0x0EEdit.get_line_edit().text = "%d" % sfx.data.unk0x0E
	%SFXUnk0x0EEdit.set_value_no_signal(sfx.data.unk0x0E)
	%SFXVolumeEdit.get_line_edit().text = "%d" % sfx.data.volume
	%SFXVolumeEdit.set_value_no_signal(sfx.data.volume)
	%SFXUnk0x11Edit.get_line_edit().text = "%d" % sfx.data.unk0x11
	%SFXUnk0x11Edit.set_value_no_signal(sfx.data.unk0x11)
	%SFXFlag1CheckBox.set_pressed_no_signal((sfx.data.unk0x08 & (1<<0)) > 0)
	%SFXFlag2CheckBox.set_pressed_no_signal((sfx.data.unk0x08 & (1<<1)) > 0)
	%SFXFlag3CheckBox.set_pressed_no_signal((sfx.data.unk0x08 & (1<<2)) > 0)
	%SFXFlag4CheckBox.set_pressed_no_signal((sfx.data.unk0x08 & (1<<3)) > 0)
	%SFXFlag5CheckBox.set_pressed_no_signal((sfx.data.unk0x08 & (1<<4)) > 0)
	%SFXFlag6CheckBox.set_pressed_no_signal((sfx.data.unk0x08 & (1<<5)) > 0)
	%SFXFlag7CheckBox.set_pressed_no_signal((sfx.data.unk0x08 & (1<<6)) > 0)
	%SFXFlag8CheckBox.set_pressed_no_signal((sfx.data.unk0x08 & (1<<7)) > 0)
	
	for each_sfx: SFX in owner.selected_sfx:
		if each_sfx.data.unk0x00 != sfx.data.unk0x00:
			%SFXPosXEdit.get_line_edit().clear.call_deferred()
		if each_sfx.data.unk0x02 != sfx.data.unk0x02:
			%SFXPosYEdit.get_line_edit().clear.call_deferred()
		if each_sfx.data.unk0x04 != sfx.data.unk0x04:
			%SFXSoundIndexEdit.get_line_edit().clear.call_deferred()
			%SFXPlayButton.hide()
		if each_sfx.data.unk0x06 != sfx.data.unk0x06:
			%SFXUnk0x06Edit.get_line_edit().clear.call_deferred()
		if each_sfx.data.unk0x08 != sfx.data.unk0x08:
			%SFXUnk0x08Edit.get_line_edit().clear.call_deferred()
		if each_sfx.data.zoneIndex != sfx.data.zoneIndex:
			%SFXZoneIndexEdit.get_line_edit().clear.call_deferred()
		if each_sfx.data.unk0x0A != sfx.data.unk0x0A:
			%SFXUnk0x0AEdit.get_line_edit().clear.call_deferred()
		if each_sfx.data.unk0x0C != sfx.data.unk0x0C:
			%SFXUnk0x0CEdit.get_line_edit().clear.call_deferred()
		if each_sfx.data.unk0x0E != sfx.data.unk0x0E:
			%SFXUnk0x0EEdit.get_line_edit().clear.call_deferred()
		if each_sfx.data.volume != sfx.data.volume:
			%SFXVolumeEdit.get_line_edit().clear.call_deferred()
		if each_sfx.data.unk0x11 != sfx.data.unk0x11:
			%SFXUnk0x11Edit.get_line_edit().clear.call_deferred()
		if ((each_sfx.data.unk0x08 & (1<<0)) > 0) != ((sfx.data.unk0x08 & (1<<0)) > 0):
			%SFXFlag1CheckBox.indeterminate = true
		if ((each_sfx.data.unk0x08 & (1<<1)) > 0) != ((sfx.data.unk0x08 & (1<<1)) > 0):
			%SFXFlag2CheckBox.indeterminate = true
		if ((each_sfx.data.unk0x08 & (1<<2)) > 0) != ((sfx.data.unk0x08 & (1<<2)) > 0):
			%SFXFlag3CheckBox.indeterminate = true
		if ((each_sfx.data.unk0x08 & (1<<3)) > 0) != ((sfx.data.unk0x08 & (1<<3)) > 0):
			%SFXFlag4CheckBox.indeterminate = true
		if ((each_sfx.data.unk0x08 & (1<<4)) > 0) != ((sfx.data.unk0x08 & (1<<4)) > 0):
			%SFXFlag5CheckBox.indeterminate = true
		if ((each_sfx.data.unk0x08 & (1<<5)) > 0) != ((sfx.data.unk0x08 & (1<<5)) > 0):
			%SFXFlag6CheckBox.indeterminate = true
		if ((each_sfx.data.unk0x08 & (1<<6)) > 0) != ((sfx.data.unk0x08 & (1<<6)) > 0):
			%SFXFlag7CheckBox.indeterminate = true
		if ((each_sfx.data.unk0x08 & (1<<7)) > 0) != ((sfx.data.unk0x08 & (1<<7)) > 0):
			%SFXFlag8CheckBox.indeterminate = true


func _on_sfx_pos_x_edit_value_changed(value: float) -> void:
	for sfx: SFX in owner.selected_sfx:
		sfx.data.unk0x00 = -value
	owner.redraw(owner.selected_sfx)
	%EditSFXTimer.start()


func _on_sfx_pos_y_edit_value_changed(value: float) -> void:
	for sfx: SFX in owner.selected_sfx:
		sfx.data.unk0x02 = value
	owner.redraw(owner.selected_sfx)
	%EditSFXTimer.start()

  
func _on_sfx_sound_index_edit_value_changed(value: float) -> void:
	for sfx: SFX in owner.selected_sfx:
		sfx.data.unk0x04 = (value-1)
	%SFXPlayButton.show()
	%EditSFXTimer.start()


func _on_sfx_unk_0x_06_edit_value_changed(value: float) -> void:
	for sfx: SFX in owner.selected_sfx:
		sfx.data.unk0x06 = value
	%EditSFXTimer.start()


func _on_sfx_unk_0x_08_edit_value_changed(value: float) -> void:
	for sfx: SFX in owner.selected_sfx:
		sfx.data.unk0x08 = value
	%EditSFXTimer.start()


func _on_sfx_zone_index_edit_value_changed(value: float) -> void:
	for sfx: SFX in owner.selected_sfx:
		sfx.data.zoneIndex = value
	owner.redraw(owner.selected_sfx)
	%EditSFXTimer.start()


func _on_sfx_unk_0x_0a_edit_value_changed(value: float) -> void:
	for sfx: SFX in owner.selected_sfx:
		sfx.data.unk0x0A = value
	owner.redraw(owner.selected_sfx)
	%EditSFXTimer.start()


func _on_sfx_unk_0x_0c_edit_value_changed(value: float) -> void:
	for sfx: SFX in owner.selected_sfx:
		sfx.data.unk0x0C = value
	%EditSFXTimer.start()


func _on_sfx_unk_0x_0e_edit_value_changed(value: float) -> void:
	for sfx: SFX in owner.selected_sfx:
		sfx.data.unk0x0E = value
	%EditSFXTimer.start()


func _on_sfx_volume_edit_value_changed(value: float) -> void:
	for sfx: SFX in owner.selected_sfx:
		sfx.data.volume = value
	%EditSFXTimer.start()


func _on_sfx_unk_0x_11_edit_value_changed(value: float) -> void:
	for sfx: SFX in owner.selected_sfx:
		sfx.data.unk0x11 = value
	%EditSFXTimer.start()


func _on_edit_sfx_timer_timeout() -> void:
	if last_selection_length == 1:
		Roth.editor_action.emit(owner.selected_sfx[0].map_info, "Edit SFX")
	elif last_selection_length > 1:
		Roth.editor_action.emit(owner.selected_sfx[0].map_info, "Edit SFXs")


func _on_sfx_play_button_pressed() -> void:
	var data := FXScript.get_from_index(%SFXSoundIndexEdit.value-1)
	Roth.play_audio_entry(data)


func _on_select_sfx_button_pressed() -> void:
	var sfx_entry: Dictionary = await %SFXSelector.select_sfx()
	%SFXSoundIndexEdit.get_line_edit().text = "%d" % (sfx_entry.index)
	%SFXSoundIndexEdit.set_value_no_signal(sfx_entry.index)
	_on_sfx_sound_index_edit_value_changed(sfx_entry.index)


func _on_sfx_flag_1_check_box_toggled(toggled_on: bool) -> void:
	for sfx: SFX in owner.selected_sfx:
		if toggled_on:
			sfx.data.unk0x08 |= (1 << 0)
		else:
			sfx.data.unk0x08 &= ~(1 << 0)
	%EditSFXTimer.start()


func _on_sfx_flag_2_check_box_toggled(toggled_on: bool) -> void:
	for sfx: SFX in owner.selected_sfx:
		if toggled_on:
			sfx.data.unk0x08 |= (1 << 1)
		else:
			sfx.data.unk0x08 &= ~(1 << 1)
	%EditSFXTimer.start()


func _on_sfx_flag_3_check_box_toggled(toggled_on: bool) -> void:
	for sfx: SFX in owner.selected_sfx:
		if toggled_on:
			sfx.data.unk0x08 |= (1 << 2)
		else:
			sfx.data.unk0x08 &= ~(1 << 2)
	%EditSFXTimer.start()


func _on_sfx_flag_4_check_box_toggled(toggled_on: bool) -> void:
	for sfx: SFX in owner.selected_sfx:
		if toggled_on:
			sfx.data.unk0x08 |= (1 << 3)
		else:
			sfx.data.unk0x08 &= ~(1 << 3)
	%EditSFXTimer.start()


func _on_sfx_flag_5_check_box_toggled(toggled_on: bool) -> void:
	for sfx: SFX in owner.selected_sfx:
		if toggled_on:
			sfx.data.unk0x08 |= (1 << 4)
		else:
			sfx.data.unk0x08 &= ~(1 << 4)
	%EditSFXTimer.start()


func _on_sfx_flag_6_check_box_toggled(toggled_on: bool) -> void:
	for sfx: SFX in owner.selected_sfx:
		if toggled_on:
			sfx.data.unk0x08 |= (1 << 5)
		else:
			sfx.data.unk0x08 &= ~(1 << 5)
	%EditSFXTimer.start()


func _on_sfx_flag_7_check_box_toggled(toggled_on: bool) -> void:
	for sfx: SFX in owner.selected_sfx:
		if toggled_on:
			sfx.data.unk0x08 |= (1 << 6)
		else:
			sfx.data.unk0x08 &= ~(1 << 6)
	%EditSFXTimer.start()


func _on_sfx_flag_8_check_box_toggled(toggled_on: bool) -> void:
	for sfx: SFX in owner.selected_sfx:
		if toggled_on:
			sfx.data.unk0x08 |= (1 << 7)
		else:
			sfx.data.unk0x08 &= ~(1 << 7)
	%EditSFXTimer.start()
