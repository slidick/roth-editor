extends MarginContainer

@onready var _things: Dictionary = {
	"options": {
		"undo_history": { "node": %UndoHistorySpinBox, "value": %UndoHistorySpinBox.value },
		"backup_saves": { "node": %BackupSavesSpinBox, "value": %BackupSavesSpinBox.value },
	}
}


func _ready() -> void:
	NodeSave.reset(_things)
	var selection_highlight: int = Settings.settings.get("options", {}).get("selection_highlight", 0)
	match selection_highlight:
		0:
			%DefaultHighlightCheckBox.set_pressed_no_signal(true)
			%OutlineHighlightCheckBox.set_pressed_no_signal(false)
			%NoHighlightCheckBox.set_pressed_no_signal(false)
			Roth.selected_material = Roth.SELECTED_MATERIAL
			Roth.highlight_material = Roth.HIGHLIGHT_MATERIAL
			Roth.selected_fixed_y_material = Roth.SELECTED_FIXED_Y_MATERIAL
			Roth.highlight_fixed_y_material = Roth.HIGHLIGHT_FIXED_Y_MATERIAL
		1:
			%DefaultHighlightCheckBox.set_pressed_no_signal(false)
			%OutlineHighlightCheckBox.set_pressed_no_signal(true)
			%NoHighlightCheckBox.set_pressed_no_signal(false)
			Roth.selected_material = Roth.SELECTED_MATERIAL_OUTLINE
			Roth.highlight_material = Roth.HIGHLIGHT_MATERIAL_OUTLINE
			Roth.selected_fixed_y_material = Roth.SELECTED_FIXED_Y_MATERIAL
			Roth.highlight_fixed_y_material = Roth.HIGHLIGHT_FIXED_Y_MATERIAL
		2:
			%DefaultHighlightCheckBox.set_pressed_no_signal(false)
			%OutlineHighlightCheckBox.set_pressed_no_signal(false)
			%NoHighlightCheckBox.set_pressed_no_signal(true)
			Roth.selected_material = null
			Roth.highlight_material = null
			Roth.selected_fixed_y_material = null
			Roth.highlight_fixed_y_material = null


func _changed() -> void:
	NodeSave.save(_things)


func _on_default_highlight_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		Settings.update_settings("options", {"selection_highlight": 0})
		Roth.selected_material = Roth.SELECTED_MATERIAL
		Roth.highlight_material = Roth.HIGHLIGHT_MATERIAL
		Roth.selected_fixed_y_material = Roth.SELECTED_FIXED_Y_MATERIAL
		Roth.highlight_fixed_y_material = Roth.HIGHLIGHT_FIXED_Y_MATERIAL


func _on_outline_highlight_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		Settings.update_settings("options", {"selection_highlight": 1})
		Roth.selected_material = Roth.SELECTED_MATERIAL_OUTLINE
		Roth.highlight_material = Roth.HIGHLIGHT_MATERIAL_OUTLINE
		Roth.selected_fixed_y_material = Roth.SELECTED_FIXED_Y_MATERIAL
		Roth.highlight_fixed_y_material = Roth.HIGHLIGHT_FIXED_Y_MATERIAL


func _on_no_highlight_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		Settings.update_settings("options", {"selection_highlight": 2})
		Roth.selected_material = null
		Roth.highlight_material = null
		Roth.selected_fixed_y_material = null
		Roth.highlight_fixed_y_material = null
