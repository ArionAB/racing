extends Node
## Sonda gongului de templu (`GongHazard`, Angkor, nava templului): masini ADEVARATE
## (`Car` cu presetarile din scenes/cars/data/) pe o podea plata, gongul pus de sonda.
## Toate scenariile unei runde ruleaza deodata, fiecare pe culoarul lui (60 m intre ele);
## runda se repeta (`--reps=N`, implicit 3), fiindca Jolt e multithread si o singura rulare
## nu spune nimic despre imprastiere. Contractele trec doar daca trec in TOATE rundele.
##
## Contractele:
##  a. REPAUS: neatins, gongul ramane sub 1° timp de 3 s si discul nu se muta (< 2 cm).
##  b. MASA DECIDE: lovitura centrata la 25 m/s (tuk-tuk-ul la plafonul lui, 18 m/s: nu
##     poate merge mai repede). Viteza pastrata la 1 s dupa contact: Autobuz > Buggy >
##     Tuk-tuk, strict, in fiecare runda; Autobuzul >= 80%; Tuk-tuk-ul pastreaza cu cel
##     putin `MASS_GAP` mai putin decat Autobuzul; toate merg inainte (> 5 m/s) la 1,5 s;
##     niciuna peste 1,5 m; nicio ejectare, repunere sau tranzitie de repunere.
##  c. SE LEAGANA SI SE LINISTESTE: dupa lovitura Buggy-ului amplitudinea trece de 25° in
##     1 s, nu depaseste limita balamalei (+0,5°), discul ramane prins (distanta de la pivot
##     constanta la 5 cm) si amplitudinea (din energie) e sub 5° la 15 s dupa lovitura.
##  d. FARA PRASTIE: a doua masina vine dupa prima, pe gongul in miscare: 4 perechi x 4
##     intarzieri (`PAIR_DELAYS`, 1,2 s e cerinta). Nicio masina nu ajunge peste 1,15x viteza
##     ei de REFERINTA (aceeasi masina, acelasi start, fara gong — cu gaz tinut, Buggy-ul
##     accelereaza oricum de la 25 spre 35 m/s), masurat pana la prima tamponare intre
##     masini (castigul de dupa ea nu e al gongului); niciuna peste 1,5 m; niciuna blocata
##     (< 2 m/s mai mult de 1 s); nicio transformare NaN. Aspiratia e oprita la perechi.
##  e. BANDA: centrul discului nu se misca lateral mai mult de 0,15 m in niciun scenariu,
##     iar o masina trecuta la 1,0 m de buza (latimea din presetare) nu atinge discul.
##  f. SUNET: un singur sunet per lovitura (`GongHazard.rings` si intrarile `gong_hit` din
##     `AudioManager.sfx_log`, care trebuie sa fie egale), niciunul in repaus sau la trecerea
##     pe langa.
##
## Sabotaje (fiecare trebuie sa pice EXACT contractul lui; codul de iesire 1):
##   --sabotaj=repaus   gongul din (a) are leagan propriu de 4°
##   --sabotaj=masa     gongurile din (b) au 400 kg
##   --sabotaj=leagan   gongul din (c) fara amortizare, frana si opritor
##   --sabotaj=prastie  gongurile din (d) cu amortizarea si frana pe semnul GRESIT (-0,3 /
##                      -0,16): gongul baga energie in loc sa scoata, clasa de regresie care
##                      face prastia. Doua incercari „fizice” n-au produs-o deloc (420 kg fara
##                      frana cu leagan propriu de 30°, si acelasi cu restitutie 1): nicio
##                      masina peste 1,00x referinta, doar blocaje la limita de 1 s — deci un
##                      sabotaj care pica la limita, nu unul de incredere.
##   --sabotaj=banda    discul din (e) are colizorul cu 1,2 m mai lat decat desenul
##   --sabotaj=sunet    gongurile din (f) fara pauza si cu pragul de lovitura la 0,01 rad/s
##
## [b]Masurat[/b] (19 nov 2026, gongul implicit: 70 kg, raza 1,3, pivot 7,5 m, buza la 0,45 m;
## 3 procese x 3 runde, imprastierea sub 0,2 puncte — Jolt a dat practic aceleasi cifre):
##   masina   intrare  pastrat la 1 s (fata de referinta fara gong)  v la 1,5 s  gong max  y max
##   Autobuz  25,4     95%  (86%)                                     25,8        62°       0,08
##   Buggy    25,6     74%  (65%)                                     22,4        59°       0,40
##   Tuk-tuk  17,7     34%  (36%)                                     8,0         36°       0,27
## Buggy-ul: 59° in prima secunda, 1,7° (amplitudine) la 15 s, disc prins la 3,5 cm. Perechile:
## la 0,6 si 1,2 s gongul e SUS si a doua masina trece pe dedesubt fara sa-l atinga; la 2,0 si
## 2,8 s il loveste in coborare (autobuzul in gongul care se intoarce: 65,6°, cel mai mare unghi
## din toata sonda). Nicio masina peste 1,00x referinta; cea mai sus a ajuns la 0,40 m (buggy-ul, pe buza discului).
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeGong.tscn [-- --reps=3] [-- --sabotaj=...]
## Iesire: o linie per contract, tabelul masurat si `PROBE GONG: OK` / `PROBE GONG: PICAT`.

