class_name Backdrop
extends Control

# Dark gradient with a few faint hexagons drifting by.

const TOP := Color("1d2236")
const BOTTOM := Color("0b0d13")

var _t := 0.0
var _hexes: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.fill(self)
	for i in 9:
		_hexes.append({"x": randf(), "y": randf(), "r": randf_range(60.0, 180.0), "s": randf_range(0.004, 0.012), "a": randf() * TAU,
			"c": UI.SIDE_COLORS[i % 2]})


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]),
		PackedColorArray([TOP, TOP, BOTTOM, BOTTOM]))
	for h in _hexes:
		var y := fposmod(h["y"] - _t * h["s"], 1.2) - 0.1
		var p := Vector2(h["x"] * size.x, y * size.y)
		var pts := Hex.corners(p, h["r"])
		var c: Color = h["c"]
		draw_colored_polygon(pts, Color(c, 0.035))
		pts.append(pts[0])
		draw_polyline(pts, Color(c, 0.12), 2.0, true)
