extends BaseWindow


@onready var _things_to_save : Dictionary = {
	"3d_paste_options": {
		"lower_texture": {"node": %LowerTextureButton, "value": %LowerTextureButton.button_pressed},
		"mid_texture": {"node": %MidTextureButton, "value": %MidTextureButton.button_pressed},
		"upper_texture": {"node": %UpperTextureButton, "value": %UpperTextureButton.button_pressed},
		"texture_x_shift": {"node": %TextureXShiftButton, "value": %TextureXShiftButton.button_pressed},
		"texture_y_shift": {"node": %TextureYShiftButton, "value": %TextureYShiftButton.button_pressed},
		"face_texture_flags": {"node": %FaceTextureFlagsButton, "value": %FaceTextureFlagsButton.button_pressed},
		"face_flags": {"node": %FaceFlagsButton, "value": %FaceFlagsButton.button_pressed},
		"face_id": {"node": %FaceIDButton, "value": %FaceIDButton.button_pressed},
		
		"floor_texture": {"node": %FloorTextureButton, "value": %FloorTextureButton.button_pressed},
		"floor_x_shift": {"node": %FloorXShiftButton, "value": %FloorXShiftButton.button_pressed},
		"floor_y_shift": {"node": %FloorYShiftButton, "value": %FloorYShiftButton.button_pressed},
		"floor_height": {"node": %FloorHeightButton, "value": %FloorHeightButton.button_pressed},
		"ceiling_texture": {"node": %CeilingTextureButton, "value": %CeilingTextureButton.button_pressed},
		"ceiling_x_shift": {"node": %CeilingXShiftButton, "value": %CeilingXShiftButton.button_pressed},
		"ceiling_y_shift": {"node": %CeilingYShiftButton, "value": %CeilingYShiftButton.button_pressed},
		"ceiling_height": {"node": %CeilingHeightButton, "value": %CeilingHeightButton.button_pressed},
		"sector_flip": {"node": %SectorFlipButton, "value": %SectorFlipButton.button_pressed},
		"sector_flags": {"node": %SectorFlagsButton, "value": %SectorFlagsButton.button_pressed},
		"glow": {"node": %GlowButton, "value": %GlowButton.button_pressed},
		"texture_height_override": {"node": %TextureHeightOverrideButton, "value": %TextureHeightOverrideButton.button_pressed},
		"sector_id": {"node": %SectorIDButton, "value": %SectorIDButton.button_pressed},
		"platform": {"node": %PlatformButton, "value": %PlatformButton.button_pressed},
	},
}


func _ready() -> void:
	super._ready()
	%WindowTitle.text = "3D View Paste Options"
	_reset()


func _reset() -> void:
	for outer_key: String in _things_to_save:
		var settings: Variant = Settings.settings.get(outer_key)
		if settings:
			for key: String in settings as Dictionary:
				if key in _things_to_save[outer_key]:
					_handle_node_reset(_things_to_save[outer_key][key].node, settings[key])
					_things_to_save[outer_key][key].value = settings[key]
		else:
			var save_data: Dictionary = {}
			for key: String in _things_to_save[outer_key]:
				_handle_node_reset(_things_to_save[outer_key][key].node, _things_to_save[outer_key][key].value)
				save_data[key] = _things_to_save[outer_key][key].value
			Settings.update_settings(outer_key, save_data)


func _save() -> void:
	for outer_key: String in _things_to_save:
		var save_data: Dictionary = {}
		for key: String in _things_to_save[outer_key]:
			_handle_node_save(_things_to_save[outer_key][key])
			save_data[key] = _things_to_save[outer_key][key].value
		Settings.update_settings(outer_key, save_data)


func _handle_node_reset(node: Control, value: Variant) -> void:
	if node is LineEdit:
		node.text = value
	if (node is CheckBox or
			node is CheckButton):
		node.button_pressed = value
	if node is OptionButton:
		for i in range(node.item_count):
			if node.get_item_text(i).to_lower() == value.to_lower():
				node.selected = i


func _handle_node_save(node_data: Dictionary) -> void:
	if node_data.node is LineEdit:
		node_data.value = node_data.node.text
	if (node_data.node is CheckBox or
			node_data.node is CheckButton):
		node_data.value = node_data.node.button_pressed
	if node_data.node is OptionButton:
		node_data.value = node_data.node.text.to_lower()


func _on_cancel_button_pressed() -> void:
	_reset()
	toggle(false)


func _on_paste_button_pressed() -> void:
	_save()
	toggle(false)
