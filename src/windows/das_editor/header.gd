extends Control

var das: Dictionary


func reset() -> void:
	das = {}
	for child: Node in get_children():
		child.queue_free()


func load_das(p_das: Dictionary) -> void:
	das = p_das
	
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	add_child(vbox)
	
	for key: String in das.header:
		var hbox := HBoxContainer.new()
		vbox.add_child(hbox)
		
		var label := Label.new()
		label.text = key
		label.custom_minimum_size.x = 450
		hbox.add_child(label)
		
		var line_edit := LineEdit.new()
		line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line_edit.text = str(das.header[key])
		if key == "unk_0x20":
			line_edit.text_changed.connect(func (new_text: String) -> void:
				das.header[key] = int(new_text)
			)
		else:
			line_edit.editable = false
		hbox.add_child(line_edit)
