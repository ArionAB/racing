class_name TouchControls
extends Control
## Controale touch (portate din racing 2D): jumatatea stanga/dreapta a
## ecranului vireaza (auto-accelerate, fara pedala) + butoane mari pentru
## TURBO si DRIFT (dreapta-jos). Evenimente touch brute pentru multitouch
## corect; starea se scrie in GameState.
##
## Butoanele de viraj din stanga-jos sunt DESENATE, dar zona de atingere
## ramane toata jumatatea de ecran: pe un telefon in miscare, o tinta de 80 px
## se rateaza, iar un viraj ratat se citeste ca joc stricat. Butoanele spun
## jucatorului UNDE sa puna degetul; jumatatea de ecran il iarta cand nu
## nimereste.

const BUTTON_RADIUS: float = 78.0
## Butoanele de viraj: mai mici decat zona lor reala de atingere, perechea
## asezata in coltul din stanga-jos ca in orice racer de mobil.
const STEER_RADIUS: float = 52.0

var _touches: Dictionary = {} # index deget -> zona ("left"/"right"/"drift"/"turbo")

func _ready() -> void:
	# ..._and_offsets_...: ancorele singure lasa `size` pe (0,0) pana cand
	# viewport-ul trimite o redimensionare. In joc asta vine de la sine si
	# nu s-a vazut niciodata, dar butoanele se aseaza din `size`, deci pana
	# la prima redimensionare se desenau in afara ecranului.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
				queue_redraw()

## Zonele de atingere sunt mai LARGI decat discurile desenate (92 si 84 fata de
## 78 si 70): pe un telefon care se misca, degetul cade langa buton, nu pe el.
## Ele se suprapun — centrele sunt la 168 px — asa ca punctul din suprapunere
## merge la butonul al carui CENTRU e mai aproape, nu la primul testat. Altfel
## marginea dinspre turbo a lui DRIFT ar fi raspuns „turbo", si ai fi ars bara
## incercand sa derapezi.
func _zone_at(pos: Vector2) -> String:
	var d_turbo := pos.distance_to(_turbo_center())
	var d_drift := pos.distance_to(_drift_center())
	var in_turbo := d_turbo < BUTTON_RADIUS + 14.0
	var in_drift := d_drift < BUTTON_RADIUS + 6.0
	if in_turbo and in_drift:
		return "turbo" if d_turbo <= d_drift else "drift"
	if in_turbo:
		return "turbo"
	if in_drift:
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

## TURBO si DRIFT stau amandoua sub degetul drept — „actionez" intr-o mana,
## „conduc" in cealalta. TURBO e cel exterior (se apasa cel mai des, degetul
## mare ajunge la colt fara sa intinda mana).
func _turbo_center() -> Vector2:
	return Vector2(size.x - 128.0, size.y - 128.0)

## Distanta intre centre: razele sunt 78 si 70, deci de la 160 px in sus
## discurile nu se mai ating. 168 lasa si o margine de aer intre ele.
func _drift_center() -> Vector2:
	return Vector2(size.x - 296.0, size.y - 128.0)

func _steer_left_center() -> Vector2:
	return Vector2(118.0, size.y - 128.0)

func _steer_right_center() -> Vector2:
	return Vector2(262.0, size.y - 128.0)


## Un buton rotund de HUD: disc translucid, inel subtire, glifa in mijloc.
## `tint` coloreaza inelul si glifa cand butonul e activ.
func _draw_round_button(center: Vector2, radius: float, pressed: bool,
		tint: Color) -> void:
	draw_circle(center, radius, Color(0.04, 0.05, 0.08, 0.62 if pressed else 0.42))
	draw_arc(center, radius, 0.0, TAU, 48,
		Color(tint.r, tint.g, tint.b, 0.9 if pressed else 0.45), 2.5, true)


## Triunghiul plin al butoanelor de viraj. `dir` = -1 pentru stanga, +1 pentru
## dreapta. Desenat ca poligon: fontul implicit nu are glifele de triunghi la
## marimea asta si ar fi iesit o caseta goala pe Android.
func _draw_steer_arrow(center: Vector2, dir: float, active: bool) -> void:
	var w := 15.0
	var h := 19.0
	var points := PackedVector2Array([
		center + FLAME_SCALE * Vector2(w * dir, 0.0),
		center + FLAME_SCALE * Vector2(-w * dir, -h),
		center + FLAME_SCALE * Vector2(-w * dir, h)])
	draw_colored_polygon(points, Color(1, 1, 1, 0.95 if active else 0.72))


