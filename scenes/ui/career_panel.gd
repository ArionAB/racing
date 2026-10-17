class_name CareerPanel
extends Control
## Raftul carierei: pasaportul (stampile + medalii) sus, apoi o cutie per lume
## cu pistele ei. Lumea deblocata arata carduri (tap = deschide foaia pistei:
## RACE / TIME TRIAL); cea sigilata arata un lacat si cate stampile mai lipsesc.
## Pe ecran intreg, cu antet fix; doar continutul deruleaza. Acelasi tipar ca
## TrackSelectPanel, a carui grila si antet le refoloseste.

signal back_pressed

const BOX_COLOR := Color(0.09, 0.12, 0.19)
const BOX_BORDER := Color(0.20, 0.27, 0.40)
const GOLD := Color(0.95, 0.78, 0.25)
const SILVER := Color(0.80, 0.83, 0.88)
const BRONZE := Color(0.75, 0.50, 0.30)

## Referinte pastrate pentru reimprospatare (si pentru sonda).
var _stamps_label: Label
var _medals_row: HBoxContainer
var _worlds_box: VBoxContainer
var _first_card: TrackCard
## Foaia pistei deschisa (null = inchisa).
var _sheet: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	margin.add_child(root)

	root.add_child(TrackSelectPanel.build_header("CAREER", "CHOOSE A WORLD",
		back_pressed.emit))

	var scroll := TouchScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		pad.add_theme_constant_override(side, 4)
	scroll.add_child(pad)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 20)
	pad.add_child(content)

	content.add_child(_build_passport())
	_worlds_box = VBoxContainer.new()
	_worlds_box.add_theme_constant_override("separation", 20)
	content.add_child(_worlds_box)

	_refresh()
	Career.progress_changed.connect(_refresh)
	visibility_changed.connect(_on_visibility_changed)


## Pasaportul: STAMPS N / MAX mare, medaliile pe culori sub el.
func _build_passport() -> Control:
	var box := _make_box()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	box.get_child(0).add_child(column)
	_stamps_label = Label.new()
	_stamps_label.add_theme_font_size_override("font_size", 40)
	_stamps_label.add_theme_color_override("font_color", TrackSelectPanel.TITLE_COLOR)
	column.add_child(_stamps_label)
	_medals_row = HBoxContainer.new()
	_medals_row.add_theme_constant_override("separation", 22)
	column.add_child(_medals_row)
	return box


func _refresh() -> void:
	_stamps_label.text = "STAMPS  %d / %d" % [Career.stamps(), Career.max_stamps()]

	for child in _medals_row.get_children():
		child.free()
	var counts := Career.medal_counts()
	for entry in [[Career.MEDAL_GOLD, GOLD], [Career.MEDAL_SILVER, SILVER],
			[Career.MEDAL_BRONZE, BRONZE]]:
		var dot := _Disc.new()
		dot.color = entry[1]
		_medals_row.add_child(dot)
		_medals_row.add_child(_label("x %d" % int(counts[entry[0]]), 20,
			TrackCard.TEXT_DIM))

	# Lumile se reconstruiesc intregi: sunt 3 cutii, iar o deblocare schimba
	# structura (carduri in loc de lacat), nu doar un text.
	for child in _worlds_box.get_children():
		child.free()
	_first_card = null
	for world in Career.worlds():
		_worlds_box.add_child(_build_world(world))


func _build_world(world: CareerWorld) -> Control:
	var box := _make_box()
	box.name = "World_%s" % world.id
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	box.get_child(0).add_child(column)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 14)
	column.add_child(title_row)
	title_row.add_child(_label(world.display_name, 30, Color.WHITE))
	if world.free:
		title_row.add_child(_label("FREE", 18, TrackSelectPanel.SUBTITLE_COLOR))

	if Career.is_world_unlocked(world):
		column.add_child(_build_grid(world))
	else:
		column.add_child(_build_sealed(world))
	return box


func _build_grid(world: CareerWorld) -> Control:
	var grid := GridContainer.new()
	grid.columns = TrackSelectPanel.COLUMNS
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	var cards: Array[TrackCard] = []
	for track_id in world.tracks:
		var index := TrackInfo.index_of_id(track_id)
		if index < 0:
			continue # config stricat: validate() l-a raportat deja
		var card := TrackCard.new().setup(index)
		var state := Career.track_state(track_id)
		card.set_medals(int(state.race_medal), int(state.tt_medal),
			bool(state.challenge))
		var id := track_id
		card.pressed.connect(func() -> void: _open_sheet(id))
		grid.add_child(card)
		cards.append(card)
		if _first_card == null or index == GameState.selected_track:
			_first_card = card
	grid.resized.connect(func() -> void:
		TrackSelectPanel.fit_cards(grid, cards, size))
	return grid


