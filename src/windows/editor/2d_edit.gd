extends Node2D

const COLOR_GRID := Color(0.498039, 1, 0.831373, 0.2)
const COLOR_AXIS := Color(1, 0.270588, 0, 0.2)
const ZOOM_SPEED := 0.95
const DRAG_SENSITIVITY := 1
const MAX_ZOOM := 100
const MIN_ZOOM := 0.2

var zoom_toward_mouse := true
var line_width: float = 0.1
var map: Map
var sectors: Array = []
var minimum_x: float = 0
var minimum_y: float = 0
var maximum_x: float = 0
var maximum_y: float = 0
var additional_zoom: float = 1
var has_focus: bool = false
var mouse_drag_enabled: bool = false
var zooming: bool = false
var hovered_sector: Variant = null
var selected_sector: Variant = null
var hovered_face: Variant = null
var selected_face: Variant = null
var holding_mouse: bool = false
var timer: Timer

@onready var grid_size: Vector2 = Vector2.ONE * %GridEdit.value / Roth.SCALE_2D_WORLD

func _ready() -> void:
	timer = Timer.new()
	timer.wait_time = 0.1
	timer.one_shot = true
	timer.timeout.connect(check_for_hover)
	add_child(timer)


func _process(_delta: float) -> void:
	if not has_focus:
		return
	var mouse_x: float = get_global_mouse_position().x + global_position.x
	var mouse_y: float = get_global_mouse_position().y + global_position.y
	%CoordinatesLabel.text = "(%d, %d)" % [mouse_x * Roth.SCALE_2D_WORLD, mouse_y * Roth.SCALE_2D_WORLD]
	%ViewportBorder2.self_modulate.a = 1.0


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("map_2d_zoom_in"):
		additional_zoom /= ZOOM_SPEED
		additional_zoom = clamp(additional_zoom, MIN_ZOOM, MAX_ZOOM)
		zooming = true
		var changed: bool = update_line_width(additional_zoom)
		if changed:
			queue_redraw()
		else:
			update_camera_zoom()
	
	if event.is_action_pressed("map_2d_zoom_out"):
		additional_zoom *= ZOOM_SPEED
		additional_zoom = clamp(additional_zoom, MIN_ZOOM, MAX_ZOOM)
		zooming = true
		var changed: bool = update_line_width(additional_zoom)
		if changed:
			queue_redraw()
		else:
			update_camera_zoom()
	
	if event is InputEventMouseMotion:
		if not hovered_sector:
			if timer.is_stopped():
				timer.start()
		else:
			check_for_hover()
	
	if mouse_drag_enabled:
		if event is InputEventMouseMotion:
			%Camera2D.position.x -= event.relative.x * DRAG_SENSITIVITY / %Camera2D.zoom.x
			%Camera2D.position.y -= event.relative.y * DRAG_SENSITIVITY / %Camera2D.zoom.x
	
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed and hovered_face:
					owner.select_face(hovered_face.index, "Face")
					selected_face = hovered_face
					selected_sector = hovered_sector
					queue_redraw()
				elif event.pressed and hovered_sector:
					owner.select_face(hovered_sector.index, "Sector")
					selected_sector = hovered_sector
					selected_face = null
					queue_redraw()
				if event.pressed:
					holding_mouse = true
				else:
					holding_mouse = false
			MOUSE_BUTTON_MIDDLE:
				if event.pressed:
					mouse_drag_enabled = true
				else:
					mouse_drag_enabled = false
					queue_redraw()
				

func _on_sub_viewport_container_mouse_entered() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		return
	has_focus = true
	%ViewportBorder2.self_modulate.a = 1.0
	%SubViewportContainer2D.grab_focus()


func _on_sub_viewport_container_mouse_exited() -> void:
	has_focus = false
	%ViewportBorder2.self_modulate.a = 0.0


func _draw() -> void:
	draw_grid()
	draw_sectors()
	update_camera_zoom()


func setup(p_map: Map) -> void:
	map = p_map
	sectors = p_map.sectors
	update_bounds()
	update_camera_center()
	update_camera_zoom()
	update_line_width(additional_zoom)
	#queue_redraw()


