class_name Hex

# Pointy-top hexagons in axial coordinates (q, r).
# Neighbours: east/west like normal, and four diagonal neighbours up/down.

const RADIUS := 5

# Six edge directions: E, NE, NW, W, SW, SE
const DIRS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
	Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1),
]

# Six "diagonal" directions, each one between two edge directions (distance 2).
const DIAGS: Array[Vector2i] = [
	Vector2i(2, -1), Vector2i(1, -2), Vector2i(-1, -1),
	Vector2i(-2, 1), Vector2i(-1, 2), Vector2i(1, 1),
]


static func dist(a: Vector2i) -> int:
	return maxi(maxi(absi(a.x), absi(a.y)), absi(a.x + a.y))


static func on_board(c: Vector2i) -> bool:
	return dist(c) <= RADIUS


static func all_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for r in range(-RADIUS, RADIUS + 1):
		for q in range(-RADIUS, RADIUS + 1):
			var c := Vector2i(q, r)
			if on_board(c):
				out.append(c)
	return out


# Twelve hex-knight jumps: two steps one way, then one step to either side.
static func knight_jumps() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for k in 6:
		out.append(DIRS[k] * 2 + DIRS[(k + 1) % 6])
		out.append(DIRS[k] * 2 + DIRS[(k + 5) % 6])
	return out


static func to_pixel(c: Vector2i, size: float) -> Vector2:
	return Vector2(size * sqrt(3.0) * (c.x + c.y / 2.0), size * 1.5 * c.y)


static func from_pixel(p: Vector2, size: float) -> Vector2i:
	var q := (sqrt(3.0) / 3.0 * p.x - p.y / 3.0) / size
	var r := (2.0 / 3.0 * p.y) / size
	return _round(q, r)


static func _round(q: float, r: float) -> Vector2i:
	var s := -q - r
	var rq := roundf(q)
	var rr := roundf(r)
	var rs := roundf(s)
	var dq := absf(rq - q)
	var dr := absf(rr - r)
	var ds := absf(rs - s)
	if dq > dr and dq > ds:
		rq = -rr - rs
	elif dr > ds:
		rr = -rq - rs
	return Vector2i(int(rq), int(rr))


static func corners(center: Vector2, size: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 6:
		var a := deg_to_rad(60.0 * i - 30.0)
		pts.append(center + Vector2(cos(a), sin(a)) * size)
	return pts
