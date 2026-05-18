extends ConsoleWindow

func _handle_command(command: String) -> void:
	var command_array: Array = command.split(" ")
	match command_array[0]:
		"orphan_nodes":
			print_orphan_nodes()
		"maps":
			for map: Variant in Roth.loaded_maps:
				Console.print(map)
		"save_hmps":
			DBase300.save_hmps()
		"clear_audio":
			Roth.audio_player.stream = null
			Roth.audio_player.playback = null
