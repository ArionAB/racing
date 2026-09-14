extends Node
## Sondele tehnice de TEREN de dinaintea traseului Machu Picchu (brief §7
## pasul 1 b/c/d). Podul (testul A) e in tools/probe_machu.gd.
##
## Pe sol plat / geometrie de test, fara pista:
##   B. TREPTELE DRUMULUI INCAS ca suprafata („ruina ca si carosabil", §3):
##      coliziunea e panta lina, treptele sunt zgomot de ±3 cm pe raycast-ul
##      suspensiei (Car.STEP_NOISE_M; aici prin meta `inca_steps` pe colizor).
##      Doua rampe identice de 10.6% x 100 m, una cu trepte: viteza la iesire
##      difera cu < 3%, suspensia vibreaza masurabil (deviatia standard a
##      compresiei si a vitezei verticale), masina nu sare si nu se ingroapa,
##      semnalul `steps_changed` se emite.
##   C. CASCADA DE TERASE: 8 caderi de 2.5 m la rand (trepte de 12 m), cele 5
##      presetari din garaj, intrare la 12 si la 20 m/s cu gaz tinut (plafon
##      la viteza de intrare). Verdict: nicio rasturnare (up·UP > 0.5 tot
##      timpul), ajunge jos si mai merge. Se raporteaza timpul, tangajul
##      maxim, contactele cu zidul urmator (fata verticala) si aterizarile
##      dure, ca sa se vada daca „Autobuzul nu poate" (brief §2 POI D) e
##      adevarat cu fizica reala.
##   D. AUTOBUZUL care coboara serpentinele (BusHazard pe Path3D): ac de par
##      de test (drum 6.5 m, raza 10 m), autobuzul pe 2/3 exterior la 7 m/s.
##      Sportul urca pe partea lui la 15 m/s: impins lateral 1-3 m, nu oprit
##      sub 5 m/s mai mult de 1 s. Pe interiorul acului: zero contact, zero
##      ghiont. Costul pe tick sub 100 us. Plus intalnirea PE ac (informativ).
##
## Ruleaza CA SCENA (Car are nevoie de autoload-uri):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeMachuTeren.tscn
##   godot ... res://tools/ProbeMachuTeren.tscn -- --only=D   (doar un test)
## Fizica (Jolt, multithread) e nedeterminista: ruleaza de 3 ori si citeste
## intervalul, nu o cifra (memoria `proberace-nedeterminism`). Pe 14 sep 2026
## trei rulari au iesit identice la bit (o singura masina, geometrie simpla).
##
## CE A IESIT (14 sep 2026), ca sa nu se reia de la zero:
##   B. trece: viteza la iesire identica (0.00%), sigma compresie 0.022 m si
##      sigma delta-v_y/tick 0.072 m/s pe trepte fata de 0.0003 / 0.001 fara.
##   C. trece pentru TOATE presetarile la 12 si 20 m/s: up min 0.81-0.93,
##      zero contact cu zidul urmator, tangaj max 35° (12 m/s) / 28° (20).
##      Afirmatia din brief §2 POI D („Autobuzul greu nu poate") e FALSA cu
##      fizica reala: 8.08 / 6.00 s fata de sportul 7.78 / 4.67 s. Daca se
##      vrea ca scurtatura sa fie a masinilor usoare, trebuie CONSTRUIT
##      (trepte mai adanci decat zborul unui corp greu, buza care agata), nu
##      presupus.
##   D. jumatate: pe dreapta, interiorul trece curat (0 contact, 0 ghiont la
##      15 m/s) si masina de pe partea autobuzului NU e oprita (max 0.68 s
##      sub 5 m/s), dar e impinsa 4.1 m spre exterior, nu 1-3: la un contact
##      frontal centrat, ca sa scape de coltul unui corp de 4.2 m trebuie
##      sa se mute geometric >= 2.1 + 0.87 ~ 3 m, deci „1-3 m" e sub minimul
##      geometric. PE ac (raza 10), interiorul NU trece: sportul deriva
##      ~0.8 m spre exterior la 9 m/s, iar coarda autobuzului taie din banda
##      (0.41 m la 6 m lungime, 0.95 m la 9 m) — 2.3 m de banda libera nu
##      ajung. Un corp de 9 m bloca masina 3.6 s; la 6 m, 0.10 s.