const STEP: float = 1.0 / 60.0
const SPEED: float = 25.0
const LANE_GAP: float = 60.0
## Startul masinii (asezarea pe suspensie), in spatele gongului (+Z; mersul e spre -Z).
const START_Z: float = 14.0
## La lansare, botul masinii e la atat in spatele discului (m): intrarea ramane ~25 m/s.
const LAUNCH_GAP: float = 3.0
const SETTLE_S: float = 0.5
## Intarzierea celei de-a doua masini fata de contactul primei (s). 1,2 s e cerinta; la ea
## gongul e sus, aproape de capatul cursei, si a doua masina trece pe dedesubt. 2,0 si 2,8 s
## o pun pe gongul care COBOARA inapoi spre ea — intalnirea pe care o cauta contractul.
const PAIR_DELAYS: Array[float] = [0.6, 1.2, 2.0, 2.8]
## Perechile merg decalat lateral (+-PAIR_X), ca sa nu se loveasca intre ele: castigul de
## viteza dintr-o tamponare nu e al gongului. Discul (coarda ~1,0-1,2 m la inaltimea
## caroseriei) le prinde pe amandoua, excentric.
const PAIR_X: float = 0.95
## Pragul de la (b): cu cat pastreaza tuk-tuk-ul mai putin decat autobuzul (fractie din viteza
## de intrare). De unde 0,35: pendulul lovit jos (~0,85 m peste asfalt, 6,65 m sub pivot) are
## masa efectiva m * (L^2 + R^2/4) / r^2 ~ 0,76 m = ~53 kg la 70 kg; ciocnirea plastica lasa
## autobuzului (260 kg) 83% si tuk-tuk-ului (34 kg) 39% — 44 de puncte, fara gazul de dupa.
## Masurat cu gaz, la 1 s: ~95% si ~34%, adica ~60 de puncte. 35 de puncte inseamna ca
## tuk-tuk-ul pierde cel putin o TREIME din viteza mai mult decat autobuzul: diferenta se
## simte, nu se banuieste, si lasa loc de reglaj (masa, frana) fara sa pice garda.
const MASS_GAP: float = 0.35
const CARS_B: Array[String] = ["bus", "buggy", "tuktuk"]
const PAIRS: Array = [["buggy", "buggy"], ["bus", "tuktuk"], ["tuktuk", "bus"], ["buggy", "bus"]]
const LANE_CARS: Array[String] = ["bus", "buggy"]
## Leaganul propriu verificat la (a): amplitudinea tinuta in ultimele 4 s din 14.
const IDLE_DEG: float = 8.0


class ScriptDriver:
	extends CarController
	var throttle: float = 0.0
	func get_steer() -> float:
		return 0.0
	func get_throttle() -> float:
		return throttle
	func is_drift_pressed() -> bool:
		return false
	func is_turbo_pressed() -> bool:
		return false


## O masina urmarita: viteza pe cadre de la lansare, inaltimea, evenimentele.
class Tracked:
	var car: Car
	var drv: ScriptDriver
	var kind: String
	var launched_frame: int = -1
	var speeds: PackedFloat32Array = PackedFloat32Array()
	var entry: float = -1.0
	## Viteza de lansare (copiata: masina se elibereaza inaintea raportului).
	var launch_speed: float = 0.0
	## Unde s-a atins raportul maxim fata de referinta: secunde de la lansare si ce atingea.
	var worst_at: float = -1.0
	var worst_ratio: float = 0.0
	var worst_what: String = ""
	var contact_frame: int = -1 # cadre de la lansare
	var touched: bool = false
	var max_y: float = -INF
	var ejects: int = 0
	var respawns: int = 0
	var recovers: int = 0
	var stuck_t: float = 0.0
	var max_stuck: float = 0.0
	var nan: bool = false
	var touch_episodes: int = 0
	var tags: PackedStringArray = PackedStringArray()
	## Primul cadru (de la lansare) cu o tamponare intre masini; -1 = niciuna.
	var car_contact_frame: int = -1
	var _touching: bool = false
	var _gap: float = 99.0


