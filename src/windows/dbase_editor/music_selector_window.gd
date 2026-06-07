extends BaseWindow

signal done(changed: bool)

var command: Dictionary

func select_music(p_command: Dictionary, p_dbase_100: Dictionary) -> bool:
	command = p_command
	%ItemList.clear()
	for song: Dictionary in p_dbase_100.songs.values():
		var song_name: String = "Unknown Song"
		if song.hash in Music.hash_mapping:
			song_name = Music.hash_mapping[song.hash]
		var idx: int = %ItemList.add_item(song_name)
		%ItemList.set_item_metadata(idx, song)
		if idx == 0:
			%ItemList.select(idx)
		if p_command.data == song:
			%ItemList.select(idx)
	%ItemList.ensure_current_is_visible()
	toggle(true)
	var changed: bool = await done
	toggle(false)
	return changed


func _on_cancel_button_pressed() -> void:
	done.emit(false)


func _on_save_button_pressed() -> void:
	save()


func _on_item_list_item_activated(_index: int) -> void:
	save()


func save() -> void:
	var new_song: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	command.data = new_song
	done.emit(true)
