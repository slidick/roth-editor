extends ConsoleWindow

func _handle_command(command: String) -> void:
	match command:
		"orphan_nodes":
			print_orphan_nodes()
		"maps":
			for map: Variant in Roth.loaded_maps:
				Console.print(map)