func update_bounds() -> void:
	minimum_x = 10000
	minimum_y = 10000
	maximum_x = -10000
	maximum_y = -10000
	for sector: Sector in sectors:
		for face_ref: WeakRef in sector.faces:
			var face: Face = face_ref.get_ref()
			minimum_x = min(minimum_x, face.v1.x / Roth.SCALE_2D_WORLD)
			minimum_x = min(minimum_x, face.v2.x / Roth.SCALE_2D_WORLD)
			minimum_y = min(minimum_y, face.v1.y / Roth.SCALE_2D_WORLD)
			minimum_y = min(minimum_y, face.v2.y / Roth.SCALE_2D_WORLD)
			
			maximum_x = max(maximum_x, face.v1.x / Roth.SCALE_2D_WORLD)
			maximum_x = max(maximum_x, face.v2.x / Roth.SCALE_2D_WORLD)
			maximum_y = max(maximum_y, face.v1.y / Roth.SCALE_2D_WORLD)
			maximum_y = max(maximum_y, face.v2.y / Roth.SCALE_2D_WORLD)


func update_camera_center() -> void:
	var center := Vector2(
		(maximum_x + minimum_x) / 2,
		(maximum_y + minimum_y) / 2,
	)
	%Camera2D.position = center


func update_camera_zoom() -> void:
	var size := Vector2(
		maximum_x - minimum_x,
		maximum_y - minimum_y
	)
	if size.x == 0 or size.y == 0:
		return
	
	var zoom_y: float = %Camera2D.get_viewport().size.y / size.y
	var zoom_x: float = %Camera2D.get_viewport().size.x / size.x
	var zoom: float = min(zoom_x, zoom_y) * 0.95
	
	
	var mouse_pos := get_global_mouse_position()
	%Camera2D.zoom = Vector2(zoom, zoom) * additional_zoom
	var new_mouse_pos := get_global_mouse_position()
	if zooming and zoom_toward_mouse:
		%Camera2D.position += mouse_pos - new_mouse_pos
		zooming = false


func update_line_width(x: float) -> bool:
	var prev_line_width: float = line_width
	if %Camera2D.zoom.x > 60:
		line_width =  0.025
	elif %Camera2D.zoom.x > 20:
		line_width =  0.05
	elif %Camera2D.zoom.x > 5:
		line_width =  0.1
	elif %Camera2D.zoom.x > 4:
		line_width =  0.3
	elif %Camera2D.zoom.x > 3:
		line_width =  0.4
	elif %Camera2D.zoom.x > 2:
		line_width =  0.5
	elif %Camera2D.zoom.x > 1.5:
		line_width =  0.8
	elif %Camera2D.zoom.x > 1:
		line_width =  1
	else:
		line_width =  2
	
	return prev_line_width == line_width


func draw_grid() -> void:
	if not %GridCheckBox.button_pressed:
		return
	var camera: Camera2D = %Camera2D
	var viewport: Viewport = camera.get_viewport()
	var vp_size: Vector2i = viewport.size
	var cam_pos := camera.position
	var vp_right := (vp_size.x / camera.zoom.x)
	var vp_bottom := (vp_size.y / camera.zoom.y)
	
	var leftmost: = -vp_right + cam_pos.x
	var topmost: = -vp_bottom + cam_pos.y
	
	var left: float = ceil(leftmost / grid_size.x) * grid_size.x
	var bottommost: = vp_bottom + cam_pos.y
	for x in range(0, ((vp_size.x * 2 / camera.zoom.x) / grid_size.x) + 1):
		draw_line(Vector2(left, topmost), Vector2(left, bottommost), COLOR_AXIS if left == 0 else COLOR_GRID, line_width*0.95, true)
		left += grid_size.x

	var top: float = ceil(topmost / grid_size.y) * grid_size.y
	var rightmost: = vp_right + cam_pos.x
	for y in range(0, ((vp_size.y * 2 / camera.zoom.y) / grid_size.y) + 1):
		draw_line(Vector2(leftmost, top), Vector2(rightmost, top), COLOR_AXIS if top == 0 else COLOR_GRID, line_width*0.95, true)
		top += grid_size.y


