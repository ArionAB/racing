extends Node
## Vantul care creste cu viteza (docs/feel_checklist.md, `sense-of-speed`, partea
## de sunet). Citeste playerul 2D `wind` al lui CarAudio.
##
## Contractele:
##   1. Pe loc si la 30% din max: vantul nu canta.
##   2. La 50% din max: mut sau aproape (nu canta, sau <= -40 dB).
##   3. De la 50% in sus urca monoton (50 / 75 / 100 / 115% din max), cu >= 20 dB
##      intre 50% si 100%, si ajunge la >= -20 dB la 100%; pitch-ul urca.
##   4. Vantul foloseste `wind_loop` pe bus-ul SFX, ca player 2D (in capul
##      jucatorului, nu in lume).
##   5. Adversarul nu are vant.
## Nu se poate masura aici: umflarea din `Car.draft` (proprietatea vine din
## feel/handling-2; pana atunci citirea e protejata si da 0).
## Sabotaj (trebuie sa PICE): `-- --off=flat` (volum constant, ca un zgomot de
## fond).
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeWind.tscn

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
	print("=== Vantul ===")
	if _off != "":
		print("  (SABOTAJ: %s)" % _off)
	await _test_player()
	await _test_ai()
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _level(au: Node) -> float:
	return au.wind.volume_db if au.wind != null and au.wind.playing else -99.0


func _test_player() -> void:
	print("")
	print("-- 1-4. jucatorul --")
	var car := U.spawn(self, true)
	var au = U.audio(car)
	if _off == "flat":
		au.wind_db = Vector2(-14.0, -14.0)
		au.wind_start_frac = 0.0
	await U.settle(get_tree())
	U.drv(car).throttle = 1.0
	var db := {}
	var pitch := {}
	for f in [0.0, 0.3, 0.5, 0.75, 1.0, 1.15]:
		for _i in 90:
			if f > 0.0:
				U.pin_speed(car, car.max_speed * f)
			else:
				car.linear_velocity = Vector3(0, car.linear_velocity.y, 0)
			await get_tree().physics_frame
		db[f] = _level(au)
		pitch[f] = au.wind.pitch_scale if au.wind != null else 0.0
		print("  %3.0f%% din max: %s, pitch %.2f" % [f * 100.0,
			"mut" if db[f] <= -90.0 else "%.1f dB" % db[f], pitch[f]])
	_check(db[0.0] <= -90.0 and db[0.3] <= -90.0, "pe loc si la 30% nu canta")
	_check(db[0.5] <= -40.0, "la 50% din max mut sau <= -40 dB")
	_check(db[0.75] > db[0.5] and db[1.0] > db[0.75] and db[1.15] >= db[1.0],
		"urca monoton de la 50% in sus")
	_check(db[1.0] - db[0.5] >= 20.0 and db[1.0] >= -20.0,
		"la 100% e cu >= 20 dB peste 50% si >= -20 dB")
	_check(pitch[1.0] > pitch[0.75] and pitch[0.75] > pitch[0.5], "pitch-ul urca cu viteza")
	var w: AudioStreamPlayer = au.wind
	_check(w != null and w.stream == AudioManager.stream(&"wind_loop") and w.bus == &"SFX",
		"`wind_loop` pe bus-ul SFX, player 2D")
	car.queue_free()
	await get_tree().physics_frame


func _test_ai() -> void:
	print("")
	print("-- 5. adversarul --")
	var car := U.spawn(self, false)
	var au = U.audio(car)
	await U.settle(get_tree())
	U.drv(car).throttle = 1.0
	for _i in 90:
		U.pin_speed(car, car.max_speed)
		await get_tree().physics_frame
	_check(au.wind == null, "AI: fara vant")
	car.queue_free()
	await get_tree().physics_frame
