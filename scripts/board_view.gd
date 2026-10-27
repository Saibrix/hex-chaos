class_name BoardView
extends Control

signal move_made(from: Vector2i, to: Vector2i)

# Warm wood tones, three shades so neighbouring tiles never match.
const TILE_COLORS := [Color("e3bc83"), Color("c99a5f"), Color("b07f48")]
const FRAME_COLOR := Color("4b2f1c")
const DRAG_THRESHOLD := 10.0

var game: HexGame
var view_side := 0        # 1 turns the board around so the second player sits at the bottom
var my_side := -1         # which side this device controls, -1 = both (local test)

var _has_sel := false
var _sel := Vector2i.ZERO
var _targets: Array[Vector2i] = []

# Press / drag state
var _pressing := false
var _press_pos := Vector2.ZERO
var _press_was_selected := false
var _dragging := false
var _drag_pos := Vector2.ZERO
var _drop_px := Vector2.INF

var _anim_t := 1.0
var _anim_from := Vector2i.ZERO
var _anim_from_px := Vector2.INF
var _anim_to := Vector2i.ZERO
var _ghost: Dictionary = {}
var _tween: Tween

var _time := 0.0
var _shake := 0.0
var _particles: Array[Dictionary] = []
var _rings: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)


func clear_selection() -> void:
	_has_sel = false
	_targets = []
	_dragging = false
	_pressing = false
	queue_redraw()


# Call after game.apply(); `captured` is what apply() returned.
func animate_move(from: Vector2i, to: Vector2i, captured: Dictionary) -> void:
	clear_selection()
	_anim_from = from
	_anim_from_px = _drop_px
	_drop_px = Vector2.INF
	_anim_to = to
	_ghost = captured
	_anim_t = 0.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_anim, 0.0, 1.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(_on_landed.bind(to, captured))


func _set_anim(t: float) -> void:
	_anim_t = t
	queue_redraw()


func _on_landed(to: Vector2i, captured: Dictionary) -> void:
	var ts := _tile_size()
	var p := _pos(to, ts)
	_rings.append({"p": p, "t": 0.0, "col": Color(1, 1, 1, 0.55), "max": ts * 1.3, "life": 0.35})
	for i in 6:
		_spawn_particle(p, Color(1, 1, 1, 0.5), ts * 0.5, 0.35, ts * 0.07)
	if not captured.is_empty():
		var col: Color = UI.SIDE_COLORS[captured["owner"]]
		_rings.append({"p": p, "t": 0.0, "col": Color(col, 0.9), "max": ts * 2.2, "life": 0.5})
		for i in 26:
			_spawn_particle(p, col.lightened(randf() * 0.3), ts * 2.6, 0.7, ts * 0.13)
		_shake = ts * 0.22
	set_process(true)


func _spawn_particle(p: Vector2, col: Color, speed: float, life: float, psize: float) -> void:
	var a := randf() * TAU
	var v := Vector2(cos(a), sin(a)) * speed * randf_range(0.35, 1.0)
	_particles.append({"p": p, "v": v, "life": life * randf_range(0.6, 1.0), "max": life, "col": col, "s": psize * randf_range(0.6, 1.0)})


func _process(delta: float) -> void:
	_time += delta
	for pt in _particles:
		pt["p"] += pt["v"] * delta
		pt["v"] *= pow(0.02, delta)
		pt["life"] -= delta
	_particles = _particles.filter(func(pt): return pt["life"] > 0.0)
	for r in _rings:
		r["t"] += delta / r["life"]
	_rings = _rings.filter(func(r): return r["t"] < 1.0)
	_shake = maxf(0.0, _shake - delta * size.y * 0.6)
	if _has_sel or _dragging or _shake > 0.0 or not _particles.is_empty() or not _rings.is_empty():
		queue_redraw()


func _tile_size() -> float:
	var w := size.x / ((2 * Hex.RADIUS + 1) * sqrt(3.0))
	var h := size.y / (3 * Hex.RADIUS + 2)
	return minf(w, h) * 0.95


func _cell(c: Vector2i) -> Vector2i:
	return c if view_side == 0 else -c


func _pos(c: Vector2i, ts: float) -> Vector2:
	return size / 2.0 + Hex.to_pixel(_cell(c), ts)


func _can_act() -> bool:
	return game != null and (my_side == -1 or my_side == game.turn)


func _tile_at(pos: Vector2) -> Vector2i:
	return _cell(Hex.from_pixel(pos - size / 2.0, _tile_size()))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_on_press(event.position)
		else:
			_on_release(event.position)
	elif event is InputEventMouseMotion and _pressing:
		_drag_pos = event.position
		if _has_sel and not _dragging and event.position.distance_to(_press_pos) > DRAG_THRESHOLD:
			_dragging = true
		if _dragging:
			queue_redraw()


func _on_press(pos: Vector2) -> void:
	if not _can_act():
		return
	var c := _tile_at(pos)
	_press_pos = pos
	_drag_pos = pos
	_pressing = false
	_dragging = false
	if not Hex.on_board(c):
		clear_selection()
		return
	if game.pieces.has(c) and game.pieces[c]["owner"] == game.turn:
		_press_was_selected = _has_sel and _sel == c
		_has_sel = true
		_sel = c
		_targets = game.legal_moves(c)
		_pressing = true
		queue_redraw()
	elif _has_sel and c in _targets:
		var from := _sel
		clear_selection()
		move_made.emit(from, c)
	else:
		clear_selection()


