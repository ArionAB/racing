class_name TouchControls
extends Control
## Controale touch: butoane explicite, fara zone de jumatate de ecran.
##
##   stanga-jos:  [ < ] [ > ]                           viraj
##   dreapta-jos:            [ TURBO ] [ ^ ]             turbo, gaz
##                                     [(P)]             frana de mana
##
## Aranjamentul e decizia dezvoltatorului dupa primul test pe iPhone (oct
## 2026): fara auto-accelerate. TURBO da si gaz — nu trebuie tinut si ^ in
## acelasi timp. < si > stau apropiate (STEER_GAP). A doua runda (oct 2026):
## ^ si frana de mana lipite de marginea din dreapta, TURBO in stanga lui ^,
## iar fosta sageata jos e acum frana de mana — drift in viraj, frana in
## linie dreapta, marsarier de pe loc (vezi `PlayerController`).
##
## Evenimente touch brute pentru multitouch corect; fiecare deget isi
## re-evalueaza butonul la glisare (degetul mare aluneca de pe < pe > sau de
## pe ^ pe (P) fara sa se ridice). Starea se scrie in GameState.

const BUTTON_RADIUS: float = 66.0
const TURBO_SCALE: float = 1.15
## Toleranta in jurul cercului: degetul nu nimereste centrul pe sticla.
const HIT_SLACK: float = 18.0
const EDGE_MARGIN: float = 34.0
const PEDAL_GAP: float = 18.0
## Golul dintre < si >. Prima varianta avea un buton intreg (132); la volan,
## dezvoltatorul le-a vrut apropiate.
const STEER_GAP: float = 22.0

var _touches: Dictionary = {} # index deget -> buton ("left"/"right"/"up"/"handbrake"/"turbo"/"")

func _ready() -> void:
	# _AND_OFFSETS: in arbore, set_anchors_preset singur pastreaza dreptunghiul
	# curent (0x0) prin offset-uri de -latime. Controlul ramanea 0x0, deci
	# butoanele se calculau fata de un ecran de latime zero; pe iPhone, primul
	# test, nu se putea vira deloc.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _exit_tree() -> void:
	GameState.reset_touch()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_touches[touch.index] = _button_at(touch.position)
		else:
			_touches.erase(touch.index)
		_refresh()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if _touches.has(drag.index):
			var b := _button_at(drag.position)
			if b != _touches[drag.index]:
				_touches[drag.index] = b
				_refresh()

func _refresh() -> void:
	var held: Array = _touches.values()
	var steer := 0.0
	if held.has("left"):
		steer -= 1.0
	if held.has("right"):
		steer += 1.0
	GameState.touch_steer = steer
	# TURBO tinut singur da si gaz: turbo fara acceleratie n-are sens.
	# Frana de mana nu e pedala: ce face din ea decide controllerul, care
	# stie viteza masinii.
	GameState.touch_handbrake = held.has("handbrake")
	if held.has("up") or held.has("turbo"):
		GameState.touch_throttle = 1.0
	else:
		GameState.touch_throttle = 0.0
	GameState.touch_turbo = held.has("turbo")
	queue_redraw()

# ---------------------------------------------------------------- geometrie

## Butonul sub punctul dat, sau "" daca degetul a cazut intre butoane.
func _button_at(pos: Vector2) -> String:
	var best := ""
	var best_d := INF
	var layout := _layout()
	for b: String in layout:
		var c: Vector2 = layout[b][0]
		var r: float = layout[b][1]
		var d := pos.distance_to(c)
		if d < r + HIT_SLACK and d < best_d:
			best = b
			best_d = d
	return best

## Centrul si raza fiecarui buton, in coordonatele controlului.
func _layout() -> Dictionary:
	var inset := _safe_insets()
	var r := BUTTON_RADIUS
	var rt := BUTTON_RADIUS * TURBO_SCALE
	var bottom := size.y - maxf(EDGE_MARGIN, inset.w)
	var left_x := maxf(EDGE_MARGIN, inset.x) + r
	var right_edge := size.x - maxf(EDGE_MARGIN, inset.z)
	var left_c := Vector2(left_x, bottom - r)
	var hand_c := Vector2(right_edge - r, bottom - r)
	var up_c := hand_c - Vector2(0.0, 2.0 * r + PEDAL_GAP)
	return {
		"left": [left_c, r],
		"right": [left_c + Vector2(2.0 * r + STEER_GAP, 0.0), r],
		"handbrake": [hand_c, r],
		"up": [up_c, r],
		"turbo": [up_c - Vector2(r + PEDAL_GAP + rt, 0.0), rt],
	}

## Zona sigura a ecranului (notch, colturi rotunjite, bara home), in unitatile
## controlului: (stanga, sus, dreapta, jos). Pe desktop iese zero.
func _safe_insets() -> Vector4:
	var win := Vector2(DisplayServer.window_get_size())
	if win.x <= 0.0 or win.y <= 0.0 or size.x <= 0.0:
		return Vector4.ZERO
	var safe := Rect2(DisplayServer.get_display_safe_area())
	if safe.size.x <= 0.0 or safe.size.y <= 0.0:
		return Vector4.ZERO
	var k := size.x / win.x
	return Vector4(safe.position.x, safe.position.y,
		win.x - safe.end.x, win.y - safe.end.y) * k

# ------------------------------------------------------------------- desen

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var held: Array = _touches.values()
	var layout := _layout()
	for b: String in layout:
		var c: Vector2 = layout[b][0]
		var r: float = layout[b][1]
		var on := held.has(b)
		var fill := Color(1.0, 0.6, 0.15, 0.38 if on else 0.18) if b == "turbo" \
			else Color(1, 1, 1, 0.30 if on else 0.14)
		draw_circle(c, r, fill)
		draw_arc(c, r, 0.0, TAU, 48, Color(1, 1, 1, 0.35), 2.0, true)
		var ink := Color(1, 1, 1, 0.9 if on else 0.75)
		match b:
			"left":
				_draw_arrow(c, Vector2.LEFT, r, ink)
			"right":
				_draw_arrow(c, Vector2.RIGHT, r, ink)
			"up":
				_draw_arrow(c, Vector2.UP, r, ink)
			"handbrake":
				_draw_handbrake(c, r, font, ink)
			"turbo":
				draw_string(font, c + Vector2(-40, 8), "TURBO",
					HORIZONTAL_ALIGNMENT_CENTER, 80, 22, ink)

## Triunghi plin in directia data. Desenat, nu glif: fontul de rezerva nu are
## garantat sagetile Unicode pe toate platformele.
func _draw_arrow(c: Vector2, dir: Vector2, r: float, col: Color) -> void:
	var s := r * 0.42
	var side := Vector2(-dir.y, dir.x)
	var tip := c + dir * s
	var base := c - dir * s * 0.7
	draw_colored_polygon(PackedVector2Array([
		tip, base + side * s, base - side * s]), col)

## Simbolul de frana de mana din bord: P intr-un cerc, intre doua paranteze.
func _draw_handbrake(c: Vector2, r: float, font: Font, col: Color) -> void:
	var w := maxf(r * 0.07, 3.0)
	draw_arc(c, r * 0.36, 0.0, TAU, 40, col, w, true)
	var side := deg_to_rad(42.0)
	draw_arc(c, r * 0.56, PI - side, PI + side, 16, col, w, true)
	draw_arc(c, r * 0.56, -side, side, 16, col, w, true)
	var fs := int(r * 0.42)
	draw_string(font, c + Vector2(-r, fs * 0.36), "P",
		HORIZONTAL_ALIGNMENT_CENTER, 2.0 * r, fs, col)
