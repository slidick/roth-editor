extends Control


func _ready() -> void:
	Roth.settings_updated.connect(_on_settings_updated)


func _on_settings_updated() -> void:
	%ItemList.clear()
	if not Roth.current_installation:
		return
	var cutscenes: Array = DBase100.parse_cutscenes(Roth.current_installation)
	for cutscene: Dictionary in cutscenes:
		cutscene["filepath"] = Roth.current_installation.get(cutscene.name.to_lower()+"_gdv")
		if cutscene.filepath and FileAccess.file_exists(cutscene.filepath):
			var idx: int = %ItemList.add_item(cutscene.name)
			%ItemList.set_item_metadata(idx, cutscene)


func _on_item_list_item_selected(index: int) -> void:
	var cutscene: Dictionary = %ItemList.get_item_metadata(index)
	%GDVVideoPlayer.load_gdv_data(cutscene.merged(GDV.get_video_by_path(cutscene.filepath)))
