class_name LoadoutScreen
extends Control

signal back_pressed
signal changed(team: Array)

var team: Array = []

var _split: BoxContainer
var _grid: GridContainer
var _count: Label
var _cards: Array[CharCard] = []


func setup(current: Array) -> void:
	team = current.duplicate()


func _ready() -> void:
	UI.fill(self)
	_split = BoxContainer.new()
	_split.add_theme_constant_override("separation", 24)
	add_child(UI.margin(_split))

	# Left: characters
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 3.0
	left.add_theme_constant_override("separation", 16)
	_split.add_child(left)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	left.add_child(head)
	var back := UI.button("< Back", Vector2(150, 60))
	back.pressed.connect(func(): back_pressed.emit())
	head.add_child(back)
	head.add_child(UI.label("Loadout", 44))

	_grid = GridContainer.new()
	_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	left.add_child(_grid)
	for ch in Chars.LIST:
		var card := CharCard.new(ch["id"])
		card.set_selected(ch["id"] in team)
		card.toggled.connect(_on_card_toggled.bind(card))
		_grid.add_child(card)
		_cards.append(card)

	_count = UI.label("", 24, UI.MUTED)
	left.add_child(_count)
	_update_count()

	# Right: empty box for later
	var right := PanelContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 2.0
	right.add_theme_stylebox_override("panel", UI.box(Color("12151d", 0.75), 28, Color(1, 1, 1, 0.08), 2, 16))
	_split.add_child(right)

	resized.connect(_relayout)
	_relayout()


func _relayout() -> void:
	var portrait := size.y > size.x * 1.05
	_split.vertical = portrait
	_grid.columns = 2 if portrait else 3


func _on_card_toggled(value: bool, card: CharCard) -> void:
	var id := card.char_id
	if value:
		if id not in team:
			team.append(id)
	else:
		if team.size() <= 1:
			return   # keep at least one character
		team.erase(id)
	team.sort()
	card.set_selected(value)
	_update_count()
	changed.emit(team)


func _update_count() -> void:
	_count.text = "Team: %d / %d  (tap to pick, at least 1)" % [team.size(), Chars.TEAM_MAX]
