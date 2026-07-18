extends Control
## Meniul principal (port din 2D): titlu + start + setari + iesire.
## Butoane mari pentru touch; navigarea intre scene trece prin GameState.

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.12, 0.18)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 24)
	add_child(box)

	var title := Label.new()
	title.text = "TOY RACER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "curse cu masinute, drift si imbranceli"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.modulate = Color(1, 1, 1, 0.6)
	box.add_child(subtitle)

	var play := _make_button("START CURSA")
	play.pressed.connect(GameState.start_race)
	box.add_child(play)

	var settings_btn := _make_button("SETARI")
	box.add_child(settings_btn)

	var quit := _make_button("IESIRE")
	quit.pressed.connect(func() -> void: get_tree().quit())
	box.add_child(quit)

	var settings := SettingsPanel.new()
	settings.visible = false
	add_child(settings)
	settings_btn.pressed.connect(func() -> void:
		box.visible = false
		settings.visible = true)
	settings.back_pressed.connect(func() -> void:
		settings.visible = false
		box.visible = true)

func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(360, 80)
	button.add_theme_font_size_override("font_size", 30)
	return button
