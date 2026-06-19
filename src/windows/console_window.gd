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
		"hmp":
			var filepath := Roth.install_directory.path_join("../DATA/DBASE300.DAT")
			var offset := 21620072
			var data: Dictionary = Hmp.parse_at_offset(filepath, offset)
			print(JSON.stringify(data, '\t', false))
		"bnk":
			var filepath: String = Roth.install_directory.path_join("../DATA/MIDI/MELODIC.BNK")
			var data: Dictionary = Bnk.parse_filepath(filepath)
			Console.print(JSON.stringify(data, '\t', false))
		"drum":
			var filepath: String = Roth.install_directory.path_join("../DATA/MIDI/DRUM.BNK")
			var data: Dictionary = Bnk.parse_filepath(filepath)
			Console.print(JSON.stringify(data, '\t', false))
		"save":
			var filepath: String = Roth.install_directory.path_join("../ROTH/SAVEGAME/SAVE2.SAV")
			var data: Dictionary = SaveGame.parse_filepath(filepath)
			Console.print(JSON.stringify(data, '\t', false))