const STEP: float = 1.0 / 60.0
const BusScript := preload("res://scenes/hazards/bus_hazard.gd")

## Presetarile, in ordinea din GameState.CAR_DATA: muscle 1.35, sport 0.9,
## taxi 1.15, autobuz 2.6, pompieri 2.0.
const SPORT: int = 1
const BUS: int = 3

# --- geometria de test ---
const RAMP_SLOPE: float = 0.106
const RAMP_LEN: float = 100.0
const RAMP_X_PLAIN: float = 0.0
const RAMP_X_STEPS: float = 40.0
const TERRACE_X: float = 1000.0
const TERRACE_DROP: float = 2.5
const TERRACE_DEPTH: float = 12.0
const TERRACE_DROPS: int = 8
const HAIRPIN_X: float = -200.0
const ROAD_HALF: float = 3.25
const HAIRPIN_R: float = 10.0
const HAIRPIN_LEG: float = 70.0
const BUS_WIDTH: float = 4.2
## Lungimea autobuzului: pe un ac de raza 10, un corp de 9 m taie ~0.95 m din
## interior (sageata corzii), deci banda libera de 2.3 m nu mai incape sportul.
const BUS_LENGTH: float = 6.0
const NOSE_DEG: float = 20.0
## Autobuzul pe 2/3 exterior: centrul lui la (hw - latime/2) spre exterior.
const BUS_LANE: float = ROAD_HALF - BUS_WIDTH * 0.5
## Banda interioara ramasa (1/3): centrul ei.
const INNER_LANE: float = -(ROAD_HALF - (ROAD_HALF * 2.0 - BUS_WIDTH) * 0.5)

var _failed: bool = false
## Scrise de lambda-uri: MEMBRI, nu locale (capturare prin valoare).
var _steps_signals: int = 0
var _shoves: int = 0
## Corp de treapta -> cota fetei de sus (pentru contactele cu zidul).
var _terrace_tops: Dictionary = {}


class ScriptDriver:
	extends CarController
	var steer: float = 0.0
	var throttle: float = 1.0
	func get_steer() -> float:
		return steer
	func get_throttle() -> float:
		return throttle
	func is_drift_pressed() -> bool:
		return false
	func is_turbo_pressed() -> bool:
		return false


## Tine o banda: urmareste o polilinie de repere (pure pursuit, privire
## inainte de `lookahead` m). Steer +1 = stanga (conventia Car).
class LaneDriver:
	extends CarController
	var points: PackedVector3Array = PackedVector3Array()
	var lookahead: float = 6.0
	var throttle: float = 1.0
	var _idx: int = 0
	func get_steer() -> float:
		if car == null or points.is_empty():
			return 0.0
		var pos := car.global_position
		var fwd := -car.global_transform.basis.z
		fwd.y = 0.0
		# Reperele deja depasite (prea aproape sau in spate) se sar.
		while _idx < points.size() - 1:
			var d := points[_idx] - pos
			d.y = 0.0
			if d.length() < lookahead or d.dot(fwd) < 0.0:
				_idx += 1
			else:
				break
		var target := points[_idx]
		var to := target - pos
		to.y = 0.0
		if to.length_squared() < 0.01 or fwd.length_squared() < 0.01:
			return 0.0
		var ang := fwd.normalized().signed_angle_to(to.normalized(), Vector3.UP)
		return clampf(ang / 0.35, -1.0, 1.0)
	func get_throttle() -> float:
		return throttle
	func is_drift_pressed() -> bool:
		return false
	func is_turbo_pressed() -> bool:
		return false


func _ready() -> void:
	_build_ground()
	_build_ramps()
	_build_terraces()
	await get_tree().physics_frame
	await get_tree().physics_frame

	# `-- --only=D` (sau B,C) ruleaza doar testele cerute, cat se itereaza pe
	# unul singur; fara argument ruleaza tot.
	var only := "BCD"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			only = arg.trim_prefix("--only=").to_upper()
	print("")
	print("=== Machu Picchu: sondele tehnice de teren (B, C, D) ===")
	if only.contains("B"):
		await _test_steps()
	if only.contains("C"):
		await _test_terraces()
	if only.contains("D"):
		await _test_bus()
	print("")
	print("REZULTAT: ", "PICAT" if _failed else "TRECUT")
	get_tree().quit(1 if _failed else 0)


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _wait(seconds: float) -> void:
	for _f in int(seconds / STEP):
		await get_tree().physics_frame


