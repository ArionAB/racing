extends Node
## Sonda de AMPLASARE a haboob-ului pe Track19 (Monument Valley, brief §1 si §3):
## nu intreaba CUM se misca zidul (asta e ProbeHaboob), ci UNDE sta fata de drum.
##
##  (1) zidul atinge drumul DOAR pe fractiile declarate (G 0.600-0.834, G prim
##      inclus): intervalul atins pe tot ciclul de 101 s, cu soseaua latita cu
##      semilatimea ei.
##  (2) contractul de telegraf din brief §1: din punctele lui F (pas >= 5 m),
##      azimutul centrului frontului fata de directia de mers <= 50 grade pe
##      >= 60% din puncte, in TOATA fereastra de 8 s dinaintea primei atingeri a
##      drumului din G, cu zidul vizibil (acoperire > 0.5).
##  (3) zona nu se suprapune cu arcul (fractia 0.434) si nici cu vreo CameraZone.
##  (4) la t=0 al cursei zidul e in liniste: acoperire 0, ascuns, nicio atingere.
##
## Geometria drumului vine din Track (`point_at`, `frac_at`), nu din functiile
## hazardului: hazardul da doar transformul zidului si dimensiunile lui, nu
## raspunsul „atinge / nu atinge".
##
## `--sabotaj`: roteste Path-ul zidului cu 90 de grade (zidul vine din alta
## parte); sonda TREBUIE sa pice. Cod: 1 = a picat (garda armata), 3 = a trecut
## (garda moarta), 2 = n-am masurat nimic.
##
## Ruleaza CA SCENA: godot --headless --fixed-fps 60 res://tools/ProbeHaboobPos.tscn [-- --sabotaj]

const G_FROM: float = 0.600
const G_TO: float = 0.834
## Toleranta pe fractie (un pas de esantionare in plus).
const FRAC_EPS: float = 0.004
const F_FROM: float = 0.442
const F_TO: float = 0.600
const ARC_FRAC: float = 0.434
const AZIMUTH_MAX_DEG: float = 50.0
const SEE_FRACTION: float = 0.6
const LEAD_S: float = 8.0
const STEP_S: float = 0.25

var _track: Track
var _hz: HaboobHazard
var _pts: PackedVector3Array = PackedVector3Array()
var _fr: PackedFloat32Array = PackedFloat32Array()
var _road_half: float = 7.0
var _fails: int = 0
var _sabotage: bool = false


