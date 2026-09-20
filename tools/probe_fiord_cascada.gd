extends Node
## Sonda tehnica pentru CASCADA PESTE DRUM (Fiordland, brief §7 pasul 1(a) /
## §3 „Cascada peste drum" / §6 „de verificat devreme" (1)).
##
## Nu construieste pista: un drum SINTETIC, drept si plat, cu o singura
## perdea `WaterfallHazard` la mijloc. Lanseaza pe rand toate presetarile din
## `GameState.CAR_DATA` la 15 si 25 m/s, cu `rain_factor` 1.0/1.3 si
## `force_accel` 9/12/15, de 3 ori fiecare (Jolt e multithread — memoria
## `proberace-nedeterminism`: se compara MEDIA, nu o rulare unica).
##
## Pentru fiecare rulare masoara:
##   - compresia MAXIMA a suspensiei in zona, ca fractie din cursa proprie
##     (`wheel_compression[i] / suspension_rest`, per roata si maximul lor —
##     acelasi calcul ca in `probe_car_identity.gd`);
##   - bottom-out: da/nu (compresie >= 97% din cursa) si cate cadre;
##   - viteza la intrare/iesire din zona (orizontala) si procentul pierdut;
##   - saltul de la iesire: inaltimea maxima a CENTRULUI masinii peste linia
##     de rulare, dupa ce iese din zona (fereastra de 1.5 s dupa iesire);
##   - rasturnare: da/nu (`up.dot(UP) < 0.5`, ca in `probe_car_identity.gd` /
##     `probe_machu_teren.gd`), si ruliul maxim;
##   - timpul petrecut in zona (s).
##
## Verifica INTAI ca forta chiar intra (memoria `sonda-masura-alt-obiect`):
## o rulare cu `force_accel = 0` trebuie sa dea compresie diferita de una cu
## `force_accel = 12`, cu ACEEASI masina si aceeasi viteza.
##
## Ruleaza CA SCENA (autoload-urile GameState/AudioManager trebuie rezolvate):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeFiordCascada.tscn
##
## Argumente optionale:
##   --cars=0,5        indici din GameState.CAR_DATA (implicit: toate)
##   --speeds=15,25     m/s
##   --rain=1.0,1.3
##   --accels=9,12,15
##   --repeats=3
##   --quick            un singur set (masina 0, 25 m/s, rain 1.0, accel 12,
##                       1 repetare) — pentru iterare rapida

const STEP: float = 1.0 / 60.0
## Lungimea perdelei (m) — vezi WaterfallHazard.length, brief: 30.
const CURTAIN_LENGTH: float = 30.0
## Latimea perdelei pe uscat (m) — brief: 6 (varianta "prin").
const CURTAIN_THICKNESS: float = 6.0
## Cat drum inainte de perdea, ca masina sa fi ajuns deja la viteza cetuta
## (pusa direct in `velocity`, dar dupa cateva cadre de fizica frana/motorul
## ar incepe sa o schimbe fara run-up scurt) — vezi nota din probe_jump.gd.
const RUN_UP: float = 12.0
## Cat drum dupa perdea urmarim saltul de iesire.
const RUN_DOWN: float = 40.0
## Fereastra de urmarire dupa iesirea din zona, pentru saltul de iesire (s).
const LANDING_WINDOW: float = 1.5
## Cat timp maxim urmarim o rulare inainte sa renuntam (siguranta).
const WATCH_MAX: float = 6.0
## Compresie >= acest procent din cursa = bottom-out (arcul la fund).
const BOTTOMOUT_FRAC: float = 0.97

var _car_indices: Array[int] = []
var _speeds: Array[float] = [15.0, 25.0]
var _rain_factors: Array[float] = [1.0, 1.3]
var _accels: Array[float] = [9.0, 12.0, 15.0]
var _repeats: int = 3
var _quick: bool = false
var _dbg: bool = false
## Override pentru `WaterfallHazard.drag`, ca sa se poata cauta valoarea buna
## din linia de comanda in loc sa se modifice default-ul de fiecare data.
## -1 = foloseste default-ul din WaterfallHazard.
var _drag_override: float = -1.0

var _ground: StaticBody3D
var _results: Array[Dictionary] = []
var _failed_hint: bool = false


