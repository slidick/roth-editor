extends Control

var dbase_data: Dictionary = {}


func load_dbase(p_dbase_data: Dictionary) -> void:
	dbase_data = p_dbase_data
	%SignatureEdit.text = str(dbase_data["dbase100"].header.signature)
	%FilesizeEdit.text = str(dbase_data["dbase100"].header.filesize)
	%Unk0x0CEdit.text = str(dbase_data["dbase100"].header.unk_dword_02)
	%InventoryCountEdit.text = str(dbase_data["dbase100"].header.nb_dbase100_inventory)
	%InventoryOffsetEdit.text = str(dbase_data["dbase100"].header.dbase100_table_inventory)
	%ActionsCountEdit.text = str(dbase_data["dbase100"].header.nb_dbase100_action)
	%ActionsOffsetEdit.text = str(dbase_data["dbase100"].header.dbase100_table_action)
	%CutscenesCountEdit.text = str(dbase_data["dbase100"].header.nb_dbase400_cutscene)
	%CutscenesOffsetEdit.text = str(dbase_data["dbase100"].header.dbase400_table_cutscene)
	%InterfacesCountEdit.text = str(dbase_data["dbase100"].header.nb_dbase400_interface)
	%InterfacesOffsetEdit.text = str(dbase_data["dbase100"].header.dbase400_table_interface)
	%Unk0x30Edit.text = str(dbase_data["dbase100"].header.unk_dword_11)


func _on_unk_0x_0c_edit_text_changed(new_text: String) -> void:
	dbase_data["dbase100"].header.unk_dword_02 = int(new_text)


func _on_unk_0x_30_edit_text_changed(new_text: String) -> void:
	dbase_data["dbase100"].header.unk_dword_11 = int(new_text)
