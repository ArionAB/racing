extends Node
## Hazardele mobile vorbesc (docs/feel_checklist.md: hazards-speak, partea de
## sunet): bariera glisanta (SlidingHazard) si autobuzul (BusHazard) scot un sunet
## de contact cand te ghiontesc, pozitional, la masina lovita.
##
## Pe corpurile REALE ale hazardelor (ca ProbeHazardKick): jucatorul sta pe traseul
## pendulului / in calea autobuzului. Sonda citeste jurnalul `sfx_log` si playerul 3D
## real din pool.
##
## Verifica:
##   1. bariera: cel putin un `hazard_barrier_hit`, pozitional, la masina (sub 3 m
##      de ea in cadrul sunetului), la `hazard_db` pentru jucator; nu mai des decat
##      pauza lui (0,35 s per masina);
##   2. aceeasi bariera peste o masina AI: aceeasi mecanica, dar cu `hazard_ai_offset_db`
##      mai incet;
##   3. `contact_sfx = &""` tace hazardul (nicio intrare hazard_*), fizica ramane;
##   4. autobuzul din spate: cel putin un `hazard_bus_hit`, pozitional, la masina;
##   5. pauza globala `hazard_interval_s`: doua contacte la mai putin de 0,12 s da
##      un singur sunet, iar in afara razei de 60 m nu suna.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeHazardSound.tscn

const ImpactSoundScript := preload("res://scenes/race/impact_sound.gd")
const STEP: float = 1.0 / 60.0

var _failed: bool = false
var _cam: Camera3D
var _db_player: float = 0.0


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _ground() -> StaticBody3D:
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(1200, 1, 1200)
	cs.shape = sh
	b.add_child(cs)
	b.position = Vector3(0, -0.5, 0)
	return b


func _entries(sfx: StringName) -> Array:
	return AudioManager.sfx_log.filter(func(e: Dictionary) -> bool: return e["name"] == sfx)


func _ready() -> void:
	print("")
	print("=== Hazarde mobile: sunet de contact ===")
	# Ceas simulat: pauzele se masoara in timpul jocului, nu in cel real.
	AudioManager.clock = func() -> float: return 20000.0 + float(Engine.get_physics_frames()) * STEP
	add_child(_ground())
	_cam = Camera3D.new()
	add_child(_cam)
	_cam.current = true
	await get_tree().physics_frame
	await _test_barrier(true, &"hazard_barrier_hit", "jucator")
	await _test_barrier(false, &"hazard_barrier_hit", "AI")
	await _test_barrier(true, &"", "contact_sfx gol")
	await _test_bus()
	_test_rate_and_range()
	AudioManager.clock = func() -> float: return Time.get_ticks_msec() * 0.001
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


## Pendulul peste o masina stationara (ca ProbeHazardKick). Intoarce jurnalul.
func _barrier_run(is_player: bool, sfx: StringName) -> Dictionary:
	var holder := Node3D.new()
	add_child(holder)
	var hz := SlidingHazard.new()
	hz.road_half_width = 14.0
	hz.max_sweep_speed = 12.0
	hz.contact_sfx = sfx
	holder.add_child(hz)
	hz.center = Vector3.ZERO
	hz.travel = Vector3.RIGHT * 8.0
	hz.global_position = Vector3.ZERO
	var car := Car.new()
	holder.add_child(car)
	car.global_position = Vector3(6.5, 0.7, 0)
	car.race_active = true
	car.is_player = is_player
	_cam.global_position = Vector3(6.5, 10, 13)
	var watcher: Car = car if is_player else Car.new()
	watcher.is_player = true
	var snd := ImpactSoundScript.new()
	holder.add_child(snd)
	snd.setup(watcher, [car])
	var car_at: Dictionary = {}
	AudioManager.sfx_log.clear()
	var moved := 0.0
	for _t in 60 * 6:
		await get_tree().physics_frame
		car_at[Engine.get_physics_frames()] = car.global_position
		moved = maxf(moved, absf(car.global_position.x - 6.5))
	var hits := _entries(&"hazard_barrier_hit")
	var out := {"hits": hits, "car_at": car_at, "moved": moved, "log": AudioManager.sfx_log.duplicate()}
	snd.queue_free()
	if watcher != car:
		watcher.free()
	holder.queue_free()
	await get_tree().physics_frame
	return out


