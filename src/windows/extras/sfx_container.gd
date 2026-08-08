extends Control


func _ready() -> void:
	Roth.settings_updated.connect(_on_settings_updated)


func _on_settings_updated() -> void:
	if not Roth.current_installation:
		return
	%SFXList.clear()
	var sfx_entries: Array = FXScript.get_sfx_entries(Roth.current_installation.fx22)
	if not sfx_entries.is_empty():
		for i in range(len(sfx_entries)):
			var entry: Dictionary = sfx_entries[i]
			var idx: int = %SFXList.add_item("%d: %s - %s" % [(i+1), entry.name, entry.desc])
			%SFXList.set_item_metadata(idx, entry)


func _on_sfx_list_item_activated(index: int) -> void:
	var entry: Dictionary = %SFXList.get_item_metadata(index)
	var entry_data := FXScript.get_from_entry(entry)
	RothAudio.play_entry(entry_data)