## Un scenariu: un culoar, poate un gong, una sau doua masini.
class Run:
	var name: String
	var kind: String
	var origin: Vector3
	var gong: GongHazard
	var cars: Array = []
	var t: float = 0.0
	var duration: float = 3.0
	var done: bool = false
	var max_angle: float = 0.0
	var max_lat: float = 0.0
	var max_disp: float = 0.0
	var max_arm_err: float = 0.0
	var rest_pos: Vector3 = Vector3.ZERO
	var angle_trace: PackedFloat32Array = PackedFloat32Array()
	var amp_trace: PackedFloat32Array = PackedFloat32Array()
	var hit_frame: int = -1 # cadre de la inceputul scenariului
	var delay: float = 0.0
	## Gongul acestui scenariu e sabotat (pentru contractul sabotajului, nu pentru celelalte).
	var sabotaged: bool = false
	var frames: int = 0
	var sfx_rings: int = 0
	## Copiate din gong la sfarsitul rundei (gongul se elibereaza inaintea raportului).
	var rings: int = 0
	var limit_deg: float = 0.0


var _sab: String = ""
var _reps: int = 3
var _round: int = 0
var _runs: Array = []
var _lane_i: int = 0
var _results: Array = [] # o lista de runde, fiecare = lista de Run
var _failed: bool = false


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--sabotaj="):
			_sab = a.trim_prefix("--sabotaj=")
		elif a.begins_with("--reps="):
			_reps = maxi(1, int(a.trim_prefix("--reps=")))
	if _sab != "":
		print("SABOTAJ: ", _sab)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4000, 1, 4000)
	shape.shape = box
	body.add_child(shape)
	add_child(body)
	body.global_position = Vector3(0, -0.5, 0)
	_start_round()


# ------------------------------------------------------------------ constructia rundei

func _start_round() -> void:
	_runs = []
	_lane_i = 0
	var am := get_node_or_null(^"/root/AudioManager")
	if am != null:
		(am.get("sfx_log") as Array).clear()
	var rest := _new_run("repaus", "rest", 3.0)
	_add_gong(rest, {"idle_swing_deg": 4.0} if _sab == "repaus" else {})
	var idle := _new_run("leagan_propriu", "idle", 14.0)
	_add_gong(idle, {"idle_swing_deg": IDLE_DEG})
	for c in CARS_B:
		var base := _new_run("referinta_" + c, "base", 6.0)
		_add_car(base, c, 0.0)
	for c in CARS_B:
		var hit := _new_run("lovitura_" + c, "hit", 4.0)
		var opts := {}
		if _sab == "masa":
			opts["mass"] = 400.0
		if _sab == "sunet":
			opts.merge(_sab_sound())
		_add_gong(hit, opts)
		_add_car(hit, c, 0.0)
	var swing := _new_run("leagan_buggy", "swing", 17.0)
	var sopts := {}
	if _sab == "leagan":
		sopts = {"damping": 0.0, "drag": 0.0, "soft_stop": 0.0}
	if _sab == "sunet":
		sopts.merge(_sab_sound())
	_add_gong(swing, sopts)
	_add_car(swing, "buggy", 0.0)
	for p: Array in PAIRS:
		for dl: float in PAIR_DELAYS:
			var pr := _new_run(_pair_name(p, dl), "pair", 6.0 + dl)
			pr.delay = dl
			var popts := {}
			if _sab == "prastie":
				popts = {"damping": -0.3, "drag": -0.16, "soft_stop": 0.0}
			if _sab == "sunet":
				popts.merge(_sab_sound())
			_add_gong(pr, popts)
			var a := _add_car(pr, String(p[0]), -PAIR_X)
			var b := _add_car(pr, String(p[1]), PAIR_X, 300.0)
			a.car.slip_max_gap = 0.0
			b.car.slip_max_gap = 0.0
	for c in LANE_CARS:
		var ln := _new_run("banda_" + c, "lane", 3.0)
		_add_gong(ln, {})
		if _sab == "banda":
			var cs := ln.gong.disc().get_child(0) as CollisionShape3D
			(cs.shape as CylinderShape3D).radius += 1.2
			ln.sabotaged = true
		var probe_car := _add_car(ln, c, 0.0)
		var x := ln.gong.radius + 1.0 + probe_car.car.collider_half_width()
		probe_car.car.global_position.x = ln.origin.x + x
	print("[gong] runda %d/%d: %d scenarii" % [_round + 1, _reps, _runs.size()])


func _pair_name(p: Array, dl: float) -> String:
	return "pereche_%s_%s_%.1fs" % [p[0], p[1], dl]


