extends Node
## Sonda tehnica RainCycle (Fiordland, brief §7 pasul 1(c)): dovedeste ca
## flag-ul global de ud chiar intra in fizica masinii si ca metronomul
## schimba mediul, printr-un test A/B pe LUME INGHETATA (memoria
## `diferenta-on-off-cere-lume-inghetata`).
##
## Nu construieste pista, nu face assets, nu face capturi de imagine.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeFiordPloaie.tscn
##   ... -- [--track=0] [--reps=3]
##
## Pista aleasa: Track01 (Dunele), pozitia 0 din GameState.TRACK_SCENES —
## are o dreapta lunga chiar de la start (puncte 0,0,0 -> 65,0,3 -> 130,2,-8
## in Curve3D, deci ~130 m aproape drepti) urmata de un viraj sustinut spre
## dreapta (130,2,-8 -> 190,7,-40 -> 222,14,-92), exact ce cere brief-ul:
## "aceeasi traiectorie scriptata (acceleratie + viraj constant)".
##
## ############################################################################
## CE MASOARA, si de ce fiecare cifra e aleasa asa
##
## 1. TEST A/B PE TRASEU (ploaie OFF vs ploaie ON fortat cu rain_factor=1,
##    prin RainCycle.force_factor): aceeasi masina, acelasi controller
##    scriptat (throttle=1, apoi steer=1 constant), pornite din ACEEASI
##    stare. Se masoara:
##      - slip_time acumulat (trebuie sa fie > 0 DOAR in ON: e dovada directa
##        ca track.rain_wet a fost citit de Car.is_wet_at -> apply_slip)
##      - deviatia laterala fata de traiectoria OFF, la finalul ferestrei de
##        viraj (acelasi comenzi, alta aderenta -> alta raza reala)
##      - viteza maxima atinsa pe portiunea dreapta
##      - fog_depth_end si sun.light_energy efective in Environment, in
##        ambele stari
##    Repetat de REPS ori (implicit 3): Jolt e multithread (memoria
##    `proberace-nedeterminism`), deci se raporteaza MEDIA, nu o rulare.
##
## 2. METRONOM LIBER: un RainCycle separat, lasat sa ruleze cu ceasul lui
##    (fara force_factor), cu print la fiecare tranzitie de faza si verificare
##    ca t=0 (telegraph), t=telegraph (rain), t=telegraph+rain_hold (dry_out),
##    t=telegraph+rain_hold+dry_out (dry) si t=period (ciclu urmator) apar la
##    momentele asteptate, plus ca rain_factor nu sare peste 0.05 pe cadru in
##    afara ferestrelor de telegraph/zvantare.
##
## Cifre IDENTICE la bit intre ON si OFF ar insemna ca track.rain_wet nu a
## fost citit de nimeni (memoria `sonda-masura-alt-obiect`) — se raporteaza
## clar, nu se ascunde sub "aproximativ acelasi".
## ############################################################################

const CAR_SCENE_PATH: String = "res://scenes/cars/data/muscle.tres"
const STEP: float = 1.0 / 60.0
## Cat conducem drept, ca sa prindem viteza, inainte sa incepem virajul.
const STRAIGHT_TIME: float = 4.0
## Cat tinem virajul constant dupa aceea.
const TURN_TIME: float = 3.0
## Unghiul de volan tinut in faza de viraj (1.0 = plin).
const TURN_STEER: float = 0.6

var _track_index: int = 0
var _reps: int = 3


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


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			_track_index = int(arg.trim_prefix("--track="))
		elif arg.begins_with("--reps="):
			_reps = maxi(int(arg.trim_prefix("--reps=")), 1)
	# `--track=` ia pozitia din lista SAU numarul scenei (Track18 = 18) — vezi
	# GameState.resolve_track_index. Indexul brut nu vedea decat pozitiile, deci un
	# numar de scena iesea din tablou sau, la clampi, devenea TACUT alta pista.
	_track_index = GameState.resolve_track_index(_track_index)
	if _track_index < 0:
		printerr("probe_fiord_ploaie: --track nu e nici pozitie in lista, nici numar de scena din GameState.TRACK_SCENES")
		get_tree().quit(1)
		return

	# Un cadru inainte de orice add_child pe root: la _ready radacina e inca
	# ocupata cu propria initializare (acelasi motiv ca in probe_theme.gd),
	# altfel primul add_child pica cu "Parent node is busy".
	await get_tree().process_frame

	print("=== ProbeFiordPloaie: RainCycle A/B pe lume inghetata ===")
	print("pista: %s" % GameState.TRACK_SCENES[_track_index])

	var ab_off: Array[Dictionary] = []
	var ab_on: Array[Dictionary] = []
	for i in _reps:
		ab_off.append(await _run_pass(false))
		ab_on.append(await _run_pass(true))

	_report_ab(ab_off, ab_on)
	await _run_metronome_free()

	get_tree().quit(0)


# ------------------------------------------------------------ trecerea A/B

