class_name UI

const BG := Color("14161c")
const PANEL := Color("1f232d")
const PANEL_HI := Color("2b3140")
const ACCENT := Color("6c8cff")
const TEXT := Color("eef0f5")
const MUTED := Color("9aa3b5")
const SIDE_COLORS := [Color("5ad1c8"), Color("ff7a6b")]


static func box(fill: Color, radius := 14, border := Color.TRANSPARENT, border_w := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.set_corner_radius_all(radius)
	s.border_color = border
	s.set_border_width_all(border_w)
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s


static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 26
	t.set_color("font_color", "Label", TEXT)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var fill := PANEL_HI
		if state == "hover":
			fill = Color("353c50")
		elif state == "pressed":
			fill = ACCENT
		elif state == "disabled":
			fill = PANEL
		if state == "focus":
			t.set_stylebox(state, "Button", StyleBoxEmpty.new())
		else:
			t.set_stylebox(state, "Button", box(fill))
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", TEXT)
	t.set_color("font_pressed_color", "Button", TEXT)
	t.set_color("font_disabled_color", "Button", MUTED)
	return t


static func button(text: String, min_size := Vector2(0, 68)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	return b


static func label(text: String, size := 26, color := TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func fill(c: Control) -> void:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


static func margin(c: Control, px := 24) -> MarginContainer:
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, px)
	fill(m)
	m.add_child(c)
	return m
