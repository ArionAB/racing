extends Node
## Turbo ca eveniment in trei parti, partea de sunet (docs/feel_checklist.md,
## `turbo-event`): click la apasare, suvoi cat arde, sisait la capat. Citeste
## contoarele lui CarAudio, playerul `whoosh` si pool-ul 2D al lui AudioManager.
##
## Contractele:
##   1. Apasare cu bara plina: exact un click (`turbo_click` pe un player din pool
##      pornit), in cel mult 3 cadre.
##   2. Cat arde: `whoosh` canta `turbo_whoosh`, volumul URCA (la 0.05 s mai jos
##      decat la 0.5 s) si ajunge la >= -12 dB.
##   3. La capat (dupa >= 0.5 s de ardere): exact un sisait (`turbo_release` pe un
##      player din pool pornit), iar suvoiul se stinge in < 1 s.
##   4. O atingere scurta (ardere < 0.25 s) nu da sisait.
##   5. Adversarul: turbo-ul lui nu scoate click, suvoi sau sisait (doar jucatorul).
## Sabotaj (trebuie sa PICE): `-- --off=whoosh` (suvoi mut), `-- --off=release`
## (fara sisait la capat).
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeTurboSound.tscn

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
	print("=== Turbo: click, suvoi, sisait ===")
	if _off != "":
		print("  (SABOTAJ: %s)" % _off)
	await _test_event()
	await _test_tap()
	await _test_ai()
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _spawn(player: bool) -> Car:
	var car := U.spawn(self, player)
	var au = U.audio(car)
	if _off == "whoosh":
		au.whoosh_db = -80.0
	elif _off == "release":
		au.release_min_burn = 99.0
	await U.settle(get_tree())
	car.turbo_charge = 1.0
	return car


func _wait(seconds: float) -> void:
	for _f in int(seconds / U.STEP):
		await get_tree().physics_frame


## Playerele 2D din pool care canta acum `sfx_name`.
func _pool_playing(sfx_name: StringName) -> int:
	var n := 0
	for c in AudioManager.get_children():
		var p := c as AudioStreamPlayer
		if p != null and p.playing and p.stream == AudioManager.stream(sfx_name):
			n += 1
	return n


func _test_event() -> void:
	print("")
	print("-- 1-3. apasare, ardere, eliberare --")
	var car := await _spawn(true)
	var au = U.audio(car)
	var drv := U.drv(car)
	drv.throttle = 1.0
	await _wait(0.3)
	drv.turbo = true
	var frames := 0
	while au.turbo_clicks == 0 and frames < 10:
		await get_tree().physics_frame
		frames += 1
	var click_playing := _pool_playing(&"turbo_click")
	print("  click dupa %d cadre, clickuri %d, playere de click pornite %d"
		% [frames, au.turbo_clicks, click_playing])
	_check(au.turbo_clicks == 1 and frames <= 3, "exact un click, in <= 3 cadre")
	_check(click_playing >= 1, "`turbo_click` canta pe un player din pool")
	await _wait(0.05)
	var early_db: float = au.whoosh.volume_db if au.whoosh != null and au.whoosh.playing else -99.0
	await _wait(0.45)
	var late_db: float = au.whoosh.volume_db if au.whoosh != null and au.whoosh.playing else -99.0
	var ok_stream: bool = au.whoosh != null and au.whoosh.playing \
		and au.whoosh.stream == AudioManager.stream(&"turbo_whoosh")
	print("  suvoi: %.1f dB la 0.05 s, %.1f dB la 0.5 s (boosting=%s, bara %.2f)"
		% [early_db, late_db, car.is_boosting, car.turbo_charge])
	_check(ok_stream, "`whoosh` canta `turbo_whoosh` cat arde")
	_check(late_db > early_db + 1.0, "volumul suvoiului urca (rampa de intrare)")
	_check(late_db >= -12.0, "suvoiul ajunge la >= -12 dB")
	_check(au.release_hisses == 0, "inca niciun sisait cat arde")
	drv.turbo = false
	await _wait(0.1)
	print("  sisaituri %d, playere de sisait pornite %d" % [au.release_hisses, _pool_playing(&"turbo_release")])
	_check(au.release_hisses == 1, "exact un sisait la capat")
	_check(_pool_playing(&"turbo_release") >= 1, "`turbo_release` canta pe un player din pool")
	await _wait(0.9)
	_check(au.whoosh == null or not au.whoosh.playing, "suvoiul s-a stins in < 1 s")
	car.queue_free()
	await get_tree().physics_frame


func _test_tap() -> void:
	print("")
	print("-- 4. atingere scurta --")
	var car := await _spawn(true)
	var au = U.audio(car)
	var drv := U.drv(car)
	drv.throttle = 1.0
	await _wait(0.3)
	drv.turbo = true
	await _wait(0.1)
	drv.turbo = false
	await _wait(0.5)
	print("  clickuri %d, sisaituri %d" % [au.turbo_clicks, au.release_hisses])
	_check(au.turbo_clicks == 1, "atingerea da click")
	_check(au.release_hisses == 0, "dar nu sisait (ardere < 0.25 s)")
	car.queue_free()
	await get_tree().physics_frame


func _test_ai() -> void:
	print("")
	print("-- 5. adversarul --")
	var car := await _spawn(false)
	var au = U.audio(car)
	var drv := U.drv(car)
	drv.throttle = 1.0
	drv.turbo = true
	await _wait(0.8)
	drv.turbo = false
	await _wait(0.3)
	print("  clickuri %d, sisaituri %d, suvoi %s" % [au.turbo_clicks, au.release_hisses, au.whoosh])
	_check(au.turbo_clicks == 0 and au.release_hisses == 0 and au.whoosh == null,
		"AI: fara click, sisait sau suvoi")
	car.queue_free()
	await get_tree().physics_frame
