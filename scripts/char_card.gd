class_name CharCard
extends Control

signal toggled(is_selected: bool)

var char_id := 0
var selected := false


func _init(id: int = 0) -> void:
	char_id = id
	custom_minimum_size = Vector2(240, 190)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL


func set_selected(value: bool) -> void:
	selected = value
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		toggled.emit(not selected)


func _draw() -> void:
	var ch := Chars.get_char(char_id)
	var rect := Rect2(Vector2.ZERO, size)
	if selected:
		draw_style_box(UI.box(UI.PANEL_HI, 16, UI.ACCENT, 4), rect)
	else:
		draw_style_box(UI.box(UI.PANEL, 16, Color("2b3140"), 2), rect)

	var center := Vector2(52, 52)
	draw_circle(center, 34.0, UI.SIDE_COLORS[0].darkened(0.35))
	draw_circle(center, 30.0, UI.SIDE_COLORS[0])
	Glyphs.draw(self, ch["glyph"], center, 17.0, UI.BG)

	var font := get_theme_default_font()
	draw_string(font, Vector2(96, 62), ch["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 26, UI.TEXT)
	draw_multiline_string(font, Vector2(20, 112), ch["desc"], HORIZONTAL_ALIGNMENT_LEFT, maxf(40.0, size.x - 40.0), 18, 4, UI.MUTED)

	if selected:
		var b := Vector2(size.x - 24, 24)
		draw_circle(b, 13.0, UI.ACCENT)
		draw_polyline(PackedVector2Array([b + Vector2(-6, 0), b + Vector2(-2, 5), b + Vector2(7, -5)]), Color.WHITE, 3.0)
