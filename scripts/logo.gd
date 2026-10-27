class_name Logo
extends Control

# Small cluster of seven hexagons, teal and coral, drawn in code.

func _init() -> void:
	custom_minimum_size = Vector2(0, 190)


func _draw() -> void:
	var ts := 30.0
	var mid := size / 2.0
	var cells: Array[Vector2i] = [Vector2i.ZERO]
	cells.append_array(Hex.DIRS)
	for c in cells:
		var p := mid + Hex.to_pixel(c, ts)
		var col: Color = UI.SIDE_COLORS[0] if (c.x - c.y) % 2 == 0 else UI.SIDE_COLORS[1]
		if c == Vector2i.ZERO:
			col = UI.ACCENT
		draw_colored_polygon(Hex.corners(p + Vector2(0, 4), ts * 0.94), Color(0, 0, 0, 0.3))
		draw_colored_polygon(Hex.corners(p, ts * 0.94), col.darkened(0.15))
		draw_colored_polygon(Hex.corners(p - Vector2(0, 2), ts * 0.8), col)
