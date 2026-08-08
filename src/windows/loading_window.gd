extends BaseWindow

func _ready() -> void:
	super._ready()
	Roth.das_loading_started.connect(_on_das_loading_started)
	Roth.das_loading_updated.connect(_on_das_loading_updated)
	Roth.map_loading_completely_finished.connect(_on_map_loading_completely_finished)


func _on_das_loading_started(map_name: String) -> void:
	_fade_in()
	%ProgressBar.value = 0
	%MapName.text = map_name
	%Status.text = "Loading:"


func _on_das_loading_updated(progress: float, das_info: Dictionary) -> void:
	%Status.text = "Loading textures: %s" % das_info.name
	%ProgressBar.value = progress * 100
	if is_equal_approx(progress, 1.0):
		_fade_out()


func _on_map_loading_completely_finished() -> void:
	_fade_out()
