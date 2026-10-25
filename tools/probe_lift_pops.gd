extends Node
## Rateuri la ridicarea gazului (docs/feel_checklist.md, `lift-pops`): `backfire`
## nu mai e incarcat degeaba. Citeste contorul `pops_fired` si playerele de rateu
## ale lui CarAudio.
##
## Contractele:
##   1. Gaz plin la 85% din max, apoi gaz 0, cu sansa fortata la 1: rateaza in
##      mai putin de 0.1 s, cu `backfire` pe un player pornit.
##   2. La 40% din max (turatie joasa) nu rateaza niciodata, oricat de mare e sansa.
##   3. Cooldown: o a doua ridicare la 0.5 s dupa prima nu mai rateaza; dupa
##      cooldown-ul maxim (pop_cooldown * 1.8) rateaza iar.
##   4. Aleator, nu tipar: cu sansa implicita, din 60 de ridicari eligibile (fara
##      cooldown) rateaza intre 30% si 80%, cu cel putin 8 pitch-uri distincte.
##   5. O ridicare de la gaz 0.3 (nu 1.0) nu rateaza (trebuie sa fi fost pe gaz).
##   6. Adversar (AI): departe de camera (~85 m) tace; aproape (~9 m) rateaza,
##      mai incet decat jucatorul.
## Sabotaj (trebuie sa PICE): `-- --off=chance` (nu rateaza niciodata),
## `-- --off=speed` (rateaza si la turatie joasa), `-- --off=cooldown` (fara cooldown).
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeLiftPops.tscn

const U := preload("res://tools/probe_audio_util.gd")

var _failed: bool = false
var _off: String = ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--off="):
			_off = a.substr(6)
	U.ground(self)
	await get_tree().physics_frame
	print("")
	print("=== Rateuri la ridicarea gazului ===")
	if _off != "":
		print("  (SABOTAJ: %s)" % _off)
	await _test_high_vs_low()
	await _test_cooldown()
	await _test_random()
	await _test_partial_lift()
	await _test_ai()
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _spawn(player: bool, chance: float = 1.0) -> Car:
	var car := U.spawn(self, player)
	var au = U.audio(car)
	au.pop_chance = chance
	au.pop_double_chance = 0.0
	au.rng.seed = 7
	if _off == "chance":
		au.pop_chance = 0.0
	elif _off == "speed":
		au.pop_min_speed_frac = 0.0
	elif _off == "cooldown":
		au.pop_cooldown = 0.0
	return car


## Un ciclu „gaz plin la `frac` din max timp de `on_s` secunde, apoi ridicat timp
## de `off_s`". Viteza e fixata (nu vrem ca drag-ul sa ne scada sub prag).
func _cycle(car: Car, frac: float, on_s: float, off_s: float, thr_on: float = 1.0) -> void:
	var drv := U.drv(car)
	drv.throttle = thr_on
	for _f in int(on_s / U.STEP):
		U.pin_speed(car, car.max_speed * frac)
		await get_tree().physics_frame
	drv.throttle = 0.0
	for _f in int(off_s / U.STEP):
		U.pin_speed(car, car.max_speed * frac)
		await get_tree().physics_frame


func _test_high_vs_low() -> void:
	print("")
	print("-- 1-2. turatie mare vs mica --")
	var car := _spawn(true)
	var au = U.audio(car)
	await U.settle(get_tree())
	await _cycle(car, 0.85, 1.0, 0.0)
	var n0: int = au.pops_fired
	U.drv(car).throttle = 0.0
	var frames := 0
	while au.pops_fired == n0 and frames < 30:
		U.pin_speed(car, car.max_speed * 0.85)
		await get_tree().physics_frame
		frames += 1
	print("  rateu dupa %d cadre, playere de rateu: %d" % [frames, au.pops.size()])
	_check(au.pops_fired > n0 and frames <= 6, "rateaza in < 0.1 s dupa ridicare la 85%")
	var ok_stream := false
	for p in au.pops:
		if p.playing and p.stream == AudioManager.stream(&"backfire"):
			ok_stream = true
	_check(ok_stream, "playerul de rateu canta `backfire`")
	await _wait(3.0)
	var n1: int = au.pops_fired
	await _cycle(car, 0.4, 1.0, 0.5)
	_check(au.pops_fired == n1, "la 40%% din max nu rateaza (%d -> %d)" % [n1, au.pops_fired])
	car.queue_free()
	await get_tree().physics_frame


func _wait(seconds: float) -> void:
	for _f in int(seconds / U.STEP):
		await get_tree().physics_frame


