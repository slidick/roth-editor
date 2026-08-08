extends MarginContainer

func clear() -> void:
	%VertexPositionLabel.text = ""
	%EditVertexContainer.hide()

func update_selections() -> void:
	clear()
	if len(owner.selected_vertex_nodes) == 0:
		return
	
	%EditVertexContainer.show()
	var vertex_node: VertexNode = owner.selected_vertex_nodes[0]
	
	if len(owner.selected_vertex_nodes) == 1:
		%VertexPositionLabel.text = "Vertex: %s" % vertex_node.coordinate
	
	elif len(owner.selected_vertex_nodes) > 1:
		%VertexPositionLabel.text = "Vertex: %d selected" % len(owner.selected_vertex_nodes)
	
	for each_vertex_node: VertexNode in owner.selected_vertex_nodes:
		pass