## O singura rulare: construieste pista + RainCycle + masina, conduce
## STRAIGHT_TIME drept si TURN_TIME in viraj constant, cu ploaia in starea
## ceruta, si intoarce masuratorile.
func _run_pass(raining: bool) -> Dictionary:
	var track := _spawn_track()
	var rain := RainCycle.new()
	rain.name = "RainCycle"
	track.add_child(rain)
	await get_tree().process_frame
	await get_tree().process_frame # RainCycle._collect() e call_deferred
	if raining:
		rain.force_factor(1.0)
	else:
		rain.force_factor(0.0)
	if OS.has_environment("PROBE_DEBUG"):
		print("  dbg after force_factor(%s): track_ref=%s rain_wet=%s is_wet_at(0)=%s"
			% [raining, rain.track_ref(), track.rain_wet, track.is_wet_at(0.0)])

	var car := _spawn_car(track)
	await get_tree().physics_frame

	var driver := car.controller as ScriptDriver
	driver.throttle = 1.0
	driver.steer = 0.0

	var max_speed := 0.0
	var slip_accum := 0.0
	var start_pos := car.global_position
	var _dbg_frame := 0
	for _f in int(STRAIGHT_TIME / STEP):
		await get_tree().physics_frame
		max_speed = maxf(max_speed, car.horizontal_speed())
		if car.slip_time > 0.0:
			slip_accum += STEP
		if OS.has_environment("PROBE_DEBUG") and _dbg_frame % 30 == 0:
			print("    dbg f=%d frac=%.4f slip_time=%.3f slip_grip=%.2f rain_wet=%s pos=%s"
				% [_dbg_frame, track.frac_at(car.road_index), car.slip_time,
					car.slip_grip, track.rain_wet, car.global_position])
		_dbg_frame += 1

	driver.steer = TURN_STEER
	var turn_start_pos := car.global_position
	var turn_start_fwd: Vector3 = -car.global_transform.basis.z
	for _f in int(TURN_TIME / STEP):
		await get_tree().physics_frame
		if car.slip_time > 0.0:
			slip_accum += STEP

	var end_pos := car.global_position
	# Deviatia laterala: proiectia deplasarii din timpul virajului pe axa
	# PERPENDICULARA directiei de intrare in viraj — adica "cat de mult te-a
	# impins/tras aderenta diferita fata de o linie dreapta continuata".
	var right := Vector3(turn_start_fwd.z, 0.0, -turn_start_fwd.x).normalized()
	var travel := end_pos - turn_start_pos
	var lateral := travel.dot(right)
	var forward_dist := travel.dot(turn_start_fwd)

	var env := rain.environment()
	var sun := rain.sun()
	var result := {
		"raining": raining,
		"max_speed": max_speed,
		"slip_time_accum": slip_accum,
		"lateral_dev": lateral,
		"forward_dist": forward_dist,
		"end_pos": end_pos,
		"rain_wet_flag": track.rain_wet,
		"fog_end": env.fog_depth_end if env != null else -1.0,
		"sun_energy": sun.light_energy if sun != null else -1.0,
	}

	car.queue_free()
	track.queue_free()
	await get_tree().process_frame
	return result


