extends Node2D

var faces: Array = []
var minimum_x: float = 0
var minimum_y: float = 0
var maximum_x: float = 0
var maximum_y: float = 0


func setup(p_faces: Array) -> void:
	clear()
	minimum_x = 10000
	minimum_y = 10000
	maximum_x = -10000
	maximum_y = -10000
	faces = p_faces
	queue_redraw()


func clear() -> void:
	for face: Dictionary in faces:
		face.clear()
	faces.clear()
	queue_redraw()


func _draw() -> void:
	if not faces:
		return
	for face: Dictionary in faces:
		minimum_x = min(minimum_x, face.v1.x / Roth.SCALE_2D_WORLD)
		minimum_x = min(minimum_x, face.v2.x / Roth.SCALE_2D_WORLD)
		minimum_y = min(minimum_y, face.v1.y / Roth.SCALE_2D_WORLD)
		minimum_y = min(minimum_y, face.v2.y / Roth.SCALE_2D_WORLD)
		
		maximum_x = max(maximum_x, face.v1.x / Roth.SCALE_2D_WORLD)
		maximum_x = max(maximum_x, face.v2.x / Roth.SCALE_2D_WORLD)
		maximum_y = max(maximum_y, face.v1.y / Roth.SCALE_2D_WORLD)
		maximum_y = max(maximum_y, face.v2.y / Roth.SCALE_2D_WORLD)
		
		if "sister" in face:
			if face.sector.floorHeight != face.sister.sector.floorHeight:
				draw_line(Vector2(face.v1.x/Roth.SCALE_2D_WORLD, face.v1.y/Roth.SCALE_2D_WORLD), Vector2(face.v2.x/Roth.SCALE_2D_WORLD, face.v2.y/Roth.SCALE_2D_WORLD), Color.BLUE, 1.0, true)
			else:
				draw_line(Vector2(face.v1.x/Roth.SCALE_2D_WORLD, face.v1.y/Roth.SCALE_2D_WORLD), Vector2(face.v2.x/Roth.SCALE_2D_WORLD, face.v2.y/Roth.SCALE_2D_WORLD), Color.STEEL_BLUE, 1.0, true)
	for face: Dictionary in faces:
		if not "sister" in face:
			draw_line(Vector2(face.v1.x/Roth.SCALE_2D_WORLD, face.v1.y/Roth.SCALE_2D_WORLD), Vector2(face.v2.x/Roth.SCALE_2D_WORLD, face.v2.y/Roth.SCALE_2D_WORLD), Color.WHITE, 1.0, true)
	
	var center := Vector2(
		(maximum_x + minimum_x) / 2,
		(maximum_y + minimum_y) / 2,
	)
	
	var size := Vector2(
		maximum_x - minimum_x,
		maximum_y - minimum_y
	)
	
	%Camera2D.position = center
	
	var zoom_y: float = %Camera2D.get_viewport().size.y / size.y
	var zoom_x: float = %Camera2D.get_viewport().size.x / size.x
	var zoom: float = min(zoom_x, zoom_y) * 0.95
	
	%Camera2D.zoom = Vector2(zoom, zoom)
