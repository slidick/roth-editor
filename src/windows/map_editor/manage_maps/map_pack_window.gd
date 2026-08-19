extends BaseWindow

signal done(new_pack: Dictionary)
signal popup_done(filepath: String)

enum Type {
	CREATE,
	EDIT,
	EXPORT,
}

var current_map_pack: Dictionary
var normality: bool = false

func map_pack(p_type: Type, p_normality: bool, p_map_pack: Dictionary = {}) -> Variant:
	if p_type == Type.EDIT and p_map_pack.is_empty():
		return false
	match p_type:
		Type.CREATE:
			window_title = "Create Map Pack"
		Type.EDIT:
			window_title = "Edit Map Pack"
		Type.EXPORT:
			window_title = "Export Map Pack"
	current_map_pack = p_map_pack
	normality = p_normality
	%ErrorLabel.text = ""
	%NameEdit.text = ""
	%TitleEdit.text = ""
	%DescriptionEdit.text = ""
	%StoryEdit.text = ""
	%ReleaseEdit.text = ""
	%VersionEdit.text = ""
	if not normality:
		%DBASEOption.get_parent().show()
		%DBASEOption.clear()
		for dbase_info: Dictionary in DBasePack.dbase_packs:
			%DBASEOption.add_item(dbase_info.name)
			%DBASEOption.set_item_metadata(%DBASEOption.item_count-1, dbase_info)
			if p_map_pack and dbase_info == p_map_pack.dbase_info:
				%DBASEOption.select(%DBASEOption.item_count-1)
		%DAS2Option.get_parent().show()
		%DAS2Option.clear()
		for das2_info: Dictionary in DASPack.das2_packs:
			%DAS2Option.add_item(das2_info.name)
			%DAS2Option.set_item_metadata(%DAS2Option.item_count-1, das2_info)
			if p_map_pack and das2_info == p_map_pack.das2_info:
				%DAS2Option.select(%DAS2Option.item_count-1)
		%SFXOption.get_parent().show()
		%SFXOption.clear()
		for sfx_info: Dictionary in SFXPack.sfx_packs:
			%SFXOption.add_item(sfx_info.name)
			%SFXOption.set_item_metadata(%SFXOption.item_count-1, sfx_info)
			if p_map_pack and sfx_info == p_map_pack.sfx_info:
				%SFXOption.select(%SFXOption.item_count-1)
		%BackdropOption.get_parent().show()
		%BackdropOption.clear()
		for backdrop_info: Dictionary in BackdropPack.backdrop_packs:
			%BackdropOption.add_item(backdrop_info.name)
			%BackdropOption.set_item_metadata(%BackdropOption.item_count-1, backdrop_info)
			if p_map_pack and backdrop_info == p_map_pack.backdrop_info:
				%BackdropOption.select(%BackdropOption.item_count-1)
		%IconsOption.get_parent().show()
		%IconsOption.clear()
		for icon_info: Dictionary in IconPack.icon_packs:
			%IconsOption.add_item(icon_info.name)
			%IconsOption.set_item_metadata(%IconsOption.item_count-1, icon_info)
			if p_map_pack and icon_info == p_map_pack.icon_info:
				%IconsOption.select(%IconsOption.item_count-1)
	else:
		%DBASEOption.get_parent().hide()
		%DAS2Option.get_parent().hide()
		%SFXOption.get_parent().hide()
		%BackdropOption.get_parent().hide()
		%IconsOption.get_parent().hide()
	%SaveButton.disabled = true
	if p_map_pack:
		%NameEdit.text = p_map_pack.name
	if p_map_pack and ("vanilla" in p_map_pack or "unassigned" in p_map_pack):
		%NameEdit.editable = false
		%DetailsContainer.hide()
	else:
		%NameEdit.editable = true
		%DetailsContainer.show()
	if p_map_pack and not ("vanilla" in p_map_pack or "unassigned" in p_map_pack):
		%TitleEdit.text = p_map_pack.title
		%DescriptionEdit.text = p_map_pack.description
		%StoryEdit.text = p_map_pack.story
		%ReleaseEdit.text = p_map_pack.release
		%VersionEdit.text = p_map_pack.version
	
	if p_type == Type.EXPORT:
		%SaveButton.text = "Export"
		%SaveButton.disabled = false
	else:
		%SaveButton.text = "Save"
	
	toggle(true)
	var new_pack: Dictionary = await done
	
	match p_type:
		Type.EDIT:
			toggle(false)
			if not new_pack.is_empty():
				update_pack(p_map_pack, new_pack)
				return true
			return false
		Type.CREATE:
			toggle(false)
			if not new_pack.is_empty():
				new_pack["maps"] = []
				if normality:
					NormPack.save(new_pack)
				else:
					MapPack.save(new_pack)
				return new_pack
			return {}
		Type.EXPORT:
			if new_pack.is_empty():
				toggle(false)
				return false
			%FileDialog.current_file = new_pack.name.to_snake_case()
			if normality:
				%FileDialog.filters = ["*.norm.zip"]
			else:
				%FileDialog.filters = ["*.roth.zip"]
			%FileDialog.popup_file_dialog()
			var filepath: String = await popup_done
			if filepath.is_empty():
				toggle(false)
				return false
			if not new_pack.is_empty():
				update_pack(p_map_pack, new_pack)
			%CompressingZip.toggle(true)
			var thread := Thread.new()
			thread.start(func () -> bool: return MapPack.export(p_map_pack, filepath) if not normality else NormPack.export(p_map_pack, filepath))
			while thread.is_alive():
				await get_tree().process_frame
			var success: bool = thread.wait_to_finish()
			%CompressingZip.toggle(false)
			toggle(false)
			if success:
				await Dialog.information("Successfully exported:\n%s" % filepath, "Success", false, Vector2(400,150), "Close", HORIZONTAL_ALIGNMENT_CENTER)
			else:
				await Dialog.information("Permission denied.", "Error", false, Vector2(400,150), "Close", HORIZONTAL_ALIGNMENT_CENTER)
			return true
	return null