# ------------------------------------------------------------------ geometrie

func _static_box(size: Vector3, xform: Transform3D, meta: StringName = &"") -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	if meta != &"":
		body.set_meta(meta, true)
	add_child(body)
	body.global_transform = xform
	return body


## Solul plat (y = 0) pentru rampe si pentru acul de par; terasele sunt
## departe, in x = TERRACE_X, in afara lui.
func _build_ground() -> void:
	_static_box(Vector3(800, 1, 800),
		Transform3D(Basis.IDENTITY, Vector3(-100, -0.5, 0)))


## Doua rampe de 10.6%: urca spre -Z de la z = 0 (y = 0) la z = -RAMP_LEN.
func _build_ramps() -> void:
	var ang := atan(RAMP_SLOPE)
	var basis := Basis(Vector3.RIGHT, ang)
	var normal := basis * Vector3.UP
	var along := basis * Vector3.FORWARD # urca
	var slant := RAMP_LEN / cos(ang)
	for x: float in [RAMP_X_PLAIN, RAMP_X_STEPS]:
		var top_mid := Vector3(x, 0.0, 0.0) + along * (slant * 0.5)
		var center := top_mid - normal * 0.5
		var meta := &"inca_steps" if x == RAMP_X_STEPS else &""
		_static_box(Vector3(16.0, 1.0, slant + 4.0), Transform3D(basis, center), meta)
	# Platou la varf, ca masina sa aiba unde iesi (masuratoarea se opreste
	# inainte de el).
	for x: float in [RAMP_X_PLAIN, RAMP_X_STEPS]:
		var top_y := RAMP_LEN * RAMP_SLOPE
		_static_box(Vector3(16.0, 1.0, 60.0),
			Transform3D(Basis.IDENTITY, Vector3(x, top_y - 0.5, -RAMP_LEN - 30.0)))


func _ramp_surface_y(z: float) -> float:
	return clampf(-z, 0.0, RAMP_LEN) * RAMP_SLOPE


## Platou sus (y = 0, z > 0), apoi TERRACE_DROPS caderi de TERRACE_DROP m, cu
## trepte de TERRACE_DEPTH m; ultima treapta continua ca platou jos.
func _build_terraces() -> void:
	_static_box(Vector3(60.0, 1.0, 60.0),
		Transform3D(Basis.IDENTITY, Vector3(TERRACE_X, -0.5, 30.0)))
	var floor_y := -TERRACE_DROP * float(TERRACE_DROPS) - 10.0
	for k in TERRACE_DROPS:
		var top_y := -TERRACE_DROP * float(k + 1)
		var depth := TERRACE_DEPTH if k < TERRACE_DROPS - 1 else 120.0
		var z0 := -TERRACE_DEPTH * float(k)
		var h := top_y - floor_y
		var body := _static_box(Vector3(60.0, h, depth),
			Transform3D(Basis.IDENTITY,
				Vector3(TERRACE_X, floor_y + h * 0.5, z0 - depth * 0.5)))
		_terrace_tops[body] = top_y


# ------------------------------------------------------------------ masini

## Masina din garaj, botul spre -Z, gaz tinut, plafon la `speed` daca e > 0.
func _spawn(pos: Vector3, preset: int, speed: float, cap: bool = true,
		driver: CarController = null) -> Car:
	var car := Car.new()
	add_child(car)
	car.apply_data(GameState.CAR_DATA[preset])
	car.global_position = pos
	car.race_active = true
	if driver == null:
		driver = ScriptDriver.new()
	car.set_controller(driver)
	if cap and speed > 0.0:
		car.speed_limit_factor = speed / car.max_speed
	car.linear_velocity = Vector3(0, 0, -speed)
	return car


func _free(car: Car) -> void:
	car.queue_free()
	await get_tree().physics_frame


func _preset_name(preset: int) -> String:
	var d := GameState.CAR_DATA[preset] as CarData
	return "%s (%.2f)" % [d.display_name, d.mass_factor]


# ------------------------------------------------------------------ B. trepte

