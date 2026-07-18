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
	subtitle.text = "curse cu masinute, drift si imbranceli"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.modulate = Color(1, 1, 1, 0.6)
	_main_box.add_child(subtitle)

	var quick := _make_button("CURSA RAPIDA")
	_main_box.add_child(quick)
	var champ := _make_button("CAMPIONAT")
	champ.pressed.connect(GameState.start_championship)
	_main_box.add_child(champ)
	var garage_btn := _make_button("GARAJ")
	_main_box.add_child(garage_btn)
	var settings_btn := _make_button("SETARI")
	_main_box.add_child(settings_btn)
	var quit := _make_button("IESIRE")
	quit.pressed.connect(func() -> void: get_tree().quit())
	_main_box.add_child(quit)

	var track_panel := _build_track_panel()
	quick.pressed.connect(func() -> void: _show_panel(track_panel))
	var garage_panel := _build_garage_panel()
	garage_btn.pressed.connect(func() -> void: _show_panel(garage_panel))
	var settings := SettingsPanel.new()
	settings.visible = false
	add_child(settings)
	_panels.append(settings)
	settings.back_pressed.connect(_show_main)
	settings_btn.pressed.connect(func() -> void: _show_panel(settings))

# ------------------------------------------------------------------ panouri

func _show_panel(panel: Control) -> void:
	_main_box.visible = false
	for p in _panels:
		p.visible = p == panel

func _show_main() -> void:
	_main_box.visible = true
	for p in _panels:
		p.visible = false

## Alegerea pistei pentru cursa rapida.
func _build_track_panel() -> Control:
	var panel := _make_panel()
	var box := panel.get_child(0).get_child(0) as VBoxContainer
	var title := Label.new()
	title.text = "ALEGE PISTA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	box.add_child(title)
	for i in GameState.TRACK_NAMES.size():
		var track_index := i
		var button := _make_button(GameState.TRACK_NAMES[i])
		button.pressed.connect(func() -> void:
			GameState.start_quick_race(track_index))
		box.add_child(button)
	_add_back(box)
	return panel

## Garajul: alegerea masinii, cu statistici; selectia se persista.
func _build_garage_panel() -> Control:
	var panel := _make_panel()
	var box := panel.get_child(0).get_child(0) as VBoxContainer
	var title := Label.new()
	title.text = "GARAJ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	box.add_child(title)
	var buttons: Array[Button] = []
	for i in GameState.CAR_DATA.size():
		var car_index := i
		var data := GameState.CAR_DATA[i] as CarData
		var button := Button.new()
		button.custom_minimum_size = Vector2(430, 70)
		button.add_theme_font_size_override("font_size", 22)
		button.pressed.connect(func() -> void:
			GameState.selected_car = car_index
			GameState.save_settings()
			_refresh_garage(buttons))
		box.add_child(button)
		buttons.append(button)
	_refresh_garage(buttons)
	_add_back(box)
	return panel

func _refresh_garage(buttons: Array[Button]) -> void:
	for i in buttons.size():
		var data := GameState.CAR_DATA[i] as CarData
		var marker := "> " if i == GameState.selected_car else "   "
		buttons[i].text = "%s%s   vit %d  accel %d  grip %d  masa %.1f" % [
			marker, data.display_name, int(data.max_speed),
			int(data.acceleration), int(data.grip), data.mass_factor]

# ---------------------------------------------------------------- utilitare

func _make_center_box() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 18)
	return box

func _make_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(
		Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.visible = false
	add_child(panel)
	_panels.append(panel)
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 24)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	return panel

func _add_back(box: VBoxContainer) -> void:
	var back := Button.new()
	back.text = "INAPOI"
	back.custom_minimum_size = Vector2(200, 60)
	back.add_theme_font_size_override("font_size", 24)
	back.pressed.connect(_show_main)
	box.add_child(back)

func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(360, 74)
	button.add_theme_font_size_override("font_size", 30)
	return button
