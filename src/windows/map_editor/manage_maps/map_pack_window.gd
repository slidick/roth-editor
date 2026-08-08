extends BaseWindow

signal done(new_pack: Dictionary)

enum Type {
	CREATE,
	EDIT,
}

var current_map_pack: Dictionary


func map_pack(p_type: Type, p_map_pack: Dictionary = {}) -> Variant:
	if p_type == Type.EDIT and p_map_pack.is_empty():
		return false
	match p_type:
		Type.CREATE:
			window_title = "Create Map Pack"
		Type.EDIT:
			window_title = "Edit Map Pack"
	current_map_pack = p_map_pack
	%ErrorLabel.text = ""
	%NameEdit.text = ""
	%DBASEOption.clear()
	for dbase_info: Dictionary in DBasePack.dbase_packs:
		%DBASEOption.add_item(dbase_info.name)
		%DBASEOption.set_item_metadata(%DBASEOption.item_count-1, dbase_info)
		if p_map_pack and dbase_info == p_map_pack.dbase_info:
			%DBASEOption.select(%DBASEOption.item_count-1)
	%DAS2Option.clear()
	for das2_info: Dictionary in DASPack.das2_packs:
		%DAS2Option.add_item(das2_info.name)
		%DAS2Option.set_item_metadata(%DAS2Option.item_count-1, das2_info)
		if p_map_pack and das2_info == p_map_pack.das2_info:
			%DAS2Option.select(%DAS2Option.item_count-1)
	%SFXOption.clear()
	for sfx_info: Dictionary in SFXPack.sfx_packs:
		%SFXOption.add_item(sfx_info.name)
		%SFXOption.set_item_metadata(%SFXOption.item_count-1, sfx_info)
		if p_map_pack and sfx_info == p_map_pack.sfx_info:
			%SFXOption.select(%SFXOption.item_count-1)
	%BackdropOption.clear()
	%IconsOption.clear()
	%SaveButton.disabled = true
	if p_map_pack:
		%NameEdit.text = p_map_pack.name
	if p_map_pack and ("vanilla" in p_map_pack or "unassigned" in p_map_pack):
		%NameEdit.editable = false
	else:
		%NameEdit.editable = true
	toggle(true)
	var new_pack: Dictionary = await done
	toggle(false)
	
	match p_type:
		Type.EDIT:
			if not new_pack.is_empty():
				p_map_pack.name = new_pack.name
				p_map_pack.dbase_info = new_pack.dbase_info
				p_map_pack.das2_info = new_pack.das2_info
				p_map_pack.sfx_info = new_pack.sfx_info
				#p_map_pack.backdrop = new_pack.backdrop
				#p_map_pack.icons = new_pack.icons
				MapPack.save(p_map_pack)
				return true
			return false
		Type.CREATE:
			if not new_pack.is_empty():
				new_pack["backdrop"] = "Original"
				new_pack["icons"] = "Original"
				new_pack["maps"] = []
				MapPack.save(new_pack)
				return new_pack
			return {}
	
	return null


func _on_cancel_button_pressed() -> void:
	toggle(false)
	done.emit({})


func _save() -> void:
	done.emit({
		"name": %NameEdit.text,
		"dbase_info": %DBASEOption.get_selected_metadata(),
		"das2_info": %DAS2Option.get_selected_metadata(),
		"sfx_info": %SFXOption.get_selected_metadata(),
	})


func _changed() -> void:
	var error: String = MapPack.check_name(%NameEdit.text)
	if error.is_empty() or (current_map_pack and %NameEdit.text == current_map_pack.name):
		%SaveButton.disabled = false
		%ErrorLabel.text = ""
	else:
		%ErrorLabel.text = error
		%SaveButton.disabled = true
	
	if (%DBASEOption.get_selected_id() == -1
		or %DAS2Option.get_selected_id() == -1
		or %SFXOption.get_selected_id() == -1
	):
		%SaveButton.disabled = true
