class_name BoardView
extends Control

signal move_made(from: Vector2i, to: Vector2i)

const TILE_COLORS := [Color("2a3042"), Color("343b50"), Color("3f4760")]

var game: HexGame
var view_side := 0        # 1 turns the board around so the second player sits at the bottom
var my_side := -1         # which side this device controls, -1 = both (local test)

var _has_sel := false
var _sel := Vector2i.ZERO
var _targets: Array[Vector2i] = []

var _anim_t := 1.0
var _anim_from := Vector2i.ZERO
var _anim_to := Vector2i.ZERO
var _ghost: Dictionary = {}
var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)


func clear_selection() -> void:
	_has_sel = false
	_targets = []
	queue_redraw()


# Call after game.apply(); `captured` is what apply() returned.
func animate_move(from: Vector2i, to: Vector2i, captured: Dictionary) -> void:
	clear_selection()
	_anim_from = from
	_anim_to = to
	_ghost = captured
	_anim_t = 0.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_anim, 0.0, 1.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _set_anim(t: float) -> void:
	_anim_t = t
	queue_redraw()


func _tile_size() -> float:
	var w := size.x / ((2 * Hex.RADIUS + 1) * sqrt(3.0))
	var h := size.y / (3 * Hex.RADIUS + 2)
	return minf(w, h) * 0.97


func _cell(c: Vector2i) -> Vector2i:
	return c if view_side == 0 else -c


func _pos(c: Vector2i, ts: float) -> Vector2:
	return size / 2.0 + Hex.to_pixel(_cell(c), ts)


func _can_act() -> bool:
	return game != null and (my_side == -1 or my_side == game.turn)


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if not _can_act():
		return
	var ts := _tile_size()
	var c := _cell(Hex.from_pixel(event.position - size / 2.0, ts))
	if not Hex.on_board(c):
		clear_selection()
		return
	if game.pieces.has(c) and game.pieces[c]["owner"] == game.turn:
		_has_sel = true
		_sel = c
		_targets = game.legal_moves(c)
		queue_redraw()
	elif _has_sel and c in _targets:
		var from := _sel
		clear_selection()
		move_made.emit(from, c)
	else:
		clear_selection()


func _draw() -> void:
	if game == null:
		return
	var ts := _tile_size()
	for c in Hex.all_cells():
		var p := _pos(c, ts)
		var col: Color = TILE_COLORS[posmod(c.x - c.y, 3)]
		draw_colored_polygon(Hex.corners(p, ts * 0.97), col)

	if not game.last_move.is_empty():
		for c in game.last_move:
			draw_colored_polygon(Hex.corners(_pos(c, ts), ts * 0.97), Color(1, 1, 1, 0.10))

	if _has_sel:
		var pts := Hex.corners(_pos(_sel, ts), ts * 0.97)
		draw_colored_polygon(pts, Color(UI.ACCENT, 0.45))

	# Pieces (the moving one is drawn between its old and new tile).
	for c in game.pieces:
		var piece: Dictionary = game.pieces[c]
		var p := _pos(c, ts)
		if _anim_t < 1.0 and c == _anim_to:
			p = _pos(_anim_from, ts).lerp(_pos(_anim_to, ts), _anim_t)
		_draw_piece(p, ts, piece, 1.0)

	if _anim_t < 1.0 and not _ghost.is_empty():
		_draw_piece(_pos(_anim_to, ts), ts, _ghost, 1.0 - _anim_t)

	for t in _targets:
		var p := _pos(t, ts)
		if game.pieces.has(t):
			draw_arc(p, ts * 0.78, 0.0, TAU, 40, Color("ff5d5d"), maxf(3.0, ts * 0.12))
		else:
			draw_circle(p, ts * 0.2, Color(UI.ACCENT, 0.95))


func _draw_piece(p: Vector2, ts: float, piece: Dictionary, scale_f: float) -> void:
	var r := ts * 0.68 * scale_f
	var col: Color = UI.SIDE_COLORS[piece["owner"]]
	draw_circle(p + Vector2(0, ts * 0.06), r, Color(0, 0, 0, 0.35 * scale_f))
	draw_circle(p, r, col.darkened(0.35))
	draw_circle(p, r * 0.88, col)
	Glyphs.draw(self, Chars.get_char(piece["char"])["glyph"], p, r * 0.5, UI.BG)
