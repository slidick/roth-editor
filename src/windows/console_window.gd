extends ConsoleWindow

func _handle_command(command: String) -> void:
	var command_array: Array = command.split(" ")
	match command_array[0]:
		"orphan_nodes":
			print_orphan_nodes()
		"maps":
			for map: Variant in Roth.loaded_maps:
				Console.print(map)
		"dbase200":
			if len(command_array) == 1:
				print(DBase200.get_animation_offsets())
				return
			if len(command_array) != 2:
				Console.print("Usage: dbase200 [offset]")
				return
			var section: Variant = DBase200.get_at_offset(command_array[1].to_int())
			Console.print("%s" % JSON.stringify(section, '\t'))
		"dbase300":
			if len(command_array) == 1:
				DBase300.parse()
				return
			if len(command_array) != 2:
				Console.print("Usage: dbase300 [offset]")
				return
			
			var section: Variant = DBase300.get_at_offset(command_array[1].to_int())
			Console.print("%s" % section)
		"dbase400":
			if len(command_array) != 2:
				Console.print("Usage: dbase400 [offset]")
				return
			var section := DBase400.get_at_offset(command_array[1].to_int())
			Console.print("%s" % section)
		"save_hmps":
			DBase300.save_hmps()
		"concave":
			var map_2d: Node = get_tree().get_root().find_child("Map2D", true, false)
			if map_2d and map_2d.map:
				var map: Map = map_2d.map
				var sectors: Array = map.find_concave_sectors()
				var editor: Node = get_tree().get_root().find_child("Editor", true, false)
				if editor:
					editor.select_resource(null)
					for sector: Sector in sectors:
						editor.select_resource(sector, false)
		"clear_audio":
			Roth.audio_player.playback = null
