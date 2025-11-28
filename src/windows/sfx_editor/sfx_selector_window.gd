extends BaseWindow

signal done(entry: Dictionary)


var fxscript: Dictionary = {}


func _ready() -> void:
	super._ready()
	%Tree.set_column_expand(0, false)
	%Tree.set_column_expand_ratio(2, 3)
	%Tree.set_column_custom_minimum_width(0, 80)
	%Tree.set_column_title(0, "Index")
	%Tree.set_column_title(1, "Name")
	%Tree.set_column_title(2, "Description")


func select_sfx(p_fxscript: Dictionary = {}) -> Dictionary:
	if p_fxscript.is_empty():
		fxscript = FXScript.parse_sfx_info(Roth.get_active_sfx_info())
	else:
		fxscript = p_fxscript
	
	%Tree.clear()
	%Tree.create_item()
	for entry: Dictionary in fxscript.entries:
		add_sound_effect(entry)
	toggle(true)
	var sfx: Dictionary = await done
	toggle(false)
	fxscript = {}
	return sfx


func select() -> void:
	var tree_item: TreeItem = %Tree.get_selected()
	done.emit(tree_item.get_metadata(0))


func add_sound_effect(entry: Dictionary) -> void:
	var tree_item: TreeItem = %Tree.get_root().create_child()
	tree_item.set_text(0, "%s" % entry.index)
	tree_item.set_text(1, entry.name)
	tree_item.set_text(2, entry.desc)
	tree_item.set_metadata(0, entry)


func _on_tree_item_activated() -> void:
	if %Tree.get_selected_column() == 0:
		var tree_item: TreeItem = %Tree.get_selected()
		var entry: Dictionary = tree_item.get_metadata(0)
		Roth.play_audio_entry(FXScript.convert_to_playable_entry(entry))
	else:
		select()


func _on_select_button_pressed() -> void:
	select()


func _on_cancel_button_pressed() -> void:
	done.emit({})


func _on_search_edit_text_changed(new_text: String) -> void:
	%Tree.clear()
	%Tree.create_item()
	var search_text: String = new_text.to_lower()
	for entry: Dictionary in fxscript.entries:
		if search_text.is_empty() or entry.name.to_lower().find(search_text) != -1 or entry.desc.to_lower().find(search_text) != -1:
			add_sound_effect(entry)
