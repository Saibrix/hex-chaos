extends SceneTree

# Run (windowed): godot --path . --resolution 720x1280 -s res://tests/perf.gd

func _init() -> void:
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.5).timeout
	main.start_game([[0, 1, 2, 3, 4, 5], [0, 1, 2, 3, 4, 5]], -1)
	await create_timer(0.6).timeout
	var gs: GameScreen = main._screen
	var b: BoardView = gs._board
	_report("idle")
	var from := Vector2i.ZERO
	for c in gs.game.pieces:
		if gs.game.pieces[c]["owner"] == 0:
			from = c
			break
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = b._pos(from, b._tile_size())
	b._gui_input(press)
	await process_frame
	await process_frame
	_report("selected")
	var to: Vector2i = b._targets[0]
	gs._on_local_move(from, to)
	for i in 6:
		await process_frame
		_report("moving")
	quit()


func _report(tag: String) -> void:
	print("%s: draw calls %d, objects %d, fps %d, process ms %.2f" % [tag,
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		Performance.get_monitor(Performance.TIME_FPS),
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0])