func _sab_sound() -> Dictionary:
	return {"ring_cooldown": 0.0, "ring_min_dw": 0.01}


func _new_run(nm: String, kind: String, duration: float) -> Run:
	var r := Run.new()
	r.name = nm
	r.kind = kind
	r.duration = duration
	r.origin = Vector3(float(_lane_i) * LANE_GAP, 0.0, 0.0)
	_lane_i += 1
	_runs.append(r)
	return r


## `opts` pune exporturi pe gong; cheia "bounce" (sabotaj) pune restitutia discului.
func _add_gong(r: Run, opts: Dictionary) -> void:
	var g := GongHazard.new()
	for k: String in opts:
		if k != "bounce":
			g.set(k, opts[k])
	g.position = r.origin
	add_child(g)
	if opts.has("bounce"):
		g.disc().physics_material_override.bounce = float(opts["bounce"])
	r.gong = g
	r.rest_pos = g.disc().global_position
	r.sabotaged = _sab != "" and not opts.is_empty() and r.kind != "idle"


func _add_car(r: Run, kind: String, x: float, z_extra: float = 0.0) -> Tracked:
	var tr := Tracked.new()
	tr.kind = kind
	var car := Car.new()
	add_child(car)
	car.apply_data(load("res://scenes/cars/data/%s.tres" % kind) as CarData)
	car.global_position = r.origin + Vector3(x, 0.7, START_Z + z_extra)
	var drv := ScriptDriver.new()
	car.set_controller(drv)
	car.race_active = true
	tr.car = car
	tr.drv = drv
	car.ejected.connect(func(_c: Car, _r: Node3D) -> void: tr.ejects += 1)
	car.respawned.connect(func(_c: Car) -> void: tr.respawns += 1)
	car.recovery_started.connect(func(_c: Car, _s: float) -> void: tr.recovers += 1)
	r.cars.append(tr)
	return tr


## Botul colizorului fata de originea masinii (m).
func _front(car: Car) -> float:
	return car.data.body_length * 0.85 * 0.5


func _disc_half(g: GongHazard) -> float:
	return (g.thickness + g.collision_pad) * 0.5 if g != null else 0.0


## Viteza de intrare: 25 m/s, sau plafonul masinii daca e mai mic (tuk-tuk-ul: 18).
func _entry_speed(car: Car) -> float:
	return minf(SPEED, car.max_speed)


func _launch(tr: Tracked, at: Vector3) -> void:
	var car := tr.car
	car.global_transform = Transform3D(Basis.IDENTITY, at)
	car.linear_velocity = Vector3(0.0, 0.0, -_entry_speed(car))
	car.angular_velocity = Vector3.ZERO
	tr.drv.throttle = 1.0
	tr.launched_frame = 0
	tr.launch_speed = _entry_speed(car)


# ------------------------------------------------------------------ pasul

func _physics_process(_delta: float) -> void:
	var all_done := true
	for r: Run in _runs:
		if not r.done:
			_tick(r)
			all_done = all_done and r.done
	if all_done:
		_end_round()


func _tick(r: Run) -> void:
	r.t += STEP
	r.frames += 1
	if r.gong != null:
		var g := r.gong
		var disc := g.disc()
		var th := absf(rad_to_deg(g.swing_angle()))
		r.angle_trace.append(th)
		r.amp_trace.append(_amp_deg(g))
		r.max_angle = maxf(r.max_angle, th)
		var loc := g.to_local(disc.global_position)
		r.max_lat = maxf(r.max_lat, absf(loc.x))
		r.max_disp = maxf(r.max_disp, disc.global_position.distance_to(r.rest_pos))
		r.max_arm_err = maxf(r.max_arm_err,
			absf(disc.global_position.distance_to(g.pivot_global()) - g.arm_length()))
		if not disc.global_transform.origin.is_finite():
			for tr: Tracked in r.cars:
				tr.nan = true
	# Lansarea: dupa asezarea pe suspensie.
	if r.cars.size() > 0:
		var first: Tracked = r.cars[0]
		if first.launched_frame < 0 and r.t >= SETTLE_S:
			var z0 := _front(first.car) + LAUNCH_GAP + _disc_half(r.gong)
			_launch(first, Vector3(first.car.global_position.x, 0.05, r.origin.z + z0))
	for tr: Tracked in r.cars:
		_tick_car(r, tr)
	# A doua masina a perechii: teleportata la contactul primei, ca botul ei sa ajunga in
	# planul discului (in repaus) dupa `delay` secunde.
	if r.kind == "pair" and r.cars.size() == 2:
		var a: Tracked = r.cars[0]
		var b: Tracked = r.cars[1]
		if a.contact_frame >= 0 and b.launched_frame < 0:
			var z := _entry_speed(b.car) * r.delay + _front(b.car) + _disc_half(r.gong)
			_launch(b, Vector3(b.car.global_position.x, 0.05, r.origin.z + z))
	if r.hit_frame < 0 and r.cars.size() > 0 and (r.cars[0] as Tracked).contact_frame >= 0:
		r.hit_frame = r.frames
	var end := r.duration + SETTLE_S
	if r.kind == "swing" and r.hit_frame >= 0:
		end = maxf(end, float(r.hit_frame) * STEP + 15.6)
	if r.t >= end:
		r.done = true


