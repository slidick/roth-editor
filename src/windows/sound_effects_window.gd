extends BaseWindow

const SHUFFLE_ICON: Texture2D = preload("uid://vqxqqwh4il66")
const STRAIGHT_ICON: Texture2D = preload("uid://v8bmkjmutd7s")

var tree_root: TreeItem
var dbase400_filepath: String
var dbase500_filepath: String

var play_all: bool = false
var shuffle: bool = false
var current: TreeItem
var playlist: Array = []

func _ready() -> void:
	super._ready()
	Roth.settings_loaded.connect(_on_settings_loaded)
	%DialogList.set_column_expand(0, true)
	%DialogList.set_column_expand(1, false)
	tree_root = %DialogList.create_item()


func _on_settings_loaded() -> void:
	for tree_item: TreeItem in tree_root.get_children():
		tree_root.remove_child(tree_item)
		tree_item.free()
	
	dbase400_filepath = Roth.directory.path_join("..").path_join("DATA").path_join("DBASE400.DAT")
	if not FileAccess.file_exists(dbase400_filepath):
		return
	dbase500_filepath = Roth.directory.path_join("..").path_join("DATA").path_join("DBASE500.DAT")
	if not FileAccess.file_exists(dbase500_filepath):
		return
	
	var entries: Array = DBase400.parse(dbase400_filepath)
	#var i: int = 0
	for entry: Dictionary in entries:
		if entry.offset > 0:
			var child_item: TreeItem = tree_root.create_child()
			child_item.set_text(0, entry.string)
			#child_item.set_text(0, "%d: %s" % [i, entry.string])
			child_item.set_metadata(0, entry)
			#i += 1


func _on_dialog_list_item_activated() -> void:
	current = %DialogList.get_selected()
	play(%DialogList.get_selected().get_metadata(0))


func play(entry: Dictionary) -> void:
	#print(entry)
	var data: Array = DBase500.parse(dbase500_filepath, entry.offset)
	Roth.play_audio_buffer(data)
	%Waveform.setup(data)
	%HSlider.value = 0
	%HSlider.max_value = (len(data) / float(22050)) * 10
	%Timer.start()


func _on_timer_timeout() -> void:
	if %HSlider.value == %HSlider.max_value:
		if play_all:
			%PlaylistLeft.text = "%d" % len(playlist)
			if not shuffle:
				current = current.get_next()
				playlist.erase(current)
			else:
				current = playlist.pop_back()
			current.select(0)
			%DialogList.scroll_to_item(current, true)
			play(current.get_metadata(0))
		else:
			%Timer.stop()
	else:
		%HSlider.value += 1



func _on_play_button_pressed() -> void:
	play_all = true
	playlist.clear()
	var tree_item: TreeItem = %DialogList.get_root().get_next_in_tree()
	while tree_item:
		playlist.append(tree_item)
		tree_item = tree_item.get_next_in_tree()
	playlist.shuffle()
	%PlaylistLeft.text = "%d" % len(playlist)
	if %DialogList.get_selected():
		current = %DialogList.get_selected()
	else:
		if not shuffle:
			current = %DialogList.get_root().get_next_in_tree()
		else:
			current = playlist.pop_back()
	current.select(0)
	%DialogList.scroll_to_item(current, true)
	playlist.erase(current)
	play(current.get_metadata(0))


func _on_stop_button_pressed() -> void:
	play_all = false
	Roth.stop_audio_buffer()
	%Timer.stop()
	%HSlider.value = 0


func _on_shuffle_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		%ShuffleButton.icon = SHUFFLE_ICON
	else:
		%ShuffleButton.icon = STRAIGHT_ICON
	shuffle = toggled_on


func _on_search_edit_text_changed(new_text: String) -> void:
	var tree_item: TreeItem = %DialogList.get_root().get_next_in_tree()
	while tree_item:
		if new_text.is_empty():
			tree_item.visible = true
		elif tree_item.get_text(0).to_lower().contains(new_text.to_lower()):
			tree_item.visible = true
		else:
			tree_item.visible = false
		tree_item = tree_item.get_next_in_tree()
