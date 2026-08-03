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
			DBase300.save_hmps(Roth.install_directory)
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
		"create_patch":
			if len(command_array) != 4:
				Console.print("Usage: create_patch [a_dir] [b_dir] [out_dir]")
				return
			ROTHPatch.create_patch_from_folders(command_array[1], command_array[2], command_array[3])