func update_pack(p_map_pack: Dictionary, new_info: Dictionary) -> void:
	p_map_pack.name = new_info.name
	if not normality:
		p_map_pack.dbase_info = new_info.dbase_info
		p_map_pack.das2_info = new_info.das2_info
		p_map_pack.sfx_info = new_info.sfx_info
		p_map_pack.backdrop_info = new_info.backdrop_info
		p_map_pack.icon_info = new_info.icon_info
	if "vanilla" not in p_map_pack and "unassigned" not in p_map_pack:
		p_map_pack.title = new_info.title
		p_map_pack.description = new_info.description
		p_map_pack.story = new_info.story
		p_map_pack.release = new_info.release
		p_map_pack.version = new_info.version
	if normality:
		NormPack.save(p_map_pack)
	else:
		MapPack.save(p_map_pack)


func _on_cancel_button_pressed() -> void:
	toggle(false)
	done.emit({})


func _save() -> void:
	done.emit({
		"name": %NameEdit.text,
		"dbase_info": %DBASEOption.get_selected_metadata(),
		"das2_info": %DAS2Option.get_selected_metadata(),
		"sfx_info": %SFXOption.get_selected_metadata(),
		"backdrop_info": %BackdropOption.get_selected_metadata(),
		"icon_info": %IconsOption.get_selected_metadata(),
		"title": %TitleEdit.text,
		"description": %DescriptionEdit.text,
		"story": %StoryEdit.text,
		"release": %ReleaseEdit.text,
		"version": %VersionEdit.text,
	})


func _changed() -> void:
	var error: String = ""
	if normality:
		NormPack.check_name(%NameEdit.text)
	else:
		MapPack.check_name(%NameEdit.text)
	if error.is_empty() or (current_map_pack and %NameEdit.text == current_map_pack.name):
		%SaveButton.disabled = false
		%ErrorLabel.text = ""
	else:
		%ErrorLabel.text = error
		%SaveButton.disabled = true
	
	if not normality and (%DBASEOption.get_selected_id() == -1
		or %DAS2Option.get_selected_id() == -1
		or %SFXOption.get_selected_id() == -1
		or %BackdropOption.get_selected_id() == -1
		or %IconsOption.get_selected_id() == -1
	):
		%SaveButton.disabled = true


func _on_file_dialog_file_selected(path: String) -> void:
	popup_done.emit(path)


func _on_file_dialog_canceled() -> void:
	popup_done.emit("")