func _tick_car(r: Run, tr: Tracked) -> void:
	var car := tr.car
	if not car.global_transform.origin.is_finite() or not car.linear_velocity.is_finite():
		tr.nan = true
		return
	if tr.launched_frame < 0:
		return
	tr.launched_frame += 1
	var v := car.horizontal_speed()
	tr.max_y = maxf(tr.max_y, car.global_position.y)
	var touching := false
	if r.gong != null:
		touching = r.gong.disc().get_colliding_bodies().has(car)
	if touching:
		if tr.contact_frame < 0:
			tr.contact_frame = tr.launched_frame
			tr.entry = tr.speeds[tr.speeds.size() - 1] if tr.speeds.size() > 0 else v
		tr.touched = true
		if not tr._touching and tr._gap > 0.25:
			tr.touch_episodes += 1
		tr._gap = 0.0
	else:
		tr._gap += STEP
	tr._touching = touching
	if tr.car_contact_frame < 0:
		for body in car.get_colliding_bodies():
			if body is Car:
				tr.car_contact_frame = tr.launched_frame
				break
	tr.speeds.append(v)
	var what := ""
	if touching:
		what += "disc "
	for body in car.get_colliding_bodies():
		if body is Car:
			what += "masina "
	tr.tags.append(what)
	# Blocat: sub 2 m/s, cu gaz, dupa ce a plecat.
	if v < 2.0 and tr.launched_frame > 10:
		tr.stuck_t += STEP
		tr.max_stuck = maxf(tr.max_stuck, tr.stuck_t)
	else:
		tr.stuck_t = 0.0


## Amplitudinea din energie (grade): unghiul la care s-ar opri pendulul cu energia de acum.
func _amp_deg(g: GongHazard) -> float:
	var gr: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
	var arm := g.arm_length()
	var th := g.swing_angle()
	var v := g.disc().linear_velocity.length()
	var h := (1.0 - cos(th)) + v * v / (2.0 * gr * arm)
	return rad_to_deg(acos(clampf(1.0 - h, -1.0, 1.0)))


func _end_round() -> void:
	var am := get_node_or_null(^"/root/AudioManager")
	var log_arr: Array = am.get("sfx_log") if am != null else []
	for r: Run in _runs:
		if r.gong == null:
			continue
		r.rings = r.gong.rings
		r.limit_deg = r.gong.swing_limit_deg
		for e: Dictionary in log_arr:
			if StringName(e.get("name", &"")) != &"gong_hit":
				continue
			var p: Vector3 = e.get("pos", Vector3.INF)
			if p.is_finite() and absf(p.x - r.origin.x) < LANE_GAP * 0.5:
				r.sfx_rings += 1
	_results.append(_runs)
	# Curatenia: alta runda, alte corpuri.
	for r: Run in _runs:
		if r.gong != null:
			r.gong.queue_free()
		for tr: Tracked in r.cars:
			tr.car.queue_free()
	_round += 1
	if _round < _reps:
		set_physics_process(false)
		await get_tree().physics_frame
		await get_tree().physics_frame
		set_physics_process(true)
		_start_round()
		return
	set_physics_process(false)
	_report()


# ------------------------------------------------------------------ verdictul

func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _find(rs: Array, nm: String) -> Run:
	for r: Run in rs:
		if r.name == nm:
			return r
	return null


## Viteza la `sec` secunde dupa contact / viteza de intrare.
func _kept(tr: Tracked, sec: float) -> float:
	if tr.contact_frame < 0 or tr.entry <= 0.0:
		return -1.0
	var i := mini(tr.contact_frame + int(round(sec / STEP)), tr.speeds.size() - 1)
	return tr.speeds[i] / tr.entry


func _speed_at(tr: Tracked, sec: float) -> float:
	if tr.contact_frame < 0:
		return -1.0
	var i := mini(tr.contact_frame + int(round(sec / STEP)), tr.speeds.size() - 1)
	return tr.speeds[i]


