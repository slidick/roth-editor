extends Control

var fxscript: Dictionary = {}


func _ready() -> void:
	%Tree.create_item()
	%Tree.set_column_expand(0, false)
	%Tree.set_column_expand_ratio(2, 3)
	%Tree.set_column_custom_minimum_width(0, 80)
	%Tree.set_column_title(0, "Index")
	%Tree.set_column_title(1, "Name")
	%Tree.set_column_title(2, "Description")


func reset() -> void:
	fxscript = {}
	for tree_item: TreeItem in %Tree.get_root().get_children():
		tree_item.free()
	%Tree.scroll_to_item(%Tree.get_root())


func load_fxscript(p_fxscript: Dictionary) -> void:
	fxscript = p_fxscript
	for entry: Dictionary in fxscript.entries:
		add_sound_effect(entry)


func add_sound_effect(entry: Dictionary) -> TreeItem:
	var tree_item: TreeItem = %Tree.get_root().create_child()
	tree_item.set_text(0, "%s" % entry.index)
	tree_item.set_text(1, entry.name)
	tree_item.set_text(2, entry.desc)
	tree_item.set_metadata(0, entry)
	return tree_item


func save_sound_effects() -> void:
	for tree_item: TreeItem in %Tree.get_root().get_children():
		var sound_effect: Dictionary = tree_item.get_metadata(0)
		sound_effect.name = tree_item.get_text(1)
		sound_effect.desc = tree_item.get_text(2)
		fxscript.entries[sound_effect.index-1] = sound_effect


func _on_tree_item_selected() -> void:
	# Work-around to simulate edit only on double click
	var tree_item: TreeItem = %Tree.get_selected()
	tree_item.set_editable(1, true)
	tree_item.set_editable(2, true)
	await get_tree().create_timer(0.5).timeout
	if tree_item:
		tree_item.set_editable(1, false)
		tree_item.set_editable(2, false)


func _on_tree_item_activated() -> void:
	if %Tree.get_selected_column() == 0:
		var tree_item: TreeItem = %Tree.get_selected()
		var entry: Dictionary = tree_item.get_metadata(0)
		Roth.play_audio_entry(FXScript.convert_to_playable_entry(entry))


func _on_tree_item_edited() -> void:
	save_sound_effects()


func _on_tree_item_moved() -> void:
	save_sound_effects()


func _on_shuffle_button_pressed() -> void:
	if await Dialog.confirm("Are you sure?", "Confirm Shuffle", false, Vector2(400,150)):
		fxscript.entries.shuffle()
		%Tree.clear()
		%Tree.create_item()
		var i: int = 1
		for entry: Dictionary in fxscript.entries:
			entry.index = i
			add_sound_effect(entry)
			i += 1
		save_sound_effects()


func _on_tree_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			%PopupMenu.popup(Rect2i(int(%Tree.global_position.x+mouse_position.x), int(%Tree.global_position.y+mouse_position.y), 0, 0))


func _on_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			var tree_item: TreeItem = %Tree.get_selected()
			var entry: Dictionary = tree_item.get_metadata(0)
			var new_entry: Dictionary = await owner.edit_audio(entry)
			if new_entry.is_empty():
				return
			tree_item.set_metadata(0, new_entry)
			save_sound_effects()
		1:
			if await Dialog.confirm("Are you sure?", "Confirm Audio Clear", false, Vector2(400,150)):
				var tree_item: TreeItem = %Tree.get_selected()
				var entry: Dictionary = tree_item.get_metadata(0)
				entry.type = 0
				#entry.name = "N"
				entry.raw_data = PackedByteArray()
				#tree_item.set_text(1, "N")
		2:
			if await Dialog.confirm("Are you sure?", "Confirm Audio Delete", false, Vector2(400,150)):
				var tree_item: TreeItem = %Tree.get_selected()
				var current: Dictionary = tree_item.get_metadata(0)
				var entry_index: int = fxscript.entries.find(current)
				for i in range(entry_index, len(fxscript.entries)):
					fxscript.entries[i].index -= 1
				fxscript.entries.erase(current)
				%Tree.clear()
				%Tree.create_item()
				for entry: Dictionary in fxscript.entries:
					add_sound_effect(entry)


func _on_search_edit_text_changed(new_text: String) -> void:
	%Tree.clear()
	%Tree.create_item()
	var search_text: String = new_text.to_lower()
	for entry: Dictionary in fxscript.entries:
		if search_text.is_empty() or entry.name.to_lower().find(search_text) != -1 or entry.desc.to_lower().find(search_text) != -1:
			add_sound_effect(entry)


func _on_new_button_pressed() -> void:
	var entry := {
		"index": len(fxscript.entries)+1,
		"name": "N",
		"desc": "(None)",
		"type": 0,
		"raw_data": PackedByteArray()
	}
	fxscript.entries.append(entry)
	var tree_item: TreeItem = add_sound_effect(entry)
	%Tree.scroll_to_item(tree_item)
	%Tree.set_selected(tree_item, 0)
