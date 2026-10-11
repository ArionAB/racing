class_name TouchScrollContainer
extends ScrollContainer
## ScrollContainer care se deruleaza tragand cu degetul ORIUNDE pe lista, nu doar
## pe bara. Cel nativ porneste tragerea doar daca apasarea ajunge la el — dar
## cartonasele si sliderele opresc evenimentul, deci pe un meniu plin de butoane
## nu ramanea aproape nicio suprafata de tras. Pe desktop nu tragea deloc
## (Godot cere ecran tactil).
##
## Ascultam in _input, inaintea GUI-ului: apasarea merge normal la buton; abia
## cand degetul a mers vertical peste prag luam tragerea, eliberam butonul cu un
## release fals in afara ecranului (deci nu se apasa) si derulam noi. Mouse-ul
## e emulat din touch pe telefon, deci un singur traseu pentru ambele.

## Pixeli de miscare verticala pana devine derulare, nu atingere.
@export var drag_threshold := 14.0
## Latimea barei — tinta de deget, nu de cursor.
@export var bar_width := 28
## Cat din viteza ramane dupa o secunda de alunecare (inertie la aruncare).
@export_range(0.0, 1.0) var fling_keep_per_second := 0.04

const _FAR := Vector2(-100000.0, -100000.0)

var _pressing := false
var _dragging := false
var _press_pos := Vector2.ZERO
var _press_scroll := 0.0
var _velocity := 0.0 # px/s, in sensul scroll_vertical
var _last_y := 0.0
var _last_usec := 0
## Sliderele sar la valoarea de sub deget la apasare. Daca apasarea era de fapt
## inceputul unei derulari, le punem valoarea inapoi.
var _slider_restore: Array = [] # [[Range, float], ...]


func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_style_bar(get_v_scroll_bar())


func _style_bar(bar: ScrollBar) -> void:
	var half := bar_width * 0.5
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.07, 0.09, 0.14, 0.75)
	track.set_corner_radius_all(int(half))
	track.content_margin_left = half
	track.content_margin_right = half
	var grab := StyleBoxFlat.new()
	grab.bg_color = Color(0.45, 0.53, 0.68)
	grab.set_corner_radius_all(int(half))
	grab.content_margin_left = half
	grab.content_margin_right = half
	grab.content_margin_top = bar_width
	var grab_hi := grab.duplicate() as StyleBoxFlat
	grab_hi.bg_color = Color(0.60, 0.68, 0.82)
	var grab_down := grab.duplicate() as StyleBoxFlat
	grab_down.bg_color = Color(0.85, 0.72, 0.35)
	bar.add_theme_stylebox_override("scroll", track)
	bar.add_theme_stylebox_override("scroll_focus", track)
	bar.add_theme_stylebox_override("grabber", grab)
	bar.add_theme_stylebox_override("grabber_highlight", grab_hi)
	bar.add_theme_stylebox_override("grabber_pressed", grab_down)
	bar.custom_minimum_size.x = bar_width


## Taiem tragerea nativa (ar derula si ea, peste noi); rotita trece mai departe.
func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
	elif event is InputEventMouseMotion and _pressing:
		accept_event()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var mb := event as InputEventMouseButton
	if mb and mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.position == _FAR:
			return # eliberarea noastra falsa, lasata sa ajunga la buton
		if mb.pressed:
			_on_press(mb.position)
		elif _pressing:
			if _dragging:
				get_viewport().set_input_as_handled()
				# Degetul oprit inainte de ridicare = fara aruncare.
				if Time.get_ticks_usec() - _last_usec > 100000:
					_velocity = 0.0
			_pressing = false
			_dragging = false
		return
	var mm := event as InputEventMouseMotion
	if mm and _pressing and mm.position != _FAR:
		_on_motion(mm)


func _on_press(pos: Vector2) -> void:
	_velocity = 0.0
	if not get_global_rect().has_point(pos) or _on_bar(pos):
		return
	_pressing = true
	_dragging = false
	_press_pos = pos
	_press_scroll = scroll_vertical
	_slider_restore.clear()
	for s in find_children("*", "Slider", true, false):
		var slider := s as Slider
		if slider.is_visible_in_tree() and slider.get_global_rect().has_point(pos):
			_slider_restore.append([slider, slider.value])


func _on_motion(mm: InputEventMouseMotion) -> void:
	var delta := mm.position - _press_pos
	if not _dragging:
		# Doar tragerea preponderent verticala; orizontal ramane al sliderelor.
		if absf(delta.y) < drag_threshold or absf(delta.y) < absf(delta.x):
			return
		_dragging = true
		_release_gui_press.call_deferred()
		# Pornim din punctul curent, fara saltul pragului.
		_press_pos = mm.position
		_press_scroll = scroll_vertical
		_last_y = mm.position.y
		_last_usec = Time.get_ticks_usec()
	get_viewport().set_input_as_handled()
	scroll_vertical = roundi(_press_scroll - (mm.position.y - _press_pos.y))
	var now := Time.get_ticks_usec()
	var dt := (now - _last_usec) / 1000000.0
	if dt > 0.0:
		_velocity = lerpf(_velocity, -(mm.position.y - _last_y) / dt, 0.5)
		_last_y = mm.position.y
		_last_usec = now


## Butonul care a primit apasarea afla ca degetul a iesit de pe el (BaseButton
## isi actualizeaza "inauntru" doar din miscari, iar pe ale noastre le-am
## inghitit), apoi primeste eliberarea: isi pierde starea apasata fara sa
## emita pressed; sliderul elibereaza manerul si primeste valoarea de dinainte.
func _release_gui_press() -> void:
	var away := InputEventMouseMotion.new()
	away.button_mask = MOUSE_BUTTON_MASK_LEFT
	away.position = _FAR
	away.global_position = _FAR
	get_viewport().push_input(away, true)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = _FAR
	up.global_position = _FAR
	get_viewport().push_input(up, true)
	# Dupa eliberare: miscarea falsa a tras si ea sliderul, la capatul stang.
	for pair in _slider_restore:
		(pair[0] as Slider).value = pair[1]
	_slider_restore.clear()


func _on_bar(pos: Vector2) -> bool:
	var bar := get_v_scroll_bar()
	return bar.visible and bar.get_global_rect().has_point(pos)


func _process(delta: float) -> void:
	if _pressing or _velocity == 0.0:
		return
	if absf(_velocity) < 20.0:
		_velocity = 0.0
		return
	scroll_vertical = roundi(scroll_vertical + _velocity * delta)
	_velocity *= pow(fling_keep_per_second, delta)
	var bar := get_v_scroll_bar()
	if scroll_vertical <= 0 or scroll_vertical >= int(bar.max_value - bar.page):
		_velocity = 0.0