## Cel mai mare raport viteza / referinta (aceeasi masina, fara gong), pe cadre de la lansare,
## pana la prima tamponare intre masini (castigul de dupa ea nu mai e al gongului).
func _max_vs_base(tr: Tracked, base: Tracked) -> float:
	var worst := 0.0
	var n := mini(tr.speeds.size(), base.speeds.size())
	if tr.car_contact_frame >= 0:
		# `speeds[L - 1]` e cadrul in care s-a raportat tamponarea (L = cadre de la lansare);
		# viteza lui are deja impulsul ei, deci se opreste cu un cadru inainte.
		n = mini(n, tr.car_contact_frame - 2)
	var wi := -1
	for i in n:
		var ref := maxf(base.speeds[i], 1.0)
		var ratio := tr.speeds[i] / ref
		if ratio > worst:
			worst = ratio
			wi = i
	tr.worst_ratio = worst
	tr.worst_at = float(wi) * STEP
	tr.worst_what = tr.tags[wi] if wi >= 0 and wi < tr.tags.size() else ""
	return worst


func _spread(vals: Array) -> String:
	if vals.is_empty():
		return "-"
	var lo := INF
	var hi := -INF
	for v: float in vals:
		lo = minf(lo, v)
		hi = maxf(hi, v)
	return "%.2f..%.2f" % [lo, hi] if hi - lo > 0.005 else "%.2f" % lo


func _report() -> void:
	print("")
	print("=== GongHazard: %d runde ===" % _results.size())
	_report_table()
	print("")
	_contract_a()
	_contract_b()
	_contract_c()
	_contract_d()
	_contract_e()
	_contract_f()
	print("")
	print("PROBE GONG: ", "PICAT" if _failed else "OK")
	# Un cadru, ca nodurile ultimei runde (queue_free) sa plece inainte de iesire.
	await get_tree().process_frame
	get_tree().quit(1 if _failed else 0)


func _report_table() -> void:
	print("")
	print("masina   | intrare m/s | pastrat 1 s (fata de referinta) | v la 1,5 s | unghi max gong | y max")
	for c in CARS_B:
		var entry: Array = []
		var kept: Array = []
		var kept_rel: Array = []
		var v15: Array = []
		var ang: Array = []
		var ymax: Array = []
		for rs: Array in _results:
			var r := _find(rs, "lovitura_" + c)
			var base := _find(rs, "referinta_" + c)
			var tr: Tracked = r.cars[0]
			var tb: Tracked = base.cars[0]
			entry.append(tr.entry)
			kept.append(_kept(tr, 1.0) * 100.0)
			var vb := tb.speeds[mini(tr.contact_frame + 60, tb.speeds.size() - 1)] \
				if tr.contact_frame >= 0 else 1.0
			kept_rel.append(_speed_at(tr, 1.0) / maxf(vb, 0.1) * 100.0)
			v15.append(_speed_at(tr, 1.5))
			ang.append(r.max_angle)
			ymax.append(tr.max_y)
		print("%-8s | %-11s | %s%% (%s%%) | %s | %s° | %s" % [c, _spread(entry), _spread(kept),
			_spread(kept_rel), _spread(v15), _spread(ang), _spread(ymax)])
	print("")
	print("perechi (decalate +-%.2f m): masina, intrare m/s, max v/referinta, a atins discul, a tamponat, unghi max gong, y max, blocat max s" % PAIR_X)
	for p: Array in PAIRS:
		for dl: float in PAIR_DELAYS:
			var nm := _pair_name(p, dl)
			for k in 2:
				var entry: Array = []
				var worst: Array = []
				var ymax: Array = []
				var stuck: Array = []
				var ang: Array = []
				var touched := 0
				var bumped := 0
				for rs: Array in _results:
					var r := _find(rs, nm)
					var tr: Tracked = r.cars[k]
					var base := _find(rs, "referinta_" + tr.kind)
					entry.append(tr.entry if tr.entry > 0.0 else tr.launch_speed)
					worst.append(_max_vs_base(tr, base.cars[0]))
					ymax.append(tr.max_y)
					stuck.append(tr.max_stuck)
					ang.append(r.max_angle)
					touched += 1 if tr.touched else 0
					bumped += 1 if tr.car_contact_frame >= 0 else 0
				print("  %-28s #%d %-6s | %s | %s | %d/%d | %d/%d | %s° | %s | %s" % [nm, k + 1,
					p[k], _spread(entry), _spread(worst), touched, _results.size(), bumped,
					_results.size(), _spread(ang), _spread(ymax), _spread(stuck)])