func _on_release(pos: Vector2) -> void:
	if not _pressing:
		return
	var was_dragging := _dragging
	_pressing = false
	_dragging = false
	if was_dragging:
		var c := _tile_at(pos)
		if Hex.on_board(c) and c in _targets:
			var from := _sel
			_drop_px = pos
			clear_selection()
			move_made.emit(from, c)
			return
		queue_redraw()      # dropped somewhere illegal: piece snaps back, stays selected
	elif _press_was_selected:
		clear_selection()   # tapped the selected piece again


func _draw() -> void:
	if game == null:
		return
	var ts := _tile_size()
	if _shake > 0.0:
		draw_set_transform(Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake)

	var cells := Hex.all_cells()
	# Wooden frame and drop shadow.
	for c in cells:
		draw_colored_polygon(Hex.corners(_pos(c, ts) + Vector2(0, ts * 0.18), ts * 1.1), Color(0, 0, 0, 0.18))
	for c in cells:
		draw_colored_polygon(Hex.corners(_pos(c, ts), ts * 1.07), FRAME_COLOR)
	for c in cells:
		var p := _pos(c, ts)
		var col: Color = TILE_COLORS[posmod(c.x - c.y, 3)]
		var pts := Hex.corners(p, ts * 0.96)
		draw_colored_polygon(pts, col)
		# soft top light and bottom shade give the tiles a little depth
		draw_polyline(PackedVector2Array([pts[3], pts[4], pts[5]]), Color(1, 1, 1, 0.22), maxf(1.5, ts * 0.05), true)
		draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2]]), Color(0, 0, 0, 0.2), maxf(1.5, ts * 0.05), true)

	if not game.last_move.is_empty():
		for c in game.last_move:
			draw_colored_polygon(Hex.corners(_pos(c, ts), ts * 0.96), Color(1, 0.95, 0.5, 0.22))

	var pulse := 0.5 + 0.5 * sin(_time * 5.0)
	if _has_sel:
		draw_colored_polygon(Hex.corners(_pos(_sel, ts), ts * 0.96), Color(UI.ACCENT, 0.5 + 0.15 * pulse))

	# Move hints under the pieces so capture rings don't hide them.
	for t in _targets:
		var p := _pos(t, ts)
		if not game.pieces.has(t):
			draw_circle(p, ts * (0.2 + 0.03 * pulse), Color(UI.ACCENT.darkened(0.2), 0.95))
			draw_arc(p, ts * 0.27, 0.0, TAU, 24, Color(1, 1, 1, 0.6), 1.5, true)

	# Pieces (the moving one is drawn between its old and new tile).
	var drag_cell := _sel if _dragging else Vector2i(9999, 9999)
	for c in game.pieces:
		if c == drag_cell:
			continue
		var piece: Dictionary = game.pieces[c]
		var p := _pos(c, ts)
		var lift := 0.0
		if _anim_t < 1.0 and c == _anim_to:
			var from_p := _pos(_anim_from, ts) if _anim_from_px == Vector2.INF else _anim_from_px
			p = from_p.lerp(_pos(_anim_to, ts), _anim_t)
			lift = sin(_anim_t * PI) * ts * 0.35
		_draw_piece(p - Vector2(0, lift), ts, piece, 1.0, lift)

	if _anim_t < 1.0 and not _ghost.is_empty():
		_draw_piece(_pos(_anim_to, ts), ts, _ghost, 1.0 - _anim_t, 0.0)

	for t in _targets:
		if game.pieces.has(t):
			var p := _pos(t, ts)
			draw_arc(p, ts * (0.8 + 0.04 * pulse), 0.0, TAU, 40, Color("ff4d4d"), maxf(3.0, ts * 0.12), true)

	for r in _rings:
		var k: float = r["t"]
		var col: Color = r["col"]
		col.a *= 1.0 - k
		draw_arc(r["p"], lerpf(ts * 0.3, r["max"], 1.0 - pow(1.0 - k, 2.0)), 0.0, TAU, 36, col, maxf(2.0, ts * 0.12) * (1.0 - k), true)
	for pt in _particles:
		var col: Color = pt["col"]
		col.a *= clampf(pt["life"] / pt["max"], 0.0, 1.0)
		draw_circle(pt["p"], pt["s"] * (0.4 + 0.6 * pt["life"] / pt["max"]), col)

	if _dragging:
		_draw_piece(_drag_pos - Vector2(0, ts * 0.45), ts * 1.12, game.pieces[_sel], 1.0, ts * 0.45)
		var hover := _tile_at(_drag_pos)
		if hover in _targets:
			draw_arc(_pos(hover, ts), ts * 0.9, 0.0, TAU, 6, Color(1, 1, 1, 0.9), 2.5, true)

	draw_set_transform(Vector2.ZERO)


func _draw_piece(p: Vector2, ts: float, piece: Dictionary, scale_f: float, lift: float) -> void:
	var r := ts * 0.68 * scale_f
	var col: Color = UI.SIDE_COLORS[piece["owner"]]
	draw_circle(p + Vector2(0, ts * 0.08 + lift), r * (1.0 - lift / ts * 0.25), Color(0, 0, 0, 0.32 * scale_f))
	draw_circle(p, r, col.darkened(0.4))
	draw_circle(p + Vector2(0, -r * 0.04), r * 0.9, col)
	draw_circle(p + Vector2(-r * 0.22, -r * 0.3), r * 0.42, Color(1, 1, 1, 0.16 * scale_f))
	Glyphs.draw(self, Chars.get_char(piece["char"])["glyph"], p, r * 0.5, UI.BG)
