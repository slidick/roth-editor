extends BaseWindow

func _ready() -> void:
	super._ready()
	Roth.map_loading_started.connect(_on_map_loading_started)
	#Roth.map_loading_status_changed.connect(_on_map_loading_status_changed)
	Roth.map_loading_updated.connect(_on_map_loading_updated)
	Roth.map_loading_completely_finished.connect(_on_map_loading_completely_finished)


func _on_map_loading_started(map_name: String) -> void:
	_fade_in()
	%ProgressBar.value = 0
	%MapName.text = map_name
	%Status.text = "Loading:"


#func _on_map_loading_status_changed(status: String) -> void:
	#%Status.text = status


func _on_map_loading_updated(das_info: Dictionary, progress: float) -> void:
	%Status.text = "Loading textures: %s" % das_info.name
	%ProgressBar.value = progress * 100
	if is_equal_approx(progress, 1.0):
		_fade_out()


func _on_map_loading_completely_finished() -> void:
	_fade_out()
