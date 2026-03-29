class_name ColorRectButton
extends ColorRect

var index: int = -1
var palette_index: int = -1
var border: ColorRect
var border_selected: ColorRect
var hovered: bool = false :
	set(p_hovered):
		hovered = p_hovered
		queue_redraw()
var selected: bool = false :
	set(p_selected):
		selected = p_selected
		queue_redraw()
var original_color: Color
var hue_start_color: Color

func _ready() -> void:
	border = ColorRect.new()
	border.color = Color.WEB_GRAY
	border.anchor_left = 0
	border.anchor_top = 0
	border.anchor_right = 1
	border.anchor_bottom = 1
	border.offset_left = -2
	border.offset_top = -2
	border.offset_right = 2
	border.offset_bottom = 2
	border.show_behind_parent = true
	border.visible = false
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(border)
	border_selected = ColorRect.new()
	border_selected.color = Color.WHITE_SMOKE
	border_selected.anchor_left = 0
	border_selected.anchor_top = 0
	border_selected.anchor_right = 1
	border_selected.anchor_bottom = 1
	border_selected.offset_left = -2
	border_selected.offset_top = -2
	border_selected.offset_right = 2
	border_selected.offset_bottom = 2
	border_selected.show_behind_parent = true
	border_selected.visible = false
	border_selected.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(border_selected)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _draw() -> void:
	if selected:
		border_selected.visible = true
		border.visible = false
	elif hovered:
		border_selected.visible = false
		border.visible = true
	else:
		border_selected.visible = false
		border.visible = false


func _on_mouse_entered() -> void:
	hovered = true
	queue_redraw()


func _on_mouse_exited() -> void:
	hovered = false
	queue_redraw()