func _build_sealed(world: CareerWorld) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.custom_minimum_size = Vector2(0, 56)
	row.add_child(_Lock.new())
	var label := _label("SEALED — %d MORE STAMPS" % Career.stamps_missing(world),
		22, TrackCard.TEXT_DIM)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)
	return row


## Focus pe o pista deblocata la deschidere (navigare cu tastatura/gamepad).
func _on_visibility_changed() -> void:
	if visible and _first_card != null:
		_first_card.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		# Intai se inchide foaia; panoul abia la a doua apasare.
		if _sheet != null:
			_close_sheet()
		else:
			back_pressed.emit()


## Foaia pistei: fundal semi-opac care inchide la tap, cu un panou centrat
## (nume, RACE, TIME TRIAL, CHALLENGE inca blocat, BACK). Un tap pe card nu
## mai porneste cursa direct: jucatorul alege intai modul.
func _open_sheet(track_id: StringName) -> void:
	_close_sheet()
	var index := TrackInfo.index_of_id(track_id)
	if index < 0:
		return
	var info := TrackInfo.for_track(index)
	var state := Career.track_state(track_id)

	_sheet = Control.new()
	_sheet.name = "TrackSheet"
	_sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_sheet)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed \
				or event is InputEventScreenTouch and event.pressed:
			_close_sheet())
	_sheet.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheet.add_child(center)
	var box := _make_box()
	box.custom_minimum_size = Vector2(560, 0)
	center.add_child(box)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	box.get_child(0).add_child(column)

	var title := _label(info.display_name, 36, TrackSelectPanel.TITLE_COLOR)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	var race_btn := _sheet_button("RACE", _medal_name(int(state.race_medal)))
	race_btn.name = "RaceButton"
	race_btn.pressed.connect(func() -> void:
		Career.start_track(track_id, Career.Mode.RACE))
	column.add_child(race_btn)

	var tt_sub := "NO TIME YET"
	if int(state.tt_best_ms) > 0:
		tt_sub = "BEST %s · %s" % [TrackCard._format_ms(int(state.tt_best_ms)),
			_medal_name(int(state.tt_medal))]
	if not info.has_targets():
		tt_sub += "  (no targets yet)"
	var tt_btn := _sheet_button("TIME TRIAL", tt_sub)
	tt_btn.name = "TimeTrialButton"
	tt_btn.pressed.connect(func() -> void:
		Career.start_track(track_id, Career.Mode.TIME_TRIAL))
	column.add_child(tt_btn)

	var challenge_btn := _sheet_button("CHALLENGE", "SOON")
	challenge_btn.name = "ChallengeButton"
	challenge_btn.disabled = true
	column.add_child(challenge_btn)

	var back_btn := _sheet_button("BACK", "")
	back_btn.name = "BackButton"
	back_btn.pressed.connect(_close_sheet)
	column.add_child(back_btn)
	race_btn.grab_focus.call_deferred()


func _close_sheet() -> void:
	if _sheet == null:
		return
	_sheet.queue_free()
	_sheet = null
	if _first_card != null:
		_first_card.grab_focus.call_deferred()


static func _medal_name(medal: int) -> String:
	match medal:
		Career.MEDAL_GOLD: return "GOLD"
		Career.MEDAL_SILVER: return "SILVER"
		Career.MEDAL_BRONZE: return "BRONZE"
	return "—"


## Buton mare (>= 64 px) cu titlu si, daca e, un subtitlu pe al doilea rand.
func _sheet_button(text: String, subtitle: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 72)
	button.text = text if subtitle == "" else "%s\n%s" % [text, subtitle]
	button.add_theme_font_size_override("font_size", 24)
	return button


## Cutie cu fundal si contur ca ale cartonaselor; continutul intra in
## `get_child(0)` (un MarginContainer).
func _make_box() -> PanelContainer:
	var box := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = BOX_COLOR
	style.border_color = BOX_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(TrackCard.RADIUS)
	box.add_theme_stylebox_override("panel", style)
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 18)
	box.add_child(margin)
	return box


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


## Disc de culoare langa numarul de medalii (desenat, fara textura).
class _Disc extends Control:
	var color := Color.WHITE

	func _init() -> void:
		custom_minimum_size = Vector2(20, 20)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_circle(size * 0.5, 9.0, color)


## Lacatul lumii sigilate: toarta + corp, desenat ca _Clock din TrackCard.
class _Lock extends Control:
	func _init() -> void:
		custom_minimum_size = Vector2(36, 44)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var col := TrackCard.TEXT_DIM
		var cx := size.x * 0.5
		draw_arc(Vector2(cx, 16.0), 9.0, PI, TAU, 16, col, 3.0, true)
		draw_line(Vector2(cx - 9.0, 16.0), Vector2(cx - 9.0, 22.0), col, 3.0, true)
		draw_line(Vector2(cx + 9.0, 16.0), Vector2(cx + 9.0, 22.0), col, 3.0, true)
		draw_rect(Rect2(cx - 14.0, 22.0, 28.0, 20.0), col)