class ScriptDriver:
	extends CarController
	var steer: float = 0.0
	var throttle: float = 0.0
	func get_steer() -> float:
		return steer
	func get_throttle() -> float:
		return throttle
	func is_drift_pressed() -> bool:
		return false
	func is_turbo_pressed() -> bool:
		return false


func _ready() -> void:
	_parse_args()
	_build_ground()
	await get_tree().physics_frame
	await get_tree().physics_frame

	print("")
	print("=== WaterfallHazard — sonda tehnica (Fiordland, brief §7.1a) ===")
	print("perdea: lungime %.0f m, latime uscat %.0f m, run-up %.0f m"
		% [CURTAIN_LENGTH, CURTAIN_THICKNESS, RUN_UP])
	print("masini testate: %s" % str(_car_indices.map(
		func(i: int) -> String: return GameState.CAR_DATA[i].display_name)))
	print("viteze: %s | rain_factor: %s | force_accel: %s | repetari: %d"
		% [str(_speeds), str(_rain_factors), str(_accels), _repeats])

	await _test_force_connected()
	await _test_matrix()
	_report_table()
	_report_verdict()

	get_tree().quit(1 if _failed_hint else 0)


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--cars="):
			_car_indices.clear()
			for s in arg.trim_prefix("--cars=").split(","):
				_car_indices.append(int(s))
		elif arg.begins_with("--speeds="):
			_speeds.clear()
			for s in arg.trim_prefix("--speeds=").split(","):
				_speeds.append(float(s))
		elif arg.begins_with("--rain="):
			_rain_factors.clear()
			for s in arg.trim_prefix("--rain=").split(","):
				_rain_factors.append(float(s))
		elif arg.begins_with("--accels="):
			_accels.clear()
			for s in arg.trim_prefix("--accels=").split(","):
				_accels.append(float(s))
		elif arg.begins_with("--repeats="):
			_repeats = int(arg.trim_prefix("--repeats="))
		elif arg.begins_with("--drag="):
			_drag_override = float(arg.trim_prefix("--drag="))
		elif arg == "--quick":
			_quick = true
		elif arg == "--dbg":
			_dbg = true
	if _car_indices.is_empty():
		for i in GameState.CAR_DATA.size():
			_car_indices.append(i)
	if _quick:
		_car_indices = [0]
		_speeds = [25.0]
		_rain_factors = [1.0]
		_accels = [12.0]
		_repeats = 1


func _build_ground() -> void:
	_ground = StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40.0, 1.0, RUN_UP + CURTAIN_LENGTH + RUN_DOWN + 40.0)
	shape.shape = box
	_ground.add_child(shape)
	add_child(_ground)
	# Centram drumul pe Z astfel incat perdeaua sa fie chiar la z=0.
	_ground.global_position = Vector3(0, -0.5, 0)


## Perdeaua sta chiar la z=0, orientata sa "priveasca" spre -Z (identic cu
## sensul de mers al masinii, care porneste din +Z spre -Z).
func _build_curtain(force_accel: float, rain_factor: float) -> WaterfallHazard:
	var wf := WaterfallHazard.new()
	wf.length = CURTAIN_LENGTH
	wf.thickness = CURTAIN_THICKNESS
	wf.force_accel = force_accel
	wf.rain_factor = rain_factor
	if _drag_override >= 0.0:
		wf.drag = _drag_override
	add_child(wf)
	wf.global_position = Vector3(0, 0.0, 0)
	return wf


