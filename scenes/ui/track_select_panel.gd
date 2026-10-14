class_name TrackSelectPanel
extends Control
## "CURSA RAPIDA": grila de cartonase, cate unul per pista din
## GameState.TRACK_SCENES. Un tap pe cartonas porneste cursa. Pe ecran intreg,
## cu antet fix (INAPOI + titlu); doar grila deruleaza.

signal back_pressed

const COLUMNS := 3
## Pe telefoanele late (20:9) trei coloane dau cartonase uriase si abia un rand
## si jumatate pe ecran; peste raportul asta trecem la patru.
const WIDE_ASPECT := 1.95
const WIDE_COLUMNS := 4
## Inaltimea cartonasului ca fractie din latime — imaginea iese ~2.4:1, ca in macheta; se vede o bucata din randul 3, semn ca lista deruleaza.
const CARD_ASPECT := 0.62
const TITLE_COLOR := Color(0.93, 0.95, 0.99)
const SUBTITLE_COLOR := Color(0.55, 0.62, 0.74)

var _grid: GridContainer
var _cards: Array[TrackCard] = []


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

	root.add_child(_build_header())

	# Se trage cu degetul oriunde pe grila, inclusiv peste cartonase; o tragere
	# nu apasa cartonasul de sub deget.
	var scroll := TouchScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	# Marginea interioara lasa loc conturului de focus (3 px) sa nu fie taiat.
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		pad.add_theme_constant_override(side, 4)
	scroll.add_child(pad)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 20)
	_grid.add_theme_constant_override("v_separation", 20)
	pad.add_child(_grid)

	for i in GameState.TRACK_SCENES.size():
		var card := TrackCard.new().setup(i)
		var track_index := i
		card.pressed.connect(func() -> void:
			GameState.start_quick_race(track_index))
		_grid.add_child(card)
		_cards.append(card)
	_grid.resized.connect(_fit_cards)
	visibility_changed.connect(_on_visibility_changed)


## Inaltimea urmeaza latimea coloanei, ca imaginea sa-si pastreze formatul pe
## orice ecran (stretch "expand" lasa latimea sa varieze cu telefonul).
func _fit_cards() -> void:
	if _cards.is_empty() or size.y <= 0.0:
		return
	var columns := WIDE_COLUMNS if size.x / size.y >= WIDE_ASPECT else COLUMNS
	if _grid.columns != columns:
		_grid.columns = columns # re-aseaza grila, care cheama iar functia asta
		return
	var sep := float(_grid.get_theme_constant("h_separation"))
	var width := (_grid.size.x - sep * (columns - 1)) / columns
	var height := roundf(width * CARD_ASPECT)
	for card in _cards:
		if not is_equal_approx(card.custom_minimum_size.y, height):
			card.custom_minimum_size.y = height


## La deschidere, focus pe pista jucata ultima — conturul auriu din macheta,
## si punctul de plecare pentru navigarea cu sageti/gamepad.
func _on_visibility_changed() -> void:
	if visible and not _cards.is_empty():
		var index := clampi(GameState.selected_track, 0, _cards.size() - 1)
		_cards[index].grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		back_pressed.emit()


func _build_header() -> Control:
	var header := Control.new()
	header.custom_minimum_size = Vector2(0, 96)

	var titles := VBoxContainer.new()
	titles.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	titles.alignment = BoxContainer.ALIGNMENT_CENTER
	titles.add_theme_constant_override("separation", 2)
	header.add_child(titles)
	var title := Label.new()
	title.text = "QUICK RACE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	titles.add_child(title)

	# "—— ALEGE PISTA ——": doua linii subtiri de o parte si de alta.
	var sub_row := HBoxContainer.new()
	sub_row.alignment = BoxContainer.ALIGNMENT_CENTER
	sub_row.add_theme_constant_override("separation", 16)
	titles.add_child(sub_row)
	sub_row.add_child(_rule())
	var subtitle := Label.new()
	subtitle.text = "CHOOSE A TRACK"
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", SUBTITLE_COLOR)
	sub_row.add_child(subtitle)
	sub_row.add_child(_rule())

	var back := Button.new()
	back.text = "<  BACK"
	back.custom_minimum_size = Vector2(160, 56)
	back.position = Vector2(0, 8)
	back.focus_mode = Control.FOCUS_NONE
	back.add_theme_font_size_override("font_size", 20)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.09, 0.12, 0.19)
	box.border_color = Color(0.30, 0.38, 0.52)
	box.set_border_width_all(2)
	box.set_corner_radius_all(6)
	var box_hover := box.duplicate() as StyleBoxFlat
	box_hover.border_color = Color(0.55, 0.64, 0.80)
	var box_pressed := box.duplicate() as StyleBoxFlat
	box_pressed.bg_color = Color(0.14, 0.18, 0.27)
	back.add_theme_stylebox_override("normal", box)
	back.add_theme_stylebox_override("hover", box_hover)
	back.add_theme_stylebox_override("pressed", box_pressed)
	back.pressed.connect(back_pressed.emit)
	header.add_child(back)
	return header


func _rule() -> Control:
	var line := ColorRect.new()
	line.color = Color(0.30, 0.37, 0.50)
	line.custom_minimum_size = Vector2(90, 2)
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return line
