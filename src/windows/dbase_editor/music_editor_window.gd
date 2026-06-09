extends BaseWindow

signal done

var song: Dictionary

func load_song(p_song: Dictionary) -> Dictionary:
	song = p_song.duplicate(true)
	# Load
	%TrackList.clear()
	for i in range(song.data.num_chunks):
		var idx: int = %TrackList.add_item("%d" % (i+1))
		%TrackList.set_item_metadata(idx, song.data.chunks[i])
	
	toggle(true)
	var new_song: Dictionary =await done
	toggle(false)
	return new_song


func _on_cancel_button_pressed() -> void:
	done.emit({})
	toggle(false)


func _on_save_button_pressed() -> void:
	done.emit({})


func _on_track_list_item_selected(index: int) -> void:
	var track_data: Dictionary = %TrackList.get_item_metadata(index)
	print(track_data.chunk_number, ": ", track_data.chunk_length)