## Masina se conduce CU ACCELERATIA APASATA (throttle=1.0), nu in ruliu liber.
##
## Descoperit pe sonda: la throttle=0, drag-ul intrinsec al lui `Car`
## (`car.gd`, `drag = 0.35`, aplicat continuu ca forta proportionala cu
## viteza) taie singur o masina de la 25 la sub 2 m/s in ~6 s, FARA nicio
## cascada — verificat cu un harnas separat, fara hazard, doar Car + sol
## plat. E asteptat: jocul e gandit pentru control tip Ignition (auto-
## accelerate pe touch, brief CLAUDE.md), nu pentru coasting. "Pierderea de
## 20-25% pe 30 m fara turbo" din brief inseamna fata de un sofer care
## TINE gazul, nu fata de o masina lasata libera — altfel orice cifra despre
## cascada s-ar fi ingropat in propriul coasting al masinii.
func _spawn_car(preset: int, speed: float) -> Car:
	var car := (load("res://scenes/cars/Car.tscn") as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(GameState.CAR_DATA[preset] as CarData)
	var driver := ScriptDriver.new()
	driver.throttle = 1.0
	car.set_controller(driver)
	car.race_active = true
	car.is_player = true # FogCorridorHazard (albirea) reactioneaza doar la is_player
	var start_z := RUN_UP + CURTAIN_LENGTH * 0.5
	car.global_transform = Transform3D(Basis.IDENTITY, Vector3(0, 0.7, start_z))
	car.velocity = Vector3(0, 0, -speed)
	car.last_safe_index = 0
	return car


# --------------------------------------------------------- testul de conexiune

## Verifica INTAI ca forta chiar e conectata: force_accel=0 trebuie sa dea o
## compresie diferita de force_accel=12, la ACEEASI masina si viteza — altfel
## orice tabel de mai jos ar putea masura un mecanism neconectat (memoria
## `sonda-masura-alt-obiect`).
func _test_force_connected() -> void:
	print("")
	print("-- test de conexiune: force_accel=0 vs 12 (Muscle, 25 m/s) --")
	var r0 := await _run_once(0, 25.0, 1.0, 0.0)
	var r12 := await _run_once(0, 25.0, 1.0, 12.0)
	print("  force_accel=0 : compresie max %.1f%%, pierdere viteza %.1f%%"
		% [float(r0.comp_max) * 100.0, float(r0.speed_loss_pct)])
	print("  force_accel=12: compresie max %.1f%%, pierdere viteza %.1f%%"
		% [float(r12.comp_max) * 100.0, float(r12.speed_loss_pct)])
	var delta := absf(float(r12.comp_max) - float(r0.comp_max))
	if delta < 0.01:
		print("  [PICAT] compresia e IDENTICA (delta %.4f) — forta NU pare conectata"
			% delta)
		_failed_hint = true
	else:
		print("  [OK] compresia difera (delta %.1f puncte procentuale) — forta e conectata"
			% (delta * 100.0))


# --------------------------------------------------------------- matricea

func _test_matrix() -> void:
	print("")
	print("-- matricea completa (medie pe %d repetari) --" % _repeats)
	for car_idx in _car_indices:
		for speed in _speeds:
			for rain in _rain_factors:
				for accel in _accels:
					var runs: Array[Dictionary] = []
					for _rep in _repeats:
						runs.append(await _run_once(car_idx, speed, rain, accel))
					_results.append(_average(car_idx, speed, rain, accel, runs))


func _average(car_idx: int, speed: float, rain: float, accel: float,
		runs: Array[Dictionary]) -> Dictionary:
	var n := float(runs.size())
	var comp_max := 0.0
	var bottom_frames := 0.0
	var bottom_any := 0
	var loss_pct := 0.0
	var exit_jump := 0.0
	var flipped_any := 0
	var roll_max := 0.0
	var zone_time := 0.0
	for r in runs:
		comp_max += float(r.comp_max)
		bottom_frames += float(r.bottom_frames)
		if bool(r.bottom_out):
			bottom_any += 1
		loss_pct += float(r.speed_loss_pct)
		exit_jump += float(r.exit_jump)
		if bool(r.flipped):
			flipped_any += 1
		roll_max = maxf(roll_max, float(r.roll_max))
		zone_time += float(r.zone_time)
	return {
		"car": car_idx,
		"name": String(GameState.CAR_DATA[car_idx].display_name),
		"speed": speed,
		"rain": rain,
		"accel": accel,
		"comp_max": comp_max / n,
		"bottom_out": bottom_any > 0,
		"bottom_frames": bottom_frames / n,
		"speed_loss_pct": loss_pct / n,
		"exit_jump": exit_jump / n,
		"flipped": flipped_any > 0,
		"roll_max": roll_max,
		"zone_time": zone_time / n,
	}


## O singura rulare: lanseaza masina, o urmareste prin zona si RUN_DOWN dupa,
## si intoarce cifrele brute.
func _run_once(preset: int, speed: float, rain: float, accel: float) -> Dictionary:
	var wf := _build_curtain(accel, rain)
	var car := _spawn_car(preset, speed)
	# O balansare scurta pe loc, la viteza deja impusa, ca sa nu numaram
	# transientul de start ca parte din compresia din zona.
	for _f in int(0.2 / STEP):
		await get_tree().physics_frame

	var comp_max := 0.0
	var bottom_frames := 0
	var flipped := false
	var roll_max := 0.0
	var entry_speed := -1.0
	var exit_speed := -1.0
	var in_zone := false
	var was_in_zone := false
	var zone_frames := 0
	var exit_time := -1.0
	var y_line := car.global_position.y
	var exit_jump := 0.0
	var t := 0.0

	while t < WATCH_MAX:
		await get_tree().physics_frame
		t += STEP
		var pos := car.global_position
		var hspeed := car.horizontal_speed()
		var z := pos.z
		in_zone = z > -CURTAIN_LENGTH * 0.5 and z < CURTAIN_LENGTH * 0.5
		if in_zone:
			zone_frames += 1
			if entry_speed < 0.0:
				entry_speed = hspeed
			for c in car.wheel_compression:
				var frac: float = float(c) / maxf(car.suspension_rest, 0.001)
				comp_max = maxf(comp_max, frac)
				if frac >= BOTTOMOUT_FRAC:
					bottom_frames += 1
			var up := car.global_transform.basis.y
			var tilt := rad_to_deg(acos(clampf(up.dot(Vector3.UP), -1.0, 1.0)))
			roll_max = maxf(roll_max, tilt)
			if up.dot(Vector3.UP) < 0.5:
				flipped = true
		if was_in_zone and not in_zone and exit_speed < 0.0:
			exit_speed = hspeed
			exit_time = t
		# Dupa iesire: continua sa citim ruliu/flip (poate rasturna dupa,
		# de la saltul arcurilor destinse) si saltul vertical peste linia
		# de rulare, pe o fereastra scurta.
		if exit_time >= 0.0 and t - exit_time <= LANDING_WINDOW:
			var up2 := car.global_transform.basis.y
			var tilt2 := rad_to_deg(acos(clampf(up2.dot(Vector3.UP), -1.0, 1.0)))
			roll_max = maxf(roll_max, tilt2)
			if up2.dot(Vector3.UP) < 0.5:
				flipped = true
			exit_jump = maxf(exit_jump, pos.y - y_line)
		was_in_zone = in_zone
		if _dbg and int(t / STEP) % 15 == 0:
			print("      [trace] t=%.2f z=%.1f hspeed=%.2f in_zone=%s on_floor=%s"
				% [t, z, hspeed, str(in_zone), str(car.is_on_floor())])
		if exit_time >= 0.0 and t - exit_time > LANDING_WINDOW:
			break
		if z < -(CURTAIN_LENGTH * 0.5 + RUN_DOWN):
			break

	if entry_speed < 0.0:
		entry_speed = speed # n-a apucat sa intre (nu ar trebui sa se intample)
	if exit_speed < 0.0:
		exit_speed = car.horizontal_speed()
	var loss_pct := 0.0
	if entry_speed > 0.01:
		loss_pct = clampf((entry_speed - exit_speed) / entry_speed, -5.0, 5.0) * 100.0
	var zone_time := float(zone_frames) * STEP

	if _dbg:
		print("    [dbg] %s v=%.0f rain=%.1f accel=%.0f -> comp=%.2f loss=%.1f%% jump=%.2f flip=%s"
			% [GameState.CAR_DATA[preset].display_name, speed, rain, accel,
				comp_max, loss_pct, exit_jump, str(flipped)])

	car.queue_free()
	wf.queue_free()
	await get_tree().physics_frame

	return {
		"comp_max": comp_max,
		"bottom_out": bottom_frames > 0,
		"bottom_frames": bottom_frames,
		"entry_speed": entry_speed,
		"exit_speed": exit_speed,
		"speed_loss_pct": loss_pct,
		"exit_jump": exit_jump,
		"flipped": flipped,
		"roll_max": roll_max,
		"zone_time": zone_time,
	}


# --------------------------------------------------------------- raportare

func _report_table() -> void:
	print("")
	print("=== TABEL (medie pe %d repetari) ===" % _repeats)
	print("%-12s %5s %5s %6s | %6s %5s %8s | %7s %6s %6s"
		% ["masina", "v", "rain", "accel", "comp%", "fund", "cadre_f",
			"pierd%", "salt_m", "ruliu"])
	for r in _results:
		if bool(r.flipped):
			_failed_hint = true
		print("%-12s %5.0f %5.1f %6.0f | %6.1f %5s %8.1f | %7.1f %6.2f %6.1f%s"
			% [String(r.name), float(r.speed), float(r.rain), float(r.accel),
				float(r.comp_max) * 100.0, "DA" if bool(r.bottom_out) else "nu",
				float(r.bottom_frames), float(r.speed_loss_pct),
				float(r.exit_jump), float(r.roll_max),
				" <-- RASTURNAT" if bool(r.flipped) else ""])


func _report_verdict() -> void:
	print("")
	print("=== VERDICT ===")

	# 1. nicio rasturnare la nicio combinatie
	var any_flip := false
	for r in _results:
		if bool(r.flipped):
			any_flip = true
	print("- rasturnari: %s" % ("DA (esec)" if any_flip else "niciuna"))
	if any_flip:
		_failed_hint = true

	# 2. diferente masurabile intre masini (aceeasi viteza/rain/accel)
	var by_key := {}
	for r in _results:
		var key := "%.0f|%.1f|%.0f" % [float(r.speed), float(r.rain), float(r.accel)]
		if not by_key.has(key):
			by_key[key] = []
		(by_key[key] as Array).append(r)
	var max_spread := 0.0
	var spread_key := ""
	for key in by_key.keys():
		var group: Array = by_key[key]
		if group.size() < 2:
			continue
		var vals: Array[float] = []
		for r: Dictionary in group:
			vals.append(float(r.comp_max))
		var lo: float = vals.min()
		var hi: float = vals.max()
		if hi - lo > max_spread:
			max_spread = hi - lo
			spread_key = key
	print("- spread maxim de compresie INTRE masini (aceeasi v/rain/accel): %.1f puncte procentuale (la %s)"
		% [max_spread * 100.0, spread_key])
	if max_spread < 0.01:
		print("  ATENTIE: spread aproape zero — verifica daca suspensia per masina chiar e citita")
		_failed_hint = true

	# 3. pierdere de viteza 20-25% la 25 m/s pe uscat fara turbo
	for r in _results:
		if absf(float(r.speed) - 25.0) < 0.1 and absf(float(r.rain) - 1.0) < 0.01:
			var ok := float(r.speed_loss_pct) >= 15.0 and float(r.speed_loss_pct) <= 30.0
			print("- %s @ 25 m/s uscat accel=%.0f: pierdere %.1f%% (tinta 20-25%%) %s"
				% [String(r.name), float(r.accel), float(r.speed_loss_pct),
					"OK" if ok else "<-- in afara tintei"])

	# 4. saltul de iesire sub 0.4 m
	var jump_over := 0
	for r in _results:
		if float(r.exit_jump) >= 0.4:
			jump_over += 1
	print("- combinatii cu salt de iesire >= 0.4 m: %d din %d" % [jump_over, _results.size()])
	if jump_over > 0:
		_failed_hint = true

	# 5. bottom-out diferentiat: Buggy da, Politia nu (identitatea suspensiei)
	var buggy_idx := -1
	var police_idx := -1
	for i in GameState.CAR_DATA.size():
		var nm := String(GameState.CAR_DATA[i].display_name)
		if nm == "Buggy":
			buggy_idx = i
		elif nm == "Politia":
			police_idx = i
	if buggy_idx >= 0 and police_idx >= 0:
		var buggy_bottom := false
		var police_bottom := false
		for r in _results:
			if int(r.car) == buggy_idx and bool(r.bottom_out):
				buggy_bottom = true
			if int(r.car) == police_idx and bool(r.bottom_out):
				police_bottom = true
		print("- Buggy atinge fundul: %s | Politia atinge fundul: %s (asteptat: Buggy da, Politia nu)"
			% ["da" if buggy_bottom else "nu", "da" if police_bottom else "nu"])

	print("")
	print("REZULTAT: ", "PICAT" if _failed_hint else "TRECUT")
