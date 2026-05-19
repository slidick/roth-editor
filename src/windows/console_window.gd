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
		"get_midi_offsets":
			print(DBase300.get_offsets_by_type(Roth.install_directory.path_join("../DATA/DBASE300.DAT"), DBase300.FILETYPE_MIDI))
		"stop_audio":
			Roth.audio_player.stop()
