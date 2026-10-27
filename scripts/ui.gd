class_name UI

const BG := Color("14161c")
const PANEL := Color("1f232d")
const PANEL_HI := Color("2b3140")
const ACCENT := Color("6c8cff")
const TEXT := Color("eef0f5")
const MUTED := Color("9aa3b5")
const SIDE_COLORS := [Color("5ad1c8"), Color("ff7a6b")]


static func box(fill: Color, radius := 14, border := Color.TRANSPARENT, border_w := 0, shadow := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.shadow_size = shadow
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_offset = Vector2(0, shadow * 0.4)
	s.anti_aliasing_size = 1.2
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
	_style_button(t, "Button", PANEL_HI, Color("353c50"), Color("46506b"), Color(1, 1, 1, 0.08))
	t.set_type_variation("PrimaryButton", "Button")
	_style_button(t, "PrimaryButton", ACCENT, ACCENT.lightened(0.15), ACCENT.darkened(0.2), Color(1, 1, 1, 0.25))
	return t


static func _style_button(t: Theme, type: String, fill: Color, hover: Color, pressed: Color, border: Color) -> void:
	t.set_stylebox("normal", type, box(fill, 22, border, 2, 10))
	t.set_stylebox("hover", type, box(hover, 22, border, 2, 12))
	t.set_stylebox("pressed", type, box(pressed, 22, border, 2, 2))
	t.set_stylebox("disabled", type, box(PANEL, 22, border, 2, 0))
	t.set_stylebox("focus", type, StyleBoxEmpty.new())
	t.set_color("font_color", type, TEXT)
	t.set_color("font_hover_color", type, TEXT)
	t.set_color("font_pressed_color", type, TEXT)
	t.set_color("font_disabled_color", type, MUTED)
	t.set_font_size("font_size", type, 28)


static func button(text: String, min_size := Vector2(0, 68), primary := false) -> Button:
	var b := Button.new()
	if primary:
		b.theme_type_variation = "PrimaryButton"
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
