extends Node
## Garda clopotului de avertizare al saniei (Carrara, POI G; brief carrara.md
## §2 randul G, §3 sania, §5.5 Sunet: „clopot de avertizare 2 s inainte").
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSledBell.tscn
##
## Construieste un `RockfallHazard` CU TRASEU (jgheab sintetic, nod-parinte rotit
## si mutat, ca pozitia globala sa nu coincida cu cea locala) si masoara, pe 3+
## cicluri, doua lucruri INDEPENDENTE unul de altul:
##   - PLECAREA: cadrul in care corpul saniei (`_rock`, nodul citit dupa tick,
##     nu functiile hazardului) incepe sa se miste in plan dupa o pauza in care
##     a stat pe loc;
##   - CLOPOTUL: intrarile `crossing_bell` din jurnalul `AudioManager.sfx_log`,
##     adica sunetul care chiar a trecut prin canalul pozitional `play_sfx_at`.
## Contractul:
##   (1) un clopot pe ciclu, la `plecare - warn_bell_s` +-1 cadru;
##   (2) clopotul suna din capatul de SUS al traseului (primul punct al curbei,
##       adus in lume de sonda, +-0,05 m), iar sania chiar pleaca de acolo;
##   (3) `warn_bell_s = 0` nu suna niciodata;
##   (4) pornit IN fereastra (plecarea la < warn_bell_s de la start), prima
##       plecare n-are clopot (momentul lui a fost inainte sa existe hazardul) si
##       nu apare niciun clopot decalat; ciclurile urmatoare au;
##   (5) `warn_bell_s` mai mare decat pauza: clopotul suna tot la plecare -
##       warn, adica in timp ce sania precedenta inca e pe jgheab;
##   (6) transportul: `HazardMarker.model_spec()` trimite `rock_warn_bell_s` doar
##       cand e > 0.
## Cod de iesire: 0 = toate OK, 1 = verdict picat, 2 = n-am masurat nimic.

const Common := preload("res://tools/probe_carrara_common.gd")
const FPS: float = 60.0
## Sub atat (m) intre doua cadre, sania „sta". Pe pauza pozitia e scrisa identic
## in fiecare cadru, deci diferenta e 0 exact; primul cadru de mers face
## 0,5 * ROUTE_ACCEL * dt^2 = 0,56 mm, de 50 de ori peste prag.
const STILL_EPS: float = 1.0e-5
## Cate cadre de nemiscare inainte, ca sa fie PLECARE (nu saltul de la capatul
## traseului inapoi sus, care vine dupa cadre de mers).
const STILL_FRAMES: int = 30
const POS_TOL: float = 0.05

var _fails: int = 0
var _measured: int = 0
## Cazurile duse pana la capat: o eroare de script la mijloc abandoneaza
## corutina fara sa pice nimic, iar garda ar iesi verde pe zero masuratori.
var _cases_done: int = 0
const CASES: int = 5
var _hz: RockfallHazard = null
var _rec: Array[Dictionary] = []


func _ready() -> void:
	# Dupa hazard in acelasi tick: citim ce a scris el in cadrul asta.
	process_physics_priority = 1000
	await get_tree().process_frame
	print("")
	print("=== Clopotul saniei (RockfallHazard.warn_bell_s) ===")
	# Carrara: ciclul de 41 s fortat ca in probe_carrara_sled, viteza 6,5 m/s.
	await _case("Carrara: ciclu 41 s, warn 2 s", 2.0, 0.0, 0.5, 41.0, 145.0, 3)
	await _case("pauza 6 s, warn 2 s", 2.0, 6.0, 0.7, 0.0, 60.0, 4)
	await _case("warn 2,5 s > pauza 1 s", 2.5, 1.0, 0.95, 0.0, 45.0, 4)
	await _case("start in fereastra (plecarea la 1 s)", 2.0, 6.0, -1.0, 0.0, 50.0, 3)
	await _case("warn 0: fara clopot", 0.0, 6.0, 0.7, 0.0, 60.0, 4)
	_check_marker()
	print("")
	if _measured == 0 or _cases_done != CASES:
		print("=== NIMIC MASURAT: %d/%d cazuri terminate, %d masuratori ===" % [
			_cases_done, CASES, _measured])
		get_tree().quit(2)
		return
	print("=== %s (%d masuratori) ===" % [
		"PICAT: %d verdicte" % _fails if _fails > 0 else "TOATE OK", _measured])
	get_tree().quit(1 if _fails > 0 else 0)


