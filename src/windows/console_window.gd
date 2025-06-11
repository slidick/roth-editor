extends ConsoleWindow

func _handle_command(command: String) -> void:
	var command_array: Array = command.split(" ")
	match command_array[0]:
		"orphan_nodes":
			print_orphan_nodes()
		"maps":
			for map: Variant in Roth.loaded_maps:
				Console.print(map)
		"dbase400":
			if len(command_array) != 2:
				Console.print("Usage: dbase400 [offset]")
				return
			var section := DBase400.get_at_offset(command_array[1].to_int())
			Console.print("%s" % section)