## Flacara butonului de TURBO. Si ea poligon, nu glifa: „⚡"/„\U0001F525" se
## randeaza ca o caseta goala pe fontul implicit de pe Android. Silueta e o
## lacrima asimetrica — varf inclinat, baza rotunda — construita din cateva
## puncte, nu o curba: la 34 px nimeni nu vede diferenta.
## Cat de mare e flacara fata de cifrele de mai jos. Silueta e desenata pentru
## ~46 px inaltime; intr-un disc de 156 px arata ca un punct, deci o crestem.
const FLAME_SCALE: float = 1.45

func _draw_flame(center: Vector2, active: bool) -> void:
	# Silueta NU e simetrica si nu e o lacrima: o lacrima (varf rotunjit sus,
	# burta jos) se citeste ca picatura de apa — prima incercare a iesit exact
	# asa pe captura. Flacara are varful INCLINAT intr-o parte, o umflatura pe
	# o latura, si o scobitura in baza, intre cele doua „picioare".
	var pts := PackedVector2Array([
		center + FLAME_SCALE * Vector2(2.0, -26.0),    # varful, impins spre dreapta
		center + FLAME_SCALE * Vector2(10.0, -10.0),
		center + FLAME_SCALE * Vector2(16.0, 2.0),     # umarul drept, lat
		center + FLAME_SCALE * Vector2(15.0, 13.0),
		center + FLAME_SCALE * Vector2(7.0, 20.0),     # piciorul drept
		center + FLAME_SCALE * Vector2(0.0, 13.0),     # scobitura din baza
		center + FLAME_SCALE * Vector2(-7.0, 20.0),    # piciorul stang
		center + FLAME_SCALE * Vector2(-14.0, 11.0),
		center + FLAME_SCALE * Vector2(-15.0, -1.0),   # umarul stang
		center + FLAME_SCALE * Vector2(-8.0, -13.0),
		center + FLAME_SCALE * Vector2(-3.0, -20.0),
	])
	draw_colored_polygon(pts, Color(1, 1, 1, 0.97 if active else 0.82))
	# Inima flacarii: aceeasi silueta micsorata si coborata, ca sa ramana o
	# rama alba vizibila in jurul ei. Portocaliul lasat singur, fara rama, se
	# pierde pe fundalul de nisip — tocmai tema pe care butonul sta cel mai des.
	var core := PackedVector2Array()
	for p in pts:
		core.append(center + (p - center) * 0.50 + Vector2(0.0, 5.0))
	draw_colored_polygon(core,
		Color(1.0, 0.52, 0.10, 0.95 if active else 0.80))


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var zones: Array = _touches.values()
	var turbo_active: bool = zones.has("turbo")
	var drift_active: bool = zones.has("drift")

	# TURBO: portocaliu, cu flacara. Cel mai mare buton de pe ecran — e si
	# actiunea cea mai frecventa, si singura cu consecinta imediata la viteza.
	var flame := Color(1.0, 0.62, 0.18)
	_draw_round_button(_turbo_center(), BUTTON_RADIUS, turbo_active, flame)
	_draw_flame(_turbo_center(), turbo_active)

	# DRIFT: alb-rece, cu „P" de handbrake (frana de mana — drift-ul e
	# handbrake pur in modelul nostru, vezi CLAUDE.md principiul 2).
	var ice := Color(0.55, 0.85, 1.0)
	_draw_round_button(_drift_center(), BUTTON_RADIUS * 0.9, drift_active, ice)
	draw_string(font, _drift_center() + Vector2(-10, 11), "P",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 32,
		Color(1, 1, 1, 0.95 if drift_active else 0.78))

	# Virajul: butoanele arata unde sa pui degetul, dar se aprind din ZONA
	# apasata, nu din buton — altfel ai fi vazut sageata stinsa in timp ce
	# masina vireaza, si ai fi crezut ca butonul nu merge.
	var left_active: bool = zones.has("left")
	var right_active: bool = zones.has("right")
	var pale := Color(1, 1, 1)
	_draw_round_button(_steer_left_center(), STEER_RADIUS, left_active, pale)
	_draw_steer_arrow(_steer_left_center(), -1.0, left_active)
	_draw_round_button(_steer_right_center(), STEER_RADIUS, right_active, pale)
	_draw_steer_arrow(_steer_right_center(), 1.0, right_active)
