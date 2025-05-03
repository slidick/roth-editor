extends Control

var root : TreeItem

func _ready() -> void:
	root = %Tree.create_item()
	root.set_text(0, "root")
	root.set_collapsed_recursive(true)
	%Tree.set_column_expand_ratio(0, 1)
	%Tree.set_column_expand_ratio(1, 3)
	%Tree.set_column_expand(2, 0.5)
	%Tree.set_column_title(0, "Key")
	%Tree.set_column_title(1, "Value")
	%Tree.set_column_title(2, "Type")
	%Tree.set_column_title(2, "Type")


func load_file(filepath: String) -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(filepath))
	add_sub_tree(root, data)


func add_sub_tree(child: TreeItem, data: Variant) -> void:
	match typeof(data):
		TYPE_DICTIONARY:
			child.set_text(2, "TYPE_DICTIONARY")
			child.set_text_alignment(2, HORIZONTAL_ALIGNMENT_CENTER)
			for k: String in data:
				var sub_child: TreeItem = child.create_child()
				sub_child.set_text(0, k)
				sub_child.set_editable(0, true)
				add_sub_tree(sub_child, data[k])
		TYPE_ARRAY:
			child.set_text(2, "TYPE_ARRAY")
			child.set_text_alignment(2, HORIZONTAL_ALIGNMENT_CENTER)
			for i in range(len(data)):
				var sub_child: TreeItem = child.create_child()
				sub_child.set_text(0, str(i))
				sub_child.set_editable(0, true)
				add_sub_tree(sub_child, data[i])
		TYPE_STRING:
			child.set_text(1, str(data))
			child.set_editable(1, true)
			child.set_text(2, "TYPE_STRING")
			child.set_text_alignment(2, HORIZONTAL_ALIGNMENT_CENTER)
		TYPE_FLOAT:
			child.set_text(1, str(data))
			child.set_editable(1, true)
			child.set_text(2, "TYPE_FLOAT")
			child.set_text_alignment(2, HORIZONTAL_ALIGNMENT_CENTER)
		TYPE_BOOL:
			child.set_text(1, str(data))
			child.set_editable(1, true)
			child.set_text(2, "TYPE_BOOL")
			child.set_text_alignment(2, HORIZONTAL_ALIGNMENT_CENTER)
		_:
			print(typeof(data), " data type not found")
