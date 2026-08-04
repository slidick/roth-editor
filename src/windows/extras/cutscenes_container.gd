extends Control


func _ready() -> void:
	Roth.settings_loaded.connect(_on_settings_loaded)


func _on_settings_loaded() -> void:
	%ItemList.clear()
	if Roth.install_directory.is_empty():
		return
	var cutscenes: Array = DBase100.parse_cutscenes(Roth.install_directory)
	for cutscene: Dictionary in cutscenes:
		cutscene["filepath"] = Roth.install_directory.path_join("../DATA/GDV/%s.GDV" % cutscene.name)
		if cutscene.name != "" and FileAccess.file_exists(cutscene.filepath):
			var idx: int = %ItemList.add_item(cutscene.name)
			%ItemList.set_item_metadata(idx, cutscene)


func _on_item_list_item_selected(index: int) -> void:
	var cutscene: Dictionary = %ItemList.get_item_metadata(index)
	%GDVVideoPlayer.load_gdv_data(cutscene.merged(GDV.get_video_by_path(cutscene.filepath)))
