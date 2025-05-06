extends Camera3D

## Configurable values for the camera including default speed and sensitivity
@export_range(0, 10, 0.01) var sensitivity : float = 3
@export_range(0, 1000, 0.1) var default_velocity : float = 5
@export_range(0, 10, 0.01) var speed_scale : float = 1.08
@export_range(1, 100, 0.1) var boost_speed_multiplier : float = 1.8
@export var max_speed : float = 1000
@export var min_speed : float = 0.2

@export var camera_left := "camera_left"
@export var camera_right := "camera_right"
@export var camera_down := "camera_down"
@export var camera_up := "camera_up"
@export var camera_forward := "camera_forward"
@export var camera_backward := "camera_backward"
@export var camera_boost := "camera_boost"

@export var has_focus: bool = false


@onready var _velocity: float = default_velocity

func _process(delta: float) -> void:
	if not current or not has_focus:
		return
	
	var direction := Vector3(
		Input.get_axis(camera_left, camera_right),
		Input.get_axis(camera_down, camera_up), 
		Input.get_axis(camera_forward, camera_backward)
	).normalized()
	
	if not Vector3.ZERO.is_equal_approx(direction):
		if Input.is_action_pressed(camera_boost): # boost
			translate(direction * _velocity * delta * boost_speed_multiplier)
		else:
			translate(direction * _velocity * delta)
	
	if get_node_or_null("%PositionLabel"):
		%PositionLabel.text = "(%d, %d)" % [global_position.x * Roth.SCALE_3D_WORLD, global_position.z * Roth.SCALE_3D_WORLD]


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_mouse_capture"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_VISIBLE)
		get_viewport().warp_mouse(Vector2(get_viewport().size / 2))
		%SubViewportContainer.grab_focus()
	
	if not current or not has_focus:
		return
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotation.y -= event.relative.x / 1000 * sensitivity
			rotation.x -= event.relative.y / 1000 * sensitivity
			rotation.x = clamp(rotation.x, PI/-2, PI/2)
			get_viewport().warp_mouse(Vector2(get_viewport().size / 2))
	
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE)
				get_viewport().warp_mouse(Vector2(get_viewport().size / 2))
			MOUSE_BUTTON_WHEEL_UP: # increase fly velocity
				_velocity = clamp(_velocity * speed_scale, min_speed, max_speed)
			MOUSE_BUTTON_WHEEL_DOWN: # decrease fly velocity
				_velocity = clamp(_velocity / speed_scale, min_speed, max_speed)