func _test_barrier(is_player: bool, sfx: StringName, label: String) -> void:
	print("")
	print("-- bariera glisanta, %s --" % label)
	var r := await _barrier_run(is_player, sfx)
	var hits: Array = r["hits"]
	print("  masina impinsa %.1f m, hazard_barrier_hit x%d" % [float(r["moved"]), hits.size()])
	_check(float(r["moved"]) > 2.0, "(control) bariera a impins masina")
	if sfx == &"":
		var any_hz := (r["log"] as Array).any(func(e: Dictionary) -> bool:
			return String(e["name"]).begins_with("hazard_"))
		_check(not any_hz, "contact_sfx gol: nicio intrare hazard_*")
		return
	_check(not hits.is_empty(), "ghiontul scoate hazard_barrier_hit")
	if hits.is_empty():
		return
	_check(hits.all(func(e: Dictionary) -> bool: return e["positional"]), "pozitional")
	var near := true
	for e in hits:
		var cp: Variant = (r["car_at"] as Dictionary).get(int(e["frame"]))
		if cp == null or (e["pos"] as Vector3).distance_to(cp as Vector3) > 3.0:
			near = false
	_check(near, "sursa 3D sta la masina (sub 3 m in cadrul sunetului)")
	var db0 := float((hits[0] as Dictionary)["db"])
	if is_player:
		_db_player = db0
		_check(db0 > -12.0 and db0 < 0.0, "volum audibil pentru jucator (%.1f dB)" % db0)
	else:
		_check(db0 <= _db_player - 6.0, "masina AI cu cel putin 6 dB mai incet (%.1f vs %.1f dB)"
			% [db0, _db_player])
	var frames: Array = hits.map(func(e: Dictionary) -> int: return int(e["frame"]))
	var min_gap := 1 << 30
	for i in range(1, frames.size()):
		min_gap = mini(min_gap, int(frames[i]) - int(frames[i - 1]))
	_check(frames.size() < 2 or float(min_gap) * STEP >= 0.3,
		"pauza intre sunete >= 0,3 s (%.2f s)" % (float(min_gap) * STEP if frames.size() >= 2 else 9.9))
	if is_player:
		var found := false
		for p in AudioManager.pool3d():
			if p.stream == AudioManager.stream(&"hazard_barrier_hit"):
				found = true
		_check(found, "un player 3D real poarta hazard_barrier_hit")


func _test_bus() -> void:
	print("")
	print("-- autobuzul din spate --")
	var holder := Node3D.new()
	add_child(holder)
	var bus := BusHazard.new()
	bus.points = PackedVector3Array([Vector3(200, 0, 140), Vector3(200, 0, -140)])
	bus.speed = 14.0
	bus.stick_to_ground = false
	bus.apex_outer_m = 0.0
	holder.add_child(bus)
	var car := Car.new()
	holder.add_child(car)
	car.global_position = Vector3(200, 0.7, 0)
	car.race_active = true
	car.is_player = true
	_cam.global_position = Vector3(200, 10, 13)
	var snd := ImpactSoundScript.new()
	holder.add_child(snd)
	snd.setup(car, [car])
	var car_at: Dictionary = {}
	AudioManager.sfx_log.clear()
	for _t in 60 * 25:
		await get_tree().physics_frame
		car_at[Engine.get_physics_frames()] = car.global_position
	var hits := _entries(&"hazard_bus_hit")
	print("  hazard_bus_hit x%d" % hits.size())
	_check(not hits.is_empty(), "autobuzul scoate hazard_bus_hit")
	if not hits.is_empty():
		_check(hits.all(func(e: Dictionary) -> bool: return e["positional"]), "pozitional")
		var near := true
		for e in hits:
			var cp: Variant = car_at.get(int(e["frame"]))
			if cp == null or (e["pos"] as Vector3).distance_to(cp as Vector3) > 3.0:
				near = false
		_check(near, "sursa 3D sta la masina")
	holder.queue_free()
	await get_tree().physics_frame


func _test_rate_and_range() -> void:
	print("")
	print("-- pauza globala si raza --")
	var t := [90000.0]
	AudioManager.clock = func() -> float: return t[0]
	_cam.global_position = Vector3(0, 10, 13)
	AudioManager.sfx_log.clear()
	var a := AudioManager.hazard_contact(&"hazard_barrier_hit", Vector3(0, 0, 0), true)
	t[0] += 0.05
	var b := AudioManager.hazard_contact(&"hazard_bus_hit", Vector3(0, 0, 0), true)
	t[0] += 0.1
	var c := AudioManager.hazard_contact(&"hazard_bus_hit", Vector3(0, 0, 0), true)
	_check(a and not b and c, "doua contacte la 0,05 s: unul singur; la 0,15 s: iar suna (%s %s %s)"
		% [str(a), str(b), str(c)])
	t[0] += 1.0
	var far := AudioManager.hazard_contact(&"hazard_bus_hit", Vector3(0, 0, -200), true)
	_check(not far, "la 215 m de camera: nu suna")
	var unknown := AudioManager.hazard_contact(&"nu_exista", Vector3.ZERO, true)
	_check(not unknown, "un nume necunoscut nu suna")
	AudioManager.clock = func() -> float: return Time.get_ticks_msec() * 0.001
