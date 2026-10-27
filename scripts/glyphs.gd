class_name Glyphs

# Simple shapes that identify a character, drawn in code so no art files are needed.


static func draw(ci: CanvasItem, glyph: String, c: Vector2, r: float, col: Color) -> void:
	match glyph:
		"circle":
			ci.draw_circle(c, r * 0.8, col)
		"square":
			ci.draw_rect(Rect2(c - Vector2(r, r) * 0.7, Vector2(r, r) * 1.4), col)
		"diamond":
			ci.draw_colored_polygon(_poly(c, r * 1.05, 4, 0.0), col)
		"hexagon":
			ci.draw_colored_polygon(_poly(c, r * 0.95, 6, 0.0), col)
		"triangle":
			ci.draw_colored_polygon(_poly(c, r * 1.05, 3, -PI / 2.0), col)
		"star":
			ci.draw_colored_polygon(_star(c, r * 1.1, r * 0.5, 5), col)


static func _poly(c: Vector2, r: float, n: int, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := rot + TAU * i / n
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


static func _star(c: Vector2, ro: float, ri: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n * 2:
		var a := -PI / 2.0 + PI * i / n
		var rad := ro if i % 2 == 0 else ri
		pts.append(c + Vector2(cos(a), sin(a)) * rad)
	return pts
