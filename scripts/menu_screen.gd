class_name MenuScreen
extends Control

signal host_pressed
signal join_pressed
signal loadout_pressed
signal local_pressed


func _ready() -> void:
	UI.fill(self)
	var center := CenterContainer.new()
	UI.fill(center)
	add_child(center)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(440, 0)
	box.add_theme_constant_override("separation", 16)
	center.add_child(box)

	box.add_child(Logo.new())
	var title := UI.label("HEX CHAOS", 76)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var sub := UI.label("working title", 20, UI.MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)
	box.add_child(Control.new())

	_add_button(box, "Host", host_pressed).theme_type_variation = "PrimaryButton"
	_add_button(box, "Join", join_pressed)
	_add_button(box, "Loadout", loadout_pressed)
	var local := _add_button(box, "Local test (one device)", local_pressed)
	local.custom_minimum_size.y = 52
	local.add_theme_font_size_override("font_size", 20)
	local.modulate = Color(1, 1, 1, 0.7)


func _add_button(parent: Control, text: String, sig: Signal) -> Button:
	var b := UI.button(text)
	b.pressed.connect(func(): sig.emit())
	parent.add_child(b)
	return b
