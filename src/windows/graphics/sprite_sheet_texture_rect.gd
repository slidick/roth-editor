extends TextureRect

var rows: int = 1
var columns: int = 4

func _draw() -> void:
	if texture:
		var color := Color.WHITE
		
		var y: float =  size.y/2.0 - texture.get_height()/2.0
		var y_jump: float = texture.get_height()/float(rows)
		var x: float = 0
		var x_jump: float = texture.get_width()/float(columns)
		
		if expand_mode == TextureRect.EXPAND_FIT_WIDTH:
			y = size.y/2.0 - (texture.get_height()*(size.x / texture.get_width())/2.0)
			y_jump *= size.x / texture.get_width()
			x_jump *= size.x / texture.get_width()
		
		for i in range(rows+1):
			draw_line(Vector2(0, y+y_jump*i), Vector2(x+x_jump*columns, y+y_jump*i), color)
		
		for i in range(columns+1):
			draw_line(Vector2(x+x_jump*i, y), Vector2(x+x_jump*i, y+y_jump*rows), color)
		
