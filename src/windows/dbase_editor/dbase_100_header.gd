extends Control

var dbase_data: Dictionary = {}


func reset() -> void:
	dbase_data = {}
	%SignatureEdit.text = ""
	%FilesizeEdit.text = ""
	%Unk0x0CEdit.text = ""
	%InventoryCountEdit.text = ""
	%InventoryOffsetEdit.text = ""
	%ActionsCountEdit.text = ""
	%ActionsOffsetEdit.text = ""
	%CutscenesCountEdit.text = ""
	%CutscenesOffsetEdit.text = ""
	%InterfacesCountEdit.text = ""
	%InterfacesOffsetEdit.text = ""
	%Unk0x30Edit.text = ""


func load_dbase(p_dbase_data: Dictionary) -> void:
	reset()
	dbase_data = p_dbase_data
	%SignatureEdit.text = str(dbase_data["dbase100"].header.signature)
	%FilesizeEdit.text = str(dbase_data["dbase100"].header.filesize)
	%Unk0x0CEdit.text = str(dbase_data["dbase100"].header.unk_dword_02)
	%InventoryCountEdit.text = str(dbase_data["dbase100"].header.inventory_count)
	%InventoryOffsetEdit.text = str(dbase_data["dbase100"].header.inventory_offset)
	%ActionsCountEdit.text = str(dbase_data["dbase100"].header.action_count)
	%ActionsOffsetEdit.text = str(dbase_data["dbase100"].header.action_offset)
	%CutscenesCountEdit.text = str(dbase_data["dbase100"].header.cutscene_count)
	%CutscenesOffsetEdit.text = str(dbase_data["dbase100"].header.cutscene_offset)
	%InterfacesCountEdit.text = str(dbase_data["dbase100"].header.interface_count)
	%InterfacesOffsetEdit.text = str(dbase_data["dbase100"].header.interface_offset)
	%Unk0x30Edit.text = str(dbase_data["dbase100"].header.unk_dword_11)


func _on_unk_0x_0c_edit_text_changed(new_text: String) -> void:
	dbase_data["dbase100"].header.unk_dword_02 = int(new_text)


func _on_unk_0x_30_edit_text_changed(new_text: String) -> void:
	dbase_data["dbase100"].header.unk_dword_11 = int(new_text)
