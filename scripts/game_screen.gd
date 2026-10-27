class_name GameScreen
extends Control

signal leave_pressed

var game := HexGame.new()
var my_side := -1          # -1 = local test, both sides on this device
var link: Link

var _board: BoardView
var _turn_label: Label
var _count_label: Label
var _pause_layer: Control
var _over_layer: Control


func setup(teams: Array, side: int, the_link: Link) -> void:
	my_side = side
	link = the_link
	game.setup(teams)


func _ready() -> void:
	UI.fill(self)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	add_child(UI.margin(col, 16))

	var top := HBoxContainer.new()
	col.add_child(top)
	_turn_label = UI.label("", 34)
	_turn_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_turn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(_turn_label)
	var pause := UI.button("Pause", Vector2(150, 60))
	pause.pressed.connect(func(): _pause_layer.show())
	top.add_child(pause)

	_board = BoardView.new()
	_board.game = game
	_board.my_side = my_side
	_board.view_side = 1 if my_side == 1 else 0
	_board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board.move_made.connect(_on_local_move)
	col.add_child(_board)

	_count_label = UI.label("", 22, UI.MUTED)
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_count_label)

	_pause_layer = _make_overlay("Paused", [
		["Resume", func(): _pause_layer.hide()],
		["Leave game", _leave],
	])
	_over_layer = _make_overlay("Opponent left the game", [
		["Back to menu", func(): leave_pressed.emit()],
	])
	_refresh()


func _make_overlay(title: String, buttons: Array) -> Control:
	var layer := ColorRect.new()
	layer.color = Color(0, 0, 0, 0.7)
	UI.fill(layer)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.hide()
	var center := CenterContainer.new()
	UI.fill(center)
	layer.add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(380, 0)
	box.add_theme_constant_override("separation", 16)
	center.add_child(box)
	var t := UI.label(title, 48)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(t)
	for b in buttons:
		var btn := UI.button(b[0])
		btn.pressed.connect(b[1])
		box.add_child(btn)
	add_child(layer)
	return layer


func _leave() -> void:
	if link and link.connected:
		link.send({"t": "leave"})
	leave_pressed.emit()


func _on_local_move(from: Vector2i, to: Vector2i) -> void:
	if not game.can_move(from, to):
		return
	if link and link.connected:
		link.send({"t": "move", "from": [from.x, from.y], "to": [to.x, to.y]})
	_do_move(from, to)


func _do_move(from: Vector2i, to: Vector2i) -> void:
	var captured := game.apply(from, to)
	_board.animate_move(from, to, captured)
	_refresh()


# Messages from the other phone while a game is running.
func on_message(data: Dictionary) -> void:
	match data.get("t", ""):
		"move":
			var f = data.get("from", [])
			var t = data.get("to", [])
			if f.size() != 2 or t.size() != 2:
				return
			var from := Vector2i(int(f[0]), int(f[1]))
			var to := Vector2i(int(t[0]), int(t[1]))
			if game.turn != my_side and game.can_move(from, to):
				_do_move(from, to)
		"leave":
			show_opponent_left()


func show_opponent_left() -> void:
	_pause_layer.hide()
	_over_layer.show()


func _refresh() -> void:
	var name_of := ["Teal", "Coral"]
	if my_side == -1:
		_turn_label.text = "%s's turn" % name_of[game.turn]
	elif game.turn == my_side:
		_turn_label.text = "Your turn"
	else:
		_turn_label.text = "Opponent's turn"
	_turn_label.add_theme_color_override("font_color", UI.SIDE_COLORS[game.turn])
	_count_label.text = "%s pieces: %d     %s pieces: %d" % [name_of[0], game.count(0), name_of[1], game.count(1)]
