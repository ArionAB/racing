extends Node
## Vocile suprafetelor (docs/feel_checklist.md, `surface-voice`, partea de sunet):
## rularea pe iarba / pietris-nisip / apa mica, cross-fade dupa suprafata, volum
## dupa viteza, si zdranganeala de bordura. Citeste playerele `roll` si `kerb`
## ale lui CarAudio.
##
## Contractele:
##   1. Asfalt (nicio suprafata speciala): nicio bucla de rulare nu canta, nici la 25 m/s.
##   2. Fiecare suprafata (cusatura `override_surface`) la 20 m/s: canta stream-ul
##      ei (`roll_grass` / `roll_gravel` / `roll_water`) si NUMAI al ei; pe loc (0 m/s)
##      tace; volumul la 25 m/s e cu >= 6 dB peste cel de la 5 m/s.
##   3. Cross-fade iarba -> pietris: la ~0.08 s dupa schimbare canta amandoua (cea
##      veche se stinge, cea noua urca); dupa 0.6 s a ramas doar pietrisul.
##   4. Bordura: `override_kerb = 1` la 20 m/s porneste `kerb_rattle`, mai tare si
##      cu pitch mai mare la viteza mai mare; `false` o opreste in < 0.3 s. Pe loc nu canta.
##   5. Adversarul (AI): nicio bucla de rulare, nicio bordura, niciun vant.
##   6. Pe PISTA REALA (Track01, masina cu `track` setat): pe sosea de asfalt suprafata
##      e NONE, pe sosea de pamant (`custom_road_surface = "dirt"`) e GRAVEL, in afara
##      soselei e afanat (GRASS sau GRAVEL, dupa culoarea terenului) — adica `tick`
##      primeste suprafata de la `Car._on_loose_ground`, nu doar din cusatura.
## Sabotaj (trebuie sa PICE): `-- --off=flat` (volum constant), `-- --off=ignore`
## (suprafata ignorata: nimic nu canta).
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSurfaceVoice.tscn

const U := preload("res://tools/probe_audio_util.gd")
const TRACK_SCENE: String = "res://scenes/tracks/Track01.tscn"
const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
const KINDS: Array[String] = ["GRASS", "GRAVEL", "WATER"]

var _failed: bool = false
var _off: String = ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--off="):
			_off = a.substr(6)
	U.ground(self)
	await get_tree().physics_frame
	print("")
	print("=== Vocile suprafetelor ===")
	if _off != "":
		print("  (SABOTAJ: %s)" % _off)
	await _test_asphalt()
	await _test_surfaces()
	await _test_crossfade()
	await _test_kerb()
	await _test_ai()
	await _test_real_track()
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _spawn(player: bool = true) -> Car:
	var car := U.spawn(self, player)
	var au = U.audio(car)
	if _off == "flat":
		au.roll_db = Vector2(-13.0, -13.0)
	await U.settle(get_tree())
	return car


func _run(car: Car, speed: float, seconds: float) -> void:
	for _f in int(seconds / U.STEP):
		if speed >= 0.0:
			U.pin_speed(car, speed)
		await get_tree().physics_frame


func _roll_playing(au: Node) -> Array[String]:
	var out: Array[String] = []
	for k in au.roll:
		var p: AudioStreamPlayer3D = au.roll[k]
		if p != null and p.playing:
			out.append(KINDS[int(k) - 1])
	return out


func _set_surface(au: Node, kind: int) -> void:
	au.override_surface = 0 if _off == "ignore" else kind


func _test_asphalt() -> void:
	print("")
	print("-- 1. asfalt --")
	var car := await _spawn()
	var au = U.audio(car)
	U.drv(car).throttle = 1.0
	await _run(car, 25.0, 0.8)
	_check(_roll_playing(au).is_empty(), "la 25 m/s pe asfalt nu canta nicio bucla de rulare")
	car.queue_free()
	await get_tree().physics_frame


func _test_surfaces() -> void:
	print("")
	print("-- 2. fiecare suprafata --")
	var expect := {1: "roll_grass", 2: "roll_gravel", 3: "roll_water"}
	for kind in [1, 2, 3]:
		var car := await _spawn()
		var au = U.audio(car)
		U.drv(car).throttle = 1.0
		_set_surface(au, kind)
		await _run(car, 5.0, 0.7)
		var slow_db := -99.0
		if au.roll.has(kind) and au.roll[kind] != null:
			slow_db = au.roll[kind].volume_db
		await _run(car, 25.0, 0.7)
		var playing := _roll_playing(au)
		var p: AudioStreamPlayer3D = au.roll.get(kind)
		var fast_db: float = p.volume_db if p != null else -99.0
		var right_stream: bool = p != null and p.playing and p.stream == AudioManager.stream(StringName(expect[kind]))
		print("  %s: canta %s, volum %.1f dB la 5 m/s, %.1f dB la 25 m/s" % [KINDS[kind - 1], playing, slow_db, fast_db])
		_check(right_stream, "%s: canta %s" % [KINDS[kind - 1], expect[kind]])
		_check(playing.size() == 1, "%s: numai ea canta" % KINDS[kind - 1])
		_check(fast_db - slow_db >= 6.0, "%s: mai tare cu viteza (>= 6 dB)" % KINDS[kind - 1])
		# Pe loc tace.
		U.drv(car).throttle = 0.0
		car.linear_velocity = Vector3.ZERO
		await _wait(0.5)
		for _f in 20:
			car.linear_velocity = Vector3(0, car.linear_velocity.y, 0)
			await get_tree().physics_frame
		_check(_roll_playing(au).is_empty(), "%s: pe loc tace" % KINDS[kind - 1])
		car.queue_free()
		await get_tree().physics_frame


