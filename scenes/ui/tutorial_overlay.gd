class_name TutorialOverlay
extends Control
## Stratul turului ghidat (#678): cartonasul cu indiciul curent (sus, la
## mijloc, departe de butoane), inelele peste butoanele touch vizate si rama
## din jurul barii de turbo. Nu decide nimic: TutorialDirector ii spune ce pas
## e si cat s-a facut.
##
## Pe touch indiciul numeste BUTONUL si, dupa `nudge_after_s` fara gest,
## butonul pulseaza. Pe tastatura numeste TASTA (din InputMap) si nu pulseaza
## nimic. Modul se schimba dupa ultimul input (o atingere sau o tasta).

signal skip_pressed
signal continue_pressed

## Inelul din jurul butonului: la `RING_GAP` de discul desenat, gros de
## `RING_WIDTH`, iar pulsul il mai creste cu `RING_GROW`. Sonda verifica ca
## inelul, la maximul pulsului, nu intra in discul altui buton.
const RING_GAP: float = 4.0
const RING_WIDTH: float = 3.0
const RING_GROW: float = 6.0
## Spatiul lasat liber pe fiecare parte a cartonasului: panoul de telemetrie
## (stanga-sus) si coloana pauza/minimapa/RESET (dreapta-sus).
const SIDE_CLEAR: float = 250.0
const CARD_MAX_W: float = 560.0
const CARD_MIN_W: float = 380.0
const CARD_TOP: float = 16.0
const HINT_COLOR := Color(1.0, 0.78, 0.22)

## Ce evidentiaza fiecare pas. „bar" e bara de turbo (in ambele moduri);
## restul sunt zone de TouchControls (doar pe touch).
const HIGHLIGHTS := {
	&"steer": ["left", "right"],
	&"gas": ["gas"],
	&"drift": ["drift", "bar"],
	&"turbo": ["turbo", "bar"],
}

var config: TutorialConfig
## Indiciile numesc butoanele (true) sau tastele (false).
var touch_mode: bool = false

var _touch: TouchControls
var _bar_rect_fn: Callable = Callable()
## Tine cartonasul; ascuns pe pauza (si cu el SKIP, ca sa nu poata fi apasat
## nevazut prin panoul de pauza).
var _holder: Control
var _card: PanelContainer
var _title: Label
var _counter: Label
var _body: Label
var _sub: Label
var _bar_bg: Panel
var _bar_fill: Panel
var _skip: Button
var _continue: Button
var _step: StringName = &""
var _nudge: bool = false
var _time: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	touch_mode = DisplayServer.is_touchscreen_available()
	_build_card()
	resized.connect(_place_card)
	_place_card()


func bind(touch: TouchControls, bar_rect_fn: Callable) -> void:
	_touch = touch
	_bar_rect_fn = bar_rect_fn


func _build_card() -> void:
	_holder = Control.new()
	_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_holder)
	_card = PanelContainer.new()
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_theme_stylebox_override("panel", RaceHUD._panel_style(16,
		Color(0.04, 0.05, 0.08, 0.80), Color(HINT_COLOR, 0.45)))
	_holder.add_child(_card)
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["margin_left", "margin_right"]:
		margin.add_theme_constant_override(side, 20)
	for side in ["margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 10)
	_card.add_child(margin)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)

	# Randul de sus: titlul, „2 / 4" si SKIP / CONTINUE — butonul pe acelasi
	# rand cu titlul, ca cartonasul sa fure cat mai putin din drum.
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_constant_override("separation", 14)
	box.add_child(top)
	_title = _label(24, HINT_COLOR)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(_title)
	_counter = _label(20, RaceHUD.DIM)
	_counter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(_counter)
	_skip = _button(config.skip_label if config != null else "SKIP TUTORIAL")
	_skip.pressed.connect(func() -> void: skip_pressed.emit())
	top.add_child(_skip)
	_continue = _button(config.continue_label if config != null else "CONTINUE")
	_continue.visible = false
	_continue.pressed.connect(func() -> void: continue_pressed.emit())
	top.add_child(_continue)

	_body = _label(27, Color.WHITE)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_body)
	_sub = _label(21, Color(1.0, 0.62, 0.3))
	_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_sub)

	# Progresul gestului: subtire, ca sa spuna „merge" fara sa ceara citit.
	_bar_bg = Panel.new()
	_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_bg.custom_minimum_size = Vector2(0, 6)
	_bar_bg.add_theme_stylebox_override("panel",
		RaceHUD._panel_style(3, Color(1, 1, 1, 0.12), Color(0, 0, 0, 0)))
	box.add_child(_bar_bg)
	_bar_fill = Panel.new()
	_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_fill.add_theme_stylebox_override("panel",
		RaceHUD._panel_style(3, HINT_COLOR, Color(0, 0, 0, 0)))
	_bar_bg.add_child(_bar_fill)


func _label(font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", RaceHUD.FONT_MEDIUM)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", maxi(3, roundi(font_size * 0.14)))
	return l


func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(160, 44)
	b.add_theme_font_override("font", RaceHUD.FONT_MEDIUM)
	b.add_theme_font_size_override("font_size", 20)
	b.focus_mode = Control.FOCUS_NONE
	return b


## Latimea cartonasului se ia din ecran: pe 16:9 si pe telefon incape intreg
## intre panoul de telemetrie si coloana din dreapta; pe 4:3 se ingusteaza.
func _place_card() -> void:
	if _card == null:
		return
	var w := clampf(size.x - 2.0 * SIDE_CLEAR, CARD_MIN_W, CARD_MAX_W)
	_card.custom_minimum_size = Vector2(w, 0)
	_card.size = Vector2(w, 0)
	_card.reset_size()
	_card.position = Vector2((size.x - w) * 0.5, CARD_TOP)