func _verdict(ok: bool, text: String) -> void:
	print("  [%s] %s" % ["OK" if ok else "PICAT", text])
	if not ok:
		_fails += 1


func _physics_process(_delta: float) -> void:
	if _hz == null or not is_instance_valid(_hz):
		return
	var g := _hz._rock.global_position
	_rec.append({"frame": Engine.get_physics_frames(), "xz": Vector2(g.x, g.z),
		"pos": g})


## Jgheabul, in coordonatele PARINTELUI hazardului: de sus (dreapta, 9 m) peste
## drum, pana pe platforma din stanga.
func _route() -> Curve3D:
	var c := Curve3D.new()
	for p in [Vector3(14, 9, -26), Vector3(8, 5, -14), Vector3(3, 1, -4),
			Vector3(0, 0, 2), Vector3(-4, 0, 10), Vector3(-8, 0, 16)]:
		c.add_point(p)
	return c


## `phase < 0` = porneste cu plecarea la `-phase` secunde de la start.
func _case(label: String, warn: float, pause: float, phase: float,
		force_period: float, run_s: float, min_deps: int) -> void:
	print("")
	print("--- %s" % label)
	AudioManager.sfx_log.clear()
	var root := Node3D.new()
	root.name = "World"
	root.transform = Transform3D(Basis(Vector3.UP, 0.6), Vector3(40.0, 3.0, -25.0))
	add_child(root)
	Common.make_ground(root)
	var curve := _route()
	var hz := RockfallHazard.new()
	hz.name = "Sanie"
	hz.route = curve
	hz.route_speed = 6.5
	hz.route_pause = pause
	hz.roll_model = false
	hz.warn_bell_s = warn
	hz.phase = maxf(phase, 0.0)
	hz.position = Vector3(1.0, 0.0, 0.0)
	root.add_child(hz)
	if force_period > 0.0:
		hz.period = force_period
	if phase < 0.0:
		# Plecarea (ceasul ajunge la `period`) la `-phase` secunde dupa start.
		hz.phase = 1.0 - (-phase) / hz.period
	var root_xf := root.global_transform
	var top := root_xf * curve.get_point_position(0)
	var start_frame := Engine.get_physics_frames()
	_rec.clear()
	_hz = hz
	var frames := int(run_s * FPS)
	for _i in frames:
		await get_tree().physics_frame
	_hz = null
	var end_frame := Engine.get_physics_frames()
	var bells: Array[Dictionary] = []
	for e in AudioManager.sfx_log:
		if StringName(e["name"]) == &"crossing_bell":
			bells.append(e)
	var period := hz.period
	var travel := hz._route_travel
	var rang := hz.warn_bells
	root.queue_free()
	await get_tree().physics_frame
	# --- plecarile, din miscarea corpului
	var deps: Array[int] = []
	var dep_pos: Array[Vector3] = []
	var dep_idx: Array[int] = []
	var still := 0
	for i in range(1, _rec.size()):
		var step := ((_rec[i]["xz"] as Vector2) - (_rec[i - 1]["xz"] as Vector2)).length()
		if step > STILL_EPS:
			if still >= STILL_FRAMES:
				deps.append(int(_rec[i]["frame"]))
				dep_pos.append(_rec[i]["pos"])
				dep_idx.append(i)
			still = 0
		else:
			still += 1
	print("    ciclu %.2f s, trecere %.2f s, pauza efectiva %.2f s; %d cadre, %d plecari, %d clopote (contorul hazardului: %d)"
		% [period, travel, period - travel, _rec.size(), deps.size(), bells.size(), rang])
	_measured += _rec.size()
	_verdict(deps.size() >= min_deps, "plecari masurate: %d (>= %d)" % [deps.size(), min_deps])
	for k in deps.size():
		var d_top := Vector2(dep_pos[k].x - top.x, dep_pos[k].z - top.z).length()
		_verdict(d_top <= POS_TOL, "plecarea %d (cadrul %d) porneste de sus: %.3f m de primul punct"
			% [k + 1, deps[k] - start_frame, d_top])
	if warn <= 0.0:
		_verdict(bells.is_empty() and rang == 0, "niciun clopot (%d in jurnal, contor %d)"
			% [bells.size(), rang])
		_cases_done += 1
		return
	var lead := int(round(warn * FPS))
	# Momentul plecarii, sub-cadru, intors in timp de pe traiectoria MASURATA:
	# primul cadru in care sania a parcurs >= 3 m (inca in faza de acceleratie,
	# care tine 1,6 s, si pe primul segment al jgheabului, care e drept) da
	# timpul scurs din d = a t^2 / 2. Primul cadru „miscat" singur nu ajunge:
	# daca restul ramas din pasul de ceas e minuscul, piatra face 1e-8 m, sub
	# precizia unui float la 60 m de origine, si plecarea pare un cadru mai
	# tarziu. Sub 3 m, esantionarea cubica a curbei coace (puncte la 0,25 m)
	# strica estimarea cu pana la 0,1 cadre (masurat: 5 cm -> +1,1, 0,5 m ->
	# +0,06, 3 m -> 0,00 pe cazul cu ceas exact).
	#
	# Ce se compara: corpul (`AnimatableBody3D` cu `sync_to_physics`) arata
	# pozitia scrisa abia in tick-ul URMATOR, deci momentul vazut e plecarea
	# ceasului + 1 cadru; clopotul suna in primul cadru DUPA momentul lui
	# (pasul [prev, prev + dt)). Cele doua se compenseaza, iar abaterea iese in
	# (-1, 0] cadre prin constructie. Un clopot decalat sau dublat iese din ea.
	var p0 := top
	var p1 := root_xf * curve.get_point_position(1)
	var seg := p1 - p0
	var ratio := seg.length() / Vector2(seg.x, seg.z).length()
	var dep_x: Array[float] = []
	for k in deps.size():
		var x := NAN
		for j in range(dep_idx[k], mini(dep_idx[k] + 120, _rec.size())):
			var xz: Vector2 = _rec[j]["xz"]
			var d := (xz - Vector2(top.x, top.z)).length() * ratio
			if d >= 3.0:
				x = float(_rec[j]["frame"]) - sqrt(2.0 * d / RockfallHazard.ROUTE_ACCEL) * FPS
				break
		dep_x.append(x)
		_verdict(not is_nan(x) and x > float(deps[k]) - 2.0 and x <= float(deps[k]) + 0.01,
			"plecarea %d: momentul intors din traiectorie %.2f, primul cadru miscat %d"
			% [k + 1, x - start_frame, deps[k] - start_frame])
	var used: Array[bool] = []
	used.resize(bells.size())
	used.fill(false)
	var prev := start_frame
	for k in deps.size():
		var want := deps[k] - lead
		var mine: Array[int] = []
		for b in bells.size():
			var bf := int(bells[b]["frame"])
			if bf > prev and bf <= deps[k]:
				mine.append(b)
				used[b] = true
		if want <= start_frame:
			_verdict(mine.is_empty(),
				"plecarea %d la %.2f s de start (< warn): fara clopot (%d)"
				% [k + 1, (deps[k] - start_frame) / FPS, mine.size()])
		else:
			_verdict(mine.size() == 1, "plecarea %d: un clopot inainte (%d)"
				% [k + 1, mine.size()])
			for b in mine:
				var off := float(bells[b]["frame"]) - (dep_x[k] - warn * FPS)
				_verdict(absf(off) <= 1.0,
					"  clopot la plecare - %.2f s, abatere %+.2f cadre (cadrul %d, plecare %.2f)"
					% [warn, off, int(bells[b]["frame"]) - start_frame, dep_x[k] - start_frame])
				var bp: Vector3 = bells[b]["pos"]
				_verdict(bool(bells[b]["positional"]) and bp.distance_to(top) <= POS_TOL,
					"  pozitional, din capatul de sus: %.3f m de primul punct al traseului"
					% bp.distance_to(top))
		prev = deps[k]
	# Clopotele de dupa ultima plecare masurata: doar al plecarii care urmeaza
	# dupa sfarsitul rularii.
	for b in bells.size():
		if used[b]:
			continue
		var bf := int(bells[b]["frame"])
		_verdict(bf > prev and bf + lead >= end_frame - 1,
			"clopot fara plecare la cadrul %d: e al plecarii de dupa rulare" % (bf - start_frame))
	_cases_done += 1


func _check_marker() -> void:
	print("")
	print("--- transportul HazardMarker.model_spec()")
	var m := HazardMarker.new()
	m.kind = HazardMarker.Kind.ROCKFALL
	var off := m.model_spec()
	m.rock_warn_bell_s = 2.0
	var on := m.model_spec()
	m.free()
	_measured += 1
	_verdict(not off.has("rock_warn_bell_s"), "la 0 cheia lipseste din spec")
	_verdict(is_equal_approx(float(on.get("rock_warn_bell_s", 0.0)), 2.0),
		"la 2.0 spec[rock_warn_bell_s] = %s" % str(on.get("rock_warn_bell_s")))