func _wait(seconds: float) -> void:
	for _f in int(seconds / U.STEP):
		await get_tree().physics_frame


func _test_crossfade() -> void:
	print("")
	print("-- 3. cross-fade iarba -> pietris --")
	var car := await _spawn()
	var au = U.audio(car)
	U.drv(car).throttle = 1.0
	_set_surface(au, 1)
	await _run(car, 22.0, 0.8)
	_set_surface(au, 2)
	await _run(car, 22.0, 0.08)
	var mid := _roll_playing(au)
	var grass_db: float = au.roll[1].volume_db if au.roll.has(1) else -99.0
	var gravel_db: float = au.roll[2].volume_db if au.roll.has(2) else -99.0
	print("  la 0.08 s: canta %s (iarba %.1f dB, pietris %.1f dB)" % [mid, grass_db, gravel_db])
	_check(mid.size() == 2, "la ~0.08 s canta si iarba (se stinge), si pietrisul (urca)")
	await _run(car, 22.0, 0.6)
	_check(_roll_playing(au) == ["GRAVEL"], "dupa 0.6 s a ramas doar pietrisul (%s)" % [_roll_playing(au)])
	car.queue_free()
	await get_tree().physics_frame


func _test_kerb() -> void:
	print("")
	print("-- 4. bordura --")
	var car := await _spawn()
	var au = U.audio(car)
	U.drv(car).throttle = 1.0
	au.override_surface = 0 # asfalt
	await _run(car, 8.0, 0.4)
	au.override_kerb = 1
	await _run(car, 8.0, 0.4)
	var slow_db: float = au.kerb.volume_db if au.kerb != null else -99.0
	var slow_pitch: float = au.kerb.pitch_scale if au.kerb != null else 0.0
	await _run(car, 26.0, 0.5)
	var ok_stream: bool = au.kerb != null and au.kerb.playing \
		and au.kerb.stream == AudioManager.stream(&"kerb_rattle")
	var fast_db: float = au.kerb.volume_db if au.kerb != null else -99.0
	var fast_pitch: float = au.kerb.pitch_scale if au.kerb != null else 0.0
	print("  8 m/s: %.1f dB pitch %.2f; 26 m/s: %.1f dB pitch %.2f" % [slow_db, slow_pitch, fast_db, fast_pitch])
	_check(ok_stream, "bordura canta `kerb_rattle`")
	_check(fast_db - slow_db >= 6.0 and fast_pitch - slow_pitch >= 0.2,
		"mai tare (>= 6 dB) si cu pitch mai mare cu viteza")
	au.override_kerb = 0
	await _run(car, 26.0, 0.3)
	_check(au.kerb == null or not au.kerb.playing, "dupa iesirea de pe bordura se opreste in < 0.3 s")
	au.override_kerb = 1
	U.drv(car).throttle = 0.0
	for _f in 40:
		car.linear_velocity = Vector3(0, car.linear_velocity.y, 0)
		await get_tree().physics_frame
	_check(au.kerb == null or not au.kerb.playing, "pe loc pe bordura nu canta")
	car.queue_free()
	await get_tree().physics_frame


func _test_ai() -> void:
	print("")
	print("-- 5. adversarul --")
	var car := await _spawn(false)
	var au = U.audio(car)
	U.drv(car).throttle = 1.0
	au.override_surface = 1
	au.override_kerb = 1
	await _run(car, 25.0, 0.8)
	_check(au.roll.is_empty() and au.kerb == null and au.wind == null,
		"AI: fara rulare, bordura sau vant")
	car.queue_free()
	await get_tree().physics_frame


## Un Car real (scena), fara fizica, pe pista adevarata: `tick` primeste suprafata
## de la `Car._on_loose_ground`.
func _real_surface(t: Track, lateral: float) -> int:
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	car.is_player = true
	add_child(car)
	car.apply_data(GameState.CAR_DATA[0])
	car.set_physics_process(false)
	car.freeze = true
	car.track = t
	car.route = 0
	car.road_index = 40
	car.wheels_on_ground = 4
	var p := t.point_at(car.road_index)
	var nxt := t.point_at(car.road_index + 3)
	var side := (nxt - p).cross(Vector3.UP).normalized()
	car.global_position = p + side * lateral + Vector3.UP * 0.5
	car.linear_velocity = Vector3(0, 0, -20.0)
	var on_road := t.is_on_road(car.road_index, car.global_position)
	var loose := car._on_loose_ground(on_road)
	var au = U.audio(car)
	for _f in 8:
		au.tick(U.STEP, on_road, loose)
	var s: int = au.surface
	car.queue_free()
	return s


func _build(surface: String) -> Track:
	var t := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	t.set("custom_road_surface", surface)
	add_child(t)
	await get_tree().process_frame
	await get_tree().process_frame
	return t


func _test_real_track() -> void:
	print("")
	print("-- 6. pe pista reala (Track01) --")
	var asph := await _build("asphalt")
	var s_road := _real_surface(asph, 0.0)
	var s_off := _real_surface(asph, 40.0)
	asph.queue_free()
	await get_tree().process_frame
	var dirt := await _build("dirt")
	var s_dirt := _real_surface(dirt, 0.0)
	dirt.queue_free()
	await get_tree().process_frame
	print("  asfalt pe sosea: %d, asfalt in afara soselei: %d, pamant pe sosea: %d (0 NONE, 1 GRASS, 2 GRAVEL, 3 WATER)"
		% [s_road, s_off, s_dirt])
	_check(s_road == 0, "sosea de asfalt: NONE")
	_check(s_dirt == 2, "sosea de pamant: GRAVEL")
	_check(s_off == 1 or s_off == 2, "in afara soselei: GRASS sau GRAVEL")
