class_name RaceHUD
extends CanvasLayer
## HUD-ul cursei: info (viteza/pozitie/tur/timpi), countdown, mesaje, bara
## de drift CTR si controalele touch. Construit in cod (placeholder pana la
## un design real, ca in racing 2D).

var _info: Label
var _countdown: Label
var _message: Label
var _charge_bg: ColorRect
var _charge_fill: ColorRect
var _touch: TouchControls

func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_touch = TouchControls.new()
	root.add_child(_touch)

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