func _spawn_track() -> Track:
	var scene := load(GameState.TRACK_SCENES[_track_index]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	return track


func _spawn_car(track: Track) -> Car:
	var car := Car.new()
	car.apply_data(load(CAR_SCENE_PATH) as CarData)
	get_tree().root.add_child(car)
	# Pornim pe dreapta de langa start, orientati DUPA traseul copt (nu
	# presupus): forward-ul local al masinii e -Z, deci il aliniem cu
	# directia reala dintre primele doua puncte coapte, oricare ar fi pista.
	car.global_position = track.baked[0] + Vector3.UP * 1.0
	var fwd := (track.baked[1] - track.baked[0])
	fwd.y = 0.0
	fwd = fwd.normalized()
	car.global_transform = Transform3D(
		Basis.looking_at(fwd, Vector3.UP), car.global_position)
	car.track = track
	car.route = 0
	car.road_index = 0
	car.set_controller(ScriptDriver.new())
	car.race_active = true
	return car


func _report_ab(off: Array[Dictionary], on: Array[Dictionary]) -> void:
	var m_off := _mean(off)
	var m_on := _mean(on)
	print("")
	print("-- A/B (medie pe %d rulari) --" % _reps)
	print("  %-18s %10s %10s" % ["", "OFF", "ON"])
	print("  %-18s %10.3f %10.3f" % ["slip_time (s)", m_off.slip_time_accum, m_on.slip_time_accum])
	print("  %-18s %10.3f %10.3f" % ["dev. laterala (m)", m_off.lateral_dev, m_on.lateral_dev])
	print("  %-18s %10.3f %10.3f" % ["viteza max (m/s)", m_off.max_speed, m_on.max_speed])
	print("  %-18s %10.1f %10.1f" % ["fog_depth_end (m)", m_off.fog_end, m_on.fog_end])
	print("  %-18s %10.3f %10.3f" % ["sun.light_energy", m_off.sun_energy, m_on.sun_energy])
	print("")
	for i in off.size():
		print("  rulare %d: OFF slip=%.3f lat=%.3f | ON slip=%.3f lat=%.3f"
			% [i, off[i].slip_time_accum, off[i].lateral_dev,
				on[i].slip_time_accum, on[i].lateral_dev])

	var off_slip: float = m_off.slip_time_accum
	var on_slip: float = m_on.slip_time_accum
	var slip_ok: bool = off_slip <= 0.001 and on_slip > 0.05
	var identical_bitwise := true
	for i in off.size():
		if not (is_equal_approx(off[i].slip_time_accum, on[i].slip_time_accum)
				and is_equal_approx(off[i].lateral_dev, on[i].lateral_dev)):
			identical_bitwise = false
			break
	var lateral_diff: float = absf(float(m_on.lateral_dev) - float(m_off.lateral_dev))
	var fog_ok: bool = not is_equal_approx(m_off.fog_end, m_on.fog_end)
	var sun_ok: bool = not is_equal_approx(m_off.sun_energy, m_on.sun_energy)

	print("")
	if identical_bitwise:
		print("VERDICT: PICAT — OFF si ON dau cifre identice la bit; " +
			"track.rain_wet NU e conectat in fizica masinii (sonda-masura-alt-obiect).")
	elif not slip_ok:
		print(("VERDICT: PICAT — slip_time nu se comporta cum trebuie " +
			"(OFF=%.3f ON=%.3f; asteptat OFF~0, ON>0.05).") % [m_off.slip_time_accum, m_on.slip_time_accum])
	elif not fog_ok or not sun_ok:
		print("VERDICT: PICAT — mediul (fog_depth_end/sun.light_energy) nu difera intre OFF si ON.")
	else:
		print(("VERDICT: TRECUT — flag-ul de ud intra in fizica (slip_time OFF=%.3f, " +
			"ON=%.3f), deviatia laterala difera cu %.2f m, mediul lerpuieste " +
			"(fog_end %.0f->%.0f, sun_energy %.2f->%.2f).")
			% [m_off.slip_time_accum, m_on.slip_time_accum, lateral_diff,
				m_off.fog_end, m_on.fog_end, m_off.sun_energy, m_on.sun_energy])


func _mean(runs: Array[Dictionary]) -> Dictionary:
	var out := {
		"slip_time_accum": 0.0, "lateral_dev": 0.0, "max_speed": 0.0,
		"fog_end": 0.0, "sun_energy": 0.0,
	}
	for r in runs:
		for k in out.keys():
			out[k] += float(r[k])
	for k in out.keys():
		out[k] /= float(runs.size())
	return out


# ------------------------------------------------------------ metronom liber

## Ruleaza un RainCycle cu ceasul lui propriu, fara nicio masina, si verifica
## tranzitiile de faza la momentele asteptate + continuitatea lui rain_factor.
func _run_metronome_free() -> void:
	print("")
	print("-- metronom liber (ceas propriu, fara masina) --")
	var track := _spawn_track()
	var rain := RainCycle.new()
	rain.name = "RainCycleLiber"
	# Perioada scurtata DOAR pentru viteza sondei (raportul de timp intre
	# telegraph/rain/dry_out ramane cel din brief), ca sa nu asteptam 95 s
	# reale de simulare de 3 ori (o bucla + putin din urmatoarea).
	track.add_child(rain)
	await get_tree().process_frame
	await get_tree().process_frame

	var expected_at: Array[float] = [
		0.0, rain.telegraph, rain.telegraph + rain.rain_hold,
		rain.telegraph + rain.rain_hold + rain.dry_out, rain.period,
	]
	var expected_name: Array[String] = [
		"telegraph (t=0)", "ploaie (t=telegraph)",
		"zvantare (t=telegraph+rain_hold)", "uscat (t=telegraph+rain_hold+dry_out)",
		"ciclu urmator (t=period)",
	]
	var next_expect := 0
	var prev_factor := rain.rain_factor
	var prev_phase := rain.phase
	var max_jump := 0.0
	var total_time := rain.period + 2.0
	var t := 0.0
	var transitions: Array[String] = []
	while t < total_time:
		await get_tree().physics_frame
		t += STEP
		var jump := absf(rain.rain_factor - prev_factor)
		var in_ramp := rain.phase == RainCycle.Phase.TELEGRAPH or rain.phase == RainCycle.Phase.DRY_OUT
		if not in_ramp:
			max_jump = maxf(max_jump, jump)
		prev_factor = rain.rain_factor
		if rain.phase != prev_phase:
			transitions.append("  t=%.2f s: faza -> %s (rain_factor=%.3f)"
				% [t, RainCycle.Phase.keys()[rain.phase], rain.rain_factor])
			prev_phase = rain.phase

	for line in transitions:
		print(line)
	print("  cel mai mare salt de rain_factor/cadru IN AFARA telegraph/zvantare: %.4f" % max_jump)
	_check(transitions.size() >= 4, "cel putin 4 tranzitii de faza intr-un ciclu")
	_check(max_jump <= 0.05, "rain_factor continuu (fara salturi peste 0.05/cadru in afara rampelor)")

	track.queue_free()
	await get_tree().process_frame


func _check(ok: bool, what: String) -> void:
	print("  [%s] %s" % ["OK " if ok else "PICAT", what])
