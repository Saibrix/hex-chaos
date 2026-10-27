class_name HexGame
extends RefCounted

# Pure game logic: no drawing, no networking.

var pieces: Dictionary = {}   # Vector2i -> {"owner": int, "char": int}
var turn := 0
var last_move: Array = []     # [from, to] of the previous move, or empty


# teams[0] / teams[1] are arrays of character ids. Side 0 starts at the bottom edge.
func setup(teams: Array) -> void:
	pieces.clear()
	turn = 0
	last_move = []
	for side in 2:
		var team: Array = teams[side]
		var n := team.size()
		var offset := (Chars.TEAM_MAX - n) / 2
		for i in n:
			var c := Vector2i(-Hex.RADIUS + offset + i, Hex.RADIUS)
			if side == 1:
				c = -c
			pieces[c] = {"owner": side, "char": int(team[i])}


func occupied() -> Dictionary:
	var out := {}
	for c in pieces:
		out[c] = pieces[c]["owner"]
	return out


func legal_moves(from: Vector2i) -> Array[Vector2i]:
	if not pieces.has(from):
		return []
	var p: Dictionary = pieces[from]
	return Chars.moves(p["char"], from, p["owner"], occupied())


func can_move(from: Vector2i, to: Vector2i) -> bool:
	return pieces.has(from) and pieces[from]["owner"] == turn and to in legal_moves(from)


# Returns the captured piece dictionary, or an empty one. Caller checks can_move first.
func apply(from: Vector2i, to: Vector2i) -> Dictionary:
	var captured := {}
	if pieces.has(to):
		captured = pieces[to]
	pieces[to] = pieces[from]
	pieces.erase(from)
	last_move = [from, to]
	turn = 1 - turn
	return captured


func count(side: int) -> int:
	var n := 0
	for c in pieces:
		if pieces[c]["owner"] == side:
			n += 1
	return n
