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
		var x: float = vertex_node.coordinate.x
		var y: float = vertex_node.coordinate.y
		if Roth.halve_display_values:
			x /= 2
			y /= 2
		%VertexPositionLabel.text = "Vertex: (%d, %d)" % [x, y]
	
	elif len(owner.selected_vertex_nodes) > 1:
		%VertexPositionLabel.text = "Vertex: %d selected" % len(owner.selected_vertex_nodes)
	
	for each_vertex_node: VertexNode in owner.selected_vertex_nodes:
		pass
