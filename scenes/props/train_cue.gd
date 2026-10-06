class_name TrainCue
extends Node3D
## TRENUL "LA CHEMARE" (Kyoto, POI G2; brief kyoto.md, randul G2).
##
## Un tren pe o bucla libera de ~350 m, din care doar ~10 s sunt peste drum,
## are sanse mici sa fie pe viaduct taman cand treci pe sub el (masurat cu
## ProbeRace --train-cam: <1 s vizibil pe tur). Aici trenul sta PARCAT sub
## pamant, in ascunzis, si e lansat de sosirea jucatorului: ETA-ul camerei pana
## la viaduct (viteza curenta, limitata la un interval realist) hotaraste CAND
## porneste, ca centrul trenului sa fie deasupra soselei in clipa in care camera
## mai are `lead_m` pana la ea. ETA-ul cu viteza curenta minte putin (virajele,
## turbo-ul), dar trenul sta ~4 s pe punte si inca ~6 s pe rampe, deci fereastra
## [rapid, lent] a sosirii incape in ea.
##
## Teatru: trenul n-are coliziune, deci cursa nu se schimba. Teleportarile sunt
## intre doua puncte SUB TEREN (parcare <-> cap de ramp), invizibile.
##
## Cum afla "unde e jucatorul": camera activa (la fel ca LeafFall), proiectata pe
## ruta principala. Fara camera sau fara ruta nu face nimic (trenul ramane parcat).

@export var mover_path: NodePath = ^"../gTren96"
## Indicii punctelor curbei trenului: parcarea (capul rampei, sub teren), cele
## doua capete ale puntii (centrul lor e deasupra soselei) si punctul de dupa
## care trenul e ascuns in desis si se intoarce in parcare.
@export var park_point: int = 7
@export var deck_a_point: int = 1
@export var deck_b_point: int = 2
@export var hide_point: int = 4
## Cat mai are camera pana la viaduct cand centrul trenului e deasupra drumului.
@export_range(0.0, 400.0, 1.0, "suffix:m") var lead_m: float = 80.0
## Limitele vitezei folosite la ETA (m/s). Viteza curenta se netezeste.
@export_range(5.0, 60.0, 0.5, "suffix:m/s") var v_min: float = 29.0
@export_range(5.0, 80.0, 0.5, "suffix:m/s") var v_max: float = 38.0
## Cat de sus (m) fata de ruta e trenul "peste drum"; sub ea punctul nu se mai
## considera viaduct (sonde).
@export var enabled: bool = true

enum State { PARCAT, PE_DRUM }

var state: State = State.PARCAT
## Ultima lansare: (timp, distanta camerei pana la viaduct, viteza folosita).
var last_release: Vector3 = Vector3.ZERO
var releases: int = 0

var _mover: PathMover
var _track: Track
var _idx: int = 0
var _tick: int = 0
var _prev_d: float = -1.0
var _v: float = 28.0
var _run_speed: float = 8.75
var _off_park: float = 0.0
var _off_deck_a: float = 0.0
var _off_deck_b: float = 0.0
var _off_hide: float = 0.0
var _d_cross: float = -1.0
var _t: float = 0.0
var _ready_done: bool = false


func _ready() -> void:
	_setup.call_deferred()


func _setup() -> void:
	_mover = get_node_or_null(mover_path) as PathMover
	var n: Node = get_parent()
	while n != null and not n is Track:
		n = n.get_parent()
	_track = n as Track
	if _mover == null or _mover.curve == null or _mover.points.size() <= maxi(park_point, hide_point):
		return
	var c := _mover.curve
	_off_park = c.get_closest_offset(_mover.points[park_point])
	_off_deck_a = c.get_closest_offset(_mover.points[deck_a_point])
	_off_deck_b = c.get_closest_offset(_mover.points[deck_b_point])
	_off_hide = c.get_closest_offset(_mover.points[hide_point])
	_run_speed = _mover.speed
	if not enabled:
		return
	# Parcat de la primul tick: faza si viteza 0 (faza se aplica la primul tick).
	_mover.phase = _off_park / maxf(c.get_baked_length(), 1.0)
	_mover.speed = 0.0
	if _track != null and _track.routes.size() > 0:
		var mid_local := (_mover.points[deck_a_point] + _mover.points[deck_b_point]) * 0.5
		var route := _track.route_at(0)
		if route.baked.size() > 1:
			var gi := route.closest_index_global(_mover.to_global(mid_local))
			_d_cross = route.dists[gi]
	_ready_done = _d_cross >= 0.0


## Distanta (m, pe ruta) a viaductului, pentru sonde.
func cross_dist() -> float:
	return _d_cross


func _physics_process(delta: float) -> void:
	if not _ready_done or not enabled:
		return
	_t += delta
	var cam := get_viewport().get_camera_3d()
	if cam == null or _track == null:
		return
	var route := _track.route_at(0)
	_tick += 1
	if _tick == 1 or _idx == 0:
		_idx = route.closest_index_global(cam.global_position)
	else:
		_idx = route.closest_index(_idx, cam.global_position)
	var total := route.dists[route.baked.size()]
	var d := route.dists[clampi(_idx, 0, route.baked.size() - 1)]
	# Viteza reala a camerei pe ruta, neteazita (tur inchis: diferenta pe cerc).
	if _prev_d >= 0.0 and delta > 0.0:
		var dd := d - _prev_d
		if dd < -total * 0.5:
			dd += total
		elif dd > total * 0.5:
			dd -= total
		_v = lerpf(_v, clampf(dd / delta, v_min, v_max), minf(delta * 2.0, 1.0))
	_prev_d = d
	if state == State.PE_DRUM:
		# Dupa ce a intrat in desisul de dincolo de viaduct, e ascuns: inapoi in parcare.
		var o := _mover.offset()
		if o >= _off_hide and o < _off_hide + 60.0:
			_park()
		return
	var dc := _d_cross - d
	if dc < -total * 0.5:
		dc += total
	if dc <= 0.0:
		return
	# Unde trebuie sa fie trenul ACUM ca sa ajunga la centrul puntii in clipa in
	# care camera mai are `lead_m`: centru - viteza_tren * timp.
	var eta := maxf(dc - lead_m, 0.0) / _v
	var length := _mover.curve.get_baked_length()
	# Pozitiile se masoara DE LA PARCARE, pe sensul de mers (bucla: modulo lungime).
	var rel_center := fposmod((_off_deck_a + _off_deck_b) * 0.5 - _off_park, length)
	var rel_end := fposmod(_off_deck_b - _off_park, length)
	var want := rel_center - _run_speed * eta
	if want < 0.0:
		return # prea devreme: trenul asteapta in parcare
	_release(fposmod(_off_park + minf(want, rel_end), length), dc)


func _release(offset: float, dc: float) -> void:
	state = State.PE_DRUM
	_mover.speed = _run_speed
	_mover.seek(offset)
	releases += 1
	last_release = Vector3(_t, dc, _v)
	#print("DBG release t=%.1f dc=%.0f d_cross=%.0f idx=%d cam=%s elapsed=%.1f" % [_t, dc, _d_cross, _idx, get_viewport().get_camera_3d().global_position, Time.get_ticks_msec() / 1000.0])


func _park() -> void:
	state = State.PARCAT
	_mover.speed = 0.0
	_mover.seek(_off_park)