func _test_steps() -> void:
	print("")
	print("-- B. treptele Drumului Incas ca suprafata (panta %.1f%%, %.0f m) --"
		% [RAMP_SLOPE * 100.0, RAMP_LEN])
	var plain := await _climb(RAMP_X_PLAIN)
	var steps := await _climb(RAMP_X_STEPS)
	for r: Dictionary in [plain, steps]:
		print("  %s: viteza intrare %.2f -> iesire %.2f m/s, timp %.2f s, sigma compresie %.4f m, sigma delta-v_y/tick %.3f m/s, y fata de panta [%.2f, %.2f], roti in aer %d cadre, semnale trepte %d"
			% [r.label, r.v_in, r.v_out, r.t, r.comp_sd, r.vy_sd, r.dy_min, r.dy_max, r.air, r.signals])
	var diff := absf(float(steps.v_out) - float(plain.v_out)) / maxf(float(plain.v_out), 0.1)
	print("  diferenta de viteza la iesire: %.2f%%" % (diff * 100.0))
	_check(diff < 0.03, "fara pierdere de viteza pe trepte (< 3%%: %.2f%%)" % (diff * 100.0))
	_check(float(steps.comp_sd) > 0.005 and float(steps.comp_sd) > float(plain.comp_sd) * 3.0,
		"suspensia vibreaza pe trepte (sigma compresie %.4f vs %.4f fara)"
		% [steps.comp_sd, plain.comp_sd])
	_check(float(steps.vy_sd) > 0.02 and float(steps.vy_sd) > float(plain.vy_sd) * 3.0,
		"vibratia ajunge in caroserie (sigma delta-v_y pe tick %.3f vs %.3f m/s fara)"
		% [steps.vy_sd, plain.vy_sd])
	_check(float(steps.dy_min) > -0.25 and float(steps.dy_max) < 0.6,
		"masina nu se ingroapa si nu sare de pe panta (y fata de panta in [-0.25, 0.6])")
	_check(int(steps.air) == 0, "toate rotile raman pe sol pe trepte")
	_check(int(steps.signals) >= 2 and int(plain.signals) == 0,
		"semnalul steps_changed: intrare + iesire pe trepte, niciunul pe rampa simpla")
	_check(bool(steps.on_steps_seen) and not bool(plain.on_steps_seen),
		"Car.on_steps e adevarat doar pe trepte")


func _climb(x: float) -> Dictionary:
	_steps_signals = 0
	var car := _spawn(Vector3(x, 0.7, 25.0), SPORT, 15.0, false)
	car.steps_changed.connect(func(_c: Car, _on: bool) -> void: _steps_signals += 1)
	var comp: Array[float] = []
	var vy: Array[float] = []
	var dy_min := INF
	var dy_max := -INF
	var air := 0
	var v_in := 0.0
	var v_out := 0.0
	var t0 := -1.0
	var t1 := -1.0
	var t := 0.0
	var on_steps_seen := false
	var vy_prev := car.linear_velocity.y
	# Pana PE platoul de sus (z < -RAMP_LEN - 6), ca sa se vada si iesirea de
	# pe trepte (semnalul de iesire).
	while car.global_position.z > -RAMP_LEN - 6.0 and t < 20.0:
		await get_tree().physics_frame
		t += STEP
		var z := car.global_position.z
		if car.on_steps:
			on_steps_seen = true
		if z < 0.0 and t0 < 0.0:
			t0 = t
			v_in = car.horizontal_speed()
		if z < -10.0 and z > -RAMP_LEN + 10.0:
			# Compresia rotii din fata-stanga; acceleratia verticala a
			# caroseriei (delta-v pe tick): pe panta constanta v_y creste lin
			# cu viteza, deci abaterea EI ar masura motorul, nu vibratia.
			comp.append(car.wheel_compression[0])
			vy.append(car.linear_velocity.y - vy_prev)
			var dy := car.global_position.y - _ramp_surface_y(z)
			dy_min = minf(dy_min, dy)
			dy_max = maxf(dy_max, dy)
			if car.wheels_on_ground < 4:
				air += 1
		vy_prev = car.linear_velocity.y
		if z < -RAMP_LEN + 5.0 and t1 < 0.0:
			t1 = t
			v_out = car.horizontal_speed()
	if v_out == 0.0:
		v_out = car.horizontal_speed()
	await _free(car)
	return {"label": "cu trepte" if x == RAMP_X_STEPS else "rampa simpla",
		"v_in": v_in, "v_out": v_out, "t": t1 - t0,
		"comp_sd": _stddev(comp), "vy_sd": _stddev(vy),
		"dy_min": dy_min, "dy_max": dy_max, "air": air,
		"signals": _steps_signals, "on_steps_seen": on_steps_seen}


