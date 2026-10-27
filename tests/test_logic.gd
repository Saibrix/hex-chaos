extends SceneTree

# Run: godot --headless --path . -s res://tests/test_logic.gd

var fails := 0


func check(cond: bool, what: String) -> void:
	if cond:
		print("ok   ", what)
	else:
		print("FAIL ", what)
		fails += 1


func _init() -> void:
	check(Hex.all_cells().size() == 91, "radius 5 board has 91 tiles")
	check(Hex.knight_jumps().size() == 12, "12 knight jumps")
	for j in Hex.knight_jumps():
		if Hex.dist(j) != 3:
			check(false, "knight jump %s has distance 3" % j)
	for c in Hex.all_cells():
		var back := Hex.from_pixel(Hex.to_pixel(c, 40.0), 40.0)
		if back != c:
			check(false, "pixel round trip for %s" % c)
	check(true, "pixel round trip")

	var g := HexGame.new()
	g.setup([[0, 1, 2, 3, 4, 5], [0, 1, 2, 3, 4, 5]])
	check(g.pieces.size() == 12, "12 pieces placed")
	check(g.count(0) == 6 and g.count(1) == 6, "6 pieces per side")
	check(g.pieces[Vector2i(-5, 5)]["owner"] == 0 and g.pieces[Vector2i(5, -5)]["owner"] == 1, "sides on opposite corners")

	# fewer pieces are centred in the edge row
	var g2 := HexGame.new()
	g2.setup([[0, 1], [0, 1, 2]])
	check(g2.count(0) == 2 and g2.count(1) == 3, "small teams place correctly")
	for c in g2.pieces:
		check(Hex.on_board(c), "piece %s on board" % c)

	# capture: charger jumps onto an enemy
	var t := HexGame.new()
	t.setup([[1], [0]])
	t.pieces.clear()
	t.pieces[Vector2i(0, 3)] = {"owner": 0, "char": 1}
	t.pieces[Vector2i(0, -2)] = {"owner": 1, "char": 0}
	t.pieces[Vector2i(0, 1)] = {"owner": 0, "char": 0}
	check(not t.can_move(Vector2i(0, 3), Vector2i(0, -2)), "slider cannot pass own piece")
	t.pieces.erase(Vector2i(0, 1))
	check(t.can_move(Vector2i(0, 3), Vector2i(0, -2)), "slider can capture along a line")
	check(not t.can_move(Vector2i(0, 3), Vector2i(0, -3)), "slider stops at the first enemy")
	var cap := t.apply(Vector2i(0, 3), Vector2i(0, -2))
	check(not cap.is_empty() and t.count(1) == 0, "enemy removed on capture")
	check(t.turn == 1, "turn passes after a move")
	check(not t.can_move(Vector2i(0, -2), Vector2i(0, 0)), "cannot move on the other side's turn")

	# jumpers ignore blockers
	var j := HexGame.new()
	j.setup([[3], [0]])
	j.pieces.clear()
	j.pieces[Vector2i(0, 0)] = {"owner": 0, "char": 3}
	for d in Hex.DIRS:
		j.pieces[d] = {"owner": 0, "char": 0}
	check(j.legal_moves(Vector2i(0, 0)).size() == 12, "hopper jumps over a ring of pieces")
	j.pieces.clear()
	j.pieces[Vector2i(0, 0)] = {"owner": 0, "char": 5}
	check(j.legal_moves(Vector2i(0, 0)).size() == 6, "leaper has 6 leaps from the centre")

	print("DONE, failures: ", fails)
	quit(1 if fails > 0 else 0)
