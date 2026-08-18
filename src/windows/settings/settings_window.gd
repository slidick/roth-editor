extends BaseWindow

func _ready() -> void:
	super._ready()
	%SettingsList.clear()
	for child: Node in %TabContainer.get_children():
		%SettingsList.add_item(child.name)
	%SettingsList.select(0)
	_on_settings_list_item_selected(0)
	Roth.settings_updated.connect(_on_settings_updated)


func _on_settings_updated() -> void:
	if not Roth.current_installation and not Normality.current_installation:
		toggle(true)


func _on_settings_list_item_selected(index: int) -> void:
	%TabContainer.current_tab = index