func _stddev(values: Array[float]) -> float:
	if values.size() < 2:
		return 0.0
	var mean := 0.0
	for v in values:
		mean += v
	mean /= float(values.size())
	var acc := 0.0
	for v in values:
		acc += (v - mean) * (v - mean)
	return sqrt(acc / float(values.size() - 1))


# ------------------------------------------------------------------ C. terase

func _test_terraces() -> void:
	print("")
	print("-- C. cascada de terase: %d caderi de %.1f m, trepte de %.0f m --"
		% [TERRACE_DROPS, TERRACE_DROP, TERRACE_DEPTH])
	var bus_ok := true
	var bus_walls := 0
	var times := {}
	for preset in GameState.CAR_DATA.size():
		for speed: float in [12.0, 20.0]:
			var r := await _descend(preset, speed)
			print("  %-16s la %2.0f m/s: timp %5.2f s, tangaj max %5.1f°, up min %.2f, zid urmator %d cadre (trepte %s), aterizari dure %d cadre, aer %d cadre, v jos %.1f m/s, ajuns %s"
				% [_preset_name(preset), speed, r.t, r.pitch_max, r.up_min,
					r.wall_frames, str(r.wall_steps), r.hard_frames, r.air, r.v_end,
					str(r.arrived)])
			_check(float(r.up_min) > 0.5, "%s la %.0f m/s: fara rasturnare" % [_preset_name(preset), speed])
			_check(bool(r.arrived) and float(r.v_end) > 3.0,
				"%s la %.0f m/s: ajunge jos si mai merge" % [_preset_name(preset), speed])
			times[[preset, speed]] = r.t
			if preset == BUS:
				bus_walls += int(r.wall_frames)
				if not bool(r.arrived) or float(r.up_min) <= 0.5:
					bus_ok = false
	# Cifra, nu dorinta: brief-ul §2 POI D zice ca Autobuzul „nu poate" lua
	# scurtatura direct. Se raporteaza ce a iesit din fizica.
	print("  brief §2 POI D 'Autobuzul greu nu poate lua scurtatura direct': %s (autobuz %.2f/%.2f s vs sport %.2f/%.2f s la 12/20 m/s, contact cu zidul %d cadre)"
		% ["FALS cu fizica reala — ajunge jos pe roti" if bus_ok
			else "ADEVARAT cu fizica reala — se rastoarna sau nu ajunge",
			times[[BUS, 12.0]], times[[BUS, 20.0]], times[[SPORT, 12.0]], times[[SPORT, 20.0]],
			bus_walls])


func _descend(preset: int, speed: float) -> Dictionary:
	var car := _spawn(Vector3(TERRACE_X, 0.7, 30.0), preset, speed)
	var t := 0.0
	var t0 := -1.0
	var pitch_max := 0.0
	var up_min := 1.0
	var wall_frames := 0
	var wall_steps: Array[int] = []
	var hard_frames := 0
	var air := 0
	var arrived := false
	var bottom_z := -TERRACE_DEPTH * float(TERRACE_DROPS - 1) - 8.0
	while t < 30.0:
		await get_tree().physics_frame
		t += STEP
		var z := car.global_position.z
		if z < 0.0 and t0 < 0.0:
			t0 = t
		if t0 >= 0.0:
			var fwd := -car.global_transform.basis.z
			pitch_max = maxf(pitch_max, rad_to_deg(asin(clampf(-fwd.y, -1.0, 1.0))))
			up_min = minf(up_min, car.global_transform.basis.y.y)
			if car.wheels_on_ground == 0:
				air += 1
			for body in car.get_colliding_bodies():
				if not _terrace_tops.has(body):
					continue
				var top: float = _terrace_tops[body]
				var k := int(roundf(-top / TERRACE_DROP)) - 1
				# Fata verticala a treptei k e la z = -TERRACE_DEPTH * k. Contact
				# cu corpul k cat originea e inca INAINTEA fetei (botul in zid);
				# altfel e caroseria pe treapta (aterizare dura, suspensia la
				# capat de cursa — talpa colizerului e la +0.25).
				var face_z := -TERRACE_DEPTH * float(k)
				if car.global_position.z > face_z + 0.3 and car.global_position.y < top + 0.1:
					wall_frames += 1
					if not wall_steps.has(k):
						wall_steps.append(k)
				else:
					hard_frames += 1
		if z < bottom_z:
			arrived = true
			break
	var v_end := car.horizontal_speed()
	await _free(car)
	return {"t": t - t0 if t0 >= 0.0 else t, "pitch_max": pitch_max, "up_min": up_min,
		"wall_frames": wall_frames, "wall_steps": wall_steps,
		"hard_frames": hard_frames, "air": air, "v_end": v_end, "arrived": arrived}


