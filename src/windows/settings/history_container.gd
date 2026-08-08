extends MarginContainer

@onready var _things: Dictionary = {
	"options": {
		"undo_history": { "node": %UndoHistorySpinBox, "value": %UndoHistorySpinBox.value },
		"backup_saves": { "node": %BackupSavesSpinBox, "value": %BackupSavesSpinBox.value },
	}
}


func _ready() -> void:
	NodeSave.reset(_things)


func _changed() -> void:
	NodeSave.save(_things)
