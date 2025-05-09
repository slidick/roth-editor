extends Node2D
class_name VertexNode

signal position_updated
signal position_finalized(vertex: VertexNode)
signal vertex_deleted
signal start_sector_split(vertex: VertexNode)
const DRAW_SIZE := 0.25

var coordinate: Vector2
var sectors := []
var faces := []
var polygon: BorderPolygon2D
var split_vertex: bool = false
var start_drag_position := Vector2.ZERO

const DRAGGING_THRESHOLD: float = 1.0
var mouse_over: bool = false
var dragging: bool = false
var drag_started: bool = false
var dragging_amount := Vector2.ZERO
var allow_move: bool = false

func _init(p_coordinate: Vector2, p_data: Dictionary, p_allow_move: bool, p_split_vertex: bool = false) -> void:
	coordinate = Vector2(p_coordinate)
	sectors = p_data.sectors
	faces = p_data.faces
	split_vertex = p_split_vertex
	allow_move = p_allow_move

func _ready() -> void:
	polygon = BorderPolygon2D.new()
	var draw_size := DRAW_SIZE
	if split_vertex:
		draw_size /= 2
	polygon.polygon = [Vector2(-draw_size, -draw_size), Vector2(draw_size, -draw_size), Vector2(draw_size, draw_size), Vector2(-draw_size, draw_size) ]
	if not split_vertex:
		polygon.color = Color.DIM_GRAY
	else:
		polygon.color = Color.YELLOW_GREEN
		draw_size *= 2
	add_child(polygon)
	position.x = coordinate.x / Roth.SCALE_2D_WORLD
	position.y = coordinate.y / Roth.SCALE_2D_WORLD
	var shape := RectangleShape2D.new()
	shape.size.x = draw_size * 2
	shape.size.y = draw_size * 2
	var collision := CollisionShape2D.new()
	collision.shape = shape
	var area := Area2D.new()
	area.add_child(collision)
	area.mouse_entered.connect(_on_mouse_entered)
	area.mouse_exited.connect(_on_mouse_exited)
	add_child(area)


func _on_mouse_entered() -> void:
	if not split_vertex:
		if allow_move:
			polygon.color = Color.GRAY
	else:
		polygon.color = Color.GREEN_YELLOW
	mouse_over = true

func _on_mouse_exited() -> void:
	if not split_vertex:
		if allow_move:
			polygon.color = Color.DIM_GRAY
	else:
		polygon.color = Color.YELLOW_GREEN
	mouse_over = false


func _input(event: InputEvent) -> void:
	if allow_move and event is InputEventKey:
		if drag_started and event.keycode == KEY_ESCAPE and event.pressed:
			if dragging:
				dragging = false
				drag_started = false
				position = start_drag_position
				update_attached_faces()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not event.shift_pressed:
				if allow_move:
					if event.pressed:
						if mouse_over and not split_vertex:
							dragging = true
							dragging_amount = Vector2.ZERO
							drag_started = false
							polygon.color = Color.WHITE
					else:
						if dragging:
							dragging = false
							drag_started = false
							if not split_vertex:
								update_meshes()
								position_finalized.emit(self)
			else:
				if mouse_over:
					start_sector_split.emit(self)
				
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if allow_move:
				if event.pressed and dragging:
					if not split_vertex:
						delete()
			if mouse_over and event.pressed and split_vertex:
				split_face()
	
	if allow_move and event is InputEventMouseMotion and dragging and not split_vertex:
		dragging_amount += event.relative
		if dragging_amount.length() > DRAGGING_THRESHOLD * get_viewport().get_camera_2d().zoom.x or drag_started:
			if drag_started == false:
				drag_started = true
				start_drag_position = position
			var mouse: Vector2 = get_global_mouse_position() + get_parent().get_parent().global_position
			global_position = mouse.snappedf(get_parent().get_parent().snap)
			update_attached_faces()

func delete() -> void:
	print("Delete vertex")
	for sector: Sector in sectors:
		sector.delete_vertex(self)
	vertex_deleted.emit()


func update_attached_faces() -> void:
	var new_coordinate := position * Roth.SCALE_2D_WORLD
	for face: Face in faces:
		if face.v1 == coordinate:
			face.v1 = new_coordinate
		elif face.v2 == coordinate:
			face.v2 = new_coordinate
	coordinate = new_coordinate
	position_updated.emit()


func update_meshes() -> void:
	for sector: Sector in sectors:
		sector._update_vertices()
		sector.initialize_mesh()
	for face: Face in faces:
		if face.sister:
			face.sister.get_ref().initialize_mesh()
			face.sister.get_ref().update_horizontal_fit()
		face.initialize_mesh()
		face.update_horizontal_fit()


func redraw_split_vertex() -> void:
	var face: Face = faces[0]
	position = ((face.v1 + face.v2) / 2) / Roth.SCALE_2D_WORLD


func split_face() -> void:
	var new_faces := []
	for sector: Sector in sectors:
		for face: Face in faces:
			var new_face: Face = await sector.split_face(face)
			if new_face:
				new_faces.append(new_face)
	if len(faces) > 1:
		faces[0].sister = weakref(new_faces[1])
		new_faces[1].sister = weakref(faces[0])
		faces[1].sister = weakref(new_faces[0])
		new_faces[0].sister = weakref(faces[1])
	
	vertex_deleted.emit()
	

class BorderPolygon2D extends Polygon2D:
	var border_color := Color.BLACK
	func _draw() -> void:
		for i in range(len(polygon)):
			draw_line( Vector2(polygon[i].x + offset.x, polygon[i].y + offset.y), Vector2(polygon[(i+1) % (len(polygon))].x + offset.x, polygon[(i+1) % (len(polygon))].y + offset.y), border_color)