# ------------------------------------------------------------------ D. autobuz

## Curba autobuzului in spatiul local al nodului: coboara pe x = +BUS_LANE
## spre -Z, ia acul in jurul originii pe raza (HAIRPIN_R + BUS_LANE), urca
## inapoi pe x = -(HAIRPIN_R + BUS_LANE) spre +Z. Masinile urca pe partea
## x < 0 spre -Z si ies pe x > 0 spre +Z.
func _bus_curve() -> Curve3D:
	var c := Curve3D.new()
	var r := HAIRPIN_R + BUS_LANE
	c.add_point(Vector3(r, 0.0, HAIRPIN_LEG))
	c.add_point(Vector3(r, 0.0, 0.0))
	for k in range(1, 8):
		var a := PI * float(k) / 8.0
		c.add_point(Vector3(r * cos(a), 0.0, -r * sin(a)))
	c.add_point(Vector3(-r, 0.0, 0.0))
	c.add_point(Vector3(-r, 0.0, HAIRPIN_LEG))
	return c


## Reperele benzii de urcare pentru masina: pe x = -(HAIRPIN_R + offset)
## dinspre +Z, apoi pe arc, apoi pe x = +(HAIRPIN_R + offset) spre +Z.
## `offset` > 0 = spre exterior (partea autobuzului), < 0 = interior.
func _lane_points(offset: float) -> PackedVector3Array:
	var pts := PackedVector3Array()
	var r := HAIRPIN_R + offset
	var origin := Vector3(HAIRPIN_X, 0.0, 0.0)
	for z in range(int(HAIRPIN_LEG) - 5, 0, -5):
		pts.append(origin + Vector3(-r, 0.0, float(z)))
	for k in range(0, 13):
		var a := PI * float(k) / 12.0
		pts.append(origin + Vector3(-r * cos(a), 0.0, -r * sin(a)))
	for z in range(5, int(HAIRPIN_LEG) + 10, 5):
		pts.append(origin + Vector3(r, 0.0, float(z)))
	return pts