func draw_sectors() -> void:
	if not sectors:
		return
	for sector: Sector in sectors:

		for face_ref: WeakRef in sector.faces:
			var face: Face = face_ref.get_ref()
			if face.sister:
				if face.sector.data.floorHeight != face.sister.get_ref().sector.data.floorHeight:
					draw_line(Vector2(face.v1.x/Roth.SCALE_2D_WORLD, face.v1.y/Roth.SCALE_2D_WORLD), Vector2(face.v2.x/Roth.SCALE_2D_WORLD, face.v2.y/Roth.SCALE_2D_WORLD), Color.BLUE, line_width, true)
					
				else:
					draw_line(Vector2(face.v1.x/Roth.SCALE_2D_WORLD, face.v1.y/Roth.SCALE_2D_WORLD), Vector2(face.v2.x/Roth.SCALE_2D_WORLD, face.v2.y/Roth.SCALE_2D_WORLD), Color.STEEL_BLUE, line_width*0.5, true)
			if not face.sister:
				draw_line(Vector2(face.v1.x/Roth.SCALE_2D_WORLD, face.v1.y/Roth.SCALE_2D_WORLD), Vector2(face.v2.x/Roth.SCALE_2D_WORLD, face.v2.y/Roth.SCALE_2D_WORLD), Color.WHITE, line_width, true)
	
	if hovered_sector:
		for face_ref: WeakRef in hovered_sector.faces:
			var face: Face = face_ref.get_ref()
			draw_line(Vector2(face.v1.x/Roth.SCALE_2D_WORLD, face.v1.y/Roth.SCALE_2D_WORLD), Vector2(face.v2.x/Roth.SCALE_2D_WORLD, face.v2.y/Roth.SCALE_2D_WORLD), Color.CORAL, line_width*2, true)
			var direction: Vector2 = (face.v2 - face.v1).normalized()
			var perendicular := Vector2(direction.y, -direction.x)
			
			var v_center := Vector2(
				(face.v1.x + face.v2.x) / 2,
				(face.v1.y + face.v2.y) / 2
			)
			var v_center_2: Vector2 = v_center + perendicular * 10
			draw_line(v_center/Roth.SCALE_2D_WORLD, v_center_2/Roth.SCALE_2D_WORLD, Color.CORAL, line_width*2, true)
	
	if selected_sector:
		for face_ref: WeakRef in selected_sector.faces:
			var face: Face = face_ref.get_ref()
			draw_line(Vector2(face.v1.x/Roth.SCALE_2D_WORLD, face.v1.y/Roth.SCALE_2D_WORLD), Vector2(face.v2.x/Roth.SCALE_2D_WORLD, face.v2.y/Roth.SCALE_2D_WORLD), Color.ORANGE, line_width*2, true)
			var direction: Vector2 = (face.v2 - face.v1).normalized()
			var perendicular := Vector2(direction.y, -direction.x)
			
			var v_center := Vector2(
				(face.v1.x + face.v2.x) / 2,
				(face.v1.y + face.v2.y) / 2
			)
			var v_center_2: Vector2 = v_center + perendicular * 10
			draw_line(v_center/Roth.SCALE_2D_WORLD, v_center_2/Roth.SCALE_2D_WORLD, Color.ORANGE, line_width*2, true)
	
	if hovered_face:
		draw_line(Vector2(hovered_face.v1.x/Roth.SCALE_2D_WORLD, hovered_face.v1.y/Roth.SCALE_2D_WORLD), Vector2(hovered_face.v2.x/Roth.SCALE_2D_WORLD, hovered_face.v2.y/Roth.SCALE_2D_WORLD), Color.WEB_PURPLE, line_width*2, true)
	if selected_face:
		draw_line(Vector2(selected_face.v1.x/Roth.SCALE_2D_WORLD, selected_face.v1.y/Roth.SCALE_2D_WORLD), Vector2(selected_face.v2.x/Roth.SCALE_2D_WORLD, selected_face.v2.y/Roth.SCALE_2D_WORLD), Color.PURPLE, line_width*2, true)