func _ready() -> void:
	_sabotage = "--sabotaj" in OS.get_cmdline_user_args()
	var idx := GameState.resolve_track_index(19)
	_track = (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	add_child(_track)
	for _i in 3:
		await get_tree().physics_frame
	var found := _track.find_children("*", "HaboobHazard", true, false)
	if found.is_empty():
		print("PICAT: Track19 n-are HaboobHazard (n-am masurat nimic)")
		get_tree().quit(2)
		return
	_hz = found[0] as HaboobHazard
	print("=== HABOOB PE TRACK19%s ===" % (" (SABOTAJ)" if _sabotage else ""))
	if _sabotage:
		var path := _hz.get_node("Path") as Path3D
		path.rotate_y(PI * 0.5)
		print("  sabotaj: Path rotit cu 90 grade")

	var r := _track.route_at(0)
	for i in r.count():
		_pts.append(_track.point_at(i, 0))
		_fr.append(_track.frac_at(i, 0))
	_road_half = float(_track.get("custom_half_width"))
	print("  drum: %d puncte, semilatime %.1f m" % [_pts.size(), _road_half])
	print("  zid: adancime %.0f m, semilatime %.0f m, viteza %.1f m/s, ciclu %.0f s"
		% [_hz.length, _hz.half_width, _hz.wall_speed, _hz.period])
	if _pts.is_empty():
		print("PICAT: drum gol (n-am masurat nimic)")
		get_tree().quit(2)
		return

	_check_quiet_start()
	var t_touch := _check_touch()
	_check_telegraph(t_touch)
	_check_zones()
	if _sabotage:
		print("=== SABOTAJ: %s ===" % ("PRINS (%d verdicte picate)" % _fails if _fails > 0 else "NEPRINS"))
		get_tree().quit(1 if _fails > 0 else 3)
	else:
		print("=== %s ===" % ("PICAT: %d verdicte" % _fails if _fails > 0 else "TOATE OK"))
		get_tree().quit(1 if _fails > 0 else 0)


func _verdict(ok: bool, text: String) -> void:
	print("  [%s] %s" % ["OK" if ok else "PICAT", text])
	if not ok:
		_fails += 1


## Fixeaza ceasul la t si aseaza zidul.
func _at(t: float) -> void:
	_hz.force_clock = t
	_hz.set_cycle_time(t)


## Punctul de drum e in amprenta zidului, latita cu `margin`? (doar xz)
func _in_footprint(p: Vector3, margin: float) -> bool:
	var w := _hz.wall()
	var q := Vector3(p.x, w.global_position.y, p.z)
	var local := w.global_transform.affine_inverse() * q
	return absf(local.x) <= _hz.half_width + margin \
		and absf(local.z) <= _hz.length * 0.5 + margin


## Indicii punctelor de drum atinse acum de zid (acoperire > 0.05).
func _touched_now() -> PackedInt32Array:
	var out := PackedInt32Array()
	if _hz.cover() <= 0.05:
		return out
	for i in _pts.size():
		if _in_footprint(_pts[i], _road_half):
			out.append(i)
	return out


func _check_quiet_start() -> void:
	print("--- (4) liniste la start")
	# Ceasul liber, asa cum il vede cursa: prima aplicare de fizica de la start.
	_hz.force_clock = -1.0
	_hz._started = false
	_hz._physics_process(1.0 / 60.0)
	var t0 := _hz.cycle_time()
	var touched := _touched_now()
	print("    start_clock %.1f, ciclu %.2f, acoperire %.2f, vizibil %s, atinse %d"
		% [_hz.start_clock, t0, _hz.cover(), str(_hz.wall().visible), touched.size()])
	_verdict(_hz.cover() == 0.0 and not _hz.wall().visible and touched.is_empty(),
		"la t=0 al cursei zidul e in liniste: nimic atins, nimic vizibil")
	var ok := true
	for k in 5:
		_at(fposmod(t0 + float(k), _hz.period))
		if _hz.cover() > 0.0:
			ok = false
	_verdict(ok, "si ramane in liniste cel putin 5 s")


## Parcurge ciclul; intoarce prima clipa (s) in care zidul atinge G.
func _check_touch() -> float:
	print("--- (1) fractiile atinse de zid pe tot ciclul")
	var lo := INF
	var hi := -INF
	var first_g := INF
	var first_any := INF
	var any_touch := false
	var outside: Array[String] = []
	var t := 0.0
	while t < _hz.period:
		_at(t)
		var touched := _touched_now()
		if not touched.is_empty():
			any_touch = true
			first_any = minf(first_any, t)
			for i in touched:
				lo = minf(lo, _fr[i])
				hi = maxf(hi, _fr[i])
				if _fr[i] >= G_FROM - FRAC_EPS and _fr[i] <= G_TO + FRAC_EPS:
					first_g = minf(first_g, t)
				else:
					var tag := "%.3f" % _fr[i]
					if not outside.has(tag) and outside.size() < 8:
						outside.append(tag)
		t += STEP_S
	if any_touch:
		print("    atinse: de la %.3f la %.3f; prima atingere oarecare la t=%.2f s, prima in G la %.2f s"
			% [lo, hi, first_any, first_g])
	else:
		print("    zidul nu atinge NICIUN punct de drum")
	_verdict(any_touch, "zidul chiar atinge drumul (altfel n-are rost)")
	_verdict(any_touch and lo >= G_FROM - FRAC_EPS and hi <= G_TO + FRAC_EPS,
		"atinge doar G [%.3f, %.3f] (atins [%.3f, %.3f]; in afara: %s)"
		% [G_FROM, G_TO, lo, hi, str(outside)])
	return first_g


func _check_telegraph(t_touch: float) -> void:
	print("--- (2) telegraful vazut de pe F")
	if t_touch == INF:
		_verdict(false, "nu exista o atingere a lui G, deci nu exista telegraf")
		return
	var fpts: Array[int] = []
	var last := Vector3.INF
	for i in _pts.size():
		if _fr[i] >= F_FROM and _fr[i] <= F_TO:
			if last == Vector3.INF or last.distance_to(_pts[i]) >= 5.0:
				fpts.append(i)
				last = _pts[i]
	print("    %d puncte pe F (pas >= 5 m)" % fpts.size())
	_verdict(fpts.size() >= 20, "F are destule puncte masurate (%d)" % fpts.size())
	var worst := 1.0
	var worst_t := 0.0
	var t := maxf(t_touch - LEAD_S, 0.0)
	var cover_ok := true
	while t <= t_touch + 0.001:
		_at(t)
		var front := _front_center()
		var seen := 0
		for i in fpts:
			var p := _pts[i]
			var heading := _pts[(i + 3) % _pts.size()] - p
			heading.y = 0.0
			var to_w := front - p
			to_w.y = 0.0
			if heading.length() < 0.01 or to_w.length() < 0.01:
				continue
			var ang := rad_to_deg(heading.normalized().angle_to(to_w.normalized()))
			if ang <= AZIMUTH_MAX_DEG:
				seen += 1
		var frac_seen := float(seen) / float(maxi(fpts.size(), 1))
		if frac_seen < worst:
			worst = frac_seen
			worst_t = t
		if _hz.cover() <= 0.5:
			cover_ok = false
		t += 1.0
	print("    fereastra %.1f..%.1f s: cel mai prost cadru %.0f%% din puncte vad frontul sub %.0f grade (t=%.1f)"
		% [maxf(t_touch - LEAD_S, 0.0), t_touch, worst * 100.0, AZIMUTH_MAX_DEG, worst_t])
	_verdict(t_touch >= LEAD_S, "zidul atinge G abia la %.1f s (>= %.0f s)" % [t_touch, LEAD_S])
	_verdict(worst >= SEE_FRACTION,
		">= %.0f%% din punctele F vad frontul sub %.0f grade in toata fereastra (minim %.0f%%)"
		% [SEE_FRACTION * 100.0, AZIMUTH_MAX_DEG, worst * 100.0])
	_verdict(cover_ok, "zidul e vizibil (acoperire > 0.5) in toata fereastra de %.0f s" % LEAD_S)


## Centrul frontului zidului, in lume.
func _front_center() -> Vector3:
	var w := _hz.wall()
	return w.global_position + (-w.global_transform.basis.z) * (_hz.length * 0.5)


func _check_zones() -> void:
	print("--- (3) arcul si CameraZone")
	var zones := _track.find_children("*", "CameraZone", true, false)
	print("    CameraZone pe pista: %d" % zones.size())
	var arc_idx := 0
	var best := INF
	for i in _pts.size():
		var d := absf(_fr[i] - ARC_FRAC)
		if d < best:
			best = d
			arc_idx = i
	var arc_touched := false
	var zone_touched := 0
	var t := 0.0
	while t < _hz.period:
		_at(t)
		if _hz.cover() > 0.05:
			if _in_footprint(_pts[arc_idx], _road_half + 20.0):
				arc_touched = true
			for z in zones:
				if _in_footprint((z as Node3D).global_position, 10.0):
					zone_touched += 1
		t += STEP_S
	_verdict(not arc_touched, "zidul nu ajunge la arc (fractia %.3f, cu 20 m rezerva)" % ARC_FRAC)
	_verdict(zone_touched == 0, "zidul nu se suprapune cu nicio CameraZone (%d zone)" % zones.size())