func _contract_a() -> void:
	var ang: Array = []
	var disp: Array = []
	for rs: Array in _results:
		var r := _find(rs, "repaus")
		ang.append(r.max_angle)
		disp.append(r.max_disp * 100.0)
	var ok := true
	for i in ang.size():
		ok = ok and float(ang[i]) < 1.0 and float(disp[i]) < 2.0
	# Leganul propriu (`idle_swing_deg`): porneste singur din repaus si se tine la amplitudinea
	# ceruta, +-1,5°, in ultimele 4 s din 14.
	var idle_lo: Array = []
	var idle_hi: Array = []
	for rs: Array in _results:
		var r := _find(rs, "leagan_propriu")
		var lo := INF
		var hi := 0.0
		for i in range(maxi(r.angle_trace.size() - 240, 0), r.angle_trace.size()):
			lo = minf(lo, r.amp_trace[i])
			hi = maxf(hi, r.angle_trace[i])
		idle_lo.append(lo)
		idle_hi.append(hi)
		ok = ok and absf(hi - IDLE_DEG) <= 1.5 and absf(lo - IDLE_DEG) <= 1.5
	_check(ok, "a. REPAUS: unghi max %s° (< 1), discul mutat %s cm (< 2) in 3 s; leagan propriu %.0f°: varf %s°, amplitudine min %s° (+-1,5)"
		% [_spread(ang), _spread(disp), IDLE_DEG, _spread(idle_hi), _spread(idle_lo)])


func _contract_b() -> void:
	var ok := true
	var notes: Array[String] = []
	for rs: Array in _results:
		var k := {}
		for c in CARS_B:
			var r := _find(rs, "lovitura_" + c)
			var tr: Tracked = r.cars[0]
			k[c] = _kept(tr, 1.0)
			if tr.contact_frame < 0:
				ok = false
				notes.append("%s n-a atins gongul" % c)
				continue
			if _speed_at(tr, 1.5) <= 5.0:
				ok = false
				notes.append("%s la %.1f m/s la 1,5 s" % [c, _speed_at(tr, 1.5)])
			if tr.max_y >= 1.5:
				ok = false
				notes.append("%s aruncat la %.2f m" % [c, tr.max_y])
			if tr.ejects + tr.respawns + tr.recovers > 0:
				ok = false
				notes.append("%s: ejectari %d, repuneri %d, tranzitii %d" % [c, tr.ejects,
					tr.respawns, tr.recovers])
		var bus := float(k["bus"])
		var bug := float(k["buggy"])
		var tuk := float(k["tuktuk"])
		if not (bus > bug and bug > tuk):
			ok = false
			notes.append("ordinea: bus %.2f, buggy %.2f, tuk-tuk %.2f" % [bus, bug, tuk])
		if bus < 0.80:
			ok = false
			notes.append("bus pastreaza %.0f%% (< 80)" % (bus * 100.0))
		if bus - tuk < MASS_GAP:
			ok = false
			notes.append("bus - tuk-tuk = %.0f%% (< %.0f)" % [(bus - tuk) * 100.0, MASS_GAP * 100.0])
	_check(ok, "b. MASA DECIDE: bus > buggy > tuk-tuk, bus >= 80%%, tuk-tuk cu >= %.0f%% sub bus, > 5 m/s la 1,5 s, < 1,5 m, fara ejectari/repuneri%s"
		% [MASS_GAP * 100.0, "" if notes.is_empty() else " — " + ", ".join(notes)])


func _contract_c() -> void:
	var ok := true
	var a1: Array = []
	var amax: Array = []
	var arm: Array = []
	var a15: Array = []
	var lim := 0.0
	for rs: Array in _results:
		var r := _find(rs, "leagan_buggy")
		lim = r.limit_deg
		if r.hit_frame < 0:
			ok = false
			continue
		var peak1 := 0.0
		for i in range(r.hit_frame, mini(r.hit_frame + 60, r.angle_trace.size())):
			peak1 = maxf(peak1, r.angle_trace[i])
		var i15 := mini(r.hit_frame + 15 * 60, r.amp_trace.size() - 1)
		a1.append(peak1)
		amax.append(r.max_angle)
		arm.append(r.max_arm_err * 100.0)
		a15.append(r.amp_trace[i15])
		ok = ok and peak1 > 25.0 and r.max_angle <= lim + 0.5 and r.max_arm_err < 0.05 \
			and r.amp_trace[i15] < 5.0
	# Limita si prinderea: si in TOATE celelalte scenarii (autobuzul in gongul care se
	# intoarce e lovitura cea mai grea, nu buggy-ul).
	var all_ang: Array = []
	var all_arm: Array = []
	for rs: Array in _results:
		var worst_a := 0.0
		var worst_e := 0.0
		for r: Run in rs:
			if r.limit_deg <= 0.0: # fara gong (referinte)
				continue
			if r.sabotaged and _sab != "leagan":
				continue # gongul altui contract
			worst_a = maxf(worst_a, r.max_angle)
			worst_e = maxf(worst_e, r.max_arm_err)
			ok = ok and r.max_angle <= r.limit_deg + 0.5 and r.max_arm_err < 0.05
		all_ang.append(worst_a)
		all_arm.append(worst_e * 100.0)
	_check(ok, "c. LEAGAN: max in 1 s %s° (> 25), max %s° (<= limita %.0f), prindere %s cm (< 5), amplitudine la 15 s %s° (< 5); toate scenariile: unghi max %s°, prindere %s cm"
		% [_spread(a1), _spread(amax), lim, _spread(arm), _spread(a15), _spread(all_ang),
		_spread(all_arm)])


