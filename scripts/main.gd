extends Control

const SAVE_PATH := "user://loadout.json"

var loadout: Array = [0, 1, 2, 3, 4, 5]
var link := Link.new()

var _screen: Control
var _toast: Label
var _backdrop: Backdrop


func _ready() -> void:
	theme = UI.make_theme()
	_backdrop = Backdrop.new()
	add_child(_backdrop)

	_toast = UI.label("", 24)
	_toast.add_theme_stylebox_override("normal", UI.box(Color("0b0d13", 0.92), 18, Color(1, 1, 1, 0.1), 2, 8))
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_toast.offset_bottom = -40
	_toast.modulate.a = 0.0
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(link)
	link.opened.connect(_on_link_opened)
	link.message.connect(_on_link_message)
	link.closed.connect(_on_link_closed)
	link.cancelled.connect(show_menu)

	_load_loadout()
	get_window().size_changed.connect(_fit_orientation)
	_fit_orientation()
	show_menu()


# Phones held upright get a tall design size, so text and buttons stay big.
func _fit_orientation() -> void:
	var win := get_window()
	var portrait := win.size.y > win.size.x
	win.content_scale_size = Vector2i(720, 1280) if portrait else Vector2i(1280, 720)


func _set_screen(s: Control) -> void:
	if _screen:
		_screen.queue_free()
	_screen = s
	_backdrop.visible = not (s is GameScreen)
	add_child(s)
	s.modulate.a = 0.0
	create_tween().tween_property(s, "modulate:a", 1.0, 0.18)
	move_child(s, 1)       # keep the toast on top
	if _toast.get_parent() == null:
		add_child(_toast)
	else:
		move_child(_toast, get_child_count() - 1)


func show_menu() -> void:
	var m := MenuScreen.new()
	m.host_pressed.connect(_start_online.bind(true))
	m.join_pressed.connect(_start_online.bind(false))
	m.loadout_pressed.connect(show_loadout)
	m.local_pressed.connect(func(): start_game([loadout, loadout], -1))
	_set_screen(m)


func show_loadout() -> void:
	var l := LoadoutScreen.new()
	l.setup(loadout)
	l.back_pressed.connect(show_menu)
	l.changed.connect(func(team: Array):
		loadout = team
		_save_loadout())
	_set_screen(l)


func start_game(teams: Array, side: int) -> void:
	var g := GameScreen.new()
	g.setup(teams, side, link)
	g.leave_pressed.connect(_leave_game)
	_set_screen(g)


func _leave_game() -> void:
	link.close()
	show_menu()


# ---- online ----

func _start_online(host: bool) -> void:
	if not Link.available():
		toast("Online play only works in the web version")
		return
	if host:
		link.start_host()
	else:
		link.start_join()


func _on_link_opened(is_host: bool) -> void:
	toast("Connected")
	if not is_host:
		link.send({"t": "hello", "team": loadout})


func _on_link_message(data: Dictionary) -> void:
	match data.get("t", ""):
		"hello":
			if link.is_host and not (_screen is GameScreen):
				var teams := [loadout, _clean_team(data.get("team", []))]
				link.send({"t": "go", "teams": teams})
				start_game(teams, 0)
		"go":
			if not link.is_host and not (_screen is GameScreen):
				var t = data.get("teams", [])
				if t is Array and t.size() == 2:
					start_game([_clean_team(t[0]), _clean_team(t[1])], 1)
		_:
			if _screen is GameScreen:
				_screen.on_message(data)


func _on_link_closed() -> void:
	if _screen is GameScreen:
		_screen.show_opponent_left()
	else:
		toast("Connection lost")
		show_menu()


# ---- helpers ----

func _clean_team(raw) -> Array:
	var out: Array = []
	if raw is Array:
		for v in raw:
			var id := int(v)
			if id >= 0 and id < Chars.LIST.size() and id not in out and out.size() < Chars.TEAM_MAX:
				out.append(id)
	if out.is_empty():
		out = [0]
	return out


func _load_loadout() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	loadout = _clean_team(JSON.parse_string(f.get_as_text()))


func _save_loadout() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(loadout))


func toast(text: String) -> void:
	_toast.text = text
	var tw := create_tween()
	tw.tween_property(_toast, "modulate:a", 1.0, 0.15)
	tw.tween_interval(2.0)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.4)
