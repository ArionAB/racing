extends Control
## Meniul principal: cursa rapida (cu alegerea pistei), campionat, garaj
## (alegerea masinii, persistata), setari. Butoane mari pentru touch.

var _main_box: VBoxContainer
var _panels: Array[Control] = []

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.12, 0.18)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_main_box = _make_center_box()
	add_child(_main_box)

	var title := Label.new()
	title.text = "TOY RACER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	_main_box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "toy cars, drifting and bumping"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.modulate = Color(1, 1, 1, 0.6)
	_main_box.add_child(subtitle)

	var quick := _make_button("QUICK RACE")
	_main_box.add_child(quick)
	# CAREER a inlocuit butonul CHAMPIONSHIP; campionatul ramane in GameState
	# (il va folosi cupa lumii), doar intrarea din meniu a disparut.
	var career_btn := _make_button("CAREER")
	_main_box.add_child(career_btn)
	var garage_btn := _make_button("GARAGE")
	_main_box.add_child(garage_btn)
	var settings_btn := _make_button("SETTINGS")
	_main_box.add_child(settings_btn)
	var quit := _make_button("QUIT")
	quit.pressed.connect(func() -> void: get_tree().quit())
	_main_box.add_child(quit)

	var track_panel := _build_track_panel()
	quick.pressed.connect(func() -> void: _show_panel(track_panel))
	var career_panel := _build_career_panel()
	career_btn.pressed.connect(func() -> void: _show_panel(career_panel))
	var garage_panel := _build_garage_panel()
	garage_btn.pressed.connect(func() -> void: _show_panel(garage_panel))
	var settings := SettingsPanel.new()
	settings.visible = false
	add_child(settings)
	_panels.append(settings)
	settings.back_pressed.connect(_show_main)
	settings_btn.pressed.connect(func() -> void: _show_panel(settings))

	# Dupa o cursa de cariera revenim direct pe raft, nu pe meniul principal.
	if GameState.menu_open_panel == &"career":
		GameState.menu_open_panel = &""
		_show_panel(career_panel)

# ------------------------------------------------------------------ panouri

func _show_panel(panel: Control) -> void:
	_main_box.visible = false
	for p in _panels:
		p.visible = p == panel
	# Garajul se redeschide pe masina SALVATA, nu pe cea la care te uitai
	# ultima data fara sa apesi SELECT.
	var garage := panel as GaragePanel
	if garage != null:
		garage.reopen()

func _show_main() -> void:
	_main_box.visible = true
	for p in _panels:
		p.visible = false

## Alegerea pistei pentru cursa rapida: grila de cartonase pe ecran intreg.
func _build_track_panel() -> Control:
	var panel := TrackSelectPanel.new()
	panel.visible = false
	add_child(panel)
	_panels.append(panel)
	panel.back_pressed.connect(_show_main)
	return panel

## Raftul carierei: lumi si piste, pe ecran intreg.
func _build_career_panel() -> Control:
	var panel := CareerPanel.new()
	panel.visible = false
	add_child(panel)
	_panels.append(panel)
	panel.back_pressed.connect(_show_main)
	return panel

## Garajul: vitrina 3D + statistici + banda de selectie, pe ecran intreg
## (GaragePanel). A inlocuit lista de butoane-text, unde cifrele brute nu
## spuneau nimic si nu vedeai masina pe care o alegi.
func _build_garage_panel() -> Control:
	var panel := GaragePanel.new()
	panel.visible = false
	add_child(panel)
	_panels.append(panel)
	panel.back_pressed.connect(_show_main)
	return panel

# ---------------------------------------------------------------- utilitare

func _make_center_box() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 18)
	return box

func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(360, 74)
	button.add_theme_font_size_override("font_size", 30)
	return button