func _test_cooldown() -> void:
	print("")
	print("-- 3. cooldown --")
	var car := _spawn(true)
	var au = U.audio(car)
	await U.settle(get_tree())
	await _cycle(car, 0.85, 0.5, 0.3)
	var first: int = au.pops_fired
	await _cycle(car, 0.85, 0.15, 0.3) # a doua ridicare, ~0.5 s dupa prima
	var second: int = au.pops_fired
	_check(first == 1, "prima ridicare rateaza (%d)" % first)
	_check(second == first, "a doua, la ~0.5 s dupa, e blocata de cooldown (%d)" % second)
	await _wait(au.pop_cooldown * 1.8)
	await _cycle(car, 0.85, 0.3, 0.3)
	_check(au.pops_fired == first + 1, "dupa cooldown-ul maxim rateaza iar (%d)" % au.pops_fired)
	car.queue_free()
	await get_tree().physics_frame


func _test_random() -> void:
	print("")
	print("-- 4. aleator, nu tipar --")
	var car := _spawn(true, 0.55)
	var au = U.audio(car)
	au.pop_cooldown = 0.0
	await U.settle(get_tree())
	var pitches := {}
	var tries := 60
	var fired := 0
	for _i in tries:
		var before: int = au.pops_fired
		await _cycle(car, 0.85, 0.2, 0.1)
		if au.pops_fired > before:
			fired += 1
			for p in au.pops:
				if p.playing:
					pitches[snappedf(p.pitch_scale, 0.01)] = true
	print("  %d din %d ridicari au rateat, %d pitch-uri distincte" % [fired, tries, pitches.size()])
	_check(fired >= 18 and fired <= 48, "rateaza intre 30%% si 80%% din ridicari (%d/%d)" % [fired, tries])
	_check(pitches.size() >= 8, "pitch variat (>= 8 valori distincte: %d)" % pitches.size())
	car.queue_free()
	await get_tree().physics_frame


func _test_partial_lift() -> void:
	print("")
	print("-- 5. ridicare de la gaz partial --")
	var car := _spawn(true)
	var au = U.audio(car)
	await U.settle(get_tree())
	await _cycle(car, 0.85, 0.5, 0.3, 0.3)
	_check(au.pops_fired == 0, "de la gaz 0.3 nu rateaza (%d)" % au.pops_fired)
	car.queue_free()
	await get_tree().physics_frame


func _test_ai() -> void:
	print("")
	print("-- 6. adversar: departe tace, aproape rateaza mai incet --")
	var cam := Camera3D.new()
	add_child(cam)
	cam.current = true
	cam.global_position = Vector3(0, 6, 55)
	var far_car := _spawn(false)
	var near_car := _spawn(false)
	near_car.global_position = Vector3(0, 0.7, 90)
	var player := _spawn(true)
	player.global_position = Vector3(-30, 0.7, 0)
	await _wait(0.5)
	# Camera la ~85 m de adversarul de la origine (care o ia spre -Z) si la ~9 m de
	# celalalt, in momentul ridicarii (dupa o secunda de mers, ~29 m).
	await _cycle_all([far_car, near_car, player])
	var far_n: int = U.audio(far_car).pops_fired
	var near_n: int = U.audio(near_car).pops_fired
	print("  AI departe: %d rateuri, AI aproape: %d, jucator: %d"
		% [far_n, near_n, U.audio(player).pops_fired])
	_check(far_n == 0, "adversarul de la ~85 m nu rateaza")
	_check(near_n >= 1, "adversarul de la ~9 m rateaza")
	var ai_db := -99.0
	for p in U.audio(near_car).pops:
		ai_db = maxf(ai_db, p.volume_db)
	var pl_db := -99.0
	for p in U.audio(player).pops:
		pl_db = maxf(pl_db, p.volume_db)
	print("  volum rateu: AI %.1f dB, jucator %.1f dB" % [ai_db, pl_db])
	_check(near_n >= 1 and pl_db - ai_db >= 4.0, "adversarul rateaza cu >= 4 dB mai incet")
	for c in [far_car, near_car, player]:
		(c as Car).queue_free()
	cam.queue_free()
	await get_tree().physics_frame


func _cycle_all(cars: Array) -> void:
	for c in cars:
		U.drv(c).throttle = 1.0
	for _f in 60:
		for c in cars:
			U.pin_speed(c, (c as Car).max_speed * 0.85)
		await get_tree().physics_frame
	for c in cars:
		U.drv(c).throttle = 0.0
	for _f in 30:
		for c in cars:
			U.pin_speed(c, (c as Car).max_speed * 0.85)
		await get_tree().physics_frame
