extends Node
## Claxonul de jucarie al AI-ului (docs/feel_checklist.md: who-hit-me, ai-reacts —
## partea de sunet).
##
## Verifica:
##   1. AudioManager.honk(): pozitional (playerul 3D real sta la masina si poarta
##      `toy_horn`), pauza per masina (3 s) si globala (0,4 s), ton diferit per
##      masina, iar in afara razei de 55 m nu suna si NU consuma pauza;
##   2. frecarea jucatorului de un AI: dupa 0,6 s AI-ul poate claxona, O SINGURA
##      data pe episod, doar cu sansa data; un AI fara AIController, jucatorul
##      insusi sau un episod scurt nu claxoneaza;
##   3. in Race.tscn REAL: cand un AI isi face ranchiuna fata de un atacator
##      (`AIController._process_hit`), claxoneaza din pozitia lui; a doua ranchiuna
##      in 3 s nu mai claxoneaza, dupa 3 s da.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeHorn.tscn

const ImpactSoundScript := preload("res://scenes/race/impact_sound.gd")
const STEP: float = 1.0 / 60.0

var _failed: bool = false
var _now: float = 5000.0


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _clock() -> float:
	return _now


func _advance(seconds: float) -> void:
	for _f in int(round(seconds / STEP)):
		_now += STEP
		await get_tree().physics_frame


func _horns() -> Array:
	return AudioManager.sfx_log.filter(func(e: Dictionary) -> bool: return e["name"] == &"toy_horn")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("")
	print("=== Claxon de jucarie ===")
	AudioManager.clock = _clock
	await _test_audio_manager()
	await _test_rub_honk()
	await _test_grudge_in_race()
	AudioManager.clock = func() -> float: return Time.get_ticks_msec() * 0.001
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


func _test_audio_manager() -> void:
	print("")
	print("-- 1. AudioManager.honk --")
	var cam := Camera3D.new()
	add_child(cam)
	cam.global_position = Vector3(0, 10, 13)
	cam.current = true
	await get_tree().process_frame
	AudioManager.sfx_log.clear()
	var pos_a := Vector3(4, 0, -6)
	_check(AudioManager.honk(101, pos_a), "prima claxonare suna")
	var log := _horns()
	_check(log.size() == 1 and log[0]["positional"], "e pozitionala (jurnal)")
	if not log.is_empty():
		var found := false
		for p in AudioManager.pool3d():
			if p.stream == AudioManager.stream(&"toy_horn") \
					and p.global_position.distance_to(pos_a) < 0.01:
				found = true
		_check(found, "playerul 3D real sta la masina si poarta toy_horn")
	_check(not AudioManager.honk(101, pos_a), "aceeasi masina imediat: nu")
	await _advance(0.5)
	_check(not AudioManager.honk(101, pos_a), "aceeasi masina la 0,5 s: nu")
	_check(AudioManager.honk(102, pos_a), "alta masina dupa pauza globala: da")
	_check(not AudioManager.honk(103, pos_a), "a treia in acelasi moment: nu (pauza globala)")
	await _advance(2.7)
	_check(AudioManager.honk(101, pos_a), "aceeasi masina dupa 3 s: da")
	# Tonuri diferite.
	await _advance(0.5)
	AudioManager.sfx_log.clear()
	AudioManager.honk(201, pos_a)
	await _advance(0.5)
	AudioManager.honk(202, pos_a)
	var h := _horns()
	if h.size() == 2:
		_check(absf(float(h[0]["pitch"]) - float(h[1]["pitch"])) > 0.02,
			"doua masini, doua tonuri (%.2f / %.2f)" % [float(h[0]["pitch"]), float(h[1]["pitch"])])
	else:
		_check(false, "doua claxoane in jurnal (%d)" % h.size())
	# In afara razei: nu suna si nu consuma pauza.
	await _advance(0.5)
	var far := Vector3(0, 0, -100)
	_check(not AudioManager.honk(301, far), "la 115 m de camera: nu suna")
	_check(AudioManager.honk(301, pos_a), "aceeasi masina, aproape, imediat dupa: suna (pauza neconsumata)")
	cam.queue_free()
	await get_tree().process_frame


func _stub(player: bool, ai: bool) -> Car:
	var c := Car.new()
	c.is_player = player
	if ai:
		c.controller = AIController.new()
	return c


func _rub_episode(snd: Node, player: Car, rival: Car, seconds: float) -> int:
	AudioManager.sfx_log.clear()
	player.rub_car = rival
	player.rub_speed = 5.0
	await _advance(seconds)
	player.rub_car = null
	player.rub_speed = 0.0
	await _advance(0.7)
	return _horns().size()


