extends Control

const COLUMNS: int = 16
var das: Variant

func reset() -> void:
	das = {}
	for child: Node in get_children():
		child.queue_free()


func load_das(p_das: Dictionary, p_key: String) -> void:
	das = p_das
	
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	add_child(vbox)
	
	var tree := Tree.new()
	tree.hide_root = true
	tree.columns = COLUMNS
	tree.hide_folding = true
	tree.column_titles_visible = false
	tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree.item_edited.connect(func () -> void:
		var data: Array = []
		var i: int = 0
		for tree_item: TreeItem in tree.get_root().get_children():
			for j in range(COLUMNS):
				if len(das[p_key].raw_data) > (i*COLUMNS+j):
					data.append(int(tree_item.get_text(j)))
			i += 1
		das[p_key].raw_data = data
	)
	vbox.add_child(tree)
	
	var root := tree.create_item()
	for i in range(ceili(len(das[p_key].raw_data)/float(COLUMNS))):
		var tree_item := root.create_child()
		for j in range(COLUMNS):
			if len(das[p_key].raw_data) > (i*COLUMNS+j):
				tree_item.set_editable(j, true)
				tree_item.set_text(j, str(das[p_key].raw_data[i*COLUMNS+j]))
