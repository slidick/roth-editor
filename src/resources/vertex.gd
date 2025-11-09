extends Node2D
class_name VertexNode

signal position_updated
signal position_finalized(vertex: VertexNode)
signal vertex_deleted
signal start_sector_split(vertex: VertexNode)
signal vertex_dragged(vertex: VertexNode, relative: Vector2)
signal single_vertex_selected(vertex: VertexNode)
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
var is_selected: bool = false
var face_vertex_move := []
var shape: RectangleShape2D
var initial_zoom: float = 1.0
var map_info: Dictionary = {}

func _init(p_map_info: Dictionary, p_coordinate: Vector2, p_data: Dictionary, p_allow_move: bool, p_initial_zoom: float, p_split_vertex: bool = false) -> void:
	map_info = p_map_info
	coordinate = Vector2(p_coordinate)
	sectors = p_data.sectors
	faces = p_data.faces
	split_vertex = p_split_vertex
	allow_move = p_allow_move
	initial_zoom = p_initial_zoom


func _ready() -> void:
	polygon = BorderPolygon2D.new()
	var draw_size := DRAW_SIZE
	if split_vertex:
		draw_size /= 2
	draw_size *= initial_zoom * 30
	polygon.polygon = [Vector2(-draw_size, -draw_size), Vector2(draw_size, -draw_size), Vector2(draw_size, draw_size), Vector2(-draw_size, draw_size) ]
	if not split_vertex:
		polygon.color = Color.DIM_GRAY
	else:
		polygon.color = Color.YELLOW_GREEN
		draw_size *= 2
	add_child(polygon)
	position.x = coordinate.x / Roth.SCALE_2D_WORLD
	position.y = coordinate.y / Roth.SCALE_2D_WORLD
	shape = RectangleShape2D.new()
	shape.size.x = draw_size * 2
	shape.size.y = draw_size * 2
	var collision := CollisionShape2D.new()
	collision.shape = shape
	var area := Area2D.new()
	area.add_child(collision)
	area.mouse_entered.connect(_on_mouse_entered)
	area.mouse_exited.connect(_on_mouse_exited)
	add_child(area)


func redraw(p_zoom_level: float) -> void:
	var draw_size := DRAW_SIZE
	if split_vertex:
		draw_size /= 2
	draw_size *= p_zoom_level * 30
	polygon.polygon = [Vector2(-draw_size, -draw_size), Vector2(draw_size, -draw_size), Vector2(draw_size, draw_size), Vector2(-draw_size, draw_size) ]
	if split_vertex:
		draw_size *= 2
	shape.size.x = draw_size * 2
	shape.size.y = draw_size * 2


func _on_mouse_entered() -> void:
	if not split_vertex:
		if allow_move and not is_selected:
			polygon.color = Color.GRAY
	else:
		polygon.color = Color.GREEN_YELLOW
	mouse_over = true

func _on_mouse_exited() -> void:
	if not split_vertex:
		if allow_move and not is_selected:
			polygon.color = Color.DIM_GRAY
	else:
		polygon.color = Color.YELLOW_GREEN
	mouse_over = false


func _input(event: InputEvent) -> void:
	if allow_move and event is InputEventKey:
		if drag_started and event.keycode == KEY_ESCAPE and event.pressed:
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
							if not is_selected:
								is_selected = true
								single_vertex_selected.emit(self)
							
					else:
						if dragging:
							dragging = false
							
							if not split_vertex:
								update_meshes()
								if drag_started:
									position_finalized.emit(self)
							drag_started = false
			else:
				if mouse_over and event.pressed:
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
				face_vertex_move = []
				for face: Face in faces:
					if face.v1 == coordinate:
						face_vertex_move.append("v1")
					elif face.v2 == coordinate:
						face_vertex_move.append("v2")
						
			var mouse: Vector2 = get_global_mouse_position() + get_parent().get_parent().global_position
			var relative: Vector2 = global_position - mouse.snappedf(get_parent().get_parent().snap)
			global_position -= relative
			vertex_dragged.emit(self, relative)
			update_attached_faces()

func delete() -> void:
	print("Delete vertex")
	for sector: Sector in sectors:
		sector.delete_vertex(self)
	vertex_deleted.emit()

func select() -> void:
	is_selected = true
	polygon.color = Color.WHITE

func deselect() -> void:
	is_selected = false
	polygon.color = Color.DIM_GRAY

func toggle_selected() -> void:
	if is_selected:
		deselect()
	else:
		select()


func move(relative: Vector2) -> void:
	if is_selected:
		if drag_started == false:
			drag_started = true
			start_drag_position = position
			face_vertex_move = []
			for face: Face in faces:
				if face.v1 == coordinate:
					face_vertex_move.append("v1")
				elif face.v2 == coordinate:
					face_vertex_move.append("v2")
		global_position -= relative
		update_attached_faces()

func finalize_move() -> void:
	if is_selected:
		drag_started = false
		update_meshes()

func update_attached_faces() -> void:
	var new_coordinate := position * Roth.SCALE_2D_WORLD
	var dont_update: bool = false
	var i: int = 0
	for face: Face in faces:
		if face.v1 == coordinate and face_vertex_move[i] == "v1":
			face.v1 = new_coordinate
		elif face.v2 == coordinate and face_vertex_move[i] == "v2":
			face.v2 = new_coordinate
		i += 1
	if not dont_update:
		coordinate = Vector2(new_coordinate)
		position_updated.emit()


func update_meshes() -> void:
	for sector: Sector in sectors:
		sector._update_vertices()
		sector.initialize_mesh()
	for face: Face in faces:
		if face.sister:
			face.sister.get_ref().update_horizontal_fit()
			face.sister.get_ref().initialize_mesh()
		face.update_horizontal_fit()
		face.initialize_mesh()


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
		faces[0].initialize_mesh()
		faces[1].initialize_mesh()
		new_faces[0].initialize_mesh()
		new_faces[1].initialize_mesh()
	
	vertex_deleted.emit()
	Roth.editor_action.emit(map_info, "Split Face")


class BorderPolygon2D extends Polygon2D:
	var border_color := Color.BLACK
	func _draw() -> void:
		for i in range(len(polygon)):
			draw_line( Vector2(polygon[i].x + offset.x, polygon[i].y + offset.y), Vector2(polygon[(i+1) % (len(polygon))].x + offset.x, polygon[(i+1) % (len(polygon))].y + offset.y), border_color)
