extends BaseWindow

func _ready() -> void:
	super._ready()
	%SettingsList.select(0)
	_on_settings_list_item_selected(0)


func _on_settings_list_item_selected(index: int) -> void:
	%TabContainer.current_tab = index
