class_name SettingsPanel
extends PanelContainer
## Panou de setari refolosit in meniul principal si in pauza (port din 2D).
## Slidere mari (tinte de touch), salvare imediata la fiecare schimbare.

signal back_pressed

func _ready() -> void:
	_build()


## Reface panoul din setarile curente. Cheltuiala e nula (se intampla la o
## apasare de buton), iar alternativa ar fi sa tinem referinte la fiecare slider
## ca sa le putem pune valoarea inapoi.
func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_build()


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 26)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var title := Label.new()
	title.text = "SETARI"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	root.add_child(title)

	# Sapte slidere nu mai incap pe un ecran de telefon in landscape. Deruleaza
	# doar LISTA: titlul si butoanele raman in afara ei, altfel INAPOI ajunge sub
	# marginea de jos si panoul se inchide doar cu scroll — pe touch, o capcana.
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(440,
		minf(520.0, get_viewport_rect().size.y * 0.58))
	root.add_child(scroll)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)

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

	# --- camera ---
	# Sliderele lucreaza pe FACTORI, nu pe metri: valorile din ChaseCamera raman
	# implicitul, iar setarea le scaleaza. Din pauza, camera se muta sub deget —
	# de aia fiecare schimbare striga si prin grup, nu doar in GameState.
	_add_slider(box, "Camera: distanta", 0.5, 2.0, GameState.cam_distance_scale,
		func(v: float) -> void:
			GameState.cam_distance_scale = v
			_push_camera())
	_add_slider(box, "Camera: inaltime", 0.4, 2.0, GameState.cam_height_scale,
		func(v: float) -> void:
			GameState.cam_height_scale = v
			_push_camera())
	_add_slider(box, "Camera: unghi de vedere", 0.7, 1.3, GameState.cam_fov_scale,
		func(v: float) -> void:
			GameState.cam_fov_scale = v
			_push_camera())
	_add_slider(box, "Camera: viteza de urmarire", 0.4, 2.5,
		GameState.cam_follow_scale,
		func(v: float) -> void:
			GameState.cam_follow_scale = v
			_push_camera())

	var reset_cam := Button.new()
	reset_cam.text = "RESETEAZA CAMERA"
	reset_cam.custom_minimum_size = Vector2(200, 48)
	reset_cam.add_theme_font_size_override("font_size", 20)
	reset_cam.pressed.connect(func() -> void:
		GameState.reset_camera_settings()
		get_tree().call_group(ChaseCamera.GROUP, &"refresh_from_settings")
		# Panoul se reface din setari: altfel sliderele ar arata in continuare
		# valorile vechi, iar urmatoarea atingere le-ar pune inapoi.
		_rebuild())
	root.add_child(reset_cam)

	var back := Button.new()
	back.text = "INAPOI"
	back.custom_minimum_size = Vector2(200, 60)
	back.add_theme_font_size_override("font_size", 24)
	back.pressed.connect(func() -> void: back_pressed.emit())
	root.add_child(back)

## Camera vie afla imediat, prin grup. Salvarea merge in acelasi apel: sliderele
## astea se misca de cateva ori pe reglaj, nu de zeci de ori pe secunda ca tastele
## din CameraTuner, deci n-are rost sa amanam scrierea.
func _push_camera() -> void:
	get_tree().call_group(ChaseCamera.GROUP, &"refresh_from_settings")
	GameState.save_settings()


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
