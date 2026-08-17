class_name TouchControls
extends Control
## Controale touch (portate din racing 2D): jumatatea stanga/dreapta a
## ecranului vireaza (auto-accelerate, fara pedala) + butoane mari pentru
## TURBO (dreapta-jos) si DRIFT (stanga-jos). Evenimente touch brute pentru
## multitouch corect; starea se scrie in GameState.

const BUTTON_RADIUS: float = 78.0

var _touches: Dictionary = {} # index deget -> zona ("left"/"right"/"drift"/"turbo")

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _exit_tree() -> void:
	GameState.reset_touch()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_touches[touch.index] = _zone_at(touch.position)
		else:
			_touches.erase(touch.index)
		_refresh()
		queue_redraw()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if _touches.get(drag.index, "") in ["left", "right"]:
			var zone := _zone_at(drag.position)
			if zone in ["left", "right"]:
				_touches[drag.index] = zone
				_refresh()

func _zone_at(pos: Vector2) -> String:
	if pos.distance_to(_turbo_center()) < BUTTON_RADIUS + 14.0:
		return "turbo"
	if pos.distance_to(_drift_center()) < BUTTON_RADIUS + 6.0:
		return "drift"
	return "left" if pos.x < size.x * 0.5 else "right"

func _refresh() -> void:
	var steer := 0.0
	var drift := false
	var turbo := false
	for zone in _touches.values():
		match zone:
			"left":
				steer -= 1.0
			"right":
				steer += 1.0
			"drift":
				drift = true
			"turbo":
				turbo = true
	GameState.touch_steer = clampf(steer, -1.0, 1.0)
	GameState.touch_drift = drift
	GameState.touch_turbo = turbo
	GameState.touch_active = not _touches.is_empty()

func _turbo_center() -> Vector2:
	return Vector2(size.x - 130.0, size.y - 130.0)

func _drift_center() -> Vector2:
	return Vector2(130.0, size.y - 130.0)

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var turbo_active: bool = _touches.values().has("turbo")
	var drift_active: bool = _touches.values().has("drift")
	draw_circle(_turbo_center(), BUTTON_RADIUS,
		Color(1.0, 0.6, 0.15, 0.35 if turbo_active else 0.16))
	draw_string(font, _turbo_center() + Vector2(-38, 8), "TURBO",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.85))
	draw_circle(_drift_center(), BUTTON_RADIUS * 0.9,
		Color(1, 1, 1, 0.28 if drift_active else 0.14))
	draw_string(font, _drift_center() + Vector2(-34, 8), "DRIFT",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.8))
