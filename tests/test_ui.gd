extends SceneTree

# Run: godot --headless --path . -s res://tests/test_ui.gd

func _init() -> void:
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	root.size = Vector2i(1280, 720)
	await process_frame
	await process_frame
	print("menu: ", main._screen is MenuScreen)

	main.show_loadout()
	await process_frame
	await process_frame
	var lo: LoadoutScreen = main._screen
	lo._on_card_toggled(false, lo._cards[0])
	print("loadout size after deselect: ", main.loadout.size())
	lo._on_card_toggled(true, lo._cards[0])

	main.start_game([[1, 0], [0, 4]], -1)
	await process_frame
	await process_frame
	var gs: GameScreen = main._screen
	var b: BoardView = gs._board
	b.size = Vector2(1000, 600)
	# player 0: charger at (-3? ) find a legal move through real input path
	var from := Vector2i.ZERO
	for c in gs.game.pieces:
		if gs.game.pieces[c]["owner"] == 0 and gs.game.pieces[c]["char"] == 1:
			from = c
	var ts := b._tile_size()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = b.size / 2.0 + Hex.to_pixel(from, ts)
	b._gui_input(press)
	print("targets after select: ", b._targets.size())
	var to := Vector2i(from.x, from.y - 3)
	press.position = b.size / 2.0 + Hex.to_pixel(to, ts)
	b._gui_input(press)
	await process_frame
	print("turn now: ", gs.game.turn, "  moved: ", gs.game.pieces.has(to))

	# capture: put an enemy in line and take it
	gs.game.pieces[Vector2i(to.x, to.y - 2)] = {"owner": 1, "char": 0}
	gs.game.turn = 0
	ts = b._tile_size()   # the container re-laid out the board after the first frame
	b._gui_input(_click(b, to, ts))
	print("second select: ", b._has_sel, " ", b._sel, " targets ", b._targets, " enemy at ", Vector2i(to.x, to.y - 2))
	b._gui_input(_click(b, Vector2i(to.x, to.y - 2), ts))
	await process_frame
	print("enemy count after capture: ", gs.game.count(1), " (was 2)")

	gs._pause_layer.show()
	await process_frame
	print("pause visible: ", gs._pause_layer.visible)
	print("UI DONE")
	quit()


func _click(b: BoardView, c: Vector2i, ts: float) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = b.size / 2.0 + Hex.to_pixel(c, ts)
	return e