func add_objects() -> void:
	for child: Node in %Objects.get_children():
		child.queue_free()
	for object: ObjectRoth in map.objects:
		%Objects.add_child(object.get_node_2d())


func remove_objects() -> void:
	for child: Node in %Objects.get_children():
		child.queue_free()



func is_mouse_inside(sector: Sector) -> bool:
	var polygon_path_finder := PolygonPathFinder.new()
	var points := sector.vertices.slice(0,-1)
	var connections := []
	for i in range(len(points)-1):
		connections.append(i)
		connections.append(i+1)
	connections.append(len(points)-1)
	connections.append(0)
	polygon_path_finder.setup(points, connections)
	return polygon_path_finder.is_point_inside((get_global_mouse_position() + global_position) * Roth.SCALE_2D_WORLD )


func check_for_hover() -> void:
	if hovered_sector and is_mouse_inside(hovered_sector):
		check_for_face_hover(hovered_sector)
		return
	for sector: Sector in sectors:
		if is_mouse_inside(sector):
			check_for_face_hover(sector)
			if hovered_sector != sector:
				hovered_sector = sector
				if holding_mouse:
					selected_sector = hovered_sector
					owner.select_face(selected_sector.index, "Sector")
				queue_redraw()
			return
	hovered_sector = null
	queue_redraw()

func check_for_face_hover(sector: Sector) -> void:
	var found: bool = false
	var smallest_distance: float = 100.0
	for face_ref: WeakRef in sector.faces:
		var face: Face = face_ref.get_ref()
		var distance: float = distance_to_face((get_global_mouse_position() + global_position) * Roth.SCALE_2D_WORLD, face)
		if distance < smallest_distance and distance < 100 / %Camera2D.zoom.x:
			smallest_distance = distance
			found = true
			if hovered_face != face:
				hovered_face = face
				if holding_mouse:
					selected_face = hovered_face
					owner.select_face(selected_face.index, "Face")
				queue_redraw()
	if not found:
		hovered_face = null
		queue_redraw()

func select(object: Variant) -> void:
	if object is Face:
		selected_face = object
		selected_sector = object.sector
		queue_redraw()
	elif object is Sector:
		selected_sector = object
		selected_face = null
		queue_redraw()
	else:
		selected_face = null
		selected_sector = null
		queue_redraw()
		

func distance_to_face(mouse_position: Vector2, face: Face) -> float:
	var x1: float = face.v1.x
	var y1: float = face.v1.y
	var x2: float = face.v2.x
	var y2: float = face.v2.y

	# Vector from line segment start to end
	var line_vec_x: float = x2 - x1
	var line_vec_y: float = y2 - y1
	var line_length: float = sqrt(line_vec_x * line_vec_x + line_vec_y * line_vec_y)

	# If the line segment has zero length, return distance to either endpoint
	if (line_length == 0):
		return sqrt((mouse_position.x - x1) * (mouse_position.x - x1) + (mouse_position.y - y1) * (mouse_position.y - y1))

	# Calculate projection of mouse_position point onto the line
	var t: float = max(0, min(1, ((mouse_position.x - x1) * line_vec_x + (mouse_position.y - y1) * line_vec_y) / (line_length * line_length)));

	# Find the nearest point on the line segment
	var nearest_x: float = x1 + t * line_vec_x;
	var nearest_y: float = y1 + t * line_vec_y;

	# Return distance to the nearest point
	return sqrt((mouse_position.x - nearest_x) * (mouse_position.x - nearest_x) + (mouse_position.y - nearest_y) * (mouse_position.y - nearest_y));


func _on_grid_check_box_toggled(toggled_on: bool) -> void:
	queue_redraw()
	if toggled_on:
		%GridEdit.editable = true
	else:
		%GridEdit.editable = false


func _on_grid_edit_value_changed(value: float) -> void:
	grid_size = Vector2.ONE * value / Roth.SCALE_2D_WORLD
	queue_redraw()


func _on_sector_check_box_toggled(_toggled_on: bool) -> void:
	queue_redraw()


func _on_object_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		add_objects()
	else:
		remove_objects()