func _test_rub_honk() -> void:
	print("")
	print("-- 2. frecare => claxon, o data pe episod --")
	var cam := Camera3D.new()
	add_child(cam)
	cam.global_position = Vector3(0, 10, 13)
	cam.current = true
	await get_tree().process_frame
	var player := _stub(true, false)
	var rival := _stub(false, true)
	var plain := _stub(false, false)
	# Jucatorul ramane IN AFARA arborelui: cu fizica proprie si-ar rescrie singur
	# `rub_car` la fiecare tick. Rivalii sunt in arbore (global_position), dar inghetati.
	for c: Car in [rival, plain]:
		c.freeze = true
		add_child(c)
	rival.global_position = Vector3(0, 0, -5)
	var snd := ImpactSoundScript.new()
	snd.clock = _clock
	snd.rub_honk_chance = 1.0
	add_child(snd)
	snd.setup(player, [player, rival, plain])
	await _advance(3.5) # pauze vechi expirate
	var n := await _rub_episode(snd, player, rival, 4.5)
	_check(n == 1, "frecare de 4,5 s cu un AI (peste pauza de 3 s): exact un claxon (%d)" % n)
	await _advance(3.5)
	n = await _rub_episode(snd, player, rival, 0.4)
	_check(n == 0, "episod de 0,4 s (sub 0,6 s): niciun claxon (%d)" % n)
	await _advance(3.5)
	n = await _rub_episode(snd, player, plain, 2.0)
	_check(n == 0, "frecare de o masina fara AIController: niciun claxon (%d)" % n)
	snd.rub_honk_chance = 0.0
	await _advance(3.5)
	n = await _rub_episode(snd, player, rival, 2.0)
	_check(n == 0, "cu sansa 0: niciun claxon (%d)" % n)
	snd.queue_free()
	cam.queue_free()
	await get_tree().process_frame


func _test_grudge_in_race() -> void:
	print("")
	print("-- 3. ranchiuna in Race => claxon --")
	GameState.total_laps = 99
	GameState.selected_track = 12
	var race := (load("res://scenes/race/Race.tscn") as PackedScene).instantiate()
	add_child(race)
	var guard := 0
	while race.get("position_watch") == null and guard < 1500:
		await get_tree().process_frame
		guard += 1
	while race.state != race.State.RUNNING and guard < 3000:
		await get_tree().physics_frame
		guard += 1
	_check(race.state == race.State.RUNNING, "cursa a pornit")
	# Ceasul continua dupa cel de la testele 1-2 (pauzele vechi sunt in viitorul lui).
	AudioManager.clock = func() -> float: return 10000.0 + float(Engine.get_physics_frames()) * STEP
	var player: Car = race.player
	var ai_car: Car = race.cars[1]
	for c in race.cars:
		if c != ai_car:
			c.on_start_grid = true
	var ctrl := ai_car.controller as AIController
	_check(ctrl != null, "AI-ul ales are AIController")
	if ctrl == null:
		race.queue_free()
		return
	await _advance_frames(120)
	AudioManager.sfx_log.clear()
	var g0 := ctrl.grudge_count
	_force_grudge(ctrl, ai_car, player)
	await _advance_frames(2)
	var hs := _horns()
	print("  ranchiuni noi %d, claxoane %d" % [ctrl.grudge_count - g0, hs.size()])
	_check(ctrl.grudge_count == g0 + 1, "ranchiuna s-a nascut")
	_check(hs.size() == 1, "AI-ul a claxonat o data")
	if hs.size() == 1:
		_check((hs[0]["pos"] as Vector3).distance_to(ai_car.global_position) < 3.0,
			"claxonul vine de la masina AI-ului")
	_force_grudge(ctrl, ai_car, player)
	await _advance_frames(2)
	_check(_horns().size() == 1, "a doua ranchiuna in 3 s: fara al doilea claxon")
	await _advance_frames(200)
	# Intre timp AI-ul a plecat in cursa, in afara razei claxonului: il aducem langa camera.
	ai_car.global_position = race.camera.global_position + Vector3(0, -8, -12)
	_force_grudge(ctrl, ai_car, player)
	await _advance_frames(2)
	_check(_horns().size() == 2, "dupa 3 s: claxoneaza din nou (%d)" % _horns().size())
	race.queue_free()
	await get_tree().process_frame


func _advance_frames(n: int) -> void:
	for _f in n:
		await get_tree().physics_frame


## Naste o ranchiuna fata de `attacker`: istoricul de viteze arata atacatorul
## venind din spate (apropiere pe linia de contact), apoi se proceseaza lovitura.
func _force_grudge(ctrl: AIController, ai_car: Car, attacker: Car) -> void:
	var n := Vector3(0, 0, -1)
	var old: Dictionary = ctrl._hist[(ctrl._hist_i + 1) % 3]
	old[ai_car] = Vector3.ZERO
	old[attacker] = Vector3(0, 0, -12)
	attacker.finished = false
	ctrl._process_hit([12.0, n, attacker])
