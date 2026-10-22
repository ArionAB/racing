extends Control
## Popup-ul de schimbare de pozitie (feel: position-change): „P3" cu un triunghi
## verde in sus (ai depasit) sau rosu in jos (ai fost depasit). Apare sus-centru,
## sub eticheta de informatii, tine ~1 s si se stinge. Un popup nou il inlocuieste
## pe cel vechi (nu se aduna).
##
## Desenat cu triunghi propriu, nu cu glifa ▲/▼: fontul HUD nu garanteaza glifele
## si un patrat gol langa „P3" ar arata a bug.

@export var hold_s: float = 1.0
@export var fade_s: float = 0.35
@export var gain_color: Color = Color(0.35, 0.9, 0.45)
@export var loss_color: Color = Color(1.0, 0.38, 0.32)
@export var font_size: int = 64

## Observabile din sonde.
var shown_count: int = 0
var last_text: String = ""
## +1 = ai urcat, -1 = ai coborat, 0 = nimic afisat inca.
var last_dir: int = 0
var last_color: Color = Color.WHITE

var _label: Label
var _tween: Tween
var _dir: int = 0
var _tri_color: Color = Color.WHITE


func _init() -> void:
	# Marimea minima TREBUIE sa existe inainte ca HUD-ul sa aplice ancora
	# (`set_anchors_and_offsets_preset` o citeste), altfel popup-ul ar iesi
	# necentrat.
	custom_minimum_size = Vector2(190, 84)
	size = custom_minimum_size


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = size * 0.5
	_label = Label.new()
	_label.add_theme_font_override("font",
		preload("res://assets/fonts/BarlowCondensed-SemiBold.ttf"))
	_label.add_theme_font_size_override("font_size", font_size)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_label.add_theme_constant_override("outline_size", maxi(3, roundi(font_size * 0.16)))
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.offset_left = 64.0
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_label)
	visible = false
	modulate.a = 0.0


## `new_pos` si `old_pos`: mai mic = mai bine.
func show_change(new_pos: int, old_pos: int) -> void:
	_dir = 1 if new_pos < old_pos else -1
	_tri_color = gain_color if _dir > 0 else loss_color
	last_dir = _dir
	last_color = _tri_color
	last_text = "P%d" % new_pos
	shown_count += 1
	_label.text = last_text
	_label.add_theme_color_override("font_color", _tri_color)
	queue_redraw()
	visible = true
	modulate.a = 1.0
	scale = Vector2(1.35, 1.35)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	# Tween-ul cu pauza activa (HUD-ul e PROCESS_MODE_ALWAYS), dar ignora time_scale
	# ca sa nu ramana intepenit in hit-stop.
	_tween = create_tween().set_ignore_time_scale(true)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(hold_s)
	_tween.tween_property(self, "modulate:a", 0.0, fade_s)
	_tween.tween_callback(func() -> void: visible = false)


## Ascunde pe loc (final de cursa, repunere).
func hide_now() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	visible = false
	modulate.a = 0.0


func _draw() -> void:
	if _dir == 0:
		return
	var c := Vector2(32.0, size.y * 0.5)
	var h := 22.0
	var pts: PackedVector2Array
	if _dir > 0:
		pts = PackedVector2Array([c + Vector2(0, -h), c + Vector2(h, h * 0.8),
			c + Vector2(-h, h * 0.8)])
	else:
		pts = PackedVector2Array([c + Vector2(0, h), c + Vector2(h, -h * 0.8),
			c + Vector2(-h, -h * 0.8)])
	var outline := PackedVector2Array()
	for p in pts:
		outline.append(c + (p - c) * 1.25)
	draw_colored_polygon(outline, Color(0, 0, 0, 0.8))
	draw_colored_polygon(pts, _tri_color)
