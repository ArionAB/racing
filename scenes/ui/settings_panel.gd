class_name SettingsPanel
extends PanelContainer
## Panou de setari refolosit in meniul principal si in pauza (port din 2D).
## Slidere mari (tinte de touch), salvare imediata la fiecare schimbare.

signal back_pressed

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 26)
	add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var title := Label.new()
	title.text = "SETARI"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	box.add_child(title)

	_add_slider(box, "Sensibilitate virare", 0.6, 1.4, GameState.steer_sensitivity,
		func(v: float) -> void:
			GameState.steer_sensitivity = v
			GameState.save_settings())
	_add_slider(box, "Volum efecte", 0.0, 1.0, GameState.sfx_volume,
		func(v: float) -> void:
			GameState.sfx_volume = v
			AudioManager.apply_volumes()
			GameState.save_settings())
	_add_slider(box, "Volum motor", 0.0, 1.0, GameState.engine_volume,
		func(v: float) -> void:
			GameState.engine_volume = v
			AudioManager.apply_volumes()
			GameState.save_settings())

	var back := Button.new()
	back.text = "INAPOI"
	back.custom_minimum_size = Vector2(200, 60)
	back.add_theme_font_size_override("font_size", 24)
	back.pressed.connect(func() -> void: back_pressed.emit())
	box.add_child(back)

func _add_slider(parent: VBoxContainer, label_text: String,
		min_v: float, max_v: float, value: float, on_change: Callable) -> void:
	var name_label := Label.new()
	name_label.text = label_text
	name_label.add_theme_font_size_override("font_size", 22)
	parent.add_child(name_label)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	parent.add_child(row)

	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(340, 44)
	row.add_child(slider)

	var value_label := Label.new()
	value_label.text = "%d%%" % roundi(value * 100.0)
	value_label.add_theme_font_size_override("font_size", 22)
	value_label.custom_minimum_size = Vector2(70, 0)
	row.add_child(value_label)

	slider.value_changed.connect(func(v: float) -> void:
		value_label.text = "%d%%" % roundi(v * 100.0)
		on_change.call(v))