func show_step(step: StringName, index: int, count: int, progress: float,
		sub: String, nudge: bool) -> void:
	_step = step
	_nudge = nudge
	_card.visible = true
	_skip.visible = true
	_continue.visible = false
	_title.text = _text(String(step) + "_title")
	_counter.text = "" if step == TutorialDirector.STEP_INTRO \
		else "%d / %d" % [index + 1, count]
	_body.text = _text(String(step) + "_body") if step == TutorialDirector.STEP_INTRO \
		else _hint_text(step)
	_sub.text = sub
	_sub.visible = sub != ""
	_bar_bg.visible = step != TutorialDirector.STEP_INTRO
	_bar_fill.size = Vector2(_bar_bg.size.x * clampf(progress, 0.0, 1.0), 6.0)
	_place_card()
	queue_redraw()


func show_done() -> void:
	_step = TutorialDirector.STEP_DONE
	_nudge = false
	_card.visible = true
	_title.text = _text("done_title")
	_counter.text = ""
	_body.text = _text("done_body")
	_sub.visible = false
	_bar_bg.visible = false
	_skip.visible = false
	_continue.visible = true
	_place_card()
	queue_redraw()


func hide_card() -> void:
	_card.visible = false
	_step = &""
	queue_redraw()


## Textul indiciului in modul curent: butonul pe touch, tasta pe tastatura.
func _hint_text(step: StringName) -> String:
	var key := String(step) + ("_touch" if touch_mode else "_keys")
	var text := _text(key)
	if touch_mode:
		return text
	for action in ["steer_left", "steer_right", "accelerate", "brake", "drift", "turbo"]:
		text = text.replace("{%s}" % action, key_name(action))
	return text


func _text(prop: String) -> String:
	if config == null:
		return ""
	var v: Variant = config.get(prop)
	return String(v) if v != null else ""


## Prima tasta a actiunii din InputMap, cu majuscule („W", „SHIFT", „SPACE").
static func key_name(action: StringName) -> String:
	if InputMap.has_action(action):
		for ev in InputMap.action_get_events(action):
			var k := ev as InputEventKey
			if k == null:
				continue
			var code := k.physical_keycode if k.physical_keycode != KEY_NONE else k.keycode
			return OS.get_keycode_string(code).to_upper()
	return String(action).to_upper()


## Zonele de touch evidentiate de pasul curent (fara „bar").
func highlighted_zones() -> Array[String]:
	var out: Array[String] = []
	if not touch_mode or not visible or not _card.visible:
		return out
	for z in HIGHLIGHTS.get(_step, []):
		if z != "bar":
			out.append(String(z))
	return out


## Zonele care PULSEAZA acum: pe touch, dupa `nudge_after_s` fara gest.
func pulsing_zones() -> Array[String]:
	if _nudge:
		return highlighted_zones()
	var none: Array[String] = []
	return none


func bar_highlighted() -> bool:
	return visible and _card.visible and "bar" in HIGHLIGHTS.get(_step, [])


## Dreptunghiurile care conteaza pentru sonda de layout.
func card_rect() -> Rect2:
	return _card.get_global_rect()


func skip_button() -> Button:
	return _skip


func continue_button() -> Button:
	return _continue


func body_text() -> String:
	return _body.text


func sub_text() -> String:
	return _sub.text if _sub.visible else ""


## Raza maxima a inelului din jurul unui disc de raza `r` (la varful pulsului).
static func ring_outer_radius(r: float) -> float:
	return r + RING_GAP + RING_GROW + RING_WIDTH * 0.5


func _input(event: InputEvent) -> void:
	# Doar observam (nu consumam): modul urmeaza ultimul fel de input.
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		touch_mode = true
	elif event is InputEventKey and (event as InputEventKey).pressed:
		touch_mode = false


func _process(delta: float) -> void:
	# Pe pauza si peste rezultate stratul se da la o parte (pauza are panoul
	# ei, iar HUD-ul ruleaza ALWAYS, deci si noi).
	var paused := get_tree().paused
	if _holder != null:
		_holder.visible = not paused
	_time += delta
	if _step != &"" and not paused:
		queue_redraw()


func _draw() -> void:
	if get_tree().paused or _card == null or not _card.visible:
		return
	# 0..1, la ~1.4 Hz: destul de lent ca sa nu para alarma.
	var wave := 0.5 + 0.5 * sin(_time * TAU * 1.4)
	if bar_highlighted() and _bar_rect_fn.is_valid():
		var r: Rect2 = _bar_rect_fn.call()
		r.position -= global_position
		var grow := 6.0 + 4.0 * wave
		var sb := StyleBoxFlat.new()
		sb.draw_center = false
		sb.set_corner_radius_all(int(r.size.y * 0.5 + grow))
		sb.set_border_width_all(3)
		sb.border_color = Color(HINT_COLOR, 0.55 + 0.4 * wave)
		draw_style_box(sb, r.grow(grow))
	if _touch == null:
		return
	var pulsing := pulsing_zones()
	for zone in highlighted_zones():
		var disc := _touch.button_disc(zone)
		var c := _touch.global_position + disc.get_center() - global_position
		var r0 := disc.size.x * 0.5
		var pulse := zone in pulsing
		var rr := r0 + RING_GAP + (RING_GROW * wave if pulse else 0.0)
		var a := (0.45 + 0.55 * wave) if pulse else 0.55
		draw_arc(c, rr, 0.0, TAU, 64, Color(HINT_COLOR, a), RING_WIDTH, true)
