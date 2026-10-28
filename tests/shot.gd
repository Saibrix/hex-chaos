extends SceneTree

# Run (windowed, needs a GPU): godot --path . --resolution 720x1280 -s res://tests/shot.gd -- <out dir>

func _init() -> void:
	var out := OS.get_cmdline_user_args()[0]
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.5).timeout
	main.start_game([[0, 1, 2, 3, 4, 5], [0, 1, 2, 3, 4, 5]], -1)
	await create_timer(0.6).timeout
	root.get_texture().get_image().save_png(out + "/1_start.png")
	var gs: GameScreen = main._screen
	var b: BoardView = gs._board
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
	press.pressed = false
	b._gui_input(press)
	await create_timer(0.4).timeout
	root.get_texture().get_image().save_png(out + "/2_selected.png")
	var to: Vector2i = b._targets[0]
	gs._on_local_move(from, to)
	await create_timer(0.12).timeout
	root.get_texture().get_image().save_png(out + "/3_moving.png")
	await create_timer(1.0).timeout
	root.get_texture().get_image().save_png(out + "/4_after.png")
	quit()
