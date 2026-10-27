class_name Chars

# Placeholder roster. Each character differs only in how it moves for now.
# "kind": step = single steps, slide = any distance until blocked, jump = fixed offsets.

const LIST := [
	{"id": 0, "name": "Grunt", "glyph": "circle", "kind": "step",
		"desc": "Steps one tile in any of the 6 directions."},
	{"id": 1, "name": "Charger", "glyph": "square", "kind": "slide",
		"desc": "Slides any distance along the 6 straight lines."},
	{"id": 2, "name": "Glider", "glyph": "diamond", "kind": "slide",
		"desc": "Slides any distance along the 6 diagonals."},
	{"id": 3, "name": "Hopper", "glyph": "hexagon", "kind": "jump",
		"desc": "Jumps like a knight, over other pieces."},
	{"id": 4, "name": "Warlord", "glyph": "star", "kind": "slide",
		"desc": "Slides along all 12 lines."},
	{"id": 5, "name": "Leaper", "glyph": "triangle", "kind": "jump",
		"desc": "Leaps exactly two tiles in a straight line, over pieces."},
]

const TEAM_MAX := 6


static func get_char(id: int) -> Dictionary:
	return LIST[id]


# All destinations the piece could reach, ignoring whose turn it is.
# `occupied` maps Vector2i -> owner (0/1) for every piece on the board.
static func moves(id: int, pos: Vector2i, owner_side: int, occupied: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	match id:
		0:
			_steps(out, pos, Hex.DIRS, owner_side, occupied)
		1:
			_slides(out, pos, Hex.DIRS, owner_side, occupied)
		2:
			_slides(out, pos, Hex.DIAGS, owner_side, occupied)
		3:
			_steps(out, pos, Hex.knight_jumps(), owner_side, occupied)
		4:
			_slides(out, pos, Hex.DIRS, owner_side, occupied)
			_slides(out, pos, Hex.DIAGS, owner_side, occupied)
		5:
			var leaps: Array[Vector2i] = []
			for d in Hex.DIRS:
				leaps.append(d * 2)
			_steps(out, pos, leaps, owner_side, occupied)
	return out


# One fixed offset each; landing on an enemy captures, own piece blocks.
static func _steps(out: Array[Vector2i], pos: Vector2i, offsets: Array[Vector2i], owner_side: int, occupied: Dictionary) -> void:
	for o in offsets:
		var t: Vector2i = pos + o
		if not Hex.on_board(t):
			continue
		if occupied.has(t) and occupied[t] == owner_side:
			continue
		out.append(t)


static func _slides(out: Array[Vector2i], pos: Vector2i, dirs: Array[Vector2i], owner_side: int, occupied: Dictionary) -> void:
	for d in dirs:
		var t: Vector2i = pos + d
		while Hex.on_board(t):
			if occupied.has(t):
				if occupied[t] != owner_side:
					out.append(t)
				break
			out.append(t)
			t += d
