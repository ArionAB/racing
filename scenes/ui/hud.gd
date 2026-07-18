class_name RaceHUD
extends CanvasLayer
## HUD-ul cursei: info (viteza/pozitie/tur/timpi), countdown, mesaje, bara
## de drift CTR, controalele touch si meniul de pauza cu setari. Construit
## in cod (placeholder pana la un design real, ca in racing 2D).

signal restart_requested
signal menu_requested

var _info: Label
var _countdown: Label
var _message: Label
var _charge_bg: ColorRect
var _charge_fill: ColorRect
var _touch: TouchControls
var _pause_button: Button
var _pause_panel: PanelContainer
var _settings: SettingsPanel

func _ready() -> void:
	# ALWAYS: HUD-ul functioneaza si cu jocul pe pauza.
	process_mode = Node.PROCESS_MODE_ALWAYS

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_touch = TouchControls.new()
	root.add_child(_touch)

	_pause_button = Button.new()
	_pause_button.text = "II"
	_pause_button.custom_minimum_size = Vector2(56, 56)
	_pause_button.add_theme_font_size_override("font_size", 22)
	_pause_button.set_anchors_and_offsets_preset(
		Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	_pause_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_pause_button.pressed.connect(_open_pause)
	root.add_child(_pause_button)

	_build_pause_panel(root)
	_settings = SettingsPanel.new()
	_settings.visible = false
	_settings.back_pressed.connect(func() -> void:
		_settings.visible = false
		_pause_panel.visible = true)
	root.add_child(_settings)

	_info = _make_label(24)
	_info.position = Vector2(20, 14)
	root.add_child(_info)

	_countdown = _make_label(110)
	_countdown.set_anchors_and_offsets_preset(
		Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_countdown.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_countdown.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.add_child(_countdown)

	_message = _make_label(38)
	_message.set_anchors_and_offsets_preset(
		Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_message.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_message.grow_vertical = Control.GROW_DIRECTION_BOTH
	_message.position += Vector2(0, 100)
	_message.modulate.a = 0.0
	root.add_child(_message)

	# Bara de drift: se umple cat tii drift-ul; culoarea = nivelul de boost;
	# rosu = backfire iminent. Feedback-ul care face timing-ul CTR jucabil.
	_charge_bg = ColorRect.new()
	_charge_bg.custom_minimum_size = Vector2(260, 20)
	_charge_bg.color = Color(0, 0, 0, 0.45)
	_charge_bg.set_anchors_and_offsets_preset(
		Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 44)
	_charge_bg.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_charge_bg.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_charge_bg.visible = false
	root.add_child(_charge_bg)
	_charge_fill = ColorRect.new()
	_charge_fill.position = Vector2(3, 3)
	_charge_fill.size = Vector2(0, 14)
	_charge_bg.add_child(_charge_fill)

func _build_pause_panel(root: Control) -> void:
	_pause_panel = PanelContainer.new()
	_pause_panel.set_anchors_and_offsets_preset(
		Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_pause_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_pause_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_pause_panel.visible = false
	root.add_child(_pause_panel)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 28)
	_pause_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var title := _make_label(38)
	title.text = "PAUZA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var resume := _make_button("CONTINUA")
	resume.pressed.connect(_close_pause)
	box.add_child(resume)
	var settings := _make_button("SETARI")
	settings.pressed.connect(func() -> void:
		_pause_panel.visible = false
		_settings.visible = true)
	box.add_child(settings)
	var restart := _make_button("RESTART")
	restart.pressed.connect(func() -> void:
		get_tree().paused = false
		restart_requested.emit())
	box.add_child(restart)
	var menu := _make_button("MENIU")
	menu.pressed.connect(func() -> void:
		get_tree().paused = false
		menu_requested.emit())
	box.add_child(menu)

func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(220, 60)
	button.add_theme_font_size_override("font_size", 24)
	return button

func _open_pause() -> void:
	get_tree().paused = true
	GameState.reset_touch() # altfel virajul "ramane apasat" peste pauza
	_touch.visible = false
	_pause_button.visible = false
	_pause_panel.visible = true

func _close_pause() -> void:
	get_tree().paused = false
	_touch.visible = true
	_pause_button.visible = true
	_pause_panel.visible = false
	_settings.visible = false

func _unhandled_input(event: InputEvent) -> void:
	# ESC comuta pauza — util pe desktop in timpul dezvoltarii.
	if event.is_action_pressed("ui_cancel"):
		if _pause_panel.visible or _settings.visible:
			_close_pause()
		else:
			_open_pause()

func _make_label(font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("outline_size", 7)
	return label

func set_info(text: String) -> void:
	_info.text = text

func show_countdown(text: String) -> void:
	_countdown.text = text
	_countdown.visible = text != ""

func flash_message(text: String) -> void:
	_message.text = text
	_message.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.2)
	tw.tween_property(_message, "modulate:a", 0.0, 0.5)

func set_charge(frac: float, level: int, drifting: bool) -> void:
	_charge_bg.visible = drifting
	if not drifting:
		return
	_charge_fill.size.x = 254.0 * clampf(frac, 0.0, 1.0)
	if frac > 0.88:
		_charge_fill.color = Color(1.0, 0.15, 0.1)
	else:
		_charge_fill.color = Car.DRIFT_COLORS[clampi(level, 0, 3)]