func _test_bus() -> void:
	print("")
	print("-- D. autobuzul care coboara serpentinele (drum %.1f m, raza %.0f m) --"
		% [ROAD_HALF * 2.0, HAIRPIN_R])
	var bus: Node3D = BusScript.new()
	bus.curve = _bus_curve()
	bus.speed = 7.0
	bus.period = 35.0
	bus.body_size = Vector3(BUS_WIDTH, 3.0, BUS_LENGTH)
	bus.nose_angle_deg = NOSE_DEG
	add_child(bus)
	bus.global_position = Vector3(HAIRPIN_X, 0.0, 0.0)
	bus.shoved.connect(func(_b: Node3D, _c: Car) -> void: _shoves += 1)
	await get_tree().physics_frame
	var length: float = bus.curve.get_baked_length()
	print("  curba %.0f m, coborare %.1f s, ciclu %.0f s, autobuz %.1f m lat x %.0f m lung, bot %.0f° (banda libera %.2f m)"
		% [length, length / bus.speed, bus.period, BUS_WIDTH, BUS_LENGTH, NOSE_DEG, ROAD_HALF * 2.0 - BUS_WIDTH])

	# 1. pe partea autobuzului, pe dreapta de urcare, la 15 m/s
	var straight_meet := HAIRPIN_LEG + PI * (HAIRPIN_R + BUS_LANE) + 15.0
	var r1 := await _meet(bus, BUS_LANE, 15.0, straight_meet, "partea autobuzului, dreapta")
	_check(int(r1.contacts) + int(r1.shoves) > 0, "partea autobuzului: contact/ghiont cu autobuzul")
	_check(absf(float(r1.lateral_max)) >= 1.0 and absf(float(r1.lateral_max)) <= 3.0,
		"partea autobuzului: impins lateral 1-3 m (%.2f m)" % r1.lateral_max)
	_check(float(r1.lateral_max) < 0.0, "partea autobuzului: impins spre EXTERIOR")
	_check(float(r1.slow_max) <= 1.0, "partea autobuzului: nu e oprit sub 5 m/s mai mult de 1 s (%.2f s)" % r1.slow_max)
	_check(float(r1.up_min) > 0.5, "partea autobuzului: fara rasturnare")

	# 2. pe interiorul acului (banda libera), pe dreapta, la 15 m/s
	var r2 := await _meet(bus, INNER_LANE, 15.0, straight_meet, "interior, dreapta")
	_check(int(r2.contacts) == 0 and int(r2.shoves) == 0, "interior: zero contact, zero ghiont")
	_check(float(r2.v_min) > 12.0, "interior: viteza pastrata (min %.1f m/s)" % r2.v_min)

	# 3. intalnire PE ac, partea autobuzului, 9 m/s (informativ + siguranta)
	var arc_meet := HAIRPIN_LEG + PI * (HAIRPIN_R + BUS_LANE) * 0.5
	var r3 := await _meet(bus, BUS_LANE, 9.0, arc_meet, "partea autobuzului, PE ac")
	_check(float(r3.up_min) > 0.5, "pe ac: fara rasturnare")
	_check(float(r3.slow_max) <= 1.5, "pe ac: nu e oprit sub 5 m/s mai mult de 1.5 s (%.2f s)" % r3.slow_max)
	# 4. interiorul acului PE ac, 9 m/s
	var r4 := await _meet(bus, INNER_LANE, 9.0, arc_meet, "interior, PE ac")
	_check(int(r4.contacts) == 0, "interior pe ac: zero contact cu autobuzul")

	# 5. costul pe tick, cu o masina in zona
	var car := _spawn(Vector3(HAIRPIN_X - HAIRPIN_R - BUS_LANE, 0.7, 40.0), SPORT, 0.0)
	await _wait(0.5)
	var total := 0
	var worst := 0
	var n := int(3.0 / STEP)
	for _f in n:
		await get_tree().physics_frame
		total += bus.last_tick_usec
		worst = maxi(worst, bus.last_tick_usec)
	print("  tick autobuz: mediu %d us, varf %d us" % [total / n, worst])
	_check(total / n < 100, "costul pe tick sub 100 us in medie")
	await _free(car)
	bus.queue_free()
	await get_tree().physics_frame