func _contract_d() -> void:
	var ok := true
	var notes: Array[String] = []
	var worst_all: Array = []
	for rs: Array in _results:
		for p: Array in PAIRS:
			for dl: float in PAIR_DELAYS:
				var r := _find(rs, _pair_name(p, dl))
				for tr: Tracked in r.cars:
					var base := _find(rs, "referinta_" + tr.kind)
					var w := _max_vs_base(tr, base.cars[0])
					worst_all.append(w)
					if w > 1.15:
						ok = false
						notes.append("%s/%s %.2fx la %.2f s [%s]" % [r.name, tr.kind, w,
							tr.worst_at, tr.worst_what.strip_edges()])
					if tr.max_y >= 1.5:
						ok = false
						notes.append("%s/%s aruncat %.2f m" % [r.name, tr.kind, tr.max_y])
					if tr.max_stuck > 1.0:
						ok = false
						notes.append("%s/%s blocat %.1f s" % [r.name, tr.kind, tr.max_stuck])
					if tr.nan:
						ok = false
						notes.append("%s/%s NaN" % [r.name, tr.kind])
					if tr.launched_frame < 0:
						ok = false
						notes.append("%s/%s nelansata" % [r.name, tr.kind])
	_check(ok, "d. FARA PRASTIE: max v/referinta %s (<= 1.15), fara zbor, blocaj sau NaN%s"
		% [_spread(worst_all), "" if notes.is_empty() else " — " + ", ".join(notes)])


func _contract_e() -> void:
	var ok := true
	var lat: Array = []
	var notes: Array[String] = []
	for rs: Array in _results:
		var worst := 0.0
		for r: Run in rs:
			if r.sabotaged and _sab != "banda":
				continue # gongul altui contract
			worst = maxf(worst, r.max_lat)
		lat.append(worst)
		ok = ok and worst <= 0.15
		for c in LANE_CARS:
			var r := _find(rs, "banda_" + c)
			var tr: Tracked = r.cars[0]
			if tr.touched or r.max_angle > 0.5:
				ok = false
				notes.append("%s a atins discul (unghi %.1f°)" % [c, r.max_angle])
	_check(ok, "e. BANDA: deplasare laterala max %s m (<= 0.15); trecere la 1,0 m de buza: neatins%s"
		% [_spread(lat), "" if notes.is_empty() else " — " + ", ".join(notes)])


func _contract_f() -> void:
	var ok := true
	var notes: Array[String] = []
	var singles: Array[String] = ["leagan_buggy"]
	for c in CARS_B:
		singles.append("lovitura_" + c)
	for rs: Array in _results:
		var rest := _find(rs, "repaus")
		if rest.rings != 0 or rest.sfx_rings != 0:
			ok = false
			notes.append("repaus %d" % rest.rings)
		for c in LANE_CARS:
			var ln := _find(rs, "banda_" + c)
			if ln.rings != 0:
				ok = false
				notes.append("banda_%s %d" % [c, ln.rings])
		for nm in singles:
			var r := _find(rs, nm)
			if r.rings != 1 or r.sfx_rings != r.rings:
				ok = false
				notes.append("%s: %d apeluri, %d redari" % [nm, r.rings, r.sfx_rings])
		for p: Array in PAIRS:
			for dl: float in PAIR_DELAYS:
				var r := _find(rs, _pair_name(p, dl))
				var episodes := 0
				for tr: Tracked in r.cars:
					episodes += tr.touch_episodes
				if r.rings < 1 or r.rings > episodes or r.sfx_rings != r.rings:
					ok = false
					notes.append("%s: %d sunete la %d contacte (%d redari)" % [r.name,
						r.rings, episodes, r.sfx_rings])
	_check(ok, "f. SUNET: 0 in repaus si pe langa, 1 per lovitura, <= contacte la perechi, apeluri = redari%s"
		% ("" if notes.is_empty() else " — " + ", ".join(notes)))