## Asteapta ca autobuzul sa fie la `meet_dist - gap` pe curba, apoi lanseaza
## masina pe banda `offset` din z = +HAIRPIN_LEG, la `speed`, si o urmareste
## 5 s. Autobuzul si masina se inchid cu (speed + 7) m/s, deci gap-ul se alege
## ca intalnirea sa cada la `meet_dist` pe curba autobuzului.
func _meet(bus: Node3D, offset: float, speed: float, meet_dist: float,
		label: String) -> Dictionary:
	_shoves = 0
	# Distanta masinii pana la punctul de intalnire, masurata pe banda ei:
	# de la z = HAIRPIN_LEG pe dreapta (spre z = 0), apoi pe arc.
	var car_r := HAIRPIN_R + offset
	var bus_r := HAIRPIN_R + BUS_LANE
	var car_dist_to_meet := 0.0
	if meet_dist <= HAIRPIN_LEG + PI * bus_r:
		var arc_frac := (meet_dist - HAIRPIN_LEG) / (PI * bus_r)
		car_dist_to_meet = HAIRPIN_LEG + PI * car_r * (1.0 - arc_frac)
	else:
		car_dist_to_meet = HAIRPIN_LEG - (meet_dist - HAIRPIN_LEG - PI * bus_r)
	var car_time := car_dist_to_meet / speed
	var bus_start: float = meet_dist - bus.speed * car_time
	# Asteapta faza potrivita a ciclului.
	var guard := 0
	while (bus.is_hidden() or bus.distance() < bus_start
			or bus.distance() > bus_start + 0.5) and guard < int(80.0 / STEP):
		await get_tree().physics_frame
		guard += 1
	var lane_x := HAIRPIN_X - car_r
	var drv := LaneDriver.new()
	drv.points = _lane_points(offset)
	var car := _spawn(Vector3(lane_x, 0.7, HAIRPIN_LEG), SPORT, speed, true, drv)
	var body: Node3D = bus.body()
	var contacts := 0
	var v_min := INF
	var slow_run := 0.0
	var slow_max := 0.0
	var up_min := 1.0
	var lat_max := 0.0
	var min_gap := INF
	# Se masoara pana cand masina a trecut cu 25 m de punctul de intalnire
	# (pe banda ei), nu un timp fix: altfel derapajul de pe arc de DUPA
	# intalnire intra in „deviere", iar o intalnire departe iese din fereastra.
	var frames := int((car_time + 8.0) / STEP)
	for _f in frames:
		await get_tree().physics_frame
		if _lane_progress(car, car_r) > car_dist_to_meet + 25.0:
			break
		for b in car.get_colliding_bodies():
			if b == body:
				contacts += 1
		# Viteza de INAINTARE pe banda: pe dreapta e -Z; pe arc, tangenta.
		var prog := _progress_speed(car, offset)
		v_min = minf(v_min, prog)
		if prog < 5.0:
			slow_run += STEP
			slow_max = maxf(slow_max, slow_run)
		else:
			slow_run = 0.0
		up_min = minf(up_min, car.global_transform.basis.y.y)
		var gap: float = (car.global_position - body.global_position).length()
		min_gap = minf(min_gap, gap)
		# Devierea se citeste doar IN intalnire (aproape de autobuz): dupa,
		# driverul revine pe banda, iar pe arc sportul deriva oricum.
		if gap < 14.0:
			var lat := _lateral_offset(car, car_r)
			if absf(lat) > absf(lat_max):
				lat_max = lat
	print("  %s la %.0f m/s: contact %d cadre, ghionturi %d, deviere max in intalnire %.2f m (+ = spre interior), v inaintare min %.1f m/s, sub 5 m/s max %.2f s, up min %.2f, distanta minima centre %.1f m"
		% [label, speed, contacts, _shoves, lat_max, v_min, slow_max, up_min, min_gap])
	var out := {"contacts": contacts, "shoves": _shoves,
		"lateral_max": lat_max, "v_min": v_min, "slow_max": slow_max, "up_min": up_min}
	await _free(car)
	return out


## Pozitia masinii fata de banda ei: + = spre interiorul acului (spre centrul
## acului), - = spre exterior (golul). Pe drepte: distanta fata de x-ul benzii;
## pe arc: raza fata de raza benzii.
func _lateral_offset(car: Car, car_r: float) -> float:
	var p := car.global_position - Vector3(HAIRPIN_X, 0.0, 0.0)
	if p.z > 0.0:
		# Pe dreapta de urcare (x < 0): interior = spre x mai mare.
		if p.x < 0.0:
			return p.x + car_r
		return car_r - p.x
	return car_r - Vector2(p.x, p.z).length()


## Cat a parcurs masina pe banda ei (m): dreapta de urcare, apoi arcul.
func _lane_progress(car: Car, car_r: float) -> float:
	var p := car.global_position - Vector3(HAIRPIN_X, 0.0, 0.0)
	if p.z > 0.0 and p.x < 0.0:
		return HAIRPIN_LEG - p.z
	if p.z > 0.0:
		return HAIRPIN_LEG + PI * car_r + p.z
	var a := atan2(-p.z, -p.x) # 0 la (-r, 0), PI la (+r, 0)
	return HAIRPIN_LEG + a * car_r


func _progress_speed(car: Car, _offset: float) -> float:
	var p := car.global_position - Vector3(HAIRPIN_X, 0.0, 0.0)
	var v := car.linear_velocity
	if p.z > 0.0:
		return -v.z if p.x < 0.0 else v.z
	# Pe arc: tangenta in sens orar vazut de sus (de la -x prin -z la +x).
	var radial := Vector2(p.x, p.z).normalized()
	var tangent := Vector3(-radial.y, 0.0, radial.x)
	return v.dot(tangent)
